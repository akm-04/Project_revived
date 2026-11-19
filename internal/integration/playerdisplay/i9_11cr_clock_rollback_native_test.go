//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/bookstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	ps "gxb.local/backend/v2/internal/adapters/postgres/commerceprivilegestore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/bookskill"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	cp "gxb.local/backend/v2/internal/application/commerceprivilege"
	"gxb.local/backend/v2/internal/application/dormhouse"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	spiritapp "gxb.local/backend/v2/internal/application/spirit"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

func clockRollbackCredentials(t *testing.T, p *pg.Pool, a identity.ActorContext, secret []byte) (string, string) {
	t.Helper()
	sidRaw := "i9-11cr-sid-" + a.SessionID.UUID().String()
	loginRaw := "i9-11cr-login-" + a.SessionID.UUID().String()
	exec(t, p, `UPDATE account_sessions SET auth_profile='SID_LOGIN_TOKEN_PAIR',last_activity_at=clock_timestamp() WHERE session_id=$1`, a.SessionID.UUID().String())
	exec(t, p, `DELETE FROM gameplay_contexts WHERE session_id=$1`, a.SessionID.UUID().String())
	for _, credential := range []struct{ kind, label, raw string }{{"SID", "sid", sidRaw}, {"LOGIN_TOKEN", "login_token", loginRaw}} {
		digest, e := identity.DigestCredential(secret, credential.label, credential.raw)
		if e != nil {
			t.Fatal(e)
		}
		exec(t, p, `INSERT INTO account_session_credentials(credential_id,session_id,kind,digest,issued_at)VALUES($1,$2,$3,$4,clock_timestamp()-interval '1 hour')`,
			uuid().String(), a.SessionID.UUID().String(), credential.kind, digest[:])
	}
	return sidRaw, loginRaw
}

func clockRollbackService(p *pg.Pool, clock *i911cFixedClock, secret []byte) i4store.BootstrapService {
	i5svc := missionOwner(p)
	mission := appi5.MissionBootstrap{Owner: i5svc}
	return i4store.BootstrapService{
		Runner:                  tx.Runner{DB: p},
		Receipts:                kernelstore.Store{},
		ReceiptReader:           kernelstore.Reader{Queryer: p},
		DigestSecret:            secret,
		BearerSecret:            secret,
		DerivationKeyID:         "i9-11cr-native",
		BootstrapProfileVersion: "i9-11cr-native",
		LoginTime:               clock,
		LoginReconcilers:        []appboot.CharacterLoginReconciler{mission},
		DetailContributors: []appboot.MID1DetailContributor{
			mission,
			cp.BootstrapProjection{Provider: privilegeProvider(p)},
			i5store.BootstrapProjection{
				Content:      contentstore.Store{Queryer: p},
				Privileges:   privilegeProvider(p),
				MaxHeroColor: appi5.PreservationMaxHeroColorProvider{},
				BackpackSort: characterstore.Store{Queryer: p},
			},
		},
	}
}

func clockRollbackLogin(t *testing.T, dispatcher stockruntime.BootstrapDispatcher, sidRaw, loginRaw string, at time.Time, seed byte) httpedge.Response {
	t.Helper()
	return dispatcher.Dispatch(ctx, httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{
		MID:       1,
		Operation: i911cFixedOperation(at, seed),
		Params:    map[string]any{"sid": sidRaw, "login_token": loginRaw, "region": int64(1)},
	}})
}

// A privilege root written before a backwards clock step (stored at T+8h) must
// not block login at T, and the reply still carries the frozen MID1 details 17
// and 160 (I9_11_CLOCK_ROLLBACK_V1 K2/K5).
func TestI9_11CRClockRollbackKeepsLoginAndMonotonePrivilegeWrites(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	secret := []byte("i9-11cr-native-digest-key-00000001")
	sidRaw, loginRaw := clockRollbackCredentials(t, p, a, secret)

	at := time.Now().UTC().Truncate(time.Microsecond)
	clock := &i911cFixedClock{at: at}
	exec(t, p, `INSERT INTO commerce_privilege_roots(player_id,logical_server_id,qualifying_charge,vip_level,monthly_state,content_revision,policy_version,origin_class,issuer,reason,state_version,created_at,updated_at)
VALUES($1,$2,0,0,'QUALIFIED_ABSENT',$3,$4,$5,'clock-rollback-native','clock-rollback-native',1,$6,$7)`,
		int64(a.PlayerID), int64(a.LogicalServerID), rev, d.ManualPolicy, d.ManualClass, at.Add(-time.Hour), at.Add(8*time.Hour))
	exec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'glue',7,1,$2)
ON CONFLICT(player_id,resource_key) DO UPDATE SET amount=excluded.amount,updated_at=excluded.updated_at`, int64(a.PlayerID), at.Add(8*time.Hour))

	service := clockRollbackService(p, clock, secret)
	dispatcher := stockruntime.BootstrapDispatcher{Bootstrap: service}
	if _, e := service.MID1(ctx, appboot.RuntimeMID1Request{Credentials: appboot.AccountCredentials{SID: sidRaw, LoginToken: loginRaw}, Region: 1, Operation: i911cFixedOperation(at, 9)}); e != nil {
		t.Fatalf("direct login: %v", e)
	}
	response := clockRollbackLogin(t, dispatcher, sidRaw, loginRaw, at, 1)
	if response.HTTPStatus != 200 {
		t.Fatalf("rollback login status %d body %#v", response.HTTPStatus, response.Body)
	}
	detail, ok := response.Body["detail"].(map[string]any)
	if !ok {
		t.Fatalf("detail %T", response.Body["detail"])
	}
	if _, ok := detail["17"].(map[string]any); !ok {
		t.Fatalf("detail 17 missing: %#v", detail)
	}
	if _, ok := detail["160"]; !ok {
		t.Fatalf("detail 160 missing: %#v", detail)
	}

	// A later privilege write keeps the stored forward timestamp (K3).
	provider := ps.Store{}
	stored, known, e := provider.ReadPrivilegeTx(ctx, p, a.PlayerID, false)
	if e != nil || !known {
		t.Fatal(stored, known, e)
	}
	if stored.UpdatedAt.Before(at.Add(8*time.Hour)) || stored.UpdatedAt.Before(stored.CreatedAt) {
		t.Fatalf("seed timestamps %+v", stored)
	}
	manual := privilegeService(p, p)
	request := cp.Import{PlayerID: a.PlayerID, LogicalServerID: a.LogicalServerID, CommandKey: uuid().String(), Charge: 100, MonthlyState: d.MonthlyAbsent}
	written, e := manual.ImportManual(ctx, authority(), request, opPinned(rev))
	if e != nil {
		t.Fatal(e)
	}
	if written.State.UpdatedAt.Before(at.Add(8*time.Hour)) || written.State.CreatedAt.After(written.State.UpdatedAt) {
		t.Fatalf("monotone write %+v", written.State)
	}

	// A genuinely malformed row (UpdatedAt < CreatedAt) is refused by the domain
	// snapshot validator; the shared R4 mapper turns that sentinel into 409/35028
	// (TestR4Part4SharedFailureRows). The table CHECK constraint makes the row
	// impossible to store, so this half is proven at the domain/mapper boundary.
	malformed := d.Snapshot{State: stored, ObservationRevision: rev, ObservedAt: at, SkillPointCap: 10, ProviderRevision: d.ManualPolicy + "/" + rev}
	malformed.State.UpdatedAt = malformed.State.CreatedAt.Add(-time.Second)
	if e := malformed.Validate(a.PlayerID, rev, at); e == nil {
		t.Fatal("malformed root accepted")
	}
}

// The fixed MID1 roster overlays keep reading a row written before a backwards
// clock step instead of refusing it (I9_11_CLOCK_ROLLBACK_V1 K2). Each overlay
// is exercised through its production application service and store.
func TestI9_11CROverlayInputsObserveForwardDatedRows(t *testing.T) {
	p := pool(t)
	at := time.Now().UTC().Truncate(time.Microsecond)
	forward := at.Add(8 * time.Hour)

	bookActor, bookRevision, books := bookFixture(t, p)
	transaction, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	if e = (bookstore.Store{}).EnsureRootTx(ctx, transaction, bookActor.PlayerID, bookRevision, at); e != nil {
		_ = transaction.Rollback(ctx)
		t.Fatal(e)
	}
	if e = transaction.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	exec(t, p, `UPDATE player_book_roots SET updated_at=$2 WHERE player_id=$1`, int64(bookActor.PlayerID), forward)
	if _, e = books.BookInputsTx(ctx, p, bookskill.InputScope{Player: bookActor.PlayerID, ContentRevision: bookRevision, ObservedAt: at}); e != nil {
		t.Fatalf("book overlay refused a forward-dated row: %v", e)
	}

	dormActor, dormRevision, _ := dormFixture(t, p)
	exec(t, p, `UPDATE player_dorm_roots SET updated_at=$2 WHERE player_id=$1`, int64(dormActor.PlayerID), forward)
	exec(t, p, `UPDATE player_hero_roots SET updated_at=$2 WHERE player_id=$1`, int64(dormActor.PlayerID), forward)
	if _, e = dormService(p, p).DormHouseInputsTx(ctx, p, dormhouse.InputScope{Player: dormActor.PlayerID, ContentRevision: dormRevision, ObservedAt: at}, character.HeroRef{PlayerID: dormActor.PlayerID, PartnerID: 1}); e != nil {
		t.Fatalf("dorm overlay refused a forward-dated row: %v", e)
	}

	spiritActor, spiritRevision, spiritService := spiritFixture(t, p)
	exec(t, p, `UPDATE player_spirit_roots SET updated_at=$2 WHERE player_id=$1`, int64(spiritActor.PlayerID), forward)
	if _, e = spiritService.InventoryTx(ctx, p, spiritapp.InputScope{Player: spiritActor.PlayerID, ContentRevision: spiritRevision, ObservedAt: at}); e != nil {
		t.Fatalf("spirit overlay refused a forward-dated row: %v", e)
	}
}
