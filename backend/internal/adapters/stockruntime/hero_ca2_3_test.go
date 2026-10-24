package stockruntime

import (
	"context"
	"testing"
	"time"

	apphero "gxb.local/backend/v2/internal/application/characterhero"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

type ca23HeroService struct {
	summonArgs []int64
	vowsTable  int64
}

func (s *ca23HeroService) Roster(context.Context, identity.ActorContext) (character.HeroRoot, []character.Hero, error) {
	return character.HeroRoot{}, nil, nil
}
func (s *ca23HeroService) RosterView(_ context.Context, _ identity.ActorContext, observedAt time.Time) (character.HeroRoot, []apphero.HeroRosterView, error) {
	return character.HeroRoot{}, nil, nil
}
func (s *ca23HeroService) SaveSortType(context.Context, identity.ActorContext, int64, operation.Context) error {
	return nil
}
func (s *ca23HeroService) UseExpItem(context.Context, identity.ActorContext, int64, int64, int64, operation.Context) (apphero.ExpResult, error) {
	return apphero.ExpResult{}, nil
}
func (s *ca23HeroService) UseExpItems(context.Context, identity.ActorContext, int64, []appi5.HeroExpItemDebit, operation.Context) (apphero.ExpResult, error) {
	return apphero.ExpResult{}, nil
}
func (s *ca23HeroService) EquipItem(context.Context, identity.ActorContext, int64, int64, operation.Context) (apphero.EquipItemResult, error) {
	return apphero.EquipItemResult{}, nil
}
func (s *ca23HeroService) OneKeyEquip(context.Context, identity.ActorContext, int64, operation.Context) (apphero.OneKeyEquipResult, error) {
	return apphero.OneKeyEquipResult{}, nil
}
func (s *ca23HeroService) EnhanceSuperEquipment(context.Context, identity.ActorContext, int64, int64, int64, operation.Context) (apphero.EnhanceSuperEquipmentResult, error) {
	return apphero.EnhanceSuperEquipmentResult{}, nil
}
func (s *ca23HeroService) FeedFumo(context.Context, identity.ActorContext, int64, int64, []int64, operation.Context) (apphero.FumoResult, error) {
	return apphero.FumoResult{}, nil
}
func (s *ca23HeroService) PowerUpHero(context.Context, identity.ActorContext, int64, operation.Context) (apphero.HeroPromotionResult, error) {
	return apphero.HeroPromotionResult{}, nil
}
func (s *ca23HeroService) OneClickJinjie(context.Context, identity.ActorContext, int64, operation.Context) (apphero.HeroPromotionResult, error) {
	return apphero.HeroPromotionResult{}, nil
}
func (s *ca23HeroService) Evolve(context.Context, identity.ActorContext, int64, operation.Context) error {
	return nil
}
func (s *ca23HeroService) HeroPieces(context.Context, identity.ActorContext) (map[int64]int64, error) {
	return map[int64]int64{}, nil
}
func ca23Hero(kind character.HeroKind, table, partner, star int64) character.Hero {
	now := time.Unix(1, 0).UTC()
	return character.Hero{RawSkills: character.NewHeroRawSkillSeed(), PlayerID: 100001, PartnerID: partner, TableID: table, OriginTableID: table, Kind: kind, Star: star, Level: 1, Exp: 0, Color: 1, CreationContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", StateVersion: 1, CreatedAt: now, UpdatedAt: now}
}
func (s *ca23HeroService) SummonNormal(_ context.Context, _ identity.ActorContext, tableID, stoneID, stoneNum int64, _ operation.Context) (character.Hero, error) {
	s.summonArgs = []int64{tableID, stoneID, stoneNum}
	return ca23Hero(character.NormalHero, tableID, 7, 3), nil
}
func (s *ca23HeroService) CreateVows(_ context.Context, _ identity.ActorContext, tableID int64, _ operation.Context) (character.Hero, error) {
	s.vowsTable = tableID
	return ca23Hero(character.SuperHero, tableID, 8, 2), nil
}

func heroReq(t *testing.T, mid uint16, params map[string]any) httpedge.DispatchRequest {
	t.Helper()
	now := time.Unix(1000, 0).UTC()
	return httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: mid, ReceivedAt: now, Params: params, Claims: wire.CredentialClaims{Token: "bearer", Region: 1}, Operation: operation.Context{StartedAt: now}}}
}

func TestCA23MID59StrictRequestAndDirectHeroResponse(t *testing.T) {
	svc := &ca23HeroService{}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc, Economy: &ca42HeroEconomy{amount: 777}}
	r := d.Dispatch(context.Background(), heroReq(t, 59, map[string]any{"table_id": int64(1001), "stone": int64(4001), "stone_num": int64(10)}))
	if r.HTTPStatus != 200 || r.Body["table_id"] != int64(1001) || r.Body["partner_id"] != int64(7) {
		t.Fatalf("response=%+v", r)
	}
	if economy, ok := r.Body["economy_"].(map[string]any); !ok || economy["mana"] != int64(777) {
		t.Fatal("missing current source Mana projection", r)
	}
	if r.Body["collection_admission"] != nil || r.Body["extra_drops_"] != nil {
		t.Fatal("private proof or duplicate fragment grant leaked", r)
	}
	if len(svc.summonArgs) != 3 || svc.summonArgs[0] != 1001 || svc.summonArgs[1] != 4001 || svc.summonArgs[2] != 10 {
		t.Fatalf("summon args=%v", svc.summonArgs)
	}
	bad := d.Dispatch(context.Background(), heroReq(t, 59, map[string]any{"table_id": int64(1001), "stone": int64(4001), "stone_num": int64(10), "capacity": int64(99)}))
	if bad.HTTPStatus != 400 {
		t.Fatalf("invented MID59 field accepted: %+v", bad)
	}
}

func TestCA23MID305StrictRequestAndPartnerInfoEnvelope(t *testing.T) {
	svc := &ca23HeroService{}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc}
	r := d.Dispatch(context.Background(), heroReq(t, 305, map[string]any{"table_id": int64(9001)}))
	if r.HTTPStatus != 200 || svc.vowsTable != 9001 {
		t.Fatalf("response=%+v table=%d", r, svc.vowsTable)
	}
	p, ok := r.Body["partner_info"].(map[string]any)
	if !ok || p["table_id"] != int64(9001) || p["partner_type"] != int64(2) || p["partner_id"] != int64(8) {
		t.Fatalf("partner_info=%#v", r.Body["partner_info"])
	}
	bad := d.Dispatch(context.Background(), heroReq(t, 305, map[string]any{"table_id": int64(9001), "extra": true}))
	if bad.HTTPStatus != 400 {
		t.Fatalf("invented MID305 field accepted: %+v", bad)
	}
}

func TestHeroDispatcherAcceptsStockEnvelopeMetadataButRejectsUnknownGameplayField(t *testing.T) {
	svc := &ca23HeroService{}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc, Economy: &ca42HeroEconomy{amount: 777}}
	params := map[string]any{
		"table_id": int64(1001), "stone": int64(4001), "stone_num": int64(10),
		"mid": int64(59), "token": "bearer", "region": int64(1),
		"v_": "1", "app_v": "1.164.0", "platform": int64(3),
	}
	r := d.Dispatch(context.Background(), heroReq(t, 59, params))
	if r.HTTPStatus != 200 {
		t.Fatalf("stock envelope metadata rejected: %+v", r)
	}
	params["invented"] = true
	r = d.Dispatch(context.Background(), heroReq(t, 59, params))
	if r.HTTPStatus != 400 {
		t.Fatalf("invented gameplay field accepted: %+v", r)
	}
}

func TestNormal59MissingEconomyRejectsBeforeMutation(t *testing.T) {
	svc := &ca23HeroService{}
	d := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc}
	r := d.Dispatch(context.Background(), heroReq(t, 59, map[string]any{"table_id": int64(1001), "stone": int64(4001), "stone_num": int64(10)}))
	if r.HTTPStatus != 503 || len(svc.summonArgs) != 0 {
		t.Fatal("missing projection allowed partial mutation", r, svc.summonArgs)
	}
}
