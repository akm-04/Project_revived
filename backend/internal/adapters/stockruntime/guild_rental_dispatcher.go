package stockruntime

import (
	"context"
	"errors"
	"net/http"

	"gxb.local/backend/v2/internal/application/guildrental"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	heroproj "gxb.local/backend/v2/internal/projection/hero"
	petproj "gxb.local/backend/v2/internal/projection/pet"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// GuildRentalMIDs are the stock guild hero and pet rental callbacks.
var GuildRentalMIDs = []uint16{593, 594, 595, 618, 619, 620, 621, 2768}

type GuildRentalPort interface {
	Place(context.Context, identity.ActorContext, guild.RentalKind, int64, operation.Context) error
	Recall(context.Context, identity.ActorContext, guild.RentalKind, int64, operation.Context) (int64, int64, error)
	OwnOffers(context.Context, identity.ActorContext, guild.RentalKind, operation.Context) ([]guildrental.Row, error)
	GuildOffers(context.Context, identity.ActorContext, guild.RentalKind, int64, operation.Context) (guildrental.List, error)
}

type GuildRentalDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   GuildRentalPort
}

func (d GuildRentalDispatcher) Dispatch(c context.Context, r httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: d.Authority}).actor(c, r)
	if fail != nil {
		return *fail
	}
	if d.Service == nil {
		return rentalFailure(guildrental.ErrUnavailable)
	}
	p, op := r.Envelope.Params, r.Envelope.Operation
	switch r.Envelope.MID {
	case 593:
		if !onlyStockGameplayParams(p) {
			return rentalBad()
		}
		rows, err := d.Service.OwnOffers(c, a, guild.RentalHero, op)
		if err != nil {
			return rentalFailure(err)
		}
		return okI5(map[string]any{"heroes": rentalSentHeroes(rows)})
	case 594:
		unit, ok := stockRentalUnit(p, "partner_id")
		if !ok {
			return rentalBad()
		}
		if err := d.Service.Place(c, a, guild.RentalHero, unit, op); err != nil {
			return rentalFailure(err)
		}
		rows, err := d.Service.OwnOffers(c, a, guild.RentalHero, op)
		if err != nil {
			return rentalFailure(err)
		}
		return okI5(map[string]any{"rent_info": rentalSentHeroes(rows)})
	case 595:
		unit, ok := stockRentalUnit(p, "partner_id")
		if !ok {
			return rentalBad()
		}
		interest, rentAward, err := d.Service.Recall(c, a, guild.RentalHero, unit, op)
		if err != nil {
			return rentalFailure(err)
		}
		rows, err := d.Service.OwnOffers(c, a, guild.RentalHero, op)
		if err != nil {
			return rentalFailure(err)
		}
		return okI5(map[string]any{"rent_list": rentalSentHeroes(rows), "award": interest, "rent_award": rentAward})
	case 618:
		if !onlyStockGameplayParams(p) {
			return rentalBad()
		}
		rows, err := d.Service.OwnOffers(c, a, guild.RentalPet, op)
		if err != nil {
			return rentalFailure(err)
		}
		return okI5(map[string]any{"pets": rentalSentPets(rows)})
	case 619:
		unit, ok := stockRentalUnit(p, "pet_id")
		if !ok {
			return rentalBad()
		}
		if err := d.Service.Place(c, a, guild.RentalPet, unit, op); err != nil {
			return rentalFailure(err)
		}
		rows, err := d.Service.OwnOffers(c, a, guild.RentalPet, op)
		if err != nil {
			return rentalFailure(err)
		}
		return okI5(map[string]any{"rent_info": rentalSentPets(rows)})
	case 620:
		unit, ok := stockRentalUnit(p, "pet_id")
		if !ok {
			return rentalBad()
		}
		interest, rentAward, err := d.Service.Recall(c, a, guild.RentalPet, unit, op)
		if err != nil {
			return rentalFailure(err)
		}
		rows, err := d.Service.OwnOffers(c, a, guild.RentalPet, op)
		if err != nil {
			return rentalFailure(err)
		}
		return okI5(map[string]any{"rent_list": rentalSentPets(rows), "award": interest, "rent_award": rentAward})
	case 621:
		if !onlyStockGameplayParams(p, "load_place", "rent_count") {
			return rentalBad()
		}
		list, err := d.Service.GuildOffers(c, a, guild.RentalPet, 0, op)
		if err != nil {
			return rentalFailure(err)
		}
		return okI5(map[string]any{"rent_count": list.RentCount, "pets": rentalPartners(list.Rows)})
	case 2768:
		if !onlyStockGameplayParams(p, "load_place", "rent_count", "campaign_type", "rent_type") {
			return rentalBad()
		}
		requested, ok := stockRentalType(p)
		if !ok {
			return rentalBad()
		}
		list, err := d.Service.GuildOffers(c, a, guild.RentalHero, requested, op)
		if err != nil {
			return rentalFailure(err)
		}
		return okI5(map[string]any{
			"guild_rent_heroes": map[string]any{"rent_type": requested, "partners": rentalPartners(list.Rows), "rent_count": list.RentCount},
			"rent_count":        list.RentCount,
			"tutor_rent_heroes": []any{},
		})
	default:
		return httpedge.Response{HTTPStatus: http.StatusNotImplemented, Body: map[string]any{"error": "not_i9_9b_mid"}}
	}
}

func stockRentalUnit(p map[string]any, key string) (int64, bool) {
	if !onlyStockGameplayParams(p, key) {
		return 0, false
	}
	value, err := requiredInt64(p, key)
	if err != nil || value <= 0 {
		return 0, false
	}
	return value, true
}

// stockRentalType returns campaign_type or its rent_type alias; absent is 0.
func stockRentalType(p map[string]any) (int64, bool) {
	value := int64(0)
	for _, key := range []string{"campaign_type", "rent_type"} {
		raw, present := p[key]
		if !present || raw == nil {
			continue
		}
		parsed, err := requiredInt64(p, key)
		if err != nil || parsed < 0 {
			return 0, false
		}
		if value == 0 || key == "campaign_type" {
			value = parsed
		}
	}
	return value, true
}

func rentalSentHeroes(rows []guildrental.Row) []any {
	out := make([]any, 0, len(rows))
	for _, row := range rows {
		out = append(out, map[string]any{"partner_id": row.Offer.Unit, "rent_time": row.Offer.RentTime.Unix(), "award": row.Interest, "rent_award": row.Offer.RentAward})
	}
	return out
}

func rentalSentPets(rows []guildrental.Row) []any {
	out := make([]any, 0, len(rows))
	for _, row := range rows {
		out = append(out, map[string]any{"pet_id": row.Offer.Unit, "rent_time": row.Offer.RentTime.Unix(), "award": row.Interest, "rent_award": row.Offer.RentAward})
	}
	return out
}

func rentalPartners(rows []guildrental.Row) []any {
	out := make([]any, 0, len(rows))
	for _, row := range rows {
		out = append(out, rentalPartner(row))
	}
	return out
}

func rentalPartner(row guildrental.Row) map[string]any {
	body := map[string]any{}
	if row.Hero != nil {
		wire, err := heroproj.StockHero(*row.Hero)
		if err == nil {
			for key, value := range wire {
				body[key] = value
			}
		}
	}
	if row.Pet != nil {
		wire, err := petproj.StockPrivate(*row.Pet, true)
		if err == nil {
			for key, value := range wire {
				body[key] = value
			}
		}
	}
	body["player_name"] = row.Profile.Name
	body["player_lev"] = row.Profile.Level
	body["player_avatar_id"] = row.Profile.AvatarID
	body["player_avatar_frame_id"] = row.Profile.AvatarFrameID
	body["player_id"] = int64(row.Offer.Lender)
	body["conquer_lev"] = row.Profile.ConquerLevel
	body["conquer_loop_id"] = row.Profile.ConquerLoopID
	body["rent_need_mana"] = row.Price
	body["can_rent"] = row.CanRent
	body["have_rent"] = row.HaveRent
	return body
}

func rentalBad() httpedge.Response {
	return httpedge.Response{HTTPStatus: http.StatusBadRequest, Body: map[string]any{"error": "guild_rental_invalid_parameter"}}
}

// rentalFailure refuses with 409 so the client's OK callback never indexes a
// nil list (Backend.lua:562-566).
func rentalFailure(err error) httpedge.Response {
	switch {
	case errors.Is(err, guildrental.ErrNotInGuild), errors.Is(err, guildrental.ErrUnitUnavailable),
		errors.Is(err, guildrental.ErrAlreadyOffered), errors.Is(err, guildrental.ErrCapReached),
		errors.Is(err, guildrental.ErrNoOffer), errors.Is(err, guildrental.ErrRecallTooEarly):
		return conflictRefusal(1)
	default:
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "guild_rental_unavailable"}}
	}
}
