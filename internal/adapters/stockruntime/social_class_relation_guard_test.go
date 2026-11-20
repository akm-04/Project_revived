package stockruntime

import (
	"context"
	"errors"
	"testing"

	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type classRelationProbe struct {
	active bool
	err    error
}

func (probe *classRelationProbe) ClassRelationActive(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (bool, error) {
	return probe.active, probe.err
}

type relationCommandProbe struct {
	executed int
}

func (probe *relationCommandProbe) Execute(context.Context, identity.ActorContext, sr.Command, operation.Context) (sr.Result, error) {
	probe.executed++
	return sr.Result{}, nil
}

// A-200: an active class relation refuses friend delete (34017) and blacklist
// (34013) before the SocialRelation owner runs, and the code travels as a 409.
func TestSocialDispatcherRefusesClassPairOnFriendSurface(t *testing.T) {
	for _, testCase := range []struct {
		name string
		mid  uint16
		code int64
	}{
		{name: "delete friend", mid: 181, code: 34017},
		{name: "add blacklist", mid: 185, code: 34013},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			relations := &relationCommandProbe{}
			dispatcher := SocialDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Relations: relations, Mentor: &classRelationProbe{active: true}, Emitter: discardReloads{}}
			response := dispatcher.Dispatch(context.Background(), heroReq(t, testCase.mid, map[string]any{"player_id": int64(200001)}))
			if response.HTTPStatus != 409 || response.Body["error_code"] != testCase.code {
				t.Fatalf("MID %d status %d body %#v, want 409/%d", testCase.mid, response.HTTPStatus, response.Body, testCase.code)
			}
			if relations.executed != 0 {
				t.Fatalf("MID %d reached the relation owner despite the class guard", testCase.mid)
			}
		})
	}
}

func TestSocialDispatcherFriendDeleteWithoutClassRelationRunsOwner(t *testing.T) {
	relations := &relationCommandProbe{}
	dispatcher := SocialDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Relations: relations, Mentor: &classRelationProbe{}, Emitter: discardReloads{}}
	response := dispatcher.Dispatch(context.Background(), heroReq(t, 181, map[string]any{"player_id": int64(200001)}))
	if response.HTTPStatus != 200 || relations.executed != 1 {
		t.Fatalf("status %d executed %d body %#v", response.HTTPStatus, relations.executed, response.Body)
	}
}

func TestSocialDispatcherClassObservationFailureIsDefect(t *testing.T) {
	dispatcher := SocialDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Relations: &relationCommandProbe{}, Mentor: &classRelationProbe{err: errors.New("database unavailable")}, Emitter: discardReloads{}}
	response := dispatcher.Dispatch(context.Background(), heroReq(t, 181, map[string]any{"player_id": int64(200001)}))
	if response.HTTPStatus != 500 || response.Body["error_code"] != unprovenRefusalCode {
		t.Fatalf("status %d body %#v, want 500/%d", response.HTTPStatus, response.Body, unprovenRefusalCode)
	}
}

func TestSocialDispatcherClassGuardedMIDsNeedTheObservation(t *testing.T) {
	dispatcher := SocialDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Relations: &relationCommandProbe{}, Emitter: discardReloads{}}
	response := dispatcher.Dispatch(context.Background(), heroReq(t, 185, map[string]any{"player_id": int64(200001)}))
	if response.HTTPStatus != 500 || response.Body["error_code"] != unprovenRefusalCode {
		t.Fatalf("status %d body %#v, want 500/%d", response.HTTPStatus, response.Body, unprovenRefusalCode)
	}
}
