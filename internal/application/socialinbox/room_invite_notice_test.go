package socialinbox

import (
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
)

func TestRoomInviteSourceKeyRoundTripsCanonicalIntegers(t *testing.T) {
	for _, noticeType := range []int16{RoomInviteIllusionNoticeType, RoomInviteOccultNoticeType, RoomInviteCoopNoticeType, RoomInviteDefenseNoticeType} {
		invite := RoomInvite{Recipient: identity.PlayerID(100001), NoticeType: noticeType, RoomID: 7, ParadiseID: 1001, ChapterID: 2, Force: 0}
		key, err := invite.SourceKey()
		if err != nil {
			t.Fatal(err)
		}
		parsed, err := ParseRoomInviteSource(invite.Recipient, noticeType, key.Key)
		if err != nil || parsed != invite {
			t.Fatalf("round trip %+v %v", parsed, err)
		}
	}
}

func TestRoomInviteSourceKeyRejectsNonCanonicalForms(t *testing.T) {
	recipient := identity.PlayerID(100001)
	for _, key := range []string{
		"6:7:1001:2",
		"6:07:1001:2:0",
		"6:+7:1001:2:0",
		"6:7:1001:2:0:9",
		"6:0:1001:2:0",
		"5:7:1001:2:0",
		"6:7:-1:2:0",
		"a:7:1001:2:0",
	} {
		if _, err := ParseRoomInviteSource(recipient, 6, key); err == nil {
			t.Fatalf("non-canonical key %q was accepted", key)
		}
	}
	if _, err := ParseRoomInviteSource(recipient, 6, "7:7:1001:2:0"); err == nil {
		t.Fatal("a key whose notice type differs from the row was accepted")
	}
}
