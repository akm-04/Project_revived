package stockruntime

import (
	"context"
	"testing"
	"time"

	mentor "gxb.local/backend/v2/internal/application/mentor"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

type mentorTestAuthority struct{ actor identity.ActorContext }

func (a mentorTestAuthority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return a.actor, nil
}

type mentorTestService struct {
	err     error
	mid     uint16
	denyAll bool
	from    identity.PlayerID
}

func (s *mentorTestService) Info(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	s.mid = 1856
	return map[string]any{"base_info": map[string]any{}, "apply_list": []any{}, "mission_list": []any{[]any{}, []any{}}}, s.err
}
func (s *mentorTestService) Apply(context.Context, identity.ActorContext, identity.PlayerID, int64, string, operation.Context) (map[string]any, error) {
	s.mid = 1857
	return map[string]any{}, s.err
}
func (s *mentorTestService) Finding(context.Context, identity.ActorContext, int64, string, operation.Context) (map[string]any, error) {
	s.mid = 1858
	return map[string]any{"player_list": []any{}}, s.err
}
func (s *mentorTestService) Accept(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (map[string]any, error) {
	s.mid = 1859
	return map[string]any{}, s.err
}
func (s *mentorTestService) Deny(_ context.Context, _ identity.ActorContext, from identity.PlayerID, denyAll bool, _ operation.Context) (map[string]any, error) {
	s.mid, s.from, s.denyAll = 1860, from, denyAll
	return map[string]any{}, s.err
}
func (s *mentorTestService) Terminate(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error) {
	s.mid = 1861
	return map[string]any{}, s.err
}
func (s *mentorTestService) Claim(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error) {
	s.mid = 1862
	return map[string]any{"awards": []any{}}, s.err
}
func (s *mentorTestService) Exam(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error) {
	s.mid = 1863
	return map[string]any{"items": []any{}}, s.err
}

func uuidForMentorTest() ids.UUID {
	identifier, err := ids.NewUUID()
	if err != nil {
		panic(err)
	}
	return identifier
}

func mentorTestRequest(mid uint16, params map[string]any) httpedge.DispatchRequest {
	params["token"] = "bearer"
	params["region"] = int64(1001)
	at := time.Now().UTC()
	return httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{Operation: operation.Context{ID: uuidForMentorTest(), StartedAt: at}, MID: mid, ReceivedAt: at, Params: params, Claims: wire.CredentialClaims{Token: "bearer", Region: 1001}}}
}

func mentorTestActor() identity.ActorContext {
	return identity.ActorContext{PlayerID: 100100001, LogicalServerID: 1001}
}

func TestMentorDispatcherDenyModes(t *testing.T) {
	service := &mentorTestService{}
	dispatcher := MentorDispatcher{Authority: mentorTestAuthority{actor: mentorTestActor()}, Service: service}
	if got := dispatcher.Dispatch(context.Background(), mentorTestRequest(1860, map[string]any{"from_player_id": int64(100100002)})); got.HTTPStatus != 200 || service.mid != 1860 || service.denyAll || service.from != 100100002 {
		t.Fatalf("single deny %d %+v", got.HTTPStatus, service)
	}
	service = &mentorTestService{}
	dispatcher.Service = service
	if got := dispatcher.Dispatch(context.Background(), mentorTestRequest(1860, map[string]any{"is_deny_all": int64(1)})); got.HTTPStatus != 200 || !service.denyAll || service.from != 0 {
		t.Fatalf("deny all %d %+v", got.HTTPStatus, service)
	}
	service = &mentorTestService{}
	dispatcher.Service = service
	if got := dispatcher.Dispatch(context.Background(), mentorTestRequest(1860, map[string]any{"is_deny_all": int64(1), "from_player_id": int64(100100002)})); got.HTTPStatus != 400 || service.mid != 0 {
		t.Fatalf("both deny modes admitted %d %+v", got.HTTPStatus, service)
	}
}

func TestMentorDispatcherRefusalIsConflict(t *testing.T) {
	service := &mentorTestService{err: &mentor.Refusal{Code: 34012}}
	dispatcher := MentorDispatcher{Authority: mentorTestAuthority{actor: mentorTestActor()}, Service: service}
	got := dispatcher.Dispatch(context.Background(), mentorTestRequest(1861, map[string]any{"relation_type": int64(2)}))
	if got.HTTPStatus != 409 || got.Body["error_code"] != int64(34012) {
		t.Fatalf("refusal %d %#v", got.HTTPStatus, got.Body)
	}
}

// A-199: a blocked pair answers 34014 and a missing target answers 20004,
// both as typed 409 refusals through the stock Mentor dispatcher.
func TestMentorDispatcherApplyGuardRefusals(t *testing.T) {
	for _, code := range []int64{34014, 20004} {
		service := &mentorTestService{err: &mentor.Refusal{Code: code}}
		dispatcher := MentorDispatcher{Authority: mentorTestAuthority{actor: mentorTestActor()}, Service: service}
		got := dispatcher.Dispatch(context.Background(), mentorTestRequest(1857, map[string]any{"to_player_id": int64(100100002), "relation_type": int64(1), "msg": ""}))
		if got.HTTPStatus != 409 || got.Body["error_code"] != code {
			t.Fatalf("1857 refusal %d %#v, want 409/%d", got.HTTPStatus, got.Body, code)
		}
	}
}

// The 1858 windows check only xyd.error.OK, so a business refusal must be a
// 409 carrying a code the stock message table knows (34011: search level limit).
func TestMentorDispatcherFindingRefusalIsConflict(t *testing.T) {
	service := &mentorTestService{err: &mentor.Refusal{Code: 34011}}
	dispatcher := MentorDispatcher{Authority: mentorTestAuthority{actor: mentorTestActor()}, Service: service}
	got := dispatcher.Dispatch(context.Background(), mentorTestRequest(1858, map[string]any{"relation_type": int64(1)}))
	if got.HTTPStatus != 409 || got.Body["error_code"] != int64(34011) {
		t.Fatalf("1858 refusal %d %#v", got.HTTPStatus, got.Body)
	}
}

func TestMentorDispatcherSuccessShapes(t *testing.T) {
	dispatcher := MentorDispatcher{Authority: mentorTestAuthority{actor: mentorTestActor()}, Service: &mentorTestService{}}
	for _, tc := range []struct {
		mid    uint16
		params map[string]any
		key    string
	}{
		{1856, map[string]any{}, "mission_list"},
		{1858, map[string]any{"relation_type": int64(1)}, "player_list"},
		{1862, map[string]any{"mission_id": int64(100025)}, "awards"},
		{1863, map[string]any{"is_win": int64(1), "formation": "1|2|3"}, "items"},
	} {
		got := dispatcher.Dispatch(context.Background(), mentorTestRequest(tc.mid, tc.params))
		if got.HTTPStatus != 200 {
			t.Fatalf("MID %d status %d %#v", tc.mid, got.HTTPStatus, got.Body)
		}
		if _, ok := got.Body[tc.key]; !ok {
			t.Fatalf("MID %d missing %s: %#v", tc.mid, tc.key, got.Body)
		}
	}
}
