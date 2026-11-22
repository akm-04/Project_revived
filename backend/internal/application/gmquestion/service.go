package gmquestion

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/playerroot"
	domain "gxb.local/backend/v2/internal/domain/gmquestion"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const PolicyVersion = "GMQUESTION_FOUNDATION_V1"
const resultSchema = "gxb.gmquestion.ask.v1"
const operationClass = "I9_GM_QUESTION_ASK"

var ErrUnavailable = errors.New("gm question: unavailable")
var ErrProof = errors.New("gm question: invalid receipt or owner proof")

type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}
type Owner interface {
	InsertQuestionTx(context.Context, tx.Tx, domain.Question) error
	ListQuestionsTx(context.Context, tx.Queryer, identity.PlayerID, identity.LogicalServerID, time.Time) ([]domain.Question, error)
}
type Acknowledgement struct{}
type Entry struct {
	Question domain.Question
	Profile  playerdirectory.Profile
}
type Service struct {
	Timed         generation.TimedRunner
	Fence         Fence
	Players       playerroot.TxLocker
	Owner         Owner
	Directory     playerdirectory.TxDiscoveryReader
	Receipts      receipt.Store
	ReceiptReader receipt.Reader
}
type terminal struct {
	Question    domain.Question
	StartedAt   time.Time
	EntropySeed [32]byte
	Reply       *Acknowledgement
}

func profile() tx.Profile {
	return tx.Profile{Name: "gm-question", AcquireTimeout: time.Second, LockTimeout: 3 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 10 * time.Second, CleanupTimeout: time.Second, ReconcileTimeout: 3 * time.Second, OperationTimeout: 20 * time.Second}
}
func validActor(actor identity.ActorContext, current operation.Context) bool {
	return actor.PlayerID.Valid() && actor.LogicalServerID.Valid() && logicalserver.PlayerRegion(actor.PlayerID) == actor.LogicalServerID && actor.AccountUID != "" && !actor.AccountID.UUID().IsZero() && !actor.SessionID.UUID().IsZero() && !actor.ContextID.UUID().IsZero() && actor.ContextGeneration > 0 && actor.ContextLivenessVersion > 0 && actor.SessionLivenessVersion > 0 && !current.ID.IsZero() && !current.StartedAt.IsZero()
}
func (service Service) Ask(ctx context.Context, actor identity.ActorContext, message string, current operation.Context) (Acknowledgement, error) {
	if service.Timed.Runner.DB == nil || service.Timed.Binder.Time == nil || service.Fence == nil || service.Players == nil || service.Owner == nil || service.Receipts == nil || service.ReceiptReader == nil {
		return Acknowledgement{}, ErrUnavailable
	}
	if !validActor(actor, current) {
		return Acknowledgement{}, domain.ErrQuestion
	}
	candidate := domain.Question{Operation: current.ID, Player: actor.PlayerID, Server: actor.LogicalServerID, Message: message, AskedAt: current.StartedAt}
	if candidate.Validate() != nil {
		return Acknowledgement{}, domain.ErrQuestion
	}
	if version, found := current.Policies.Get("gmquestion"); found && version != PolicyVersion {
		return Acknowledgement{}, ErrProof
	}
	identityValue := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: "gmquestion", Operation: "ask", SemanticKey: current.ID.String()}
	fingerprint, err := receipt.FingerprintRequest(struct {
		Player          identity.PlayerID
		Server          identity.LogicalServerID
		Message, Policy string
	}{actor.PlayerID, actor.LogicalServerID, message, PolicyVersion})
	if err != nil {
		return Acknowledgement{}, err
	}
	recovery := recovery{reader: service.ReceiptReader, identity: identityValue, fingerprint: fingerprint, actor: actor, current: current, message: message}
	var output *Acknowledgement
	_, result, err := service.Timed.Run(ctx, current, profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 8, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 10 * time.Millisecond, DefiniteAbortBackoffMax: 80 * time.Millisecond}, recovery, func(ctx context.Context, scope generation.TimedScope) error {
		if err := service.Fence.FenceActorTx(ctx, scope.Tx, actor, scope.Operation.DecisionAt()); err != nil {
			return err
		}
		roots, err := service.Players.LockPlayerRootsTx(ctx, scope.Tx, actor.LogicalServerID, []identity.PlayerID{actor.PlayerID})
		if err != nil {
			return err
		}
		if len(roots) != 1 || roots[0].Validate() != nil || roots[0].PlayerID != actor.PlayerID || roots[0].LogicalServerID != actor.LogicalServerID {
			return ErrProof
		}
		stored, found, err := service.Receipts.FindTx(ctx, scope.Tx, identityValue)
		if err != nil {
			return err
		}
		if found {
			ack, err := recovery.decode(stored)
			output = &ack
			return err
		}
		question := candidate
		question.AskedAt = scope.Operation.DecisionAt()
		if err := service.Owner.InsertQuestionTx(ctx, scope.Tx, question); err != nil {
			return err
		}
		references := current.Policies.Refs()
		if _, found := current.Policies.Get("gmquestion"); !found {
			references = append(references, policy.Ref{Name: "gmquestion", Version: PolicyVersion})
		}
		bound := current
		bound.Policies, err = policy.NewSet(references...)
		if err != nil {
			return err
		}
		payload, err := json.Marshal(terminal{Question: question, StartedAt: current.StartedAt, EntropySeed: current.EntropySeed, Reply: &Acknowledgement{}})
		if err != nil {
			return err
		}
		stored, err = receipt.New(bound, identityValue, operationClass, resultSchema, payload, fingerprint)
		if err != nil {
			return err
		}
		stored.PolicyVersion = PolicyVersion
		stored.ActorAccountUID = string(actor.AccountUID)
		stored.ContextID = actor.ContextID.UUID()
		inserted, err := service.Receipts.PutTx(ctx, scope.Tx, stored)
		if err != nil {
			return err
		}
		if !inserted.Inserted {
			return &receipt.ConflictError{Identity: identityValue}
		}
		ack, err := recovery.decode(stored)
		output = &ack
		return err
	})
	if err != nil {
		return Acknowledgement{}, err
	}
	if result.Reconciled {
		stored, ok := result.Evidence.(receipt.Receipt)
		if !ok {
			return Acknowledgement{}, ErrProof
		}
		return recovery.decode(stored)
	}
	if output == nil {
		return Acknowledgement{}, ErrProof
	}
	return *output, nil
}
func (service Service) List(ctx context.Context, actor identity.ActorContext, current operation.Context) ([]Entry, error) {
	if service.Timed.Runner.DB == nil || service.Timed.Binder.Time == nil || service.Fence == nil || service.Owner == nil || service.Directory == nil {
		return nil, ErrUnavailable
	}
	if !validActor(actor, current) {
		return nil, domain.ErrQuestion
	}
	var output []Entry
	_, _, err := service.Timed.Run(ctx, current, profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(ctx context.Context, scope generation.TimedScope) error {
		output = make([]Entry, 0)
		if err := service.Fence.FenceActorTx(ctx, scope.Tx, actor, scope.Operation.DecisionAt()); err != nil {
			return err
		}
		questions, err := service.Owner.ListQuestionsTx(ctx, scope.Tx, actor.PlayerID, actor.LogicalServerID, scope.Operation.DecisionAt())
		if err != nil {
			return err
		}
		if len(questions) > domain.HistoryLimit {
			return ErrProof
		}
		if len(questions) == 0 {
			return nil
		}
		profile, found, err := service.Directory.ProfileTx(ctx, scope.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		if !found || profile.PlayerID != actor.PlayerID || profile.Validate() != nil {
			return ErrProof
		}
		for _, question := range questions {
			if question.Validate() != nil || question.Player != actor.PlayerID || question.Server != actor.LogicalServerID || question.AskedAt.After(scope.Operation.DecisionAt()) {
				return ErrProof
			}
			output = append(output, Entry{Question: question, Profile: profile})
		}
		return nil
	})
	return output, err
}

type recovery struct {
	reader      receipt.Reader
	identity    receipt.Identity
	fingerprint [32]byte
	actor       identity.ActorContext
	current     operation.Context
	message     string
}

func (recovery recovery) decode(stored receipt.Receipt) (Acknowledgement, error) {
	if stored.RequestFingerprint != recovery.fingerprint {
		return Acknowledgement{}, &receipt.ConflictError{Identity: recovery.identity}
	}
	if stored.Validate() != nil || stored.Identity != recovery.identity || stored.OperationClass != operationClass || stored.ResultSchema != resultSchema || stored.PolicyVersion != PolicyVersion || stored.ActorAccountUID != string(recovery.actor.AccountUID) || stored.ContextID != recovery.actor.ContextID.UUID() || stored.OperationStartedAt.UnixMicro() != recovery.current.StartedAt.UnixMicro() || stored.RetainUntil != nil {
		return Acknowledgement{}, ErrProof
	}

	references := recovery.current.Policies.Refs()
	version, found := recovery.current.Policies.Get("gmquestion")
	if found && version != PolicyVersion {
		return Acknowledgement{}, ErrProof
	}
	if !found {
		references = append(references, policy.Ref{Name: "gmquestion", Version: PolicyVersion})
	}
	expected, err := policy.NewSet(references...)
	if err != nil || !stored.OperationPolicyRefs.Equal(expected) {
		return Acknowledgement{}, ErrProof
	}

	var result terminal
	decoder := json.NewDecoder(bytes.NewReader(stored.ResultPayload))
	decoder.DisallowUnknownFields()
	if decoder.Decode(&result) != nil {
		return Acknowledgement{}, ErrProof
	}
	var extra any
	if decoder.Decode(&extra) != io.EOF {
		return Acknowledgement{}, ErrProof
	}
	if result.Reply == nil || result.Question.Validate() != nil || result.Question.Operation != recovery.current.ID || result.Question.Player != recovery.actor.PlayerID || result.Question.Server != recovery.actor.LogicalServerID || result.Question.Message != recovery.message || !result.StartedAt.Equal(recovery.current.StartedAt) || result.EntropySeed != recovery.current.EntropySeed {
		return Acknowledgement{}, ErrProof
	}
	return *result.Reply, nil
}
func (recovery recovery) ResolveTimed(ctx context.Context, _ generation.TimedResolutionRequest) (tx.Resolution, error) {
	stored, found, err := recovery.reader.Find(ctx, recovery.identity)
	if err != nil {
		return tx.Resolution{}, err
	}
	if !found {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	if _, err := recovery.decode(stored); err != nil {
		return tx.Resolution{}, err
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: stored}, nil
}
