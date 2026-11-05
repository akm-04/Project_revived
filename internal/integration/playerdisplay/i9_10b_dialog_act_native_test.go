//go:build postgres

package playerdisplay_test

import (
	"context"
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	app "gxb.local/backend/v2/internal/application/librarylocal"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
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
	typed, ok := body["partner_dialogs"].([]app.DialogRow)
	if !ok {
		t.Fatalf("partner_dialogs %T", body["partner_dialogs"])
	}
	rows := make([]map[string]any, 0, len(typed))
	for _, row := range typed {
		rows = append(rows, map[string]any{"dialog_id": row.DialogID, "is_read": row.IsRead, "is_awarded": row.IsAwarded, "select_id": row.SelectID})
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
	acts, ok := response.Body["partner_acts"].([]app.ActSlot)
	if !ok || len(acts) != 4 {
		t.Fatalf("partner_acts %T %+v", response.Body["partner_acts"], response.Body["partner_acts"])
	}
	for i, act := range acts {
		if act.IsAwarded != int64(0) {
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
	acts = response.Body["partner_acts"].([]app.ActSlot)
	for i, want := range []int64{1, 1, 0, 0} {
		if got := acts[i].IsAwarded; got != want {
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

func TestI9_10B836And838ShareDialogProjection(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	at := time.Now().UTC().Add(-time.Minute).Truncate(time.Microsecond)
	store := librarystore.Store{}
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if e = store.SaveDialogTx(ctx, tr, lib.DialogFact{PlayerID: a.PlayerID, PartnerID: 1, DialogID: 3, IsRead: true, IsAwarded: true, SelectID: 9, UpdatedAt: at}); e != nil {
		t.Fatal(e)
	}
	// A retained row outside the catalog is not a known contextual dialog.
	if e = store.SaveDialogTx(ctx, tr, lib.DialogFact{PlayerID: a.PlayerID, PartnerID: 1, DialogID: 999, IsRead: true, UpdatedAt: at}); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}

	s := libraryService(p, p)
	body836, e := s.Read(ctx, a, op(), 836, 0)
	if e != nil {
		t.Fatal(e)
	}
	row := body836["library_infos"].(map[string]any)["1"].(map[string]any)
	from836 := row["partner_dialogs"].([]app.DialogRow)
	response := libraryCall(t, p, a, 838, map[string]any{"partner_id": int64(1)})
	if response.HTTPStatus != 200 {
		t.Fatalf("838 status %d body %+v", response.HTTPStatus, response.Body)
	}
	if !reflect.DeepEqual(from836, response.Body["partner_dialogs"]) {
		t.Fatalf("836 %+v differs from 838 %+v", from836, response.Body["partner_dialogs"])
	}
	if len(from836) != 2 || from836[0].DialogID != int64(1) || from836[1].DialogID != int64(3) {
		t.Fatalf("sorted dialog union %+v", from836)
	}
	stored, e := store.ListDialogsTx(ctx, p, a.PlayerID)
	if e != nil || len(stored) != 2 {
		t.Fatalf("reads wrote dialog rows %+v %v", stored, e)
	}

	if response := libraryDispatch(t, p, a, 837, map[string]any{"partner_id": int64(1), "dialog_id": int64(1)}, op()); response.HTTPStatus != 200 {
		t.Fatalf("837 status %d body %+v", response.HTTPStatus, response.Body)
	}
	body836, e = s.Read(ctx, a, op(), 836, 0)
	if e != nil {
		t.Fatal(e)
	}
	from836 = body836["library_infos"].(map[string]any)["1"].(map[string]any)["partner_dialogs"].([]app.DialogRow)
	response = libraryCall(t, p, a, 838, map[string]any{"partner_id": int64(1)})
	if !reflect.DeepEqual(from836, response.Body["partner_dialogs"]) {
		t.Fatalf("after read 836 %+v differs from 838 %+v", from836, response.Body["partner_dialogs"])
	}
	opened, retained := from836[0], from836[1]
	if opened.DialogID != int64(1) || opened.IsRead != int64(1) || opened.IsAwarded != int64(0) {
		t.Fatalf("read state lost %+v", opened)
	}
	if retained.DialogID != int64(3) || retained.IsRead != int64(1) || retained.IsAwarded != int64(1) || retained.SelectID != int64(9) {
		t.Fatalf("retained state lost %+v", retained)
	}
}

func TestI9_10B840PostGiftProjectionAndExactRetry(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	setLibraryFavor(t, p, a, 1, 100)
	at := time.Now().UTC().Add(-time.Minute).Truncate(time.Microsecond)
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if _, e = (librarystore.Store{}).InsertActAwardTx(ctx, tr, lib.ActAwardFact{PlayerID: a.PlayerID, PartnerID: 1, ActID: 1, AwardedAt: at}); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	if response := libraryDispatch(t, p, a, 837, map[string]any{"partner_id": int64(1), "dialog_id": int64(1)}, op()); response.HTTPStatus != 200 {
		t.Fatalf("837 status %d body %+v", response.HTTPStatus, response.Body)
	}
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,50005011,1,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour') ON CONFLICT(player_id,item_id) DO UPDATE SET quantity=1,updated_at=clock_timestamp()-interval '1 hour'`, int64(a.PlayerID))

	giftOperation := op()
	response := libraryDispatch(t, p, a, 840, map[string]any{"partner_id": int64(1), "gift_id": int64(50005011), "gift_num": int64(1)}, giftOperation)
	if response.HTTPStatus != 200 || response.Body["favor_degree"] != int64(113) {
		t.Fatalf("840 status %d body %+v", response.HTTPStatus, response.Body)
	}
	dialogs, ok := response.Body["partner_dialogs"].([]app.DialogRow)
	if !ok || len(dialogs) != 3 {
		t.Fatalf("post-gift dialogs %T %+v", response.Body["partner_dialogs"], response.Body["partner_dialogs"])
	}
	for index, wantID := range []int64{1, 2, 12} {
		if got := dialogs[index].DialogID; got != wantID {
			t.Fatalf("post-gift dialog %d id %v want %d", index, got, wantID)
		}
	}
	if read := dialogs[0].IsRead; read != int64(1) {
		t.Fatalf("pre-read dialog state lost %+v", dialogs[0])
	}
	acts, ok := response.Body["partner_acts"].([]app.ActSlot)
	if !ok || len(acts) != lib.ActCount {
		t.Fatalf("post-gift acts %T %+v", response.Body["partner_acts"], response.Body["partner_acts"])
	}
	for index, want := range []int64{1, 0, 0, 0} {
		if got := acts[index].IsAwarded; got != want {
			t.Fatalf("post-gift act %d %v want %d", index+1, got, want)
		}
	}
	capturedDialogs := append([]app.DialogRow(nil), dialogs...)
	capturedActs := append([]app.ActSlot(nil), acts...)

	// Later state must not leak into the receipt replay.
	setLibraryFavor(t, p, a, 1, 200)
	retry := libraryDispatch(t, p, a, 840, map[string]any{"partner_id": int64(1), "gift_id": int64(50005011), "gift_num": int64(1)}, giftOperation)
	if retry.HTTPStatus != 200 || retry.Body["favor_degree"] != int64(113) {
		t.Fatalf("840 retry status %d body %+v", retry.HTTPStatus, retry.Body)
	}
	if !reflect.DeepEqual(capturedDialogs, retry.Body["partner_dialogs"]) {
		t.Fatalf("retry dialogs %+v want %+v", retry.Body["partner_dialogs"], capturedDialogs)
	}
	if !reflect.DeepEqual(capturedActs, retry.Body["partner_acts"]) {
		t.Fatalf("retry acts %+v want %+v", retry.Body["partner_acts"], capturedActs)
	}
}

func TestI9_10BFavorProducersFailClosedWithoutFacts(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	service := libraryService(p, p)
	service.Facts = nil
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,50005011,1,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour') ON CONFLICT(player_id,item_id) DO UPDATE SET quantity=1,updated_at=clock_timestamp()-interval '1 hour'`, int64(a.PlayerID))

	response := libraryDispatchService(t, a, service, 840, map[string]any{"partner_id": int64(1), "gift_id": int64(50005011), "gift_num": int64(1)}, op())
	if response.HTTPStatus != 503 || response.Body["error"] != "library_unavailable" {
		t.Fatalf("840 without Facts status %d body %+v", response.HTTPStatus, response.Body)
	}
	facts, e := (librarystore.Store{}).ReadHeroTx(ctx, p, character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1})
	if e != nil || facts.Favor != 0 {
		t.Fatalf("favor moved without Facts %+v %v", facts, e)
	}
	var quantity int64
	if e = p.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=50005011`, int64(a.PlayerID)).Scan(&quantity); e != nil || quantity != 1 {
		t.Fatalf("gift stack moved without Facts %d %v", quantity, e)
	}

	setLibraryFavor(t, p, a, 1, 100)
	response = libraryDispatchService(t, a, service, 844, map[string]any{"partner_id": int64(1), "act_id": int64(1)}, op())
	if response.HTTPStatus != 503 {
		t.Fatalf("844 without Facts status %d body %+v", response.HTTPStatus, response.Body)
	}
	awards, e := (librarystore.Store{}).ListActAwardsTx(ctx, p, a.PlayerID)
	if e != nil || len(awards) != 0 {
		t.Fatalf("act award written without Facts %+v %v", awards, e)
	}
	facts, e = (librarystore.Store{}).ReadHeroTx(ctx, p, character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1})
	if e != nil || facts.Favor != 100 {
		t.Fatalf("act favor moved without Facts %+v %v", facts, e)
	}

	response = libraryDispatchService(t, a, service, 843, map[string]any{"partner_id": int64(1), "dialog_id": int64(2), "select_info": "1|42"}, op())
	if response.HTTPStatus != 503 {
		t.Fatalf("843 without Facts status %d body %+v", response.HTTPStatus, response.Body)
	}
	if _, found, e := (librarystore.Store{}).ReadDialogTx(ctx, p, a.PlayerID, 1, 2); e != nil || found {
		t.Fatalf("talk dialog written without Facts found=%v %v", found, e)
	}
	facts, e = (librarystore.Store{}).ReadHeroTx(ctx, p, character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1})
	if e != nil || facts.Favor != 100 {
		t.Fatalf("talk favor moved without Facts %+v %v", facts, e)
	}
}
