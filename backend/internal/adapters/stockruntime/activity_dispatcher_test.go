package stockruntime

import (
	"context"
	"testing"
	"time"

	appactivity "gxb.local/backend/v2/internal/application/activitydirectory"
	"gxb.local/backend/v2/internal/domain/activity"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

type activityProviderFunc func(context.Context, appactivity.ProjectionContext) (activity.Projection, bool, error)

func (f activityProviderFunc) Project(ctx context.Context, pc appactivity.ProjectionContext) (activity.Projection, bool, error) {
	return f(ctx, pc)
}

type activityTime struct{ at time.Time }

func (s activityTime) Now(context.Context) (time.Time, error) { return s.at, nil }

func activityReq(mid uint16, params map[string]any, now time.Time) httpedge.DispatchRequest {
	return httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: mid, ReceivedAt: now, Params: params, Claims: wire.CredentialClaims{Token: "bearer", Region: 1}}}
}

func TestActivityMID229EmptyRegistrySourceShape(t *testing.T) {
	r, err := appactivity.NewRegistry(nil, nil)
	if err != nil {
		t.Fatal(err)
	}
	d := ActivityDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: appactivity.Runtime{Directory: appactivity.Directory{Registry: r}}}
	got := d.Dispatch(context.Background(), activityReq(229, map[string]any{}, time.Unix(10, 0).UTC()))
	if got.HTTPStatus != 200 {
		t.Fatalf("%+v", got)
	}
	list, ok := got.Body["list"].([]any)
	if !ok || len(list) != 0 {
		t.Fatalf("list=%#v", got.Body["list"])
	}
}

func TestActivityMID234UnknownFailsClosedWithoutSentinel(t *testing.T) {
	r, _ := appactivity.NewRegistry(nil, nil)
	d := ActivityDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: appactivity.Runtime{Directory: appactivity.Directory{Registry: r}}}
	got := d.Dispatch(context.Background(), activityReq(234, map[string]any{"activity_id": int64(1032)}, time.Unix(10, 0).UTC()))
	if got.HTTPStatus == 200 || got.Body["table_id"] != nil {
		t.Fatalf("fabricated sentinel: %+v", got)
	}
}

func TestActivityMID234RegisteredProjectionAndCanonicalActor(t *testing.T) {
	wantAt := time.Unix(500, 0).UTC()
	actor := actorForHTTP(t)
	seen := false
	p := activityProviderFunc(func(_ context.Context, pc appactivity.ProjectionContext) (activity.Projection, bool, error) {
		seen = true
		if pc.Actor.PlayerID != actor.PlayerID || pc.Actor.LogicalServerID != actor.LogicalServerID || !pc.DecisionAt.Equal(wantAt) {
			t.Fatalf("context=%+v", pc)
		}
		return activity.Projection{TableID: 1032, IsOpen: 0, StartTime: 100, EndTime: 200, Days: 0, Details: map[string]any{"x": int64(1)}}, true, nil
	})
	r, err := appactivity.NewRegistry([]appactivity.Registration{{Name: "half", TableID: 1032, RuntimeCapability: "activity.half", Provider: p}}, nil)
	if err != nil {
		t.Fatal(err)
	}
	d := ActivityDispatcher{Authority: httpAuthority{actor}, Service: appactivity.Runtime{Directory: appactivity.Directory{Registry: r}, Time: activityTime{at: wantAt}}}
	got := d.Dispatch(context.Background(), activityReq(234, map[string]any{"activity_id": int64(1032)}, time.Unix(10, 0).UTC()))
	if got.HTTPStatus != 200 || !seen || got.Body["table_id"] != int64(1032) || got.Body["is_open"] != int64(0) {
		t.Fatalf("%+v seen=%t", got, seen)
	}
}

func TestActivityDispatcherRejectsForgedRegion(t *testing.T) {
	r, _ := appactivity.NewRegistry(nil, nil)
	d := ActivityDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: appactivity.Runtime{Directory: appactivity.Directory{Registry: r}}}
	req := activityReq(229, map[string]any{}, time.Unix(10, 0).UTC())
	req.Envelope.Claims.Region = 2
	if got := d.Dispatch(context.Background(), req); got.HTTPStatus != 403 {
		t.Fatalf("%+v", got)
	}
}
