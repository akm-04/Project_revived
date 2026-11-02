// Package guildrental owns guild hero and pet rental (I9_GUILD_RENTAL_V1): open
// offers and day uses at lock rank 609b, the mana price paid inside a battle
// START, and the lender's payout on recall or departure.
package guildrental

import (
	"context"
	"errors"
	"fmt"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/combat"
	"gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	capability      = "GUILD_RENTAL_V1"
	policyVersion   = "I9_GUILD_POLICY_V1"
	manaResource    = "mana"
	departureSource = "GUILD_RENTAL_DEPARTURE"
	petOfferCap     = 1
)

var (
	ErrUnavailable     = errors.New("guild rental: unavailable")
	ErrNotInGuild      = errors.New("guild rental: not in a guild")
	ErrUnitUnavailable = errors.New("guild rental: unit cannot be lent")
	ErrAlreadyOffered  = errors.New("guild rental: unit already offered")
	ErrCapReached      = errors.New("guild rental: offer cap reached")
	ErrNoOffer         = errors.New("guild rental: no such offer")
	ErrRecallTooEarly  = errors.New("guild rental: recall too early")
)

// ModeRule is one borrow_modes row of I9_GUILD_POLICY_V1. StarCap 0 means uncapped.
type ModeRule struct {
	Enabled bool
	StarCap int64
}

// VIPLimit is one vip.lua row: num_mercenary and rent_level_up.
type VIPLimit struct {
	Lend    int64
	LevelUp int64
}

type DepartureMail struct {
	Sender string
	Title  string
	Body   string
}

type Policy struct {
	Money     guild.RentalMoney
	Modes     map[int64]ModeRule
	VIP       map[int64]VIPLimit
	Departure DepartureMail
}

func (p Policy) Validate() error {
	if !p.Money.Valid() || len(p.Modes) == 0 || len(p.VIP) == 0 || p.Departure.Title == "" {
		return ErrUnavailable
	}
	return nil
}

// Unit is what the owner reads about a lent unit: Force is its power today.
type Unit struct {
	Level int64
	Force int64
}

type Store interface {
	ReadMembershipTx(context.Context, tx.Queryer, identity.PlayerID) (guild.Membership, bool, error)
	LockMembershipTx(context.Context, tx.Tx, identity.PlayerID) (guild.Membership, bool, error)
	LockRentalOfferTx(context.Context, tx.Tx, identity.PlayerID, guild.RentalKind, int64) (guild.RentalOffer, bool, error)
	LockLenderRentalOffersTx(context.Context, tx.Tx, identity.PlayerID) ([]guild.RentalOffer, error)
	InsertRentalOfferTx(context.Context, tx.Tx, guild.RentalOffer) error
	DeleteRentalOfferTx(context.Context, tx.Tx, guild.RentalOffer) error
	AddRentalAwardTx(context.Context, tx.Tx, guild.RentalOffer, int64) error
	LockRentalUseTx(context.Context, tx.Tx, identity.PlayerID, identity.PlayerID, int64) (guild.RentalUse, bool, error)
	InsertRentalUseTx(context.Context, tx.Tx, guild.RentalUse) (bool, error)
	DeleteExpiredRentalUsesTx(context.Context, tx.Tx, identity.PlayerID, int64) error
}

// Units reads a player's own unit without locks; found is false when not owned.
type Units interface {
	UnitTx(context.Context, tx.Queryer, identity.PlayerID, guild.RentalKind, int64) (Unit, bool, error)
}

// Levels reads a player's level without a lock: I5 progression 710 follows economy 700.
type Levels interface {
	LevelTx(context.Context, tx.Queryer, identity.PlayerID) (int64, error)
}

type Workplace interface {
	BusyTx(context.Context, tx.Queryer, identity.PlayerID, int64) (bool, error)
}

type Values interface {
	SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error)
}

type Costs interface {
	DebitMaterialCostTx(context.Context, tx.Tx, identity.PlayerID, i5.MaterialCost, operation.Context) (i5.MaterialDebitResult, error)
}

type Facts interface {
	PrepareTx(context.Context, tx.Tx, identity.PlayerID, generation.TimedOperation) (context.Context, error)
	RecordTx(context.Context, tx.Tx, operation.Context, ...objective.Fact) error
}

type Mail interface {
	DeliverTx(context.Context, tx.Tx, i5.SettlementMailRequest) (mail.Record, bool, error)
}

type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
}

type Service struct {
	Runner     tx.Runner
	Store      Store
	Units      Units
	Levels     Levels
	Workplace  Workplace
	Privileges i5.PrivilegeSnapshotProvider
	Values     Values
	Costs      Costs
	Facts      Facts
	Mail       Mail
	Fence      Fence
	Players    playerroot.TxLocker
	Content    Content
	Policy     Policy
}

func (s Service) validate() error {
	ready := s.Runner.DB != nil && s.Store != nil && s.Units != nil && s.Levels != nil && s.Workplace != nil && s.Privileges != nil &&
		s.Values != nil && s.Costs != nil && s.Facts != nil && s.Mail != nil && s.Fence != nil && s.Players != nil && s.Content != nil
	if !ready {
		return ErrUnavailable
	}
	return s.Policy.Validate()
}

func refused(reason string) error { return fmt.Errorf("%w: %s", d.ErrLoanRefused, reason) }

func provenance(loan combat.Loan) d.Provenance {
	return d.Provenance{Capability: capability, Reference: fmt.Sprintf("%s/%d/%d", loan.Kind, int64(loan.Lender), loan.Identity)}
}

// admit checks one loan and returns its price, 0 when the day's use already paid.
// The offer row is locked here; the caller debits only after every offer is locked.
func (s Service) admit(c context.Context, t tx.Tx, scope ca.CoherentReadScope, loan combat.Loan, membership guild.Membership, limit VIPLimit, borrowerLevel, day int64) (int64, error) {
	rule, listed := s.Policy.Modes[loan.CampaignType]
	if !listed || !rule.Enabled {
		return 0, refused("mode does not allow borrowing")
	}
	kind := guild.RentalKind(loan.Kind)
	offer, found, err := s.Store.LockRentalOfferTx(c, t, loan.Lender, kind, loan.Identity)
	if err != nil {
		return 0, err
	}
	if !found {
		return 0, refused("no open offer")
	}
	// The offer row carries the lender's guild: every lender departure closes it under this lock (C15).
	if membership.GuildID != offer.Guild {
		return 0, refused("lender is in another guild")
	}
	unit, owned, err := s.Units.UnitTx(c, t, loan.Lender, kind, loan.Identity)
	if err != nil {
		return 0, err
	}
	if !owned {
		return 0, refused("lender no longer owns the unit")
	}
	if !s.Policy.Money.LevelAllowed(unit.Level, borrowerLevel, limit.LevelUp) {
		return 0, refused("unit level above the borrower's limit")
	}
	use, used, err := s.Store.LockRentalUseTx(c, t, loan.Borrower, loan.Lender, day)
	if err != nil {
		return 0, err
	}
	if used {
		if use.Kind == kind && use.Unit == loan.Identity {
			return 0, nil
		}
		return 0, refused("one unit from a lender per day")
	}
	price := s.Policy.Money.Price(offer.Force)
	inserted, err := s.Store.InsertRentalUseTx(c, t, guild.RentalUse{Borrower: loan.Borrower, Lender: loan.Lender, GameDay: day, Kind: kind, Unit: loan.Identity, CampaignType: loan.CampaignType, CostMana: price, UsedAt: scope.ObservedAt})
	if err != nil {
		return 0, err
	}
	if !inserted {
		return 0, refused("one unit from a lender per day")
	}
	if err := s.Store.AddRentalAwardTx(c, t, offer, price); err != nil {
		return 0, err
	}
	return price, nil
}

// LendTx implements combat.Lending. Offers and uses (609b) are all taken before
// the I5 debit, so a battle borrowing a girl and a pet never holds the borrower's
// economy row while waiting on a second offer. Held loans are a March run's girl,
// already paid for at the run's first START (C12).
func (s Service) LendTx(c context.Context, t tx.Tx, scope ca.CoherentReadScope, loans []combat.Loan) ([]d.Provenance, error) {
	if err := s.validate(); err != nil {
		return nil, err
	}
	fresh := []combat.Loan{}
	out := make([]d.Provenance, 0, len(loans))
	for _, loan := range loans {
		out = append(out, provenance(loan))
		if !loan.Held {
			fresh = append(fresh, loan)
		}
	}
	if len(fresh) == 0 {
		return out, nil
	}
	if len(fresh) > 2 || fresh[0].Kind == d.PetActor && len(fresh) == 2 || len(fresh) == 2 && fresh[0].Kind == fresh[1].Kind {
		return nil, refused("one girl and one pet a battle")
	}
	borrower := fresh[0].Borrower
	membership, joined, err := s.Store.ReadMembershipTx(c, t, borrower)
	if err != nil {
		return nil, err
	}
	if !joined {
		return nil, refused("borrower is not in a guild")
	}
	privilege, err := s.Privileges.SnapshotTx(c, t, borrower, scope.ObservedAt)
	if err != nil {
		return nil, err
	}
	limit, known := s.Policy.VIP[privilege.VIPLevel]
	if !known {
		return nil, refused("unknown vip level")
	}
	level, err := s.Levels.LevelTx(c, t, borrower)
	if err != nil {
		return nil, err
	}
	day := modes.Day(scope.ObservedAt)
	var total int64
	paid := []combat.Loan{}
	for _, loan := range fresh {
		price, err := s.admit(c, t, scope, loan, membership, limit, level, day)
		if err != nil {
			return nil, err
		}
		if price > 0 {
			total += price
			paid = append(paid, loan)
		}
	}
	if total == 0 {
		return out, nil
	}
	if err := s.Store.DeleteExpiredRentalUsesTx(c, t, borrower, day); err != nil {
		return nil, err
	}
	bound, err := bindContent(scope.Operation, scope.ContentRevision)
	if err != nil {
		return nil, err
	}
	// Mission rows precede the economy debit (C16 records Fact 116 in START).
	timed, err := generation.NewTimedOperation(bound, scope.ObservedAt)
	if err != nil {
		return nil, err
	}
	prepared, err := s.Facts.PrepareTx(c, t, borrower, timed)
	if err != nil {
		return nil, err
	}
	if _, err := s.Costs.DebitMaterialCostTx(c, t, borrower, i5.MaterialCost{Scalars: []i5.ScalarMaterialCost{{ResourceKey: manaResource, Amount: total}}}, bound); err != nil {
		return nil, fmt.Errorf("%w: %w", d.ErrLoanRefused, err)
	}
	for _, loan := range paid {
		key := fmt.Sprintf("rental:%d:%d:%d", int64(borrower), int64(loan.Lender), day)
		if err := s.Facts.RecordTx(prepared, t, bound, objective.Fact{PlayerID: borrower, SourceDomain: "guildrental", SourceBusinessKey: key, Kind: "HERO_LENT", Delta: 1}); err != nil {
			return nil, err
		}
	}
	return out, nil
}

// Place opens an offer. The membership row (320) serialises it against leaving,
// which closes the lender's offers under the same lock.
func (s Service) Place(c context.Context, a identity.ActorContext, kind guild.RentalKind, unitID int64, op operation.Context) error {
	if err := s.validate(); err != nil {
		return err
	}
	if unitID <= 0 || kind != guild.RentalHero && kind != guild.RentalPet {
		return ErrUnitUnavailable
	}
	return s.command(c, a, op, func(c context.Context, t tx.Tx, at time.Time) error {
		membership, joined, err := s.Store.LockMembershipTx(c, t, a.PlayerID)
		if err != nil {
			return err
		}
		if !joined {
			return ErrNotInGuild
		}
		unit, owned, err := s.Units.UnitTx(c, t, a.PlayerID, kind, unitID)
		if err != nil {
			return err
		}
		if !owned {
			return ErrUnitUnavailable
		}
		if kind == guild.RentalHero {
			busy, err := s.Workplace.BusyTx(c, t, a.PlayerID, unitID)
			if err != nil {
				return err
			}
			if busy {
				return ErrUnitUnavailable
			}
		}
		privilege, err := s.Privileges.SnapshotTx(c, t, a.PlayerID, at)
		if err != nil {
			return err
		}
		offers, err := s.Store.LockLenderRentalOffersTx(c, t, a.PlayerID)
		if err != nil {
			return err
		}
		if err := s.checkCap(offers, kind, unitID, privilege.VIPLevel); err != nil {
			return err
		}
		return s.Store.InsertRentalOfferTx(c, t, guild.RentalOffer{Lender: a.PlayerID, Kind: kind, Unit: unitID, Guild: membership.GuildID, Force: unit.Force, RentTime: at})
	})
}

func (s Service) checkCap(offers []guild.RentalOffer, kind guild.RentalKind, unitID, vipLevel int64) error {
	limit, known := s.Policy.VIP[vipLevel]
	if !known {
		return ErrUnavailable
	}
	capacity := limit.Lend
	if kind == guild.RentalPet {
		capacity = petOfferCap
	}
	var held int64
	for _, offer := range offers {
		if offer.Kind != kind {
			continue
		}
		if offer.Unit == unitID {
			return ErrAlreadyOffered
		}
		held++
	}
	if held >= capacity {
		return ErrCapReached
	}
	return nil
}

// Recall closes an offer after the minimum time and pays the lender. It returns
// the closed offer's two payout parts, which the client shows.
func (s Service) Recall(c context.Context, a identity.ActorContext, kind guild.RentalKind, unitID int64, op operation.Context) (interest, rentAward int64, err error) {
	if err := s.validate(); err != nil {
		return 0, 0, err
	}
	err = s.command(c, a, op, func(c context.Context, t tx.Tx, at time.Time) error {
		offer, found, err := s.Store.LockRentalOfferTx(c, t, a.PlayerID, kind, unitID)
		if err != nil {
			return err
		}
		if !found {
			return ErrNoOffer
		}
		if !s.Policy.Money.RecallAllowed(offer, at) {
			return ErrRecallTooEarly
		}
		if err := s.Store.DeleteRentalOfferTx(c, t, offer); err != nil {
			return err
		}
		interest, rentAward = s.Policy.Money.Interest(offer, at), offer.RentAward
		if interest+rentAward == 0 {
			return nil
		}
		revision, err := s.Content.ActiveRevision(c, t)
		if err != nil {
			return err
		}
		bound, err := bindContent(op, revision)
		if err != nil {
			return err
		}
		plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "guildrental", Operation: "recall", BusinessKey: offerKey(offer), Occurrence: op.ID.String(), PolicyVersion: policyVersion},
			Lines: []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: manaResource, Amount: interest + rentAward}}}
		_, err = s.Values.SettleGrantTx(c, t, a, plan, bound, i5.GrantTxOptions{AllowOverflowMail: true})
		return err
	})
	return interest, rentAward, err
}

// CloseLenderOffersTx ends a departing lender's offers inside the guild's leave,
// kick or dissolve transaction and mails each payout once (C15). Started fights stand.
func (s Service) CloseLenderOffersTx(c context.Context, t tx.Tx, lender identity.PlayerID, at time.Time) error {
	if err := s.validate(); err != nil {
		return err
	}
	offers, err := s.Store.LockLenderRentalOffersTx(c, t, lender)
	if err != nil {
		return err
	}
	for _, offer := range offers {
		if err := s.Store.DeleteRentalOfferTx(c, t, offer); err != nil {
			return err
		}
		payout := s.Policy.Money.Payout(offer, at)
		if payout == 0 {
			continue
		}
		request := i5.SettlementMailRequest{Recipient: lender, SourceKind: departureSource, SourceKey: offerKey(offer), Title: s.Policy.Departure.Title, Sender: s.Policy.Departure.Sender, Body: s.Policy.Departure.Body,
			PolicyVersion: policyVersion, Lines: []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: manaResource, Amount: payout}}, At: at}
		if _, _, err := s.Mail.DeliverTx(c, t, request); err != nil {
			return err
		}
	}
	return nil
}

func offerKey(offer guild.RentalOffer) string {
	return fmt.Sprintf("%d:%s:%d:%d", int64(offer.Lender), offer.Kind, offer.Unit, offer.RentTime.UnixMicro())
}

func (s Service) command(c context.Context, a identity.ActorContext, op operation.Context, body func(context.Context, tx.Tx, time.Time) error) error {
	_, err := s.Runner.Run(c, op, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(c context.Context, sc tx.Scope) error {
		at := op.StartedAt.UTC()
		if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
			return err
		}
		if _, err := s.Players.LockPlayerRootsTx(c, sc.Tx, a.LogicalServerID, []identity.PlayerID{a.PlayerID}); err != nil {
			return err
		}
		return body(c, sc.Tx, at)
	})
	return err
}

func bindContent(op operation.Context, revision string) (operation.Context, error) {
	if current, ok := op.Policies.Get("content"); ok {
		if current != revision {
			return operation.Context{}, i5.ErrContentRevisionConflict
		}
		return op, nil
	}
	set, err := policy.NewSet(append(op.Policies.Refs(), policy.Ref{Name: "content", Version: revision})...)
	if err != nil {
		return operation.Context{}, err
	}
	op.Policies = set
	return op, nil
}

var _ combat.Lending = Service{}
