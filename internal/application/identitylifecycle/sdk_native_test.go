//go:build postgres

package identitylifecycle_test

import (
	"context"
	"errors"
	"fmt"
	"os"
	"strings"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/identitystore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	appidentity "gxb.local/backend/v2/internal/application/identitylifecycle"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var sdkDigestSecret = []byte("0123456789abcdef")

func sdkTestPool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_I11A_G51F_DSN")
	if dsn == "" {
		t.Skip("GXB_I11A_G51F_DSN required (ops/testing/fresh_db.sh g51f)")
	}
	pool, err := pg.Open(context.Background(), dsn, pg.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

func sdkTestService(pool *pg.Pool) appidentity.SDKService {
	return appidentity.SDKService{
		Runner:       tx.Runner{DB: pool},
		Store:        identitystore.Store{},
		DigestSecret: sdkDigestSecret,
		Operations:   operation.Factory{Clock: clock.System{}},
	}
}

func newSDKTestLogin(t *testing.T) string {
	t.Helper()
	value, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return "sdk-" + value.String() + "@example.com"
}

func newSDKTestUUID(t *testing.T) string {
	t.Helper()
	value, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return value.String()
}

// TestSDKRegisterLoginAndTheGameAcceptsTheSession proves the issued SID pair
// through the backend's own stock bootstrap authentication (MID18).
func TestSDKRegisterLoginAndTheGameAcceptsTheSession(t *testing.T) {
	pool := sdkTestPool(t)
	ctx := context.Background()
	service := sdkTestService(pool)
	login := newSDKTestLogin(t)

	registered, err := service.Register(ctx, appidentity.SDKRegisterRequest{Login: login, Password: "secret-1", Repassword: "secret-1"})
	if err != nil {
		t.Fatal(err)
	}
	if registered.UID == "" || registered.LoginEmail != login {
		t.Fatalf("register = %+v", registered)
	}
	again, err := service.Register(ctx, appidentity.SDKRegisterRequest{Login: login, Password: "secret-1", Repassword: "secret-1"})
	if err != nil || again.UID != registered.UID {
		t.Fatalf("same-password register = %+v err=%v, want the existing account", again, err)
	}
	if _, err := service.Register(ctx, appidentity.SDKRegisterRequest{Login: login, Password: "other-1", Repassword: "other-1"}); !errors.Is(err, appidentity.ErrSDKAccountExists) {
		t.Fatalf("other-password register err = %v, want account exists", err)
	}
	if _, err := service.Login(ctx, appidentity.SDKLoginRequest{Login: login, Password: "wrong-1"}); !errors.Is(err, appidentity.ErrSDKInvalidAccount) {
		t.Fatalf("wrong password err = %v", err)
	}
	if _, err := service.Login(ctx, appidentity.SDKLoginRequest{Login: newSDKTestLogin(t), Password: "secret-1"}); !errors.Is(err, appidentity.ErrSDKInvalidAccount) {
		t.Fatalf("unknown login err = %v", err)
	}

	session, err := service.Login(ctx, appidentity.SDKLoginRequest{Login: login, Password: "secret-1"})
	if err != nil {
		t.Fatal(err)
	}
	if session.UID != registered.UID || session.SID == "" || session.Token == "" || session.Username != login || session.LoginEmail != login {
		t.Fatalf("login = %+v", session)
	}
	bootstrap := i4store.BootstrapService{
		Runner:                  tx.Runner{DB: pool},
		Receipts:                kernelstore.Store{},
		ReceiptReader:           kernelstore.Reader{Queryer: pool},
		DigestSecret:            sdkDigestSecret,
		DerivationKeyID:         "g51f-test",
		BearerSecret:            []byte("abcdefghijklmnop"),
		BootstrapProfileVersion: "g51f-test",
	}
	op, err := operation.Factory{Clock: clock.System{}}.New(policy.Set{})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := bootstrap.MID18(ctx, appboot.AccountCredentials{SID: session.SID, LoginToken: session.Token}, op); err != nil {
		t.Fatalf("the game SID validation refused the issued session: %v", err)
	}
}

func TestSDKLoginIssuesIndependentSessionCredentials(t *testing.T) {
	pool := sdkTestPool(t)
	ctx := context.Background()
	service := sdkTestService(pool)
	login := newSDKTestLogin(t)
	if _, err := service.Register(ctx, appidentity.SDKRegisterRequest{Login: login, Password: "secret-1", Repassword: "secret-1"}); err != nil {
		t.Fatal(err)
	}
	first, err := service.Login(ctx, appidentity.SDKLoginRequest{Login: login, Password: "secret-1"})
	if err != nil {
		t.Fatal(err)
	}
	second, err := service.Login(ctx, appidentity.SDKLoginRequest{Login: login, Password: "secret-1"})
	if err != nil {
		t.Fatal(err)
	}
	if first.SID == second.SID || first.Token == second.Token {
		t.Fatal("two logins reused one session credential")
	}
	sidSecret := strings.TrimPrefix(first.SID, "sdk-sid-")
	tokenSecret := strings.TrimPrefix(first.Token, "sdk-login-")
	if strings.Contains(first.SID, tokenSecret) || strings.Contains(first.Token, sidSecret) {
		t.Fatal("the login token is derivable from the SID")
	}
}

func TestSDKImportCountsPasswordRecordsOutsideTheIterationBounds(t *testing.T) {
	pool := sdkTestPool(t)
	ctx := context.Background()
	uid := newSDKTestUUID(t)
	document := fmt.Sprintf(`{
  "accounts": [{"uid": %q, "type": "normal", "username": "iter-one"}],
  "logins": [
    {"normalized": "iter-high", "display": "iter-high", "account_uid": %q, "algorithm": "pbkdf2-sha256", "iterations": %d, "salt": "00000000000000000000000000000000", "hash": "0000000000000000000000000000000000000000000000000000000000000000"},
    {"normalized": "iter-low", "display": "iter-low", "account_uid": %q, "algorithm": "pbkdf2-sha256", "iterations": %d, "salt": "00000000000000000000000000000000", "hash": "0000000000000000000000000000000000000000000000000000000000000000"}
  ],
  "devices": []
}`, uid, uid, appidentity.SDKPasswordMaximumIterations+1, uid, appidentity.SDKPasswordMinimumIterations-1)
	input, err := appidentity.DecodeSDKImport(strings.NewReader(document))
	if err != nil {
		t.Fatalf("an out-of-range iteration record refused the whole import: %v", err)
	}
	importer := appidentity.SDKImporter{Runner: tx.Runner{DB: pool}, Store: identitystore.Store{}, Operations: operation.Factory{Clock: clock.System{}}}
	result, err := importer.Import(ctx, input)
	if err != nil {
		t.Fatal(err)
	}
	if result.AccountsImported != 1 || result.LoginsImported != 0 || result.Conflicts != 2 {
		t.Fatalf("import = %+v, want two iteration conflicts", result)
	}
}

func TestSDKConcurrentDoubleRegisterKeepsOneAccount(t *testing.T) {
	pool := sdkTestPool(t)
	ctx := context.Background()
	service := sdkTestService(pool)
	login := newSDKTestLogin(t)
	type outcome struct {
		result appidentity.SDKRegisterResult
		err    error
	}
	start := make(chan struct{})
	outcomes := make([]outcome, 2)
	var wait sync.WaitGroup
	for index := range outcomes {
		wait.Add(1)
		go func(index int) {
			defer wait.Done()
			<-start
			outcomes[index].result, outcomes[index].err = service.Register(ctx, appidentity.SDKRegisterRequest{Login: login, Password: "secret-1", Repassword: "secret-1"})
		}(index)
	}
	close(start)
	wait.Wait()
	for _, outcome := range outcomes {
		if outcome.err != nil {
			t.Fatalf("concurrent register err = %v", outcome.err)
		}
	}
	if outcomes[0].result.UID != outcomes[1].result.UID {
		t.Fatalf("concurrent register uids = %q %q", outcomes[0].result.UID, outcomes[1].result.UID)
	}
	var accounts, logins int
	if err := pool.QueryRow(ctx, `SELECT count(*) FROM sdk_logins WHERE login_normalized=$1`, appidentity.NormalizeSDKLogin(login)).Scan(&logins); err != nil {
		t.Fatal(err)
	}
	if err := pool.QueryRow(ctx, `SELECT count(*) FROM accounts WHERE account_uid=$1`, outcomes[0].result.UID).Scan(&accounts); err != nil {
		t.Fatal(err)
	}
	if logins != 1 || accounts != 1 {
		t.Fatalf("rows logins=%d accounts=%d, want one each", logins, accounts)
	}
}

type sdkPasswordSwapStore struct {
	identitystore.Store
	swap func(context.Context)
	once sync.Once
}

func (store *sdkPasswordSwapStore) FindSDKLoginTx(ctx context.Context, query tx.Queryer, normalized string) (*appidentity.SDKLoginRecord, error) {
	record, err := store.Store.FindSDKLoginTx(ctx, query, normalized)
	if err != nil || record == nil {
		return record, err
	}
	store.once.Do(func() { store.swap(ctx) })
	return record, nil
}

// TestSDKLoginRefusesWhenThePasswordChangesBetweenReadAndIssue changes the
// stored password while the first read transaction is still open; the issuing
// transaction re-reads a different salt and hash and must refuse.
func TestSDKLoginRefusesWhenThePasswordChangesBetweenReadAndIssue(t *testing.T) {
	pool := sdkTestPool(t)
	ctx := context.Background()
	login := newSDKTestLogin(t)
	normalized := appidentity.NormalizeSDKLogin(login)
	if _, err := sdkTestService(pool).Register(ctx, appidentity.SDKRegisterRequest{Login: login, Password: "secret-1", Repassword: "secret-1"}); err != nil {
		t.Fatal(err)
	}
	_, _, salt, hash, err := appidentity.HashSDKPassword("changed-1")
	if err != nil {
		t.Fatal(err)
	}
	store := &sdkPasswordSwapStore{swap: func(swapCtx context.Context) {
		if _, err := pool.Raw().Exec(swapCtx, `UPDATE sdk_logins SET password_salt=$2, password_hash=$3, password_changed_at=now() WHERE login_normalized=$1`, normalized, salt, hash); err != nil {
			t.Errorf("swap the stored password: %v", err)
		}
	}}
	service := appidentity.SDKService{Runner: tx.Runner{DB: pool}, Store: store, DigestSecret: sdkDigestSecret, Operations: operation.Factory{Clock: clock.System{}}}
	if _, err := service.Login(ctx, appidentity.SDKLoginRequest{Login: login, Password: "secret-1"}); !errors.Is(err, appidentity.ErrSDKInvalidAccount) {
		t.Fatalf("login after the password changed err = %v, want invalid account", err)
	}
	var sessions int
	if err := pool.QueryRow(ctx, `SELECT count(*) FROM account_sessions WHERE account_id=(SELECT account_id FROM sdk_logins WHERE login_normalized=$1)`, normalized).Scan(&sessions); err != nil {
		t.Fatal(err)
	}
	if sessions != 0 {
		t.Fatalf("a session was issued from the stale password record: %d", sessions)
	}
	if _, err := service.Login(ctx, appidentity.SDKLoginRequest{Login: login, Password: "changed-1"}); err != nil {
		t.Fatalf("the changed password was refused: %v", err)
	}
}

func TestSDKAnonymousByCookieDeviceAndNewGuest(t *testing.T) {
	pool := sdkTestPool(t)
	ctx := context.Background()
	service := sdkTestService(pool)
	device := newSDKTestUUID(t)

	first, err := service.Anonymous(ctx, appidentity.SDKAnonymousRequest{})
	if err != nil {
		t.Fatal(err)
	}
	if !strings.HasPrefix(first.Username, "guest-") || len(first.Username) != len("guest-")+8 || first.LoginEmail != "" {
		t.Fatalf("new guest = %+v", first)
	}
	second, err := service.Anonymous(ctx, appidentity.SDKAnonymousRequest{})
	if err != nil {
		t.Fatal(err)
	}
	if second.UID == first.UID {
		t.Fatal("two cookie-less anonymous calls reused one guest")
	}

	bound, err := service.Anonymous(ctx, appidentity.SDKAnonymousRequest{DeviceID: device})
	if err != nil {
		t.Fatal(err)
	}
	rebound, err := service.Anonymous(ctx, appidentity.SDKAnonymousRequest{DeviceID: device})
	if err != nil {
		t.Fatal(err)
	}
	if bound.UID != rebound.UID || bound.SID == rebound.SID {
		t.Fatalf("device guest = %+v then %+v, want the same account and a new session", bound, rebound)
	}
	byCookie, err := service.Anonymous(ctx, appidentity.SDKAnonymousRequest{CookieSID: rebound.SID})
	if err != nil {
		t.Fatal(err)
	}
	if byCookie.UID != bound.UID || byCookie.SID == rebound.SID {
		t.Fatalf("cookie lookup = %+v, want the device account and a new session", byCookie)
	}
	byFirstCookie, err := service.Anonymous(ctx, appidentity.SDKAnonymousRequest{CookieSID: first.SID})
	if err != nil {
		t.Fatal(err)
	}
	if byFirstCookie.UID != first.UID {
		t.Fatalf("cookie account = %q, want %q", byFirstCookie.UID, first.UID)
	}
	precedence, err := service.Anonymous(ctx, appidentity.SDKAnonymousRequest{CookieSID: first.SID, DeviceID: device})
	if err != nil {
		t.Fatal(err)
	}
	if precedence.UID != first.UID {
		t.Fatalf("cookie should win over the device: %q vs %q", precedence.UID, first.UID)
	}
}

type sdkImportFixture struct {
	document      string
	normal1       string
	password1     string
	guest         string
	guestLogin    string
	guestPassword string
	device        string
}

func buildSDKImportFixture(t *testing.T) sdkImportFixture {
	t.Helper()
	account1, account2, guest := newSDKTestUUID(t), newSDKTestUUID(t), newSDKTestUUID(t)
	first, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	password1, password2, guestPassword := "import-one-"+first.String(), "import-two-"+first.String(), "import-guest-"+first.String()
	_, _, salt1, hash1, err := appidentity.HashSDKPassword(password1)
	if err != nil {
		t.Fatal(err)
	}
	_, _, salt2, hash2, err := appidentity.HashSDKPassword(password2)
	if err != nil {
		t.Fatal(err)
	}
	_, _, salt3, hash3, err := appidentity.HashSDKPassword(guestPassword)
	if err != nil {
		t.Fatal(err)
	}
	device := "device-" + newSDKTestUUID(t)
	normal1 := "import-" + first.String() + "-one"
	normal2 := "import-" + first.String() + "-two"
	guestLogin := "import-" + first.String() + "-guest"
	document := fmt.Sprintf(`{
  "accounts": [
    {"uid": %q, "type": "normal", "username": %q},
    {"uid": %q, "type": "normal", "username": %q},
    {"uid": %q, "type": "guest", "username": %q}
  ],
  "logins": [
    {"normalized": %q, "display": %q, "account_uid": %q, "algorithm": "pbkdf2-sha256", "iterations": 200000, "salt": %q, "hash": %q},
    {"normalized": %q, "display": %q, "account_uid": %q, "algorithm": "pbkdf2-sha256", "iterations": 200000, "salt": %q, "hash": %q},
    {"normalized": %q, "display": %q, "account_uid": %q, "algorithm": "pbkdf2-sha256", "iterations": 200000, "salt": %q, "hash": %q}
  ],
  "devices": [
    {"device_id": %q, "account_uid": %q}
  ]
}`, account1, "import-one", account2, "import-two", guest, "guest-"+guest[:8],
		appidentity.NormalizeSDKLogin(normal1), normal1, account1, salt1, hash1,
		appidentity.NormalizeSDKLogin(normal2), normal2, account2, salt2, hash2,
		appidentity.NormalizeSDKLogin(guestLogin), guestLogin, guest, salt3, hash3,
		device, guest)
	return sdkImportFixture{document: document, normal1: normal1, password1: password1, guest: guest, guestLogin: guestLogin, guestPassword: guestPassword, device: device}
}

func TestSDKImportIsIdempotentAndVerifiesTheImportedPassword(t *testing.T) {
	pool := sdkTestPool(t)
	ctx := context.Background()
	service := sdkTestService(pool)
	fixture := buildSDKImportFixture(t)
	input, err := appidentity.DecodeSDKImport(strings.NewReader(fixture.document))
	if err != nil {
		t.Fatal(err)
	}
	importer := appidentity.SDKImporter{Runner: tx.Runner{DB: pool}, Store: identitystore.Store{}, Operations: operation.Factory{Clock: clock.System{}}}
	first, err := importer.Import(ctx, input)
	if err != nil {
		t.Fatal(err)
	}
	if first.AccountsImported != 3 || first.LoginsImported != 3 || first.DevicesImported != 1 || first.Conflicts != 0 {
		t.Fatalf("first import = %+v", first)
	}
	second, err := importer.Import(ctx, input)
	if err != nil {
		t.Fatal(err)
	}
	if second.AccountsImported != 0 || second.LoginsImported != 0 || second.DevicesImported != 0 ||
		second.AccountsSkipped != 3 || second.LoginsSkipped != 3 || second.DevicesSkipped != 1 || second.Conflicts != 0 {
		t.Fatalf("second import = %+v", second)
	}
	session, err := service.Login(ctx, appidentity.SDKLoginRequest{Login: fixture.normal1, Password: fixture.password1})
	if err != nil {
		t.Fatalf("imported password refused: %v", err)
	}
	if session.LoginEmail != fixture.normal1 {
		t.Fatalf("imported login = %+v", session)
	}
	if _, err := service.Login(ctx, appidentity.SDKLoginRequest{Login: fixture.normal1, Password: "not-the-imported-one"}); !errors.Is(err, appidentity.ErrSDKInvalidAccount) {
		t.Fatalf("wrong imported password err = %v", err)
	}
	if _, err := service.Login(ctx, appidentity.SDKLoginRequest{Login: "import-" + newSDKTestUUID(t), Password: fixture.password1}); !errors.Is(err, appidentity.ErrSDKInvalidAccount) {
		t.Fatalf("unknown imported login err = %v", err)
	}
	guest, err := service.Anonymous(ctx, appidentity.SDKAnonymousRequest{DeviceID: fixture.device})
	if err != nil {
		t.Fatal(err)
	}
	if guest.UID != fixture.guest {
		t.Fatalf("imported device account = %q, want %q", guest.UID, fixture.guest)
	}
	// The guest account has a stored login record, but a guest never logs in.
	if _, err := service.Login(ctx, appidentity.SDKLoginRequest{Login: fixture.guestLogin, Password: fixture.guestPassword}); !errors.Is(err, appidentity.ErrSDKInvalidAccount) {
		t.Fatalf("guest login err = %v", err)
	}
}
