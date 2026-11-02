package combat

import "testing"

func TestAwakeningProducerProfilesPreservePinnedSnapshots(t *testing.T) {
	legacy, ok := LookupProducerProfile(LegacyProducerProfileID)
	if !ok {
		t.Fatal("legacy profile missing")
	}
	current := CurrentProducerProfile()
	if current.ID == legacy.ID {
		t.Fatal("producer activation must version snapshots")
	}
	for _, id := range []string{LegacyProducerProfileID, ProducerProfileID} {
		s := fixtureSnapshot()
		s.ProducerProfile = id
		raw, hash, err := s.Canonical()
		if err != nil {
			t.Fatal(id, err)
		}
		restored, err := DecodeSnapshot(raw, hash)
		if err != nil || restored.ProducerProfile != id {
			t.Fatal("pinned snapshot changed", id, err)
		}
	}
	params := fixtureActor(OwnedSelf, 9).Params
	for _, stage := range []int64{1, 2, 3} {
		positive := withParam(params, "twice_awake_stage", stage)
		if legacy.CheckOwned(HeroActor, positive) == nil {
			t.Fatal("legacy positive gate weakened", stage)
		}
		if err := current.CheckOwned(HeroActor, positive); err != nil {
			t.Fatal(stage, err)
		}
	}
	for _, stage := range []any{-1, 4, 1.5, "2", nil} {
		if current.CheckOwned(HeroActor, withParam(params, "twice_awake_stage", stage)) == nil {
			t.Fatal("invalid raw stage admitted", stage)
		}
	}
	if current.CheckOwned(HeroActor, withoutParam(params, "twice_awake_stage")) == nil {
		t.Fatal("missing raw facet admitted")
	}
	if current.CheckOwned(HeroActor, withParam(params, "buffs", []int64{})) == nil {
		t.Fatal("unrelated inactive producer activated")
	}
	for _, p := range current.Producers {
		if p.ID == "CHAR_RUNE" && p.Status != ProducerDeclaredInactive {
			t.Fatal("Rune activated")
		}
	}
}
