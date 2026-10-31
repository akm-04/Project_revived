package stockruntime

import (
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/protocol/amf3"
)

func TestOccultRoomFrameCarriesFunctionAndRoomType(t *testing.T) {
	frame, err := occultRoomFrame(occultFunctionEvent, map[string]any{"event_id": int64(5), "dispatch_limit": int64(33)})
	if err != nil {
		t.Fatal(err)
	}
	if err = ValidateOccultRoomNotice(frame); err != nil {
		t.Fatalf("a built room push must validate: %v", err)
	}
	fields, _ := frame.StrictMap()
	if fields["notice_type"] != OccultRoomNoticeType {
		t.Fatalf("notice_type %v", fields["notice_type"])
	}
	bad, err := occultNotice(OccultRoomNoticeType, map[string]any{"function_type": int64(13), "room_type": int64(1)})
	if err != nil || ValidateOccultRoomNotice(bad) == nil {
		t.Fatalf("function 13 must be refused: %v", err)
	}
	single, err := occultNotice(OccultRoomNoticeType, map[string]any{"function_type": int64(1), "room_type": int64(2)})
	if err != nil || ValidateOccultRoomNotice(single) == nil {
		t.Fatalf("room_type 2 must be refused: %v", err)
	}
	if ValidateOccultRoomNotice(&amf3.Object{}) == nil {
		t.Fatal("an empty object must be refused")
	}
}

func TestOccultInviteNoticeNeedsRoomChapterAndInviter(t *testing.T) {
	good, err := occultNotice(OccultInviteNoticeType, map[string]any{"room_id": int64(4), "chapter_id": int64(2), "force": int64(0), "player_info": map[string]any{"player_id": int64(1)}})
	if err != nil || ValidateOccultInviteNotice(good) != nil {
		t.Fatalf("invite must validate: %v", err)
	}
	bad, err := occultNotice(OccultInviteNoticeType, map[string]any{"room_id": int64(0), "chapter_id": int64(2), "player_info": map[string]any{}})
	if err != nil || ValidateOccultInviteNotice(bad) == nil {
		t.Fatalf("room 0 must be refused: %v", err)
	}
}

func TestOccultLedgerPushesOnlyChangesAfterTheFirstSight(t *testing.T) {
	ledger := NewRoomNoticeLedger()
	events := []d.EventRecord{{Sequence: 1, Type: 5, DispatchLimit: 33}}
	if fresh := ledger.newEvents(7, events); len(fresh) != 0 {
		t.Fatalf("first sight must not repeat events: %v", fresh)
	}
	events = append(events, d.EventRecord{Sequence: 2, Type: 2})
	if fresh := ledger.newEvents(7, events); len(fresh) != 1 || fresh[0].Sequence != 2 {
		t.Fatalf("fresh %v", fresh)
	}
	if fresh := ledger.newEvents(7, events); len(fresh) != 0 {
		t.Fatalf("a repeated wakeup must not resend: %v", fresh)
	}

	if moved := ledger.movedPositions(7, map[identity.PlayerID]int64{10: 100, 11: 100}); len(moved) != 0 {
		t.Fatalf("first sight records: %v", moved)
	}
	moved := ledger.movedPositions(7, map[identity.PlayerID]int64{10: 100, 11: 200, 12: 100})
	if len(moved) != 1 || moved[0] != (positionMove{Player: 11, Position: 200}) {
		t.Fatalf("moved %v (a new member only records)", moved)
	}

	ledger.changedOnline(7, map[identity.PlayerID]bool{10: true, 11: true})
	changed := ledger.changedOnline(7, map[identity.PlayerID]bool{10: true, 11: false})
	if len(changed) != 1 || changed[0] != (onlineChange{Player: 11, Online: false}) {
		t.Fatalf("changed %v", changed)
	}
	ledger.forget(7)
	if fresh := ledger.newEvents(7, events); len(fresh) != 0 {
		t.Fatalf("a forgotten room starts over without a replay: %v", fresh)
	}
}

func TestOccultRemovalIsOneShotAndAReseatedPlayerCanBeRemovedAgain(t *testing.T) {
	ledger := NewRoomNoticeLedger()
	players := []identity.PlayerID{11}
	if len(ledger.undelivered(7, occultRoomNoticeKey, players)) != 1 {
		t.Fatal("a removal starts undelivered")
	}
	ledger.markDelivered(7, occultRoomNoticeKey, 11)
	if len(ledger.undelivered(7, occultRoomNoticeKey, players)) != 0 {
		t.Fatal("a delivered removal must not repeat on the next wakeup")
	}
	ledger.reseat(7, occultRoomNoticeKey, players)
	if len(ledger.undelivered(7, occultRoomNoticeKey, players)) != 1 {
		t.Fatal("a player who rejoined can be told of a later departure")
	}
}
