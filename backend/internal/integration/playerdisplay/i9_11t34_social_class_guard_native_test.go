//go:build postgres

package playerdisplay_test

import (
	"context"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinboxstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/adapters/socialpresentation"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appgeneration "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/socialinbox"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type nativeDiscardReloads struct{}

func (nativeDiscardReloads) Emit(context.Context, []sr.ReloadReference) {}

func classGuardRelationService(p *pg.Pool) sr.Service {
	return sr.Service{
		Timed:        appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}},
		PlayerRoots:  i4store.PlayerRootLocker{},
		Store:        socialrelationstore.Store{},
		Inbox:        socialinbox.RelationService{Store: socialinboxstore.Store{}},
		Presentation: socialpresentation.TransactionReader{},
	}
}

// A-200 over the production Social dispatcher: a class pair cannot be deleted
// from the friend list (34017) or blacklisted (34013), and the refusal leaves
// the friendship and block state untouched.
func TestI9_11T34ClassPairFriendSurfaceNative(t *testing.T) {
	p := pool(t)
	mentor := mentorService(p)
	relations := classGuardRelationService(p)
	server := rankingServer(t, p)
	teacher := mentorActorOn(t, p, server, 60)
	student := mentorActorOn(t, p, server, 20)

	expectMentorOK(t, mentorCall(t, mentor, student, 1857, map[string]any{"to_player_id": int64(teacher.PlayerID), "relation_type": int64(1), "msg": ""}), 1857)
	expectMentorOK(t, mentorCall(t, mentor, teacher, 1859, map[string]any{"from_player_id": int64(student.PlayerID)}), 1859)

	dispatch := func(actor identity.ActorContext, mid uint16, target identity.PlayerID) httpedge.Response {
		dispatcher := stockruntime.SocialDispatcher{Authority: unpinnedDispatchAuthority{actor: actor}, Relations: relations, Mentor: mentor, Emitter: nativeDiscardReloads{}}
		return dispatcher.Dispatch(ctx, unpinnedRequest(mid, actor, time.Now().UTC(), map[string]any{"player_id": int64(target)}))
	}
	if response := dispatch(teacher, 181, student.PlayerID); response.HTTPStatus != 409 || response.Body["error_code"] != int64(34017) {
		t.Fatalf("MID 181 status %d body %#v, want 409/34017", response.HTTPStatus, response.Body)
	}
	if response := dispatch(student, 185, teacher.PlayerID); response.HTTPStatus != 409 || response.Body["error_code"] != int64(34013) {
		t.Fatalf("MID 185 status %d body %#v, want 409/34013", response.HTTPStatus, response.Body)
	}
	var friendships, blocks int64
	if err := p.Raw().QueryRow(ctx, `SELECT count(*) FROM social_friendships WHERE active AND ((player_low_id=$1 AND player_high_id=$2) OR (player_low_id=$2 AND player_high_id=$1))`, int64(teacher.PlayerID), int64(student.PlayerID)).Scan(&friendships); err != nil || friendships != 1 {
		t.Fatalf("class friendship changed %d %v", friendships, err)
	}
	if err := p.Raw().QueryRow(ctx, `SELECT count(*) FROM social_blocks WHERE active AND ((blocker_player_id=$1 AND blocked_player_id=$2) OR (blocker_player_id=$2 AND blocked_player_id=$1))`, int64(teacher.PlayerID), int64(student.PlayerID)).Scan(&blocks); err != nil || blocks != 0 {
		t.Fatalf("refused blacklist wrote blocks=%d %v", blocks, err)
	}
}
