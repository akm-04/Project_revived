package stockruntime

import (
	"context"
	"testing"

	questions "gxb.local/backend/v2/internal/application/gmquestion"
	domain "gxb.local/backend/v2/internal/domain/gmquestion"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/mids"
)

type questionProbe struct {
	asks, lists int
	err         error
}

func (probe *questionProbe) Ask(context.Context, identity.ActorContext, string, operation.Context) (questions.Acknowledgement, error) {
	probe.asks++
	return questions.Acknowledgement{}, probe.err
}
func (probe *questionProbe) List(context.Context, identity.ActorContext, operation.Context) ([]questions.Entry, error) {
	probe.lists++
	return []questions.Entry{}, probe.err
}
func TestGMQuestionDispatcherUsesOrdinarySourceShapes(t *testing.T) {
	probe := &questionProbe{}
	dispatcher := GMQuestionDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: probe}
	loaded := dispatcher.Dispatch(context.Background(), heroReq(t, 4, map[string]any{}))
	if loaded.HTTPStatus != 200 {
		t.Fatal(loaded)
	}
	rows, ok := loaded.Body["list"].([]any)
	if !ok || rows == nil || len(rows) != 0 {
		t.Fatal("GM list shape", loaded)
	}
	asked := dispatcher.Dispatch(context.Background(), heroReq(t, 5, map[string]any{"msg": "help"}))
	if asked.HTTPStatus != 200 || asked.Body["gm_url"] != nil || asked.Body["list"] != nil {
		t.Fatal("GM acknowledgement", asked)
	}
	for _, parameters := range []map[string]any{{}, {"msg": 1}, {"msg": "help", "player_id": int64(225001)}} {
		result := dispatcher.Dispatch(context.Background(), heroReq(t, 5, parameters))
		if result.HTTPStatus != 400 {
			t.Fatal("malformed question", parameters, result)
		}
	}
	probe.err = domain.ErrQuestion
	refused := dispatcher.Dispatch(context.Background(), heroReq(t, 5, map[string]any{"msg": " "}))
	if refused.HTTPStatus != 409 || refused.Body["list"] != nil {
		t.Fatal("200 refusal would append local message", refused)
	}
	probe.err = questions.ErrProof
	unavailable := dispatcher.Dispatch(context.Background(), heroReq(t, 4, map[string]any{}))
	if unavailable.HTTPStatus != 503 || unavailable.Body["list"] != nil {
		t.Fatal(unavailable)
	}
	if probe.asks != 2 || probe.lists != 2 {
		t.Fatal("malformed request reached service", probe)
	}
}

func TestGMQuestionsDoNotUseMaskedTransport(t *testing.T) {
	for _, number := range []uint16{4, 5} {
		descriptor, found := mids.Lookup(number)
		if !found || descriptor.Transport != mids.HTTP || mids.IsGMNumber(number) {
			t.Fatal("question routed to unavailable GM URL", number, descriptor)
		}
	}
}
