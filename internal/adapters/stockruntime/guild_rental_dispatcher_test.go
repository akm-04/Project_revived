package stockruntime

import (
	"context"
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
	body := got.Body
	nested, ok := body["guild_rent_heroes"].(map[string]any)
	if !ok {
		t.Fatal("2768 guild_rent_heroes", body)
	}
	partners, ok := nested["partners"].([]any)
	if !ok || len(partners) != 1 || body["rent_count"] != int64(4242) || nested["rent_count"] != int64(4242) || nested["rent_type"] != int64(1) {
		t.Fatal("2768 shape", body)
	}
	partner := partners[0].(map[string]any)
	for _, key := range []string{"partner_id", "table_id", "player_name", "player_id", "rent_need_mana", "can_rent", "have_rent"} {
		if _, ok := partner[key]; !ok {
			t.Fatal("partner row missing", key)
		}
	}
	if tutors, ok := body["tutor_rent_heroes"].([]any); !ok || len(tutors) != 0 {
		t.Fatal("2768 tutor list", body["tutor_rent_heroes"])
	}

	got = d.Dispatch(context.Background(), heroReq(t, 621, map[string]any{"load_place": int64(0)}))
	if got.HTTPStatus != 200 || got.Body["rent_count"] != int64(4242) {
		t.Fatal("621 shape", got)
	}
	if _, ok := got.Body["pets"].([]any); !ok {
		t.Fatal("621 pets", got.Body["pets"])
	}

	got = d.Dispatch(context.Background(), heroReq(t, 593, map[string]any{}))
	heroes, ok := got.Body["heroes"].([]any)
	if got.HTTPStatus != 200 || !ok || len(heroes) != 1 {
		t.Fatal("593 shape", got)
	}
	item := heroes[0].(map[string]any)
	if item["partner_id"] != int64(31) || item["rent_time"] != int64(1700000000) || item["award"] != int64(500) || item["rent_award"] != int64(3000) {
		t.Fatal("593 item", item)
	}

	got = d.Dispatch(context.Background(), heroReq(t, 595, map[string]any{"partner_id": int64(31)}))
	list, ok := got.Body["rent_list"].([]any)
	if got.HTTPStatus != 200 || !ok || len(list) != 1 || got.Body["award"] != int64(11) || got.Body["rent_award"] != int64(22) {
		t.Fatal("595 shape", got)
	}

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
