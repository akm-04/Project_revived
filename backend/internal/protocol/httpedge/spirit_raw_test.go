package httpedge

import "testing"

func TestSpiritSelectedRawDuplicateBoundary(t *testing.T) {
	for _, raw := range []string{`{"mid":3089,"spirit_id":1,"spirit_id":2}`, `{"mid":3094,"mid":49,"pos":1}`, `{"mid":3113,"collocation":"1|0|0|0|0|0","collocation":"2|0|0|0|0|0"}`} {
		if validateSocialRaw([]byte(raw), false, 64, 1000) == nil {
			t.Fatal("duplicate lost", raw)
		}
	}
}
