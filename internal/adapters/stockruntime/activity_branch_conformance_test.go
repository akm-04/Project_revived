package stockruntime

import (
	"context"
	"testing"
	"time"

	appactivity "gxb.local/backend/v2/internal/application/activitydirectory"
	"gxb.local/backend/v2/internal/application/worldboss"
	"gxb.local/backend/v2/internal/domain/activity"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
)

func TestWorldBossActivityReplySatisfiesItsOwnBranchObligations(t *testing.T) {
	provider := activityProviderFunc(func(ctx context.Context, pc appactivity.ProjectionContext) (activity.Projection, bool, error) {
		pc.PlayerLevel = func(context.Context, identity.PlayerID) (int64, bool, error) { return 48, true, nil }
		return (worldboss.ActivityProvider{}).Project(ctx, pc)
	})
	registry, err := appactivity.NewRegistry([]appactivity.Registration{{Name: "worldboss", TableID: 1026, RuntimeCapability: "activity.worldboss", Provider: provider}}, nil)
	if err != nil {
		t.Fatal(err)
	}
	dispatcher := ActivityDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: appactivity.Runtime{Directory: appactivity.Directory{Registry: registry}, Time: activityTime{at: time.Unix(500, 0).UTC()}}}
	response := dispatcher.Dispatch(context.Background(), activityReq(234, map[string]any{"activity_id": int64(1026)}, time.Unix(500, 0).UTC()))
	if response.HTTPStatus != 200 || response.Body["table_id"] != int64(1026) {
		t.Fatalf("response=%+v", response)
	}
	if violations := (replyconformance.Checker{}).Check(234, response.Body); len(violations) != 0 {
		t.Fatalf("valid production worldboss projection produced %d violations: %v", len(violations), violations)
	}
}
