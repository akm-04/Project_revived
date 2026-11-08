package stockruntime

import (
	"testing"

	app "gxb.local/backend/v2/internal/application/broadcast"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
)

func broadcastTestMessage(msgType int64, fields app.Fields, enemy identity.PlayerID) app.Message {
	mid := app.SystemMID
	if msgType == app.DormExpand {
		mid = app.ActivityMID
	}
	return app.Message{MID: mid, MsgType: msgType, Server: 7, Player: identity.PlayerID(100001), Enemy: enemy, Fields: fields}
}

func TestBroadcastFrameShapesEachClientCallback(t *testing.T) {
	cases := []struct {
		message app.Message
		want    map[string]any
	}{
		{broadcastTestMessage(app.SXHero, app.Fields{HeroTableID: 10001001}, 0), map[string]any{"msg_type": int64(app.SXHero), "player_name": "A", "partner_id": int64(10001001)}},
		{broadcastTestMessage(app.ArenaWins, app.Fields{KeepWinTimes: 9}, 0), map[string]any{"msg_type": int64(app.ArenaWins), "player_name": "A", "keep_win_times": int64(9)}},
		{broadcastTestMessage(app.ArenaTop3, app.Fields{Rank: 2}, identity.PlayerID(100002)), map[string]any{"msg_type": int64(app.ArenaTop3), "player_name": "A", "enemy_name": "B", "rank": int64(2)}},
		{broadcastTestMessage(app.Married, app.Fields{HeroTableID: 10001001}, 0), map[string]any{"msg_type": int64(app.Married), "player_name": "A", "hero_table_id": int64(10001001)}},
		{broadcastTestMessage(app.ConquerSchool, app.Fields{Region: 3, ConquerLoopID: 2, ConquerLev: 12}, 0), map[string]any{"msg_type": int64(app.ConquerSchool), "player_name": "A", "region": int64(3), "conquer_loop_id": int64(2), "conquer_lev": int64(12)}},
		{broadcastTestMessage(app.TreasureDiamond, app.Fields{CrystalAward: 40}, 0), map[string]any{"msg_type": int64(app.TreasureDiamond), "player_name": "A", "crystal_award": int64(40)}},
		{broadcastTestMessage(app.GetDormKey, app.Fields{KeyItem: 50035001}, 0), map[string]any{"msg_type": int64(app.GetDormKey), "player_name": "A", "key_item": int64(50035001)}},
		{broadcastTestMessage(app.GetDormKeyNew, app.Fields{KeyItem: 50035002}, 0), map[string]any{"msg_type": int64(app.GetDormKeyNew), "player_name": "A", "key_item": int64(50035002)}},
		{broadcastTestMessage(app.UnlockCG, app.Fields{CGID: 5}, 0), map[string]any{"msg_type": int64(app.UnlockCG), "region": int64(7), "player_name": "A", "cg_id": int64(5)}},
		{broadcastTestMessage(app.SuperPartner, app.Fields{TableID: 10001001}, 0), map[string]any{"msg_type": int64(app.SuperPartner), "region": int64(7), "player_name": "A", "table_id": int64(10001001)}},
		{broadcastTestMessage(app.DormExpand, app.Fields{}, 0), map[string]any{"msg_type": int64(app.DormExpand), "region_id": int64(7), "player_name": "A"}},
	}
	for _, tc := range cases {
		frame := broadcastFrame(tc.message, "A", "B")
		validate := ValidateSystemBroadcast
		if tc.message.MID == app.ActivityMID {
			validate = ValidateActivityBroadcast
		}
		if err := validate(frame); err != nil {
			t.Fatalf("msg_type %d frame rejected: %v", tc.message.MsgType, err)
		}
		outer, err := frame.StrictMap()
		if err != nil {
			t.Fatal(err)
		}
		msg, ok := outer["msg"].(*amf3.Object)
		if !ok {
			t.Fatalf("msg_type %d msg type %T", tc.message.MsgType, outer["msg"])
		}
		body, err := msg.StrictMap()
		if err != nil {
			t.Fatal(err)
		}
		if len(body) != len(tc.want) {
			t.Fatalf("msg_type %d fields=%v want=%v", tc.message.MsgType, body, tc.want)
		}
		for key, want := range tc.want {
			if body[key] != want {
				t.Fatalf("msg_type %d field %s=%v want %v", tc.message.MsgType, key, body[key], want)
			}
		}
	}
}

func TestBroadcastValidationFailsClosed(t *testing.T) {
	frame := broadcastFrame(broadcastTestMessage(app.UnlockCG, app.Fields{CGID: 5}, 0), "A", "")
	if err := ValidateActivityBroadcast(frame); err == nil {
		t.Fatal("system frame accepted on activity MID")
	}
	bad := &amf3.Object{Properties: []amf3.Property{{Name: "msg", Value: &amf3.Object{Properties: []amf3.Property{{Name: "msg_type", Value: int64(app.UnlockCG)}}}}}}
	if err := ValidateSystemBroadcast(bad); err == nil {
		t.Fatal("missing fields accepted")
	}
	if _, err := NewBroadcastNoticeRegistry(); err != nil {
		t.Fatal(err)
	}
	if descriptor, ok := mids.Lookup(mids.MIDSystemBroadcast); !ok || descriptor.Direction != mids.S2C || descriptor.Transport != mids.TCP {
		t.Fatalf("system broadcast descriptor=%+v ok=%v", descriptor, ok)
	}
}
