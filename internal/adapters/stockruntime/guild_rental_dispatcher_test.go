package stockruntime

import (
	"context"
	"encoding/json"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/guildrental"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type rentalProbe struct {
	list     guildrental.List
	own      []guildrental.Row
	placeErr error
	lastMid  uint16
}

func (p *rentalProbe) Place(_ context.Context, _ identity.ActorContext, _ guild.RentalKind, _ int64, _ operation.Context) error {
	return p.placeErr
}

func (p *rentalProbe) Recall(_ context.Context, _ identity.ActorContext, _ guild.RentalKind, _ int64, _ operation.Context) (int64, int64, error) {
	return 11, 22, nil
}

func (p *rentalProbe) OwnOffers(_ context.Context, _ identity.ActorContext, _ guild.RentalKind, _ operation.Context) ([]guildrental.Row, error) {
	return p.own, nil
}

func (p *rentalProbe) GuildOffers(_ context.Context, _ identity.ActorContext, _ guild.RentalKind, _ int64, _ operation.Context) (guildrental.List, error) {
	return p.list, nil
}

func rentalRow(lender identity.PlayerID, kind guild.RentalKind, unit int64) guildrental.Row {
	offer := guild.RentalOffer{Lender: lender, Kind: kind, Unit: unit, Force: 4000, RentAward: 3000, RentTime: time.Unix(1700000000, 0)}
	row := guildrental.Row{Offer: offer, Price: 2000, Interest: 500, CanRent: true, HaveRent: false}
	row.Profile = playerProfile(lender)
	if kind == guild.RentalHero {
		at := time.Now().UTC()
		hero := character.Hero{PlayerID: lender, PartnerID: unit, TableID: 10001001, OriginTableID: 10001001, Kind: character.NormalHero,
			Star: 1, Level: 1, Color: 1, RawSkills: character.NewHeroRawSkillSeed(), CreationContentRevision: strings.Repeat("a", 64), StateVersion: 1, CreatedAt: at, UpdatedAt: at}
		row.Hero = &hero
	}
	return row
}

func rentalPetRow(lender identity.PlayerID, unit int64) guildrental.Row {
	offer := guild.RentalOffer{Lender: lender, Kind: guild.RentalPet, Unit: unit, Force: 4000, RentAward: 3000, RentTime: time.Unix(1700000000, 0)}
	row := guildrental.Row{Offer: offer, Price: 2000, Interest: 500, CanRent: true, HaveRent: false}
	row.Profile = playerProfile(lender)
	at := time.Now().UTC()
	pet := character.Pet{PlayerID: lender, PetID: unit, TableID: 10001, Star: 1, Level: 1, Color: 1, StateVersion: 1, CreatedAt: at, UpdatedAt: at}
	row.Pet = &pet
	return row
}

func exactJSON(t *testing.T, body map[string]any, want string) {
	t.Helper()
	raw, err := json.Marshal(body)
	if err != nil {
		t.Fatal(err)
	}
	if string(raw) != want {
		t.Fatalf("body=%s want=%s", raw, want)
	}
}

func playerProfile(lender identity.PlayerID) playerdirectory.Profile {
	return playerdirectory.Profile{PlayerID: lender, Name: "lender", Level: 9, AvatarID: 110001001, AvatarFrameID: 0, ConquerLevel: 0, ConquerLoopID: 1}
}

func TestGuildRentalWireShapes(t *testing.T) {
	lender := identity.PlayerID(7)
	probe := &rentalProbe{list: guildrental.List{Rows: []guildrental.Row{rentalRow(lender, guild.RentalHero, 31)}, RentCount: 4242},
		own: []guildrental.Row{rentalRow(lender, guild.RentalHero, 31)}}
	d := GuildRentalDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: probe}

	got := d.Dispatch(context.Background(), heroReq(t, 2768, map[string]any{"load_place": int64(0), "campaign_type": int64(1)}))
	if got.HTTPStatus != 200 {
		t.Fatal("2768 status", got)
	}
	nested := got.Body["guild_rent_heroes"].(map[string]any)
	partners := nested["partners"].([]any)
	if len(partners) != 1 || got.Body["rent_count"] != int64(4242) || nested["rent_count"] != int64(4242) || nested["rent_type"] != int64(1) {
		t.Fatal("2768 shape", got.Body)
	}
	partner := partners[0].(map[string]any)
	if partner["partner_id"] != int64(31) || partner["table_id"] != int64(10001001) || partner["player_id"] != int64(7) ||
		partner["player_name"] != "lender" || partner["rent_need_mana"] != int64(2000) || partner["can_rent"] != true || partner["have_rent"] != false {
		t.Fatal("2768 partner row", partner)
	}
	if tutors := got.Body["tutor_rent_heroes"].([]any); len(tutors) != 0 {
		t.Fatal("2768 tutor list", tutors)
	}

	probe.list = guildrental.List{Rows: []guildrental.Row{rentalPetRow(lender, 41)}, RentCount: 4242}
	got = d.Dispatch(context.Background(), heroReq(t, 621, map[string]any{"load_place": int64(0)}))
	petRows := got.Body["pets"].([]any)
	if got.HTTPStatus != 200 || got.Body["rent_count"] != int64(4242) || len(petRows) != 1 ||
		petRows[0].(map[string]any)["player_id"] != int64(7) || petRows[0].(map[string]any)["rent_need_mana"] != int64(2000) ||
		petRows[0].(map[string]any)["can_rent"] != true || petRows[0].(map[string]any)["have_rent"] != false {
		t.Fatal("621 shape", got.Body)
	}

	got = d.Dispatch(context.Background(), heroReq(t, 593, map[string]any{}))
	heroes := got.Body["heroes"].([]any)
	if got.HTTPStatus != 200 || len(heroes) != 1 {
		t.Fatal("593 shape", got.Body)
	}
	item := heroes[0].(map[string]any)
	if item["partner_id"] != int64(31) || item["rent_time"] != int64(1700000000) || item["award"] != int64(500) || item["rent_award"] != int64(3000) {
		t.Fatal("593 item", item)
	}

	got = d.Dispatch(context.Background(), heroReq(t, 594, map[string]any{"partner_id": int64(31)}))
	rentInfo := got.Body["rent_info"].([]any)
	if got.HTTPStatus != 200 || len(rentInfo) != 1 || rentInfo[0].(map[string]any)["partner_id"] != int64(31) {
		t.Fatal("594 rent_info", got.Body)
	}

	got = d.Dispatch(context.Background(), heroReq(t, 595, map[string]any{"partner_id": int64(31)}))
	list := got.Body["rent_list"].([]any)
	if got.HTTPStatus != 200 || len(list) != 1 || list[0].(map[string]any)["partner_id"] != int64(31) ||
		got.Body["award"] != int64(11) || got.Body["rent_award"] != int64(22) {
		t.Fatal("595 shape", got.Body)
	}

	probe.own = []guildrental.Row{rentalPetRow(lender, 41)}
	got = d.Dispatch(context.Background(), heroReq(t, 618, map[string]any{}))
	pets := got.Body["pets"].([]any)
	if got.HTTPStatus != 200 || len(pets) != 1 || pets[0].(map[string]any)["pet_id"] != int64(41) ||
		pets[0].(map[string]any)["rent_time"] != int64(1700000000) || pets[0].(map[string]any)["award"] != int64(500) || pets[0].(map[string]any)["rent_award"] != int64(3000) {
		t.Fatal("618 shape", got.Body)
	}
	got = d.Dispatch(context.Background(), heroReq(t, 619, map[string]any{"pet_id": int64(41)}))
	if got.HTTPStatus != 200 || len(got.Body["rent_info"].([]any)) != 1 || got.Body["rent_info"].([]any)[0].(map[string]any)["pet_id"] != int64(41) {
		t.Fatal("619 rent_info", got.Body)
	}
	got = d.Dispatch(context.Background(), heroReq(t, 620, map[string]any{"pet_id": int64(41)}))
	if got.HTTPStatus != 200 || len(got.Body["rent_list"].([]any)) != 1 || got.Body["rent_list"].([]any)[0].(map[string]any)["pet_id"] != int64(41) ||
		got.Body["award"] != int64(11) || got.Body["rent_award"] != int64(22) {
		t.Fatal("620 shape", got.Body)
	}

	probe.list = guildrental.List{Rows: []guildrental.Row{}, RentCount: 1}
	got = d.Dispatch(context.Background(), heroReq(t, 621, map[string]any{}))
	exactJSON(t, got.Body, `{"pets":[],"rent_count":1}`)
	got = d.Dispatch(context.Background(), heroReq(t, 2768, map[string]any{"campaign_type": int64(1)}))
	exactJSON(t, got.Body, `{"guild_rent_heroes":{"partners":[],"rent_count":1,"rent_type":1},"rent_count":1,"tutor_rent_heroes":[]}`)

	probe.placeErr = guildrental.ErrAlreadyOffered
	got = d.Dispatch(context.Background(), heroReq(t, 594, map[string]any{"partner_id": int64(31)}))
	if got.HTTPStatus != 409 || got.Body["error_code"] != int64(1) {
		t.Fatal("594 refusal must be 409", got)
	}
	got = d.Dispatch(context.Background(), heroReq(t, 594, map[string]any{"partner_id": int64(31), "extra": int64(1)}))
	if got.HTTPStatus != 400 {
		t.Fatal("unknown param must be 400", got)
	}
}
