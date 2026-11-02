package stockruntime

import (
	"context"
	feedback "gxb.local/backend/v2/internal/application/profilefeedback"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/profilefeedback"
	"gxb.local/backend/v2/internal/foundation/operation"
	"testing"
)

type stockShapeComments struct{}

func (stockShapeComments) ExecuteComment(_ context.Context, a identity.ActorContext, q feedback.CommentCommand, _ operation.Context) (feedback.CommentResult, error) {
	out := feedback.CommentResult{Terminal: feedback.CommentTerminal{Kind: q.Kind, Actor: a.PlayerID}}
	switch q.Kind {
	case "post":
		out.Current = d.CommentObservation{Target: q.Target, Actor: a.PlayerID, Best: []d.CommentRow{}, Rows: []d.CommentRow{}}
	case "react":
		out.Affected = &d.CommentRow{ID: q.CommentID, Owner: q.Target, HasPraised: 1}
	}
	return out, nil
}

func (stockShapeComments) ListComments(_ context.Context, a identity.ActorContext, target identity.PlayerID, _ feedback.PageRequest, _ operation.Context) (feedback.CommentPage, error) {
	return feedback.CommentPage{Target: target, Actor: a.PlayerID, Best: []d.CommentRow{}, Rows: []d.CommentRow{}}, nil
}

func TestStockEnvelopeFieldsReachProfileCommentMIDs(t *testing.T) {
	a := actorForHTTP(t)
	dispatcher := ProfileCommentDispatcher{Authority: httpAuthority{a}, Service: stockShapeComments{}}
	for mid, params := range map[uint16]map[string]any{
		1835: {"to_player_id": int64(100002), "content": "hello"},
		1836: {"to_player_id": int64(100002), "comment_id": int64(7)},
		1839: {"to_player_id": int64(100002), "start": int64(0), "offset": int64(10)},
		1841: {"comment_id": int64(7)},
	} {
		if got := dispatcher.Dispatch(context.Background(), stockShapeRequest(mid, params)); got.HTTPStatus != 200 {
			t.Fatalf("%d stock envelope %+v", mid, got)
		}
	}
	if got := dispatcher.Dispatch(context.Background(), stockShapeRequest(1835, map[string]any{"to_player_id": int64(100002), "content": "hello", "player_id": int64(1)})); got.HTTPStatus != 400 {
		t.Fatalf("foreign field accepted %+v", got)
	}
}
