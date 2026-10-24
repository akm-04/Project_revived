package provision

import "testing"

func TestStockOpenLevel(t *testing.T) {
	for raw, want := range map[string]int64{"1|10": 10, "6|60|5": 60, "7|100": 100, "2|100018": -1, "3|30|9": -1, "": -1} {
		level, readable := stockOpenLevel(raw)
		if (want < 0 && readable) || (want >= 0 && (!readable || level != want)) {
			t.Errorf("stockOpenLevel(%q) = %d, %v; want %d", raw, level, readable, want)
		}
	}
}
