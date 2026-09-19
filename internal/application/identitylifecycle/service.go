package identitylifecycle

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	ErrServicePortsIncomplete = errors.New("identity lifecycle service ports incomplete")
	ErrAccountNotLive         = errors.New("identity lifecycle account not live")
	ErrSessionAccountMismatch = errors.New("session/account mismatch")
)

type Service struct {
	Runner      tx.Runner
	Store       Store
	Receipts    receipt.Store
	ReceiptRead receipt.Reader
	Notifier    RevocationNotifier

	Profile tx.Profile

	// Idle expiry is an explicit deployment policy. Preservation default is
	// false; when true, activity writes are coalesced by ActivityTouchInterval.
	IdleExpiryEnabled     bool
	ActivityTouchInterval time.Duration
	PostCommitHintTimeout time.Duration
}

func DefaultProfile() tx.Profile {
	return tx.Profile{Name: "IDENTITY_LIFECYCLE_WRITE", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 12 * time.Second}
}

func (s Service) profile() tx.Profile {
	if s.Profile.Name == "" {
		return DefaultProfile()
	}
	return s.Profile
}
func (s Service) validateReceipted() error {
	if s.Store == nil || s.Receipts == nil || s.ReceiptRead == nil {
		return ErrServicePortsIncomplete
	}
	return nil
}
func (s Service) validateStore() error {
	if s.Store == nil {
		return ErrServicePortsIncomplete
	}
	return nil
}

type BindPrincipalCommand struct {
	AccountID identity.AccountID
	Binding   identity.ProviderBinding
}
type BindPrincipalResult struct {
	BindingID string `json:"binding_id"`
	Created   bool   `json:"created"`
}

type IssueSessionCommand struct{ Issue identity.SessionIssue }
type IssueSessionResult struct {
	SessionID string `json:"session_id"`
	Created   bool   `json:"created"`
}

type RevokeSessionCommand struct {
	SessionID identity.SessionID
	Reason    string
}
type RevokeSessionResult struct {
	SessionID       string `json:"session_id"`
	Changed         bool   `json:"changed"`
	SessionVersion  int64  `json:"session_version"`
	ContextEnded    bool   `json:"context_ended"`
	ContextVersion  int64  `json:"context_version,omitempty"`
	CanonicalReason string `json:"canonical_reason"`
	HintError       string `json:"-"`
}

type ActivityTouchResult struct {
	PolicyEnabled bool
	Persisted     bool
}

func (s Service) BindPrincipal(ctx context.Context, cmd BindPrincipalCommand, op operation.Context) (BindPrincipalResult, error) {
	if err := s.validateReceipted(); err != nil {
		return BindPrincipalResult{}, err
	}
	if cmd.Binding.AccountID != cmd.AccountID {
		return BindPrincipalResult{}, errors.New("binding/account mismatch")
	}
	if err := cmd.Binding.Principal.Validate(); err != nil {
		return BindPrincipalResult{}, err
	}
	if cmd.Binding.ID.UUID().IsZero() || cmd.AccountID.UUID().IsZero() {
		return BindPrincipalResult{}, errors.New("binding identity required")
	}

	rid := providerBindingReceiptIdentity(cmd.Binding.Principal)
	fp, err := receipt.FingerprintRequest(struct {
		AccountID string `json:"account_id"`
		BindingID string `json:"binding_id"`
		Provider  string `json:"provider"`
		Subject   string `json:"subject"`
	}{cmd.AccountID.UUID().String(), cmd.Binding.ID.UUID().String(), cmd.Binding.Principal.ProviderKey, cmd.Binding.Principal.SubjectNormalized})
	if err != nil {
		return BindPrincipalResult{}, err
	}
	var out BindPrincipalResult
	res, err := s.Runner.Run(ctx, op, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: rid, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, rid); err != nil {
			return err
		} else if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
				return &receipt.ConflictError{Identity: rid}
			}
			return json.Unmarshal(prior.ResultPayload, &out)
		}
		account, err := s.Store.LockAccountTx(txctx, scope.Tx, cmd.AccountID)
		if err != nil {
			return err
		}
		if !account.Live() {
			return ErrAccountNotLive
		}
		existing, err := s.Store.FindProviderBindingTx(txctx, scope.Tx, cmd.Binding.Principal)
		if err != nil {
			return err
		}
		bound, created, err := identity.BindPrincipal(existing, cmd.Binding)
		if err != nil {
			return err
		}
		if created {
			if err := s.Store.InsertProviderBindingTx(txctx, scope.Tx, bound); err != nil {
				return err
			}
		}
		out = BindPrincipalResult{BindingID: bound.ID.UUID().String(), Created: created}
		return putReceipt(txctx, scope.Tx, s.Receipts, op, rid, fp, "IDENTITY_PROVIDER_BIND", "gxb.identity.provider-bind.v1", out)
	})
	if err != nil {
		return BindPrincipalResult{}, err
	}
	if res.Reconciled {
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
				return BindPrincipalResult{}, err
			}
		}
	}
	return out, nil
}

func (s Service) IssueSession(ctx context.Context, cmd IssueSessionCommand, op operation.Context) (IssueSessionResult, error) {
	if err := s.validateReceipted(); err != nil {
		return IssueSessionResult{}, err
	}
	issue, err := identity.NewSessionIssue(cmd.Issue.Session, cmd.Issue.SID, cmd.Issue.LoginToken)
	if err != nil {
		return IssueSessionResult{}, err
	}
	rid := sessionIssueReceiptIdentity(issue.Session)
	fp, err := receipt.FingerprintRequest(struct {
		SessionID         string   `json:"session_id"`
		AccountID         string   `json:"account_id"`
		AuthProfile       string   `json:"auth_profile"`
		SIDCredentialID   string   `json:"sid_credential_id"`
		LoginCredentialID string   `json:"login_credential_id"`
		SIDDigest         [32]byte `json:"sid_digest"`
		LoginDigest       [32]byte `json:"login_digest"`
	}{issue.Session.ID.UUID().String(), issue.Session.AccountID.UUID().String(), string(issue.Session.AuthProfile), issue.SID.ID.UUID().String(), issue.LoginToken.ID.UUID().String(), issue.SID.Digest, issue.LoginToken.Digest})
	if err != nil {
		return IssueSessionResult{}, err
	}
	var out IssueSessionResult
	res, err := s.Runner.Run(ctx, op, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: rid, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, rid); err != nil {
			return err
		} else if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
				return &receipt.ConflictError{Identity: rid}
			}
			return json.Unmarshal(prior.ResultPayload, &out)
		}
		account, err := s.Store.LockAccountTx(txctx, scope.Tx, issue.Session.AccountID)
		if err != nil {
			return err
		}
		if !account.Live() {
			return ErrAccountNotLive
		}
		if issue.Session.AccountID != account.ID {
			return ErrSessionAccountMismatch
		}
		if err = s.Store.InsertSessionTx(txctx, scope.Tx, issue.Session); err != nil {
			return err
		}
		if err = s.Store.InsertSessionCredentialTx(txctx, scope.Tx, issue.SID); err != nil {
			return err
		}
		if err = s.Store.InsertSessionCredentialTx(txctx, scope.Tx, issue.LoginToken); err != nil {
			return err
		}
		out = IssueSessionResult{SessionID: issue.Session.ID.UUID().String(), Created: true}
		return putReceipt(txctx, scope.Tx, s.Receipts, op, rid, fp, "IDENTITY_SESSION_ISSUE", "gxb.identity.session-issue.v1", out)
	})
	if err != nil {
		return IssueSessionResult{}, err
	}
	if res.Reconciled {
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
				return IssueSessionResult{}, err
			}
		}
	}
	return out, nil
}

func (s Service) RevokeSession(ctx context.Context, cmd RevokeSessionCommand, op operation.Context) (RevokeSessionResult, error) {
	if err := s.validateReceipted(); err != nil {
		return RevokeSessionResult{}, err
	}
	if cmd.SessionID.UUID().IsZero() || cmd.Reason == "" {
		return RevokeSessionResult{}, errors.New("session id and revocation reason required")
	}
	rid := sessionRevokeReceiptIdentity(cmd.SessionID)
	fp, err := receipt.FingerprintRequest(struct {
		SessionID string `json:"session_id"`
		Reason    string `json:"reason"`
	}{cmd.SessionID.UUID().String(), cmd.Reason})
	if err != nil {
		return RevokeSessionResult{}, err
	}
	var out RevokeSessionResult
	res, err := s.Runner.Run(ctx, op, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: rid, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, rid); err != nil {
			return err
		} else if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
				return &receipt.ConflictError{Identity: rid}
			}
			return json.Unmarshal(prior.ResultPayload, &out)
		}
		sess, err := s.Store.LockSessionTx(txctx, scope.Tx, cmd.SessionID)
		if err != nil {
			return err
		}
		cx, err := s.Store.LockLiveContextTx(txctx, scope.Tx, cmd.SessionID)
		if err != nil {
			return err
		}
		beforeSessionVersion := sess.LivenessVersion
		beforeContextVersion := int64(0)
		if cx != nil {
			beforeContextVersion = cx.LivenessVersion
		}
		plan, err := identity.RevokeSession(sess, cx, nil, nil, op.StartedAt, cmd.Reason)
		if err != nil {
			return err
		}
		changed := plan.Session.LivenessVersion != beforeSessionVersion
		if changed {
			if err = s.Store.SaveRevokedSessionTx(txctx, scope.Tx, plan.Session, beforeSessionVersion); err != nil {
				return err
			}
		}
		contextEnded := false
		if plan.Context != nil && plan.Context.LivenessVersion != beforeContextVersion {
			contextEnded = true
			if err = s.Store.SaveEndedContextTx(txctx, scope.Tx, *plan.Context, beforeContextVersion); err != nil {
				return err
			}
		}
		// Updates run only after session then context row locks have been taken.
		if err = s.Store.RevokeSessionCredentialsTx(txctx, scope.Tx, cmd.SessionID, op.StartedAt.UTC()); err != nil {
			return err
		}
		if err = s.Store.RevokeGameplayCredentialsTx(txctx, scope.Tx, cmd.SessionID, op.StartedAt.UTC()); err != nil {
			return err
		}
		out = RevokeSessionResult{SessionID: cmd.SessionID.UUID().String(), Changed: changed, SessionVersion: plan.Session.LivenessVersion, ContextEnded: contextEnded, CanonicalReason: plan.Session.RevocationReason}
		if plan.Context != nil {
			out.ContextVersion = plan.Context.LivenessVersion
		}
		return putReceipt(txctx, scope.Tx, s.Receipts, op, rid, fp, "IDENTITY_SESSION_REVOKE", "gxb.identity.session-revoke.v1", out)
	})
	if err != nil {
		return RevokeSessionResult{}, err
	}
	if res.Reconciled {
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
				return RevokeSessionResult{}, err
			}
		}
	}
	// Hint is deliberately after canonical commit/reconciliation. Failure is
	// returned as metadata, not as transaction failure.
	if s.Notifier != nil {
		d := s.PostCommitHintTimeout
		if d <= 0 {
			d = 2 * time.Second
		}
		hintCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), d)
		herr := s.Notifier.SessionRevoked(hintCtx, cmd.SessionID, out.CanonicalReason)
		cancel()
		if herr != nil {
			out.HintError = herr.Error()
		}
	}
	return out, nil
}

func (s Service) TouchActivity(ctx context.Context, sessionID identity.SessionID, op operation.Context) (ActivityTouchResult, error) {
	if !s.IdleExpiryEnabled {
		return ActivityTouchResult{PolicyEnabled: false}, nil
	}
	if err := s.validateStore(); err != nil {
		return ActivityTouchResult{}, err
	}
	if s.ActivityTouchInterval <= 0 {
		return ActivityTouchResult{}, errors.New("activity touch interval must be positive when idle expiry is enabled")
	}
	if sessionID.UUID().IsZero() {
		return ActivityTouchResult{}, errors.New("session id required")
	}
	var changed bool
	_, err := s.Runner.Run(ctx, op, s.profile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(txctx context.Context, scope tx.Scope) error {
		cutoff := op.StartedAt.UTC().Add(-s.ActivityTouchInterval)
		var e error
		changed, e = s.Store.TouchSessionActivityTx(txctx, scope.Tx, sessionID, cutoff, op.StartedAt.UTC())
		return e
	})
	if err != nil {
		return ActivityTouchResult{}, err
	}
	return ActivityTouchResult{PolicyEnabled: true, Persisted: changed}, nil
}

func providerBindingReceiptIdentity(p identity.ProviderPrincipal) receipt.Identity {
	h := sha256.Sum256([]byte("gxb-v2/provider-principal/v1\x00" + p.ProviderKey + "\x00" + p.SubjectNormalized))
	return receipt.Identity{OwnerKind: "provider_principal", OwnerKey: hex.EncodeToString(h[:]), Domain: "identity", Operation: "provider.bind", SemanticKey: "canonical"}
}
func sessionIssueReceiptIdentity(s identity.Session) receipt.Identity {
	return receipt.Identity{OwnerKind: "session", OwnerKey: s.ID.UUID().String(), Domain: "identity", Operation: "session.issue", SemanticKey: "canonical"}
}
func sessionRevokeReceiptIdentity(s identity.SessionID) receipt.Identity {
	return receipt.Identity{OwnerKind: "session", OwnerKey: s.UUID().String(), Domain: "identity", Operation: "session.revoke", SemanticKey: "canonical"}
}

func putReceipt(ctx context.Context, t tx.Tx, store receipt.Store, op operation.Context, id receipt.Identity, fp [32]byte, class, schema string, result any) error {
	raw, err := json.Marshal(result)
	if err != nil {
		return err
	}
	r, err := receipt.New(op, id, class, schema, raw, fp)
	if err != nil {
		return err
	}
	got, err := store.PutTx(ctx, t, r)
	if err != nil {
		return err
	}
	if !bytes.Equal(got.Receipt.RequestFingerprint[:], fp[:]) {
		return &receipt.ConflictError{Identity: id}
	}
	return nil
}

func (r RevokeSessionResult) String() string {
	return fmt.Sprintf("session=%s changed=%t version=%d", r.SessionID, r.Changed, r.SessionVersion)
}
