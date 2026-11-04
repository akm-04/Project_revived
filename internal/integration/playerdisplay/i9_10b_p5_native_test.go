//go:build postgres

package playerdisplay_test

import (
	"context"
	"reflect"
	"strconv"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	i5 "gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/librarylocal"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func libraryP5Service(p *pg.Pool) app.Service {
	service := libraryGrantService(p)
	service.Stacks = i5store.Store{Queryer: p}
	service.Skins = characterstore.Store{Queryer: p}
	return service
}

func p5StackQuantity(t *testing.T, p *pg.Pool, player identity.PlayerID, itemID int64) int64 {
	t.Helper()
	var quantity int64
	if e := p.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2`, int64(player), itemID).Scan(&quantity); e != nil {
		t.Fatal(e)
	}
	return quantity
}

func p5CrystalBalance(t *testing.T, p *pg.Pool, player identity.PlayerID) int64 {
	t.Helper()
	var amount int64
	if e := p.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(player)).Scan(&amount); e != nil {
		t.Fatal(e)
	}
	return amount
}

func seedStack(t *testing.T, p *pg.Pool, a identity.ActorContext, rev string, itemID, amount int64) {
	t.Helper()
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "i9-10b-fixture", Operation: "p5-stack-seed", BusinessKey: "i9-10b:p5:" + strconv.FormatInt(int64(a.PlayerID), 10), Occurrence: op().ID.String(), PolicyVersion: "i9-10b-fixture-v1"}, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: itemID, Amount: amount}}}
	if _, e = compositeI5(p).SettleGrantTx(ctx, tr, a, plan, opPinned(rev), i5.GrantTxOptions{}); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
}

func saveSkinEntitlement(t *testing.T, p *pg.Pool, a identity.ActorContext, partner, model int64) character.Hero {
	t.Helper()
	at := time.Now().UTC().Add(-time.Minute).Truncate(time.Microsecond)
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	store := characterstore.Store{}
	h, e := store.LockHeroByPartnerIDTx(ctx, tr, a.PlayerID, partner)
	if e != nil {
		t.Fatal(e)
	}
	old := h.StateVersion
	h.StateVersion++
	h.UpdatedAt = at
	if e = store.SaveHeroSkinEntitlementTx(ctx, tr, h, character.HeroSkinEntitlement{PlayerID: a.PlayerID, PartnerID: partner, ModelID: model}, old); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	return h
}

func TestI9_10B839BuyGiftDebitCreditAndOwnedCount(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := bornActor(t, p)
	service := libraryP5Service(p)
	const giftID = int64(50005011)
	const giftPrice = int64(50)

	purchaseOperation := op()
	response := libraryDispatchService(t, a, service, 839, map[string]any{"gift_id": giftID, "gift_num": int64(1)}, purchaseOperation)
	if response.HTTPStatus != 200 || response.Body["gift_id"] != giftID || response.Body["gift_num"] != int64(1) {
		t.Fatalf("839 first status %d body %+v", response.HTTPStatus, response.Body)
	}
	if got := p5CrystalBalance(t, p, a.PlayerID); got != 1000-giftPrice {
		t.Fatalf("crystal %d", got)
	}
	if got := p5StackQuantity(t, p, a.PlayerID, giftID); got != 1 {
		t.Fatalf("gift stack %d", got)
	}
	response = libraryDispatchService(t, a, service, 839, map[string]any{"gift_id": giftID, "gift_num": int64(1)}, purchaseOperation)
	if response.HTTPStatus != 200 || response.Body["gift_num"] != int64(1) {
		t.Fatalf("839 replay status %d body %+v", response.HTTPStatus, response.Body)
	}
	if got := p5CrystalBalance(t, p, a.PlayerID); got != 1000-giftPrice {
		t.Fatalf("crystal after replay %d", got)
	}
	response = libraryDispatchService(t, a, service, 839, map[string]any{"gift_id": giftID, "gift_num": int64(1)}, op())
	if response.HTTPStatus != 200 || response.Body["gift_num"] != int64(2) {
		t.Fatalf("839 second status %d body %+v", response.HTTPStatus, response.Body)
	}
	if got := p5CrystalBalance(t, p, a.PlayerID); got != 1000-2*giftPrice {
		t.Fatalf("crystal after second %d", got)
	}
	if got := p5StackQuantity(t, p, a.PlayerID, giftID); got != 2 {
		t.Fatalf("gift stack after second %d", got)
	}

	response = libraryDispatchService(t, a, service, 839, map[string]any{"gift_id": int64(50009999), "gift_num": int64(1)}, op())
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("unknown gift status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = libraryDispatchService(t, a, service, 839, map[string]any{"gift_id": giftID, "gift_num": int64(2)}, op())
	if response.HTTPStatus != 400 {
		t.Fatalf("gift_num 2 status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = libraryDispatchService(t, a, service, 839, map[string]any{"gift_id": giftID, "gift_num": int64(1), "partner_id": int64(1)}, op())
	if response.HTTPStatus != 400 {
		t.Fatalf("839 partner param status %d body %+v", response.HTTPStatus, response.Body)
	}
	before := p5CrystalBalance(t, p, a.PlayerID)
	response = libraryDispatchService(t, a, service, 839, map[string]any{"gift_id": int64(50001112), "gift_num": int64(1)}, op())
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("ring without crystal status %d body %+v", response.HTTPStatus, response.Body)
	}
	if got := p5CrystalBalance(t, p, a.PlayerID); got != before {
		t.Fatalf("failed purchase moved crystal %d -> %d", before, got)
	}
}

func TestI9_10B835BoardSetResetAndMID1(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	bornHero(t, p, a, rev, 10001002, 2)
	service := libraryP5Service(p)

	setOperation := op()
	response := libraryDispatchService(t, a, service, 835, map[string]any{"partner_id": int64(1), "card_status": int64(1), "board_model_id": int64(10001001)}, setOperation)
	if response.HTTPStatus != 200 || response.Body["board_partner"] != int64(1) || response.Body["board_card"] != int64(1) || response.Body["board_model_id"] != int64(10001001) {
		t.Fatalf("835 set status %d body %+v", response.HTTPStatus, response.Body)
	}
	body, e := service.Read(ctx, a, op(), 49, 0)
	if e != nil {
		t.Fatal(e)
	}
	heros := body["heros"].(map[string]any)
	board := heros["1"].(map[string]any)
	if board["is_board"] != int64(1) || board["board_card"] != int64(1) || board["board_model_id"] != int64(10001001) {
		t.Fatalf("MID1 board row %+v", board)
	}
	plain := heros["2"].(map[string]any)
	if plain["is_board"] != int64(0) || plain["board_card"] != int64(1) || plain["board_model_id"] != int64(0) {
		t.Fatalf("MID1 plain row %+v", plain)
	}

	response = libraryDispatchService(t, a, service, 835, map[string]any{"partner_id": int64(1), "card_status": int64(1), "board_model_id": int64(10001001)}, op())
	if response.HTTPStatus != 200 || response.Body["board_partner"] != int64(0) || response.Body["board_card"] != int64(0) || response.Body["board_model_id"] != int64(0) {
		t.Fatalf("835 reset status %d body %+v", response.HTTPStatus, response.Body)
	}
	root, e := (librarystore.Store{}).ReadRootTx(ctx, p, a.PlayerID)
	if e != nil || root.BoardPartner != 0 || root.BoardCard != 0 || root.BoardModelID != 0 {
		t.Fatalf("stored reset %+v %v", root, e)
	}

	response = libraryDispatchService(t, a, service, 835, map[string]any{"partner_id": int64(1), "card_status": int64(3), "board_model_id": int64(11001001)}, op())
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("unawakened card status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = libraryDispatchService(t, a, service, 835, map[string]any{"partner_id": int64(1), "card_status": int64(2), "board_model_id": int64(40001001)}, op())
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("unowned skin status %d body %+v", response.HTTPStatus, response.Body)
	}
	saveSkinEntitlement(t, p, a, 1, 40001001)
	response = libraryDispatchService(t, a, service, 835, map[string]any{"partner_id": int64(1), "card_status": int64(2), "board_model_id": int64(40001001)}, op())
	if response.HTTPStatus != 200 || response.Body["board_card"] != int64(2) || response.Body["board_model_id"] != int64(40001001) {
		t.Fatalf("owned skin status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = libraryDispatchService(t, a, service, 835, map[string]any{"partner_id": int64(99), "card_status": int64(1), "board_model_id": int64(10001001)}, op())
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("unowned hero status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = libraryDispatchService(t, a, service, 835, map[string]any{"partner_id": int64(1), "card_status": int64(4), "board_model_id": int64(10001001)}, op())
	if response.HTTPStatus != 400 {
		t.Fatalf("card 4 status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = libraryDispatchService(t, a, service, 835, map[string]any{"partner_id": int64(1), "card_status": int64(1)}, op())
	if response.HTTPStatus != 400 {
		t.Fatalf("missing model status %d body %+v", response.HTTPStatus, response.Body)
	}
}

func TestI9_10B835BoardCardModelSource(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	expect := func(a identity.ActorContext, service app.Service, partner, card, model int64, status int) {
		t.Helper()
		response := libraryDispatchService(t, a, service, 835, map[string]any{"partner_id": partner, "card_status": card, "board_model_id": model}, op())
		if response.HTTPStatus != status {
			t.Fatalf("board partner %d card %d model %d status %d body %+v", partner, card, model, response.HTTPStatus, response.Body)
		}
	}

	base := bornActor(t, p)
	bornHero(t, p, base, rev, 10001001, 1)
	baseService := libraryP5Service(p)
	expect(base, baseService, 1, 1, 10001001, 200)
	expect(base, baseService, 1, 1, 10001002, 409)
	expect(base, baseService, 1, 3, 11001001, 409)

	transformed := bornActor(t, p)
	bornHeroCard(t, p, transformed, rev, 11001001, 10001001, 1)
	transformedService := libraryP5Service(p)
	expect(transformed, transformedService, 1, 1, 10001001, 200)
	expect(transformed, transformedService, 1, 1, 11001001, 409)
	expect(transformed, transformedService, 1, 3, 11001001, 200)
	expect(transformed, transformedService, 1, 3, 10001001, 409)

	// 10001042 has an awake target row but raw awaken 0, so the awake card is closed.
	noAwaken := bornActor(t, p)
	bornHeroCard(t, p, noAwaken, rev, 11001042, 10001042, 1)
	expect(noAwaken, libraryP5Service(p), 1, 3, 11001042, 409)

	super := bornActor(t, p)
	bornHero(t, p, super, rev, 11001, 1)
	superService := libraryP5Service(p)
	expect(super, superService, 1, 1, 11001, 200)
	expect(super, superService, 1, 3, 11001, 409)
	expect(super, superService, 1, 1, 11002, 409)
}

type metadataLessLibraryContent struct{ app.ContentPort }

func (m metadataLessLibraryContent) LibraryCatalogTx(ctx context.Context, q tx.Queryer, revision string) (lib.Catalog, error) {
	catalog, e := m.ContentPort.LibraryCatalogTx(ctx, q, revision)
	if e != nil {
		return catalog, e
	}
	for tableID, template := range catalog.Templates {
		template.ModelID, template.AwakenTableID, template.Awaken = 0, 0, 0
		catalog.Templates[tableID] = template
	}
	return catalog, nil
}

func TestI9_10B835BoardReceiptSurvivesMissingCardMetadata(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	service := libraryFactService(p)
	command := map[string]any{"partner_id": int64(1), "card_status": int64(1), "board_model_id": int64(10001001)}

	setOperation := op()
	first := libraryDispatchService(t, a, service, 835, command, setOperation)
	if first.HTTPStatus != 200 || first.Body["board_partner"] != int64(1) || first.Body["board_card"] != int64(1) || first.Body["board_model_id"] != int64(10001001) {
		t.Fatalf("set status %d body %+v", first.HTTPStatus, first.Body)
	}

	service.Content = metadataLessLibraryContent{ContentPort: service.Content}
	replay := libraryDispatchService(t, a, service, 835, command, setOperation)
	if replay.HTTPStatus != 200 || !reflect.DeepEqual(first.Body, replay.Body) {
		t.Fatalf("replay status %d body %+v want %+v", replay.HTTPStatus, replay.Body, first.Body)
	}

	failed := libraryDispatchService(t, a, service, 835, command, op())
	if failed.HTTPStatus != 409 || failed.Body["error_code"] != int64(1) {
		t.Fatalf("missing metadata mutation status %d body %+v", failed.HTTPStatus, failed.Body)
	}
	root, e := (librarystore.Store{}).ReadRootTx(ctx, p, a.PlayerID)
	if e != nil || root.BoardPartner != 1 || root.BoardCard != 1 || root.BoardModelID != 10001001 {
		t.Fatalf("stored board after refusal %+v %v", root, e)
	}

	read := libraryDispatchService(t, a, service, 836, nil, op())
	if read.HTTPStatus != 200 || read.Body["library_infos"] == nil || read.Body["library_talk_infos"] == nil {
		t.Fatalf("836 with old metadata status %d body %+v", read.HTTPStatus, read.Body)
	}

	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,50005011,1,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour') ON CONFLICT(player_id,item_id) DO UPDATE SET quantity=1,updated_at=clock_timestamp()-interval '1 hour'`, int64(a.PlayerID))
	gift := libraryDispatchService(t, a, service, 840, map[string]any{"partner_id": int64(1), "gift_id": int64(50005011), "gift_num": int64(1)}, op())
	if gift.HTTPStatus != 200 {
		t.Fatalf("840 with old metadata status %d body %+v", gift.HTTPStatus, gift.Body)
	}

	setLibraryFavor(t, p, a, 1, 100)
	talk := libraryDispatchService(t, a, service, 843, map[string]any{"partner_id": int64(1), "dialog_id": int64(2), "select_info": "0|203001"}, op())
	if talk.HTTPStatus != 200 {
		t.Fatalf("843 with old metadata status %d body %+v", talk.HTTPStatus, talk.Body)
	}
}

func TestI9_10B855CGClaimOnce(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := bornActor(t, p)
	service := libraryP5Service(p)

	claimOperation := op()
	response := libraryDispatchService(t, a, service, 855, map[string]any{"index": int64(1)}, claimOperation)
	if response.HTTPStatus != 200 {
		t.Fatalf("855 status %d body %+v", response.HTTPStatus, response.Body)
	}
	awards, ok := response.Body["awards"].([]any)
	if !ok || len(awards) != 1 || awards[0].(map[string]any)["table_id"] != int64(50001648) || awards[0].(map[string]any)["item_num"] != int64(1) {
		t.Fatalf("855 awards %+v", response.Body["awards"])
	}
	if got := p5StackQuantity(t, p, a.PlayerID, 50001648); got != 1 {
		t.Fatalf("cg stack %d", got)
	}
	response = libraryDispatchService(t, a, service, 855, map[string]any{"index": int64(1)}, claimOperation)
	if response.HTTPStatus != 200 {
		t.Fatalf("855 replay status %d body %+v", response.HTTPStatus, response.Body)
	}
	if got := p5StackQuantity(t, p, a.PlayerID, 50001648); got != 1 {
		t.Fatalf("cg stack after replay %d", got)
	}
	response = libraryDispatchService(t, a, service, 855, map[string]any{"index": int64(1)}, op())
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("855 second claim status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = libraryDispatchService(t, a, service, 855, map[string]any{"index": int64(99)}, op())
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("855 unknown index status %d body %+v", response.HTTPStatus, response.Body)
	}
	body, e := service.Read(ctx, a, op(), 836, 0)
	if e != nil {
		t.Fatal(e)
	}
	cgInfos, ok := body["library_cg_infos"].([]int64)
	if !ok || len(cgInfos) != 1 || cgInfos[0] != 1 {
		t.Fatalf("836 cg infos %T %+v", body["library_cg_infos"], body["library_cg_infos"])
	}
}

func TestI9_10B856857Backgrounds(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	service := libraryP5Service(p)

	response := libraryDispatchService(t, a, service, 856, map[string]any{"bg_id": int64(3)}, op())
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("856 without item status %d body %+v", response.HTTPStatus, response.Body)
	}
	seedStack(t, p, a, rev, lib.BackgroundUnlockItemID, 2)

	unlockOperation := op()
	response = libraryDispatchService(t, a, service, 856, map[string]any{"bg_id": int64(3)}, unlockOperation)
	if response.HTTPStatus != 200 {
		t.Fatalf("856 status %d body %+v", response.HTTPStatus, response.Body)
	}
	if got := p5StackQuantity(t, p, a.PlayerID, lib.BackgroundUnlockItemID); got != 1 {
		t.Fatalf("unlock item after buy %d", got)
	}
	response = libraryDispatchService(t, a, service, 856, map[string]any{"bg_id": int64(3)}, unlockOperation)
	if response.HTTPStatus != 200 {
		t.Fatalf("856 replay status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = libraryDispatchService(t, a, service, 856, map[string]any{"bg_id": int64(3)}, op())
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("856 second unlock status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = libraryDispatchService(t, a, service, 856, map[string]any{"bg_id": int64(1)}, op())
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("856 free bg status %d body %+v", response.HTTPStatus, response.Body)
	}

	response = libraryDispatchService(t, a, service, 857, map[string]any{"_type": int64(1), "bg_id": int64(3)}, op())
	if response.HTTPStatus != 200 {
		t.Fatalf("857 owned status %d body %+v", response.HTTPStatus, response.Body)
	}
	root, e := (librarystore.Store{}).ReadRootTx(ctx, p, a.PlayerID)
	if e != nil || root.BgMain != 3 {
		t.Fatalf("bg main %+v %v", root, e)
	}
	response = libraryDispatchService(t, a, service, 857, map[string]any{"_type": int64(1), "bg_id": int64(3)}, op())
	if response.HTTPStatus != 200 {
		t.Fatalf("857 reset status %d body %+v", response.HTTPStatus, response.Body)
	}
	root, e = (librarystore.Store{}).ReadRootTx(ctx, p, a.PlayerID)
	if e != nil || root.BgMain != lib.DefaultBgMain {
		t.Fatalf("bg main after reset %+v %v", root, e)
	}
	response = libraryDispatchService(t, a, service, 857, map[string]any{"_type": int64(2), "bg_id": int64(4)}, op())
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("857 unowned paid bg status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = libraryDispatchService(t, a, service, 857, map[string]any{"_type": int64(1), "bg_id": int64(2)}, op())
	if response.HTTPStatus != 200 {
		t.Fatalf("857 free bg status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = libraryDispatchService(t, a, service, 857, map[string]any{"_type": int64(3), "bg_id": int64(1)}, op())
	if response.HTTPStatus != 400 {
		t.Fatalf("857 bad type status %d body %+v", response.HTTPStatus, response.Body)
	}
	body, e := service.Read(ctx, a, op(), 836, 0)
	if e != nil {
		t.Fatal(e)
	}
	bgInfos, ok := body["library_bg_infos"].(map[string]any)
	if !ok || bgInfos["bg_main"] != int64(2) || bgInfos["bg_room"] != int64(lib.DefaultBgRoom) {
		t.Fatalf("836 bg infos %+v", body["library_bg_infos"])
	}
	hasBuy, ok := bgInfos["has_buy"].([]int64)
	if !ok || len(hasBuy) != 1 || hasBuy[0] != 3 {
		t.Fatalf("836 has_buy %T %+v", bgInfos["has_buy"], bgInfos["has_buy"])
	}
}
