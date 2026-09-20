package characterstore

import (
	"context"
	"errors"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/characterqueries"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type ca73Exec struct {
	sql  string
	args []any
}

type ca73StoreTx struct {
	execs   []ca73Exec
	casRows int64
}

func (*ca73StoreTx) QueryRow(context.Context, string, ...any) tx.Row { return ca42Row{} }
func (q *ca73StoreTx) Exec(_ context.Context, sql string, args ...any) (tx.CommandTag, error) {
	q.execs = append(q.execs, ca73Exec{sql: sql, args: append([]any(nil), args...)})
	if sql == characterqueries.SaveHeroAppearanceSelectors || sql == characterqueries.TouchHeroAppearanceVersion {
		return ca42Tag(q.casRows), nil
	}
	return ca42Tag(1), nil
}
func (*ca73StoreTx) Commit(context.Context) error   { return errors.New("unexpected commit") }
func (*ca73StoreTx) Rollback(context.Context) error { return errors.New("unexpected rollback") }

func ca73StoreHero() character.Hero {
	now := time.Unix(100, 0).UTC()
	return character.Hero{
		PlayerID: identity.PlayerID(1), PartnerID: 7, TableID: 11001, OriginTableID: 11001,
		Star: 3, Level: 20, Color: 5, IllusionSkinID: -1,
		CreationContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
		StateVersion:            5, CreatedAt: now, UpdatedAt: now,
	}
}

func TestCA73SaveHeroAppearanceMutationTxEntitlementAndSelectorShareOneOwnerCAS(t *testing.T) {
	h := ca73StoreHero()
	old := h.StateVersion
	h.StateVersion++
	h.CurrentSkinID = 40002006
	h.UpdatedAt = h.UpdatedAt.Add(time.Second)
	expires := time.Unix(200, 0).UTC()
	ent := character.HeroSkinEntitlement{PlayerID: h.PlayerID, PartnerID: h.PartnerID, ModelID: 40002006, ExpiresAt: &expires}
	q := &ca73StoreTx{casRows: 1}
	if err := (Store{}).SaveHeroAppearanceMutationTx(context.Background(), q, h, &ent, old); err != nil {
		t.Fatal(err)
	}
	if len(q.execs) != 2 {
		t.Fatalf("execs=%#v", q.execs)
	}
	if q.execs[0].sql != characterqueries.UpsertHeroSkinEntitlement || !reflect.DeepEqual(q.execs[0].args, []any{int64(h.PlayerID), h.PartnerID, ent.ModelID, expires}) {
		t.Fatalf("entitlement write=%#v", q.execs[0])
	}
	wantCAS := []any{int64(h.PlayerID), h.PartnerID, h.CurrentSkinID, h.IllusionSkinID, h.UpdatedAt.UTC(), old}
	if q.execs[1].sql != characterqueries.SaveHeroAppearanceSelectors || !reflect.DeepEqual(q.execs[1].args, wantCAS) {
		t.Fatalf("owner CAS=%#v", q.execs[1])
	}
}

func TestCA73SaveHeroAppearanceMutationTxSelectorOnlyStillUsesExactlyOneCAS(t *testing.T) {
	h := ca73StoreHero()
	old := h.StateVersion
	h.StateVersion++
	h.IllusionSkinID = 1
	h.UpdatedAt = h.UpdatedAt.Add(time.Second)
	q := &ca73StoreTx{casRows: 1}
	if err := (Store{}).SaveHeroAppearanceMutationTx(context.Background(), q, h, nil, old); err != nil {
		t.Fatal(err)
	}
	if len(q.execs) != 1 || q.execs[0].sql != characterqueries.SaveHeroAppearanceSelectors {
		t.Fatalf("execs=%#v", q.execs)
	}
}

func TestCA73SaveHeroAppearanceMutationTxRollsBackLostOwnerCASByReturningError(t *testing.T) {
	h := ca73StoreHero()
	old := h.StateVersion
	h.StateVersion++
	ent := character.HeroSkinEntitlement{PlayerID: h.PlayerID, PartnerID: h.PartnerID, ModelID: 40002006}
	q := &ca73StoreTx{casRows: 0}
	if err := (Store{}).SaveHeroAppearanceMutationTx(context.Background(), q, h, &ent, old); err == nil {
		t.Fatal("lost Hero CAS accepted after entitlement child write")
	}
}

func TestCA74SaveHeroLIVEEntitlementTxUsesOneChildWriteAndOneOwnerCAS(t *testing.T) {
	h := ca73StoreHero()
	old := h.StateVersion
	h.StateVersion++
	h.UpdatedAt = h.UpdatedAt.Add(time.Second)
	ent := character.HeroLIVEEntitlement{PlayerID: h.PlayerID, PartnerID: h.PartnerID, ModelID: 40001074, IsShow: true}
	q := &ca73StoreTx{casRows: 1}
	if err := (Store{}).SaveHeroLIVEEntitlementTx(context.Background(), q, h, ent, old); err != nil {
		t.Fatal(err)
	}
	if len(q.execs) != 2 {
		t.Fatalf("execs=%#v", q.execs)
	}
	if q.execs[0].sql != characterqueries.UpsertHeroLIVEEntitlement || !reflect.DeepEqual(q.execs[0].args, []any{int64(h.PlayerID), h.PartnerID, ent.ModelID, ent.IsShow}) {
		t.Fatalf("LIVE child write=%#v", q.execs[0])
	}
	wantCAS := []any{int64(h.PlayerID), h.PartnerID, h.UpdatedAt.UTC(), old}
	if q.execs[1].sql != characterqueries.TouchHeroAppearanceVersion || !reflect.DeepEqual(q.execs[1].args, wantCAS) {
		t.Fatalf("owner CAS=%#v", q.execs[1])
	}
}
