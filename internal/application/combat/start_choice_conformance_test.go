package combat

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"slices"
	"testing"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// The conformance tests below START one registered mode twice for the same
// stage with a different chosen team and assert the rule its registry row
// declares (START_REPLAY_GUARD_V1 ruling 2). The choice reaches the attempt the
// way the mode's builder does: for REPLAYS_FROZEN it stays out of the START
// fingerprint, for SUPERSEDES it enters it.

func TestClosureE8ArenaPlayoffsStartChoiceConformance(t *testing.T) {
	assertStartChoiceRule(t, d.ModeArenaPlayoffs)
}

func TestClosureE8ArenaFriendFightStartChoiceConformance(t *testing.T) {
	assertStartChoiceRule(t, d.ModeArenaFriendFight)
}

func TestClosureE8AwakeningStartChoiceConformance(t *testing.T) {
	assertStartChoiceRule(t, d.ModeAwakeningBlood)
}

func TestClosureE8EventCentreBoardStartChoiceConformance(t *testing.T) {
	assertStartChoiceRule(t, d.ModeEventCentreBoard)
}

func TestClosureE8GodsTrialStartChoiceConformance(t *testing.T) {
	assertStartChoiceRule(t, d.ModeGodsTrial)
}

func TestClosureE8GuildCampaignStartChoiceConformance(t *testing.T) {
	assertStartChoiceRule(t, d.ModeGuildCampaign)
}

func TestClosureE8MarchStartChoiceConformance(t *testing.T) {
	assertStartChoiceRule(t, d.ModeMarch)
}

func TestClosureE8PetCampaignStartChoiceConformance(t *testing.T) {
	assertStartChoiceRule(t, d.ModePetCampaign)
}

func TestClosureE8PetCampaignPracticeStartChoiceConformance(t *testing.T) {
	assertStartChoiceRule(t, d.ModePetCampaignPractice)
}

func assertStartChoiceRule(t *testing.T, key d.ModeKey) {
	t.Helper()
	registration := d.MustMode(key)
	if registration.Trust == d.ServerEntropyClientDerived {
		t.Fatalf("%s refuses a changed choice in its dispatcher; use its native refusal test", key)
	}
	at := kAt
	store := &conformanceStore{snapshots: map[string][]byte{}}
	service := conformanceService(store)
	actor := conformanceActor()
	locator := d.Locator{DomainKind: registration.Family, AuthorityScope: "server:1", DomainLocator: "player:7"}
	first := conformanceRequest(registration, actor, locator, at, 101, conformanceFingerprint(101))
	second := conformanceRequest(registration, actor, locator, at, 102, conformanceFingerprint(102))
	if registration.OnChoiceChange == d.ChoiceReplaysFrozen {
		second.StartFingerprint = first.StartFingerprint
	}
	startedFirst := mustStart(t, service, first)
	startedSecond := mustStart(t, service, second)
	if team := frozenTeam(t, store, startedFirst.Attempt.SnapshotHash); !slices.Equal(team, []int64{101}) {
		t.Fatalf("%s froze team %v, want the first choice", key, team)
	}
	switch registration.OnChoiceChange {
	case d.ChoiceReplaysFrozen:
		if !startedSecond.Replayed || startedSecond.Attempt.ID != startedFirst.Attempt.ID {
			t.Fatalf("%s did not replay the frozen START on a choice change", key)
		}
		if len(store.snapshots) != 1 {
			t.Fatalf("%s froze %d snapshots, want the first only", key, len(store.snapshots))
		}
		if team := frozenTeam(t, store, startedSecond.Attempt.SnapshotHash); !slices.Equal(team, []int64{101}) {
			t.Fatalf("%s served team %v on replay, want the frozen first choice", key, team)
		}
	case d.ChoiceSupersedes:
		if startedSecond.Replayed || startedSecond.Attempt.ID == startedFirst.Attempt.ID {
			t.Fatalf("%s replayed instead of superseding on a choice change", key)
		}
		if startedSecond.Superseded == nil || startedSecond.Superseded.ID != startedFirst.Attempt.ID || startedSecond.Attempt.SupersedesAttemptID != startedFirst.Attempt.ID {
			t.Fatalf("%s did not supersede the open attempt", key)
		}
		if len(store.snapshots) != 2 {
			t.Fatalf("%s froze %d snapshots, want a new one for the successor", key, len(store.snapshots))
		}
		if team := frozenTeam(t, store, startedSecond.Attempt.SnapshotHash); !slices.Equal(team, []int64{102}) {
			t.Fatalf("%s froze team %v for the successor, want the second choice", key, team)
		}
	default:
		t.Fatalf("%s names rule %q without a service-level conformance case", key, registration.OnChoiceChange)
	}
}

func frozenTeam(t *testing.T, store *conformanceStore, hash string) []int64 {
	t.Helper()
	raw, ok := store.snapshots[hash]
	if !ok {
		t.Fatalf("snapshot %s was not stored", hash)
	}
	snapshot, err := d.DecodeSnapshot(raw, hash)
	if err != nil {
		t.Fatalf("decode snapshot %s: %v", hash, err)
	}
	team := make([]int64, 0, len(snapshot.Battle.TeamA))
	for _, actor := range snapshot.Battle.TeamA {
		team = append(team, actor.Identity)
	}
	return team
}

func mustStart(t *testing.T, service Service, request StartRequest) Started {
	t.Helper()
	scope := conformanceScope(t)
	freezer := service.newFreezer(conformanceTransaction, scope, request.Actor.PlayerID)
	started, err := service.start(context.Background(), conformanceTransaction, scope, request, freezer)
	if err != nil {
		t.Fatalf("%s START: %v", request.Mode, err)
	}
	return started
}

// conformanceTransaction is the witnessed transaction start compares with the
// scope's queryer.
var conformanceTransaction = conformanceTx{}

func conformanceScope(t *testing.T) ca.CoherentReadScope {
	t.Helper()
	scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: conformanceTransaction, Operation: kOperation, Attempt: 1, Options: tx.Options{Isolation: tx.RepeatableRead}}, kRevision, kAt)
	if err != nil {
		t.Fatalf("scope: %v", err)
	}
	return scope
}

var (
	kAt               = time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	kRevision         = "d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0"
	kRulesID          = "e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0"
	kArchive          = "f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0"
	kOperation        = operation.Context{ID: ids.UUID{1}, StartedAt: kAt}
	kContextID        = mustContextID()
	kConformanceRules = conformanceRules{}
)

func mustContextID() identity.ContextID {
	contextID, err := identity.ContextIDFrom(ids.UUID{2})
	if err != nil {
		panic(err)
	}
	return contextID
}

func conformanceActor() identity.ActorContext {
	return identity.ActorContext{PlayerID: 7, LogicalServerID: 1, ContextID: kContextID}
}

func conformanceFingerprint(choice int64) string {
	sum := sha256.Sum256([]byte{byte(choice)})
	return hex.EncodeToString(sum[:])
}

func conformanceRequest(registration d.ModeRegistration, actor identity.ActorContext, locator d.Locator, at time.Time, choice int64, fingerprint string) StartRequest {
	battle := BattleRequest{CampaignType: 1, BattleID: 1,
		TeamA:  []Participant{{Origin: d.Template, Kind: d.HeroActor, Identity: choice, TemplateParams: map[string]any{"table_id": choice}}},
		WavesB: [][]Participant{{{Origin: d.Template, Kind: d.HeroActor, Identity: 9001, TemplateParams: map[string]any{"table_id": 9001}}}}}
	if registration.Trust == d.ClientSummaryAttested {
		battle.Formation = []int64{choice}
	}
	if registration.Transform != "" {
		battle.Context = &d.BattleContext{Transform: registration.Transform}
	}
	return StartRequest{Mode: registration.Key, Actor: actor, Locator: locator, GenerationRef: "conformance-stage",
		StartFingerprint: fingerprint, ResultDeadline: at.Add(time.Hour), Battle: battle,
		TrustProfile: registration.Trust, Replay: registration.Replay}
}

func conformanceService(store Store) Service {
	return Service{Rules: kConformanceRules, Keys: conformanceKeys{}, Store: store, Content: conformanceContent{}}
}

type conformanceRules struct{}

func (conformanceRules) ID() string                  { return kRulesID }
func (conformanceRules) SourceArchiveSHA256() string { return kArchive }
func (conformanceRules) FighterClass(table string, id int64) (string, bool, bool) {
	return "warrior", true, true
}
func (conformanceRules) BattleLineup(int64) ([][]int64, []int64, error) { return nil, nil, nil }

type conformanceKeys struct{}

func (conformanceKeys) Current() (string, []byte, error) { return "v1", make([]byte, 32), nil }
func (conformanceKeys) Key(string) ([]byte, error)       { return make([]byte, 32), nil }

type conformanceContent struct{}

func (conformanceContent) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return kRevision, nil
}
func (conformanceContent) SourceArchiveTx(context.Context, tx.Queryer, string) (string, error) {
	return kArchive, nil
}

type conformanceStore struct {
	Store
	open      *d.Attempt
	snapshots map[string][]byte
	attempts  []d.Attempt
	terminal  map[ids.UUID]d.Attempt
}

func (s *conformanceStore) LockLocatorTx(context.Context, tx.Tx, d.Locator) error { return nil }

func (s *conformanceStore) FindUnresolvedTx(context.Context, tx.Queryer, d.Locator) (d.Attempt, bool, error) {
	if s.open == nil {
		return d.Attempt{}, false, nil
	}
	return *s.open, true, nil
}

func (s *conformanceStore) InsertSnapshotTx(_ context.Context, _ tx.Tx, hash string, raw []byte) error {
	s.snapshots[hash] = raw
	return nil
}

func (s *conformanceStore) InsertAttemptTx(_ context.Context, _ tx.Tx, attempt d.Attempt) error {
	current := attempt
	s.open = &current
	s.attempts = append(s.attempts, attempt)
	return nil
}

func (s *conformanceStore) ReadMembersTx(context.Context, tx.Queryer, ids.UUID) ([]int64, error) {
	return nil, nil
}

func (s *conformanceStore) LockAttemptTx(context.Context, tx.Tx, ids.UUID) (d.Attempt, error) {
	if s.open == nil {
		return d.Attempt{}, d.ErrStale
	}
	return *s.open, nil
}

func (s *conformanceStore) SaveAttemptTx(_ context.Context, _ tx.Tx, attempt d.Attempt, _ int64) error {
	if s.terminal == nil {
		s.terminal = map[ids.UUID]d.Attempt{}
	}
	s.terminal[attempt.ID] = attempt
	return nil
}

func (s *conformanceStore) ReadStartPackageTx(context.Context, tx.Queryer, ids.UUID) (d.StartPackage, bool, error) {
	return d.StartPackage{}, false, nil
}

type conformanceTx struct{}

func (conformanceTx) QueryRow(context.Context, string, ...any) tx.Row { return conformanceRow{} }
func (conformanceTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return nil, nil
}
func (conformanceTx) Commit(context.Context) error   { return nil }
func (conformanceTx) Rollback(context.Context) error { return nil }

type conformanceRow struct{}

func (conformanceRow) Scan(...any) error { return nil }
