package i5

import (
	"context"
	"crypto/rand"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/redeem"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	OperatorRedeemPolicyVersion = "operator-redeem-v1"
	MaxRedeemListLimit          = 200
	DefaultRedeemListLimit      = 50
)

// RedeemCreateRequest is one operator-issued redeem code: lines are already
// catalogue-checked by the operator module; this owner revalidates them.
type RedeemCreateRequest struct {
	Code      string
	Lines     []grant.Line
	ExpiresAt *time.Time
	TotalCap  *int64
}

type RedeemCreateResult struct {
	Code          string     `json:"code"`
	CodeID        string     `json:"code_id"`
	CampaignID    string     `json:"campaign_id"`
	ExpiresAt     *time.Time `json:"expires_at"`
	TotalCap      *int64     `json:"total_cap"`
	PerSubjectCap int64      `json:"per_subject_cap"`
	State         string     `json:"state"`
}

type RedeemDisableResult struct {
	Code  string `json:"code"`
	State string `json:"state"`
}

type RedeemPage struct {
	Entries []RedeemSummary `json:"entries"`
	Next    string          `json:"next,omitempty"`
}

// buildOperatorRedeem validates a create request and fixes its durable row.
func (s Service) buildOperatorRedeem(admin AdminOperator, request RedeemCreateRequest, op operation.Context) (RedeemInsert, RedeemCreateResult, error) {
	if err := admin.Validate(); err != nil {
		return RedeemInsert{}, RedeemCreateResult{}, err
	}
	if len(s.RedeemSecret) < 16 {
		return RedeemInsert{}, RedeemCreateResult{}, errors.New("redeem digest configuration incomplete")
	}
	if len(request.Lines) == 0 {
		return RedeemInsert{}, RedeemCreateResult{}, errors.New("redeem lines required")
	}
	for _, line := range request.Lines {
		if err := line.Validate(); err != nil {
			return RedeemInsert{}, RedeemCreateResult{}, err
		}
	}
	if op.StartedAt.IsZero() {
		return RedeemInsert{}, RedeemCreateResult{}, errors.New("authoritative time required")
	}
	code := request.Code
	if code == "" {
		generated, err := redeem.GenerateCode(rand.Reader)
		if err != nil {
			return RedeemInsert{}, RedeemCreateResult{}, err
		}
		code = generated
	}
	normalized, err := redeem.Normalize(code, redeem.ExactCode)
	if err != nil {
		return RedeemInsert{}, RedeemCreateResult{}, errors.New("redeem code is invalid")
	}
	digest, err := redeem.LookupDigest(s.RedeemSecret, normalized)
	if err != nil {
		return RedeemInsert{}, RedeemCreateResult{}, err
	}
	var endsAt *time.Time
	if request.ExpiresAt != nil {
		at := request.ExpiresAt.UTC()
		if !at.After(op.StartedAt.UTC()) {
			return RedeemInsert{}, RedeemCreateResult{}, errors.New("redeem expiry must be in the future")
		}
		endsAt = &at
	}
	if request.TotalCap != nil && *request.TotalCap <= 0 {
		return RedeemInsert{}, RedeemCreateResult{}, errors.New("redeem total cap must be positive")
	}
	plan := grant.Plan{Source: grant.SourceIdentity{Domain: "redeem", Operation: "redeem", PolicyVersion: OperatorRedeemPolicyVersion}, Lines: append([]grant.Line(nil), request.Lines...)}
	campaignID, err := ids.NewUUID()
	if err != nil {
		return RedeemInsert{}, RedeemCreateResult{}, err
	}
	codeID, err := ids.NewUUID()
	if err != nil {
		return RedeemInsert{}, RedeemCreateResult{}, err
	}
	bundleID, err := ids.NewUUID()
	if err != nil {
		return RedeemInsert{}, RedeemCreateResult{}, err
	}
	insert := RedeemInsert{
		CampaignID:    campaignID.String(),
		CodeID:        codeID.String(),
		BundleID:      bundleID.String(),
		Name:          "operator redeem",
		Code:          normalized,
		Plan:          plan,
		Digest:        digest,
		SubjectType:   string(redeem.PlayerSubject),
		EndsAt:        endsAt,
		TotalCap:      request.TotalCap,
		PerSubjectCap: 1,
		PolicyVersion: OperatorRedeemPolicyVersion,
		CreatedBy:     admin.ID,
		CreatedAt:     op.StartedAt.UTC(),
	}
	result := RedeemCreateResult{Code: normalized, CodeID: insert.CodeID, CampaignID: insert.CampaignID, ExpiresAt: endsAt, TotalCap: request.TotalCap, PerSubjectCap: 1, State: "ACTIVE"}
	return insert, result, nil
}

// OperatorCreateRedeemTx creates one code in the caller's transaction (the
// operator bus transaction), so the audit row and the code commit together.
func (s Service) OperatorCreateRedeemTx(ctx context.Context, transaction tx.Tx, admin AdminOperator, request RedeemCreateRequest, op operation.Context) (RedeemCreateResult, error) {
	if err := s.validate(); err != nil {
		return RedeemCreateResult{}, err
	}
	insert, result, err := s.buildOperatorRedeem(admin, request, op)
	if err != nil {
		return RedeemCreateResult{}, err
	}
	if transaction == nil {
		return RedeemCreateResult{}, errors.New("redeem create transaction required")
	}
	if err := s.Store.InsertOperatorRedeemTx(ctx, transaction, insert); err != nil {
		return RedeemCreateResult{}, err
	}
	return result, nil
}

// OperatorCreateRedeem is the transaction-owning form, for direct native use.
func (s Service) OperatorCreateRedeem(ctx context.Context, admin AdminOperator, request RedeemCreateRequest, op operation.Context) (RedeemCreateResult, error) {
	if err := s.validate(); err != nil {
		return RedeemCreateResult{}, err
	}
	if s.Runner.DB == nil {
		return RedeemCreateResult{}, errors.New("redeem owner unavailable")
	}
	var out RedeemCreateResult
	_, err := s.Runner.Run(ctx, op, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(txctx context.Context, scope tx.Scope) error {
		var createErr error
		out, createErr = s.OperatorCreateRedeemTx(txctx, scope.Tx, admin, request, op)
		return createErr
	})
	return out, err
}

// OperatorDisableRedeemTx disables one code in the caller's transaction.
func (s Service) OperatorDisableRedeemTx(ctx context.Context, transaction tx.Tx, admin AdminOperator, rawCode string, op operation.Context) (RedeemDisableResult, error) {
	if err := admin.Validate(); err != nil {
		return RedeemDisableResult{}, err
	}
	if transaction == nil {
		return RedeemDisableResult{}, errors.New("redeem disable transaction required")
	}
	normalized, err := redeem.Normalize(rawCode, redeem.ExactCode)
	if err != nil {
		return RedeemDisableResult{}, ErrRedeemUnknown
	}
	digest, err := redeem.LookupDigest(s.RedeemSecret, normalized)
	if err != nil {
		return RedeemDisableResult{}, err
	}
	found, err := s.Store.DisableRedeemCodeTx(ctx, transaction, digest)
	if err != nil {
		return RedeemDisableResult{}, err
	}
	if !found {
		return RedeemDisableResult{}, ErrRedeemUnknown
	}
	return RedeemDisableResult{Code: normalized, State: "DISABLED"}, nil
}

// OperatorDisableRedeem is the transaction-owning form, for direct native use.
func (s Service) OperatorDisableRedeem(ctx context.Context, admin AdminOperator, rawCode string, op operation.Context) (RedeemDisableResult, error) {
	if s.Runner.DB == nil {
		return RedeemDisableResult{}, errors.New("redeem owner unavailable")
	}
	var out RedeemDisableResult
	_, err := s.Runner.Run(ctx, op, s.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(txctx context.Context, scope tx.Scope) error {
		var disableErr error
		out, disableErr = s.OperatorDisableRedeemTx(txctx, scope.Tx, admin, rawCode, op)
		return disableErr
	})
	return out, err
}

// OperatorRedeemRead answers redeem.list as a bounded read-only query.
type OperatorRedeemRead struct {
	Runner     tx.Runner
	Operations operation.Factory
	Store      RedeemReadStore
}

type RedeemReadStore interface {
	ListRedeemSummariesTx(context.Context, tx.Queryer, string, int) ([]RedeemSummary, error)
}

func (read OperatorRedeemRead) List(ctx context.Context, after string, limit int) (RedeemPage, error) {
	if read.Runner.DB == nil || read.Store == nil {
		return RedeemPage{}, errors.New("redeem read unavailable")
	}
	if limit <= 0 || limit > MaxRedeemListLimit {
		limit = DefaultRedeemListLimit
	}
	if after != "" {
		if _, err := ids.ParseUUID(after); err != nil {
			return RedeemPage{}, errors.New("redeem cursor is not a code id")
		}
	}
	current, err := read.Operations.New(policy.Set{})
	if err != nil {
		return RedeemPage{}, err
	}
	page := RedeemPage{}
	_, err = read.Runner.Run(ctx, current, readProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		entries, readErr := read.Store.ListRedeemSummariesTx(ctx, scope.Tx, after, limit+1)
		if readErr != nil {
			return readErr
		}
		if len(entries) > limit {
			page.Next = entries[limit-1].CodeID
			entries = entries[:limit]
		}
		page.Entries = entries
		return nil
	})
	if err != nil {
		return RedeemPage{}, err
	}
	return page, nil
}

func readProfile() tx.Profile {
	return tx.Profile{Name: "operator-redeem-read-v1", AcquireTimeout: 500 * time.Millisecond, LockTimeout: 500 * time.Millisecond, StatementTimeout: 1500 * time.Millisecond, TransactionTimeout: 2 * time.Second, CleanupTimeout: 500 * time.Millisecond, ReconcileTimeout: 500 * time.Millisecond, OperationTimeout: 3 * time.Second}
}
