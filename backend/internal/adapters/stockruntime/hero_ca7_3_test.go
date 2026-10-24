package stockruntime

import (
	"context"
	"errors"
	"testing"

	apphero "gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type ca73AppearanceService struct {
	skinPartner  int64
	skinItem     int64
	skinResult   apphero.SkinOnResult
	skinErr      error
	cancelID     int64
	illusionID   int64
	illusionItem int64
}

func (s *ca73AppearanceService) SkinOn(_ context.Context, _ identity.ActorContext, partnerID, itemID int64, _ operation.Context) (apphero.SkinOnResult, error) {
	s.skinPartner, s.skinItem = partnerID, itemID
	return s.skinResult, s.skinErr
}
func (s *ca73AppearanceService) SkinCancel(_ context.Context, _ identity.ActorContext, partnerID int64, _ operation.Context) (apphero.SkinCancelResult, error) {
	s.cancelID = partnerID
	return apphero.SkinCancelResult{PartnerID: partnerID, CurrentSkinID: 0, StateVersion: 2}, nil
}
func (s *ca73AppearanceService) UseIllusionSkinItem(_ context.Context, _ identity.ActorContext, partnerID, itemID int64, _ operation.Context) (apphero.IllusionSelectResult, error) {
	s.illusionID, s.illusionItem = partnerID, itemID
	return apphero.IllusionSelectResult{PartnerID: partnerID, IllusionSkinID: 40002006, StateVersion: 3}, nil
}

func TestCA73MID60StockShapeAndConsumptionFlag(t *testing.T) {
	expires := int64(1700000000)
	appearance := &ca73AppearanceService{skinResult: apphero.SkinOnResult{
		PartnerID: 7, CurrentSkinID: 40002006, RemoveItem: true, StateVersion: 9,
		Skins: []apphero.SkinResultEntitlement{{ModelID: 40002006, ExpiresAtUnix: &expires}, {ModelID: 40002007}},
	}}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: &ca23HeroService{}, Appearance: appearance}
	r := d.Dispatch(context.Background(), heroReq(t, 60, map[string]any{"partner_id": int64(7), "item_id": int64(50001807)}))
	if r.HTTPStatus != 200 || appearance.skinPartner != 7 || appearance.skinItem != 50001807 {
		t.Fatalf("response=%+v args=%d/%d", r, appearance.skinPartner, appearance.skinItem)
	}
	if r.Body["current_skin_id"] != int64(40002006) || r.Body["remove_item"] != int64(1) {
		t.Fatalf("MID60 body=%#v", r.Body)
	}
	skins, ok := r.Body["skin_ids"].(map[string]any)
	if !ok || skins["40002006"] != expires || skins["40002007"] != int64(-1) {
		t.Fatalf("MID60 skin_ids=%#v", r.Body["skin_ids"])
	}
	if _, invented := r.Body["server_time"]; invented {
		t.Fatal("MID60 invented mandatory server_time")
	}
}

func TestCA73MID60Recovered35035UsesErrorHTTPStatus(t *testing.T) {
	appearance := &ca73AppearanceService{skinErr: apphero.ErrHeroSkinExperienceAlreadyOwned}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: &ca23HeroService{}, Appearance: appearance}
	r := d.Dispatch(context.Background(), heroReq(t, 60, map[string]any{"partner_id": int64(7), "item_id": int64(50009163)}))
	if r.HTTPStatus != 400 || r.Body["error_code"] != int64(35035) {
		t.Fatalf("MID60 35035 response=%+v", r)
	}
}

func TestCA73MID61AndMID2979StrictWire(t *testing.T) {
	appearance := &ca73AppearanceService{}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: &ca23HeroService{}, Appearance: appearance}
	cancel := d.Dispatch(context.Background(), heroReq(t, 61, map[string]any{"partner_id": int64(8)}))
	if cancel.HTTPStatus != 200 || len(cancel.Body) != 0 || appearance.cancelID != 8 {
		t.Fatalf("MID61 response=%+v id=%d", cancel, appearance.cancelID)
	}
	illusion := d.Dispatch(context.Background(), heroReq(t, 2979, map[string]any{"partner_id": int64(8), "item_id": int64(50001807)}))
	if illusion.HTTPStatus != 200 || illusion.Body["illusion_skin_id"] != int64(40002006) || appearance.illusionID != 8 || appearance.illusionItem != 50001807 {
		t.Fatalf("MID2979 response=%+v args=%d/%d", illusion, appearance.illusionID, appearance.illusionItem)
	}
	bad := d.Dispatch(context.Background(), heroReq(t, 2979, map[string]any{"partner_id": int64(8), "item_id": int64(-1)}))
	if bad.HTTPStatus != 400 {
		t.Fatalf("MID2979 accepted undocumented wire -1: %+v", bad)
	}
	extra := d.Dispatch(context.Background(), heroReq(t, 60, map[string]any{"partner_id": int64(8), "item_id": int64(50001807), "duration": int64(3)}))
	if extra.HTTPStatus != 400 {
		t.Fatalf("MID60 accepted invented gameplay field: %+v", extra)
	}
}

func TestCA73AppearanceUnavailableMapsToHeroRejection(t *testing.T) {
	appearance := &ca73AppearanceService{skinErr: apphero.ErrHeroAppearanceUnavailable}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: &ca23HeroService{}, Appearance: appearance}
	r := d.Dispatch(context.Background(), heroReq(t, 60, map[string]any{"partner_id": int64(7), "item_id": int64(123)}))
	if r.HTTPStatus != 400 || r.Body["error"] != "hero_operation_rejected" {
		t.Fatalf("response=%+v", r)
	}
	appearance.skinErr = errors.New("db")
	r = d.Dispatch(context.Background(), heroReq(t, 60, map[string]any{"partner_id": int64(7), "item_id": int64(123)}))
	if r.HTTPStatus != 503 {
		t.Fatalf("unexpected internal error mapping: %+v", r)
	}
}
