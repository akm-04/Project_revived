package i5

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type missionMemory struct {
	root        objective.MissionRoot
	rows        map[string]objective.Instance
	definitions []objective.MissionDefinition
	value       int64
	gate        bool
	heroes      []int64
	inserts     int
}

func (m *missionMemory) LockMissionRootTx(_ context.Context, _ tx.Tx, player identity.PlayerID, at time.Time) (objective.MissionRoot, error) {
	if m.root.StateVersion == 0 {
		var err error
		m.root, err = objective.NewMissionRoot(player, at)
		return m.root, err
	}
	return m.root, nil
}
func (m *missionMemory) ReadMissionRootTx(context.Context, tx.Queryer, identity.PlayerID) (objective.MissionRoot, error) {
	return m.root, nil
}
func (m *missionMemory) SaveMissionRootTx(_ context.Context, _ tx.Tx, root objective.MissionRoot, old int64) error {
	if m.root.StateVersion != old {
		return errors.New("stale test root")
	}
	m.root = root
	return nil
}
func (m *missionMemory) DeletePreviousDailyMissionsTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, generation string) error {
	for key, row := range m.rows {
		if row.ProgramID == "mission:1" && row.GenerationID != generation {
			delete(m.rows, key)
		}
	}
	return nil
}
func (m *missionMemory) InsertMissionInstanceTx(_ context.Context, _ tx.Tx, row objective.Instance) error {
	key := missionOccurrence(row.ObjectiveID, row.GenerationID)
	if _, exists := m.rows[key]; exists {
		return errors.New("duplicate test mission")
	}
	m.rows[key] = row
	m.inserts++
	return nil
}
func (m *missionMemory) ListMissionInstancesTx(context.Context, tx.Queryer, identity.PlayerID) ([]objective.Instance, error) {
	rows := make([]objective.Instance, 0, len(m.rows))
	for _, row := range m.rows {
		rows = append(rows, row)
	}
	return rows, nil
}
func (m *missionMemory) SaveObjectiveTx(_ context.Context, _ tx.Tx, row objective.Instance, old int64) error {
	key := missionOccurrence(row.ObjectiveID, row.GenerationID)
	if m.rows[key].StateVersion != old {
		return errors.New("stale test mission")
	}
	m.rows[key] = row
	return nil
}
func (m *missionMemory) MissionDefinitionsTx(context.Context, tx.Queryer, string) ([]objective.MissionDefinition, error) {
	return m.definitions, nil
}
func (m *missionMemory) MissionPartnerTemplatesTx(context.Context, tx.Queryer, MissionScope) ([]int64, error) {
	return m.heroes, nil
}
func (m *missionMemory) ObserveMissionTx(context.Context, tx.Queryer, MissionScope, objective.MissionDefinition, int64) (MissionObservation, error) {
	return MissionObservation{GatePassed: m.gate, Value: m.value}, nil
}

func testMission(family objective.StockFamily, id int64) objective.MissionDefinition {
	generation, program := "LIFETIME", "mission:2"
	if family == objective.Daily {
		generation, program = "DAY", "mission:1"
	}
	if family == objective.Partner {
		generation, program = "HERO", "mission:6"
	}
	plan := grant.Plan{Source: grant.SourceIdentity{PolicyVersion: "I9_MISSIONS_V1"}}
	return objective.MissionDefinition{ProgramID: program, Family: family, ObjectiveID: id, DefinitionRevision: "I9_MISSIONS_V1", Strategy: "HIGH_WATER", AcceptedFactKind: "PLAYER_LEVEL", Target: 7, GenerationKind: generation,
		Prerequisite: objective.MissionPrerequisite{Gate: []int64{0}}, Reward: plan, Presentation: objective.MissionPresentation{Condition: 16, Parameters: []int64{7}, BaseReward: plan}}
}

func TestMissionMaterializationHighWaterChainAndDailyReset(t *testing.T) {
	ctx := context.Background()
	at := time.Date(2026, 10, 25, 20, 59, 59, 0, time.UTC)
	scope := MissionScope{PlayerID: 100001, ContentRevision: strings.Repeat("a", 64), DecisionAt: at}
	first, second := testMission(objective.GrowMain, 1), testMission(objective.GrowMain, 2)
	first.Presentation.Next, second.Prerequisite.Previous = 2, 1
	memory := &missionMemory{rows: map[string]objective.Instance{}, definitions: []objective.MissionDefinition{testMission(objective.Daily, 10), first, second}, gate: true, value: 7}
	materializer := MissionMaterializer{Store: memory, Catalog: memory, Observations: memory}
	view, err := materializer.MaterializeTx(ctx, &testTx{}, scope)
	if err != nil || len(view.Instances) != 2 || memory.inserts != 2 {
		t.Fatalf("first view %+v, %v", view, err)
	}
	for _, row := range view.Instances {
		if row.CompletedAt == nil {
			t.Fatal("high-water row not complete at creation")
		}
	}
	if _, err := materializer.MaterializeTx(ctx, &testTx{}, scope); err != nil || memory.inserts != 2 {
		t.Fatalf("repeated read materialized duplicates: %v", err)
	}
	key := missionOccurrence(1, "lifetime")
	claimed, err := objective.Claim(memory.rows[key], at)
	if err != nil {
		t.Fatal(err)
	}
	memory.rows[key] = claimed
	view, err = materializer.MaterializeTx(ctx, &testTx{}, scope)
	if err != nil || len(view.Instances) != 3 || memory.rows[missionOccurrence(2, "lifetime")].CompletedAt == nil {
		t.Fatalf("chain next not materialized complete: %+v %v", view, err)
	}
	memory.root.DayHuoyue = 30
	scope.DecisionAt = at.Add(time.Second)
	view, err = materializer.MaterializeTx(ctx, &testTx{}, scope)
	if err != nil || view.Root.DayHuoyue != 0 || len(view.Instances) != 3 || memory.inserts != 4 {
		t.Fatalf("rollover %+v inserts %d: %v", view, memory.inserts, err)
	}
}

func TestMissionMaterializationHonoursGateAndPartnerIdentity(t *testing.T) {
	ctx := context.Background()
	scope := MissionScope{PlayerID: 100001, ContentRevision: strings.Repeat("a", 64), DecisionAt: time.Unix(1000, 0)}
	memory := &missionMemory{rows: map[string]objective.Instance{}, definitions: []objective.MissionDefinition{testMission(objective.Partner, 1)}, heroes: []int64{11, 10, 11}, value: 7}
	materializer := MissionMaterializer{Store: memory, Catalog: memory, Observations: memory}
	view, err := materializer.MaterializeTx(ctx, &testTx{}, scope)
	if err != nil || len(view.Instances) != 0 {
		t.Fatalf("closed gate materialized: %+v %v", view, err)
	}
	memory.gate = true
	view, err = materializer.MaterializeTx(ctx, &testTx{}, scope)
	if err != nil || len(view.Instances) != 2 || view.Instances[0].GenerationID == view.Instances[1].GenerationID {
		t.Fatalf("partner identities %+v %v", view, err)
	}
}
