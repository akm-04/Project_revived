package stockruntime

import (
	"context"
	"errors"
	"net/http"
	"testing"
	"time"

	appactivity "gxb.local/backend/v2/internal/application/activitydirectory"
	"gxb.local/backend/v2/internal/domain/activity"
)

func TestPart3BActivityFailureReplies(t *testing.T) {
	failing := activityProviderFunc(func(context.Context, appactivity.ProjectionContext) (activity.Projection, bool, error) {
		return activity.Projection{}, false, errors.New("database unavailable")
	})
	registry, err := appactivity.NewRegistry([]appactivity.Registration{{Name: "failing", TableID: 1032, RuntimeCapability: "activity.failing", Provider: failing}}, nil)
	if err != nil {
		t.Fatal(err)
	}
	dispatcher := ActivityDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: appactivity.Runtime{Directory: appactivity.Directory{Registry: registry}}}
	request := activityReq(229, map[string]any{}, time.Unix(10, 0).UTC())
	assertPart2FailureCases(t, []part2FailureCase{
		{"projection unavailable", dispatcher.Dispatch(context.Background(), request), http.StatusServiceUnavailable, serverBusyCode, ""},
		{"invalid activity id", dispatcher.Dispatch(context.Background(), activityReq(234, map[string]any{"activity_id": int64(0)}, time.Unix(10, 0).UTC())), http.StatusBadRequest, 0, "invalid_activity_id"},
	})
}
