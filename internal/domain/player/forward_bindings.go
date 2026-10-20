package player

// ForwardBindingsPolicy is C6_COSMETIC_FORWARD_BINDINGS_V1 (user Q1): rows whose
// producing mode is not live. They are never earnable, counted or claimed as a
// negative until the owning phase binds a producer and removes them here.
const ForwardBindingsPolicy = "C6_COSMETIC_FORWARD_BINDINGS_V1"

type catalogRange struct{ first, last int64 }

var forwardBound = map[string][]catalogRange{
	"title":  {{100006, 100021}, {100029, 100036}, {100053, 100058}, {100067, 100103}, {100105, 100110}, {100112, 100113}, {100122, 100123}, {100201, 100209}},
	"bubble": {{10008, 10008}},
	// Timed frames without a producer, and the nonbaseline VIP frames whose
	// commerce provider is I9; a VIP frame the privilege branch decides is not
	// unavailable and never reaches this registry.
	"frame": {{120001002, 120001003}, {120001041, 120001042}, {120001155, 120001155}, {120001163, 120001164}},
}

func ForwardBound(family string, id int64) bool {
	for _, r := range forwardBound[family] {
		if id >= r.first && id <= r.last {
			return true
		}
	}
	return false
}
