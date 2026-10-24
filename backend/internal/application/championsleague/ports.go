// Package championsleague composes the canonical League owner through existing
// I4, I5, Combat, Character, Achievement and display ports. No foreign SQL.
package championsleague

import (
	"context"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/application/playerroot"
	d "gxb.local/backend/v2/internal/domain/championsleague"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store interface {
	RootTx(context.Context, tx.Queryer, bool) (d.Root, bool, error)
	PutRootTx(context.Context, tx.Tx, d.Root, int64) error
	PlayersTx(context.Context, tx.Queryer, bool) ([]d.Player, error)
	PutPlayerTx(context.Context, tx.Tx, d.Player, int64) error
	MatchTx(context.Context, tx.Queryer, ids.UUID) (d.Match, bool, error)
	IntentTx(context.Context, tx.Queryer, identity.PlayerID, int64) (d.Match, bool, error)
	PutMatchTx(context.Context, tx.Tx, d.Match, int64) (d.Match, error)
	OpenTx(context.Context, tx.Queryer, int) ([]d.Match, error)
	RecordsTx(context.Context, tx.Queryer, identity.PlayerID) ([]d.Match, error)
	SettlementTx(context.Context, tx.Queryer, string, int64) (d.Settlement, bool, error)
	PutSettlementTx(context.Context, tx.Tx, d.Settlement) error
	OriginsTx(context.Context, tx.Queryer, identity.PlayerID) ([]OriginAward, error)
	PutOriginTx(context.Context, tx.Tx, OriginAward) error
}
type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	LeagueCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error)
}
type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}
type Roster interface {
	OverlayMID1(context.Context, tx.Queryer, identity.ActorContext, bool, time.Time, map[string]any) error
}
type Guilds interface {
	ReadMembershipTx(context.Context, tx.Queryer, identity.PlayerID) (guild.Membership, bool, error)
	ReadGuildTx(context.Context, tx.Queryer, guild.ID) (guild.Guild, bool, error)
}
type Progression interface {
	ReadProgressionTx(context.Context, tx.Queryer, identity.PlayerID) (player.Progression, error)
	ReadFunctionEligibilityTx(context.Context, tx.Queryer, identity.PlayerID, int64) (player.FunctionEligibility, bool, error)
}
type Directory interface {
	ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error)
}
type Combat interface {
	StartTx(context.Context, tx.Tx, ca.CoherentReadScope, combat.StartRequest) (combat.Started, error)
	ResolveDetached(context.Context, operation.Context, ids.UUID) *combat.Flight
	TerminalTx(context.Context, tx.Tx, combat.TerminalRequest) (combat.Settled, error)
	CloseTx(context.Context, tx.Tx, combat.TerminalRequest) (combat.Closed, error)
	ResultTx(context.Context, tx.Queryer, ids.UUID) (combat.Resolved, error)
	ReplayTx(context.Context, tx.Queryer, ids.UUID, cd.Retention, time.Time) (combat.Resolved, bool, error)
	AttemptTx(context.Context, tx.Queryer, ids.UUID) (cd.Attempt, bool, error)
}
type Mail interface {
	DeliverTx(context.Context, tx.Tx, i5.SettlementMailRequest) (mail.Record, bool, error)
}
type Achievements interface {
	ObserveLeagueDaysTx(context.Context, tx.Tx, identity.PlayerID, string, int64, time.Time) error
}
type Recipient interface {
	ReceiveOriginTx(context.Context, tx.Tx, playerroot.Root, playerdisplay.Origin) error
}
type Entitlements interface {
	ReadDisplayEntitlementsTx(context.Context, tx.Queryer, identity.PlayerID, string) ([]playerdisplay.Origin, error)
}
type Service struct {
	Timed        gen.TimedRunner
	Fresh        tx.Queryer
	Store        Store
	Content      Content
	Fence        Fence
	Heroes, Pets Roster
	Directory    Directory
	Guilds       Guilds
	Progression  Progression
	Combat       Combat
	Grants       i5.TxGrantSettler
	Mail         Mail
	Achievements Achievements
	Players      playerroot.TxLocker
	Recipient    Recipient
	Entitlements Entitlements
	Receipts     receipt.Store
	ReceiptRead  receipt.Reader
}

func (s Service) ready() bool {
	return s.Timed.Runner.DB != nil && s.Timed.Binder.Time != nil && s.Fresh != nil && s.Store != nil && s.Content != nil && s.Fence != nil && s.Heroes != nil && s.Pets != nil && s.Directory != nil && s.Guilds != nil && s.Progression != nil && s.Combat != nil && s.Grants != nil && s.Mail != nil && s.Achievements != nil && s.Players != nil && s.Recipient != nil && s.Entitlements != nil && s.Receipts != nil && s.ReceiptRead != nil
}

// Command carries owned instance identities, never Region Arena table IDs.
type Command struct {
	Kind        string
	Enemy       identity.PlayerID
	Lineup      d.Lineup
	UseOriginal bool
	RecordID    int64
}
type EnemyView = d.EnemyView
type InfoView = d.InfoView
type Item = d.Item
type Reply = d.Reply

// OriginAward binds one grant to the immutable genuine season placement.
type OriginAward struct {
	Origin    playerdisplay.Origin
	Season    int64
	Placement d.Placement
	Count     int64
}
