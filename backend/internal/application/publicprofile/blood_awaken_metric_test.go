package publicprofile

import (
	"context"
	"testing"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type awakeningsByPartner map[int64]character.RawAwakeningBirth

func (a awakeningsByPartner) ListRawAwakeningsTx(_ context.Context, _ tx.Queryer, _ identity.PlayerID, _ []int64) (map[int64]character.RawAwakeningBirth, error) {
	return a, nil
}

func rawBirth(t *testing.T, player, partner, stage int64) character.RawAwakeningBirth {
	t.Helper()
	at := time.Unix(100, 0).UTC()
	birth := character.RawAwakeningBirth{
		Ref:                     character.HeroRef{PlayerID: identity.PlayerID(player), PartnerID: partner},
		Version:                 2,
		RawStage:                stage,
		BirthPolicy:             character.RawAwakeningBirthPolicy,
		ProducerReference:       "I9_AWAKENING_MISSIONS_V1/1/1/00000000-0000-0000-0000-000000000001",
		CreationContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
		BirthAt:                 at,
		CreatedAt:               at,
		UpdatedAt:               at,
	}
	if e := birth.Validate(); e != nil {
		t.Fatal(e)
	}
	return birth
}

func bloodAwakenFixture(t *testing.T, partners []int64, births map[int64]character.RawAwakeningBirth) (tx.Scope, MetricRequest, CanonicalMetricProvider) {
	t.Helper()
	sc, r, _ := metricFixture()
	rows := make([]ca.RosterMetricRow, 0, len(partners))
	for _, partner := range partners {
		rows = append(rows, ca.RosterMetricRow{InstanceID: partner, OriginTableID: partner, TableID: partner, Star: 3, Version: 1})
	}
	roster := &rosterOwner{calls: map[string]int{}, populations: map[string]ca.RosterMetricPopulation{"Hero": {PlayerID: r.PlayerID, Family: "Hero", Revision: r.ContentRevision, ObservedAt: r.ObservedAt, RootVersion: 7, Rows: rows}}}
	return sc, r, CanonicalMetricProvider{Roster: roster, Awakenings: awakeningsByPartner(births)}
}

func TestI912BloodAwakenMetricCountsOnlyCompleteStages(t *testing.T) {
	births := map[int64]character.RawAwakeningBirth{
		1: rawBirth(t, 1, 1, 3),
		2: rawBirth(t, 1, 2, 3),
		3: rawBirth(t, 1, 3, 2),
	}
	sc, r, provider := bloodAwakenFixture(t, []int64{1, 2, 3, 4}, births)
	m, e := provider.ReadBloodAwakenMetricScopeTx(context.Background(), sc, r)
	if e != nil || m.Value != 2 || m.FieldID != BloodAwakenMetricFieldID || m.Owner != "CharacterHero" || m.PrivatePolicy != BloodAwakenMetricPolicy || m.Semantics != BloodAwakenMetricSemantics || m.SourceVersion != 7 || m.PopulationVersion != 7 {
		t.Fatal(m, e)
	}
	if !validRosterDigest(m.PopulationDigest) {
		t.Fatal("missing population witness", m)
	}

	empty, e := (CanonicalMetricProvider{Roster: provider.Roster}).ReadBloodAwakenMetricScopeTx(context.Background(), sc, r)
	if e == nil || empty.Value != 0 {
		t.Fatal("missing reader accepted", empty, e)
	}
	sc.Operation.Policies, _ = policy.NewSet()
	if _, e = provider.ReadBloodAwakenMetricScopeTx(context.Background(), sc, r); e == nil {
		t.Fatal("unpinned content accepted")
	}
}
