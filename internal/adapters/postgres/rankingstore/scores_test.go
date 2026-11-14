package rankingstore

import (
	"encoding/json"
	"strings"
	"testing"

	d "gxb.local/backend/v2/internal/domain/ranking"
)

func TestDecodeScoreMetricIsStrict(t *testing.T) {
	raw, err := json.Marshal(d.BoardMetric{Player: 7, Owner: "CharacterHero", Policy: "policy", Semantics: "semantics", Revision: strings.Repeat("a", 64), PopulationDigest: strings.Repeat("b", 64), FieldID: 1001, Value: 3, SourceVersion: 1, PopulationVersion: 1})
	if err != nil {
		t.Fatal(err)
	}
	if _, err = decodeScoreMetric(string(raw)); err != nil {
		t.Fatal(err)
	}
	unknown := strings.TrimSuffix(string(raw), "}") + `,"Unexpected":1}`
	if _, err = decodeScoreMetric(unknown); err == nil {
		t.Fatal("accepted an unknown metric field")
	}
	if _, err = decodeScoreMetric(string(raw) + `{}`); err == nil {
		t.Fatal("accepted trailing JSON values")
	}
}
