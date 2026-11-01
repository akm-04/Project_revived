// Package guildtea is the Guild-owned Tea Party mode (I9_GUILD_ACTIVITY_V1
// C13-C16): day-stable wishes, gifts, their claim, and the MID1 red-point embed.
package guildtea

import (
	"context"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	ErrInvalid        = errors.New("guild tea: invalid input")
	ErrNotInGuild     = errors.New("guild tea: not a guild member")
	ErrAlreadyWished  = errors.New("guild tea: wish already requested today")
	ErrNoWish         = errors.New("guild tea: no wish today")
	ErrWishFull       = errors.New("guild tea: wish already fulfilled")
	ErrAlreadyDonated = errors.New("guild tea: already donated to this member today")
	ErrSelfDonation   = errors.New("guild tea: cannot donate to yourself")
	ErrNotOwner       = errors.New("guild tea: scroll is not for an owned girl")
	ErrUnknownScroll  = errors.New("guild tea: item is not a girl scroll")
	ErrUnavailable    = errors.New("guild tea: unavailable")
)

const policyVersion = "I9_GUILD_POLICY_V1"

// Policy is the immutable Tea Party document values the content adapter loads
// from docs/i9/I9_GUILD_POLICY_V1.json (D406, C13).
type Policy struct {
	RequestsPerDay            int64
	NormalNeed                int64
	SXNeed                    int64
	DonorFriendMedalPerScroll int64
}

func (p Policy) Validate() error {
	if p.RequestsPerDay != 1 || p.NormalNeed <= 0 || p.SXNeed <= 0 || p.DonorFriendMedalPerScroll <= 0 {
		return ErrUnavailable
	}
	return nil
}

type WishInfo struct {
	ItemID     int64
	CurrentNum int64
	NeedNum    int64
}

type PlayerInfo struct {
	PlayerID      int64
	Name          string
	Level         int64
	GuildJob      int64
	AvatarID      int64
	AvatarFrameID int64
	ConquerLevel  int64
	ConquerLoopID int64
}

type WishRow struct {
	Wish       WishInfo
	Player     PlayerInfo
	CanPresent bool
}

type GiftRow struct {
	Player PlayerInfo
}

type Award struct {
	ItemID int64
	Num    int64
}

// State is the reply of every Tea Party MID; SelfOnly is the is_self 1808 and
// MID1 shape (self_wish_info only).
type State struct {
	SelfOnly bool
	SelfWish WishInfo
	WishFlag int64
	Gifts    []GiftRow
	Wishes   []WishRow
	Award    *Award
}

type Store interface {
	ReadMembershipTx(context.Context, tx.Queryer, identity.PlayerID) (guild.Membership, bool, error)
	ListMembershipsTx(context.Context, tx.Queryer, guild.ID) ([]guild.Membership, error)
	ReadWishTx(context.Context, tx.Queryer, identity.PlayerID, int64) (guild.Wish, bool, error)
	LockWishTx(context.Context, tx.Tx, identity.PlayerID, int64) (guild.Wish, bool, error)
	InsertWishTx(context.Context, tx.Tx, guild.Wish) error
	AdvanceWishTx(context.Context, tx.Tx, identity.PlayerID, int64) (guild.Wish, bool, error)
	InsertGiftTx(context.Context, tx.Tx, guild.Gift) (bool, error)
	ListUnclaimedGiftsTx(context.Context, tx.Queryer, identity.PlayerID, int64) ([]guild.Gift, error)
	ListWishesTx(context.Context, tx.Queryer, guild.ID, int64) ([]guild.Wish, error)
	GiftedReceiversTx(context.Context, tx.Queryer, identity.PlayerID, int64) (map[identity.PlayerID]bool, error)
	ClaimGiftsTx(context.Context, tx.Tx, identity.PlayerID, int64, time.Time) (int64, error)
	DeleteExpiredWishesTx(context.Context, tx.Tx, guild.ID, int64) error
	DeleteExpiredGiftsForPlayerTx(context.Context, tx.Tx, identity.PlayerID, int64) error
}

type Directory interface {
	ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error)
}

type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	HeroAcquisitionByItemTx(context.Context, tx.Queryer, string, int64) (character.HeroAcquisitionTemplate, error)
}

type Heroes interface {
	ListHeroesTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Hero, error)
}

type Inventory interface {
	ListStacksTx(context.Context, tx.Queryer, identity.PlayerID) ([]economy.StackState, error)
}

type Values interface {
	SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error)
}

type Costs interface {
	DebitMaterialCostTx(context.Context, tx.Tx, identity.PlayerID, i5.MaterialCost, operation.Context) (i5.MaterialDebitResult, error)
}

type Facts interface {
	RecordTx(context.Context, tx.Tx, operation.Context, ...objective.Fact) error
}

type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

type Service struct {
	Runner    tx.Runner
	Store     Store
	Directory Directory
	Content   Content
	Heroes    Heroes
	Inventory Inventory
	Values    Values
	Costs     Costs
	Facts     Facts
	Fence     Fence
	Players   playerroot.TxLocker
	Policy    Policy
}

func (s Service) validate() error {
	if s.Runner.DB == nil || s.Store == nil || s.Directory == nil || s.Content == nil || s.Heroes == nil || s.Inventory == nil || s.Values == nil || s.Costs == nil || s.Facts == nil || s.Fence == nil || s.Players == nil {
		return ErrUnavailable
	}
	if err := s.Policy.Validate(); err != nil {
		return ErrUnavailable
	}
	return nil
}

func (s Service) read(c context.Context, op operation.Context, body func(context.Context, tx.Queryer) error) error {
	_, err := s.Runner.Run(c, op, i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		return body(c, sc.Tx)
	})
	return err
}

func (s Service) command(c context.Context, a identity.ActorContext, op operation.Context, body func(context.Context, tx.Tx) error) error {
	_, err := s.Runner.Run(c, op, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: true}, nil, func(c context.Context, sc tx.Scope) error {
		if err := s.Fence.FenceActorTx(c, sc.Tx, a, op.StartedAt.UTC()); err != nil {
			return err
		}
		return body(c, sc.Tx)
	})
	return err
}

func (s Service) player(c context.Context, q tx.Queryer, pid identity.PlayerID, job int64) (PlayerInfo, error) {
	p, ok, err := s.Directory.ProfileTx(c, q, pid)
	if err != nil {
		return PlayerInfo{}, err
	}
	if !ok {
		return PlayerInfo{}, ErrUnavailable
	}
	return PlayerInfo{PlayerID: int64(pid), Name: p.Name, Level: p.Level, GuildJob: job, AvatarID: p.AvatarID, AvatarFrameID: p.AvatarFrameID, ConquerLevel: p.ConquerLevel, ConquerLoopID: p.ConquerLoopID}, nil
}

func wishInfo(w guild.Wish) WishInfo {
	if w.ItemID <= 0 {
		return WishInfo{}
	}
	return WishInfo{ItemID: w.ItemID, CurrentNum: w.CurrentNum, NeedNum: w.NeedNum}
}

// stateTx assembles the reply inside the caller's transaction. Reads derive;
// nothing here writes (C3, C15).
func (s Service) stateTx(c context.Context, q tx.Queryer, a identity.ActorContext, day int64, selfOnly bool) (State, error) {
	out := State{SelfOnly: selfOnly, Gifts: []GiftRow{}, Wishes: []WishRow{}}
	m, member, err := s.Store.ReadMembershipTx(c, q, a.PlayerID)
	if err != nil {
		return State{}, err
	}
	if !member {
		return State{}, ErrNotInGuild
	}
	wish, found, err := s.Store.ReadWishTx(c, q, a.PlayerID, day)
	if err != nil {
		return State{}, err
	}
	if found {
		out.SelfWish = wishInfo(wish)
		out.WishFlag = 1
	}
	if selfOnly {
		return out, nil
	}
	stacks, err := s.Inventory.ListStacksTx(c, q, a.PlayerID)
	if err != nil {
		return State{}, err
	}
	owned := make(map[int64]bool, len(stacks))
	for _, stack := range stacks {
		if stack.Quantity > 0 {
			owned[stack.ItemID] = true
		}
	}
	given, err := s.Store.GiftedReceiversTx(c, q, a.PlayerID, day)
	if err != nil {
		return State{}, err
	}
	gifts, err := s.Store.ListUnclaimedGiftsTx(c, q, a.PlayerID, day)
	if err != nil {
		return State{}, err
	}
	for _, gift := range gifts {
		donor, err := s.player(c, q, gift.DonorID, 0)
		if err != nil {
			return State{}, err
		}
		out.Gifts = append(out.Gifts, GiftRow{Player: donor})
	}
	wishes, err := s.Store.ListWishesTx(c, q, m.GuildID, day)
	if err != nil {
		return State{}, err
	}
	for _, row := range wishes {
		member, found, err := s.Store.ReadMembershipTx(c, q, row.PlayerID)
		if err != nil {
			return State{}, err
		}
		if !found || member.GuildID != m.GuildID {
			continue
		}
		player, err := s.player(c, q, row.PlayerID, int64(member.Role))
		if err != nil {
			return State{}, err
		}
		canPresent := row.PlayerID != a.PlayerID && row.CurrentNum < row.NeedNum && owned[row.ItemID] && !given[row.PlayerID]
		out.Wishes = append(out.Wishes, WishRow{Wish: wishInfo(row), Player: player, CanPresent: canPresent})
	}
	return out, nil
}

// Info is 1808: the viewer's wish and, unless is_self, the guild's wishes and gifts.
func (s Service) Info(c context.Context, a identity.ActorContext, op operation.Context, selfOnly bool) (State, error) {
	if err := s.validate(); err != nil {
		return State{}, err
	}
	day := modes.Day(op.StartedAt)
	var out State
	err := s.read(c, op, func(c context.Context, q tx.Queryer) error {
		var err error
		out, err = s.stateTx(c, q, a, day, selfOnly)
		return err
	})
	return out, err
}

// Request is 1809: one immutable wish per game day.
func (s Service) Request(c context.Context, a identity.ActorContext, itemID int64, op operation.Context) (State, error) {
	if err := s.validate(); err != nil || itemID <= 0 {
		if err != nil {
			return State{}, err
		}
		return State{}, ErrInvalid
	}
	day := modes.Day(op.StartedAt)
	var out State
	err := s.command(c, a, op, func(c context.Context, t tx.Tx) error {
		if _, found, err := s.Store.LockWishTx(c, t, a.PlayerID, day); err != nil {
			return err
		} else if found {
			return ErrAlreadyWished
		}
		revision, err := s.Content.ActiveRevision(c, t)
		if err != nil {
			return err
		}
		tmpl, err := s.Content.HeroAcquisitionByItemTx(c, t, revision, itemID)
		if err != nil {
			return ErrUnknownScroll
		}
		heroes, err := s.Heroes.ListHeroesTx(c, t, a.PlayerID)
		if err != nil {
			return err
		}
		owned := false
		for _, hero := range heroes {
			if hero.TableID == tmpl.TableID || hero.OriginTableID == tmpl.TableID {
				owned = true
				break
			}
		}
		if !owned {
			return ErrNotOwner
		}
		need := s.Policy.NormalNeed
		if tmpl.Kind == character.SuperHero {
			need = s.Policy.SXNeed
		}
		if err := s.Store.InsertWishTx(c, t, guild.Wish{PlayerID: a.PlayerID, GameDay: day, ItemID: itemID, NeedNum: need}); err != nil {
			return err
		}
		member, found, err := s.Store.ReadMembershipTx(c, t, a.PlayerID)
		if err != nil {
			return err
		}
		if !found {
			return ErrNotInGuild
		}
		if err := s.Store.DeleteExpiredWishesTx(c, t, member.GuildID, day); err != nil {
			return err
		}
		if err := s.Store.DeleteExpiredGiftsForPlayerTx(c, t, a.PlayerID, day); err != nil {
			return err
		}
		out, err = s.stateTx(c, t, a, day, false)
		return err
	})
	return out, err
}

// Present is 1810: one scroll from the donor to the receiver's wish.
func (s Service) Present(c context.Context, a identity.ActorContext, receiver identity.PlayerID, op operation.Context) (State, error) {
	if err := s.validate(); err != nil {
		return State{}, err
	}
	if !receiver.Valid() {
		return State{}, ErrInvalid
	}
	if receiver == a.PlayerID {
		return State{}, ErrSelfDonation
	}
	day := modes.Day(op.StartedAt)
	var out State
	err := s.command(c, a, op, func(c context.Context, t tx.Tx) error {
		if _, err := s.Players.LockPlayerRootsTx(c, t, a.LogicalServerID, []identity.PlayerID{a.PlayerID}); err != nil {
			return err
		}
		donor, donorMember, err := s.Store.ReadMembershipTx(c, t, a.PlayerID)
		if err != nil {
			return err
		}
		if !donorMember {
			return ErrNotInGuild
		}
		receiverMember, receiverJoined, err := s.Store.ReadMembershipTx(c, t, receiver)
		if err != nil {
			return err
		}
		if !receiverJoined || receiverMember.GuildID != donor.GuildID {
			return ErrNotInGuild
		}
		wish, found, err := s.Store.LockWishTx(c, t, receiver, day)
		if err != nil {
			return err
		}
		if !found {
			return ErrNoWish
		}
		if wish.CurrentNum >= wish.NeedNum {
			return ErrWishFull
		}
		inserted, err := s.Store.InsertGiftTx(c, t, guild.Gift{ReceiverID: receiver, DonorID: a.PlayerID, GameDay: day, ItemID: wish.ItemID})
		if err != nil {
			return err
		}
		if !inserted {
			return ErrAlreadyDonated
		}
		if _, advanced, err := s.Store.AdvanceWishTx(c, t, receiver, day); err != nil {
			return err
		} else if !advanced {
			return ErrWishFull
		}
		revision, err := s.Content.ActiveRevision(c, t)
		if err != nil {
			return err
		}
		bound, err := bindContent(op, revision)
		if err != nil {
			return err
		}
		presentation := fmt.Sprintf("tea:%d:%d:%d", int64(receiver), int64(a.PlayerID), day)
		plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "guildtea", Operation: "present", BusinessKey: presentation, Occurrence: op.ID.String(), PolicyVersion: policyVersion},
			Lines: []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "friend_medal", Amount: s.Policy.DonorFriendMedalPerScroll}}}
		if _, err := s.Values.SettleGrantTx(c, t, a, plan, bound, i5.GrantTxOptions{AllowOverflowMail: false}); err != nil {
			return err
		}
		if _, err := s.Costs.DebitMaterialCostTx(c, t, a.PlayerID, i5.MaterialCost{Stacks: []i5.StackMaterialCost{{ItemID: wish.ItemID, Amount: 1}}}, bound); err != nil {
			return err
		}
		if err := s.Facts.RecordTx(c, t, bound, objective.Fact{PlayerID: a.PlayerID, SourceDomain: "guildtea", SourceBusinessKey: presentation, Kind: "TEA_PARTY_DONATED", Delta: 1}); err != nil {
			return err
		}
		if err := s.Store.DeleteExpiredWishesTx(c, t, donor.GuildID, day); err != nil {
			return err
		}
		if err := s.Store.DeleteExpiredGiftsForPlayerTx(c, t, a.PlayerID, day); err != nil {
			return err
		}
		out, err = s.stateTx(c, t, a, day, false)
		return err
	})
	return out, err
}

// Confirm is 1811: pays the receiver the wish item per unclaimed gift and clears
// them once; a second call pays nothing (C15).
func (s Service) Confirm(c context.Context, a identity.ActorContext, op operation.Context) (State, error) {
	if err := s.validate(); err != nil {
		return State{}, err
	}
	day := modes.Day(op.StartedAt)
	var out State
	err := s.command(c, a, op, func(c context.Context, t tx.Tx) error {
		if _, err := s.Players.LockPlayerRootsTx(c, t, a.LogicalServerID, []identity.PlayerID{a.PlayerID}); err != nil {
			return err
		}
		wish, found, err := s.Store.LockWishTx(c, t, a.PlayerID, day)
		if err != nil {
			return err
		}
		if !found {
			return ErrNoWish
		}
		gifts, err := s.Store.ListUnclaimedGiftsTx(c, t, a.PlayerID, day)
		if err != nil {
			return err
		}
		if len(gifts) > 0 {
			claimed, err := s.Store.ClaimGiftsTx(c, t, a.PlayerID, day, op.StartedAt.UTC())
			if err != nil {
				return err
			}
			if claimed > 0 {
				revision, err := s.Content.ActiveRevision(c, t)
				if err != nil {
					return err
				}
				bound, err := bindContent(op, revision)
				if err != nil {
					return err
				}
				plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "guildtea", Operation: "confirm", BusinessKey: fmt.Sprintf("tea:claim:%d:%d", int64(a.PlayerID), day), Occurrence: op.ID.String(), PolicyVersion: policyVersion}, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: wish.ItemID, Amount: claimed}}}
				if _, err := s.Values.SettleGrantTx(c, t, a, plan, bound, i5.GrantTxOptions{AllowOverflowMail: true}); err != nil {
					return err
				}
				out.Award = &Award{ItemID: wish.ItemID, Num: claimed}
			}
		}
		member, memberFound, err := s.Store.ReadMembershipTx(c, t, a.PlayerID)
		if err != nil {
			return err
		}
		if memberFound {
			if err := s.Store.DeleteExpiredWishesTx(c, t, member.GuildID, day); err != nil {
				return err
			}
		}
		if err := s.Store.DeleteExpiredGiftsForPlayerTx(c, t, a.PlayerID, day); err != nil {
			return err
		}
		state, err := s.stateTx(c, t, a, day, false)
		if err != nil {
			return err
		}
		state.Award = out.Award
		out = state
		return nil
	})
	return out, err
}

// MID1 is the 1808 embed: self_wish_info only, omitted for guildless players.
func (s Service) MID1(c context.Context, q tx.Queryer, player identity.PlayerID, day int64) (State, bool, error) {
	if s.Store == nil {
		return State{}, false, ErrUnavailable
	}
	if _, member, err := s.Store.ReadMembershipTx(c, q, player); err != nil {
		return State{}, false, err
	} else if !member {
		return State{}, false, nil
	}
	wish, found, err := s.Store.ReadWishTx(c, q, player, day)
	if err != nil {
		return State{}, false, err
	}
	out := State{SelfOnly: true}
	if found {
		out.SelfWish = wishInfo(wish)
		out.WishFlag = 1
	}
	return out, true, nil
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
