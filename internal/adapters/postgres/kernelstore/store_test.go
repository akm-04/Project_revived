package kernelstore

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type tag int64

func (t tag) RowsAffected() int64 { return int64(t) }

type row struct{ scan func(...any) error }

func (r row) Scan(v ...any) error { return r.scan(v...) }

type fakeTx struct {
	rows      []row
	n         int
	queryArgs [][]any
}

func (f *fakeTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return tag(1), nil }
func (f *fakeTx) QueryRow(_ context.Context, _ string, args ...any) tx.Row {
	f.queryArgs = append(f.queryArgs, append([]any(nil), args...))
	r := f.rows[f.n]
	f.n++
	return r
}
func (f *fakeTx) Commit(context.Context) error   { return nil }
func (f *fakeTx) Rollback(context.Context) error { return nil }
func receiptRow(r receipt.Receipt) row {
	return row{scan: func(v ...any) error {
		*(v[0].(*string)) = r.ID.String()
		*(v[1].(*string)) = r.Identity.OwnerKind
		*(v[2].(*string)) = r.Identity.OwnerKey
		*(v[3].(*string)) = r.Identity.Domain
		*(v[4].(*string)) = r.Identity.Operation
		*(v[5].(*string)) = r.Identity.SemanticKey
		*(v[6].(*string)) = r.OperationClass
		*(v[7].(*string)) = "0000000000000000000000000000000000000000000000000000000000000001"
		*(v[8].(*string)) = r.ResultSchema
		*(v[9].(*string)) = string(r.ResultPayload)
		*(v[10].(*time.Time)) = r.OperationStartedAt
		*(v[11].(*string)) = r.PolicyVersion
		policyJSON, err := policy.MarshalCanonicalJSON(r.OperationPolicyRefs)
		if err != nil {
			return err
		}
		*(v[12].(*string)) = string(policyJSON)
		*(v[13].(*string)) = r.ActorAccountUID
		*(v[14].(*string)) = ""
		*(v[15].(*time.Time)) = r.RecordedAt
		*(v[16].(*bool)) = false
		*(v[17].(*time.Time)) = time.Unix(0, 0)
		return nil
	}}
}
func baseReceipt() receipt.Receipt {
	return receipt.Receipt{ID: ids.UUID{1}, Identity: receipt.Identity{OwnerKind: "player", OwnerKey: "1", Domain: "shop", Operation: "buy", SemanticKey: "s"}, OperationClass: "write", RequestFingerprint: [32]byte{31: 1}, ResultSchema: "v1", ResultPayload: []byte(`{"ok":true}`), OperationStartedAt: time.Unix(1, 0).UTC(), RecordedAt: time.Unix(2, 0).UTC()}
}
func TestPutConvergesOnStoredReceipt(t *testing.T) {
	r := baseReceipt()
	f := &fakeTx{rows: []row{{scan: func(v ...any) error { *(v[0].(*bool)) = false; return nil }}, receiptRow(r)}}
	got, err := (Store{}).PutTx(context.Background(), f, r)
	if err != nil {
		t.Fatal(err)
	}
	if got.Inserted {
		t.Fatal("expected replay")
	}
}
func TestPutRejectsFingerprintConflict(t *testing.T) {
	r := baseReceipt()
	stored := r
	stored.RequestFingerprint = [32]byte{31: 1}
	r.RequestFingerprint = [32]byte{31: 2}
	f := &fakeTx{rows: []row{{scan: func(v ...any) error { *(v[0].(*bool)) = false; return nil }}, receiptRow(stored)}}
	_, err := (Store{}).PutTx(context.Background(), f, r)
	var c *receipt.ConflictError
	if !errors.As(err, &c) {
		t.Fatalf("expected conflict, got %v", err)
	}
}

func TestPutReplayKeepsStoredPolicyEvidenceWithoutConflict(t *testing.T) {
	r := baseReceipt()
	incomingPolicies, err := policy.NewSet(policy.Ref{Name: "content", Version: "r2"})
	if err != nil {
		t.Fatal(err)
	}
	storedPolicies, err := policy.NewSet(policy.Ref{Name: "content", Version: "r1"})
	if err != nil {
		t.Fatal(err)
	}
	r.OperationPolicyRefs = incomingPolicies
	stored := r
	stored.OperationPolicyRefs = storedPolicies
	f := &fakeTx{rows: []row{{scan: func(v ...any) error { *(v[0].(*bool)) = false; return nil }}, receiptRow(stored)}}
	got, err := (Store{}).PutTx(context.Background(), f, r)
	if err != nil {
		t.Fatal(err)
	}
	if got.Inserted {
		t.Fatal("expected replay")
	}
	if !got.Receipt.OperationPolicyRefs.Equal(storedPolicies) {
		t.Fatalf("stored execution evidence lost: %#v", got.Receipt.OperationPolicyRefs.Refs())
	}
}

func TestPutWritesCanonicalPolicyJSON(t *testing.T) {
	ps, err := policy.NewSet(policy.Ref{Name: "zeta", Version: "v2"}, policy.Ref{Name: "content", Version: "r1"})
	if err != nil {
		t.Fatal(err)
	}
	r := baseReceipt()
	r.OperationPolicyRefs = ps
	f := &fakeTx{rows: []row{{scan: func(v ...any) error { *(v[0].(*bool)) = true; return nil }}, receiptRow(r)}}
	if _, err := (Store{}).PutTx(context.Background(), f, r); err != nil {
		t.Fatal(err)
	}
	if len(f.queryArgs) < 1 || len(f.queryArgs[0]) != 16 {
		t.Fatalf("insert args=%d/%d", len(f.queryArgs), len(f.queryArgs[0]))
	}
	if got, want := f.queryArgs[0][12], `[{"name":"content","version":"r1"},{"name":"zeta","version":"v2"}]`; got != want {
		t.Fatalf("policy json=%v want=%s", got, want)
	}
}

func TestFindRejectsInvalidStoredPolicyEvidence(t *testing.T) {
	r := baseReceipt()
	bad := receiptRow(r)
	original := bad.scan
	bad.scan = func(v ...any) error {
		if err := original(v...); err != nil {
			return err
		}
		*(v[12].(*string)) = `[{"name":"z","version":"1"},{"name":"a","version":"2"}]`
		return nil
	}
	f := &fakeTx{rows: []row{bad}}
	_, _, err := (Store{}).FindTx(context.Background(), f, r.Identity)
	if err == nil {
		t.Fatal("expected invalid stored policy evidence to fail closed")
	}
}
