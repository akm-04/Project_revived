//go:build postgres

package publicshowcase_test

import (
	"context"
	"encoding/json"
	"strconv"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/characterasset"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/domain/character"
	dconquer "gxb.local/backend/v2/internal/domain/conquerschool"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type countingRoster struct {
	inner app.Roster
	calls int
}

func (r *countingRoster) OverlayMID1(c context.Context, q tx.Queryer, a identity.ActorContext, created bool, at time.Time, detail map[string]any) error {
	r.calls++
	return r.inner.OverlayMID1(c, q, a, created, at, detail)
}

// The raw fixture heroes carry no birth row, so the decoration ports report an
// unknown basis rather than the production readers' unavailable error.
type unknownAwakening struct{}

func (unknownAwakening) RawAwakeningTx(context.Context, characterasset.CoherentReadScope, character.HeroRef) (characterasset.HeroRawAwakeningObservation, error) {
	return characterasset.HeroRawAwakeningObservation{}, nil
}

type unknownConquer struct{}

func (unknownConquer) FactsTx(context.Context, characterasset.CoherentReadScope, identity.PlayerID) (dconquer.Observation, error) {
	return dconquer.Observation{}, nil
}

// perSlotRecords is the pre-fix builder: SlotRecordsTx cannot batch it, so it
// recomposes the roster for every selected slot.
type perSlotRecords struct{ records app.RosterRecords }

func (p perSlotRecords) RecordTx(c context.Context, sc characterasset.CoherentReadScope, pid identity.PlayerID, id int64) (map[string]any, error) {
	return p.records.RecordTx(c, sc, pid, id)
}

func TestBug101ShowcaseRecordsComposeRosterOnce(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := profileActor(t, p)
	assets(t, p, a, rev)
	seedProfileHeroes(t, p, a.PlayerID, rev, 4, 4)

	content := contentstore.Store{Queryer: p}
	heroes := characterstore.HeroBootstrapProjection{Content: content}
	pets := characterstore.PetBootstrapProjection{Content: content}
	heroRoster, petRoster := &countingRoster{inner: heroes}, &countingRoster{inner: pets}
	batched := app.RosterRecords{Heroes: heroRoster, Pets: petRoster, Awakening: unknownAwakening{}, Conquer: unknownConquer{}}

	// Partner 3 shares partner 1's template, and a showcase cannot repeat one
	// template, so the six slots use partners 1, 2 and 4 through 7.
	selection := app.Selection{1, 2, 4, 5, 6, 7}
	ids := make([]any, 0, len(selection))
	for _, id := range selection {
		ids = append(ids, json.Number(strconv.FormatInt(id, 10)))
	}
	readService := composer(t, p)
	readService.Records = batched
	dispatch := stockruntime.PublicProfileReadDispatcher{Authority: bookmarkAuthority{a}, Service: readService, Showcase: wire(p, p, perSlotRecords{records: batched})}

	started := time.Now()
	beforeReply := dispatch.Dispatch(ctx, bookmarkRequest(1832, a, map[string]any{"ids": ids}))
	beforeElapsed := time.Since(started)
	if beforeReply.HTTPStatus != 200 {
		_, dbgErr := wire(p, p, perSlotRecords{records: batched}).Execute(ctx, a, selection, op())
		t.Fatalf("per-slot 1832 status %d body %+v err %v", beforeReply.HTTPStatus, beforeReply.Body, dbgErr)
	}
	if heroRoster.calls != 6 {
		t.Fatalf("per-slot 1832 composed the hero roster %d times", heroRoster.calls)
	}

	heroRoster.calls = 0
	dispatch = stockruntime.PublicProfileReadDispatcher{Authority: bookmarkAuthority{a}, Service: readService, Showcase: wire(p, p, batched)}
	started = time.Now()
	batchedReply := dispatch.Dispatch(ctx, bookmarkRequest(1832, a, map[string]any{"ids": ids}))
	afterElapsed := time.Since(started)
	if batchedReply.HTTPStatus != 200 {
		t.Fatalf("batched 1832 status %d body %+v", batchedReply.HTTPStatus, batchedReply.Body)
	}
	if heroRoster.calls != 1 {
		t.Fatalf("batched 1832 composed the hero roster %d times", heroRoster.calls)
	}
	t.Logf("six-slot 1832 wall: per-slot=%s batched=%s", beforeElapsed, afterElapsed)

	beforeRows, ok := beforeReply.Body["show_case"].([6]map[string]any)
	if !ok {
		t.Fatalf("per-slot show_case %T", beforeReply.Body["show_case"])
	}
	afterRows, ok := batchedReply.Body["show_case"].([6]map[string]any)
	if !ok {
		t.Fatalf("batched show_case %T", batchedReply.Body["show_case"])
	}
	reference := app.RosterRecords{Heroes: heroes, Pets: pets, Awakening: unknownAwakening{}, Conquer: unknownConquer{}}
	references := perSlotReference(t, p, rev, a.PlayerID, reference, selection)
	for i, id := range selection {
		want := references[id]
		if got := recordJSON(t, afterRows[i]); got != want {
			t.Fatalf("slot %d batched record %s want %s", i, got, want)
		}
		if got := recordJSON(t, beforeRows[i]); got != want {
			t.Fatalf("slot %d per-slot record %s want %s", i, got, want)
		}
	}

	heroRoster.calls = 0
	readReply := dispatch.Dispatch(ctx, bookmarkRequest(1829, a, map[string]any{"to_player_id": json.Number(strconv.FormatInt(int64(a.PlayerID), 10)), "sub_type": json.Number("1")}))
	if readReply.HTTPStatus != 200 {
		t.Fatalf("1829 status %d body %+v", readReply.HTTPStatus, readReply.Body)
	}
	if heroRoster.calls != 1 {
		t.Fatalf("1829 composed the hero roster %d times", heroRoster.calls)
	}
	readRows, ok := readReply.Body["show_case"].([6]map[string]any)
	if !ok {
		t.Fatalf("1829 show_case %T", readReply.Body["show_case"])
	}
	for i, id := range selection {
		want := references[id]
		if got := recordJSON(t, afterRows[i]); got != want {
			t.Fatalf("1832 slot %d record %s want %s", i, got, want)
		}
		if got := recordJSON(t, readRows[i]); got != want {
			t.Fatalf("1829 slot %d record %s want %s", i, got, want)
		}
	}
}

// perSlotReference computes each record through the unchanged single-record
// path so the batched reply can be compared byte for byte.
func perSlotReference(t *testing.T, p *pg.Pool, rev string, pid identity.PlayerID, records app.RosterRecords, selection app.Selection) map[int64]string {
	t.Helper()
	o := op()
	refs := append(o.Policies.Refs(), policy.Ref{Name: "content", Version: rev})
	var e error
	if o.Policies, e = policy.NewSet(refs...); e != nil {
		t.Fatal(e)
	}
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	sc, e := characterasset.NewCoherentReadScope(tx.Scope{Tx: tr, Operation: o, Attempt: 1, Options: tx.Options{Isolation: tx.RepeatableRead}}, rev, time.Now().UTC())
	if e != nil {
		t.Fatal(e)
	}
	out := map[int64]string{}
	for _, id := range selection {
		row, e := records.RecordTx(ctx, sc, pid, id)
		if e != nil {
			t.Fatalf("reference record %d: %v", id, e)
		}
		out[id] = recordJSON(t, row)
	}
	return out
}

func recordJSON(t *testing.T, row map[string]any) string {
	t.Helper()
	raw, e := json.Marshal(row)
	if e != nil {
		t.Fatal(e)
	}
	return string(raw)
}
