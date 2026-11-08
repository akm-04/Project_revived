//go:build postgres && river && socialintegration && channelintegration

package socialactivation_test

import (
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/channelchatread"
	"gxb.local/backend/v2/internal/adapters/postgres/arenastore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/leaguestore"
	"gxb.local/backend/v2/internal/adapters/postgres/sharedroomstore"
	"gxb.local/backend/v2/internal/adapters/postgres/topfloorstore"
	cc "gxb.local/backend/v2/internal/application/channelchat"
	"gxb.local/backend/v2/internal/domain/identity"
	dr "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"net"
	"testing"
)

const arenaReferenceRobotTeam = 1

func arenaReferenceOwners() cc.Owners {
	return cc.Owners{
		Arena:             channelchatread.ArenaReportReader{TopFloor: topfloorstore.Store{}, Arena: arenastore.Store{}, League: leaguestore.Store{}, Content: contentstore.Store{}},
		Illusion:          channelchatread.IllusionRoomReader{Store: sharedroomstore.Store{}, Content: contentstore.Store{}},
		Occult:            channelchatread.OccultRoomReader{Store: sharedroomstore.Store{}},
		AdventureIllusion: channelchatread.AdventureIllusionRoomReader{Store: sharedroomstore.Store{}, Content: contentstore.Store{}},
		Defense:           channelchatread.DefenseRoomReader{Store: sharedroomstore.Store{}},
	}
}

// seedTopFloorRecord inserts the ladder and combat envelope a retained Top
// Floor record points at; this file does not replay the stored report.
func seedTopFloorRecord(t *testing.T, f *fixture, owner identity.PlayerID) int64 {
	t.Helper()
	revision, e := (contentstore.Store{}).ActiveRevision(ctx, f.p)
	if e != nil {
		t.Fatal(e)
	}
	server := int64(owner) / 100000
	f.sql(`INSERT INTO top_floor_ladders(logical_server_id,content_revision,policy_id,size,settled_day,state_version,created_at,updated_at)
VALUES($1,$2,'C5B_TOP_FLOOR_PRIVATE_POLICY_V1',10326,0,1,$3,$3) ON CONFLICT(logical_server_id) DO NOTHING`, server, revision, f.now())
	f.sql(`INSERT INTO top_floor_players(player_id,logical_server_id,content_revision,best_rank,ticket_day,tickets_left,purchases,refresh_count,offered_day,offered,defense,defense_pet,fights,wins,state_version,created_at,updated_at)
VALUES($1,$2,$3,1,0,5,0,0,0,'[]'::jsonb,'[]'::jsonb,0,1,1,1,$4,$4) ON CONFLICT(player_id) DO NOTHING`, int64(owner), server, revision, f.now())
	unique, e := ids.NewUUID()
	if e != nil {
		t.Fatal(e)
	}
	f.sql(`INSERT INTO combat_locator_roots(domain_kind,authority_scope,domain_locator)VALUES('TOP_FLOOR',$1,$2)`, "fixture-"+unique.String(), "fixture-"+unique.String())
	snapshot := f.text(`INSERT INTO combat_snapshots(snapshot_hash,content_revision,rules_corpus_id,canonical)VALUES(md5(random()::text)||md5(random()::text),$1,md5(random()::text)||md5(random()::text),'\x0000'::bytea) RETURNING snapshot_hash`, revision)
	attempt := f.text(`INSERT INTO combat_attempts(attempt_id,domain_kind,authority_scope,domain_locator,actor_player_id,gameplay_context_id,generation_ref,start_fingerprint,trust_profile_id,trust_profile_version,snapshot_hash,rules_corpus_version,entropy_policy_version,entropy_key_version,resolver_status,state,started_at,result_deadline,state_version)
VALUES(gen_random_uuid(),'TOP_FLOOR',$1,$2,$3,gen_random_uuid(),'fixture',repeat('a',64),'SERVER_REPORT_AUTHORITATIVE_V1',1,$4,repeat('b',64),'HMAC_SHA256_COUNTER_LUA_RANDOM_COMPAT_V1','fixture','PENDING','STAGED',$5::timestamptz,$5::timestamptz+interval '1 hour',1) RETURNING attempt_id::text`, "fixture-"+unique.String(), "fixture-"+unique.String(), int64(owner), snapshot, f.now())
	f.sql(`INSERT INTO top_floor_fights(attempt_id,logical_server_id,challenger_id,defender_robot,is_avenge,start_fingerprint,formation,pet_id,challenger_rank,defender_rank,started_at,status,outcome,settled_at,state_version)
VALUES($1::uuid,$2,$3,$4,false,repeat('a',64),'[1]'::jsonb,0,2,1,$5,'SETTLED','{}'::jsonb,$5,1)`, attempt, server, int64(owner), arenaReferenceRobotTeam, f.now())
	return f.number(`INSERT INTO top_floor_records(owner_player_id,attempt_id,is_attack,win,opponent_robot,recorded_at)VALUES($1,$2::uuid,true,true,$3,$4) RETURNING record_id`, int64(owner), attempt, arenaReferenceRobotTeam, f.now())
}

func topFloorRobotName(t *testing.T, f *fixture) string {
	t.Helper()
	revision, e := (contentstore.Store{}).ActiveRevision(ctx, f.p)
	if e != nil {
		t.Fatal(e)
	}
	catalog, e := (contentstore.Store{}).TopFloorCatalogTx(ctx, f.p, revision)
	if e != nil {
		t.Fatal(e)
	}
	return catalog.RobotName(arenaReferenceRobotTeam)
}

func arenaReferenceCard(t *testing.T, player identity.PlayerID, recordID int64) string {
	t.Helper()
	body, e := json.Marshal(map[string]any{"player_id": int64(player), "player_name": "forged", "enemy_name": "forged", "time": 0, "is_attack": 1, "id": recordID})
	if e != nil {
		t.Fatal(e)
	}
	return string(body)
}

func TestChatH2ArenaReferenceTopFloorCardService(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001, 100002, 100003)
	record := seedTopFloorRecord(t, f, 100001)
	name := topFloorRobotName(t, f)
	h := chatHarness(t, f, channelHarnessOptions{owners: arenaReferenceOwners()})
	a, _, _ := h.login(100001, dr.Service, 99999)
	b, _, _ := h.login(100002, dr.Service, 99999)
	c, _, _ := h.login(100003, dr.Service, 99999)
	sendChat(t, a, arenaReferenceCard(t, 100001, record), 4, amf3.Property{Name: "type", Value: 1.0})
	for _, recipient := range []net.Conn{b, c} {
		body := readCard(t, recipient, 1)
		if body["player_id"] != float64(100001) || body["enemy_name"] != name || body["id"] != float64(record) || body["is_attack"] != float64(1) || body["time"] == float64(0) {
			t.Fatal(body)
		}
	}
	if h.report().Outcomes["TRANSPORT_WRITE_RECORDED"] != 3 {
		t.Fatal("service card recipients")
	}
}

func TestChatH2ArenaReferenceTopFloorCardGuild(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001, 100002, 100003)
	f.chatGuild(1000001, 100001, 100002)
	f.chatGuild(1000002, 100003)
	recordA := seedTopFloorRecord(t, f, 100001)
	recordB := seedTopFloorRecord(t, f, 100002)
	name := topFloorRobotName(t, f)
	h := chatHarness(t, f, channelHarnessOptions{owners: arenaReferenceOwners()})
	a, _, _ := h.login(100001, dr.Guild, 1000001)
	b, _, _ := h.login(100002, dr.Guild, 1000001)
	c, _, _ := h.login(100003, dr.Guild, 1000002)

	// B references A's record: silent, and B's session stays usable.
	sendChat(t, b, arenaReferenceCard(t, 100002, recordA), 2, amf3.Property{Name: "type", Value: 1.0})
	noChat(t, a)
	sendChat(t, b, arenaReferenceCard(t, 100002, recordB), 2, amf3.Property{Name: "type", Value: 1.0})
	body := readCard(t, a, 1)
	if body["player_id"] != float64(100002) || body["enemy_name"] != name || body["id"] != float64(recordB) {
		t.Fatal(body)
	}
	readCard(t, b, 1)
	noChat(t, c)

	// A missing record: silent, and A's session stays usable.
	sendChat(t, a, arenaReferenceCard(t, 100001, 99999999), 2, amf3.Property{Name: "type", Value: 1.0})
	noChat(t, b)
	sendChat(t, a, arenaReferenceCard(t, 100001, recordA), 2, amf3.Property{Name: "type", Value: 1.0})
	if got := readCard(t, b, 1); got["id"] != float64(recordA) {
		t.Fatal(got)
	}
	noChat(t, c)
}
