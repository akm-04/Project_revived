package guildbroadcast

import (
	"context"
	"gxb.local/backend/v2/internal/domain/guild"
	gb "gxb.local/backend/v2/internal/domain/guildbroadcast"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// GuildReader is owner-local I6C access. It closes the source-time roster under
// the Guild root before mutations; adapters never read foreign Player/Mail SQL.
type GuildReader interface {
	LockGuildTx(context.Context, tx.Tx, guild.ID) (guild.Guild, bool, error)
	LockMembershipTx(context.Context, tx.Tx, identity.PlayerID) (guild.Membership, bool, error)
	ListMembershipsTx(context.Context, tx.Queryer, guild.ID) ([]guild.Membership, error)
	LatestMembershipEventTx(context.Context, tx.Queryer, identity.PlayerID) (guild.MembershipEvent, bool, error)
}

// Store receives the caller transaction. No internal transaction/commit, Mail
// write or job-completion based settlement is permitted.
type Store interface {
	ReadSourceTx(context.Context, tx.Queryer, ids.UUID) (gb.Source, bool, error)
	ReadBindingTx(context.Context, tx.Queryer, ids.UUID, identity.PlayerID) (gb.Binding, bool, error)
	InsertSourceTx(context.Context, tx.Tx, gb.Source, ids.UUID) error
	InsertBindingTx(context.Context, tx.Tx, gb.Binding, gb.Member) error
}

// SchedulingReader is a delivery accelerator only. PENDING source facts remain
// authoritative when jobs are missing, discarded or acknowledged ambiguously.
type SchedulingReader interface {
	ListPendingTx(context.Context, tx.Queryer, time.Time, int) ([]gb.Binding, error)
}

// ContentPolicy binds the finite source policy to its durable content revision.
type ContentPolicy struct {
	Revision          string
	GuildCoreRevision string
	PolicyID          string
	StoragePolicyID   string
	TextSourceSHA256  string
	MemberCap         int
}

func (p ContentPolicy) Validate() error {
	if !gb.ValidRevision(p.Revision) || !gb.ValidRevision(p.GuildCoreRevision) || p.PolicyID != gb.PolicyID || p.StoragePolicyID != gb.StoragePolicyID || p.TextSourceSHA256 != gb.TextSourceSHA256 || p.MemberCap != gb.MaxRecipients {
		return gb.ErrSource
	}
	return nil
}

type ContentReader interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	ReadBroadcastPolicy(context.Context, tx.Queryer, string) (ContentPolicy, error)
}

// AckStore locks only the source recipient leaf, after any typed I4 proof fence.
// Target Mail owns its transaction and commit; Guild owns this separate ACK.
type AckStore interface {
	SourceStore
	LockBindingTx(context.Context, tx.Tx, ids.UUID, identity.PlayerID) (gb.Binding, bool, error)
	AcknowledgeBindingTx(context.Context, tx.Tx, gb.TargetProof, time.Time) error
}
type Target interface {
	Materialize(context.Context, ids.UUID, identity.PlayerID) (gb.TargetProof, error)
	ReadGuildBroadcastProofTx(context.Context, tx.Tx, ids.UUID, identity.PlayerID) (gb.TargetProof, bool, error)
}
