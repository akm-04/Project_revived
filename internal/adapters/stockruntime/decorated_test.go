package stockruntime

import (
	"context"
	"reflect"
	"testing"

	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

func decorate(body map[string]any, status int) httpedge.Response {
	return Decorated{Next: httpedge.DispatcherFunc(func(ctx context.Context, _ httpedge.DispatchRequest) httpedge.Response {
		changes.Balance(ctx, "crystal", 90)
		changes.Balance(ctx, "mana", 7)
		changes.FunctionOpened(ctx, 12)
		changes.FunctionOpened(ctx, 3)
		return httpedge.Response{HTTPStatus: status, Body: body}
	})}.Dispatch(context.Background(), httpedge.DispatchRequest{})
}

func TestDecoratedMergesCommittedChanges(t *testing.T) {
	got := decorate(map[string]any{"economy_": map[string]int64{"mana": 5}, "new_funcs_": []int64{3, 40}}, 200).Body
	if !reflect.DeepEqual(got["economy_"], map[string]any{"crystal": int64(90), "mana": int64(5)}) {
		t.Fatalf("economy_ %v", got["economy_"])
	}
	if !reflect.DeepEqual(got["new_funcs_"], []int64{3, 12, 40}) {
		t.Fatalf("new_funcs_ %v", got["new_funcs_"])
	}
}

func TestDecoratedLeavesRefusalsAlone(t *testing.T) {
	for _, response := range []httpedge.Response{decorate(map[string]any{"error_code": 1}, 200), decorate(map[string]any{"error": "x"}, 503)} {
		if _, has := response.Body["economy_"]; has {
			t.Fatalf("decorated a refusal: %v", response.Body)
		}
	}
	if got := decorate(map[string]any{"error_code": 0}, 200).Body; got["economy_"] == nil {
		t.Fatal("error_code 0 is not a refusal")
	}
}
