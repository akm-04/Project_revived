package guildrental

import (
	"context"
	"crypto/sha256"
	"encoding/binary"
	"fmt"

	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// listLimit bounds every guild list read.
const listLimit = 200

// ReadStore is the read side of the rental store. It takes no locks: a list is
// a projection, and recall eligibility is computed from rent_time on read.
type ReadStore interface {
	ReadMembershipTx(context.Context, tx.Queryer, identity.PlayerID) (guild.Membership, bool, error)
	ListRentalOffersByGuildTx(context.Context, tx.Queryer, guild.ID, guild.RentalKind, int) ([]guild.RentalOffer, error)
	ListLenderRentalOffersTx(context.Context, tx.Queryer, identity.PlayerID, guild.RentalKind, int) ([]guild.RentalOffer, error)
	ReadRentalUsesDayTx(context.Context, tx.Queryer, identity.PlayerID, int64) ([]guild.RentalUse, error)
}

// Characters is the existing owned-character read, not a second stat path.
type Characters interface {
	HeroTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Hero, bool, error)
	PetTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Pet, bool, error)
}

type Profiles interface {
	ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error)
}

type Mana interface {
	BalanceTx(context.Context, tx.Queryer, identity.PlayerID, string) (int64, bool, error)
}

// Row is one visible offer with the projections the stock windows index.
type Row struct {
	Offer    guild.RentalOffer
	Hero     *character.Hero
	Pet      *character.Pet
	Profile  playerdirectory.Profile
	Price    int64
	Interest int64
	CanRent  bool
	HaveRent bool
}

// List is one 2768 or 621 answer. RentCount is the client list cache key (C6).
type List struct {
	Rows      []Row
	RentCount int64
}

type Reader struct {
	Runner     tx.Runner
	Store      ReadStore
	Characters Characters
	Profiles   Profiles
	Levels     Levels
	Mana       Mana
	Privileges i5.PrivilegeSnapshotProvider
	Policy     Policy
}

func (r Reader) validate() error {
	if r.Runner.DB == nil || r.Store == nil || r.Characters == nil || r.Profiles == nil || r.Levels == nil || r.Mana == nil || r.Privileges == nil {
		return ErrUnavailable
	}
	return r.Policy.Validate()
}

func (r Reader) readTx(c context.Context, op operation.Context, body func(context.Context, tx.Scope) error) error {
	_, err := r.Runner.Run(c, op, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, body)
	return err
}

// OwnOffers is 593/618's list: the caller's own offers, with the current
// interest the item cell adds to the stored award at render time.
func (r Reader) OwnOffers(c context.Context, a identity.ActorContext, kind guild.RentalKind, op operation.Context) ([]Row, error) {
	if err := r.validate(); err != nil {
		return nil, err
	}
	var rows []Row
	err := r.readTx(c, op, func(c context.Context, sc tx.Scope) error {
		offers, err := r.Store.ListLenderRentalOffersTx(c, sc.Tx, a.PlayerID, kind, listLimit)
		if err != nil {
			return err
		}
		at := op.StartedAt.UTC()
		rows = make([]Row, 0, len(offers))
		for _, offer := range offers {
			rows = append(rows, Row{Offer: offer, Price: r.Policy.Money.Price(offer.Force), Interest: r.Policy.Money.Interest(offer, at)})
		}
		return nil
	})
	return rows, err
}

// GuildOffers is 2768/621's list. A disabled requested mode returns no rows;
// the lender never sees their own offer (C7). Price, can_rent and have_rent
// are the borrower's projection, and rent_count hashes them (C6).
func (r Reader) GuildOffers(c context.Context, a identity.ActorContext, kind guild.RentalKind, requestedType int64, op operation.Context) (List, error) {
	if err := r.validate(); err != nil {
		return List{}, err
	}
	if requestedType > 0 {
		rule, listed := r.Policy.Modes[requestedType]
		if !listed || !rule.Enabled {
			return List{Rows: []Row{}, RentCount: 1}, nil
		}
	}
	var list List
	err := r.readTx(c, op, func(c context.Context, sc tx.Scope) error {
		membership, joined, err := r.Store.ReadMembershipTx(c, sc.Tx, a.PlayerID)
		if err != nil {
			return err
		}
		if !joined {
			list = List{Rows: []Row{}, RentCount: 1}
			return nil
		}
		offers, err := r.Store.ListRentalOffersByGuildTx(c, sc.Tx, membership.GuildID, kind, listLimit)
		if err != nil {
			return err
		}
		at := op.StartedAt.UTC()
		level, err := r.Levels.LevelTx(c, sc.Tx, a.PlayerID)
		if err != nil {
			return err
		}
		privilege, err := r.Privileges.SnapshotTx(c, sc.Tx, a.PlayerID, at)
		if err != nil {
			return err
		}
		vipLimit, known := r.Policy.VIP[privilege.VIPLevel]
		if !known {
			return ErrUnavailable
		}
		mana, _, err := r.Mana.BalanceTx(c, sc.Tx, a.PlayerID, manaResource)
		if err != nil {
			return err
		}
		uses, err := r.Store.ReadRentalUsesDayTx(c, sc.Tx, a.PlayerID, modes.Day(at))
		if err != nil {
			return err
		}
		borrowerLimit := level + min(vipLimit.LevelUp, r.Policy.Money.LevelUpCeiling)
		rows := make([]Row, 0, len(offers))
		for _, offer := range offers {
			if offer.Lender == a.PlayerID {
				continue
			}
			row := Row{Offer: offer, Price: r.Policy.Money.Price(offer.Force), Interest: r.Policy.Money.Interest(offer, at)}
			row.Profile, _, err = r.Profiles.ProfileTx(c, sc.Tx, offer.Lender)
			if err != nil {
				return err
			}
			unitLevel, found, err := r.unit(c, sc.Tx, offer, &row)
			if err != nil {
				return err
			}
			if !found {
				continue
			}
			row.HaveRent, row.CanRent = admission(offer, kind, uses, unitLevel, borrowerLimit, mana >= row.Price)
			rows = append(rows, row)
		}
		list = List{Rows: rows, RentCount: rentCount(kind, requestedType, rows)}
		return nil
	})
	return list, err
}

// HeroOfferedTx is the workplace admission read: a girl with a live offer
// cannot be sent to a workplace (C14).
func (r Reader) HeroOfferedTx(c context.Context, q tx.Queryer, pid identity.PlayerID, unit int64) (bool, error) {
	if r.Store == nil || q == nil || !pid.Valid() || unit <= 0 {
		return false, ErrUnavailable
	}
	offers, err := r.Store.ListLenderRentalOffersTx(c, q, pid, guild.RentalHero, listLimit)
	if err != nil {
		return false, err
	}
	for _, offer := range offers {
		if offer.Unit == unit {
			return true, nil
		}
	}
	return false, nil
}

func (r Reader) unit(c context.Context, q tx.Queryer, offer guild.RentalOffer, row *Row) (int64, bool, error) {
	if offer.Kind == guild.RentalHero {
		hero, found, err := r.Characters.HeroTx(c, q, offer.Lender, offer.Unit)
		if err != nil || !found {
			return 0, found, err
		}
		row.Hero = &hero
		return hero.Level, true, nil
	}
	pet, found, err := r.Characters.PetTx(c, q, offer.Lender, offer.Unit)
	if err != nil || !found {
		return 0, found, err
	}
	row.Pet = &pet
	return pet.Level, true, nil
}

// admission applies rule 5, 6, 10 and 16 to one visible row.
func admission(offer guild.RentalOffer, kind guild.RentalKind, uses []guild.RentalUse, unitLevel, borrowerLimit int64, affordable bool) (haveRent, canRent bool) {
	for _, use := range uses {
		if use.Lender != offer.Lender {
			continue
		}
		if use.Kind == kind && use.Unit == offer.Unit {
			return true, true
		}
		return false, false
	}
	return false, affordable && unitLevel <= borrowerLimit
}

// rentCount is the nonzero cache key SelfGuild.lua compares (C6): the visible
// rows, the requested type and each row's price, can_rent and have_rent.
func rentCount(kind guild.RentalKind, requestedType int64, rows []Row) int64 {
	raw := fmt.Sprintf("%s:%d", kind, requestedType)
	for _, row := range rows {
		raw += fmt.Sprintf(";%d:%s:%d:%d:%t:%t", int64(row.Offer.Lender), row.Offer.Kind, row.Offer.Unit, row.Price, row.CanRent, row.HaveRent)
	}
	sum := sha256.Sum256([]byte(raw))
	value := int64(binary.BigEndian.Uint64(sum[:8]) & 0x7fffffffffffffff)
	if value == 0 {
		return 1
	}
	return value
}
