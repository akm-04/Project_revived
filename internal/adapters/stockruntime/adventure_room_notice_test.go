package stockruntime

import (
	"testing"

	app "gxb.local/backend/v2/internal/application/adventure"
	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/protocol/amf3"
)

func roomNoticeFrame(function, roomType int64) *amf3.Object {
	return &amf3.Object{Properties: []amf3.Property{
		{Name: "notice_type", Value: AdventureRoomNoticeType},
		{Name: "params", Value: &amf3.Object{Properties: []amf3.Property{
			{Name: "function_type", Value: function}, {Name: "room_type", Value: roomType},
		}}},
	}}
}

func TestAdventureRoomNoticeValidation(t *testing.T) {
	for _, roomType := range []int64{d.RoomTypeDefense, d.RoomTypeIllusion} {
		if err := ValidateAdventureRoomNotice(roomNoticeFrame(adventureFunctionRoomChange, roomType)); err != nil {
			t.Fatalf("room_type %d: %v", roomType, err)
		}
	}
	if err := ValidateAdventureRoomNotice(roomNoticeFrame(adventureFunctionRoomFight, d.RoomTypeDefense)); err != nil {
		t.Fatal(err)
	}
	if err := ValidateAdventureRoomNotice(roomNoticeFrame(adventureFunctionRoomChange, 4)); err == nil {
		t.Fatal("unknown room_type must refuse")
	}
	if err := ValidateAdventureRoomNotice(roomNoticeFrame(9, d.RoomTypeDefense)); err == nil {
		t.Fatal("unknown function_type must refuse")
	}
}

func TestAdventurePushLedgerSendsOnlyNewSequences(t *testing.T) {
	ledger := NewAdventurePushLedger()
	pushes := []app.RoomPush{{Sequence: 1}, {Sequence: 2}}
	if fresh := ledger.newPushes(5, pushes); len(fresh) != 0 {
		t.Fatalf("first sight must only record: %+v", fresh)
	}
	if fresh := ledger.newPushes(5, pushes); len(fresh) != 0 {
		t.Fatalf("repeated wake must not resend: %+v", fresh)
	}
	pushes = append(pushes, app.RoomPush{Sequence: 3})
	if fresh := ledger.newPushes(5, pushes); len(fresh) != 1 || fresh[0].Sequence != 3 {
		t.Fatalf("new push %+v", fresh)
	}
}
