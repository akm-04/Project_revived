//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/domain/identity"
)

// The stock accept handler refuses the clicker's own full friend list before
// sending 1859 (TeacherWindow.lua:712-718) and message.lua:352-436 names both
// full-list codes and the blacklist code for mentor relations.
const friendNumberLimit = 80

func seedSocialRoot(t *testing.T, p *pg.Pool, player identity.PlayerID, at time.Time) {
	t.Helper()
	exec(t, p, `INSERT INTO player_social_roots(player_id,state_version,created_at,updated_at)VALUES($1,1,$2,$2)ON CONFLICT(player_id)DO NOTHING`, int64(player), at)
}

func seedActiveFriendship(t *testing.T, p *pg.Pool, first, second identity.PlayerID, at time.Time) {
	t.Helper()
	low, high := first, second
	if high < low {
		low, high = high, low
	}
	exec(t, p, `INSERT INTO social_friendships(player_low_id,player_high_id,generation,active,activated_at,ended_at,state_version,updated_at)VALUES($1,$2,1,true,$3,NULL,1,$3)`, int64(low), int64(high), at)
}

func seedFullFriendList(t *testing.T, p *pg.Pool, server identity.LogicalServerID, player identity.PlayerID) {
	t.Helper()
	at := time.Now().UTC().Add(-time.Hour)
	seedSocialRoot(t, p, player, at)
	for i := 0; i < friendNumberLimit; i++ {
		friend, _ := playerRoot(t, p, server)
		seedSocialRoot(t, p, friend.PlayerID, at)
		seedActiveFriendship(t, p, player, friend.PlayerID, at)
	}
}

func assertNoMentorEffect(t *testing.T, p *pg.Pool, first, second identity.PlayerID) {
	t.Helper()
	var friendships, relations int
	low, high := first, second
	if high < low {
		low, high = high, low
	}
	if err := p.Raw().QueryRow(ctx, `SELECT count(*) FROM social_friendships WHERE player_low_id=$1 AND player_high_id=$2 AND active`, int64(low), int64(high)).Scan(&friendships); err != nil {
		t.Fatal(err)
	}
	if err := p.Raw().QueryRow(ctx, `SELECT count(*) FROM mentor_relations WHERE mentor_id=$1 AND student_id=$2 AND ended_at IS NULL`, int64(first), int64(second)).Scan(&relations); err != nil {
		t.Fatal(err)
	}
	if friendships != 0 || relations != 0 {
		t.Fatalf("accept left effects: friendships %d relations %d", friendships, relations)
	}
}

// DL-ab3dc95e: B blocked A; A applies and B accepts. The friendship seam must
// refuse the blocked pair (34014) instead of creating a friendship.
func TestI9_10FMentorAcceptRefusesBlockedPair(t *testing.T) {
	p := pool(t)
	service := mentorService(p)
	server := rankingServer(t, p)
	teacher := mentorActorOn(t, p, server, 60)
	student := mentorActorOn(t, p, server, 20)

	expectMentorOK(t, mentorCall(t, service, student, 1857, map[string]any{"to_player_id": int64(teacher.PlayerID), "relation_type": int64(1), "msg": ""}), 1857)

	at := time.Now().UTC().Add(-time.Hour)
	seedSocialRoot(t, p, teacher.PlayerID, at)
	seedSocialRoot(t, p, student.PlayerID, at)
	exec(t, p, `INSERT INTO social_blocks(blocker_player_id,blocked_player_id,generation,active,activated_at,removed_at,state_version,updated_at)VALUES($1,$2,1,true,$3,NULL,1,$3)`, int64(student.PlayerID), int64(teacher.PlayerID), at)

	expectMentorRefusal(t, mentorCall(t, service, teacher, 1859, map[string]any{"from_player_id": int64(student.PlayerID)}), 1859, 34014)
	assertNoMentorEffect(t, p, teacher.PlayerID, student.PlayerID)
}

// DL-ab3dc95e: either side at the 80-friend cap refuses 34006 (own) / 34007
// (other), as the codes in message.lua:352-436 name.
func TestI9_10FMentorAcceptRefusesFullFriendList(t *testing.T) {
	for _, testCase := range []struct {
		name   string
		full   func(teacher, student identity.ActorContext) identity.PlayerID
		status int64
	}{
		{name: "actor full", full: func(teacher, student identity.ActorContext) identity.PlayerID { return teacher.PlayerID }, status: 34006},
		{name: "applicant full", full: func(teacher, student identity.ActorContext) identity.PlayerID { return student.PlayerID }, status: 34007},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			p := pool(t)
			service := mentorService(p)
			server := rankingServer(t, p)
			teacher := mentorActorOn(t, p, server, 60)
			student := mentorActorOn(t, p, server, 20)

			expectMentorOK(t, mentorCall(t, service, student, 1857, map[string]any{"to_player_id": int64(teacher.PlayerID), "relation_type": int64(1), "msg": ""}), 1857)
			seedFullFriendList(t, p, server, testCase.full(teacher, student))

			expectMentorRefusal(t, mentorCall(t, service, teacher, 1859, map[string]any{"from_player_id": int64(student.PlayerID)}), 1859, testCase.status)
			assertNoMentorEffect(t, p, teacher.PlayerID, student.PlayerID)
		})
	}
}
