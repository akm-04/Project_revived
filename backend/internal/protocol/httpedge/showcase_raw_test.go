package httpedge

import "testing"

func TestShowcaseSelectedRawDuplicateBoundary(t *testing.T) {
	for _, mid := range []string{"1832", "1838"} {
		for _, raw := range []string{`{"mid":` + mid + `,"params":{"ids":[1,0,0,0,0,0],"ids":[0,0,0,0,0,0]}}`, `{"mid":` + mid + `,"mid":1,"params":{}}`} {
			if validateSocialRaw([]byte(raw), false, 32, 1000) == nil {
				t.Fatal("ambiguous showcase", raw)
			}
		}
	}
}
