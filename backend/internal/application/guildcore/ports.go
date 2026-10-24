package guildcore

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type ActorFencer interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

type Store interface {
	LockAllocatorTx(context.Context, tx.Tx, identity.LogicalServerID, time.Time) (int64, int64, error)
	AdvanceAllocatorTx(context.Context, tx.Tx, identity.LogicalServerID, int64, int64, time.Time) error
	InsertGuildTx(context.Context, tx.Tx, guild.Guild) error
	LockGuildTx(context.Context, tx.Tx, guild.ID) (guild.Guild, bool, error)
	ReadGuild(context.Context, guild.ID) (guild.Guild, bool, error)
	GuildNameInUseTx(context.Context, tx.Queryer, identity.LogicalServerID, string, guild.ID) (bool, error)
	SaveGuildTx(context.Context, tx.Tx, guild.Guild, int64) error
	ListGuilds(context.Context, identity.LogicalServerID, int) ([]guild.Guild, error)
	LockMembershipTx(context.Context, tx.Tx, identity.PlayerID) (guild.Membership, bool, error)
	ReadMembership(context.Context, identity.PlayerID) (guild.Membership, bool, error)
	InsertMembershipTx(context.Context, tx.Tx, guild.Membership) error
	SaveMembershipRoleTx(context.Context, tx.Tx, guild.Membership, int64) error
	DeleteMembershipTx(context.Context, tx.Tx, identity.PlayerID, guild.ID, int64) error
	CountMembersTx(context.Context, tx.Queryer, guild.ID) (int64, error)
	CountRoleTx(context.Context, tx.Queryer, guild.ID, guild.Role) (int64, error)
	AppendMembershipEventTx(context.Context, tx.Tx, guild.MembershipEvent, ids.UUID) error
	LatestMembershipEventTx(context.Context, tx.Queryer, identity.PlayerID) (guild.MembershipEvent, bool, error)
	CountJoinsSinceTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (int64, error)
	LastDepartureTx(context.Context, tx.Queryer, identity.PlayerID) (guild.ID, guild.MembershipEventKind, time.Time, bool, error)
	MembershipEpochTx(context.Context, tx.Queryer, identity.PlayerID) (int64, error)
	FindApplicationTx(context.Context, tx.Queryer, guild.ID, identity.PlayerID) (guild.Application, bool, error)
	LockApplicationTx(context.Context, tx.Tx, guild.ID, identity.PlayerID) (guild.Application, bool, error)
	InsertApplicationTx(context.Context, tx.Tx, guild.Application) error
	DeleteApplicationTx(context.Context, tx.Tx, guild.ID, identity.PlayerID) error
	DeleteApplicationsForPlayerTx(context.Context, tx.Tx, identity.PlayerID) error
	DeleteGuildApplicationsTx(context.Context, tx.Tx, guild.ID) error
	CountOutgoingApplicationsTx(context.Context, tx.Queryer, identity.PlayerID) (int64, error)
	CountGuildApplicationsTx(context.Context, tx.Queryer, guild.ID) (int64, error)
	ListGuildApplications(context.Context, guild.ID) ([]guild.Application, error)
	ListPlayerApplications(context.Context, identity.PlayerID) ([]guild.Application, error)
	FindInviteTx(context.Context, tx.Queryer, guild.ID, identity.PlayerID) (guild.Invite, bool, error)
	LockInviteTx(context.Context, tx.Tx, guild.ID, identity.PlayerID) (guild.Invite, bool, error)
	UpsertInviteTx(context.Context, tx.Tx, guild.Invite) error
	DeleteInviteTx(context.Context, tx.Tx, guild.ID, identity.PlayerID) error
	DeleteGuildInvitesTx(context.Context, tx.Tx, guild.ID) error
	CountInvitesSinceTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (int64, error)
	AppendInviteSendTx(context.Context, tx.Tx, guild.ID, identity.PlayerID, identity.PlayerID, time.Time, string, ids.UUID) error
	ListMemberships(context.Context, guild.ID) ([]guild.Membership, error)
	AppendAuditTx(context.Context, tx.Tx, guild.ID, string, identity.PlayerID, identity.PlayerID, time.Time, string, ids.UUID, string) error
}

type PlayerRootLocker = playerroot.TxLocker

type LevelReader = i5.TxPlayerLevelReader
type ScalarDebiter = i5.TxScalarDebiter
type LevelAndScalarDebiter = i5.TxLevelAndScalarDebiter

type ReceiptStore interface {
	receipt.Store
}
