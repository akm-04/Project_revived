package stockruntime

import (
	dm "gxb.local/backend/v2/internal/application/generaldm"
	"testing"
	"time"
)

func Test6B_G33ConservativeCompletionBridge(t *testing.T) {
	n := time.Unix(1700000000, 0).UTC()
	for _, v := range []struct {
		name    string
		end     time.Time
		elapsed time.Duration
		want    time.Time
		bad     bool
	}{
		{"normal", n.Add(time.Second), time.Second, n.Add(1250 * time.Millisecond), false},
		{"slow-observation", n.Add(3 * time.Second), time.Second, n.Add(3 * time.Second), false},
		{"forward", n.Add(time.Hour), time.Millisecond, n.Add(time.Hour), false},
		{"backward", n.Add(-time.Second), time.Millisecond, time.Time{}, true},
		{"tolerance-equality", n.Add(750 * time.Millisecond), time.Second, n.Add(1250 * time.Millisecond), false},
		{"beyond-tolerance", n.Add(750*time.Millisecond - time.Nanosecond), time.Second, time.Time{}, true},
	} {
		t.Run(v.name, func(t *testing.T) {
			u, e := GeneralCompletionUpper(n, v.end, v.elapsed)
			if (e != nil) != v.bad || !u.Equal(v.want) {
				t.Fatal(u, e)
			}
		})
	}
	if _, e := GeneralCompletionUpper(n, n, -time.Nanosecond); e != dm.ErrTimeInvalid {
		t.Fatal(e)
	}
}
