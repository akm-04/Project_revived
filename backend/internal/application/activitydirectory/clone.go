package activitydirectory

import (
	"encoding/json"
	"math"
)

const (
	maxDetailsDepth = 32
	maxDetailsNodes = 20000
)

func cloneDetails(v any) (any, error) {
	nodes := 0
	return cloneJSON(v, 0, &nodes)
}

func cloneJSON(v any, depth int, nodes *int) (any, error) {
	if depth > maxDetailsDepth || *nodes >= maxDetailsNodes {
		return nil, ErrUnsupportedDetails
	}
	*nodes++
	switch x := v.(type) {
	case nil, bool, string, int, int32, int64:
		return x, nil
	case float64:
		if math.IsNaN(x) || math.IsInf(x, 0) {
			return nil, ErrUnsupportedDetails
		}
		return x, nil
	case json.Number:
		if _, err := x.Int64(); err != nil {
			if f, ferr := x.Float64(); ferr != nil || math.IsNaN(f) || math.IsInf(f, 0) {
				return nil, ErrUnsupportedDetails
			}
		}
		return x, nil
	case map[string]any:
		out := make(map[string]any, len(x))
		for k, item := range x {
			if k == "" {
				return nil, ErrUnsupportedDetails
			}
			cv, err := cloneJSON(item, depth+1, nodes)
			if err != nil {
				return nil, err
			}
			out[k] = cv
		}
		return out, nil
	case []any:
		out := make([]any, len(x))
		for i, item := range x {
			cv, err := cloneJSON(item, depth+1, nodes)
			if err != nil {
				return nil, err
			}
			out[i] = cv
		}
		return out, nil
	default:
		return nil, ErrUnsupportedDetails
	}
}
