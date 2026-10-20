// Package arena composes the Arena owner (C5D_ARENA_SEASON_MODE_V1): entry,
// defense, matching, START/FIGHT/STOP through the Combat foundation, terminal
// star/point settlement, missions, exchanges, season settlement mail and
// history facts. Combat, I5, Achievement, Character, Guild and identity keep
// their ownership behind these ports.
package arena

import (
	"context"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	d "gxb.local/backend/v2/internal/domain/arena"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store interface {
	ReadCompetitionTx(context.Context, tx.Queryer, bool) (d.Competition, bool, error)
	CreateCompetitionTx(context.Context, tx.Tx, d.Competition) error
	SaveCompetitionTx(context.Context, tx.Tx, d.Competition, int64) error
	ReadPlayerTx(context.Context, tx.Queryer, identity.PlayerID, bool) (d.Player, bool, error)
	InsertPlayerTx(context.Context, tx.Tx, d.Player, string) error
	SavePlayerTx(context.Context, tx.Tx, d.Player, int64) error
	StandingsTx(context.Context, tx.Queryer, int64) ([]d.Standing, error)
	ReadMatchTx(context.Context, tx.Queryer, ids.UUID, bool) (d.Match, bool, error)
	LatestMatchTx(context.Context, tx.Queryer, identity.PlayerID) (d.Match, bool, error)
	OpenMatchesTx(context.Context, tx.Queryer, time.Time, int) ([]ids.UUID, error)
	InsertMatchTx(context.Context, tx.Tx, d.Match) error
	SaveMatchTx(context.Context, tx.Tx, d.Match, int64) error
	InsertRecordTx(context.Context, tx.Tx, d.Record, int64) error
	RecordsTx(context.Context, tx.Queryer, identity.PlayerID) ([]d.Record, error)
	RetainedAttemptTx(context.Context, tx.Queryer, ids.UUID) (bool, error)
	AddUsageTx(context.Context, tx.Tx, identity.PlayerID, int64, []cd.PartnerUse) error
	UsageTx(context.Context, tx.Queryer, identity.PlayerID, int64) ([]d.Usage, error)
	InsertSettlementTx(context.Context, tx.Tx, d.Settlement) error
}

type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	ArenaCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error)
	ArenaTemplatesTx(context.Context, tx.Queryer, string) (d.Templates, error)
}

type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

type Mail interface {
	DeliverTx(context.Context, tx.Tx, i5.SettlementMailRequest) (mail.Record, bool, error)
}

type Grants interface {
	SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error)
}

type Values interface {
	ReadScalarTx(context.Context, tx.Queryer, identity.PlayerID, string) (economy.ScalarBalance, bool, error)
}

type Achievements interface {
	ObserveArenaWinStreakTx(context.Context, tx.Tx, identity.PlayerID, string, int64, time.Time) error
}

type Combat interface {
	StartTx(context.Context, tx.Tx, ca.CoherentReadScope, combat.StartRequest) (combat.Started, error)
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

type Guilds interface {
	ReadMembershipTx(context.Context, tx.Queryer, identity.PlayerID) (guild.Membership, bool, error)
	ReadGuildTx(context.Context, tx.Queryer, guild.ID) (guild.Guild, bool, error)
}

type Servers interface {
	ServerNameTx(context.Context, tx.Queryer, identity.LogicalServerID) (string, error)
}

type Service struct {
	Timed        gen.TimedRunner
	Fresh        tx.Queryer
	Store        Store
	Content      Content
	Fence        Fence
	Costs        i5.TxMaterialCostDebiter
	Grants       Grants
	Values       Values
	Mail         Mail
	Achievements Achievements
	Combat       Combat
	Heroes       Roster
	Pets         Roster
	Directory    Directory
	Guilds       Guilds
	Servers      Servers
	Receipts     receipt.Store
	ReceiptRead  receipt.Reader
}

func (s Service) ready() bool {
	return s.Timed.Runner.DB != nil && s.Timed.Binder.Time != nil && s.Fresh != nil && s.Store != nil && s.Content != nil && s.Fence != nil && s.Costs != nil && s.Grants != nil &&
		s.Values != nil && s.Mail != nil && s.Achievements != nil && s.Combat != nil && s.Heroes != nil && s.Pets != nil && s.Directory != nil && s.Guilds != nil && s.Servers != nil &&
		s.Receipts != nil && s.ReceiptRead != nil
}
