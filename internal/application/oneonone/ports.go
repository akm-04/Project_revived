// Package oneonone composes the 1 on 1 owner (C5C_ONE_ON_ONE_MODE_V1): entry,
// teams, candidates, multi-round START through the Combat foundation, terminal
// slot/points settlement, promotion, Wednesday/Sunday mail settlement, titles
// and history facts. Combat, I5, Achievement, Character and PlayerDisplay keep
// their ownership behind these ports.
package oneonone

import (
	"context"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	appdisplay "gxb.local/backend/v2/internal/application/playerdisplay"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	d "gxb.local/backend/v2/internal/domain/oneonone"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store interface {
	ReadCompetitionTx(context.Context, tx.Queryer, bool) (d.Competition, bool, error)
	CreateCompetitionTx(context.Context, tx.Tx, d.Competition) error
	SaveCompetitionTx(context.Context, tx.Tx, d.Competition, int64) error
	ReadPlayerTx(context.Context, tx.Queryer, identity.PlayerID, bool) (d.Player, d.Totals, bool, error)
	PromotingTx(context.Context, tx.Queryer) ([]identity.PlayerID, error)
	InsertPlayerTx(context.Context, tx.Tx, d.Player) error
	SavePlayerTx(context.Context, tx.Tx, d.Player, int64, d.Totals) error
	StandingsTx(context.Context, tx.Queryer) ([]d.Standing, error)
	ReadMatchTx(context.Context, tx.Queryer, ids.UUID, bool) (d.Match, bool, error)
	LatestMatchTx(context.Context, tx.Queryer, identity.PlayerID) (d.Match, bool, error)
	OpenMatchesTx(context.Context, tx.Queryer, time.Time, int) ([]ids.UUID, error)
	InsertMatchTx(context.Context, tx.Tx, d.Match) error
	FinishMatchTx(context.Context, tx.Tx, d.Match, int64) error
	InsertRecordTx(context.Context, tx.Tx, d.Record, int64) error
	RecordsTx(context.Context, tx.Queryer, identity.PlayerID) ([]d.Record, error)
	RecordTx(context.Context, tx.Queryer, int64) (d.Record, bool, error)
	RetainedRoundTx(context.Context, tx.Queryer, ids.UUID) (bool, error)
	AddUsageTx(context.Context, tx.Tx, identity.PlayerID, []cd.PartnerUse) error
	InsertSettlementTx(context.Context, tx.Tx, d.Settlement) error
	TitlesTx(context.Context, tx.Queryer, identity.PlayerID, int64) ([]d.TitleAward, error)
}

type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	OneOnOneCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error)
	ReadPlayerDisplayCatalogTx(context.Context, tx.Queryer, string) (player.DisplayCatalog, error)
}

type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

type Mail interface {
	DeliverTx(context.Context, tx.Tx, i5.SettlementMailRequest) (mail.Record, bool, error)
}

type Achievements interface {
	ObserveOneOnOneWeekTx(context.Context, tx.Tx, identity.LogicalServerID, int64, string, []identity.PlayerID, time.Time) error
	ObserveOneOnOneWinStreakTx(context.Context, tx.Tx, identity.PlayerID, string, int64, time.Time) error
}

type Combat interface {
	StartManyTx(context.Context, tx.Tx, ca.CoherentReadScope, []combat.StartRequest) ([]combat.Started, error)
	Resolve(context.Context, operation.Context, ids.UUID) (combat.Resolved, error)
	ResolveDetached(context.Context, operation.Context, ids.UUID) *combat.Flight
	TerminalTx(context.Context, tx.Tx, combat.TerminalRequest) (combat.Settled, error)
	CloseTx(context.Context, tx.Tx, combat.TerminalRequest) (combat.Closed, error)
	ResultTx(context.Context, tx.Queryer, ids.UUID) (combat.Resolved, error)
	AttemptTx(context.Context, tx.Queryer, ids.UUID) (cd.Attempt, bool, error)
}

// Roster is the existing stock roster composer (MID1 key 49 Heroes, 780 Pets).
type Roster interface {
	OverlayMID1(context.Context, tx.Queryer, identity.ActorContext, bool, time.Time, map[string]any) error
}

type Directory interface {
	ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error)
}

// Entitlements is the PlayerDisplay mirror ledger read used to prove title origins.
type Entitlements interface {
	ReadDisplayEntitlementsTx(context.Context, tx.Queryer, identity.PlayerID, string) ([]appdisplay.Origin, error)
}

type Service struct {
	Timed        gen.TimedRunner
	Fresh        tx.Queryer
	Store        Store
	Content      Content
	Fence        Fence
	Privileges   i5.PrivilegeSnapshotProvider
	Costs        i5.TxMaterialCostDebiter
	Mail         Mail
	Achievements Achievements
	Combat       Combat
	Heroes       Roster
	Pets         Roster
	Directory    Directory
	Entitlements Entitlements
	Receipts     receipt.Store
	ReceiptRead  receipt.Reader
}

func (s Service) ready() bool {
	return s.Timed.Runner.DB != nil && s.Timed.Binder.Time != nil && s.Fresh != nil && s.Store != nil && s.Content != nil && s.Fence != nil && s.Privileges != nil && s.Costs != nil &&
		s.Mail != nil && s.Achievements != nil && s.Combat != nil && s.Heroes != nil && s.Pets != nil && s.Directory != nil && s.Entitlements != nil && s.Receipts != nil && s.ReceiptRead != nil
}
