package occult

import (
	"encoding/json"
	"errors"
	"fmt"
	"testing"
)

func teamState(t *testing.T) RunState {
	t.Helper()
	catalog := generatedCatalog(t)
	state := NewRun(2, MultiCampaignType)
	if err := state.BindRoom(catalog); err != nil {
		t.Fatal(err)
	}
	return state
}

func firstFightCampaign(t *testing.T, state RunState) int64 {
	t.Helper()
	for key, stages := range state.Stages {
		if len(stages) > 0 {
			var id int64
			if _, err := fmt.Sscan(key, &id); err != nil {
				t.Fatal(err)
			}
			return id
		}
	}
	t.Fatal("no fight campaign")
	return 0
}

func TestTeamFightWindowsAndRestart(t *testing.T) {
	state := teamState(t)
	campaign := firstFightCampaign(t, state)
	opened, err := state.OpenTeamFight(campaign, 0, 1, 1000)
	if err != nil || !opened {
		t.Fatalf("opened=%v err=%v", opened, err)
	}
	if again, err := state.OpenTeamFight(campaign, 0, 1, 1001); err != nil || again {
		t.Fatalf("same stage again: %v %v", again, err)
	}
	if _, err = state.OpenTeamFight(campaign, 0, 2, 1002); !errors.Is(err, ErrRefused) {
		t.Fatalf("another member must wait: %v", err)
	}
	if state.Team.Accept(1, 3, 1003) || state.Team.Accept(2, 3, 1004) {
		t.Fatal("two of three must not open selection")
	}
	if !state.Team.Accept(3, 3, 1005) || state.Team.SelectionStartedAt != 1005 {
		t.Fatalf("selection did not open: %+v", state.Team)
	}
	if state.Team.Expired(1005 + SelectionSeconds - 1) {
		t.Fatal("selection ran out early")
	}
	if !state.Team.Expired(1005 + SelectionSeconds) {
		t.Fatal("selection must run out after 60 s")
	}
	opened, err = state.OpenTeamFight(campaign, 0, 2, 1005+SelectionSeconds)
	if err != nil || !opened || state.Team.StartPlayer != 2 || state.Team.Round != 2 {
		t.Fatalf("an abandoned fight must restart: %v %v %+v", opened, err, state.Team)
	}
}

func TestTeamFightFightWindowAndSettlement(t *testing.T) {
	state := teamState(t)
	campaign := firstFightCampaign(t, state)
	if _, err := state.OpenTeamFight(campaign, 0, 1, 10); err != nil {
		t.Fatal(err)
	}
	state.Team.FightStartedAt = 100
	if state.Team.Expired(100+FightSeconds-1) || !state.Team.Expired(100+FightSeconds) {
		t.Fatal("fight window is 150 s")
	}
	result, err := state.ApplyTeamResult(2)
	if err != nil || !result.Won || state.StagesOf(campaign)[0].HP != 0 || state.Points != 2 {
		t.Fatalf("win: %+v %v points=%d", result, err, state.Points)
	}
	state.Conclude("key")
	if !state.Team.Settled() || state.Team.Expired(1<<40) || state.LiveTeam(campaign, 1, 1<<40) != nil {
		t.Fatal("a settled fight is only replayed")
	}
	if state.StagesOf(campaign)[0].InBattle != 0 {
		t.Fatal("settling frees the stage")
	}
}

func TestTeamFormationDropsReadiness(t *testing.T) {
	team := TeamFight{}
	team.SetHero(7, 1, 55, json.RawMessage(`{"table_id":9}`))
	if !team.Toggle(7) || !team.AllPrepared([]int64{7}) {
		t.Fatal("member not ready")
	}
	team.SetHero(7, 2, 56, json.RawMessage(`{"table_id":10}`))
	if team.IsPrepared(7) {
		t.Fatal("a changed formation must be confirmed again")
	}
	if got := team.Pick(7).Fielded(); len(got) != 2 || got[0] != 55 || got[1] != 56 {
		t.Fatalf("fielded %v", got)
	}
	if !team.Toggle(7) || team.Toggle(7) {
		t.Fatal("a second toggle must unready")
	}
}

func TestNoticeLogKeepsSequenceAndBound(t *testing.T) {
	var state RunState
	for range noticeLimit + 5 {
		state.AddNotice(NoticeRecord{Function: NoticeFightStatus})
	}
	last := state.Notices[len(state.Notices)-1].Sequence
	if len(state.Notices) != noticeLimit || last != noticeLimit+5 {
		t.Fatalf("len=%d last=%d", len(state.Notices), last)
	}
}
