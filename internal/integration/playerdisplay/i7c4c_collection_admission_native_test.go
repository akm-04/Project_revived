//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"reflect"
	"strconv"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	hero "gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func collectionService(p *pg.Pool) hero.Service {
	s := privateHeroService(p)
	s.Capacity = nil // No diagnostic capacity authorizer is used by this path.
	s.CollectionAdmission = hero.CatalogCollectionAdmission{Content: contentstore.Store{Queryer: p}}
	return s
}
func collectionResources(t *testing.T, p *pg.Pool, a identity.ActorContext, rev string, table int64) character.HeroNormalSummonPolicy {
	t.Helper()
	def, e := (contentstore.Store{Queryer: p}).HeroNormalSummonTx(ctx, p, rev, table)
	if e != nil {
		t.Fatal(e)
	}
	// Explicit native resource fixture. Actual source costs are still debited by
	// the real I5 owner in the genuine Character command, not a mock debit.
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,$2,$3,1,clock_timestamp(),clock_timestamp())ON CONFLICT(player_id,item_id)DO UPDATE SET quantity=excluded.quantity`, int64(a.PlayerID), def.Template.FragmentItemID, def.FragmentCount+9)
	return def
}
func collectionReceipt(t *testing.T, p *pg.Pool, a identity.ActorContext, o operation.Context) receipt.Receipt {
	t.Helper()
	r, ok, e := (kernelstore.Store{}).FindTx(ctx, p, receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "character-hero", Operation: "stone-summon", SemanticKey: o.ID.String()})
	if e != nil || !ok {
		t.Fatal("missing canonical receipt", ok, e)
	}
	return r
}

type noCurrentHeroDiscovery struct {
	hero.ProgressionContent
	Calls int
}

func (s *noCurrentHeroDiscovery) HeroProgressionActive(context.Context) (string, bool, error) {
	s.Calls++
	return "", false, errors.New("current discovery forbidden for historic receipt")
}
func (s *noCurrentHeroDiscovery) HeroProgressionRevision(context.Context, string) (bool, error) {
	s.Calls++
	return false, errors.New("current eligibility forbidden for historic receipt")
}

func TestI7C4CCollectionAdmissionCanonicalPolicyAndLegacyReceiptReplay(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := rankingActor(t, p, rankingServer(t, p), true)
	oldDef := collectionResources(t, p, a, rev, 10001001)
	oldOp := op()
	// This first legacy receipt intentionally uses the old diagnostic service to
	// qualify migration/replay compatibility; it is not new production proof.
	oldHero, e := privateHeroService(p).SummonNormal(ctx, a, 10001001, oldDef.Template.FragmentItemID, oldDef.FragmentCount, oldOp)
	if e != nil {
		t.Fatal(e)
	}
	def := collectionResources(t, p, a, rev, 10001002)
	s := collectionService(p)
	o := op()
	created, e := s.SummonNormal(ctx, a, 10001002, def.Template.FragmentItemID, def.FragmentCount, o)
	if e != nil {
		t.Fatal(e)
	}
	r := collectionReceipt(t, p, a, o)
	var payload struct {
		Admission *character.CollectionAdmissionProof `json:"collection_admission"`
	}
	if e = json.Unmarshal(r.ResultPayload, &payload); e != nil || payload.Admission == nil || payload.Admission.Validate() != nil || payload.Admission.OwnedCount != 1 || payload.Admission.ResultCount != 2 || payload.Admission.OriginTableID != 10001002 || r.PolicyVersion != character.CollectionAdmissionPolicy {
		t.Fatal("missing canonical policy proof", string(r.ResultPayload), e)
	}
	if pin, ok := r.OperationPolicyRefs.Get(character.CollectionAdmissionPolicyRef); !ok || pin != character.CollectionAdmissionPolicy {
		t.Fatal("admission policy not pinned")
	}
	discovery := &noCurrentHeroDiscovery{ProgressionContent: s.Progression}
	s.Progression = discovery
	for _, tc := range []struct {
		def       character.HeroNormalSummonPolicy
		operation operation.Context
		want      character.Hero
	}{{oldDef, oldOp, oldHero}, {def, o, created}} {
		got, e := s.SummonNormal(ctx, a, tc.want.OriginTableID, tc.def.Template.FragmentItemID, tc.def.FragmentCount, tc.operation)
		if e != nil || !reflect.DeepEqual(got, tc.want) {
			t.Fatal("historic result reinterpreted", got, e)
		}
	}
	if discovery.Calls != 0 {
		t.Fatal("old positive receipt attempted current discovery", discovery.Calls)
	}
	if _, e = collectionService(p).CreateVows(ctx, a, 11001, op()); !errors.Is(e, hero.ErrHeroCapacityUnavailable) {
		t.Fatal("Normal policy silently activated Vows", e)
	}
}

func TestI7C4CCollectionAdmissionStaleInstantRejectsBeforeDebit(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := rankingActor(t, p, rankingServer(t, p), true)
	first := collectionResources(t, p, a, rev, 10001001)
	next := collectionResources(t, p, a, rev, 10001002)
	s := collectionService(p)
	stale := op()
	if _, e := s.SummonNormal(ctx, a, 10001001, first.Template.FragmentItemID, first.FragmentCount, op()); e != nil {
		t.Fatal(e)
	}
	store := characterstore.Store{}
	before, e := store.ReadRootTx(ctx, p, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	var mana, stones int64
	if e = p.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='mana'`, int64(a.PlayerID)).Scan(&mana); e != nil {
		t.Fatal(e)
	}
	if e = p.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2`, int64(a.PlayerID), next.Template.FragmentItemID).Scan(&stones); e != nil {
		t.Fatal(e)
	}
	if _, e = s.SummonNormal(ctx, a, 10001002, next.Template.FragmentItemID, next.FragmentCount, stale); !errors.Is(e, hero.ErrHeroCapacityUnavailable) {
		t.Fatal("older instant accepted or resampled", e)
	}
	after, e := store.ReadRootTx(ctx, p, a.PlayerID)
	if e != nil || !reflect.DeepEqual(before, after) {
		t.Fatal("root/allocator changed", before, after, e)
	}
	var actualMana, actualStones int64
	if e = p.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='mana'`, int64(a.PlayerID)).Scan(&actualMana); e != nil {
		t.Fatal(e)
	}
	if e = p.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2`, int64(a.PlayerID), next.Template.FragmentItemID).Scan(&actualStones); e != nil {
		t.Fatal(e)
	}
	if mana != actualMana || stones != actualStones {
		t.Fatal("stale admission paid", mana, actualMana, stones, actualStones)
	}
	if _, ok, e := (kernelstore.Store{}).FindTx(ctx, p, receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "character-hero", Operation: "stone-summon", SemanticKey: stale.ID.String()}); e != nil || ok {
		t.Fatal("stale admission receipt", ok, e)
	}
}

func TestI7C4CCollectionAdmissionConcurrentSameOriginDebitsOnce(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := rankingActor(t, p, rankingServer(t, p), true)
	def := collectionResources(t, p, a, rev, 10001001)
	s := collectionService(p)
	var wg sync.WaitGroup
	errs := make(chan error, 2)
	for i := 0; i < 2; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, e := s.SummonNormal(ctx, a, 10001001, def.Template.FragmentItemID, def.FragmentCount, op())
			errs <- e
		}()
	}
	wg.Wait()
	close(errs)
	success := 0
	for e := range errs {
		if e == nil {
			success++
		} else if !errors.Is(e, hero.ErrHeroDuplicateOrigin) {
			t.Fatal(e)
		}
	}
	if success != 1 {
		t.Fatal("concurrent origins", success)
	}
	rows, e := (characterstore.Store{}).ListHeroesTx(ctx, p, a.PlayerID)
	if e != nil || len(rows) != 1 {
		t.Fatal(rows, e)
	}
	var stones int64
	if e = p.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2`, int64(a.PlayerID), def.Template.FragmentItemID).Scan(&stones); e != nil || stones != 9 {
		t.Fatal("duplicate cost", stones, e)
	}
}

type failCollectionFacet struct{}

var errCollectionFacet = errors.New("injected fresh facet failure after real Hero insertion and debit")

func (failCollectionFacet) InitFreshHeroTx(context.Context, tx.Tx, character.HeroRef, time.Time) error {
	return errCollectionFacet
}

func TestI7C4CCollectionAdmissionFacetFailureRollsBackAndUnknownCommit(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	t.Run("fresh facet failure", func(t *testing.T) {
		a := rankingActor(t, p, rankingServer(t, p), true)
		def := collectionResources(t, p, a, rev, 10001001)
		s := collectionService(p)
		s.FreshFacets = failCollectionFacet{}
		o := op()
		if _, e := s.SummonNormal(ctx, a, 10001001, def.Template.FragmentItemID, def.FragmentCount, o); !errors.Is(e, errCollectionFacet) {
			t.Fatal(e)
		}
		rows, e := (characterstore.Store{}).ListHeroesTx(ctx, p, a.PlayerID)
		if e != nil || len(rows) != 0 {
			t.Fatal("partial Hero", rows, e)
		}
		var stones int64
		if e = p.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2`, int64(a.PlayerID), def.Template.FragmentItemID).Scan(&stones); e != nil || stones != def.FragmentCount+9 {
			t.Fatal("debit escaped rollback", stones, e)
		}
		if _, e = collectionService(p).SummonNormal(ctx, a, 10001001, def.Template.FragmentItemID, def.FragmentCount, o); e != nil {
			t.Fatal("same semantic retry after definite rollback", e)
		}
	})
	for _, commit := range []bool{true, false} {
		name := "absent remains unresolved"
		if commit {
			name = "positive committed proof"
		}
		t.Run(name, func(t *testing.T) {
			a := rankingActor(t, p, rankingServer(t, p), true)
			def := collectionResources(t, p, a, rev, 10001001)
			s := collectionService(p)
			s.Runner.DB = metricCommitDB{p, commit}
			o := op()
			got, e := s.SummonNormal(ctx, a, 10001001, def.Template.FragmentItemID, def.FragmentCount, o)
			if commit {
				if e != nil {
					t.Fatal(e)
				}
				replay, e := collectionService(p).SummonNormal(ctx, a, 10001001, def.Template.FragmentItemID, def.FragmentCount, o)
				if e != nil || !reflect.DeepEqual(got, replay) {
					t.Fatal("positive proof changed", e)
				}
			} else {
				if e == nil {
					t.Fatal("unknown absence became success")
				}
				rows, e := (characterstore.Store{}).ListHeroesTx(ctx, p, a.PlayerID)
				if e != nil || len(rows) != 0 {
					t.Fatal("rolled back ambiguous fixture leaked", rows, e)
				}
			}
		})
	}
}
