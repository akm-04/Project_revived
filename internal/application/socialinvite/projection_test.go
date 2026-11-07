package socialinvite

import (
	"encoding/json"
	"testing"

	domain "gxb.local/backend/v2/internal/domain/socialinvite"
)

func testCatalog() MissionCatalog {
	return MissionCatalog{
		{ID: 100001, Type: domain.MissionInvitedCount, RequiredCount: 1, Threshold: 0, Diamond: 16},
		{ID: 100016, Type: domain.MissionHighestOwnedHeroLevel, RequiredCount: 1, Threshold: 50, Diamond: 90},
	}
}

func TestProjectionUsesHighestHeroLevelForTypeThree(t *testing.T) {
	snapshot := Snapshot{InviteCode: "1F", Invitees: []InviteeFacts{{Player: 100002, Name: "Invitee", AvatarID: 7, RegionName: "S1", AcademyLevel: 49, OwnedHeroCount: 3, HighestOwnedHeroLevel: 50, ChargeTotal: 100}}, Claimed: []int64{}}
	projection, err := BuildProjection(snapshot, testCatalog())
	if err != nil {
		t.Fatal(err)
	}
	if !projection.Missions[1].CanAward || !projection.Missions[0].CanAward {
		t.Fatalf("missions not claimable: %+v", projection.Missions)
	}
	if projection.InvitePlayerList()[0].(map[string]any)["lev"] != int64(50) {
		t.Fatalf("lev is not highest hero level: %+v", projection.InvitePlayerList())
	}

	academyHigh := snapshot
	academyHigh.Invitees = []InviteeFacts{{Player: 100002, Name: "Invitee", RegionName: "S1", AcademyLevel: 99, OwnedHeroCount: 1, HighestOwnedHeroLevel: 10}}
	projection, err = BuildProjection(academyHigh, testCatalog())
	if err != nil {
		t.Fatal(err)
	}
	if projection.Missions[1].CanAward {
		t.Fatal("academy level leaked into type 3")
	}
}

func TestProjectionClaimedMissionsAreNeverAwardableAgain(t *testing.T) {
	snapshot := Snapshot{InviteCode: "1F", Invitees: []InviteeFacts{{Player: 100002, Name: "Invitee", RegionName: "S1", AcademyLevel: 49, HighestOwnedHeroLevel: 80}}, Claimed: []int64{100016}}
	projection, err := BuildProjection(snapshot, testCatalog())
	if err != nil {
		t.Fatal(err)
	}
	if projection.Missions[1].CanAward {
		t.Fatal("claimed mission remained awardable")
	}
}

func TestInvitationOffHookIsValidated(t *testing.T) {
	if !invitationOff(json.RawMessage(`{"version":1,"revision":"ops-1","invitation_off":true}`)) {
		t.Fatal("valid off hook ignored")
	}
	for _, raw := range []string{"", `{`, `{"version":2,"revision":"x","invitation_off":true}`, `{"version":1,"revision":"","invitation_off":true}`, `{"version":1,"revision":"x","unknown":1}`, `{"version":1,"revision":"x","invitation_off":false}`} {
		if invitationOff(json.RawMessage(raw)) {
			t.Fatalf("invalid payload disabled the product: %q", raw)
		}
	}
}
