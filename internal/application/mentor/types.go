package mentor

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	"gxb.local/backend/v2/internal/application/socialpresence"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/mentor"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	ErrInvalid     = errors.New("mentor: invalid request")
	ErrRefused     = errors.New("mentor: request refused")
	ErrUnavailable = errors.New("mentor: unavailable")
)

// Refusal is a stock message code (message.lua 34001-34019).
type Refusal struct{ Code int64 }

func (refusal *Refusal) Error() string { return "mentor: refused" }

// State is one player's persisted counters and break cooldown.
type State struct {
	PlayerID     identity.PlayerID
	Server       identity.LogicalServerID
	ApplyDay     time.Time
	CountMentor  int64
	CountStudent int64
	BrokeAt      *time.Time
	Version      int64
}

// Application is one stored request. RecipientSlot is the recipient's new slot,
// the opposite of the role the applicant sought.
type Application struct {
	Applicant     identity.PlayerID
	Target        identity.PlayerID
	Server        identity.LogicalServerID
	RecipientSlot domain.Slot
	Message       string
	CreatedAt     time.Time
	ExpiresAt     time.Time
	Status        string
	Version       int64
}

const (
	ApplicationPending  = "PENDING"
	ApplicationAccepted = "ACCEPTED"
	ApplicationDenied   = "DENIED"
)

// MissionProgress is durable high-water progress and claim state.
type MissionProgress struct {
	PlayerID    identity.PlayerID
	MissionID   int64
	Progress    int64
	CompletedAt *time.Time
	AwardedAt   *time.Time
	Version     int64
}

// ExamReceipt binds one graduation win to its granted items.
type ExamReceipt struct {
	StudentID  identity.PlayerID
	MissionID  int64
	RelationID ids.UUID
	WonAt      time.Time
	Items      []ExamItem
	Version    int64
}

type ExamItem struct {
	ItemID   int64 `json:"item_id"`
	Quantity int64 `json:"quantity"`
}

// CandidateState is another player's slot occupancy and cooldown.
type CandidateState struct {
	HasMentor  bool
	MentorID   identity.PlayerID
	HasStudent bool
	StudentID  identity.PlayerID
	BrokeAt    *time.Time
}

type Store interface {
	ReadRelationshipsTx(context.Context, tx.Queryer, identity.PlayerID, identity.LogicalServerID) ([]domain.Relationship, error)
	LockRelationshipsTx(context.Context, tx.Tx, identity.PlayerID, identity.LogicalServerID) ([]domain.Relationship, error)
	InsertRelationshipTx(context.Context, tx.Tx, domain.Relationship) error
	EndRelationshipTx(context.Context, tx.Tx, domain.Relationship, time.Time) error
	AddIntimacyTx(context.Context, tx.Tx, domain.Relationship, int64, string, time.Time) error

	LockStateTx(context.Context, tx.Tx, identity.PlayerID, identity.LogicalServerID, time.Time) (State, error)
	ReadStateTx(context.Context, tx.Queryer, identity.PlayerID, identity.LogicalServerID) (State, bool, error)
	WriteStateTx(context.Context, tx.Tx, State, State) error

	LockApplicationTx(context.Context, tx.Tx, identity.PlayerID, identity.PlayerID) (Application, bool, error)
	PutApplicationTx(context.Context, tx.Tx, *Application, Application) error
	ListApplicationsToTx(context.Context, tx.Queryer, identity.PlayerID, identity.LogicalServerID, time.Time) ([]Application, error)
	PendingTargetsTx(context.Context, tx.Queryer, identity.PlayerID, identity.LogicalServerID, time.Time) ([]identity.PlayerID, error)

	ReadMissionProgressTx(context.Context, tx.Queryer, identity.PlayerID) ([]MissionProgress, error)
	LockMissionProgressTx(context.Context, tx.Tx, identity.PlayerID, int64) (MissionProgress, bool, error)
	PutMissionProgressTx(context.Context, tx.Tx, *MissionProgress, MissionProgress) error

	CandidateStatesTx(context.Context, tx.Queryer, identity.LogicalServerID, []identity.PlayerID) (map[identity.PlayerID]CandidateState, error)

	ReadExamReceiptTx(context.Context, tx.Queryer, identity.PlayerID, int64) (ExamReceipt, bool, error)
	LockExamReceiptTx(context.Context, tx.Tx, identity.PlayerID, int64) (ExamReceipt, bool, error)
	InsertExamReceiptTx(context.Context, tx.Tx, ExamReceipt) error
}

type DirectoryReader interface {
	ProfileTx(context.Context, tx.Tx, identity.PlayerID) (playerdirectory.Profile, bool, error)
	ProfilesAfterTx(context.Context, tx.Tx, identity.PlayerID, int) ([]playerdirectory.Profile, error)
	ProfilesByExactNameTx(context.Context, tx.Tx, string, int) ([]playerdirectory.Profile, error)
	PlayerIDBoundsTx(context.Context, tx.Tx) (identity.PlayerID, identity.PlayerID, bool, error)
}

type CardReader interface {
	ReadManyTx(context.Context, tx.Tx, []identity.PlayerID) (playerpresentation.Batch, error)
}

type PresenceReader interface {
	ReadManyAt(context.Context, []identity.PlayerID, time.Time) (map[identity.PlayerID]socialpresence.Observation, error)
}

type FriendshipEnsurer interface {
	EnsureFriendshipTx(context.Context, tx.Tx, identity.PlayerID, identity.PlayerID, time.Time) (bool, error)
}

type BackgroundReader interface {
	BackgroundCountTx(context.Context, tx.Queryer, identity.PlayerID) (int64, error)
}

type GrantOwner interface {
	SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error)
}

type ContentReader interface {
	MentorCatalog() (builtin.MentorInputCatalog, error)
	ActiveRevision(context.Context, tx.Queryer) (string, error)
}

// RevisionReader is the immutable content revision used by relation rows.
type RevisionReader interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
}
