package contentstore

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"strings"
	"testing"
	"time"
)

func TestR5BootstrapBindingPreservesRevisionAcrossActivation(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	refs, _ := policy.NewSet(policy.Ref{Name: "bootstrap", Version: "v1"})
	op := operation.Context{ID: ids.UUID{1}, StartedAt: now, EntropySeed: [32]byte{7}, Policies: refs}
	q := &recording{values: []any{true, strings.Repeat("a", 64), int64(1), now, "operator"}}
	bound, err := (Store{}).BindCharacterBootstrapOperation(context.Background(), q, op)
	if err != nil {
		t.Fatal(err)
	}
	if bound.ID != op.ID || bound.StartedAt != op.StartedAt || bound.EntropySeed != op.EntropySeed {
		t.Fatal("operation identity changed")
	}
	if x, _ := bound.Policies.Get("bootstrap"); x != "v1" {
		t.Fatal("lost existing policy")
	}
	q.sql = ""
	q.err = errors.New("active pointer must not be read on retry")
	again, err := (Store{}).BindCharacterBootstrapOperation(context.Background(), q, bound)
	if err != nil {
		t.Fatal(err)
	}
	if x, _ := again.Policies.Get("content"); x != strings.Repeat("a", 64) || q.sql != "" {
		t.Fatal("rebound content on retry")
	}
}
func TestR5BootstrapBindingRejectsInvalidRevision(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	op := operation.Context{ID: ids.UUID{1}, StartedAt: now}
	q := &recording{values: []any{true, "bad", int64(1), now, "operator"}}
	if _, err := (Store{}).BindCharacterBootstrapOperation(context.Background(), q, op); err == nil {
		t.Fatal("bad revision accepted")
	}
}
