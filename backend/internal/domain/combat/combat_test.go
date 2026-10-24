package combat

import (
	"bytes"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"fmt"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/ids"
)

var fixtureAttempt, _ = ids.ParseUUID("6f3c2c1e-8a0b-4f53-9d3e-2b7a4c1d9e01")

func fixtureRoot(t *testing.T) [32]byte {
	key := sha256.Sum256([]byte("combat-domain-test-key"))
	root, err := EntropyRoot(key[:], fixtureAttempt, fmt.Sprintf("%064x", 7))
	if err != nil {
		t.Fatal(err)
	}
	return root
}

// Pinned vectors: any change to the inherited 418 mapping changes these.
func TestEntropyVectors(t *testing.T) {
	s := NewStream(fixtureRoot(t))
	f := s.Float()
	n := s.Uniform(6) + 1
	b, err := s.Between(-3, 3)
	if err != nil {
		t.Fatal(err)
	}
	if err = s.Reseed(1700000000); err != nil {
		t.Fatal(err)
	}
	after := s.Float()
	got := fmt.Sprintf("%.17g|%d|%d|%.17g|%d|%d", f, n, b, after, s.Draws, s.Reseeds)
	if got != entropyGolden {
		t.Fatalf("entropy vector drift: %s", got)
	}
	again := NewStream(fixtureRoot(t))
	if again.Float() != f {
		t.Fatal("same root must replay")
	}
}

const entropyGolden = "0.30651544107171425|4|0|0.63806132432449014|4|1"

func TestEntropyRejectsInexactRanges(t *testing.T) {
	s := NewStream(fixtureRoot(t))
	for _, bad := range [][2]float64{{2, 1}, {0.5, 3}, {0, MaxExactInteger + 1}} {
		if _, err := s.Between(bad[0], bad[1]); !errors.Is(err, ErrRandomRange) {
			t.Fatal(bad)
		}
	}
	for i := 0; i < 2000; i++ {
		if v := s.Uniform(3); v > 2 {
			t.Fatal(v)
		}
	}
	if _, err := EntropyRoot([]byte("short"), fixtureAttempt, fmt.Sprintf("%064x", 7)); !errors.Is(err, ErrKeyUnavailable) {
		t.Fatal("short key accepted")
	}
}

func fixtureActor(origin Origin, player int64) Actor {
	fields := map[string]any{"player_id": player, "partner_id": 3, "table_id": 10001001, "star": 1}
	if origin != Template && origin != Trial {
		for _, key := range []string{"fumos", "skin_ids", "skill_book_info", "inscript_items", "courses", "spirit_equip", "spirit_item", "element_equips"} {
			fields[key] = []any{}
		}
		for _, key := range []string{"favor_degree", "house_id", "evo_stage", "twice_awake_stage"} {
			fields[key] = 0
		}
	}
	params, _ := CanonicalJSON(fields)
	a := Actor{Origin: origin, Kind: HeroActor, Player: player, Identity: 3, TableID: 10001001, FighterClass: "Lvmeng", Params: params}
	if origin != Template && origin != Trial {
		a.OwnerStateVersion = 1
		a.BattleTotals = json.RawMessage(`{"hp":1}`)
	}
	return a
}

func withParam(params json.RawMessage, key string, value any) json.RawMessage {
	var fields map[string]any
	_ = json.Unmarshal(params, &fields)
	fields[key] = value
	out, _ := CanonicalJSON(fields)
	return out
}

func withoutParam(params json.RawMessage, key string) json.RawMessage {
	var fields map[string]any
	_ = json.Unmarshal(params, &fields)
	delete(fields, key)
	out, _ := CanonicalJSON(fields)
	return out
}

func fixtureSnapshot() Snapshot {
	return Snapshot{Schema: SnapshotSchema, ProducerProfile: ProducerProfileID, Contract: ContractID, ContentRevision: fmt.Sprintf("%064x", 1), CorpusID: fmt.Sprintf("%064x", 2), SourceArchiveSHA256: fmt.Sprintf("%064x", 3),
		TrustProfile: TrustProfileID, EntropyPolicy: EntropyPolicyVersion, AdapterPolicy: AdapterPolicyVersion, CollectionPolicy: CollectionPolicy, DecidedAt: time.Unix(1700000000, 0).UTC(),
		Battle:  Battle{CampaignType: 1, TeamA: []Actor{fixtureActor(OwnedSelf, 9)}, WavesB: [][]Actor{{fixtureActor(Template, 0)}}},
		Players: []PlayerContext{{Player: 9, StateVersions: map[string]int64{"hero_root": 1}, CollectionHundredths: map[string]int64{}, ExclusiveBooks: map[string]int64{}}}}
}

func TestSnapshotCanonicalRoundTripAndNegatives(t *testing.T) {
	s := fixtureSnapshot()
	raw, hash, err := s.Canonical()
	if err != nil {
		t.Fatal(err)
	}
	back, err := DecodeSnapshot(raw, hash)
	if err != nil {
		t.Fatal(err)
	}
	raw2, _, _ := back.Canonical()
	if !bytes.Equal(raw, raw2) {
		t.Fatal("canonical drift")
	}
	if _, err = DecodeSnapshot(raw, fmt.Sprintf("%064x", 0)); !errors.Is(err, ErrIntegrity) {
		t.Fatal("hash mismatch accepted")
	}
	contexts := map[string]func(*Snapshot){
		"legacy schema 1": func(s *Snapshot) { s.Schema, s.ProducerProfile = LegacySnapshotSchema, "" },
		"transform with parameters": func(s *Snapshot) {
			s.Battle.Context = &BattleContext{Transform: "REGION_ARENA_SEASON_AWARDS_V1", Parameters: json.RawMessage(`{"a":1}`)}
			s.Battle.WavesB[0][0].Transform = json.RawMessage(`{"arena_add_star":2}`)
		},
	}
	for name, mutate := range contexts {
		m := fixtureSnapshot()
		mutate(&m)
		raw, hash, err := m.Canonical()
		if err != nil {
			t.Fatal(name, err)
		}
		if back, err := DecodeSnapshot(raw, hash); err != nil || back.Schema != m.Schema {
			t.Fatal(name, "round trip", err)
		}
	}
	mutations := []func(*Snapshot){
		func(s *Snapshot) { s.Battle.TeamA[0].Params = json.RawMessage(`{"table_id":10001001, "player_id":9}`) },
		func(s *Snapshot) { s.Battle.TeamA[0].Player = 10 },
		func(s *Snapshot) { s.Battle.WavesB[0][0].Player = 9 },
		func(s *Snapshot) { s.Battle.TeamA[0].BattleTotals = nil },
		func(s *Snapshot) { s.Players[0].ExclusiveBooks = map[string]int64{"50000026": 1} },
		func(s *Snapshot) {
			s.Players = append(s.Players, PlayerContext{Player: 11, StateVersions: map[string]int64{"x": 1}, CollectionHundredths: map[string]int64{}, ExclusiveBooks: map[string]int64{}})
		},
		func(s *Snapshot) { s.Battle.WavesB = nil },
		func(s *Snapshot) { s.DecidedAt = s.DecidedAt.In(time.FixedZone("x", 3600)) },
		func(s *Snapshot) { s.Schema = SnapshotSchema + 1 },
		func(s *Snapshot) { s.Battle.TeamA[0].Transform = json.RawMessage(`{"arena_add_star":1}`) },
		func(s *Snapshot) { s.Battle.Context = &BattleContext{Transform: "region_arena_v1"} },
		func(s *Snapshot) { s.Battle.Context = &BattleContext{Transform: "REGION_ARENA"} },
		func(s *Snapshot) {
			s.Battle.Context = &BattleContext{Transform: "REGION_ARENA_V1", Parameters: json.RawMessage(`{"b":1, "a":2}`)}
		},
		func(s *Snapshot) {
			s.Battle.Context = &BattleContext{Transform: "REGION_ARENA_V1"}
			s.Battle.TeamA[0].Transform = json.RawMessage(`[1]`)
		},
		func(s *Snapshot) {
			s.Schema, s.ProducerProfile = LegacySnapshotSchema, ""
			s.Battle.Context = &BattleContext{Transform: "REGION_ARENA_V1"}
		},
		func(s *Snapshot) { s.ProducerProfile = "" },
		func(s *Snapshot) { s.ProducerProfile = "I8_BATTLE_PRODUCERS_V0" },
		func(s *Snapshot) { s.Schema = LegacySnapshotSchema },
		func(s *Snapshot) { s.Battle.TeamA[0].Params = withParam(s.Battle.TeamA[0].Params, "buffs", []any{}) },
		func(s *Snapshot) { s.Battle.TeamA[0].Params = withParam(s.Battle.TeamA[0].Params, "is_board", 1) },
		func(s *Snapshot) {
			s.Battle.TeamA[0].Params = withParam(s.Battle.TeamA[0].Params, "rune_items", []any{})
		},
		func(s *Snapshot) {
			s.Battle.TeamA[0].Params = withParam(s.Battle.TeamA[0].Params, "twice_awake_stage", 1)
		},
		func(s *Snapshot) { s.Battle.TeamA[0].Params = withoutParam(s.Battle.TeamA[0].Params, "favor_degree") },
	}
	for i, mutate := range mutations {
		m := fixtureSnapshot()
		mutate(&m)
		if m.Validate() == nil {
			t.Fatal("mutation accepted", i)
		}
	}
}

func fixtureAttemptEnvelope(start time.Time) Attempt {
	return Attempt{ID: fixtureAttempt, Locator: Locator{"fixture", "server/1", "slot"}, ActorPlayer: 9, GameplayContextID: "ctx", GenerationRef: "g1", StartFingerprint: fmt.Sprintf("%064x", 4), SnapshotHash: fmt.Sprintf("%064x", 5),
		TrustProfile: ServerReport, Replay: ReplaySpec{Response: ReplayStoredReport},
		EntropyKeyVersion: "k1", RulesCorpusID: fmt.Sprintf("%064x", 6), ResolverStatus: ResolverPending, State: Staged, StartedAt: start, ResultDeadline: start.Add(time.Minute), StateVersion: 1}
}

func TestAttemptLifecycle(t *testing.T) {
	start := time.Unix(1700000000, 0).UTC()
	a := fixtureAttemptEnvelope(start)
	if err := a.Validate(); err != nil {
		t.Fatal(err)
	}
	if _, err := a.Terminate("WIN", "receipt", start); err == nil {
		t.Fatal("terminal before resolution")
	}
	failed, err := a.FailResolution(false, "TIMEOUT")
	if err != nil || !failed.Runnable() {
		t.Fatal("retryable failure must stay runnable")
	}
	ready, err := failed.Resolve(fmt.Sprintf("%064x", 8))
	if err != nil || ready.State != ResolutionReady || ready.StateVersion != 3 {
		t.Fatal(err)
	}
	if _, err = ready.Resolve(fmt.Sprintf("%064x", 9)); err == nil {
		t.Fatal("second resolution accepted")
	}
	done, err := ready.Terminate("WIN", "receipt", start)
	if err != nil || done.Unresolved() {
		t.Fatal(err)
	}
	if _, err = done.Terminate("WIN", "receipt", start); err == nil {
		t.Fatal("second terminal accepted")
	}
	permanent, _ := a.FailResolution(true, "SCRIPT")
	if permanent.Runnable() {
		t.Fatal("permanent failure runnable")
	}
	if _, err = a.Close("EXPIRED", "close", start); err == nil {
		t.Fatal("pending attempt closed before its deadline")
	}
	closed, err := permanent.Close("RESOLVER_FAILED", "close", start)
	if err != nil || closed.Unresolved() || closed.ResolutionHash != "" {
		t.Fatal("permanent failure must be closable without resolution", err)
	}
	expired, err := ready.Close("EXPIRED", "close", a.ResultDeadline)
	if err != nil || expired.ResolutionHash == "" {
		t.Fatal("expired ready attempt keeps its resolution", err)
	}
	if _, err = ready.Close("EXPIRED", "close", start); err == nil {
		t.Fatal("ready attempt closed before its deadline")
	}
}
