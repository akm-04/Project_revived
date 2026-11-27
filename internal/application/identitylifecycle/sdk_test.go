package identitylifecycle

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
	"testing"
	"time"

	"golang.org/x/crypto/pbkdf2"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestNormalizeSDKLoginTrimsAndCaseFolds(t *testing.T) {
	cases := map[string]string{
		"  Player@Example.COM ": "player@example.com",
		"PLAYER@EXAMPLE.COM":    "player@example.com",
		"Straße":                "strasse",
		"":                      "",
	}
	for input, want := range cases {
		if got := NormalizeSDKLogin(input); got != want {
			t.Fatalf("NormalizeSDKLogin(%q) = %q, want %q", input, got, want)
		}
	}
}

func TestHashSDKPasswordMatchesThePythonRecordLayout(t *testing.T) {
	algorithm, iterations, saltHex, hashHex, err := HashSDKPassword("password-1")
	if err != nil {
		t.Fatal(err)
	}
	if algorithm != "pbkdf2-sha256" || iterations != 200000 {
		t.Fatalf("record = %s %d", algorithm, iterations)
	}
	salt, err := hex.DecodeString(saltHex)
	if err != nil || len(salt) != 16 {
		t.Fatalf("salt = %q err=%v, want 16 bytes of hex", saltHex, err)
	}
	hash, err := hex.DecodeString(hashHex)
	if err != nil || len(hash) != 32 {
		t.Fatalf("hash = %q err=%v, want 32 bytes of hex", hashHex, err)
	}
	if want := pbkdf2.Key([]byte("password-1"), salt, 200000, 32, sha256.New); hex.EncodeToString(want) != hashHex {
		t.Fatal("the hash is not pbkdf2-sha256 over the stored salt")
	}
	if !VerifySDKPassword(algorithm, iterations, saltHex, hashHex, "password-1") {
		t.Fatal("the correct password was refused")
	}
	if VerifySDKPassword(algorithm, iterations, saltHex, hashHex, "password-2") {
		t.Fatal("a wrong password was accepted")
	}
	if VerifySDKPassword("bcrypt", iterations, saltHex, hashHex, "password-1") {
		t.Fatal("another algorithm was accepted")
	}
	if VerifySDKPassword(algorithm, iterations, "zz", hashHex, "password-1") {
		t.Fatal("a malformed salt was accepted")
	}
	if VerifySDKPassword(algorithm, iterations, saltHex, "zz", "password-1") {
		t.Fatal("a malformed hash was accepted")
	}
}

func TestVerifySDKPasswordRefusesIterationsOutsideBounds(t *testing.T) {
	_, _, salt, hash, err := HashSDKPassword("password-1")
	if err != nil {
		t.Fatal(err)
	}
	if VerifySDKPassword(SDKPasswordAlgorithm, SDKPasswordMinimumIterations-1, salt, hash, "password-1") {
		t.Fatal("a record below the iteration floor was accepted")
	}
	if VerifySDKPassword(SDKPasswordAlgorithm, SDKPasswordMaximumIterations+1, salt, hash, "password-1") {
		t.Fatal("a record above the iteration ceiling was accepted")
	}
}

func TestAcquireSDKPasswordDerivationRespectsContext(t *testing.T) {
	releases := make([]func(), 0, SDKPasswordDerivationSlots)
	defer func() {
		for _, release := range releases {
			release()
		}
	}()
	for index := 0; index < SDKPasswordDerivationSlots; index++ {
		release, err := acquireSDKPasswordDerivation(context.Background())
		if err != nil {
			t.Fatal(err)
		}
		releases = append(releases, release)
	}
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if _, err := acquireSDKPasswordDerivation(ctx); !errors.Is(err, context.Canceled) {
		t.Fatalf("canceled acquire err = %v, want context canceled", err)
	}
}

func TestSDKPasswordDerivationBoundHolds(t *testing.T) {
	releases := make([]func(), 0, SDKPasswordDerivationSlots)
	defer func() {
		for _, release := range releases {
			release()
		}
	}()
	for index := 0; index < SDKPasswordDerivationSlots; index++ {
		release, err := acquireSDKPasswordDerivation(context.Background())
		if err != nil {
			t.Fatal(err)
		}
		releases = append(releases, release)
	}
	acquired := make(chan struct{})
	go func() {
		release, err := acquireSDKPasswordDerivation(context.Background())
		if err != nil {
			t.Errorf("waiting derivation: %v", err)
			close(acquired)
			return
		}
		release()
		close(acquired)
	}()
	select {
	case <-acquired:
		t.Fatal("a derivation beyond the bound ran while every slot was held")
	case <-time.After(50 * time.Millisecond):
	}
	release := releases[0]
	releases = releases[1:]
	release()
	select {
	case <-acquired:
	case <-time.After(time.Second):
		t.Fatal("the waiting derivation did not run after a slot was freed")
	}
}

func TestSDKSessionSecretsAreIndependent(t *testing.T) {
	first, err := newSDKRawSession()
	if err != nil {
		t.Fatal(err)
	}
	second, err := newSDKRawSession()
	if err != nil {
		t.Fatal(err)
	}
	if first.SID == second.SID || first.Token == second.Token {
		t.Fatal("two sessions reused one credential")
	}
	if !strings.HasPrefix(first.SID, "sdk-sid-") || !strings.HasPrefix(first.Token, "sdk-login-") {
		t.Fatalf("raw session = %+v", first)
	}
	sidSecret := strings.TrimPrefix(first.SID, "sdk-sid-")
	tokenSecret := strings.TrimPrefix(first.Token, "sdk-login-")
	if len(sidSecret) != 2*SDKSessionSecretBytes || len(tokenSecret) != 2*SDKSessionSecretBytes {
		t.Fatalf("secret lengths = %d %d", len(sidSecret), len(tokenSecret))
	}
	if strings.Contains(first.SID, tokenSecret) || strings.Contains(first.Token, sidSecret) {
		t.Fatal("the login token is derivable from the SID")
	}
	if sharesSDKSubstring(sidSecret, tokenSecret, 8) {
		t.Fatal("the SID and token share a substring")
	}
}

func sharesSDKSubstring(left, right string, length int) bool {
	for start := 0; start+length <= len(left); start++ {
		if strings.Contains(right, left[start:start+length]) {
			return true
		}
	}
	return false
}

const (
	sdkImportNormalUID  = "11111111-1111-4111-8111-111111111111"
	sdkImportGuestUID   = "22222222-2222-4222-8222-222222222222"
	sdkImportMissingUID = "33333333-3333-4333-8333-333333333333"
)

func sdkImportJSON(t *testing.T) string {
	t.Helper()
	_, _, salt, hash, err := HashSDKPassword("secret-1")
	if err != nil {
		t.Fatal(err)
	}
	return `{
  "version": 1,
  "accounts": {
    "` + sdkImportNormalUID + `": {
      "uid": "` + sdkImportNormalUID + `",
      "login": "player-one",
      "username": "player-one",
      "account_type": "normal",
      "created_at": 1760000000,
      "password": {"algorithm": "pbkdf2-sha256", "iterations": 200000, "salt": "` + salt + `", "hash": "` + hash + `"},
      "session": {"session_id": "00000000-0000-4000-8000-000000000000", "sid": "pl-sid-1", "token": "pl-login-1"}
    },
    "` + sdkImportGuestUID + `": {
      "uid": "` + sdkImportGuestUID + `",
      "login": null,
      "username": "guest-22222222",
      "account_type": "guest",
      "created_at": 1760000001,
      "password": null,
      "session": null
    }
  },
  "logins": {"player-one": "` + sdkImportNormalUID + `"},
  "devices": {"device-1": "` + sdkImportGuestUID + `"}
}`
}

func TestDecodeSDKImportAcceptsTheStandInShape(t *testing.T) {
	input, err := DecodeSDKImport(strings.NewReader(sdkImportJSON(t)))
	if err != nil {
		t.Fatal(err)
	}
	if len(input.Accounts) != 2 || len(input.Logins) != 1 || len(input.Devices) != 1 || input.UnresolvedLogins != 0 {
		t.Fatalf("decoded = %+v", input)
	}
	if input.Accounts[0].Type != SDKAccountKindNormal || input.Accounts[1].Type != SDKAccountKindGuest {
		t.Fatalf("account kinds = %+v", input.Accounts)
	}
	if input.Accounts[0].Created.Unix() != 1760000000 {
		t.Fatalf("account created = %v, want unix 1760000000", input.Accounts[0].Created)
	}
	if input.Logins[0].Display != "player-one" || input.Logins[0].AccountUID != sdkImportNormalUID {
		t.Fatalf("login = %+v", input.Logins[0])
	}
	if input.Logins[0].Created.Unix() != 1760000000 || !input.Logins[0].PasswordChangedAt.Equal(input.Logins[0].Created) {
		t.Fatalf("login times = %+v", input.Logins[0])
	}
	if input.Devices[0].DeviceID != "device-1" || input.Devices[0].AccountUID != sdkImportGuestUID {
		t.Fatalf("device = %+v", input.Devices[0])
	}
}

func TestDecodeSDKImportSkipsLoginsWithoutAnAccountOrPassword(t *testing.T) {
	valid := sdkImportJSON(t)
	document := strings.Replace(valid, `"logins": {"player-one": "`+sdkImportNormalUID+`"}`,
		`"logins": {"guest-login": "`+sdkImportGuestUID+`", "missing-login": "`+sdkImportMissingUID+`", "player-one": "`+sdkImportNormalUID+`"}`, 1)
	input, err := DecodeSDKImport(strings.NewReader(document))
	if err != nil {
		t.Fatal(err)
	}
	if len(input.Logins) != 1 || input.UnresolvedLogins != 2 {
		t.Fatalf("decoded = %+v, want one login and two unresolved", input)
	}
}

func TestDecodeSDKImportRefusesBrokenRecords(t *testing.T) {
	valid := sdkImportJSON(t)
	cases := map[string]string{
		"unknown field":   strings.Replace(valid, `"account_type": "normal",`, `"account_type": "normal", "extra": 1,`, 1),
		"bad uid":         strings.ReplaceAll(valid, sdkImportNormalUID, "not-a-uuid"),
		"mismatched key":  strings.Replace(valid, `"`+sdkImportNormalUID+`": {`, `"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa": {`, 1),
		"bad type":        strings.Replace(valid, `"account_type": "normal"`, `"account_type": "system"`, 1),
		"blank name":      strings.Replace(valid, `"username": "player-one"`, `"username": " "`, 1),
		"bad algorithm":   strings.Replace(valid, `"pbkdf2-sha256"`, `"sha1"`, 1),
		"bad salt":        strings.Replace(valid, `"salt": "`, `"salt": "zz`, 1),
		"bad device":      strings.Replace(valid, `"device-1"`, `""`, 1),
		"bad version":     strings.Replace(valid, `"version": 1`, `"version": 2`, 1),
		"missing version": strings.Replace(valid, `"version": 1,`, ``, 1),
	}
	for name, body := range cases {
		t.Run(name, func(t *testing.T) {
			if _, err := DecodeSDKImport(strings.NewReader(body)); err == nil {
				t.Fatalf("broken import accepted: %s", body)
			}
		})
	}
}

// sdkSlotHold parks every derivation slot so a test can tell whether the
// derivation blocked on a slot while a transaction was still open.
type sdkSlotHold struct {
	held int
}

func (hold *sdkSlotHold) holdAll() {
	for hold.held < SDKPasswordDerivationSlots {
		sdkPasswordDerivations <- struct{}{}
		hold.held++
	}
}

func (hold *sdkSlotHold) releaseAll() {
	for hold.held > 0 {
		<-sdkPasswordDerivations
		hold.held--
	}
}

type sdkProbeBeginner struct {
	commits chan struct{}
}

func (beginner sdkProbeBeginner) Begin(context.Context, tx.Options) (tx.Tx, error) {
	return sdkProbeTx{commits: beginner.commits}, nil
}

type sdkProbeTx struct {
	commits chan struct{}
}

func (sdkProbeTx) QueryRow(context.Context, string, ...any) tx.Row { return sdkProbeRow{} }
func (sdkProbeTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return sdkProbeTag{}, nil
}
func (transaction sdkProbeTx) Commit(context.Context) error {
	transaction.commits <- struct{}{}
	return nil
}
func (sdkProbeTx) Rollback(context.Context) error { return nil }

type sdkProbeRow struct{}

func (sdkProbeRow) Scan(...any) error { return errors.New("unused probe row") }

type sdkProbeTag struct{}

func (sdkProbeTag) RowsAffected() int64 { return 1 }

type sdkProbeStore struct {
	login *SDKLoginRecord
	hold  *sdkSlotHold
	reads int
}

func (store *sdkProbeStore) FindSDKLoginTx(context.Context, tx.Queryer, string) (*SDKLoginRecord, error) {
	store.reads++
	if store.reads == 1 && store.hold != nil {
		store.hold.holdAll()
	}
	return store.login, nil
}

func (store *sdkProbeStore) InsertSessionTx(context.Context, tx.Tx, identity.Session) error {
	return nil
}

func (store *sdkProbeStore) InsertSessionCredentialTx(context.Context, tx.Tx, identity.SessionCredential) error {
	return nil
}

func (sdkProbeStore) InsertSDKAccountTx(context.Context, tx.Tx, SDKAccountRecord) error {
	return errors.New("unused probe account insert")
}

func (sdkProbeStore) InsertSDKAccountIfAbsentTx(context.Context, tx.Tx, SDKAccountRecord) (bool, error) {
	return false, errors.New("unused probe account insert")
}

func (sdkProbeStore) FindSDKAccountByUIDTx(context.Context, tx.Queryer, string) (*SDKAccountRecord, error) {
	return nil, errors.New("unused probe account lookup")
}

func (sdkProbeStore) InsertSDKLoginTx(context.Context, tx.Tx, SDKLoginRecord) (bool, error) {
	return false, errors.New("unused probe login insert")
}

func (sdkProbeStore) FindSDKAccountByDeviceTx(context.Context, tx.Queryer, string) (*SDKAccountRecord, error) {
	return nil, errors.New("unused probe device lookup")
}

func (sdkProbeStore) InsertSDKDeviceTx(context.Context, tx.Tx, string, identity.AccountID) (bool, error) {
	return false, errors.New("unused probe device insert")
}

func (sdkProbeStore) FindLiveSDKAccountBySIDDigestTx(context.Context, tx.Queryer, identity.CredentialDigest, time.Time) (*SDKAccountRecord, error) {
	return nil, errors.New("unused probe sid lookup")
}

func sdkProbeRecord(t *testing.T) *SDKLoginRecord {
	t.Helper()
	accountUUID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	accountID, err := identity.AccountIDFrom(accountUUID)
	if err != nil {
		t.Fatal(err)
	}
	algorithm, iterations, salt, hash, err := HashSDKPassword("secret-1")
	if err != nil {
		t.Fatal(err)
	}
	return &SDKLoginRecord{
		Normalized: "player-one",
		Display:    "player-one",
		Account:    SDKAccountRecord{ID: accountID, UID: accountUUID.String(), Kind: SDKAccountKindNormal, Username: "player-one", Active: true},
		Algorithm:  algorithm,
		Iterations: iterations,
		SaltHex:    salt,
		HashHex:    hash,
	}
}

// TestSDKPasswordVerificationRunsOutsideTheTransaction parks every derivation
// slot inside the first read. The read transaction must commit anyway, which is
// only possible when the derivation is not started under it.
func TestSDKPasswordVerificationRunsOutsideTheTransaction(t *testing.T) {
	record := sdkProbeRecord(t)

	run := func(t *testing.T, call func(SDKService) error) {
		t.Helper()
		hold := &sdkSlotHold{}
		t.Cleanup(hold.releaseAll)
		commits := make(chan struct{}, 8)
		service := SDKService{
			Runner:       tx.Runner{DB: sdkProbeBeginner{commits: commits}},
			Store:        &sdkProbeStore{login: record, hold: hold},
			DigestSecret: []byte("0123456789abcdef"),
			Operations:   operation.Factory{Clock: clock.System{}},
		}
		done := make(chan error, 1)
		go func() { done <- call(service) }()
		select {
		case <-commits:
		case <-time.After(5 * time.Second):
			hold.releaseAll()
			<-done
			t.Fatal("the read transaction did not commit before the password derivation")
		}
		select {
		case err := <-done:
			t.Fatalf("the call finished while every derivation slot was held: %v", err)
		case <-time.After(50 * time.Millisecond):
		}
		hold.releaseAll()
		if err := <-done; err != nil {
			t.Fatal(err)
		}
	}

	t.Run("login", func(t *testing.T) {
		run(t, func(service SDKService) error {
			issued, err := service.Login(context.Background(), SDKLoginRequest{Login: "player-one", Password: "secret-1"})
			if err != nil {
				return err
			}
			if issued.UID != record.Account.UID {
				return fmt.Errorf("issued uid %q, want %q", issued.UID, record.Account.UID)
			}
			return nil
		})
	})

	t.Run("register existing login", func(t *testing.T) {
		run(t, func(service SDKService) error {
			result, err := service.Register(context.Background(), SDKRegisterRequest{Login: "player-one", Password: "secret-1", Repassword: "secret-1"})
			if err != nil {
				return err
			}
			if result.UID != record.Account.UID {
				return fmt.Errorf("existing uid %q, want %q", result.UID, record.Account.UID)
			}
			return nil
		})
	})
}

// sdkDeviceAuthenticationStore answers the device and live-cookie lookups of
// the anonymous recovery regression.
type sdkDeviceAuthenticationStore struct {
	sdkProbeStore
	deviceAccount *SDKAccountRecord
	cookieAccount *SDKAccountRecord
	deviceLookups int
	issued        int
}

func (store *sdkDeviceAuthenticationStore) FindSDKAccountByDeviceTx(context.Context, tx.Queryer, string) (*SDKAccountRecord, error) {
	store.deviceLookups++
	return store.deviceAccount, nil
}

func (store *sdkDeviceAuthenticationStore) FindLiveSDKAccountBySIDDigestTx(context.Context, tx.Queryer, identity.CredentialDigest, time.Time) (*SDKAccountRecord, error) {
	return store.cookieAccount, nil
}

func (store *sdkDeviceAuthenticationStore) InsertSessionTx(context.Context, tx.Tx, identity.Session) error {
	store.issued++
	return nil
}

func sdkDeviceAuthenticationAccount(t *testing.T, kind, username string) *SDKAccountRecord {
	t.Helper()
	accountID, err := newSDKAccountID()
	if err != nil {
		t.Fatal(err)
	}
	uid := accountID.UUID().String()
	if username == "" {
		username = "guest-" + uid[:8]
	}
	return &SDKAccountRecord{ID: accountID, UID: uid, Kind: kind, Username: username, Active: true, CreatedAt: time.Now()}
}

func sdkDeviceAuthenticationService(store *sdkDeviceAuthenticationStore) SDKService {
	return SDKService{
		Runner:       tx.Runner{DB: sdkProbeBeginner{commits: make(chan struct{}, 8)}},
		Store:        store,
		DigestSecret: []byte("0123456789abcdef"),
		Operations:   operation.Factory{Clock: clock.System{}},
	}
}

// TestSDKAnonymousRefusesADeviceOnlyPasswordAccount is A-207: a known device
// identifier must not recover a password account without the password or a
// live cookie, and the refusal must issue no session credential.
func TestSDKAnonymousRefusesADeviceOnlyPasswordAccount(t *testing.T) {
	store := &sdkDeviceAuthenticationStore{deviceAccount: sdkDeviceAuthenticationAccount(t, SDKAccountKindNormal, "player-one")}
	recovered, err := sdkDeviceAuthenticationService(store).Anonymous(context.Background(), SDKAnonymousRequest{DeviceID: "known-device-id"})
	if !errors.Is(err, ErrSDKInvalidAccount) {
		t.Fatalf("device-only password account err = %v, want invalid account", err)
	}
	if recovered.UID != "" || recovered.SID != "" || recovered.Token != "" || store.issued != 0 {
		t.Fatalf("refused device request issued credentials: %+v issued=%d", recovered, store.issued)
	}
}

func TestSDKAnonymousRecoversAGuestFromItsDevice(t *testing.T) {
	account := sdkDeviceAuthenticationAccount(t, SDKAccountKindGuest, "")
	store := &sdkDeviceAuthenticationStore{deviceAccount: account}
	recovered, err := sdkDeviceAuthenticationService(store).Anonymous(context.Background(), SDKAnonymousRequest{DeviceID: "guest-device-id"})
	if err != nil {
		t.Fatal(err)
	}
	if recovered.UID != account.UID || recovered.SID == "" || recovered.Token == "" || store.issued != 1 {
		t.Fatalf("guest device recovery = %+v issued=%d", recovered, store.issued)
	}
}

func TestSDKAnonymousCookieRecoveryIgnoresAnotherDevice(t *testing.T) {
	cookieAccount := sdkDeviceAuthenticationAccount(t, SDKAccountKindNormal, "player-one")
	deviceAccount := sdkDeviceAuthenticationAccount(t, SDKAccountKindGuest, "")
	store := &sdkDeviceAuthenticationStore{cookieAccount: cookieAccount, deviceAccount: deviceAccount}
	recovered, err := sdkDeviceAuthenticationService(store).Anonymous(context.Background(), SDKAnonymousRequest{CookieSID: "sdk-sid-presented", DeviceID: "another-device"})
	if err != nil {
		t.Fatal(err)
	}
	if recovered.UID != cookieAccount.UID || recovered.SID == "" || recovered.Token == "" {
		t.Fatalf("cookie recovery = %+v, want the cookie account %q", recovered, cookieAccount.UID)
	}
	if store.deviceLookups != 0 || store.issued != 1 {
		t.Fatalf("device lookups=%d issued=%d, want the live cookie to decide", store.deviceLookups, store.issued)
	}
}

func TestDecodeSDKImportRefusesDuplicateNormalizedLogins(t *testing.T) {
	valid := sdkImportJSON(t)
	duplicate := strings.Replace(valid, `"logins": {"player-one": "`+sdkImportNormalUID+`"}`,
		`"logins": {"player-one": "`+sdkImportNormalUID+`", "Player-One": "`+sdkImportNormalUID+`"}`, 1)
	if _, err := DecodeSDKImport(strings.NewReader(duplicate)); err == nil {
		t.Fatal("a duplicate normalized login was accepted")
	}
}
