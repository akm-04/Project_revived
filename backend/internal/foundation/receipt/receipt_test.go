package receipt

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"testing"
	"time"
)

type reader struct {
	r   Receipt
	ok  bool
	err error
}

func (x reader) Find(context.Context, Identity) (Receipt, bool, error) { return x.r, x.ok, x.err }
func TestResolverCommittedMissingIsUnknownAndConflict(t *testing.T) {
	id := Identity{OwnerKind: "player", OwnerKey: "1", Domain: "shop", Operation: "buy", SemanticKey: "k"}
	fp, _ := FingerprintRequest(map[string]any{"slot": int64(2)})
	rr := Receipt{ID: ids.UUID{1}, Identity: id, RequestFingerprint: fp, ResultSchema: "v1", ResultPayload: []byte(`{}`), OperationClass: "write", OperationStartedAt: time.Unix(1, 0)}
	r := Resolver{Reader: reader{r: rr, ok: true}, Identity: id, Fingerprint: fp}
	got, err := r.Resolve(context.Background(), tx.ResolutionRequest{})
	if err != nil || got.State != tx.ResolutionCommitted {
		t.Fatalf("got=%+v err=%v", got, err)
	}
	r.Reader = reader{}
	got, err = r.Resolve(context.Background(), tx.ResolutionRequest{})
	if err != nil || got.State != tx.ResolutionUnknown {
		t.Fatalf("generic receipt miss must stay unknown: got=%+v err=%v", got, err)
	}
	other, _ := FingerprintRequest("different")
	rr.RequestFingerprint = other
	r.Reader = reader{r: rr, ok: true}
	_, err = r.Resolve(context.Background(), tx.ResolutionRequest{})
	var c *ConflictError
	if !errors.As(err, &c) {
		t.Fatalf("expected conflict, got %v", err)
	}
}

func TestNewCapturesOperationPolicyRefs(t *testing.T) {
	ps, err := policy.NewSet(policy.Ref{Name: "content", Version: "r1"})
	if err != nil {
		t.Fatal(err)
	}
	op := operation.Context{StartedAt: time.Unix(10, 0).UTC(), Policies: ps}
	id := Identity{OwnerKind: "player", OwnerKey: "1", Domain: "mail", Operation: "claim", SemanticKey: "m1"}
	r, err := New(op, id, "write", "v1", json.RawMessage(`{"ok":true}`), [32]byte{1})
	if err != nil {
		t.Fatal(err)
	}
	if !r.OperationPolicyRefs.Equal(ps) {
		t.Fatalf("got %#v want %#v", r.OperationPolicyRefs.Refs(), ps.Refs())
	}
}
