// Package guildinvite coordinates the finite Guild Invite presentation source
// and target commands. Every persisted owner is reached through its typed port.
package guildinvite

import (
	"context"
	"gxb.local/backend/v2/internal/domain/guild"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// HistoricalGenerationReader exposes only the retained finite I6C Invite
// generation witness. It is implemented by Foundation, never Guild SQL.
type HistoricalGenerationReader interface {
	GuildInviteGenerationHighWaterTx(context.Context, tx.Queryer, guild.ID, identity.PlayerID) (int64, error)
}

type ContentPolicy struct {
	Revision, GuildCoreRevision, PolicyID string
}

type ContentReader interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	ReadInvitePolicy(context.Context, tx.Queryer, string) (ContentPolicy, bool, error)
}

// Store is Guild-only SQL. Source and lifecycle payloads are immutable; ACK and
// scheduling progress are separate rows/fields and excluded from fingerprints.
type Store interface {
	LockCursorTx(context.Context, tx.Tx, guild.ID, identity.PlayerID) (int64, int64, error)
	AdvanceCursorTx(context.Context, tx.Tx, gi.Tuple, int64, time.Time) error
	PrepareScopeTx(context.Context, tx.Tx, guild.ID) error
	ReadRetainedValidityTx(context.Context, tx.Queryer, gi.Issue) (ids.UUID, error)
	NextIssueSerialTx(context.Context, tx.Queryer) (int64, error)
	IssueHighWaterTx(context.Context, tx.Queryer) (int64, error)
	LatestMarkerSourceDecisionTx(context.Context, tx.Queryer, gi.MarkerKind, guild.ID, identity.PlayerID, int64) (time.Time, bool, error)
	InsertIssueTx(context.Context, tx.Tx, gi.Issue, gi.Delivery) error
	ReadIssueTx(context.Context, tx.Queryer, ids.UUID) (gi.Issue, bool, error)
	ReadIssueTupleTx(context.Context, tx.Queryer, gi.Tuple) (gi.Issue, bool, error)
	InsertMarkerTx(context.Context, tx.Tx, gi.Marker, gi.MarkerProgress) error
	ReadMarkerTx(context.Context, tx.Queryer, ids.UUID) (gi.Marker, gi.MarkerProgress, bool, error)
	FindMarkerForEventTx(context.Context, tx.Queryer, int64) (ids.UUID, error)
	SourceSetThroughCursorTx(context.Context, tx.Queryer, gi.Marker, int64) (gi.SetWitness, error)
	CoveredSourcePayloadsTx(context.Context, tx.Queryer, gi.Marker, int64) (gi.OwnerPayloadSet, error)
	LockMarkerTx(context.Context, tx.Tx, ids.UUID) (gi.Marker, gi.MarkerProgress, bool, error)
	AdvanceProvenMarkerTx(context.Context, tx.Tx, gi.MarkerProgress, gi.CursorProof) error
	ReadDeliveryTx(context.Context, tx.Queryer, ids.UUID) (gi.Delivery, bool, error)
	LockDeliveryTx(context.Context, tx.Tx, ids.UUID) (gi.Delivery, bool, error)
	AcknowledgeDeliveryTx(context.Context, tx.Tx, gi.TargetProof, time.Time) error
	ReadMarkerPageTx(context.Context, tx.Queryer, gi.Marker, gi.MarkerProgress, int) ([]gi.Issue, error)
}

// GuildBindings is the current/event owner, separate from retained source SQL.
// The exact event ID comes from INSERT RETURNING, never a max/id guess.
type GuildBindings interface {
	UpsertInviteForProjectionTx(context.Context, tx.Tx, guild.Invite) error
	LatestJoinTx(context.Context, tx.Queryer, identity.PlayerID) (guild.MembershipEvent, bool, error)
	ReadGuildInviteSnapshotTx(context.Context, tx.Queryer, gi.Issue) (gi.Snapshot, error)
	AppendMembershipEventReturningTx(context.Context, tx.Tx, guild.MembershipEvent, ids.UUID) (guild.MembershipEvent, error)
	AppendInviteSendReturningTx(context.Context, tx.Tx, guild.ID, identity.PlayerID, identity.PlayerID, time.Time, string, ids.UUID) (int64, error)
	BindInviteIssueTx(context.Context, tx.Tx, gi.Issue) error
	BindMembershipMarkerTx(context.Context, tx.Tx, gi.Marker) error
	ReadInviteIssueIDTx(context.Context, tx.Queryer, guild.ID, identity.PlayerID) (ids.UUID, error)
	ReadMembershipMarkerIDTx(context.Context, tx.Queryer, int64) (ids.UUID, error)
	ReadRetirementEventTx(context.Context, tx.Queryer, guild.ID) (guild.MembershipEvent, bool, error)
	PrepareMembershipCleanupTx(context.Context, tx.Tx, identity.PlayerID) error
	PrepareRetirementChildrenTx(context.Context, tx.Tx, guild.ID) error
	ValidateIssueBindingsTx(context.Context, tx.Queryer, gi.Issue) error
	ValidateMarkerBindingsTx(context.Context, tx.Queryer, gi.Marker) error
}

// ImmutableReader proves the complete source/core receipt and exact bindings
// before crossing owner boundaries. Snapshot is read-only and takes no Guild
// root lock in target/read transactions.
type ImmutableReader interface {
	ReadIssueTupleEvidenceTx(context.Context, tx.Queryer, gi.Tuple) (gi.Issue, error)
	ReadIssueDeliveryEvidenceTx(context.Context, tx.Queryer, ids.UUID) (gi.Delivery, error)
	ReadIssueEvidenceTx(context.Context, tx.Queryer, ids.UUID) (gi.Issue, error)
	ReadMarkerEvidenceTx(context.Context, tx.Queryer, ids.UUID) (gi.Marker, error)
	ReadInviteSnapshotTx(context.Context, tx.Queryer, ids.UUID) (gi.Snapshot, error)
}

type Target interface {
	Materialize(context.Context, ids.UUID) (gi.TargetProof, error)
	Invalidate(context.Context, ids.UUID, ids.UUID) (gi.InvalidationProof, error)
	ReadInviteTargetProofTx(context.Context, tx.Queryer, ids.UUID) (gi.TargetProof, bool, error)
	ReadInviteInvalidationProofTx(context.Context, tx.Queryer, ids.UUID, ids.UUID) (gi.InvalidationProof, bool, error)
}

type ProgressTarget interface {
	Target
	ValidateCoveredInviteInvalidationsTx(context.Context, tx.Queryer, gi.Marker, int64, gi.SetWitness) error
	CoveredTargetPayloadsTx(context.Context, tx.Queryer, gi.Marker, int64) (gi.OwnerPayloadSet, error)
}

type ReceiptWitness interface {
	GuildInviteReceiptSetWitnessTx(context.Context, tx.Queryer, []ids.UUID) (gi.SetWitness, error)
}
