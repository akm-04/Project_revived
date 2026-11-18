// Package adventure is the Adventure application: the 2416/2417 reads, the
// single-player event actions and the trigger notice reader. Multi-player
// defense and illusion rooms live with SharedRoom in later leaf parts.
package adventure

import (
	"context"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/application/roominvite"
	"gxb.local/backend/v2/internal/application/sharedroom"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/domain/summon"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"

	d "gxb.local/backend/v2/internal/domain/adventure"
)

type Store interface {
	ListOccurrencesTx(context.Context, tx.Queryer, identity.LogicalServerID, identity.PlayerID, time.Time, int64) ([]d.Occurrence, error)
	ReadOccurrenceTx(context.Context, tx.Queryer, identity.PlayerID, int64) (d.Occurrence, bool, error)
	ReadOccurrenceBySourceKeyTx(context.Context, tx.Queryer, identity.PlayerID, int64, string) (d.Occurrence, bool, error)
	FinishOccurrenceTx(context.Context, tx.Tx, identity.PlayerID, int64, time.Time, time.Time) (bool, error)
	InsertSettlementTx(context.Context, tx.Tx, ids.UUID, identity.PlayerID, int64, time.Time) error
	ReadSettlementTx(context.Context, tx.Queryer, ids.UUID) (int64, bool, error)
	InsertReportTx(context.Context, tx.Tx, string, int64, int64, []int64, string, time.Time) error
	ReadReportTx(context.Context, tx.Queryer, string, int64, identity.PlayerID, time.Time) (string, bool, error)
	PurgeExpiredReportsTx(context.Context, tx.Tx, time.Time, int, int64) (int64, error)
	PurgeOccurrencesTx(context.Context, tx.Tx, time.Time, int64) (int64, error)
}

type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	AdventureCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error)
	IllusionCatalogTx(context.Context, tx.Queryer, string) (illusion.Catalog, error)
	SummonCatalogTx(context.Context, tx.Queryer, string) (summon.Catalog, error)
}

type Functions interface {
	ReadFunctionEligibilityTx(context.Context, tx.Queryer, identity.PlayerID, int64) (player.FunctionEligibility, bool, error)
}

type Directory interface {
	ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error)
}

// Guilds is the I6C owner's typed guild identity read for room member rows.
type Guilds interface {
	GuildNamesTx(context.Context, tx.Queryer, identity.LogicalServerID, []identity.PlayerID) (map[identity.PlayerID]string, error)
}

// Roster is the existing stock roster composer (MID1 key 49 Heroes, 780 Pets).
type Roster interface {
	OverlayMID1(context.Context, tx.Queryer, identity.ActorContext, bool, time.Time, map[string]any) error
}

// Stats reads the qualified public force the team window displays.
type Stats interface {
	HeroTx(context.Context, ca.CoherentReadScope, character.HeroRef, publicstats.View) (publicstats.Result, error)
}

type Combat interface {
	StartTx(context.Context, tx.Tx, ca.CoherentReadScope, cb.StartRequest) (cb.Started, error)
	CurrentAttemptTx(context.Context, tx.Queryer, cd.Locator) (cb.CurrentAttempt, bool, error)
	AttestSummaryTx(context.Context, tx.Tx, cb.SummaryRequest) (cb.SummaryAttested, error)
	Resolve(context.Context, operation.Context, ids.UUID) (cb.Resolved, error)
	TerminalTx(context.Context, tx.Tx, cb.TerminalRequest) (cb.Settled, error)
	SettleMemberTx(context.Context, tx.Tx, cb.MemberSettleRequest) (cb.MemberSettled, error)
	CloseTx(context.Context, tx.Tx, cb.TerminalRequest) (cb.Closed, error)
	MonsterWaves(int64) ([][]cb.Participant, error)
}

type Mail interface {
	DeliverTx(context.Context, tx.Tx, i5.SettlementMailRequest) (mail.Record, bool, error)
}

// Partners materializes an adventure card's hero through the Character owner.
type Partners interface {
	AwardStoryPartnerTx(context.Context, tx.Tx, identity.PlayerID, int64, string, operation.Context) (character.Hero, *character.CollectionAdmissionProof, error)
}

type HeroWire func(character.Hero) (map[string]any, error)

type Costs interface {
	DebitMaterialCostTx(context.Context, tx.Tx, identity.PlayerID, i5.MaterialCost, operation.Context) (i5.MaterialDebitResult, error)
}

type Grants interface {
	SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error)
}

// Opponent is one 10004 target: an Arena player defense or a robot team, both
// already resolved to typed Combat participants by their owner.
type Opponent struct {
	PlayerID identity.PlayerID
	Name     string
	Level    int64
	Heroes   []cb.Participant
	Pets     []cb.Participant
}

type Opponents interface {
	ArenaOpponentTx(context.Context, tx.Queryer, identity.PlayerID, int64, uint64, time.Time) (Opponent, bool, error)
	RobotOpponentTx(context.Context, tx.Queryer, uint64) (Opponent, bool, error)
}

// Wake emits the commit-coupled realtime wakeup that carries notices 33 and 34.
type Wake interface {
	WakeAdventureNotice(context.Context, tx.Execer, identity.PlayerID) error
}

type Mode struct {
	Timed     gen.TimedRunner
	Fresh     tx.Queryer
	Store     Store
	Content   Content
	Functions Functions
	Directory Directory
	Guilds    Guilds
	Heroes    Roster
	Pets      Roster
	Stats     Stats
	Combat    Combat
	Costs     Costs
	Grants    Grants
	Opponents Opponents
	Wake      Wake
	Rooms     sharedroom.Service
	RoomStore sharedroom.Store
	Invites   roominvite.Materializer
	Mail      Mail
	Partners  Partners
	HeroWire  HeroWire
	// RetentionDays is the R8 cap (U4) on the owner's report window; zero
	// keeps the owner window alone.
	RetentionDays int
}

func (s Mode) ready() bool {
	return s.Timed.Binder.Time != nil && s.Timed.Runner.DB != nil && s.Fresh != nil && s.Store != nil && s.Content != nil &&
		s.Functions != nil && s.Directory != nil && s.Guilds != nil && s.Heroes != nil && s.Pets != nil && s.Combat != nil && s.Costs != nil && s.Grants != nil && s.Opponents != nil && s.Wake != nil &&
		s.Rooms.Store != nil && s.RoomStore != nil && s.Mail != nil && s.Partners != nil && s.HeroWire != nil
}

type FightRequest struct {
	Formation []int64
	PetID     int64
}

type ResultRequest struct {
	Star      int64
	Damage    int64
	PetID     int64
	Formation []int64
}

type Response struct {
	Body      map[string]any
	Duplicate bool
}
