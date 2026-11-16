//go:build postgres

package playerdisplay_test

import (
	"encoding/json"
	"fmt"
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/adapters/postgres/mentorstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/adapters/socialpresentation"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appgeneration "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	appmentor "gxb.local/backend/v2/internal/application/mentor"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

func mentorActorOn(t *testing.T, p *pg.Pool, server identity.LogicalServerID, level int64) identity.ActorContext {
	t.Helper()
	a, _ := playerRoot(t, p, server)
	exec(t, p, `INSERT INTO player_profiles(player_id,display_name,avatar_id,avatar_frame_id,player_type,state_version,created_at,updated_at)VALUES($1,'',110001001,0,0,1,clock_timestamp()-interval '1 day',clock_timestamp()-interval '1 day')`, int64(a.PlayerID))
	exec(t, p, `INSERT INTO player_progression(player_id,level,exp,state_version,updated_at)VALUES($1,$2,0,1,clock_timestamp()-interval '1 day')`, int64(a.PlayerID), level)
	exec(t, p, `INSERT INTO player_economy_owners(player_id,state_version,created_at)VALUES($1,1,clock_timestamp()-interval '1 day')`, int64(a.PlayerID))
	exec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'crystal',1000,1,clock_timestamp()-interval '1 day')`, int64(a.PlayerID))
	exec(t, p, `UPDATE player_directory_profiles SET lev=$2 WHERE player_id=$1`, int64(a.PlayerID), level)
	return a
}

func mentorActor(t *testing.T, p *pg.Pool, level int64) identity.ActorContext {
	t.Helper()
	a := actor(t, p)
	exec(t, p, `UPDATE player_progression SET level=$2 WHERE player_id=$1`, int64(a.PlayerID), level)
	exec(t, p, `UPDATE player_directory_profiles SET lev=$2 WHERE player_id=$1`, int64(a.PlayerID), level)
	return a
}

var poolForService *pg.Pool

func mentorService(p *pg.Pool) appmentor.Service {
	poolForService = p
	store := i5store.Store{Queryer: p}
	content := contentstore.Store{Queryer: p}
	grant := appi5.Service{Runner: tx.Runner{DB: p}, Store: store, Content: content, Privileges: appi5.BaselinePrivilegeProvider{}, Functions: appi5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: store, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, RedeemSecret: []byte("i9-10f-test-redeem-key-0000000000")}
	relations := mentorstore.Store{}
	return appmentor.Service{
		Timed:       appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}},
		Players:     i4store.PlayerRootLocker{},
		Store:       relations,
		Directory:   i4store.TransactionDiscoveryReader{},
		Cards:       socialpresentation.TransactionReader{},
		Friendships: socialrelation.FriendshipEnsurer{Players: i4store.PlayerRootLocker{}, Store: socialrelationstore.Store{}},
		Backgrounds: librarystore.Store{},
		Grants:      grant,
		Content:     content,
		Receipts:    kernelstore.Store{},
	}
}

func mentorOperation(t *testing.T, p *pg.Pool) operation.Context {
	t.Helper()
	revision, err := (contentstore.Store{Queryer: p}).ActiveRevision(ctx, p)
	if err != nil {
		t.Fatal(err)
	}
	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: revision})
	if err != nil {
		t.Fatal(err)
	}
	return operation.Context{ID: uuid(), StartedAt: time.Now().UTC(), Policies: policies}
}

func mentorCallWith(t *testing.T, service appmentor.Service, actor identity.ActorContext, mid uint16, params map[string]any, op operation.Context) httpedge.Response {
	t.Helper()
	params["token"] = "bearer"
	params["region"] = int64(actor.LogicalServerID)
	request := httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{Operation: op, MID: mid, ReceivedAt: op.StartedAt, Params: params, Claims: wire.CredentialClaims{Token: "bearer", Region: int64(actor.LogicalServerID)}}}
	dispatcher := stockruntime.MentorDispatcher{Authority: unpinnedDispatchAuthority{actor: actor}, Service: service}
	return dispatcher.Dispatch(ctx, request)
}

func mentorCall(t *testing.T, service appmentor.Service, actor identity.ActorContext, mid uint16, params map[string]any) httpedge.Response {
	t.Helper()
	return mentorCallWith(t, service, actor, mid, params, mentorOperation(t, poolForService))
}

func expectMentorOK(t *testing.T, response httpedge.Response, mid uint16) map[string]any {
	t.Helper()
	if response.HTTPStatus != 200 {
		t.Fatalf("MID %d status %d body %#v cause %v", mid, response.HTTPStatus, response.Body, response.Cause)
	}
	return response.Body
}

func expectMentorRefusal(t *testing.T, response httpedge.Response, mid uint16, code int64) {
	t.Helper()
	if response.HTTPStatus != 409 || response.Body["error_code"] != code {
		t.Fatalf("MID %d status %d body %#v, want 409/%d", mid, response.HTTPStatus, response.Body, code)
	}
}

func TestI9_10FMentorLifeCycleThroughDispatcher(t *testing.T) {
	p := pool(t)
	service := mentorService(p)
	// 1858 scans at most 100 neighbours by player id; a server of its own keeps package neighbours out of that window.
	server := rankingServer(t, p)
	teacher := mentorActorOn(t, p, server, 60)
	student := mentorActorOn(t, p, server, 20)

	info := expectMentorOK(t, mentorCall(t, service, teacher, 1856, map[string]any{}), 1856)
	if _, ok := info["base_info"].(map[string]any); !ok {
		t.Fatalf("1856 base_info %#v", info)
	}
	if list, _ := info["mission_list"].([]any); len(list) != 2 {
		t.Fatalf("1856 mission_list %#v", info["mission_list"])
	}

	finding := expectMentorOK(t, mentorCall(t, service, student, 1858, map[string]any{"relation_type": int64(1)}), 1858)
	found := false
	for _, raw := range finding["player_list"].([]any) {
		row := raw.(map[string]any)
		if row["player_id"] == int64(teacher.PlayerID) {
			found = true
			if row["lev"] != int64(60) || row["is_send_apply"] != false {
				t.Fatalf("1858 card %#v", row)
			}
		}
	}
	if !found {
		t.Fatalf("1858 did not find eligible mentor: %#v", finding)
	}

	expectMentorOK(t, mentorCall(t, service, student, 1857, map[string]any{"to_player_id": int64(teacher.PlayerID), "relation_type": int64(1), "msg": "teach me"}), 1857)
	applied := expectMentorOK(t, mentorCall(t, service, teacher, 1856, map[string]any{}), 1856)
	applyList := applied["apply_list"].([]any)
	if len(applyList) != 1 {
		t.Fatalf("apply_list %#v", applyList)
	}
	apply := applyList[0].(map[string]any)
	if apply["relation_type"] != int64(2) || apply["msg"] != "teach me" || apply["player_info"].(map[string]any)["player_id"] != int64(student.PlayerID) {
		t.Fatalf("apply row %#v", apply)
	}

	accepted := expectMentorOK(t, mentorCall(t, service, teacher, 1859, map[string]any{"from_player_id": int64(student.PlayerID)}), 1859)
	base := accepted["base_info"].(map[string]any)
	relations := base["relations"].([]any)
	if relations[1].(map[string]any)["player_id"] != int64(student.PlayerID) || relations[0].(map[string]any)["player_id"] != nil {
		t.Fatalf("accept relations %#v", relations)
	}
	studentInfo := expectMentorOK(t, mentorCall(t, service, student, 1856, map[string]any{}), 1856)
	studentRelations := studentInfo["base_info"].(map[string]any)["relations"].([]any)
	if studentRelations[0].(map[string]any)["player_id"] != int64(teacher.PlayerID) {
		t.Fatalf("student relation %#v", studentRelations)
	}
	var friends int
	if err := p.Raw().QueryRow(ctx, `SELECT count(*) FROM social_friendships WHERE (player_low_id=$1 AND player_high_id=$2) AND active`, int64(teacher.PlayerID), int64(student.PlayerID)).Scan(&friends); err != nil || friends != 1 {
		t.Fatalf("auto-friendship %d %v", friends, err)
	}

	expectMentorRefusal(t, mentorCall(t, service, teacher, 1861, map[string]any{"relation_type": int64(2)}), 1861, 34012)
	exec(t, p, `UPDATE mentor_relations SET accepted_at=accepted_at-interval '25 hours' WHERE mentor_id=$1 AND student_id=$2 AND ended_at IS NULL`, int64(teacher.PlayerID), int64(student.PlayerID))
	terminated := expectMentorOK(t, mentorCall(t, service, teacher, 1861, map[string]any{"relation_type": int64(2)}), 1861)
	if rels := terminated["base_info"].(map[string]any)["relations"].([]any); len(rels) != 2 || rels[1].(map[string]any)["player_id"] != nil {
		t.Fatalf("terminate reply %#v", rels)
	}
	expectMentorRefusal(t, mentorCall(t, service, teacher, 1857, map[string]any{"to_player_id": int64(student.PlayerID), "relation_type": int64(2), "msg": ""}), 1857, 34002)
}

// C3: a filter_str search returns same-server candidates only. The cross-server
// teacher is otherwise eligible, so only the server filter keeps it out.
func TestI9_10FMentorFindingFilterStaysOnTheActorServer(t *testing.T) {
	p := pool(t)
	service := mentorService(p)
	server := rankingServer(t, p)
	foreignServer := rankingServer(t, p)
	for foreignServer == server {
		foreignServer = rankingServer(t, p)
	}
	teacher := mentorActorOn(t, p, server, 60)
	foreignTeacher := mentorActorOn(t, p, foreignServer, 60)
	student := mentorActorOn(t, p, server, 20)
	for _, named := range []struct {
		actor identity.ActorContext
		name  string
	}{{teacher, "LocalTeacher"}, {foreignTeacher, "ForeignTeacher"}, {student, "LocalStudent"}} {
		exec(t, p, `UPDATE player_profiles SET display_name=$2 WHERE player_id=$1`, int64(named.actor.PlayerID), named.name)
		exec(t, p, `UPDATE player_directory_profiles SET name=$2 WHERE player_id=$1`, int64(named.actor.PlayerID), named.name)
	}
	find := func(filter string) []any {
		t.Helper()
		params := map[string]any{"relation_type": int64(1)}
		if filter != "" {
			params["filter_str"] = filter
		}
		return expectMentorOK(t, mentorCall(t, service, student, 1858, params), 1858)["player_list"].([]any)
	}
	if list := find("ForeignTeacher"); len(list) != 0 {
		t.Fatalf("1858 exact-name search crossed the server: %#v", list)
	}
	if list := find(fmt.Sprintf("%d", int64(foreignTeacher.PlayerID))); len(list) != 0 {
		t.Fatalf("1858 numeric-id search crossed the server: %#v", list)
	}
	for filter, want := range map[string]int64{"LocalTeacher": int64(teacher.PlayerID), fmt.Sprintf("%d", int64(teacher.PlayerID)): int64(teacher.PlayerID)} {
		list := find(filter)
		if len(list) != 1 || list[0].(map[string]any)["player_id"] != want {
			t.Fatalf("1858 local search %q = %#v, want teacher %d", filter, list, want)
		}
	}
}

func TestI9_10FMentorDailyApplicationLimit(t *testing.T) {
	p := pool(t)
	service := mentorService(p)
	student := mentorActor(t, p, 20)
	targets := []identity.ActorContext{mentorActor(t, p, 60), mentorActor(t, p, 60), mentorActor(t, p, 60), mentorActor(t, p, 60)}
	for index := 0; index < 3; index++ {
		expectMentorOK(t, mentorCall(t, service, student, 1857, map[string]any{"to_player_id": int64(targets[index].PlayerID), "relation_type": int64(1), "msg": ""}), 1857)
	}
	expectMentorRefusal(t, mentorCall(t, service, student, 1857, map[string]any{"to_player_id": int64(targets[3].PlayerID), "relation_type": int64(1), "msg": ""}), 1857, 34008)
}

func TestI9_10FMentorGraduationExamAndClaim(t *testing.T) {
	p := pool(t)
	service := mentorService(p)
	teacher := mentorActor(t, p, 60)
	student := mentorActor(t, p, 20)
	expectMentorOK(t, mentorCall(t, service, student, 1857, map[string]any{"to_player_id": int64(teacher.PlayerID), "relation_type": int64(1), "msg": ""}), 1857)
	expectMentorOK(t, mentorCall(t, service, teacher, 1859, map[string]any{"from_player_id": int64(student.PlayerID)}), 1859)
	exec(t, p, `UPDATE player_progression SET level=90 WHERE player_id=$1`, int64(student.PlayerID))
	exec(t, p, `UPDATE player_directory_profiles SET lev=90 WHERE player_id=$1`, int64(student.PlayerID))

	exam := expectMentorOK(t, mentorCall(t, service, student, 1863, map[string]any{"is_win": int64(1), "formation": "1|2|3"}), 1863)
	items, _ := exam["items"].([]map[string]any)
	if len(items) != 3 || items[0]["item_id"] == nil || items[0]["item_num"] == nil {
		t.Fatalf("1863 items %#v", exam)
	}
	expectMentorRefusal(t, mentorCall(t, service, student, 1863, map[string]any{"is_win": int64(1), "formation": "1|2|3"}), 1863, 30005)

	claim := expectMentorOK(t, mentorCall(t, service, student, 1862, map[string]any{"mission_id": int64(100025)}), 1862)
	if awards, _ := claim["awards"].([]map[string]any); len(awards) == 0 {
		t.Fatalf("1862 awards %#v", claim)
	}
	var active int
	if err := p.Raw().QueryRow(ctx, `SELECT count(*) FROM mentor_relations WHERE student_id=$1 AND ended_at IS NULL`, int64(student.PlayerID)).Scan(&active); err != nil || active != 0 {
		t.Fatalf("graduation did not end relation: %d %v", active, err)
	}
	teacherInfo := expectMentorOK(t, mentorCall(t, service, teacher, 1856, map[string]any{}), 1856)
	mentorMissions := teacherInfo["mission_list"].([]any)[0].([]any)
	graduated := false
	for _, raw := range mentorMissions {
		row := raw.(map[string]any)
		if row["table_id"] == int64(100001) && row["progress"] == int64(1) && row["is_complete"] == int64(1) {
			graduated = true
		}
	}
	if !graduated {
		t.Fatalf("mentor graduated high-water missing: %#v", mentorMissions)
	}
	expectMentorRefusal(t, mentorCall(t, service, student, 1862, map[string]any{"mission_id": int64(100025)}), 1862, 33002)
}

func TestI9_10FFunction50Kind8Gate(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	revision, err := (contentstore.Store{Queryer: p}).ActiveRevision(ctx, p)
	if err != nil {
		t.Fatal(err)
	}
	nobody := mentorActorOn(t, p, server, 10)
	exec(t, p, `INSERT INTO player_function_state_owners(player_id,state_version,updated_at)VALUES($1,1,clock_timestamp())`, int64(nobody.PlayerID))
	service := appi5.Service{Runner: tx.Runner{DB: p}, Store: i5store.Store{Queryer: p}, Content: contentstore.Store{Queryer: p}, Privileges: appi5.BaselinePrivilegeProvider{}, Functions: appi5.LevelFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: i5store.Store{Queryer: p}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, ServerLevels: i5store.Store{Queryer: p}, RedeemSecret: []byte("i9-10f-test-redeem-key-0000000000")}
	transaction, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	opened, err := service.OpenCharacterFunctionsTx(ctx, transaction, nobody.PlayerID, revision, time.Now().UTC())
	if err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	for _, id := range opened {
		if id == 50 {
			t.Fatal("function 50 opened with no server player at level 60")
		}
	}
	_ = mentorActorOn(t, p, server, 60)
	transaction, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	opened, err = service.OpenCharacterFunctionsTx(ctx, transaction, nobody.PlayerID, revision, time.Now().UTC())
	if err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	opened50 := false
	for _, id := range opened {
		opened50 = opened50 || id == 50
	}
	if !opened50 {
		t.Fatalf("function 50 did not open after a server player reached 60: %v", opened)
	}
}

func TestI9_10FMentorDenyBondAndLoginProjection(t *testing.T) {
	p := pool(t)
	service := mentorService(p)
	teacher := mentorActor(t, p, 60)
	student := mentorActor(t, p, 20)

	expectMentorOK(t, mentorCall(t, service, student, 1857, map[string]any{"to_player_id": int64(teacher.PlayerID), "relation_type": int64(1), "msg": "please"}), 1857)
	expectMentorOK(t, mentorCall(t, service, teacher, 1860, map[string]any{"from_player_id": int64(student.PlayerID)}), 1860)
	afterDeny := expectMentorOK(t, mentorCall(t, service, teacher, 1856, map[string]any{}), 1856)
	if list := afterDeny["apply_list"].([]any); len(list) != 0 {
		t.Fatalf("deny left rows: %#v", afterDeny)
	}
	expectMentorOK(t, mentorCall(t, service, student, 1857, map[string]any{"to_player_id": int64(teacher.PlayerID), "relation_type": int64(1), "msg": ""}), 1857)
	expectMentorOK(t, mentorCall(t, service, teacher, 1859, map[string]any{"from_player_id": int64(student.PlayerID)}), 1859)

	at := time.Now().UTC()
	transaction, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = service.AddDailyBondTx(ctx, transaction, teacher.PlayerID, student.PlayerID, at); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	transaction, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = service.AddDailyBondTx(ctx, transaction, teacher.PlayerID, student.PlayerID, at.Add(time.Hour)); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	info := expectMentorOK(t, mentorCall(t, service, student, 1856, map[string]any{}), 1856)
	base := info["base_info"].(map[string]any)
	if base["intimacies"].([]any)[0] != int64(100) || base["daily_intimacy_add"].([]any)[0] != int64(1) {
		t.Fatalf("bond after one day %#v", base)
	}

	transaction, err = p.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	detail := map[string]any{}
	if err = (mentorstore.BootstrapProjection{Service: service}).OverlayMID1(ctx, transaction, teacher, false, at, detail); err != nil {
		t.Fatal(err)
	}
	embedded, ok := detail["1856"].(map[string]any)
	if !ok {
		t.Fatalf("login 1856 %#v", detail)
	}
	relations := embedded["base_info"].(map[string]any)["relations"].([]any)
	if relations[1].(map[string]any)["player_id"] != int64(student.PlayerID) {
		t.Fatalf("login 1856 relation %#v", relations)
	}
}

func expectSameMentorReply(t *testing.T, mid uint16, first, replay map[string]any) {
	t.Helper()
	encodedFirst, err := json.Marshal(first)
	if err != nil {
		t.Fatal(err)
	}
	encodedReplay, err := json.Marshal(replay)
	if err != nil {
		t.Fatal(err)
	}
	if string(encodedFirst) != string(encodedReplay) {
		t.Fatalf("MID %d exact-operation replay drifted: %s vs %s", mid, encodedFirst, encodedReplay)
	}
}

func mentorReceiptCount(t *testing.T, p *pg.Pool, player identity.PlayerID, command string, op operation.Context) int64 {
	t.Helper()
	var count int64
	if err := p.QueryRow(ctx, `SELECT count(*) FROM gxb_operation_receipts WHERE owner_kind='player' AND owner_key=$1 AND domain=$2 AND operation=$3 AND semantic_key=$4`, fmt.Sprint(int64(player)), appmentor.ReceiptDomain, command, op.ID.String()).Scan(&count); err != nil {
		t.Fatal(err)
	}
	return count
}

func mentorRelationCount(t *testing.T, p *pg.Pool, mentor, student identity.PlayerID, active bool) int64 {
	t.Helper()
	condition := "ended_at IS NOT NULL"
	if active {
		condition = "ended_at IS NULL"
	}
	var count int64
	if err := p.QueryRow(ctx, `SELECT count(*) FROM mentor_relations WHERE mentor_id=$1 AND student_id=$2 AND `+condition, int64(mentor), int64(student)).Scan(&count); err != nil {
		t.Fatal(err)
	}
	return count
}

// TestI9_10FMentorExactOperationRetry replays each state-changing mentor
// command with the same operation context through the production dispatcher.
func TestI9_10FMentorExactOperationRetry(t *testing.T) {
	p := pool(t)
	service := mentorService(p)

	apply := func(actor identity.ActorContext, target identity.PlayerID) {
		t.Helper()
		expectMentorOK(t, mentorCall(t, service, actor, 1857, map[string]any{"to_player_id": int64(target), "relation_type": int64(1), "msg": "retry"}), 1857)
	}
	accept := func(actor identity.ActorContext, from identity.PlayerID) {
		t.Helper()
		expectMentorOK(t, mentorCall(t, service, actor, 1859, map[string]any{"from_player_id": int64(from)}), 1859)
	}

	t.Run("1858 refusal", func(t *testing.T) {
		actor := mentorActor(t, p, 20)
		response := mentorCallWith(t, service, actor, 1858, map[string]any{"relation_type": int64(3)}, mentorOperation(t, p))
		if response.HTTPStatus != 400 {
			t.Fatalf("1858 malformed relation_type status=%d body=%v", response.HTTPStatus, response.Body)
		}
	})

	t.Run("1857 apply", func(t *testing.T) {
		teacher := mentorActor(t, p, 60)
		student := mentorActor(t, p, 20)
		op := mentorOperation(t, p)
		params := func() map[string]any {
			return map[string]any{"to_player_id": int64(teacher.PlayerID), "relation_type": int64(1), "msg": "retry"}
		}
		first := expectMentorOK(t, mentorCallWith(t, service, student, 1857, params(), op), 1857)
		replay := expectMentorOK(t, mentorCallWith(t, service, student, 1857, params(), op), 1857)
		expectSameMentorReply(t, 1857, first, replay)
		if count := mentorReceiptCount(t, p, student.PlayerID, "apply", op); count != 1 {
			t.Fatalf("apply receipts=%d", count)
		}
		var applications int64
		if err := p.QueryRow(ctx, `SELECT count(*) FROM mentor_applications WHERE applicant_id=$1 AND target_id=$2`, int64(student.PlayerID), int64(teacher.PlayerID)).Scan(&applications); err != nil || applications != 1 {
			t.Fatalf("applications=%d err=%v", applications, err)
		}
	})

	t.Run("1859 accept", func(t *testing.T) {
		teacher := mentorActor(t, p, 60)
		student := mentorActor(t, p, 20)
		apply(student, teacher.PlayerID)
		op := mentorOperation(t, p)
		params := func() map[string]any { return map[string]any{"from_player_id": int64(student.PlayerID)} }
		first := expectMentorOK(t, mentorCallWith(t, service, teacher, 1859, params(), op), 1859)
		replay := expectMentorOK(t, mentorCallWith(t, service, teacher, 1859, params(), op), 1859)
		expectSameMentorReply(t, 1859, first, replay)
		if count := mentorReceiptCount(t, p, teacher.PlayerID, "accept", op); count != 1 {
			t.Fatalf("accept receipts=%d", count)
		}
		if count := mentorRelationCount(t, p, teacher.PlayerID, student.PlayerID, true); count != 1 {
			t.Fatalf("active relations=%d", count)
		}
	})

	t.Run("1860 deny", func(t *testing.T) {
		teacher := mentorActor(t, p, 60)
		student := mentorActor(t, p, 20)
		apply(student, teacher.PlayerID)
		op := mentorOperation(t, p)
		params := func() map[string]any { return map[string]any{"from_player_id": int64(student.PlayerID)} }
		first := expectMentorOK(t, mentorCallWith(t, service, teacher, 1860, params(), op), 1860)
		replay := expectMentorOK(t, mentorCallWith(t, service, teacher, 1860, params(), op), 1860)
		expectSameMentorReply(t, 1860, first, replay)
		if count := mentorReceiptCount(t, p, teacher.PlayerID, "deny", op); count != 1 {
			t.Fatalf("deny receipts=%d", count)
		}
		var status string
		if err := p.QueryRow(ctx, `SELECT status FROM mentor_applications WHERE applicant_id=$1 AND target_id=$2`, int64(student.PlayerID), int64(teacher.PlayerID)).Scan(&status); err != nil || status != "DENIED" {
			t.Fatalf("application status=%q err=%v", status, err)
		}
	})

	t.Run("1861 terminate", func(t *testing.T) {
		teacher := mentorActor(t, p, 60)
		student := mentorActor(t, p, 20)
		apply(student, teacher.PlayerID)
		accept(teacher, student.PlayerID)
		exec(t, p, `UPDATE mentor_relations SET accepted_at=accepted_at-interval '25 hours' WHERE mentor_id=$1 AND student_id=$2 AND ended_at IS NULL`, int64(teacher.PlayerID), int64(student.PlayerID))
		op := mentorOperation(t, p)
		params := func() map[string]any { return map[string]any{"relation_type": int64(2)} }
		first := expectMentorOK(t, mentorCallWith(t, service, teacher, 1861, params(), op), 1861)
		replay := expectMentorOK(t, mentorCallWith(t, service, teacher, 1861, params(), op), 1861)
		expectSameMentorReply(t, 1861, first, replay)
		if count := mentorReceiptCount(t, p, teacher.PlayerID, "terminate", op); count != 1 {
			t.Fatalf("terminate receipts=%d", count)
		}
		if count := mentorRelationCount(t, p, teacher.PlayerID, student.PlayerID, true); count != 0 {
			t.Fatalf("active relations=%d", count)
		}
		if count := mentorRelationCount(t, p, teacher.PlayerID, student.PlayerID, false); count != 1 {
			t.Fatalf("ended relations=%d", count)
		}
	})

	t.Run("1863 exam and 1862 claim", func(t *testing.T) {
		teacher := mentorActor(t, p, 60)
		student := mentorActor(t, p, 20)
		apply(student, teacher.PlayerID)
		accept(teacher, student.PlayerID)
		exec(t, p, `UPDATE player_progression SET level=90 WHERE player_id=$1`, int64(student.PlayerID))
		exec(t, p, `UPDATE player_directory_profiles SET lev=90 WHERE player_id=$1`, int64(student.PlayerID))

		examOp := mentorOperation(t, p)
		examParams := func() map[string]any { return map[string]any{"is_win": int64(1), "formation": "1|2|3"} }
		firstExam := expectMentorOK(t, mentorCallWith(t, service, student, 1863, examParams(), examOp), 1863)
		replayExam := expectMentorOK(t, mentorCallWith(t, service, student, 1863, examParams(), examOp), 1863)
		expectSameMentorReply(t, 1863, firstExam, replayExam)
		if count := mentorReceiptCount(t, p, student.PlayerID, "exam", examOp); count != 1 {
			t.Fatalf("exam receipts=%d", count)
		}

		claimOp := mentorOperation(t, p)
		claimParams := func() map[string]any { return map[string]any{"mission_id": int64(100025)} }
		firstClaim := expectMentorOK(t, mentorCallWith(t, service, student, 1862, claimParams(), claimOp), 1862)
		replayClaim := expectMentorOK(t, mentorCallWith(t, service, student, 1862, claimParams(), claimOp), 1862)
		expectSameMentorReply(t, 1862, firstClaim, replayClaim)
		if count := mentorReceiptCount(t, p, student.PlayerID, "claim", claimOp); count != 1 {
			t.Fatalf("claim receipts=%d", count)
		}
		if count := mentorRelationCount(t, p, teacher.PlayerID, student.PlayerID, true); count != 0 {
			t.Fatalf("graduation left active relations=%d", count)
		}
	})
}

// A player with no class gets no complete unawarded mission from 1856, so the
// Social > My Class red dot stays off. A student in a class still gets it.
func TestI9_10FNoRelationHasNoClassRedDot(t *testing.T) {
	p := pool(t)
	service := mentorService(p)
	solo := mentorActor(t, p, 85)

	alone := expectMentorOK(t, mentorCall(t, service, solo, 1856, map[string]any{}), 1856)
	if applications, _ := alone["apply_list"].([]any); len(applications) != 0 {
		t.Fatalf("1856 apply_list without relation %#v", applications)
	}
	requireNoClaimableClassMission(t, alone)

	teacher := mentorActor(t, p, 90)
	expectMentorOK(t, mentorCall(t, service, solo, 1857, map[string]any{"to_player_id": int64(teacher.PlayerID), "relation_type": int64(1), "msg": ""}), 1857)
	expectMentorOK(t, mentorCall(t, service, teacher, 1859, map[string]any{"from_player_id": int64(solo.PlayerID)}), 1859)

	inClass := expectMentorOK(t, mentorCall(t, service, solo, 1856, map[string]any{}), 1856)
	studentMissions, _ := inClass["mission_list"].([]any)
	requireCompleteUnawardedMission(t, studentMissions[len(studentMissions)-1], 100024)
}

func requireNoClaimableClassMission(t *testing.T, info map[string]any) {
	t.Helper()
	lists, _ := info["mission_list"].([]any)
	for _, raw := range lists {
		missions, _ := raw.([]any)
		for _, mission := range missions {
			row := mission.(map[string]any)
			if row["is_complete"] == int64(1) && row["is_awarded"] == int64(0) {
				t.Fatalf("complete unawarded class mission without relation: %#v", row)
			}
		}
	}
}

func requireCompleteUnawardedMission(t *testing.T, raw any, missionID int64) {
	t.Helper()
	missions, _ := raw.([]any)
	for _, mission := range missions {
		row := mission.(map[string]any)
		if row["table_id"] == missionID && row["is_complete"] == int64(1) && row["is_awarded"] == int64(0) {
			return
		}
	}
	t.Fatalf("mission %d complete unawarded missing from student list", missionID)
}

// TestI9_10FMentorDailyApplyReadNormalisesAtTheGameDayBoundary is BUGS #97: the client gates its
// send button on this read, so a count left from yesterday locks the feature until a write resets it.
func TestI9_10FMentorDailyApplyReadNormalisesAtTheGameDayBoundary(t *testing.T) {
	p := pool(t)
	service := mentorService(p)
	student := mentorActor(t, p, 20)
	targets := []identity.ActorContext{mentorActor(t, p, 60), mentorActor(t, p, 60), mentorActor(t, p, 60), mentorActor(t, p, 60)}
	boundary := nextGameDayBoundary(time.Now().UTC())
	service.Timed.Binder.Time = fixedTime{at: boundary.Add(-time.Second)}
	for index := 0; index < 3; index++ {
		expectMentorOK(t, mentorCall(t, service, student, 1857, map[string]any{"to_player_id": int64(targets[index].PlayerID), "relation_type": int64(1), "msg": ""}), 1857)
	}
	before := expectMentorOK(t, mentorCall(t, service, student, 1856, map[string]any{}), 1856)
	if got := dailyApplyTimes(t, before); !reflect.DeepEqual(got, []any{int64(3), int64(0)}) {
		t.Fatalf("04:59:59 GMT+8 daily_apply_times %v", got)
	}

	service.Timed.Binder.Time = fixedTime{at: boundary}
	after := expectMentorOK(t, mentorCall(t, service, student, 1856, map[string]any{}), 1856)
	if got := dailyApplyTimes(t, after); !reflect.DeepEqual(got, []any{int64(0), int64(0)}) {
		t.Fatalf("05:00:00 GMT+8 daily_apply_times stayed stale: %v", got)
	}
	expectMentorOK(t, mentorCall(t, service, student, 1857, map[string]any{"to_player_id": int64(targets[3].PlayerID), "relation_type": int64(1), "msg": ""}), 1857)
}

// An evening application is already on the next GMT+8 game day; the stored marker must be that day, so the read the
// next morning does not reset it and grant an extra day of applications.
func TestI9_10FMentorEveningApplicationKeepsTheNextGameDay(t *testing.T) {
	p := pool(t)
	service := mentorService(p)
	student := mentorActor(t, p, 20)
	target := mentorActor(t, p, 60)
	service.Timed.Binder.Time = fixedTime{at: time.Date(2026, 11, 10, 22, 0, 0, 0, time.UTC)}
	expectMentorOK(t, mentorCall(t, service, student, 1857, map[string]any{"to_player_id": int64(target.PlayerID), "relation_type": int64(1), "msg": ""}), 1857)
	service.Timed.Binder.Time = fixedTime{at: time.Date(2026, 11, 11, 10, 0, 0, 0, time.UTC)}
	info := expectMentorOK(t, mentorCall(t, service, student, 1856, map[string]any{}), 1856)
	if got := dailyApplyTimes(t, info); !reflect.DeepEqual(got, []any{int64(1), int64(0)}) {
		t.Fatalf("evening application was reset inside its own game day: %v", got)
	}
}

// A legacy row written before 21:00 UTC stores UTC date D; the first read after the new 05:00 GMT+8 boundary
// (21:00 UTC on D) must project zero, the same day-keyed reset the apply command performs.
func TestI9_10FMentorSwitchResetsALegacyDayAtTheNewBoundary(t *testing.T) {
	p := pool(t)
	service := mentorService(p)
	student := mentorActor(t, p, 20)
	exec(t, p, `INSERT INTO mentor_states(player_id,logical_server_id,apply_day,apply_count_mentor,apply_count_student,state_version)VALUES($1,$2,'2026-11-10',3,0,1)`, int64(student.PlayerID), int32(student.LogicalServerID))
	service.Timed.Binder.Time = fixedTime{at: time.Date(2026, 11, 10, 20, 59, 59, 0, time.UTC)}
	before := expectMentorOK(t, mentorCall(t, service, student, 1856, map[string]any{}), 1856)
	if got := dailyApplyTimes(t, before); !reflect.DeepEqual(got, []any{int64(3), int64(0)}) {
		t.Fatalf("04:59:59 GMT+8 daily_apply_times %v", got)
	}
	service.Timed.Binder.Time = fixedTime{at: time.Date(2026, 11, 10, 21, 0, 0, 0, time.UTC)}
	after := expectMentorOK(t, mentorCall(t, service, student, 1856, map[string]any{}), 1856)
	if got := dailyApplyTimes(t, after); !reflect.DeepEqual(got, []any{int64(0), int64(0)}) {
		t.Fatalf("05:00:00 GMT+8 daily_apply_times stayed stale: %v", got)
	}
}

func nextGameDayBoundary(now time.Time) time.Time {
	boundary := time.Date(now.Year(), now.Month(), now.Day(), 21, 0, 0, 0, time.UTC)
	if !boundary.After(now) {
		boundary = boundary.Add(24 * time.Hour)
	}
	return boundary
}

func dailyApplyTimes(t *testing.T, info map[string]any) []any {
	t.Helper()
	base, _ := info["base_info"].(map[string]any)
	times, _ := base["daily_apply_times"].([]any)
	return times
}
