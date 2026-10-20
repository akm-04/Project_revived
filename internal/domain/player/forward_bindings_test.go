package player

import "testing"

func TestForwardBindingsMatchThePolicyLists(t *testing.T) {
	titles := 0
	for id := int64(100000); id < 100300; id++ {
		if ForwardBound("title", id) {
			titles++
		}
	}
	if titles != 86 {
		t.Fatal("forward-bound titles", titles)
	}
	for _, routed := range []int64{100001, 100005, 100022, 100028, 100059, 100063, 100066, 100104, 100111, 100114, 100121} {
		if ForwardBound("title", routed) {
			t.Fatal("title with a live owner is forward-bound", routed)
		}
	}
	if !ForwardBound("bubble", 10008) || ForwardBound("bubble", 10007) || !ForwardBound("frame", 120001155) || ForwardBound("frame", 120001156) || ForwardBound("avatar", 110006001) {
		t.Fatal("bubble/frame/avatar registry")
	}
}
