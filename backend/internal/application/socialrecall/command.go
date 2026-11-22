package socialrecall

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"strconv"
	"time"
	"unicode/utf8"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	domain "gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const RecallPolicyVersion = "I9_10E_SOCIAL_RECALL_V1"
const recallOperationClass = "I9_10E_SOCIAL_RECALL_START"
const recallResultSchema = "gxb.social.recall.start.v1"

var ErrRecallProof = errors.New("social recall: invalid terminal receipt")
var ErrRecallUnavailable = errors.New("social recall: command unavailable")

type ActorFence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}
type RecallContent interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	SocialRecallRulesTx(context.Context, tx.Queryer, string) (domain.StartRules, error)
}
type DoingRecall struct {
	PlayerID      identity.PlayerID `json:"player_id"`
	PlayerName    string            `json:"player_name"`
	RecallingTime int64             `json:"recalling_time"`
}
type DoingProjection interface {
	DoingRecallTx(context.Context, tx.Tx, identity.PlayerID, string, time.Time, int) ([]DoingRecall, error)
}
type StartService struct {
	Timed         generation.TimedRunner
	Fence         ActorFence
	Content       RecallContent
	Starter       Starter
	Projection    DoingProjection
	Receipts      receipt.Store
	ReceiptReader receipt.Reader
}
type startTerminal struct {
	OperationID string
	StartedAt   time.Time
	EntropySeed [32]byte
	Rules       domain.StartRules
	Record      TaskRecord
	Doing       []DoingRecall
}

func (service StartService) Start(ctx context.Context, actor identity.ActorContext, target identity.PlayerID, current operation.Context) (map[string]any, error) {
	if service.Timed.Runner.DB == nil || service.Timed.Binder.Time == nil || service.Fence == nil || service.Content == nil || service.Starter.Players == nil || service.Starter.Targets == nil || service.Starter.Owner == nil || service.Projection == nil || service.Receipts == nil || service.ReceiptReader == nil {
		return nil, ErrRecallUnavailable
	}
	if !actor.PlayerID.Valid() || !actor.LogicalServerID.Valid() || logicalserver.PlayerRegion(actor.PlayerID) != actor.LogicalServerID || !target.Valid() || target == actor.PlayerID || logicalserver.PlayerRegion(target) != actor.LogicalServerID || actor.AccountUID == "" || actor.ContextID.UUID().IsZero() || current.ID.IsZero() || current.StartedAt.IsZero() {
		return nil, ErrStartFacts
	}
	if selected, found := current.Policies.Get("socialrecall"); found && selected != RecallPolicyVersion {
		return nil, ErrRecallProof
	}
	identityValue := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: "socialrecall", Operation: "start", SemanticKey: current.ID.String()}
	fingerprint, err := receipt.FingerprintRequest(struct {
		Caller identity.PlayerID
		Server identity.LogicalServerID
		Target identity.PlayerID
		Policy string
	}{actor.PlayerID, actor.LogicalServerID, target, RecallPolicyVersion})
	if err != nil {
		return nil, err
	}
	recovery := startRecovery{reader: service.ReceiptReader, identity: identityValue, fingerprint: fingerprint, actor: actor, target: target, current: current}
	profile := tx.Profile{Name: "social-recall-start", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 45 * time.Second}
	var output map[string]any
	_, result, err := service.Timed.Run(ctx, current, profile, tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 8, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 160 * time.Millisecond}, recovery, func(ctx context.Context, scope generation.TimedScope) error {
		at := scope.Operation.DecisionAt()
		if err := service.Fence.FenceActorTx(ctx, scope.Tx, actor, at); err != nil {
			return err
		}
		stored, found, err := service.Receipts.FindTx(ctx, scope.Tx, identityValue)
		if err != nil {
			return err
		}
		if found {
			output, err = recovery.decode(stored)
			return err
		}
		revision, pinned := current.Policies.Get("content")
		if !pinned {
			revision, err = service.Content.ActiveRevision(ctx, scope.Tx)
			if err != nil {
				return err
			}
		}
		if characterasset.ValidateExactRevisionID(revision) != nil {
			return ErrRecallProof
		}
		rules, err := service.Content.SocialRecallRulesTx(ctx, scope.Tx, revision)
		if err != nil {
			return err
		}
		if err := rules.Validate(); err != nil {
			return err
		}
		bound, err := BindRecallPolicies(current, revision)
		if err != nil {
			return err
		}
		record, err := service.Starter.StartTx(ctx, tx.Scope{Tx: scope.Tx, Operation: bound, Attempt: scope.Attempt, Options: scope.Options}, StartRequest{Caller: actor.PlayerID, Target: target, LogicalServerID: actor.LogicalServerID, ContentRevision: revision, PolicyVersion: RecallPolicyVersion, Limits: rules.Limits, Duration: rules.TaskDuration}, at)
		if err != nil {
			return err
		}
		doing, err := service.Projection.DoingRecallTx(ctx, scope.Tx, actor.PlayerID, revision, at, rules.Limits.MaxActiveTasks)
		if err != nil {
			return err
		}
		terminal := startTerminal{OperationID: current.ID.String(), StartedAt: current.StartedAt, EntropySeed: current.EntropySeed, Rules: rules, Record: record, Doing: doing}
		encoded, err := json.Marshal(terminal)
		if err != nil {
			return err
		}
		value, err := receipt.New(bound, identityValue, recallOperationClass, recallResultSchema, encoded, fingerprint)
		if err != nil {
			return err
		}
		value.PolicyVersion = RecallPolicyVersion
		value.ActorAccountUID = string(actor.AccountUID)
		value.ContextID = actor.ContextID.UUID()
		// Validate the complete captured reply before persisting any terminal success.
		output, err = recovery.decode(value)
		if err != nil {
			return err
		}
		inserted, err := service.Receipts.PutTx(ctx, scope.Tx, value)
		if err != nil {
			return err
		}
		if !inserted.Inserted {
			return &receipt.ConflictError{Identity: identityValue}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	if result.Reconciled {
		stored, valid := result.Evidence.(receipt.Receipt)
		if !valid {
			return nil, ErrRecallProof
		}
		return recovery.decode(stored)
	}
	return output, nil
}

// BindRecallPolicies adds the exact content/roster/recall pins used by the
// recall transaction family. A conflicting existing pin is never replaced.
func BindRecallPolicies(current operation.Context, revision string) (operation.Context, error) {
	references := current.Policies.Refs()
	for _, wanted := range []policy.Ref{{Name: "content", Version: revision}, {Name: "roster-metrics", Version: characterasset.RosterMetricPolicy}, {Name: "socialrecall", Version: RecallPolicyVersion}} {
		if existing, found := current.Policies.Get(wanted.Name); found {
			if existing != wanted.Version {
				return current, ErrRecallProof
			}
			continue
		}
		references = append(references, wanted)
	}
	var err error
	current.Policies, err = policy.NewSet(references...)
	return current, err
}

type startRecovery struct {
	reader      receipt.Reader
	identity    receipt.Identity
	fingerprint [32]byte
	actor       identity.ActorContext
	target      identity.PlayerID
	current     operation.Context
}

func (recovery startRecovery) decode(stored receipt.Receipt) (map[string]any, error) {
	if stored.RequestFingerprint != recovery.fingerprint {
		return nil, &receipt.ConflictError{Identity: recovery.identity}
	}
	if stored.Validate() != nil || stored.Identity != recovery.identity || stored.OperationClass != recallOperationClass || stored.ResultSchema != recallResultSchema || stored.PolicyVersion != RecallPolicyVersion || stored.ActorAccountUID != string(recovery.actor.AccountUID) || stored.ContextID != recovery.actor.ContextID.UUID() || stored.OperationStartedAt.UnixMicro() != recovery.current.StartedAt.UnixMicro() || stored.RetainUntil != nil {
		return nil, ErrRecallProof
	}
	for _, reference := range recovery.current.Policies.Refs() {
		actual, found := stored.OperationPolicyRefs.Get(reference.Name)
		if !found || actual != reference.Version {
			return nil, ErrRecallProof
		}
	}
	var terminal startTerminal
	decoder := json.NewDecoder(bytes.NewReader(stored.ResultPayload))
	decoder.DisallowUnknownFields()
	if decoder.Decode(&terminal) != nil {
		return nil, ErrRecallProof
	}
	var extra any
	if decoder.Decode(&extra) != io.EOF {
		return nil, ErrRecallProof
	}
	record := terminal.Record
	task := record.Task
	if terminal.OperationID != recovery.current.ID.String() || !terminal.StartedAt.Equal(recovery.current.StartedAt) || terminal.EntropySeed != recovery.current.EntropySeed || terminal.Rules.Validate() != nil || task.Validate() != nil || task.Status != domain.StatusActive || task.Caller != recovery.actor.PlayerID || task.Target != recovery.target || task.LogicalServerID != recovery.actor.LogicalServerID || task.OperationID != recovery.current.ID || !task.ExpiresAt.Equal(task.StartedAt.Add(terminal.Rules.TaskDuration)) || record.StateVersion != 1 || !record.UpdatedAt.Equal(task.StartedAt) || record.PolicyVersion != RecallPolicyVersion || characterasset.ValidateExactRevisionID(record.ContentRevision) != nil {
		return nil, ErrRecallProof
	}
	for _, wanted := range []policy.Ref{{Name: "content", Version: record.ContentRevision}, {Name: "roster-metrics", Version: characterasset.RosterMetricPolicy}, {Name: "socialrecall", Version: RecallPolicyVersion}} {
		actual, found := stored.OperationPolicyRefs.Get(wanted.Name)
		if !found || actual != wanted.Version {
			return nil, ErrRecallProof
		}
	}
	if len(terminal.Doing) < 1 || len(terminal.Doing) > terminal.Rules.Limits.MaxActiveTasks {
		return nil, ErrRecallProof
	}
	seen := map[identity.PlayerID]bool{}
	foundTarget := false
	rows := make([]any, 0, len(terminal.Doing))
	for _, entry := range terminal.Doing {
		if !entry.PlayerID.Valid() || entry.PlayerID == recovery.actor.PlayerID || logicalserver.PlayerRegion(entry.PlayerID) != recovery.actor.LogicalServerID || seen[entry.PlayerID] || !utf8.ValidString(entry.PlayerName) || entry.RecallingTime < 0 || entry.RecallingTime > task.StartedAt.Unix() {
			return nil, ErrRecallProof
		}
		seen[entry.PlayerID] = true
		if entry.PlayerID == recovery.target {
			if entry.RecallingTime != task.StartedAt.Unix() {
				return nil, ErrRecallProof
			}
			foundTarget = true
		}
		rows = append(rows, map[string]any{"player_id": int64(entry.PlayerID), "player_name": entry.PlayerName, "recalling_time": entry.RecallingTime})
	}
	if !foundTarget {
		return nil, ErrRecallProof
	}
	return map[string]any{"doing_recall": rows}, nil
}
func (recovery startRecovery) ResolveTimed(ctx context.Context, _ generation.TimedResolutionRequest) (tx.Resolution, error) {
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
