package arena

import (
	"gxb.local/backend/v2/internal/foundation/ids"
	"testing"
	"time"
)

func TestFriendFightSingleTeamEndsAfterEightTurns(t *testing.T) {
	at := time.Date(2026, 10, 29, 0, 0, 0, 0, time.UTC)
	room, err := NewSelectionRoom(100001, 100002, at)
	if err != nil {
		t.Fatal(err)
	}
	room.RequiredTeams = 1
	rosters := [2]SelectionRoster{selectionRosterFixture(0), selectionRosterFixture(1)}
	for range 8 {
		room, err = room.Expire(rosters[room.Turn%2], room.Deadline)
		if err != nil {
			t.Fatal(err)
		}
	}
	if !room.Complete() || room.Team != 1 || room.Validate() != nil {
		t.Fatal("single team did not terminate", room)
	}
	for side := range 2 {
		if len(room.Teams[side][0].Heroes) != 5 || len(room.Teams[side][1].Heroes) != 0 {
			t.Fatal("unexpected team materialization", room)
		}
	}
	room.RequiredTeams = 2
	if room.Validate() == nil {
		t.Fatal("unsupported team count")
	}
}
func TestFriendInvitationRequiresConsentIdentityAndExactLifetime(t *testing.T) {
	identifier, _ := ids.NewUUID()
	roomIdentifier, _ := ids.NewUUID()
	at := time.Date(2026, 10, 29, 0, 0, 0, 0, time.UTC)
	invitation := FriendInvitation{Identifier: identifier, Inviter: AdmissionFrom(admissionFixture(t, 100001)), Recipient: 100002, Mode: 1, GameType: 1, Status: FriendInvitationPending, CreatedAt: at, ExpiresAt: at.Add(FriendFightInvitationLifetime), Sequence: 1, StateVersion: 1}
	if invitation.Validate() != nil {
		t.Fatal("valid invitation")
	}
	for _, mutate := range []func(*FriendInvitation){func(value *FriendInvitation) { value.Recipient = value.Inviter.PlayerID }, func(value *FriendInvitation) { value.ExpiresAt = value.ExpiresAt.Add(time.Second) }, func(value *FriendInvitation) { value.Status = FriendInvitationAccepted }, func(value *FriendInvitation) { value.Room = roomIdentifier }, func(value *FriendInvitation) { value.Mode = 3 }, func(value *FriendInvitation) { value.Inviter.SessionID = ids.UUID{} }} {
		invalid := invitation
		mutate(&invalid)
		if invalid.Validate() == nil {
			t.Fatal("invalid invitation accepted", invalid)
		}
	}
	invitation.Status = FriendInvitationAccepted
	invitation.Room = roomIdentifier
	if invitation.Validate() != nil {
		t.Fatal("accepted invitation rejected")
	}
}
