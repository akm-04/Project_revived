package socialinvite

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	domain "gxb.local/backend/v2/internal/domain/socialinvite"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// BindService is the MID 386 boundary: one immutable inviter per invitee.
type BindService struct {
	Timed         generation.TimedRunner
	Fence         ActorFence
	Players       playerroot.TxLocker
	Owner         Owner
	Facts         FactsReader
	Receipts      receipt.Store
	ReceiptReader receipt.Reader
}

type bindTerminal struct {
	OperationID string    `json:"operation_id"`
	StartedAt   time.Time `json:"started_at"`
	InviterID   int64     `json:"inviter_id"`
	InviterName string    `json:"inviter_name"`
	Policy      string    `json:"policy"`
}

func bindProfile() tx.Profile {
	return tx.Profile{Name: "social-invite-bind", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 45 * time.Second}
}

func (service BindService) Bind(ctx context.Context, actor identity.ActorContext, rawCode string, current operation.Context) (map[string]any, error) {
	if service.Timed.Runner.DB == nil || service.Timed.Binder.Time == nil || service.Fence == nil || service.Players == nil || service.Owner == nil || service.Facts == nil || service.Receipts == nil || service.ReceiptReader == nil {
		return nil, ErrUnavailable
	}
	if !actor.PlayerID.Valid() || !actor.LogicalServerID.Valid() || logicalserver.PlayerRegion(actor.PlayerID) != actor.LogicalServerID || actor.AccountUID == "" || actor.ContextID.UUID().IsZero() || current.ID.IsZero() || current.StartedAt.IsZero() {
		return nil, ErrFacts
	}
	inviter, err := domain.DecodeCode(rawCode)
	if err != nil {
		return nil, ErrBindRefused
	}
	if inviter == actor.PlayerID || logicalserver.PlayerRegion(inviter) != actor.LogicalServerID {
		return nil, ErrBindRefused
	}
	identityValue := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: "socialinvite", Operation: "bind", SemanticKey: current.ID.String()}
	fingerprint, err := receipt.FingerprintRequest(struct {
		Player identity.PlayerID
		Server identity.LogicalServerID
		Code   string
		Policy string
	}{actor.PlayerID, actor.LogicalServerID, rawCode, PolicyVersion})
	if err != nil {
		return nil, err
	}
	recovery := bindRecovery{reader: service.ReceiptReader, identity: identityValue, fingerprint: fingerprint, actor: actor, current: current}
	var output map[string]any
	_, result, err := service.Timed.Run(ctx, current, bindProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 8, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 160 * time.Millisecond}, recovery, func(ctx context.Context, scope generation.TimedScope) error {
		at := scope.Operation.DecisionAt()
		if err := service.Fence.FenceActorTx(ctx, scope.Tx, actor, at); err != nil {
			return err
		}
		roots, err := service.Players.LockPlayerRootsTx(ctx, scope.Tx, actor.LogicalServerID, []identity.PlayerID{actor.PlayerID})
		if err != nil {
			return err
		}
		if len(roots) != 1 || roots[0].Validate() != nil || roots[0].PlayerID != actor.PlayerID || roots[0].LogicalServerID != actor.LogicalServerID {
			return ErrFacts
		}
		stored, found, err := service.Receipts.FindTx(ctx, scope.Tx, identityValue)
		if err != nil {
			return err
		}
		if found {
			output, err = recovery.decode(stored)
			return err
		}
		existing, bound, err := service.Owner.ReadBindingTx(ctx, scope.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		if bound {
			if existing.Inviter == inviter {
				return &receipt.ConflictError{Identity: identityValue}
			}
			return ErrBindRefused
		}
		profile, err := service.Facts.ReadPlayerProfileTx(ctx, scope.Tx, inviter)
		if err != nil {
			return ErrBindRefused
		}
		inviterAccount, err := service.Facts.ReadAccountTx(ctx, scope.Tx, inviter)
		if err != nil {
			return err
		}
		academyLevel, err := service.Facts.ReadAcademyLevelTx(ctx, scope.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		if academyLevel >= domain.InviteAcademyLevelLimit {
			return ErrBindRefused
		}
		binding, err := domain.Bind(nil, domain.Candidate{Inviter: inviter, Invitee: actor.PlayerID, LogicalServerID: actor.LogicalServerID, InviterAccount: inviterAccount, InviteeAccount: actor.AccountID, InviteeAcademyLevel: academyLevel}, domain.InviteAcademyLevelLimit, at)
		if errors.Is(err, domain.ErrSameAccount) {
			return domain.ErrSameAccount
		}
		if err != nil {
			return ErrBindRefused
		}
		record := BindingRecord{Invitee: binding.Invitee, Inviter: binding.Inviter, LogicalServerID: binding.LogicalServerID, OperationID: scope.Operation.Operation().ID, PolicyVersion: PolicyVersion, BoundAt: binding.BoundAt}
		if err := service.Owner.InsertBindingTx(ctx, scope.Tx, record); err != nil {
			if errors.Is(err, ErrBindConflict) {
				return &receipt.ConflictError{Identity: identityValue}
			}
			return err
		}
		terminal := bindTerminal{OperationID: scope.Operation.Operation().ID.String(), StartedAt: scope.Operation.Operation().StartedAt, InviterID: int64(inviter), InviterName: profile.Name, Policy: PolicyVersion}
		encoded, err := json.Marshal(terminal)
		if err != nil {
			return err
		}
		boundOperation, err := bindPolicies(scope.Operation.Operation())
		if err != nil {
			return err
		}
		value, err := receipt.New(boundOperation, identityValue, bindOperationClass, bindResultSchema, encoded, fingerprint)
		if err != nil {
			return err
		}
		value.PolicyVersion = PolicyVersion
		value.ActorAccountUID = string(actor.AccountUID)
		value.ContextID = actor.ContextID.UUID()
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
			return nil, ErrProof
		}
		return recovery.decode(stored)
	}
	return output, nil
}

func bindPolicies(current operation.Context) (operation.Context, error) {
	references := current.Policies.Refs()
	if existing, found := current.Policies.Get("socialinvite"); found {
		if existing != PolicyVersion {
			return current, ErrProof
		}
	} else {
		references = append(references, policy.Ref{Name: "socialinvite", Version: PolicyVersion})
	}
	var err error
	current.Policies, err = policy.NewSet(references...)
	return current, err
}

type bindRecovery struct {
	reader      receipt.Reader
	identity    receipt.Identity
	fingerprint [32]byte
	actor       identity.ActorContext
	current     operation.Context
}

func (recovery bindRecovery) decode(stored receipt.Receipt) (map[string]any, error) {
	if stored.RequestFingerprint != recovery.fingerprint {
		return nil, &receipt.ConflictError{Identity: recovery.identity}
	}
	if stored.Validate() != nil || stored.Identity != recovery.identity || stored.OperationClass != bindOperationClass || stored.ResultSchema != bindResultSchema || stored.PolicyVersion != PolicyVersion || stored.ActorAccountUID != string(recovery.actor.AccountUID) || stored.ContextID != recovery.actor.ContextID.UUID() || stored.OperationStartedAt.UnixMicro() != recovery.current.StartedAt.UnixMicro() || stored.RetainUntil != nil {
		return nil, ErrProof
	}
	version, found := stored.OperationPolicyRefs.Get("socialinvite")
	if !found || version != PolicyVersion {
		return nil, ErrProof
	}
	var terminal bindTerminal
	decoder := json.NewDecoder(bytes.NewReader(stored.ResultPayload))
	decoder.DisallowUnknownFields()
	if decoder.Decode(&terminal) != nil {
		return nil, ErrProof
	}
	var extra any
	if decoder.Decode(&extra) != io.EOF {
		return nil, ErrProof
	}
	if terminal.OperationID != recovery.current.ID.String() || !terminal.StartedAt.Equal(recovery.current.StartedAt) || terminal.Policy != PolicyVersion || terminal.InviterID <= 0 || terminal.InviterID == int64(recovery.actor.PlayerID) {
		return nil, ErrProof
	}
	return map[string]any{"invitor_id": terminal.InviterID, "invitor_name": terminal.InviterName}, nil
}

func (recovery bindRecovery) ResolveTimed(ctx context.Context, _ generation.TimedResolutionRequest) (tx.Resolution, error) {
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
