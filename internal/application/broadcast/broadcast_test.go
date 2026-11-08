package broadcast

import (
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
)

func validMessage() Message {
	return Message{MID: SystemMID, MsgType: UnlockCG, Server: 1, Player: 100001, Fields: Fields{CGID: 7}}
}

func TestMessageValidate(t *testing.T) {
	if err := validMessage().Validate(); err != nil {
		t.Fatal(err)
	}
	cases := []Message{
		{MID: SystemMID, MsgType: DormExpand, Server: 1, Player: 100001},
		{MID: ActivityMID, MsgType: UnlockCG, Server: 1, Player: 100001, Fields: Fields{CGID: 7}},
		{MID: SystemMID, MsgType: SXHero, Server: 1, Player: 100001},
		{MID: SystemMID, MsgType: ArenaWins, Server: 1, Player: 100001, Fields: Fields{KeepWinTimes: 0}},
		{MID: SystemMID, MsgType: ArenaTop3, Server: 1, Player: 100001, Fields: Fields{Rank: 2}},
		{MID: SystemMID, MsgType: ConquerSchool, Server: 1, Player: 100001, Fields: Fields{Region: 1, ConquerLoopID: 1}},
		{MID: SystemMID, MsgType: TreasureDiamond, Server: 1, Player: 100001, Fields: Fields{CrystalAward: 0}},
		{MID: SystemMID, MsgType: UnlockCG, Server: 0, Player: 100001, Fields: Fields{CGID: 7}},
		{MID: SystemMID, MsgType: UnlockCG, Server: 1, Player: 0, Fields: Fields{CGID: 7}},
		{MID: SystemMID, MsgType: 9999, Server: 1, Player: 100001},
	}
	for index, message := range cases {
		if err := message.Validate(); err == nil {
			t.Fatalf("case %d accepted: %+v", index, message)
		}
	}
	if err := (Message{MID: ActivityMID, MsgType: DormExpand, Server: 2, Player: 100001}).Validate(); err != nil {
		t.Fatalf("dorm expand activity: %v", err)
	}
	top3 := Message{MID: SystemMID, MsgType: ArenaTop3, Server: 1, Player: 100001, Enemy: identity.PlayerID(100002), Fields: Fields{Rank: 3}}
	if err := top3.Validate(); err != nil {
		t.Fatal(err)
	}
}
