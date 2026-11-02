package stockruntime

import (
	"context"
	"net/http"
	"slices"

	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// Decorated adds the stock common hook keys economy_ and new_funcs_ (I9_MODE_FRAMEWORK_V1 F17, D93) from the state its
// owners committed during the request. Keys the dispatcher wrote itself win; refusals and failures stay untouched.
type Decorated struct {
	Next httpedge.Dispatcher
}

func (d Decorated) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	tracked, set := changes.Track(ctx)
	response := d.Next.Dispatch(tracked, req)
	succeeded := response.HTTPStatus == 0 || response.HTTPStatus == http.StatusOK
	if !succeeded || response.JSON != nil || response.Body == nil || stockRefusal(response.Body) {
		return response
	}
	mergeEconomy(response.Body, set.Balances())
	mergeNewFunctions(response.Body, set.Functions())
	for key, value := range set.MissionFields() {
		if key == "redmarks_" {
			if existing, ok := response.Body[key].(map[string]any); ok {
				merged := map[string]any{}
				for k, v := range value.(map[string]any) {
					merged[k] = v
				}
				for k, v := range existing {
					merged[k] = v
				}
				response.Body[key] = merged
				continue
			}
		}
		if _, written := response.Body[key]; !written {
			response.Body[key] = value
		}
	}
	return response
}

func stockRefusal(body map[string]any) bool {
	code, present := body["error_code"]
	return present && code != 0 && code != int64(0) && code != float64(0)
}

func mergeEconomy(body map[string]any, balances map[string]int64) {
	if len(balances) == 0 {
		return
	}
	economy := map[string]any{}
	for key, amount := range balances {
		economy[key] = amount
	}
	switch written := body["economy_"].(type) {
	case nil:
	case map[string]any:
		for key, value := range written {
			economy[key] = value
		}
	case map[string]int64:
		for key, value := range written {
			economy[key] = value
		}
	default:
		return
	}
	body["economy_"] = economy
}

func mergeNewFunctions(body map[string]any, opened []int64) {
	if len(opened) == 0 {
		return
	}
	switch written := body["new_funcs_"].(type) {
	case nil:
		body["new_funcs_"] = opened
	case []int64:
		union := append(slices.Clone(written), opened...)
		slices.Sort(union)
		body["new_funcs_"] = slices.Compact(union)
	}
}
