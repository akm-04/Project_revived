package stockruntime

import (
	"context"
	"errors"
	"testing"

	recall "gxb.local/backend/v2/internal/application/socialrecall"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
)

type recallStartProbe struct {
	calls   int
	target  identity.PlayerID
	current operation.Context
	err     error
}

func (probe *recallStartProbe) Start(_ context.Context, _ identity.ActorContext, target identity.PlayerID, current operation.Context) (map[string]any, error) {
	probe.calls++
	probe.target = target
	probe.current = current
	return map[string]any{"doing_recall": []any{map[string]any{"player_id": int64(target), "player_name": "target", "recalling_time": int64(1)}}}, probe.err
}

type recallAwardProbe struct {
	calls   int
	award   int64
	current operation.Context
	err     error
}

func (probe *recallAwardProbe) Claim(_ context.Context, _ identity.ActorContext, award int64, current operation.Context) (map[string]any, error) {
	probe.calls++
	probe.award = award
	probe.current = current
	return map[string]any{"recall_awarded": []int64{100001}, "awards": []any{map[string]any{"table_id": int64(-1), "item_num": int64(50), "crystal": int64(50)}}}, probe.err
}

func TestRecallAwardDispatcherStockShapeAndRefusals(t *testing.T) {
	probe := &recallAwardProbe{}
	dispatcher := SocialRecallAwardDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: probe}
	for _, test := range []struct {
		parameters map[string]any
		status     int
	}{
		{map[string]any{"award_id": int64(100001)}, 200},
		{map[string]any{"award_id": int64(100001), "content_revision": "forged"}, 400},
		{map[string]any{}, 400},
		{map[string]any{"award_id": 1.5}, 400},
		{map[string]any{"award_id": int64(0)}, 400},
	} {
		request := heroReq(t, 194, test.parameters)
		result := dispatcher.Dispatch(context.Background(), request)
		if result.HTTPStatus != test.status {
			t.Fatal(test.parameters, result)
		}
		if test.status != 200 && result.Body["awards"] != nil {
			t.Fatal("refusal ran success callback", result)
		}
		if test.status == 200 && (probe.award != 100001 || probe.current.ID != request.Envelope.Operation.ID) {
			t.Fatal("dispatcher changed semantic request")
		}
	}
	if probe.calls != 1 {
		t.Fatal(probe.calls)
	}
	for _, refusal := range []error{recall.ErrAwardRefused, &receipt.ConflictError{}} {
		probe.err = refusal
		result := dispatcher.Dispatch(context.Background(), heroReq(t, 194, map[string]any{"award_id": int64(100001)}))
		if result.HTTPStatus != 409 || result.Body["awards"] != nil {
			t.Fatal(refusal, result)
		}
	}
	for _, failure := range []error{recall.ErrAwardProof, recall.ErrAwardUnavailable, errors.New("database unavailable")} {
		probe.err = failure
		result := dispatcher.Dispatch(context.Background(), heroReq(t, 194, map[string]any{"award_id": int64(100001)}))
		if result.HTTPStatus != 500 || result.Body["awards"] != nil {
			t.Fatal(failure, result)
		}
	}
}

func TestRecallStartDispatcherStockShapeAndRefusals(t *testing.T) {
	probe := &recallStartProbe{}
	dispatcher := SocialRecallStartDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: probe}
	for _, test := range []struct {
		parameters map[string]any
		status     int
	}{
		{map[string]any{"friend_id": int64(125002)}, 200},
		{map[string]any{"friend_id": int64(125002), "content_revision": "forged"}, 400},
		{map[string]any{}, 400},
		{map[string]any{"friend_id": 1.5}, 400},
		{map[string]any{"friend_id": int64(0)}, 409},
	} {
		request := heroReq(t, 193, test.parameters)
		result := dispatcher.Dispatch(context.Background(), request)
		if result.HTTPStatus != test.status {
			t.Fatal(test.parameters, result)
		}
		if test.status != 200 && result.Body["doing_recall"] != nil {
			t.Fatal("refusal ran success callback", result)
		}
		if test.status == 200 && (probe.target != 125002 || probe.current.ID != request.Envelope.Operation.ID || len(probe.current.Policies.Refs()) != len(request.Envelope.Operation.Policies.Refs())) {
			t.Fatal("dispatcher changed semantic request")
		}
	}
	if probe.calls != 1 {
		t.Fatal(probe.calls)
	}
	for _, refusal := range []error{recall.ErrStartFacts, recall.ErrStartRefused, &receipt.ConflictError{}} {
		probe.err = refusal
		result := dispatcher.Dispatch(context.Background(), heroReq(t, 193, map[string]any{"friend_id": int64(125002)}))
		if result.HTTPStatus != 409 || result.Body["doing_recall"] != nil {
			t.Fatal(refusal, result)
		}
	}
	probe.err = errors.New("database unavailable")
	result := dispatcher.Dispatch(context.Background(), heroReq(t, 193, map[string]any{"friend_id": int64(125002)}))
	if result.HTTPStatus != 500 || result.Body["doing_recall"] != nil {
		t.Fatal(result)
	}
}
