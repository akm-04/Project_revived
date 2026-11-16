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
	for _, id := range []string{LegacyProducerProfileID, AwakeningProducerProfileID, ProducerProfileID} {
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
	awakening, ok := LookupProducerProfile(AwakeningProducerProfileID)
	if !ok || awakening.ID != AwakeningProducerProfileID {
		t.Fatalf("awakening profile identity %+v", awakening)
	}
	registered, found := LookupProducerProfile(ProducerProfileID)
	if !found || registered.ID != ProducerProfileID || current.ID != ProducerProfileID {
		t.Fatalf("current profile identity %+v / %s", registered, current.ID)
	}
	if status := current.Keys(HeroActor)["is_board"]; status != ProducerActive {
		t.Fatalf("current profile board producer %v", status)
	}
	if status, ok := awakening.Keys(HeroActor)["is_board"]; !ok || status != ProducerDeclaredInactive {
		t.Fatalf("awakening profile board producer %v %v", status, ok)
	}
	board := withParam(withParam(withParam(params, "is_board", 1), "board_card", 2), "board_model_id", 7)
	if awakening.CheckOwned(HeroActor, board) == nil {
		t.Fatal("awakening profile admitted board keys")
	}
	if err := current.CheckOwned(HeroActor, board); err != nil {
		t.Fatal(err)
	}
	if current.CheckOwned(HeroActor, withParam(board, "force", 1)) == nil {
		t.Fatal("display producer activated")
	}
	// ARENA_HERO_PICKS_V1 moves the roster's region_arena_times to its own
	// active producer in the current profile only.
	if status, ok := current.Keys(HeroActor)["region_arena_times"]; !ok || status != ProducerActive {
		t.Fatalf("current profile arena picks producer %v %v", status, ok)
	}
	if err := current.CheckOwned(HeroActor, withParam(params, "region_arena_times", 2)); err != nil {
		t.Fatal("current profile refused arena picks", err)
	}
	for _, profile := range []ProducerProfile{legacy, awakening} {
		if profile.CheckOwned(HeroActor, withParam(params, "region_arena_times", 2)) == nil {
			t.Fatal("pinned profile admitted arena picks", profile.ID)
		}
		if _, ok := profile.Keys(HeroActor)["region_arena_times"]; !ok {
			t.Fatal("pinned profile lost region_arena_times", profile.ID)
		}
		for _, producer := range profile.Producers {
			if producer.ID == "ARENA_PICKS" {
				t.Fatal("pinned profile gained ARENA_PICKS", profile.ID)
			}
		}
	}
	for _, p := range current.Producers {
		if p.ID == "CHAR_RUNE" && p.Status != ProducerDeclaredInactive {
			t.Fatal("Rune activated")
		}
	}
}
