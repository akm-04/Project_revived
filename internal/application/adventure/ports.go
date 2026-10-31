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
	"gxb.local/backend/v2/internal/application/sharedroom"
	"gxb.local/backend/v2/internal/domain/character"
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
	ListOccurrencesTx(context.Context, tx.Queryer, identity.PlayerID) ([]d.Occurrence, error)
	ReadOccurrenceTx(context.Context, tx.Queryer, identity.PlayerID, int64) (d.Occurrence, bool, error)
	FinishOccurrenceTx(context.Context, tx.Tx, identity.PlayerID, int64, time.Time, time.Time) (bool, error)
	InsertAttemptTx(context.Context, tx.Tx, d.SingleAttempt) error
	FindLatestAttemptTx(context.Context, tx.Queryer, identity.PlayerID, int64) (d.SingleAttempt, bool, error)
	SaveAttemptTx(context.Context, tx.Tx, d.SingleAttempt) error
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

type Heroes interface {
	OverlayMID1(context.Context, tx.Queryer, identity.ActorContext, bool, time.Time, map[string]any) error
}

type Combat interface {
	StartTx(context.Context, tx.Tx, ca.CoherentReadScope, cb.StartRequest) (cb.Started, error)
	AttestSummaryTx(context.Context, tx.Tx, cb.SummaryRequest) (cb.SummaryAttested, error)
	Resolve(context.Context, operation.Context, ids.UUID) (cb.Resolved, error)
	TerminalTx(context.Context, tx.Tx, cb.TerminalRequest) (cb.Settled, error)
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

// Opponent is one 10004 target: an Arena player defense or a robot team.
type Opponent struct {
	PlayerID       identity.PlayerID
	Heroes         []int64
	PetID          int64
	TemplateHeroes []cb.Participant
}

type Opponents interface {
	ArenaOpponentTx(context.Context, tx.Queryer, identity.PlayerID, int64, uint64) (Opponent, bool, error)
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
	Heroes    Heroes
	Combat    Combat
	Costs     Costs
	Grants    Grants
	Opponents Opponents
	Wake      Wake
	Rooms     sharedroom.Service
	RoomStore sharedroom.Store
	Mail      Mail
	Partners  Partners
	HeroWire  HeroWire
}

func (s Mode) ready() bool {
	return s.Timed.Binder.Time != nil && s.Timed.Runner.DB != nil && s.Fresh != nil && s.Store != nil && s.Content != nil &&
		s.Functions != nil && s.Directory != nil && s.Heroes != nil && s.Combat != nil && s.Costs != nil && s.Grants != nil && s.Opponents != nil && s.Wake != nil &&
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
