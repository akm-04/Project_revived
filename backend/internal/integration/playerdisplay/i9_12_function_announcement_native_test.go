//go:build postgres

package playerdisplay_test

import (
	"fmt"
	"net/http"
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/campaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	app "gxb.local/backend/v2/internal/application/campaign"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

func tutorialOwner(p *pg.Pool) i5.Service {
	values, content := i5store.Store{Queryer: p}, contentstore.Store{Queryer: p}
	return i5.Service{Runner: tx.Runner{DB: p}, Store: values, Content: content, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.LevelFunctionAnnouncements{}, CampaignClears: campaignstore.TutorialMilestones{}, Directory: i4store.DirectoryLevelProjection{},
		Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, RedeemSecret: []byte("i9-3a-campaign-native-fixture-secret")}
}

func tutorialPlayerAt100007(t *testing.T, p *pg.Pool) identity.ActorContext {
	t.Helper()
	revision := installed(t, p)
	actor := bornActor(t, p)
	bornHero(t, p, actor, revision, 10001001, 1)
	bornHero(t, p, actor, revision, 10001002, 2)
	exec(t, p, `UPDATE player_progression SET level=7,exp=(SELECT p.total_exp FROM gxb_content_player_progression p JOIN gxb_content_activation a ON a.revision_id=p.revision_id WHERE a.slot='content' AND p.level=6) WHERE player_id=$1`, int64(actor.PlayerID))
	exec(t, p, `UPDATE player_directory_profiles SET lev=7 WHERE player_id=$1`, int64(actor.PlayerID))
	exec(t, p, `INSERT INTO campaign_players(player_id,normal_bonus_id,super_bonus_id,pending_generation,last_generation,state_version,updated_at)VALUES($1,0,0,'','',1,clock_timestamp()) ON CONFLICT(player_id) DO NOTHING`, int64(actor.PlayerID))
	for node := int64(100001); node <= 100006; node++ {
		exec(t, p, `INSERT INTO campaign_nodes(player_id,campaign_id,star,win_day,wins,reset_day,resets,partner_drop,first_clear_day)VALUES($1,$2,3,0,0,0,0,false,1) ON CONFLICT(player_id,campaign_id) DO UPDATE SET star=3,first_clear_day=1`, int64(actor.PlayerID), node)
	}
	return actor
}

func tutorialCampaignRequest(actor identity.ActorContext, mid uint16, params map[string]any) httpedge.DispatchRequest {
	return playtestRequest(actor, mid, params)
}

func functionAnnouncementDecorator(database *pg.Pool, next httpedge.Dispatcher) httpedge.Dispatcher {
	return stockruntime.Decorated{Next: next, PendingFunctions: i5store.Store{Queryer: database}}
}

func functionIDs(body map[string]any) []int64 {
	raw, ok := body["new_funcs_"].([]any)
	if ok {
		out := make([]int64, 0, len(raw))
		for _, value := range raw {
			if number, ok := value.(float64); ok {
				out = append(out, int64(number))
			}
		}
		return out
	}
	typed, _ := body["new_funcs_"].([]int64)
	return typed
}

func hasFunction(body map[string]any, want int64) bool {
	for _, id := range functionIDs(body) {
		if id == want {
			return true
		}
	}
	return false
}

// BUGS #114: the client starts the Skill Upgrade guide only from a reply's
// new_funcs_ (Backend.lua:775-777, SelfPlayer.lua:487-518,554); a lost reply
// never repeats it. The announcement must survive until the client saves the
// skill guide cursor through SAVE_STORY (StoryData.lua:82-92, MainScene.lua:1069-1078).
func TestI912Function33AnnouncementReplaysUntilSaveStoryAcknowledgesIt(t *testing.T) {
	database := pool(t)
	defer database.Close()
	actor := tutorialPlayerAt100007(t, database)
	mode := campaignModeWithLevelAnnouncements(t, database)
	team := []int64{0, 1, 2, 0, 0}
	if _, err := mode.Fight(ctx, actor, app.Fight{CampaignID: 100007, Type: d.Normal, Formation: team}, op()); err != nil {
		t.Fatal(err)
	}
	campaign := stockruntime.CampaignDispatcher{Authority: fixedSocialAuthority{actor: actor}, Service: mode}
	decorated := functionAnnouncementDecorator(database, campaign)
	tracked := i911aTracked(actor)
	result := decorated.Dispatch(tracked, tutorialCampaignRequest(actor, 114, map[string]any{
		"campaign_id": int64(100007), "campaign_type": d.Normal, "star": int64(3), "formation": "0|1|2|0|0",
	}))
	if result.HTTPStatus != http.StatusOK || !hasFunction(result.Body, 33) {
		t.Fatalf("first 100007 result %d %#v", result.HTTPStatus, result.Body)
	}
	var pending bool
	if err := database.QueryRow(ctx, `SELECT acknowledged_at IS NULL FROM player_function_unlocks WHERE player_id=$1 AND function_id=33`, int64(actor.PlayerID)).Scan(&pending); err != nil || !pending {
		t.Fatalf("function 33 pending=%v err=%v", pending, err)
	}

	later := decorated.Dispatch(tracked, tutorialCampaignRequest(actor, 112, map[string]any{}))
	if later.HTTPStatus != http.StatusOK || !hasFunction(later.Body, 33) {
		t.Fatalf("a later successful reply dropped function 33: %d %#v", later.HTTPStatus, later.Body)
	}

	owner := tutorialOwner(database)
	i5d := stockruntime.I5Dispatcher{Authority: fixedSocialAuthority{actor: actor}, Service: owner}
	acknowledged := i5d.Dispatch(tracked, tutorialCampaignRequest(actor, 26, map[string]any{"story_id": int64(10002), "story_state": int64(3), "guide_id": int64(100198)}))
	if acknowledged.HTTPStatus != http.StatusOK {
		t.Fatalf("SAVE_STORY acknowledgement %d %#v", acknowledged.HTTPStatus, acknowledged.Body)
	}
	var cleared bool
	if err := database.QueryRow(ctx, `SELECT acknowledged_at IS NOT NULL FROM player_function_unlocks WHERE player_id=$1 AND function_id=33`, int64(actor.PlayerID)).Scan(&cleared); err != nil || !cleared {
		t.Fatalf("function 33 acknowledged=%v err=%v", cleared, err)
	}
	after := decorated.Dispatch(tracked, tutorialCampaignRequest(actor, 112, map[string]any{}))
	if after.HTTPStatus != http.StatusOK || hasFunction(after.Body, 33) {
		t.Fatalf("acknowledged function 33 still replayed: %d %#v", after.HTTPStatus, after.Body)
	}
}

// BUGS #114 follow-up: only functions 31/33/42/48 have an acknowledging guide
// cursor. A NULL row for any other function can never be cleared, so replaying
// it makes the client replay its guide on every reply (Backend.lua:775-777,
// SelfPlayer.lua:487-554).
func TestI912FunctionAnnouncementWithoutAcknowledgementCursorIsNotReplayed(t *testing.T) {
	database := pool(t)
	actor := tutorialPlayerAt100007(t, database)
	mode := campaignModeWithLevelAnnouncements(t, database)
	campaign := stockruntime.CampaignDispatcher{Authority: fixedSocialAuthority{actor: actor}, Service: mode}
	decorated := functionAnnouncementDecorator(database, campaign)
	tracked := i911aTracked(actor)
	unacknowledgeable := []int64{1, 5, 7}
	for _, functionID := range unacknowledgeable {
		exec(t, database, `INSERT INTO player_function_unlocks(player_id,function_id,opened_at,source_fact_key,state_version,acknowledged_at)VALUES($1,$2,clock_timestamp(),$3,1,NULL) ON CONFLICT(player_id,function_id) DO UPDATE SET acknowledged_at=NULL`, int64(actor.PlayerID), functionID, fmt.Sprintf("i9-12-null-function-%d", functionID))
	}

	result := decorated.Dispatch(tracked, tutorialCampaignRequest(actor, 112, map[string]any{}))
	if result.HTTPStatus != http.StatusOK {
		t.Fatalf("reply %d %#v", result.HTTPStatus, result.Body)
	}
	for _, functionID := range unacknowledgeable {
		if hasFunction(result.Body, functionID) {
			t.Fatalf("function %d has no acknowledgement cursor but replayed: %#v", functionID, result.Body)
		}
	}
}

// BUGS #114 follow-up: a player whose saved guide cursor has already reached an
// announcement's cursor never sends that SAVE_STORY, so the pending row must
// count as acknowledged instead of replaying forever.
func TestI912FunctionAnnouncementPastItsGuideCursorIsNotReplayed(t *testing.T) {
	database := pool(t)
	actor := tutorialPlayerAt100007(t, database)
	exec(t, database, `UPDATE player_story_cursors SET guide_id=$2 WHERE player_id=$1`, int64(actor.PlayerID), int64(100198))
	exec(t, database, `INSERT INTO player_function_unlocks(player_id,function_id,opened_at,source_fact_key,state_version,acknowledged_at)VALUES($1,33,clock_timestamp(),'i9-12-null-past-cursor',1,NULL) ON CONFLICT(player_id,function_id) DO UPDATE SET acknowledged_at=NULL`, int64(actor.PlayerID))
	mode := campaignModeWithLevelAnnouncements(t, database)
	campaign := stockruntime.CampaignDispatcher{Authority: fixedSocialAuthority{actor: actor}, Service: mode}
	decorated := functionAnnouncementDecorator(database, campaign)
	tracked := i911aTracked(actor)

	result := decorated.Dispatch(tracked, tutorialCampaignRequest(actor, 112, map[string]any{}))
	if result.HTTPStatus != http.StatusOK {
		t.Fatalf("reply %d %#v", result.HTTPStatus, result.Body)
	}
	if hasFunction(result.Body, 33) {
		t.Fatalf("function 33's guide cursor was already reached but it replayed: %#v", result.Body)
	}
}
