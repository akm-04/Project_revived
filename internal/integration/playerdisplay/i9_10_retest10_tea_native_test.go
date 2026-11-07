//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

// TestI9_10Retest10TeaPresentPreparesMission sends one scroll between guild
// members through the dispatcher and proves the mission view was prepared in
// the same transaction as the fact.
func TestI9_10Retest10TeaPresentPreparesMission(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	donor, receiver := bornActor(t, p), bornActor(t, p)
	guildFixture(t, p, donor, receiver)
	bornHero(t, p, receiver, revision, 10001001, 1)
	scroll := scrollForHero(t, p, revision, 10001001)
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,$2,1,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour')`, int64(donor.PlayerID), scroll)
	exec(t, p, `INSERT INTO objective_definitions(program_id,stock_family,objective_id,definition_revision,strategy,accepted_fact_kind,target,generation_kind,reward_plan,content_policy_version)
		VALUES('tea:fact',2,90028,'LEGACY_TEA','COMMITTED_DELTA','TEA_PARTY_DONATED',1,'STATIC','{"PlayerID":0,"Source":{"Domain":"mission","Operation":"claim","BusinessKey":"legacy","Occurrence":"","PolicyVersion":"I9_MISSIONS_V1"},"Lines":[{"Kind":"STACK_ITEM","ItemID":40001001,"Amount":1}]}'::jsonb,'I9_MISSIONS_V1') ON CONFLICT DO NOTHING`)
	exec(t, p, `INSERT INTO player_mission_instances(player_id,program_id,objective_id,generation_id,definition_revision,progress,claim_state,state_version)VALUES($1,'tea:fact',90028,'','LEGACY_TEA',0,'UNCLAIMED',1)`, int64(donor.PlayerID))

	service := teaService(p)
	opCtx := contentOp(t, p, revision)
	call := func(actor identity.ActorContext, mid uint16, params map[string]any) httpedge.Response {
		dispatcher := stockruntime.GuildTeaDispatcher{Authority: teaAuthority{"player": actor}, Service: service}
		return dispatcher.Dispatch(ctx, httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{Operation: opCtx, MID: mid, Params: params,
			Claims: wire.CredentialClaims{Token: "player", Region: int64(actor.LogicalServerID)}, ReceivedAt: time.Now().UTC()}})
	}
	if got := call(receiver, 1809, map[string]any{"item_id": scroll}); got.HTTPStatus != 200 {
		t.Fatalf("wish %d %#v", got.HTTPStatus, got.Body)
	}
	if got := call(donor, 1810, map[string]any{"player_id": int64(receiver.PlayerID)}); got.HTTPStatus != 200 {
		t.Fatalf("present %d %#v cause %v", got.HTTPStatus, got.Body, got.Cause)
	}
	if left := scalar(t, p, `SELECT COALESCE((SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2),0)`, int64(donor.PlayerID), scroll); left != 0 {
		t.Fatalf("donor scroll %d", left)
	}
	if credited := scalar(t, p, `SELECT current_num FROM guild_tea_wishes WHERE player_id=$1`, int64(receiver.PlayerID)); credited != 1 {
		t.Fatalf("receiver wish %d", credited)
	}
	if progress := scalar(t, p, `SELECT progress FROM player_mission_instances WHERE player_id=$1 AND objective_id=90028`, int64(donor.PlayerID)); progress != 1 {
		t.Fatalf("TEA_PARTY_DONATED mission progress %d", progress)
	}
}
