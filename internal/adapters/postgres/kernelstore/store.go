package kernelstore

import (
	"bytes"
	"context"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelqueries"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Store persists Wave-A semantic receipts using only the transaction/query port.
// The same implementation works over the pgx adapter without exposing pgx to
// foundation/domain packages.
type Store struct{}

func (Store) PutTx(ctx context.Context, t tx.Tx, r receipt.Receipt) (receipt.PutResult, error) {
	if t == nil {
		return receipt.PutResult{}, errors.New("nil transaction")
	}
	if err := r.Validate(); err != nil {
		return receipt.PutResult{}, err
	}
	var inserted bool
	var retain any
	if r.RetainUntil != nil {
		retain = r.RetainUntil.UTC()
	}
	policyRefs, err := policy.MarshalCanonicalJSON(r.OperationPolicyRefs)
	if err != nil {
		return receipt.PutResult{}, fmt.Errorf("operation policy refs: %w", err)
	}
	err = t.QueryRow(ctx, kernelqueries.InsertOperationReceipt,
		r.ID.String(), r.Identity.OwnerKind, r.Identity.OwnerKey, r.Identity.Domain, r.Identity.Operation, r.OperationClass, r.Identity.SemanticKey,
		r.RequestFingerprint[:], r.ResultSchema, string(r.ResultPayload), r.OperationStartedAt.UTC(), r.PolicyVersion, string(policyRefs), r.ActorAccountUID, optionalUUID(r.ContextID), retain,
	).Scan(&inserted)
	if err != nil {
		return receipt.PutResult{}, err
	}
	stored, ok, err := Store{}.FindTx(ctx, t, r.Identity)
	if err != nil {
		return receipt.PutResult{}, err
	}
	if !ok {
		return receipt.PutResult{}, errors.New("receipt insert/find invariant violated")
	}
	if !bytes.Equal(stored.RequestFingerprint[:], r.RequestFingerprint[:]) {
		return receipt.PutResult{}, &receipt.ConflictError{Identity: r.Identity}
	}
	return receipt.PutResult{Receipt: stored, Inserted: inserted}, nil
}

func (Store) FindTx(ctx context.Context, q tx.Queryer, id receipt.Identity) (receipt.Receipt, bool, error) {
	if q == nil {
		return receipt.Receipt{}, false, errors.New("nil queryer")
	}
	if err := id.Validate(); err != nil {
		return receipt.Receipt{}, false, err
	}
	var rid, ownerKind, ownerKey, domain, operation, semanticKey, class, fpHex, schema, payload, policyVersion, policyRefsJSON, actor, contextID string
	var started, recorded, retain time.Time
	var hasRetain bool
	err := q.QueryRow(ctx, kernelqueries.FindOperationReceipt, id.OwnerKind, id.OwnerKey, id.Domain, id.Operation, id.SemanticKey).Scan(
		&rid, &ownerKind, &ownerKey, &domain, &operation, &semanticKey, &class, &fpHex, &schema, &payload, &started, &policyVersion, &policyRefsJSON, &actor, &contextID, &recorded, &hasRetain, &retain,
	)
	if err != nil {
		if isNoRows(err) {
			return receipt.Receipt{}, false, nil
		}
		return receipt.Receipt{}, false, err
	}
	parsedID, err := ids.ParseUUID(rid)
	if err != nil {
		return receipt.Receipt{}, false, fmt.Errorf("stored receipt id: %w", err)
	}
	fp, err := hex.DecodeString(fpHex)
	if err != nil || len(fp) != 32 {
		return receipt.Receipt{}, false, errors.New("stored receipt fingerprint invalid")
	}
	var fpa [32]byte
	copy(fpa[:], fp)
	var cid ids.UUID
	if contextID != "" {
		cid, err = ids.ParseUUID(contextID)
		if err != nil {
			return receipt.Receipt{}, false, fmt.Errorf("stored context id: %w", err)
		}
	}
	raw := json.RawMessage(payload)
	if !json.Valid(raw) {
		return receipt.Receipt{}, false, errors.New("stored receipt result JSON invalid")
	}
	policyRefs, err := policy.ParseCanonicalJSON([]byte(policyRefsJSON))
	if err != nil {
		return receipt.Receipt{}, false, fmt.Errorf("stored receipt operation policy refs: %w", err)
	}
	out := receipt.Receipt{ID: parsedID, Identity: receipt.Identity{OwnerKind: ownerKind, OwnerKey: ownerKey, Domain: domain, Operation: operation, SemanticKey: semanticKey}, OperationClass: class, RequestFingerprint: fpa, ResultSchema: schema, ResultPayload: raw, OperationStartedAt: started.UTC(), PolicyVersion: policyVersion, OperationPolicyRefs: policyRefs, ActorAccountUID: actor, ContextID: cid, RecordedAt: recorded.UTC()}
	if hasRetain {
		x := retain.UTC()
		out.RetainUntil = &x
	}
	return out, true, nil
}

// Reader binds an authoritative fresh-connection queryer for unknown-COMMIT reconciliation.
type Reader struct{ Queryer tx.Queryer }

func (r Reader) Find(ctx context.Context, id receipt.Identity) (receipt.Receipt, bool, error) {
	return Store{}.FindTx(ctx, r.Queryer, id)
}
func optionalUUID(id ids.UUID) string {
	if id.IsZero() {
		return ""
	}
	return id.String()
}

// pgx.ErrNoRows isn't imported here to keep this adapter buildable offline. The
// pgx wrapper normalizes no-row errors to this sentinel.
func isNoRows(err error) bool { return errors.Is(err, ErrNoRows) }

var ErrNoRows = errors.New("postgres: no rows")
