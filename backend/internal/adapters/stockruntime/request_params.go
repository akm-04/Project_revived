package stockruntime

import "fmt"

// onlyStockGameplayParams validates top-level command parameters while
// allowing the fields Backend.lua injects into every ordinary stock HTTP
// request. These fields are envelope/client metadata, not invented gameplay
// command arguments. Nested gameplay objects must continue using their strict
// command-local validators.
func int64List(params map[string]any, key string) ([]int64, error) {
	value, present := params[key]
	if !present || value == nil {
		return nil, nil
	}
	if direct, ok := value.([]int64); ok {
		return append([]int64(nil), direct...), nil
	}
	// The stock client's Lua encoder sends an empty array as {}.
	if object, ok := value.(map[string]any); ok && len(object) == 0 {
		return nil, nil
	}
	entries, ok := value.([]any)
	if !ok {
		return nil, fmt.Errorf("%s is not a list", key)
	}
	out := make([]int64, 0, len(entries))
	for _, entry := range entries {
		number, err := requiredInt64(map[string]any{key: entry}, key)
		if err != nil {
			return nil, err
		}
		out = append(out, number)
	}
	return out, nil
}

func onlyStockGameplayParams(params map[string]any, allowed ...string) bool {
	set := make(map[string]struct{}, len(allowed))
	for _, k := range allowed {
		set[k] = struct{}{}
	}
	for k := range params {
		switch k {
		case "mid", "token", "region", "v_", "app_v", "platform":
			continue
		}
		if _, ok := set[k]; !ok {
			return false
		}
	}
	return true
}
