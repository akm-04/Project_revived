package i5

import (
	"context"
	"errors"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type firstClearReader struct {
	reached bool
	err     error
	calls   int
}

func (r *firstClearReader) CampaignFirstClearCommittedTx(context.Context, tx.Queryer, identity.PlayerID, int64) (bool, error) {
	r.calls++
	return r.reached, r.err
}

func TestSkillFunctionWaitsForTheCampaignMilestone(t *testing.T) {
	policy := FunctionGatePolicy{Revision: "rev", Gates: []FunctionGate{
		{FunctionID: 33, GateKind: "PURE_LEVEL", RequiredLevel: 7, RawOpenValue: "1|7", SourceFactKey: "function:33", AnnouncementCapability: "CAMPAIGN_FIRST_CLEAR:100007"},
	}}
	now := time.Unix(100, 0).UTC()
	eligible, err := pureLevelEligibility(policy, 125001, 7, now)
	if err != nil {
		t.Fatal(err)
	}
	service := Service{}
	without, err := service.filterMilestoneEligibilityTx(context.Background(), nil, 125001, policy, eligible, nil)
	if err != nil || len(without) != 0 {
		t.Fatalf("level 7 before the clear = %+v %v", without, err)
	}
	withClear, err := service.filterMilestoneEligibilityTx(context.Background(), nil, 125001, policy, eligible, []int64{100007})
	if err != nil || len(withClear) != 1 || !withClear[0].MilestoneSatisfied {
		t.Fatalf("committed clear = %+v %v", withClear, err)
	}
	reader := &firstClearReader{reached: true}
	service.CampaignClears = reader
	durable, err := service.filterMilestoneEligibilityTx(context.Background(), nil, 125001, policy, eligible, nil)
	if err != nil || reader.calls != 1 || len(durable) != 1 || !durable[0].MilestoneSatisfied {
		t.Fatalf("durable clear = %+v %v calls=%d", durable, err, reader.calls)
	}
	announced, err := LevelFunctionAnnouncements{}.Announce(context.Background(), 125001, policy, eligible)
	if err != nil || len(announced) != 0 {
		t.Fatalf("unproved milestone announced %v %v", announced, err)
	}
	announced, err = LevelFunctionAnnouncements{}.Announce(context.Background(), 125001, policy, withClear)
	if err != nil || !reflect.DeepEqual(announced, []int64{33}) {
		t.Fatalf("proved milestone announced %v %v", announced, err)
	}
	service.CampaignClears = &firstClearReader{err: errors.New("read failed")}
	if _, err := service.filterMilestoneEligibilityTx(context.Background(), nil, 125001, policy, eligible, nil); err == nil {
		t.Fatal("milestone read failure was swallowed")
	}
}

func TestLevelFunctionAnnouncementsAndBirthOpenings(t *testing.T) {
	policy := FunctionGatePolicy{Revision: "rev", Gates: []FunctionGate{
		{FunctionID: 1, GateKind: "PURE_LEVEL", RequiredLevel: 1, RawOpenValue: "1|1", SourceFactKey: "function:1", AnnouncementCapability: "NONE"},
		{FunctionID: 7, GateKind: "PURE_LEVEL", RequiredLevel: 25, RawOpenValue: "1|25", SourceFactKey: "function:7", AnnouncementCapability: "NONE"},
		{FunctionID: 38, GateKind: "PURE_LEVEL", RequiredLevel: 40, RawOpenValue: "1|40", SourceFactKey: "function:38", AnnouncementCapability: "PET_STARTER_CA3"},
		{FunctionID: 71, GateKind: "UNSUPPORTED_COMPOSITE", RawOpenValue: "2|100018", SourceFactKey: "function:71", AnnouncementCapability: "NONE"},
	}}
	now := time.Unix(100, 0).UTC()
	eligible, err := pureLevelEligibility(policy, 125001, 40, now)
	if err != nil {
		t.Fatal(err)
	}
	announced, err := LevelFunctionAnnouncements{}.Announce(context.Background(), 125001, policy, eligible)
	if err != nil || !reflect.DeepEqual(announced, []int64{1, 7, 38}) {
		t.Fatalf("level 40 announcements %v %v", announced, err)
	}
	born, unlocks, err := LevelFunctionOpenings(policy, 125001, 1, now)
	if err != nil || len(born) != 1 || !reflect.DeepEqual(unlocks, []player.FunctionUnlock{{PlayerID: 125001, FunctionID: 1, OpenedAt: now, SourceFactKey: born[0].SourceFactKey, StateVersion: 1}}) {
		t.Fatalf("birth openings %+v %+v %v", born, unlocks, err)
	}
	reached, unlocks, err := LevelFunctionOpenings(policy, 125001, 40, now)
	if err != nil || len(reached) != 2 || len(unlocks) != 2 || unlocks[0].FunctionID != 1 || unlocks[1].FunctionID != 7 {
		t.Fatalf("level 40 openings must leave the granting Pet Function 38 to its level-up: %+v %+v %v", reached, unlocks, err)
	}
}
