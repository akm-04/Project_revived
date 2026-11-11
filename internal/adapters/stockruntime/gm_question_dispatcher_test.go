package stockruntime

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	questions "gxb.local/backend/v2/internal/application/gmquestion"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	domain "gxb.local/backend/v2/internal/domain/gmquestion"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/mids"
)

type questionProbe struct {
	asks, lists int
	entries     []questions.Entry
	err         error
}

func (probe *questionProbe) Ask(context.Context, identity.ActorContext, string, operation.Context) (questions.Acknowledgement, error) {
	probe.asks++
	return questions.Acknowledgement{}, probe.err
}
func (probe *questionProbe) List(context.Context, identity.ActorContext, operation.Context) ([]questions.Entry, error) {
	probe.lists++
	return probe.entries, probe.err
}
func TestGMQuestionDispatcherUsesOrdinarySourceShapes(t *testing.T) {
	probe := &questionProbe{}
	dispatcher := GMQuestionDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: probe}
	loaded := dispatcher.Dispatch(context.Background(), heroReq(t, 4, map[string]any{}))
	if loaded.HTTPStatus != 200 {
		t.Fatal(loaded)
	}
	assertGMQuestionBody(t, loaded.Body, `{"list":[]}`)

	probe.entries = []questions.Entry{{
		Question: domain.Question{Player: identity.PlayerID(225001), Message: "help 世界", AskedAt: time.Unix(1700000000, 0).UTC()},
		Profile:  playerdirectory.Profile{PlayerID: identity.PlayerID(225001), Name: "Player One", Level: 10, AvatarID: 8, AvatarFrameID: 9},
	}}
	history := dispatcher.Dispatch(context.Background(), heroReq(t, 4, map[string]any{}))
	if history.HTTPStatus != 200 {
		t.Fatal(history)
	}
	assertGMQuestionBody(t, history.Body, `{"list":[{"created_time":1700000000,"msg":"help 世界","player_id":225001,"player_type":0,"talker_id":225001,"talker_name":"Player One"}]}`)

	asked := dispatcher.Dispatch(context.Background(), heroReq(t, 5, map[string]any{"msg": "help"}))
	if asked.HTTPStatus != 200 {
		t.Fatal("GM acknowledgement", asked)
	}
	assertGMQuestionBody(t, asked.Body, `{}`)
	for _, parameters := range []map[string]any{{}, {"msg": 1}, {"msg": "help", "player_id": int64(225001)}} {
		result := dispatcher.Dispatch(context.Background(), heroReq(t, 5, parameters))
		if result.HTTPStatus != 400 {
			t.Fatal("malformed question", parameters, result)
		}
		assertGMQuestionBody(t, result.Body, `{"error":"invalid_gm_question_parameter"}`)
	}
	probe.err = domain.ErrQuestion
	refused := dispatcher.Dispatch(context.Background(), heroReq(t, 5, map[string]any{"msg": " "}))
	if refused.HTTPStatus != 409 {
		t.Fatal("200 refusal would append local message", refused)
	}
	assertGMQuestionBody(t, refused.Body, `{"error_code":35028,"error_msg":""}`)
	probe.err = questions.ErrProof
	unavailable := dispatcher.Dispatch(context.Background(), heroReq(t, 4, map[string]any{}))
	if unavailable.HTTPStatus != 503 {
		t.Fatal(unavailable)
	}
	assertGMQuestionBody(t, unavailable.Body, `{"error_code":35033,"error_msg":""}`)
	if probe.asks != 2 || probe.lists != 3 {
		t.Fatal("malformed request reached service", probe)
	}
}

func assertGMQuestionBody(t *testing.T, body map[string]any, expected string) {
	t.Helper()
	encoded, err := json.Marshal(body)
	if err != nil {
		t.Fatal(err)
	}
	if string(encoded) != expected {
		t.Fatalf("unexpected GM callback body: got %s, want %s", encoded, expected)
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
