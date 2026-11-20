//go:build postgres && socialintegration

package socialactivation_test

import (
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/mentorstore"
	"gxb.local/backend/v2/internal/adapters/socialpresentation"
	appmentor "gxb.local/backend/v2/internal/application/mentor"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func giftMentorService(f *fixture) appmentor.Service {
	return appmentor.Service{
		Store:     mentorstore.Store{},
		Directory: i4store.TransactionDiscoveryReader{},
		Cards:     socialpresentation.TransactionReader{},
		Content:   contentstore.Store{Queryer: f.p},
		Receipts:  kernelstore.Store{},
	}
}

// A class pair's gift reads the raised bond in the same transaction and serves
// the freshBaseInfo shape SocialSystem.lua:451-454 refreshes from.
func Test7A_ClassPairGiftCarriesMasterInfo(t *testing.T) {
	f := fresh(t)
	f.sql(`TRUNCATE social_gift_epochs CASCADE`)
	f.sql(`TRUNCATE gxb_operation_receipts CASCADE`)
	student, teacher := identity.PlayerID(100001), identity.PlayerID(100002)
	f.player(student)
	f.player(teacher)
	f.friend(student, teacher)
	_, token := f.live(student)
	f.live(teacher)
	if _, e := registry.Initialize(ctx, registry.Service{Runner: tx.Runner{DB: f.p}, Repo: contentstore.Store{}, Fresh: f.p, Providers: registry.DefaultProviderSet()}, operation.Factory{Clock: clock.System{}}); e != nil {
		t.Fatal(e)
	}
	revision, e := (contentstore.Store{Queryer: f.p}).ActiveRevision(ctx, f.p)
	if e != nil {
		t.Fatal(e)
	}
	f.sql(`INSERT INTO mentor_relations(relation_id,logical_server_id,mentor_id,student_id,content_revision,policy_version,accepted_at,intimacy,state_version) VALUES(gen_random_uuid(),1,$1,$2,$3,'I9_MENTOR_LEVEL_GAP_AT_LEAST_V1',$4,0,1)`, int64(teacher), int64(student), revision, f.now())

	mentor := giftMentorService(f)
	service := f.gift()
	service.Bond = mentor
	service.ClassInfo = mentor
	dispatcher, _, _, _ := f.giftStock(service, f.scalar())
	server := f.giftHTTP(dispatcher)
	defer server.Close()

	status, value := httpRequest(t, server, token, 1, 183, map[string]any{"player_id": int64(teacher)})
	if status != 200 {
		t.Fatalf("status %d body %#v", status, value)
	}
	body := value.(map[string]any)
	master, ok := body["master_info"].(map[string]any)
	if !ok {
		t.Fatalf("master_info %#v", body)
	}
	intimacies, ok := master["intimacies"].([]any)
	if !ok || len(intimacies) != 2 || intimacies[0] != float64(100) {
		t.Fatalf("raised intimacy %#v", master["intimacies"])
	}
	daily, ok := master["daily_intimacy_add"].([]any)
	if !ok || len(daily) != 2 || daily[0] != float64(1) {
		t.Fatalf("daily intimacy add %#v", master["daily_intimacy_add"])
	}
	relations, ok := master["relations"].([]any)
	if !ok || len(relations) != 2 || relations[0].(map[string]any)["player_id"] != float64(teacher) {
		t.Fatalf("relation card %#v", master["relations"])
	}
	if got := f.number(`SELECT intimacy FROM mentor_relations WHERE mentor_id=$1 AND student_id=$2 AND ended_at IS NULL`, int64(teacher), int64(student)); got != 100 {
		t.Fatalf("durable intimacy %d", got)
	}
}
