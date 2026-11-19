package campaign

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"os"
	"testing"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	appcombat "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/summon"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type awardStore struct {
	Store
	saved []d.Record
}

func (s *awardStore) SaveTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, r d.Record, _ []int64, _ time.Time) error {
	s.saved = append(s.saved, r)
	return nil
}

type awardGrants struct {
	result i5.GrantResult
	plans  []grant.Plan
}

func (g *awardGrants) SettleGrantTx(_ context.Context, _ tx.Tx, _ identity.ActorContext, plan grant.Plan, _ operation.Context, _ i5.GrantTxOptions) (i5.GrantResult, error) {
	g.plans = append(g.plans, plan)
	return g.result, nil
}

type awardContent struct {
	Content
	campaign d.Catalog
	summon   summon.Catalog
}

func (c awardContent) CampaignCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error) {
	return c.campaign, nil
}

func (c awardContent) SummonCatalogTx(context.Context, tx.Queryer, string) (summon.Catalog, error) {
	return c.summon, nil
}

type ownedStoryHeroes struct{}

func (ownedStoryHeroes) LockStoryRosterTx(context.Context, tx.Tx, identity.PlayerID) error {
	return nil
}

func (ownedStoryHeroes) AwardStoryPartnerTx(context.Context, tx.Tx, identity.PlayerID, int64, string, operation.Context) (character.Hero, *character.CollectionAdmissionProof, error) {
	return character.Hero{}, nil, nil
}

type storyCombat struct{}

func (storyCombat) StartTx(context.Context, tx.Tx, ca.CoherentReadScope, appcombat.StartRequest) (appcombat.Started, error) {
	return appcombat.Started{}, nil
}

func (storyCombat) AttestSummaryTx(context.Context, tx.Tx, appcombat.SummaryRequest) (appcombat.SummaryAttested, error) {
	return appcombat.SummaryAttested{}, nil
}

func (storyCombat) BorrowedTx(context.Context, tx.Tx, cd.Locator) (bool, error) { return false, nil }

func (storyCombat) LiveGenerationTx(context.Context, tx.Tx, cd.Locator, identity.PlayerID, string, time.Time) (bool, error) {
	return true, nil
}

func awardScope(t *testing.T) gen.TimedScope {
	t.Helper()
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: "test-revision"})
	if err != nil {
		t.Fatal(err)
	}
	op := operation.Context{ID: id, StartedAt: time.Unix(1700000000, 0).UTC(), EntropySeed: [32]byte{1}, Policies: policies}
	timed, err := gen.NewTimedOperation(op, op.StartedAt)
	if err != nil {
		t.Fatal(err)
	}
	return gen.TimedScope{Operation: timed}
}

func builtinSummonCatalog(t *testing.T) summon.Catalog {
	t.Helper()
	raw, err := os.ReadFile("../../content/builtin/generated/summon_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	var catalog summon.Catalog
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.DisallowUnknownFields()
	if err = decoder.Decode(&catalog); err != nil {
		t.Fatal(err)
	}
	if err = catalog.Validate(); err != nil {
		t.Fatal(err)
	}
	return catalog
}

func clearedChapterOne() d.Progress {
	return d.Progress{Nodes: map[int64]d.NodeState{
		100018: {CampaignID: 100018, Star: 3},
		100024: {CampaignID: 100024, Star: 3},
	}}
}

func TestChapterAwardRefusesFullyMailedGift(t *testing.T) {
	catalog := builtinCatalog(t)
	store, grants := &awardStore{}, &awardGrants{}
	mode := Mode{Store: store, Grants: grants, Content: awardContent{campaign: catalog}}
	body, err := mode.chapterAward(context.Background(), awardScope(t), identity.ActorContext{PlayerID: 7}, view{catalog: catalog, revision: "rev"}, d.Record{Progress: clearedChapterOne()}, 1)
	if !errors.Is(err, d.ErrRefused) {
		t.Fatalf("fully mailed chapter gift: body=%v err=%v", body, err)
	}
	if len(store.saved) != 0 {
		t.Fatalf("refused claim saved progress: %+v", store.saved)
	}
	if len(grants.plans) != 1 {
		t.Fatalf("grant attempted %d times, want one", len(grants.plans))
	}
}

func TestChapterAwardKeepsFittingRows(t *testing.T) {
	catalog := builtinCatalog(t)
	store := &awardStore{}
	grants := &awardGrants{result: i5.GrantResult{Awards: []i5.Award{{TableID: 50001024, ItemNum: 1}}}}
	mode := Mode{Store: store, Grants: grants, Content: awardContent{campaign: catalog}}
	body, err := mode.chapterAward(context.Background(), awardScope(t), identity.ActorContext{PlayerID: 7}, view{catalog: catalog, revision: "rev"}, d.Record{Progress: clearedChapterOne()}, 1)
	if err != nil {
		t.Fatal(err)
	}
	rows, ok := body["awards"].([]any)
	if !ok || len(rows) != 1 || rows[0].(map[string]any)["item_num"] != int64(1) {
		t.Fatalf("awards = %v", body["awards"])
	}
	if len(store.saved) != 1 {
		t.Fatalf("fitting claim saved %d rows", len(store.saved))
	}
}

func TestChapterAwardWithoutItemsStaysSuccessful(t *testing.T) {
	catalog := d.Catalog{
		Chapters:     []d.Chapter{{ID: 1, EventType: 1, EventCondition: []int64{1}, EventGift: []int64{90085001}, EventOpenTimes: 1}},
		ChapterGifts: []d.ChapterGift{{ID: 90085001}},
	}
	progress := d.Progress{Nodes: map[int64]d.NodeState{1: {CampaignID: 1, Star: 3}}}
	store, grants := &awardStore{}, &awardGrants{}
	mode := Mode{Store: store, Grants: grants, Content: awardContent{campaign: catalog}}
	body, err := mode.chapterAward(context.Background(), awardScope(t), identity.ActorContext{PlayerID: 7}, view{catalog: catalog, revision: "rev"}, d.Record{Progress: progress}, 1)
	if err != nil {
		t.Fatal(err)
	}
	if rows, ok := body["awards"].([]any); !ok || len(rows) != 0 {
		t.Fatalf("item-less gift awards = %v", body["awards"])
	}
	if len(store.saved) != 1 {
		t.Fatalf("item-less gift saved %d rows", len(store.saved))
	}
}

func TestStoryAwardOwnedPartnerConvertsToStone(t *testing.T) {
	campaignCatalog := builtinCatalog(t)
	store, grants := &awardStore{}, &awardGrants{}
	mode := Mode{Store: store, Grants: grants, Content: awardContent{campaign: campaignCatalog, summon: builtinSummonCatalog(t)},
		StoryHeroes: ownedStoryHeroes{}, StoryWire: func(character.Hero) (map[string]any, error) { return map[string]any{"table_id": 1}, nil }, Combat: storyCombat{}}
	actor := identity.ActorContext{PlayerID: 7, LogicalServerID: 1}
	v := view{catalog: campaignCatalog, revision: "rev"}
	record := d.Record{Progress: d.Progress{Nodes: map[int64]d.NodeState{}}, PendingGeneration: "1/200002"}
	choice := StoryChoice{CampaignID: 200002, Type: d.Normal, Partner: 10001008}
	sc := awardScope(t)
	body, err := mode.storyAward(context.Background(), sc, actor, v, record, choice)
	if err != nil {
		t.Fatal(err)
	}
	rows, ok := body["story_drop_awards"].([]any)
	if !ok || len(rows) != 1 {
		t.Fatalf("story_drop_awards = %v", body["story_drop_awards"])
	}
	row := rows[0].(map[string]any)
	if row["table_id"] != int64(40001008) || row["item_num"] != int64(7) || row["to_stone"] != true {
		t.Fatalf("owned partner row = %v", row)
	}
	if _, partner := row["is_partner"]; partner {
		t.Fatalf("owned partner still claims is_partner: %v", row)
	}
	if len(grants.plans) != 1 || len(grants.plans[0].Lines) != 1 || grants.plans[0].Lines[0].ItemID != 40001008 || grants.plans[0].Lines[0].Amount != 7 {
		t.Fatalf("stone grant = %+v", grants.plans)
	}
	if len(store.saved) != 1 {
		t.Fatalf("claim saved %d rows", len(store.saved))
	}
	again, err := mode.storyAward(context.Background(), sc, actor, v, store.saved[0], choice)
	if err != nil {
		t.Fatal(err)
	}
	first, _ := json.Marshal(body)
	replay, _ := json.Marshal(again)
	if string(first) != string(replay) {
		t.Fatalf("replay body %s, want %s", replay, first)
	}
	if len(grants.plans) != 1 || len(store.saved) != 1 {
		t.Fatalf("replay granted again: plans=%d saved=%d", len(grants.plans), len(store.saved))
	}
}
