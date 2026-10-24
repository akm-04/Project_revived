package httpedge

import "testing"

func TestEvolutionSelectedRawDuplicatesCannotBeCollapsed(t *testing.T) {
	for _, raw := range []string{`{"mid":2608,"partner_id":1,"partner_id":2}`, `{"mid":2609,"mid":49,"partner_id":1}`, `{"mid":2608,"attr_id":4,"attr_id":7}`, `{"mid":2608,"cost_item":40001001,"cost_item":50005149}`} {
		if validateSocialRaw([]byte(raw), false, 64, 1000) == nil {
			t.Fatal("ambiguous evolution packet accepted", raw)
		}
	}
}
