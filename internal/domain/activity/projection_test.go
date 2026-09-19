package activity

import (
	"math"
	"testing"
)

func TestProjectionCommonEnvelopeValidation(t *testing.T) {
	good := Projection{TableID: 1032, IsOpen: 1, StartTime: 0, EndTime: 0, Days: -1}
	if err := good.Validate(); err != nil {
		t.Fatal(err)
	}
	for name, p := range map[string]Projection{
		"table": {TableID: 0},
		"open":  {TableID: 1, IsOpen: 2},
		"start": {TableID: 1, StartTime: -1},
		"end":   {TableID: 1, EndTime: -1},
		"days":  {TableID: 1, Days: int64(math.MinInt32) - 1},
	} {
		t.Run(name, func(t *testing.T) {
			if p.Validate() == nil {
				t.Fatalf("accepted %#v", p)
			}
		})
	}
}
