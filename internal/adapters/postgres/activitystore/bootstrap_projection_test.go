package activitystore

import (
	"context"
	"fmt"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/activity"
	"gxb.local/backend/v2/internal/foundation/tx"

	appactivity "gxb.local/backend/v2/internal/application/activitydirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

func testActor(t *testing.T) identity.ActorContext {
	mk := func(b byte) ids.UUID { var u ids.UUID; u[15] = b; return u }
	a, _ := identity.AccountIDFrom(mk(1))
	s, _ := identity.SessionIDFrom(mk(2))
	c, _ := identity.ContextIDFrom(mk(3))
	return identity.ActorContext{AccountID: a, AccountUID: "u", SessionID: s, ContextID: c, LogicalServerID: 1, PlayerID: 100001, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}

func TestEmptyDirectoryOverlaysExactMID229ShapeWithoutDBTime(t *testing.T) {
	r, err := appactivity.NewRegistry(nil, nil)
	if err != nil {
		t.Fatal(err)
	}
	b := BootstrapProjection{Directory: appactivity.Directory{Registry: r}}
	detail := map[string]any{"229": map[string]any{"list": []any{map[string]any{"table_id": int64(1032)}}}}
	if err := b.OverlayMID1(context.Background(), nil, testActor(t), false, time.Unix(10, 0).UTC(), detail); err != nil {
		t.Fatal(err)
	}
	v, ok := detail["229"].(map[string]any)
	if !ok {
		t.Fatalf("shape %T", detail["229"])
	}
	list, ok := v["list"].([]any)
	if !ok || len(list) != 0 {
		t.Fatalf("list %#v", v["list"])
	}
}

type testRow struct{ at time.Time }

func (r testRow) Scan(dest ...any) error { *(dest[0].(*time.Time)) = r.at; return nil }

type testQueryer struct {
	at    time.Time
	calls *int
}

func (q testQueryer) QueryRow(context.Context, string, ...any) tx.Row {
	(*q.calls)++
	return testRow{at: q.at}
}

type bootstrapProvider struct {
	want time.Time
	seen *bool
}

func (p bootstrapProvider) Project(_ context.Context, pc appactivity.ProjectionContext) (activity.Projection, bool, error) {
	*p.seen = true
	if !pc.DecisionAt.Equal(p.want) {
		return activity.Projection{}, false, fmt.Errorf("decision=%v want=%v", pc.DecisionAt, p.want)
	}
	return activity.Projection{TableID: 77, IsOpen: 1, StartTime: 10, EndTime: 20, Days: 0, Details: map[string]any{"ok": int64(1)}}, true, nil
}

func TestBootstrapUsesDatabaseProjectionInstantForQualifiedProvider(t *testing.T) {
	want := time.Unix(900, 0).UTC()
	seen := false
	calls := 0
	r, err := appactivity.NewRegistry([]appactivity.Registration{{Name: "p", TableID: 77, RuntimeCapability: "activity.p", Provider: bootstrapProvider{want: want, seen: &seen}}}, nil)
	if err != nil {
		t.Fatal(err)
	}
	b := BootstrapProjection{Directory: appactivity.Directory{Registry: r}}
	detail := map[string]any{}
	q := testQueryer{at: want, calls: &calls}
	if err := b.OverlayMID1(context.Background(), q, testActor(t), false, time.Unix(1, 0).UTC(), detail); err != nil {
		t.Fatal(err)
	}
	if !seen || calls != 1 {
		t.Fatalf("seen=%t calls=%d", seen, calls)
	}
	list := detail["229"].(map[string]any)["list"].([]any)
	if len(list) != 1 || list[0].(map[string]any)["table_id"] != int64(77) {
		t.Fatalf("%#v", list)
	}
}
