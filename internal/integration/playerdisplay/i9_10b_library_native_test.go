//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	app "gxb.local/backend/v2/internal/application/librarylocal"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestI9_10BStoreFacetsRoundTrip(t *testing.T) {
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
	dialog := lib.DialogFact{PlayerID: a.PlayerID, PartnerID: 1, DialogID: 3, IsRead: true, IsAwarded: true, SelectID: 9, UpdatedAt: at}
	mission := lib.MissionFact{PlayerID: a.PlayerID, PartnerID: 1, MissionID: 1001, Process: 1, MissionState: 2, UpdatedAt: at}
	award := lib.ActAwardFact{PlayerID: a.PlayerID, PartnerID: 1, ActID: 2, AwardedAt: at}
	talk := lib.TalkClaimFact{PlayerID: a.PlayerID, TalkID: 1001, ClaimedAt: at}
	cg := lib.CGClaimFact{PlayerID: a.PlayerID, CGID: 1, ClaimedAt: at}
	owned := lib.BackgroundFact{PlayerID: a.PlayerID, BgID: 3, UnlockedAt: at}
	if e = store.SaveDialogTx(ctx, tr, dialog); e != nil {
		t.Fatal(e)
	}
	if e = store.SaveMissionTx(ctx, tr, mission); e != nil {
		t.Fatal(e)
	}
	if inserted, err := store.InsertActAwardTx(ctx, tr, award); err != nil || !inserted {
		t.Fatal("act award", inserted, err)
	}
	if inserted, err := store.InsertTalkClaimTx(ctx, tr, talk); err != nil || !inserted {
		t.Fatal("talk claim", inserted, err)
	}
	if inserted, err := store.InsertCGClaimTx(ctx, tr, cg); err != nil || !inserted {
		t.Fatal("cg claim", inserted, err)
	}
	if inserted, err := store.UnlockBackgroundTx(ctx, tr, owned); err != nil || !inserted {
		t.Fatal("background", inserted, err)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	dialogs, e := store.ListDialogsTx(ctx, p, a.PlayerID)
	if e != nil || len(dialogs) != 1 || dialogs[0] != (lib.DialogFact{PlayerID: a.PlayerID, PartnerID: 1, DialogID: 3, IsRead: true, IsAwarded: true, SelectID: 9, UpdatedAt: dialogs[0].UpdatedAt}) || !dialogs[0].UpdatedAt.Equal(at) {
		t.Fatalf("dialogs %+v %v", dialogs, e)
	}
	missions, e := store.ListMissionsTx(ctx, p, a.PlayerID)
	if e != nil || len(missions) != 1 || missions[0].MissionID != 1001 || missions[0].Process != 1 || missions[0].MissionState != 2 {
		t.Fatalf("missions %+v %v", missions, e)
	}
	awards, e := store.ListActAwardsTx(ctx, p, a.PlayerID)
	if e != nil || len(awards) != 1 || awards[0].ActID != 2 {
		t.Fatalf("awards %+v %v", awards, e)
	}
	talks, e := store.ListTalkClaimsTx(ctx, p, a.PlayerID)
	if e != nil || len(talks) != 1 || talks[0].TalkID != 1001 {
		t.Fatalf("talks %+v %v", talks, e)
	}
	cgs, e := store.ListCGClaimsTx(ctx, p, a.PlayerID)
	if e != nil || len(cgs) != 1 || cgs[0].CGID != 1 {
		t.Fatalf("cgs %+v %v", cgs, e)
	}
	backgrounds, e := store.ListBackgroundsTx(ctx, p, a.PlayerID)
	if e != nil || len(backgrounds) != 1 || backgrounds[0].BgID != 3 {
		t.Fatalf("backgrounds %+v %v", backgrounds, e)
	}
	tr2, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr2.Rollback(ctx)
	if inserted, err := store.InsertActAwardTx(ctx, tr2, award); err != nil || inserted {
		t.Fatal("act award replay must not insert", inserted, err)
	}
	if inserted, err := store.InsertTalkClaimTx(ctx, tr2, talk); err != nil || inserted {
		t.Fatal("talk replay must not insert", inserted, err)
	}
}

func TestI9_10BLibrary836FullPayload(t *testing.T) {
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
	root, e := store.LockRootTx(ctx, tr, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	old := root.StateVersion
	root.BoardPartner, root.BoardCard, root.BoardModelID = 1, 2, 42
	root.BgMain, root.BgRoom = 3, 4
	root.StateVersion++
	root.UpdatedAt = at
	if e = store.SavePlayerTx(ctx, tr, root, old); e != nil {
		t.Fatal(e)
	}
	if e = store.SaveDialogTx(ctx, tr, lib.DialogFact{PlayerID: a.PlayerID, PartnerID: 1, DialogID: 3, IsRead: true, IsAwarded: true, SelectID: 9, UpdatedAt: at}); e != nil {
		t.Fatal(e)
	}
	if e = store.SaveMissionTx(ctx, tr, lib.MissionFact{PlayerID: a.PlayerID, PartnerID: 1, MissionID: 1001, Process: 1, MissionState: 2, UpdatedAt: at}); e != nil {
		t.Fatal(e)
	}
	if _, e = store.InsertActAwardTx(ctx, tr, lib.ActAwardFact{PlayerID: a.PlayerID, PartnerID: 1, ActID: 2, AwardedAt: at}); e != nil {
		t.Fatal(e)
	}
	if _, e = store.InsertTalkClaimTx(ctx, tr, lib.TalkClaimFact{PlayerID: a.PlayerID, TalkID: 1001, ClaimedAt: at}); e != nil {
		t.Fatal(e)
	}
	if _, e = store.InsertCGClaimTx(ctx, tr, lib.CGClaimFact{PlayerID: a.PlayerID, CGID: 1, ClaimedAt: at}); e != nil {
		t.Fatal(e)
	}
	if _, e = store.UnlockBackgroundTx(ctx, tr, lib.BackgroundFact{PlayerID: a.PlayerID, BgID: 3, UnlockedAt: at}); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	s := libraryService(p, p)
	body, e := s.Read(ctx, a, op(), 836, 0)
	if e != nil {
		t.Fatal(e)
	}
	infos, ok := body["library_infos"].(map[string]any)
	if !ok {
		t.Fatalf("library_infos %T", body["library_infos"])
	}
	row, ok := infos["1"].(map[string]any)
	if !ok {
		t.Fatalf("partner row %T", infos["1"])
	}
	if row["favor_degree"] != int64(0) || row["is_married"] != int64(0) {
		t.Fatalf("favor row %+v", row)
	}
	dialogs, ok := row["partner_dialogs"].([]app.DialogRow)
	if !ok || len(dialogs) != 3 {
		t.Fatalf("partner_dialogs %T %+v", row["partner_dialogs"], row["partner_dialogs"])
	}
	if opened := dialogs[0]; opened.DialogID != int64(1) || opened.IsRead != int64(0) || opened.IsAwarded != int64(0) || opened.SelectID != int64(0) {
		t.Fatalf("statically opened dialog row %+v", opened)
	}
	dialog := dialogs[1]
	if dialog.DialogID != int64(3) || dialog.IsRead != int64(1) || dialog.IsAwarded != int64(1) || dialog.SelectID != int64(9) {
		t.Fatalf("dialog row %+v", dialog)
	}
	if dialogs[2].DialogID != int64(12) {
		t.Fatalf("act 1 dialog missing %+v", dialogs)
	}
	missions, ok := row["partner_missions"].([]any)
	if !ok || len(missions) != 1 {
		t.Fatalf("partner_missions %T %+v", row["partner_missions"], row["partner_missions"])
	}
	mission := missions[0].(map[string]any)
	if mission["mission_id"] != int64(1001) || mission["process"] != int64(1) || mission["mission_state"] != int64(2) {
		t.Fatalf("mission row %+v", mission)
	}
	acts, ok := row["partner_acts"].([]app.ActSlot)
	if !ok || len(acts) != 1 {
		t.Fatalf("partner_acts %T %+v", row["partner_acts"], row["partner_acts"])
	}
	if acts[0].IsAwarded != int64(0) {
		t.Fatalf("act 1 is_awarded %v", acts[0].IsAwarded)
	}
	// The fresh facet records the acquisition milestone (type 1).
	logs, ok := row["partner_logs"].(map[string]any)
	if !ok || len(logs) != 1 {
		t.Fatalf("partner_logs %T %+v", row["partner_logs"], row["partner_logs"])
	}
	if _, present := logs["10001"]; !present {
		t.Fatalf("acquisition log missing %+v", logs)
	}
	talks, ok := body["library_talk_infos"].(map[string]any)
	if !ok || len(talks) != 23 || talks["1001"] != int64(1) || talks["1002"] != int64(0) {
		t.Fatalf("library_talk_infos %T len=%d", body["library_talk_infos"], len(talks))
	}
	cgs, ok := body["library_cg_infos"].([]int64)
	if !ok || len(cgs) != 1 || cgs[0] != 1 {
		t.Fatalf("library_cg_infos %T %+v", body["library_cg_infos"], body["library_cg_infos"])
	}
	bg, ok := body["library_bg_infos"].(map[string]any)
	if !ok || bg["bg_main"] != int64(3) || bg["bg_room"] != int64(4) || bg["server_time"].(int64) <= 0 {
		t.Fatalf("library_bg_infos %+v", body["library_bg_infos"])
	}
	hasBuy, ok := bg["has_buy"].([]int64)
	if !ok || len(hasBuy) != 1 || hasBuy[0] != 3 {
		t.Fatalf("has_buy %T %+v", bg["has_buy"], bg["has_buy"])
	}
}

func TestI9_10BLibrary836TalkMapAlwaysPresent(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	s := libraryService(p, p)
	body, e := s.Read(ctx, a, op(), 836, 0)
	if e != nil {
		t.Fatal(e)
	}
	talks, ok := body["library_talk_infos"].(map[string]any)
	if !ok {
		t.Fatalf("library_talk_infos absent or %T", body["library_talk_infos"])
	}
	if len(talks) != 23 || talks["1001"] != int64(0) {
		t.Fatalf("library_talk_infos len=%d", len(talks))
	}
}

func TestI9_10BMID1BoardFields(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	bornHero(t, p, a, rev, 10001002, 2)
	at := time.Now().UTC().Add(-time.Minute).Truncate(time.Microsecond)
	store := librarystore.Store{}
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	root, e := store.LockRootTx(ctx, tr, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	old := root.StateVersion
	root.BoardPartner, root.BoardCard, root.BoardModelID = 1, 2, 42
	root.StateVersion++
	root.UpdatedAt = at
	if e = store.SavePlayerTx(ctx, tr, root, old); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	s := libraryService(p, p)
	body, e := s.Read(ctx, a, op(), 49, 0)
	if e != nil {
		t.Fatal(e)
	}
	heros, ok := body["heros"].(map[string]any)
	if !ok {
		t.Fatalf("heros %T", body["heros"])
	}
	board := heros["1"].(map[string]any)
	if board["is_board"] != int64(1) || board["board_card"] != int64(2) || board["board_model_id"] != int64(42) {
		t.Fatalf("board hero row %+v", board)
	}
	if board["favor_degree"] != int64(0) || board["is_married"] != int64(0) || board["collect_quality_stage"] != int64(0) || board["collect_star_stage"] != int64(0) {
		t.Fatalf("library fields %+v", board)
	}
	if _, ok := board["feed_attrs"].(lib.FeedAttrs); !ok {
		t.Fatalf("feed_attrs %T", board["feed_attrs"])
	}
	plain := heros["2"].(map[string]any)
	if plain["is_board"] != int64(0) || plain["board_card"] != int64(1) || plain["board_model_id"] != int64(0) {
		t.Fatalf("plain hero row %+v", plain)
	}
}
