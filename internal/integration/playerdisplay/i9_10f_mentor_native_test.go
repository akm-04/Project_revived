//go:build postgres

package playerdisplay_test

import (
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
	}
}

func mentorCall(t *testing.T, service appmentor.Service, actor identity.ActorContext, mid uint16, params map[string]any) httpedge.Response {
	t.Helper()
	revision, err := (contentstore.Store{Queryer: poolForService}).ActiveRevision(ctx, poolForService)
	if err != nil {
		t.Fatal(err)
	}
	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: revision})
	if err != nil {
		t.Fatal(err)
	}
	at := time.Now().UTC()
	params["token"] = "bearer"
	params["region"] = int64(actor.LogicalServerID)
	op := operation.Context{ID: uuid(), StartedAt: at, Policies: policies}
	request := httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{Operation: op, MID: mid, ReceivedAt: at, Params: params, Claims: wire.CredentialClaims{Token: "bearer", Region: int64(actor.LogicalServerID)}}}
	dispatcher := stockruntime.MentorDispatcher{Authority: unpinnedDispatchAuthority{actor: actor}, Service: service}
	return dispatcher.Dispatch(ctx, request)
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
	teacher := mentorActor(t, p, 60)
	student := mentorActor(t, p, 20)

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
