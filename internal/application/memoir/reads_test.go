package memoir

import "testing"

func TestTenthFloorNeedsTenGirls(t *testing.T) {
	nine := map[int64]int{}
	for girl := int64(1); girl <= 9; girl++ {
		nine[girl] = 3
	}
	if got := TenthFloor(nine); got != 0 {
		t.Fatalf("nine girls gave %d, want 0", got)
	}
	ten := map[int64]int{}
	for girl := int64(1); girl <= 9; girl++ {
		ten[girl] = 100
	}
	ten[10] = 4
	if got := TenthFloor(ten); got != 4 {
		t.Fatalf("tenth-highest gave %d, want 4", got)
	}
}
