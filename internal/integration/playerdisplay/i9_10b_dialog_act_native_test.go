//go:build postgres

package playerdisplay_test

import (
	"context"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

type fixedLibraryAuthority struct{ actor identity.ActorContext }

func (a fixedLibraryAuthority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return a.actor, nil
}

func libraryDispatch(t *testing.T, p *pg.Pool, actor identity.ActorContext, mid uint16, params map[string]any, opCtx operation.Context) httpedge.Response {
	t.Helper()
	dispatcher := stockruntime.LibraryDispatcher{Authority: fixedLibraryAuthority{actor: actor}, Service: libraryService(p, p)}
	return dispatcher.Dispatch(ctx, httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: mid, Operation: opCtx, ReceivedAt: time.Now().UTC(),
		Claims: wire.CredentialClaims{Token: "fixture", Region: int64(actor.LogicalServerID)}, Params: params}})
}

func libraryCall(t *testing.T, p *pg.Pool, actor identity.ActorContext, mid uint16, params map[string]any) httpedge.Response {
	t.Helper()
	return libraryDispatch(t, p, actor, mid, params, op())
}

func setLibraryFavor(t *testing.T, p *pg.Pool, actor identity.ActorContext, partner, favor int64) {
	t.Helper()
	store := librarystore.Store{}
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	facts, e := store.LockHeroTx(ctx, tr, character.HeroRef{PlayerID: actor.PlayerID, PartnerID: partner})
	if e != nil {
		t.Fatal(e)
	}
	old := facts.StateVersion
	facts.Favor = favor
	facts.StateVersion++
	facts.UpdatedAt = time.Now().UTC().Add(-time.Minute)
	if e = store.SaveHeroTx(ctx, tr, facts, old); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
}

func libraryDialogRows(t *testing.T, body map[string]any) []map[string]any {
	t.Helper()
	raw, ok := body["partner_dialogs"].([]any)
	if !ok {
		t.Fatalf("partner_dialogs %T", body["partner_dialogs"])
	}
	rows := make([]map[string]any, 0, len(raw))
	for _, row := range raw {
		table, ok := row.(map[string]any)
		if !ok {
			t.Fatalf("dialog row %T", row)
		}
		rows = append(rows, table)
	}
	return rows
}

func TestI9_10B838DialogArrayAnd837ReadFlag(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)

	response := libraryCall(t, p, a, 838, map[string]any{"partner_id": int64(1)})
	if response.HTTPStatus != 200 {
		t.Fatalf("838 status %d body %+v", response.HTTPStatus, response.Body)
	}
	rows := libraryDialogRows(t, response.Body)
	if len(rows) != 1 || rows[0]["dialog_id"] != int64(1) || rows[0]["is_read"] != int64(0) || rows[0]["is_awarded"] != int64(0) || rows[0]["select_id"] != int64(0) {
		t.Fatalf("opened dialogs at zero favor %+v", rows)
	}

	readOperation := op()
	response = libraryDispatch(t, p, a, 837, map[string]any{"partner_id": int64(1), "dialog_id": int64(1)}, readOperation)
	if response.HTTPStatus != 200 {
		t.Fatalf("837 status %d body %+v", response.HTTPStatus, response.Body)
	}
	dialog, ok := response.Body["dialog"].(map[string]any)
	if !ok || dialog["dialog_id"] != int64(1) || dialog["is_read"] != int64(1) || dialog["is_awarded"] != int64(0) || dialog["select_id"] != int64(0) {
		t.Fatalf("837 dialog %T %+v", response.Body["dialog"], response.Body["dialog"])
	}

	response = libraryDispatch(t, p, a, 837, map[string]any{"partner_id": int64(1), "dialog_id": int64(1)}, readOperation)
	if response.HTTPStatus != 200 || response.Body["dialog"].(map[string]any)["is_read"] != int64(1) {
		t.Fatalf("837 replay status %d body %+v", response.HTTPStatus, response.Body)
	}

	response = libraryCall(t, p, a, 838, map[string]any{"partner_id": int64(1)})
	rows = libraryDialogRows(t, response.Body)
	if len(rows) != 1 || rows[0]["is_read"] != int64(1) {
		t.Fatalf("838 after read %+v", rows)
	}

	response = libraryCall(t, p, a, 837, map[string]any{"partner_id": int64(1), "dialog_id": int64(2)})
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("closed dialog status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = libraryCall(t, p, a, 837, map[string]any{"partner_id": int64(1)})
	if response.HTTPStatus != 400 {
		t.Fatalf("missing dialog_id status %d body %+v", response.HTTPStatus, response.Body)
	}

	setLibraryFavor(t, p, a, 1, 100)
	response = libraryCall(t, p, a, 838, map[string]any{"partner_id": int64(1)})
	rows = libraryDialogRows(t, response.Body)
	ids := make([]int64, 0, len(rows))
	for _, row := range rows {
		ids = append(ids, row["dialog_id"].(int64))
	}
	if len(ids) != 3 || ids[0] != 1 || ids[1] != 2 || ids[2] != 12 {
		t.Fatalf("opened dialogs at favor 100 %+v", ids)
	}
	if rows[0]["is_read"] != int64(1) || rows[1]["is_read"] != int64(0) {
		t.Fatalf("read flags at favor 100 %+v", rows)
	}
}

func TestI9_10B838EmptyArrayAndMissingKey(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 11001, 1)

	response := libraryCall(t, p, a, 838, map[string]any{"partner_id": int64(1)})
	if response.HTTPStatus != 200 {
		t.Fatalf("838 status %d body %+v", response.HTTPStatus, response.Body)
	}
	rows := libraryDialogRows(t, response.Body)
	if len(rows) != 0 {
		t.Fatalf("dialog-disabled hero dialogs %+v", rows)
	}

	response = libraryCall(t, p, a, 838, map[string]any{"partner_id": int64(2)})
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("unowned partner status %d body %+v", response.HTTPStatus, response.Body)
	}
	if _, present := response.Body["partner_dialogs"]; present {
		t.Fatalf("refusal carried partner_dialogs %+v", response.Body)
	}
}

func TestI9_10B842ActSlotsAnd844OnceOnly(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)

	response := libraryCall(t, p, a, 842, map[string]any{"partner_id": int64(1)})
	if response.HTTPStatus != 200 {
		t.Fatalf("842 status %d body %+v", response.HTTPStatus, response.Body)
	}
	acts, ok := response.Body["partner_acts"].([]any)
	if !ok || len(acts) != 4 {
		t.Fatalf("partner_acts %T %+v", response.Body["partner_acts"], response.Body["partner_acts"])
	}
	for i, act := range acts {
		if act.(map[string]any)["is_awarded"] != int64(0) {
			t.Fatalf("act %d awarded at zero favor", i+1)
		}
	}

	response = libraryCall(t, p, a, 844, map[string]any{"partner_id": int64(1), "act_id": int64(1)})
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("locked act status %d body %+v", response.HTTPStatus, response.Body)
	}

	setLibraryFavor(t, p, a, 1, 100)
	awardOperation := op()
	response = libraryDispatch(t, p, a, 844, map[string]any{"partner_id": int64(1), "act_id": int64(1)}, awardOperation)
	if response.HTTPStatus != 200 || response.Body["favor_degree"] != int64(105) {
		t.Fatalf("act award status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = libraryDispatch(t, p, a, 844, map[string]any{"partner_id": int64(1), "act_id": int64(1)}, awardOperation)
	if response.HTTPStatus != 200 || response.Body["favor_degree"] != int64(105) {
		t.Fatalf("act award replay status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = libraryCall(t, p, a, 844, map[string]any{"partner_id": int64(1), "act_id": int64(1)})
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("second act award status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = libraryCall(t, p, a, 844, map[string]any{"partner_id": int64(1), "act_id": int64(2)})
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("act 2 before favor 300 status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = libraryCall(t, p, a, 844, map[string]any{"partner_id": int64(1), "act_id": int64(5)})
	if response.HTTPStatus != 400 {
		t.Fatalf("act 5 status %d body %+v", response.HTTPStatus, response.Body)
	}

	setLibraryFavor(t, p, a, 1, 300)
	response = libraryCall(t, p, a, 844, map[string]any{"partner_id": int64(1), "act_id": int64(2)})
	if response.HTTPStatus != 200 || response.Body["favor_degree"] != int64(305) {
		t.Fatalf("act 2 award status %d body %+v", response.HTTPStatus, response.Body)
	}

	response = libraryCall(t, p, a, 842, map[string]any{"partner_id": int64(1)})
	acts = response.Body["partner_acts"].([]any)
	for i, want := range []int64{1, 1, 0, 0} {
		if got := acts[i].(map[string]any)["is_awarded"]; got != want {
			t.Fatalf("act %d is_awarded %v want %d", i+1, got, want)
		}
	}
	facts, e := (librarystore.Store{}).ReadHeroTx(ctx, p, character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1})
	if e != nil || facts.Favor != 305 {
		t.Fatalf("stored favor %+v %v", facts, e)
	}
	awards, e := (librarystore.Store{}).ListActAwardsTx(ctx, p, a.PlayerID)
	if e != nil || len(awards) != 2 || awards[0].ActID != 1 || awards[1].ActID != 2 {
		t.Fatalf("act award rows %+v %v", awards, e)
	}
}
