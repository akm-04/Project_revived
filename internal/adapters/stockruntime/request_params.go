package stockruntime

// onlyStockGameplayParams validates top-level command parameters while
// allowing the fields Backend.lua injects into every ordinary stock HTTP
// request. These fields are envelope/client metadata, not invented gameplay
// command arguments. Nested gameplay objects must continue using their strict
// command-local validators.
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
