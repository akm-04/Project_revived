package characterhero

import (
	"encoding/json"
	"gxb.local/backend/v2/internal/domain/character"
	"testing"
)

func TestRawSkillHistoricalAndNewAcquisitionReceiptSnapshots(t *testing.T) {
	h := heroAt(1, 10001001, 10001001, 1, 1, 0, testOp(t, "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee").StartedAt)
	h.Kind = character.NormalHero
	raw, e := encodeAcquisitionReceipt(h)
	if e != nil {
		t.Fatal(e)
	}
	var ar acquisitionReceipt
	if e = json.Unmarshal(raw, &ar); e != nil {
		t.Fatal(e)
	}
	got, e := heroFromReceipt(ar, h.PlayerID, testOp(t, "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee"))
	if e != nil || got.RawSkills != h.RawSkills {
		t.Fatal(got, e)
	}
	ar.RawSkills = nil
	ar.SkillSchema = 0
	got, e = heroFromReceipt(ar, h.PlayerID, testOp(t, "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee"))
	if e != nil || got.RawSkills != character.NewHeroRawSkillSeed() {
		t.Fatal("historical seed", got, e)
	}
	ar.SkillSchema = 2
	if _, e = heroFromReceipt(ar, h.PlayerID, testOp(t, "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee")); e == nil {
		t.Fatal("missing new snapshot accepted")
	}
}
