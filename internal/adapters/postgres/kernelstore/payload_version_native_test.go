//go:build postgres

package kernelstore_test

import (
	"context"
	"encoding/json"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripKernelStore(t *testing.T) {
	dsn := os.Getenv("GXB_R8_2C_BATCH14_DSN")
	if dsn == "" {
		t.Fatal("required GXB_R8_2C_BATCH14_DSN for a migrated test database is missing")
	}
	ctx := context.Background()
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	refs, err := policy.NewSet(policy.Ref{Name: "content", Version: "r1"}, policy.Ref{Name: "guild-core", Version: "r9"})
	if err != nil {
		t.Fatal(err)
	}
	receiptID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	written := receipt.Receipt{ID: receiptID, Identity: receipt.Identity{OwnerKind: "player", OwnerKey: "99999925001", Domain: "payload-version", Operation: "probe", SemanticKey: "probe"}, OperationClass: "write", RequestFingerprint: [32]byte{31: 1}, ResultSchema: "v1", ResultPayload: []byte(`{"ok":true}`), OperationStartedAt: time.Unix(1, 0).UTC(), OperationPolicyRefs: refs}
	if _, err := (kernelstore.Store{}).PutTx(ctx, transaction, written); err != nil {
		t.Fatal(err)
	}
	var storedText string
	var version int16
	if err := transaction.QueryRow(ctx, `SELECT operation_policy_refs::text,payload_version FROM gxb_operation_receipts WHERE receipt_id=$1`, receiptID.String()).Scan(&storedText, &version); err != nil {
		t.Fatal(err)
	}
	if version != payload.Current {
		t.Fatalf("payload_version=%d want=%d", version, payload.Current)
	}
	marshalled, err := json.Marshal(written.OperationPolicyRefs)
	if err != nil {
		t.Fatal(err)
	}
	var expectedText string
	if err := transaction.QueryRow(ctx, `SELECT ($1::jsonb)::text`, string(marshalled)).Scan(&expectedText); err != nil {
		t.Fatal(err)
	}
	if storedText != expectedText {
		t.Fatalf("stored policy refs=%s want json.Marshal=%s", storedText, expectedText)
	}
	var decoded policy.Set
	if err := payload.Decode("gxb_operation_receipts", version, []byte(storedText), &decoded); err != nil {
		t.Fatalf("strict decode: %v", err)
	}
	if !decoded.Equal(refs) {
		t.Fatalf("decoded=%#v want=%#v", decoded.Refs(), refs.Refs())
	}
	found, ok, err := (kernelstore.Store{}).FindTx(ctx, transaction, written.Identity)
	if err != nil {
		t.Fatal(err)
	}
	if !ok {
		t.Fatal("FindTx did not find the written receipt")
	}
	if !found.OperationPolicyRefs.Equal(refs) {
		t.Fatalf("FindTx policy refs=%#v want=%#v", found.OperationPolicyRefs.Refs(), refs.Refs())
	}
}
