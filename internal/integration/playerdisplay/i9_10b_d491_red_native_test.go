//go:build postgres

// D491 regressions recovered from the expected-RED pass at 84dfab0. They are
// green only with the fdceb60 raw seam plus source-graph talk validation.
package playerdisplay_test

import (
	"context"
	"reflect"
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	app "gxb.local/backend/v2/internal/application/librarylocal"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type graphLessLibraryContent struct{ app.ContentPort }

func (m graphLessLibraryContent) LibraryCatalogTx(ctx context.Context, q tx.Queryer, revision string) (lib.Catalog, error) {
	catalog, err := m.ContentPort.LibraryCatalogTx(ctx, q, revision)
	if err != nil {
		return catalog, err
	}
	catalog.DialogNodes = nil
	return catalog, nil
}

func d491Catalog(t *testing.T, p *pg.Pool, revision string) lib.Catalog {
	t.Helper()
	catalog, e := (contentstore.Store{Queryer: p}).LibraryCatalogTx(ctx, p, revision)
	if e != nil {
		t.Fatal(e)
	}
	return catalog
}

// Source: data/tables/10001001.lua group 11 is the single node 1101001 with
// is_reward = 1 and turn_id = -1. It is reachable from the group entry, so a
// dialog-end call claims the dialog; library_dialog_config id 11 has
// amour_reward = 0, so the configured favor delta is zero.
func TestI9_10BD491NoSelectPositiveEndOnCatalog(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	catalog := d491Catalog(t, p, rev)
	config, ok := catalog.DialogConfigs[11]
	if !ok {
		t.Fatal("dialog config 11 missing")
	}
	if grant, e := catalog.TalkEnd(10001001, 11, 0); e != nil || !grant {
		t.Fatalf("catalog positive terminal grant=%v err=%v", grant, e)
	}

	actor := bornActor(t, p)
	bornHero(t, p, actor, rev, 10001001, 1)
	setLibraryFavor(t, p, actor, 1, 100)
	service := libraryService(p, p)
	before := d491StoredFavor(t, p, actor, 1)
	want := before + config.AmourReward
	params := map[string]any{"partner_id": int64(1), "dialog_id": int64(11)}
	request := op()

	first := libraryDispatchService(t, actor, service, 843, params, request)
	t.Logf("positive end status=%d body=%+v before=%d amour_reward=%d", first.HTTPStatus, first.Body, before, config.AmourReward)
	if first.HTTPStatus != 200 || first.Body["favor_degree"] != want {
		t.Fatalf("positive end status %d body %+v want favor %d", first.HTTPStatus, first.Body, want)
	}
	info, ok := first.Body["dialog_info"].(map[string]any)
	if !ok || info["is_awarded"] != int64(1) || info["select_id"] != int64(0) {
		t.Fatalf("positive end dialog_info %T %+v", first.Body["dialog_info"], first.Body["dialog_info"])
	}
	if awards, ok := first.Body["awards"].([]any); !ok || len(awards) != 0 {
		t.Fatalf("positive end awards %T %+v", first.Body["awards"], first.Body["awards"])
	}
	fact, found := d491StoredDialog(t, p, actor, 1, 11)
	if !found || !fact.IsAwarded || fact.SelectID != 0 {
		t.Fatalf("positive end stored dialog %+v found=%v", fact, found)
	}
	firstUpdated := fact.UpdatedAt

	for _, replay := range []struct {
		name      string
		operation func() operation.Context
	}{
		{"same-operation retry", func() operation.Context { return request }},
		{"fresh operation", op},
	} {
		response := libraryDispatchService(t, actor, service, 843, params, replay.operation())
		t.Logf("%s status=%d body=%+v", replay.name, response.HTTPStatus, response.Body)
		if response.HTTPStatus != 200 || response.Body["favor_degree"] != want {
			t.Fatalf("%s status %d body %+v want favor %d", replay.name, response.HTTPStatus, response.Body, want)
		}
		repeat, found := d491StoredDialog(t, p, actor, 1, 11)
		if !found || !repeat.IsAwarded || repeat.SelectID != 0 || !repeat.UpdatedAt.Equal(firstUpdated) {
			t.Fatalf("%s stored dialog %+v found=%v, want unchanged award", replay.name, repeat, found)
		}
	}
}

// Source: data/tables/10001175.lua has the two real cross-group edges
// 1001006 (group 10) -> 1001007 (group 11) -> 1001008 (group 10); the positive
// node 1101001 in group 11 is disconnected. A group-scoped walk would fail,
// while the relationship-global walk ends on the nonpositive terminal.
func TestI9_10BD491CrossGroupCatalogWalk(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	catalog := d491Catalog(t, p, rev)
	for _, dialogID := range []int64{10, 11} {
		if grant, e := catalog.TalkEnd(10001175, dialogID, 0); e != nil || grant {
			t.Fatalf("cross-group dialog %d grant=%v err=%v", dialogID, grant, e)
		}
	}

	actor := bornActor(t, p)
	bornHero(t, p, actor, rev, 10001175, 1)
	setLibraryFavor(t, p, actor, 1, 100)
	service := libraryService(p, p)
	before := d491StoredFavor(t, p, actor, 1)
	response := libraryDispatchService(t, actor, service, 843, map[string]any{"partner_id": int64(1), "dialog_id": int64(11)}, op())
	t.Logf("cross-group dialog 11 status=%d body=%+v before=%d", response.HTTPStatus, response.Body, before)
	if response.HTTPStatus != 200 || response.Body["favor_degree"] != before {
		t.Fatalf("cross-group dialog 11 status %d body %+v", response.HTTPStatus, response.Body)
	}
	info, ok := response.Body["dialog_info"].(map[string]any)
	if !ok || info["is_awarded"] != int64(0) || info["select_id"] != int64(0) {
		t.Fatalf("cross-group dialog 11 dialog_info %T %+v", response.Body["dialog_info"], response.Body["dialog_info"])
	}
	if after := d491StoredFavor(t, p, actor, 1); after != before {
		t.Fatalf("cross-group dialog 11 moved favor %d -> %d", before, after)
	}
}

func d491StoredFavor(t *testing.T, p *pg.Pool, actor identity.ActorContext, partner int64) int64 {
	t.Helper()
	facts, err := (librarystore.Store{}).ReadHeroTx(ctx, p, character.HeroRef{PlayerID: actor.PlayerID, PartnerID: partner})
	if err != nil {
		t.Fatal(err)
	}
	return facts.Favor
}

func d491StoredDialog(t *testing.T, p *pg.Pool, actor identity.ActorContext, partner, dialogID int64) (lib.DialogFact, bool) {
	t.Helper()
	fact, found, err := (librarystore.Store{}).ReadDialogTx(ctx, p, actor.PlayerID, partner, dialogID)
	if err != nil {
		t.Fatal(err)
	}
	return fact, found
}

// Source: data/tables/10001006.lua dialog 2, 201004.turn_id = 202001|203001,
// 202001.is_reward = 3, 203001.is_reward = 2; library_dialog_config id 2
// amour_reward = 2. HeroTalkWindow.lua:256 sends the raw flag verbatim and
// DialogueTable.lua:28 stores it, so both options are source-valid choices.
func TestI9_10BD491RawChoiceGrantsConfiguredAmour(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	const wantAmourReward = int64(2)
	cases := []struct {
		name       string
		selectInfo string
		option     int64
	}{
		{"raw3-202001", "3|202001", 202001},
		{"raw2-203001", "2|203001", 203001},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			actor := bornActor(t, p)
			bornHero(t, p, actor, rev, 10001006, 1)
			setLibraryFavor(t, p, actor, 1, 100)
			service := libraryService(p, p)

			before := d491StoredFavor(t, p, actor, 1)
			t.Logf("before select_info=%q stored_favor=%d", tc.selectInfo, before)

			request := op()
			params := map[string]any{"partner_id": int64(1), "dialog_id": int64(2), "select_info": tc.selectInfo}
			response := libraryDispatchService(t, actor, service, 843, params, request)
			t.Logf("first select_info=%q status=%d body=%+v", tc.selectInfo, response.HTTPStatus, response.Body)
			if response.HTTPStatus != 200 {
				t.Fatalf("source-valid select_info %q status %d body %+v", tc.selectInfo, response.HTTPStatus, response.Body)
			}
			if got := response.Body["favor_degree"]; got != before+wantAmourReward {
				t.Fatalf("select_info %q favor_degree %v want %d (amour_reward once, no raw multiplier)", tc.selectInfo, got, before+wantAmourReward)
			}
			info, ok := response.Body["dialog_info"].(map[string]any)
			if !ok || info["is_awarded"] != int64(1) || info["select_id"] != tc.option {
				t.Fatalf("select_info %q dialog_info %T %+v", tc.selectInfo, response.Body["dialog_info"], response.Body["dialog_info"])
			}
			if awards, ok := response.Body["awards"].([]any); !ok || len(awards) != 0 {
				t.Fatalf("select_info %q awards %T %+v", tc.selectInfo, response.Body["awards"], response.Body["awards"])
			}
			afterFirst := d491StoredFavor(t, p, actor, 1)
			fact, found := d491StoredDialog(t, p, actor, 1, 2)
			t.Logf("after first stored_favor=%d dialog_found=%v dialog=%+v", afterFirst, found, fact)
			if afterFirst != before+wantAmourReward {
				t.Fatalf("select_info %q stored favor %d want %d", tc.selectInfo, afterFirst, before+wantAmourReward)
			}
			if !found || !fact.IsAwarded || fact.SelectID != tc.option {
				t.Fatalf("select_info %q stored dialog %+v found=%v", tc.selectInfo, fact, found)
			}

			// Exact native receipt retry: the same operation must not grant twice.
			response = libraryDispatchService(t, actor, service, 843, params, request)
			t.Logf("exact retry select_info=%q status=%d body=%+v", tc.selectInfo, response.HTTPStatus, response.Body)
			if response.HTTPStatus != 200 || response.Body["favor_degree"] != afterFirst {
				t.Fatalf("select_info %q exact retry status %d body %+v", tc.selectInfo, response.HTTPStatus, response.Body)
			}
			if got := d491StoredFavor(t, p, actor, 1); got != afterFirst {
				t.Fatalf("select_info %q exact retry stored favor %d want %d", tc.selectInfo, got, afterFirst)
			}

			// A fresh operation is not the receipt retry; D491 still allows one
			// grant per player/partner/dialog, so state must not move again.
			response = libraryDispatchService(t, actor, service, 843, params, op())
			t.Logf("fresh operation select_info=%q status=%d body=%+v", tc.selectInfo, response.HTTPStatus, response.Body)
			if got := d491StoredFavor(t, p, actor, 1); got != afterFirst {
				t.Fatalf("select_info %q fresh operation stored favor %d want %d", tc.selectInfo, got, afterFirst)
			}
			if fact, found = d491StoredDialog(t, p, actor, 1, 2); !found || !fact.IsAwarded || fact.SelectID != tc.option {
				t.Fatalf("select_info %q fresh operation stored dialog %+v found=%v", tc.selectInfo, fact, found)
			}
		})
	}
}

// Source: data/tables/10001001.lua dialog 2, 201004.turn_id = 202001|203001;
// both terminal rows 202006 and 203003 have is_reward = 0. With no select_info
// there is no retained positive path, so D491 grants nothing.
func TestI9_10BD491NoSelectEndNonPositivePathNoFavor(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	actor := bornActor(t, p)
	bornHero(t, p, actor, rev, 10001001, 1)
	setLibraryFavor(t, p, actor, 1, 100)
	service := libraryService(p, p)

	before := d491StoredFavor(t, p, actor, 1)
	t.Logf("before no-select end stored_favor=%d", before)
	response := libraryDispatchService(t, actor, service, 843, map[string]any{"partner_id": int64(1), "dialog_id": int64(2)}, op())
	t.Logf("no-select end status=%d body=%+v", response.HTTPStatus, response.Body)
	if response.HTTPStatus != 200 {
		t.Fatalf("source-valid no-op end status %d body %+v", response.HTTPStatus, response.Body)
	}
	after := d491StoredFavor(t, p, actor, 1)
	fact, found := d491StoredDialog(t, p, actor, 1, 2)
	t.Logf("after no-select end stored_favor=%d dialog_found=%v dialog=%+v", after, found, fact)
	if after != before {
		t.Fatalf("no-select end on 10001001 dialog 2 moved stored favor %d -> %d", before, after)
	}
	if got := response.Body["favor_degree"]; got != before {
		t.Fatalf("no-select end favor_degree %v want %d", got, before)
	}
	if info, ok := response.Body["dialog_info"].(map[string]any); !ok || info["is_awarded"] != int64(0) {
		t.Fatalf("no-select end dialog_info %T %+v", response.Body["dialog_info"], response.Body["dialog_info"])
	}
	if found && fact.IsAwarded {
		t.Fatalf("no-select end stored dialog awarded %+v", fact)
	}
}

func TestI9_10BD491RejectsForgedSourceSelection(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	for _, tc := range []struct {
		name       string
		table      int64
		favor      int64
		dialogID   int64
		selectInfo string
	}{
		{"wrong source flag", 10001006, 100, 2, "2|202001"},
		{"choice node not an option", 10001006, 100, 2, "3|202002"},
		{"foreign hero option", 10001001, 100, 2, "2|203004"},
		{"option from another group", 10001006, 200, 3, "3|202001"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			actor := bornActor(t, p)
			bornHero(t, p, actor, rev, tc.table, 1)
			setLibraryFavor(t, p, actor, 1, tc.favor)
			service := libraryService(p, p)
			before := d491StoredFavor(t, p, actor, 1)
			response := libraryDispatchService(t, actor, service, 843, map[string]any{"partner_id": int64(1), "dialog_id": tc.dialogID, "select_info": tc.selectInfo}, op())
			t.Logf("forged select_info=%q status=%d body=%+v before=%d", tc.selectInfo, response.HTTPStatus, response.Body, before)
			if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
				t.Fatalf("forged select_info %q status %d body %+v", tc.selectInfo, response.HTTPStatus, response.Body)
			}
			if after := d491StoredFavor(t, p, actor, 1); after != before {
				t.Fatalf("forged select_info %q moved favor %d -> %d", tc.selectInfo, before, after)
			}
			if fact, found := d491StoredDialog(t, p, actor, 1, tc.dialogID); found && fact.IsAwarded {
				t.Fatalf("forged select_info %q stored awarded dialog %+v", tc.selectInfo, fact)
			}
		})
	}
}

func TestI9_10BD491MissingSourceGraphRefusesMutation(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	actor := bornActor(t, p)
	// 11001209 is dialog-enabled, but its relationship source file is the known
	// unknown 11001209, so the catalog carries no graph for it.
	bornHero(t, p, actor, rev, 11001209, 1)
	setLibraryFavor(t, p, actor, 1, 100)
	service := libraryService(p, p)
	before := d491StoredFavor(t, p, actor, 1)
	response := libraryDispatchService(t, actor, service, 843, map[string]any{"partner_id": int64(1), "dialog_id": int64(2), "select_info": "1|202001"}, op())
	t.Logf("missing source status=%d body=%+v before=%d", response.HTTPStatus, response.Body, before)
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("missing source status %d body %+v", response.HTTPStatus, response.Body)
	}
	if after := d491StoredFavor(t, p, actor, 1); after != before {
		t.Fatalf("missing source moved favor %d -> %d", before, after)
	}
}

// Each case first writes a new receipt, then removes the source graph before
// replaying the same operation. The replay must return the stored result bytes;
// a different operation must still fail closed without the graph.
func TestI9_10BD491NewChoiceReceiptAndReadsSurviveMissingGraph(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	cases := []struct {
		name        string
		table       int64
		selectInfo  string
		wantFavor   int64
		wantAwarded int64
		wantSelect  int64
	}{
		{"raw3-new-receipt", 10001006, "3|202001", 102, 1, 202001},
		{"zero-option", 10001001, "0|203001", 100, 0, 203001},
		{"positive-option", 10001013, "1|203001", 102, 1, 203001},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			actor := bornActor(t, p)
			bornHero(t, p, actor, rev, tc.table, 1)
			setLibraryFavor(t, p, actor, 1, 100)
			service := libraryService(p, p)
			request := op()
			params := map[string]any{"partner_id": int64(1), "dialog_id": int64(2), "select_info": tc.selectInfo}

			first := libraryDispatchService(t, actor, service, 843, params, request)
			t.Logf("first select_info=%q status=%d body=%+v", tc.selectInfo, first.HTTPStatus, first.Body)
			if first.HTTPStatus != 200 || first.Body["favor_degree"] != tc.wantFavor {
				t.Fatalf("first select_info %q status %d body %+v", tc.selectInfo, first.HTTPStatus, first.Body)
			}
			info, ok := first.Body["dialog_info"].(map[string]any)
			if !ok || info["is_awarded"] != tc.wantAwarded || info["select_id"] != tc.wantSelect {
				t.Fatalf("first select_info %q dialog_info %T %+v", tc.selectInfo, first.Body["dialog_info"], first.Body["dialog_info"])
			}

			service.Content = graphLessLibraryContent{ContentPort: service.Content}
			replay := libraryDispatchService(t, actor, service, 843, params, request)
			t.Logf("missing-graph receipt replay select_info=%q status=%d body=%+v", tc.selectInfo, replay.HTTPStatus, replay.Body)
			if replay.HTTPStatus != 200 || !reflect.DeepEqual(first.Body, replay.Body) {
				t.Fatalf("receipt replay select_info %q status %d body %+v want %+v", tc.selectInfo, replay.HTTPStatus, replay.Body, first.Body)
			}

			fresh := libraryDispatchService(t, actor, service, 843, params, op())
			t.Logf("missing-graph fresh operation select_info=%q status=%d body=%+v", tc.selectInfo, fresh.HTTPStatus, fresh.Body)
			if fresh.HTTPStatus != 409 || fresh.Body["error_code"] != int64(1) {
				t.Fatalf("missing-graph fresh operation select_info %q status %d body %+v", tc.selectInfo, fresh.HTTPStatus, fresh.Body)
			}

			read := libraryDispatchService(t, actor, service, 836, nil, op())
			if read.HTTPStatus != 200 || read.Body["library_infos"] == nil || read.Body["library_talk_infos"] == nil {
				t.Fatalf("read with missing graph select_info %q status %d body %+v", tc.selectInfo, read.HTTPStatus, read.Body)
			}
		})
	}
}
