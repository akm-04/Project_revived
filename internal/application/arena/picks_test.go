package arena

import (
	"testing"

	d "gxb.local/backend/v2/internal/domain/arena"
)

func TestSeasonPickCountsSumAwakenedRowsUnderTheBaseGirl(t *testing.T) {
	templates := d.Templates{10001001: {Base: 10001001}, 10001041: {Base: 10001040, Awakened: true}}
	counts := seasonPickCounts([]d.Usage{{TableID: 10001041, Fights: 2}, {TableID: 10001001, Fights: 1}}, templates)
	if len(counts) != 2 {
		t.Fatalf("counts = %#v", counts)
	}
	if counts[10001040] != 2 {
		t.Fatalf("awakened usage row counted for base girl = %d, want 2", counts[10001040])
	}
	if counts[10001001] != 1 {
		t.Fatalf("base usage row count = %d, want 1", counts[10001001])
	}
}
