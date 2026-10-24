package receipt

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Identity struct{ OwnerKind, OwnerKey, Domain, Operation, SemanticKey string }

func (i Identity) Validate() error {
	if i.OwnerKind == "" || i.OwnerKey == "" || i.Domain == "" || i.Operation == "" || i.SemanticKey == "" {
		return errors.New("incomplete semantic receipt identity")
	}
	return nil
}

type Receipt struct {
	ID                  ids.UUID
	Identity            Identity
	OperationClass      string
	RequestFingerprint  [32]byte
	ResultSchema        string
	ResultPayload       json.RawMessage
	OperationStartedAt  time.Time
	PolicyVersion       string
	OperationPolicyRefs policy.Set
	ActorAccountUID     string
	ContextID           ids.UUID
	RecordedAt          time.Time
	RetainUntil         *time.Time
}

func (r Receipt) Validate() error {
	if r.ID.IsZero() {
		return errors.New("receipt id required")
	}
	if err := r.Identity.Validate(); err != nil {
		return err
	}
	if r.OperationClass == "" || r.ResultSchema == "" {
		return errors.New("receipt class/schema required")
	}
	if len(r.ResultPayload) == 0 || !json.Valid(r.ResultPayload) {
		return errors.New("valid terminal result payload required")
	}
	if r.OperationStartedAt.IsZero() {
		return errors.New("operation start required")
	}
	if _, err := policy.MarshalCanonicalJSON(r.OperationPolicyRefs); err != nil {
		return fmt.Errorf("operation policy refs: %w", err)
	}
	return nil
}

type PutResult struct {
	Receipt  Receipt
	Inserted bool
}
type Store interface {
	PutTx(context.Context, tx.Tx, Receipt) (PutResult, error)
	FindTx(context.Context, tx.Queryer, Identity) (Receipt, bool, error)
}
type Reader interface {
	Find(context.Context, Identity) (Receipt, bool, error)
}

type ConflictError struct{ Identity Identity }

func (e *ConflictError) Error() string {
	return fmt.Sprintf("semantic receipt replay fingerprint conflict: %s/%s/%s/%s/%s", e.Identity.OwnerKind, e.Identity.OwnerKey, e.Identity.Domain, e.Identity.Operation, e.Identity.SemanticKey)
}

// Resolver reconciles unknown COMMITs from a fresh authoritative-writer read.
// Receipt presence can prove commit, but receipt absence alone cannot prove
// abort: the original ambiguous transaction may still become visible. Therefore
// this generic resolver returns ResolutionUnknown on a miss. Only an
// operation-specific resolver with a terminal/owner fence may emit
// ResolutionAbsent (authoritative negative proof).
type Resolver struct {
	Reader      Reader
	Identity    Identity
	Fingerprint [32]byte
}

func (r Resolver) Resolve(ctx context.Context, _ tx.ResolutionRequest) (tx.Resolution, error) {
	if r.Reader == nil {
		return tx.Resolution{}, errors.New("nil receipt reader")
	}
	got, ok, err := r.Reader.Find(ctx, r.Identity)
	if err != nil {
		return tx.Resolution{}, err
	}
	if !ok {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	if !bytes.Equal(got.RequestFingerprint[:], r.Fingerprint[:]) {
		return tx.Resolution{}, &ConflictError{Identity: r.Identity}
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: got}, nil
}

func New(op operation.Context, id Identity, class, resultSchema string, result json.RawMessage, fingerprint [32]byte) (Receipt, error) {
	rid, err := ids.NewUUID()
	if err != nil {
		return Receipt{}, err
	}
	r := Receipt{ID: rid, Identity: id, OperationClass: class, RequestFingerprint: fingerprint, ResultSchema: resultSchema, ResultPayload: append(json.RawMessage(nil), result...), OperationStartedAt: op.StartedAt.UTC(), OperationPolicyRefs: op.Policies}
	if err := r.Validate(); err != nil {
		return Receipt{}, err
	}
	return r, nil
}
