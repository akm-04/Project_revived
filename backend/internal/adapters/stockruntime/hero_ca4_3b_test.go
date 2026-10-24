package stockruntime

import (
	"context"
	"reflect"
	"testing"

	apphero "gxb.local/backend/v2/internal/application/characterhero"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
)

func TestCA43BMID49ProjectsDerivedFumoLevelsAfterReconnect(t *testing.T) {
	h := ca23Hero(character.NormalHero, 1001, 41, 5)
	h.Fumo = character.HeroFumoSlots{0, 20, 160, 1120, 1680, 3210}
	svc := &ca42HeroService{rosterRoot: character.HeroRoot{SortType: 3}, rosterViews: []apphero.HeroRosterView{{Hero: h, FumoLevels: character.HeroFumoSlots{0, 1, 2, 3, 4, 5}}}}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc}
	r := d.Dispatch(context.Background(), heroReq(t, 49, map[string]any{}))
	if r.HTTPStatus != 200 {
		t.Fatalf("response=%+v", r)
	}
	rows := r.Body["heros"].(map[string]any)
	hero := rows["41"].(map[string]any)
	want := []any{int64(0), int64(1), int64(2), int64(3), int64(4), int64(5)}
	if got, ok := hero["fumo_levels"].([]any); !ok || !reflect.DeepEqual(got, want) {
		t.Fatalf("levels=%#v", hero["fumo_levels"])
	}
}

func TestCA43BMID51StrictSparseRestoreResponse(t *testing.T) {
	svc := &ca42HeroService{promoteResult: apphero.HeroPromotionResult{PartnerID: 41, Branch: apphero.HeroPromotionMID51Promote, RestoreItems: []appi5.Award{{TableID: 50001007, ItemNum: 2}, {TableID: 50001003, ItemNum: 1}}}}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc}
	r := d.Dispatch(context.Background(), heroReq(t, 51, map[string]any{"partner_id": int64(41)}))
	if r.HTTPStatus != 200 || svc.promotePartner != 41 {
		t.Fatalf("response=%+v partner=%d", r, svc.promotePartner)
	}
	rows, ok := r.Body["restore_items"].([]any)
	if !ok || len(rows) != 2 || len(r.Body) != 1 {
		t.Fatalf("body=%#v", r.Body)
	}
	if got := rows[0].(map[string]any); got["table_id"] != int64(50001007) || got["item_num"] != int64(2) {
		t.Fatalf("restore=%#v", got)
	}
	if bad := d.Dispatch(context.Background(), heroReq(t, 51, map[string]any{"partner_id": int64(41), "color": int64(2)})); bad.HTTPStatus != 400 {
		t.Fatalf("invented field accepted: %+v", bad)
	}
}

func TestCA43BMID57UsesReceiptManaAndDoesNotPostReadEconomy(t *testing.T) {
	mana := int64(9876)
	svc := &ca42HeroService{oneClickResult: apphero.HeroPromotionResult{PartnerID: 55, Branch: apphero.HeroPromotionMID57Collect, ManaAfter: &mana}}
	economy := &ca42HeroEconomy{amount: 123}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc, Economy: economy}
	r := d.Dispatch(context.Background(), heroReq(t, 57, map[string]any{"partner_id": int64(55)}))
	if r.HTTPStatus != 200 || svc.oneClickPartner != 55 {
		t.Fatalf("response=%+v partner=%d", r, svc.oneClickPartner)
	}
	e, ok := r.Body["economy_"].(map[string]any)
	if !ok || e["mana"] != mana || len(r.Body) != 1 {
		t.Fatalf("body=%#v", r.Body)
	}
	if economy.calls != 0 {
		t.Fatalf("MID57 performed postcommit scalar read calls=%d", economy.calls)
	}
}

func TestCA43BPromotionFailuresClassifyContentAndSemanticRejections(t *testing.T) {
	svc := &ca42HeroService{promoteErr: apphero.ErrHeroPromotionContentInactive}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc}
	if r := d.Dispatch(context.Background(), heroReq(t, 51, map[string]any{"partner_id": int64(1)})); r.HTTPStatus != 503 || r.Body["error"] != "hero_content_inactive" {
		t.Fatalf("content=%+v", r)
	}
	svc.promoteErr = apphero.ErrHeroPromotionPrerequisites
	if r := d.Dispatch(context.Background(), heroReq(t, 51, map[string]any{"partner_id": int64(1)})); r.HTTPStatus != 400 || r.Body["error"] != "hero_operation_rejected" {
		t.Fatalf("semantic=%+v", r)
	}
}
