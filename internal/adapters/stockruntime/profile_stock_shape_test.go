package stockruntime

import (
	"context"
	feedback "gxb.local/backend/v2/internal/application/profilefeedback"
	"gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/profilefeedback"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"maps"
	"testing"
	"time"
)

type stockShapeFeedback struct {
	actor identity.ActorContext
}

func (s stockShapeFeedback) Execute(_ context.Context, _ identity.ActorContext, q feedback.Command, _ operation.Context) (feedback.CommandResult, error) {
	return feedback.CommandResult{Current: d.Observation{Target: q.Target, Actor: s.actor.PlayerID, HasPraised: true, Count: 1}}, nil
}

func (s stockShapeFeedback) List(context.Context, identity.ActorContext, feedback.PageRequest, operation.Context) (feedback.Page, error) {
	return feedback.Page{Rows: []feedback.Row{}, Current: d.Observation{Target: s.actor.PlayerID}}, nil
}

func stockShapeRequest(mid uint16, params map[string]any) httpedge.DispatchRequest {
	r := activityReq(mid, params, time.Now())
	maps.Copy(r.Envelope.Params, map[string]any{"v_": "1.0.0", "app_v": "1.0.0", "platform": "android"})
	return r
}

func TestStockEnvelopeFieldsReachProfileReadAndFeedbackMIDs(t *testing.T) {
	a := actorForHTTP(t)
	reads := PublicProfileReadDispatcher{Authority: httpAuthority{a}, Service: profileReadsFunc(func(context.Context, identity.ActorContext, publicprofile.ReadRequest, operation.Context) (map[string]any, error) {
		return map[string]any{"all_show_types": map[string]int64{}}, nil
	})}
	if got := reads.Dispatch(context.Background(), stockShapeRequest(1829, map[string]any{"to_player_id": int64(100002)})); got.HTTPStatus != 200 {
		t.Fatalf("1829 stock envelope %+v", got)
	}

	dispatcher := ProfileFeedbackDispatcher{Authority: httpAuthority{a}, Service: stockShapeFeedback{actor: a}}
	if got := dispatcher.Dispatch(context.Background(), stockShapeRequest(1830, map[string]any{"to_player_id": int64(100002)})); got.HTTPStatus != 200 {
		t.Fatalf("1830 stock envelope %+v", got)
	}
	if got := dispatcher.Dispatch(context.Background(), stockShapeRequest(1842, map[string]any{"start": int64(0), "offset": int64(10)})); got.HTTPStatus != 200 {
		t.Fatalf("1842 stock envelope %+v", got)
	}
}
