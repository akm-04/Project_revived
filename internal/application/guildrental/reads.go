package guildrental

import (
	"cmp"
	"context"
	"encoding/binary"
	"slices"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
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

// HeroProjection is the qualified owner view of one offered Hero: the durable
// row plus the appearance and twice-awake facts the stock detail window reads.
type HeroProjection struct {
	Hero            character.Hero
	Appearance      characterasset.EffectiveHeroAppearance
	TwiceAwakeStage *int64
}

// Characters is the existing owned-character read, not a second stat path.
type Characters interface {
	HeroProjectionTx(context.Context, tx.Queryer, string, time.Time, identity.PlayerID, int64) (HeroProjection, bool, error)
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
	Offer           guild.RentalOffer
	Hero            *character.Hero
	Appearance      *characterasset.EffectiveHeroAppearance
	TwiceAwakeStage *int64
	Pet             *character.Pet
	Profile         playerdirectory.Profile
	Price           int64
	Interest        int64
	CanRent         bool
	HaveRent        bool
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
	Workplace  Workplace
	Policy     Policy
	Content    Content
	Now        func(context.Context, tx.Queryer) (time.Time, error)
}

func (r Reader) validate() error {
	if r.Runner.DB == nil || r.Store == nil || r.Characters == nil || r.Profiles == nil || r.Levels == nil || r.Mana == nil || r.Privileges == nil || r.Content == nil || r.Now == nil {
		return ErrUnavailable
	}
	return r.Policy.Validate()
}

func (r Reader) readTx(c context.Context, op operation.Context, body func(context.Context, tx.Scope) error) error {
	_, err := r.Runner.Run(c, op, i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, body)
	return err
}

// UsedPartners is 623: units the stock hero picker must not offer. It is the
// union of the player's workplace workers and their own hero offers.
func (r Reader) UsedPartners(c context.Context, a identity.ActorContext, op operation.Context) ([]int64, error) {
	if err := r.validate(); err != nil {
		return nil, err
	}
	if r.Workplace == nil {
		return nil, ErrUnavailable
	}
	seen := map[int64]bool{}
	out := []int64{}
	add := func(id int64) {
		if id > 0 && !seen[id] {
			seen[id] = true
			out = append(out, id)
		}
	}
	err := r.readTx(c, op, func(c context.Context, sc tx.Scope) error {
		workers, err := r.Workplace.BusyPartnersTx(c, sc.Tx, a.PlayerID)
		if err != nil {
			return err
		}
		for _, worker := range workers {
			add(worker)
		}
		offers, err := r.Store.ListLenderRentalOffersTx(c, sc.Tx, a.PlayerID, guild.RentalHero, listLimit)
		if err != nil {
			return err
		}
		for _, offer := range offers {
			add(offer.Unit)
		}
		return nil
	})
	return out, err
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
		var revision string
		var thresholds []character.HeroExpThreshold
		var observedAt time.Time
		if kind == guild.RentalHero {
			revision, err = r.Content.ActiveRevision(c, sc.Tx)
			if err != nil {
				return err
			}
			thresholds, err = r.Content.HeroExpPolicyTx(c, sc.Tx, revision, character.MaxHeroLevel)
			if err != nil {
				return err
			}
			observedAt, err = r.Now(c, sc.Tx)
			if err != nil {
				return err
			}
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
			unitLevel, found, err := r.unit(c, sc.Tx, revision, observedAt.UTC(), thresholds, offer, &row)
			if err != nil {
				return err
			}
			if !found {
				continue
			}
			row.HaveRent, row.CanRent = admission(offer, kind, uses, unitLevel, borrowerLimit, mana >= row.Price)
			rows = append(rows, row)
		}
		count, err := rentCount(kind, requestedType, rows)
		if err != nil {
			return err
		}
		list = List{Rows: rows, RentCount: count}
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

func (r Reader) unit(c context.Context, q tx.Queryer, revision string, observedAt time.Time, thresholds []character.HeroExpThreshold, offer guild.RentalOffer, row *Row) (int64, bool, error) {
	if offer.Kind == guild.RentalHero {
		projection, found, err := r.Characters.HeroProjectionTx(c, q, revision, observedAt, offer.Lender, offer.Unit)
		if err != nil || !found {
			return 0, found, err
		}
		cumulativeExp, err := projection.Hero.SourceCumulativeEXP(thresholds)
		if err != nil {
			return 0, false, err
		}
		projection.Hero.Exp = cumulativeExp
		row.Hero = &projection.Hero
		row.Appearance = &projection.Appearance
		row.TwiceAwakeStage = projection.TwiceAwakeStage
		return projection.Hero.Level, true, nil
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

// rentCount excludes observation metadata and interest: they change on reads
// without changing the cached detail. Character data is copied before normalization.
func rentCount(kind guild.RentalKind, requestedType int64, rows []Row) (int64, error) {
	type cacheEntry struct {
		Lender            identity.PlayerID
		Kind              guild.RentalKind
		Unit              int64
		Price             int64
		CanRent, HaveRent bool
		Profile           playerdirectory.Profile
		Hero              *character.Hero
		Pet               *character.Pet
		Appearance        *characterasset.EffectiveHeroAppearance
		TwiceAwakeStage   *int64
	}
	entries := make([]cacheEntry, 0, len(rows))
	for _, row := range rows {
		entry := cacheEntry{Lender: row.Offer.Lender, Kind: row.Offer.Kind, Unit: row.Offer.Unit,
			Price: row.Price, CanRent: row.CanRent, HaveRent: row.HaveRent, Profile: row.Profile, TwiceAwakeStage: row.TwiceAwakeStage}
		if row.Hero != nil {
			hero := *row.Hero
			hero.StateVersion, hero.CurrentSkinID, hero.IllusionSkinID = 0, 0, 0
			hero.CreatedAt, hero.UpdatedAt = time.Time{}, time.Time{}
			hero.CreationContentRevision = ""
			entry.Hero = &hero
		}
		if row.Pet != nil {
			pet := *row.Pet
			pet.StateVersion, pet.ActiveStyle, pet.OriginTableID = 0, 0, 0
			pet.CreatedAt, pet.UpdatedAt = time.Time{}, time.Time{}
			pet.CreationContentRevision = ""
			entry.Pet = &pet
		}
		if row.Appearance != nil {
			appearance := *row.Appearance
			appearance.OwnerStateVersion = 0
			appearance.ObservedAt = time.Time{}
			appearance.Skins = slices.Clone(appearance.Skins)
			appearance.LIVE = slices.Clone(appearance.LIVE)
			slices.SortFunc(appearance.Skins, func(first, second characterasset.QualifiedSkinEntitlement) int {
				return cmp.Compare(first.ModelID, second.ModelID)
			})
			slices.SortFunc(appearance.LIVE, func(first, second characterasset.QualifiedLIVEState) int {
				return cmp.Compare(first.ModelID, second.ModelID)
			})
			entry.Appearance = &appearance
		}
		entries = append(entries, entry)
	}
	slices.SortFunc(entries, func(first, second cacheEntry) int {
		if order := cmp.Compare(first.Lender, second.Lender); order != 0 {
			return order
		}
		if order := cmp.Compare(first.Kind, second.Kind); order != 0 {
			return order
		}
		return cmp.Compare(first.Unit, second.Unit)
	})
	sum, err := receipt.FingerprintRequest(struct {
		Kind          guild.RentalKind
		RequestedType int64
		Rows          []cacheEntry
	}{kind, requestedType, entries})
	if err != nil {
		return 0, err
	}
	value := int64(binary.BigEndian.Uint64(sum[:8]) & 0x7fffffffffffffff)
	if value == 0 {
		return 1, nil
	}
	return value, nil
}
