//go:build postgres

// WIP D491 regression tests. Expected RED at 84dfab039e988a935613748a5001a7a431b2881b:
// the dispatcher still accepts only select_info 0|1 and the end-call still claims.
package playerdisplay_test

import (
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
)

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
	if response.HTTPStatus != 200 && response.HTTPStatus != 409 {
		t.Fatalf("no-select end transport status %d body %+v", response.HTTPStatus, response.Body)
	}
	after := d491StoredFavor(t, p, actor, 1)
	fact, found := d491StoredDialog(t, p, actor, 1, 2)
	t.Logf("after no-select end stored_favor=%d dialog_found=%v dialog=%+v", after, found, fact)
	if after != before {
		t.Fatalf("no-select end on 10001001 dialog 2 moved stored favor %d -> %d", before, after)
	}
	if response.HTTPStatus == 200 {
		if got := response.Body["favor_degree"]; got != before {
			t.Fatalf("no-select end favor_degree %v want %d", got, before)
		}
		if info, ok := response.Body["dialog_info"].(map[string]any); ok && info["is_awarded"] != int64(0) {
			t.Fatalf("no-select end dialog_info awarded %+v", info)
		}
	}
	if found && fact.IsAwarded {
		t.Fatalf("no-select end stored dialog awarded %+v", fact)
	}
}
