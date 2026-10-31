// Package occult is the Sorcery War application: solo rooms on the shared room
// core, tickets and rewards through I5, and awakening fragments by mission.
package occult

import (
	"context"
	"encoding/json"
	"time"

	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/application/sharedroom"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	d "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"

	ca "gxb.local/backend/v2/internal/application/characterasset"
)

// Store owns the rank-605 player row and the run, report and log rows.
type Store interface {
	LockPlayerTx(context.Context, tx.Tx, int64, identity.PlayerID, time.Time) (d.Scores, error)
	ReadScoresTx(context.Context, tx.Queryer, identity.PlayerID) (d.Scores, error)
	SaveScoresTx(context.Context, tx.Tx, identity.PlayerID, d.Scores, time.Time) error
	InsertRunTx(context.Context, tx.Tx, int64, int64, int64, int64, time.Time) error
	FinishRunTx(context.Context, tx.Tx, int64, time.Time) error
	InsertReportTx(context.Context, tx.Tx, string, int64, int64, []int64, string, time.Time) error
	ReadReportTx(context.Context, tx.Queryer, string, int64, identity.PlayerID, time.Time) (string, bool, error)
	InsertLogTx(context.Context, tx.Tx, int64, int64, int, identity.PlayerID, string, time.Time) error
	ReadLogsTx(context.Context, tx.Queryer, int64, identity.PlayerID, int64) ([]json.RawMessage, error)
}

type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	OccultCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error)
}

type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

type Players interface {
	LockPlayerRootsTx(context.Context, tx.Tx, identity.LogicalServerID, []identity.PlayerID) ([]playerroot.Root, error)
}

// Functions is the F6 function gate for function 67.
type Functions interface {
	ReadFunctionEligibilityTx(context.Context, tx.Queryer, identity.PlayerID, int64) (player.FunctionEligibility, bool, error)
}

type Directory interface {
	ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error)
}

// Heroes is the stock roster composer (MID1 key 49).
type Heroes interface {
	OverlayMID1(context.Context, tx.Queryer, identity.ActorContext, bool, time.Time, map[string]any) error
}

type Combat interface {
	StartTx(context.Context, tx.Tx, ca.CoherentReadScope, cb.StartRequest) (cb.Started, error)
	AttestSummaryTx(context.Context, tx.Tx, cb.SummaryRequest) (cb.SummaryAttested, error)
	Resolve(context.Context, operation.Context, ids.UUID) (cb.Resolved, error)
	TerminalTx(context.Context, tx.Tx, cb.TerminalRequest) (cb.Settled, error)
	SettleMemberTx(context.Context, tx.Tx, cb.MemberSettleRequest) (cb.MemberSettled, error)
	MonsterWaves(int64) ([][]cb.Participant, error)
}

// Values settles rewards through I5; the mode never writes a stack itself.
type Values interface {
	SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error)
}

// Awakening supplies the ordinary-hero fragment of the active stage-1 mission.
type Awakening = i5.AwakeningOccultMaterialPort

type Facts interface {
	PrepareTx(context.Context, tx.Tx, identity.PlayerID, gen.TimedOperation) (context.Context, error)
	RecordTx(context.Context, tx.Tx, operation.Context, ...objective.Fact) error
}

type Mode struct {
	Timed       gen.TimedRunner
	Fresh       tx.Queryer
	Store       Store
	Content     Content
	Fence       Fence
	Players     Players
	Functions   Functions
	Directory   Directory
	Heroes      Heroes
	Pets        Heroes
	Rooms       sharedroom.Service
	RoomStore   sharedroom.Store
	Combat      Combat
	Tickets     i5.OccultTicketPort
	Values      Values
	Awakening   Awakening
	Facts       Facts
	Receipts    receipt.Store
	ReceiptRead receipt.Reader
}

func (s Mode) ready() bool {
	return s.Timed.Binder.Time != nil && s.Fresh != nil && s.Store != nil && s.Content != nil && s.Fence != nil && s.Players != nil &&
		s.Functions != nil && s.Directory != nil && s.Heroes != nil && s.Combat != nil && s.Tickets != nil && s.Values != nil &&
		s.Awakening != nil && s.Facts != nil && s.Receipts != nil && s.ReceiptRead != nil && s.Rooms.Store != nil && s.RoomStore != nil
}
