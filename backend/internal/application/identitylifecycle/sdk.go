package identitylifecycle

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"errors"
	"strings"
	"time"

	"golang.org/x/crypto/pbkdf2"
	"golang.org/x/text/cases"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// The product SDK login service (G51F F1/F2). The stock client never sees a
// stock MID here: every reply is the SDK envelope the stand-in answered.
const (
	SDKAccountKindNormal = "normal"
	SDKAccountKindGuest  = "guest"

	SDKPasswordAlgorithm  = "pbkdf2-sha256"
	SDKPasswordIterations = 200000
	SDKPasswordSaltBytes  = 16
	SDKPasswordHashBytes  = 32

	// A stored record outside this range is refused instead of spending its
	// iteration count.
	SDKPasswordMinimumIterations = 10000
	SDKPasswordMaximumIterations = 1000000

	// Each raw session credential is its own 32 random bytes.
	SDKSessionSecretBytes = 32

	// Unauthenticated register/login issue at most this many concurrent PBKDF2
	// derivations per process.
	SDKPasswordDerivationSlots = 4
)

var (
	ErrSDKInvalidRegistration = errors.New("invalid registration request")
	ErrSDKAccountExists       = errors.New("account already exists")
	ErrSDKInvalidAccount      = errors.New("invalid account or password")

	errSDKLoginRace  = errors.New("sdk register lost the login insert race")
	errSDKDeviceRace = errors.New("sdk anonymous lost the device insert race")

	sdkPasswordDerivations = make(chan struct{}, SDKPasswordDerivationSlots)
	sdkDummyPasswordSalt   = [SDKPasswordSaltBytes]byte{'g', 'x', 'b', '-', 's', 'd', 'k', '-', 'd', 'u', 'm', 'm', 'y', '-', 'v', '1'}
)

// SDKAccountRecord is the account row as the SDK paths read it.
type SDKAccountRecord struct {
	ID        identity.AccountID
	UID       string
	Kind      string
	Username  string
	Active    bool
	CreatedAt time.Time
}

// SDKLoginRecord is one login and its password record.
type SDKLoginRecord struct {
	Normalized        string
	Display           string
	Account           SDKAccountRecord
	Algorithm         string
	Iterations        int
	SaltHex           string
	HashHex           string
	CreatedAt         time.Time
	PasswordChangedAt time.Time
}

// SDKStore is the owner-shaped storage port of the SDK login service and the
// one-time import.
type SDKStore interface {
	InsertSDKAccountTx(context.Context, tx.Tx, SDKAccountRecord) error
	InsertSDKAccountIfAbsentTx(context.Context, tx.Tx, SDKAccountRecord) (bool, error)
	FindSDKAccountByUIDTx(context.Context, tx.Queryer, string) (*SDKAccountRecord, error)

	FindSDKLoginTx(context.Context, tx.Queryer, string) (*SDKLoginRecord, error)
	InsertSDKLoginTx(context.Context, tx.Tx, SDKLoginRecord) (bool, error)

	FindSDKAccountByDeviceTx(context.Context, tx.Queryer, string) (*SDKAccountRecord, error)
	InsertSDKDeviceTx(context.Context, tx.Tx, string, identity.AccountID) (bool, error)

	// FindLiveSDKAccountBySIDDigestTx resolves the account of a live SID
	// credential; the presented raw sid is digested by the caller.
	FindLiveSDKAccountBySIDDigestTx(context.Context, tx.Queryer, identity.CredentialDigest, time.Time) (*SDKAccountRecord, error)

	InsertSessionTx(context.Context, tx.Tx, identity.Session) error
	InsertSessionCredentialTx(context.Context, tx.Tx, identity.SessionCredential) error
}

type SDKRegisterRequest struct {
	Login      string
	Password   string
	Repassword string
}

type SDKRegisterResult struct {
	UID        string
	LoginEmail string
}

type SDKLoginRequest struct {
	Login    string
	Password string
}

type SDKAnonymousRequest struct {
	CookieSID string
	DeviceID  string
}

// SDKIdentity is one successful SDK identity reply.
type SDKIdentity struct {
	UID        string
	SID        string
	Token      string
	Username   string
	LoginEmail string
}

type sdkRawSession struct {
	SID   string
	Token string
}

// SDKService owns register, login and anonymous over the identity store.
type SDKService struct {
	Runner       tx.Runner
	Store        SDKStore
	DigestSecret []byte
	Operations   operation.Factory
}

func (service SDKService) validate() error {
	if service.Runner.DB == nil || service.Store == nil {
		return ErrServicePortsIncomplete
	}
	if len(service.DigestSecret) < 16 {
		return errors.New("sdk digest secret too short")
	}
	return nil
}

// NormalizeSDKLogin is the register/login key: trim and Unicode case fold.
func NormalizeSDKLogin(login string) string {
	return cases.Fold().String(strings.TrimSpace(login))
}

// HashSDKPassword writes the pbkdf2-sha256 record the stand-in uses: algorithm,
// iterations, hex salt and hex hash (the Python hashlib.pbkdf2_hmac layout).
func HashSDKPassword(password string) (string, int, string, string, error) {
	salt := make([]byte, SDKPasswordSaltBytes)
	if _, err := rand.Read(salt); err != nil {
		return "", 0, "", "", err
	}
	hash := pbkdf2.Key([]byte(password), salt, SDKPasswordIterations, SDKPasswordHashBytes, sha256.New)
	return SDKPasswordAlgorithm, SDKPasswordIterations, hex.EncodeToString(salt), hex.EncodeToString(hash), nil
}

// VerifySDKPassword derives with the stored iteration count and compares in
// constant time. A record of another algorithm or a malformed value fails.
func VerifySDKPassword(algorithm string, iterations int, saltHex, hashHex, password string) bool {
	if algorithm != SDKPasswordAlgorithm || !sdkPasswordIterationsAcceptable(iterations) {
		return false
	}
	salt, err := hex.DecodeString(saltHex)
	if err != nil || len(salt) != SDKPasswordSaltBytes {
		return false
	}
	want, err := hex.DecodeString(hashHex)
	if err != nil || len(want) != SDKPasswordHashBytes {
		return false
	}
	got := pbkdf2.Key([]byte(password), salt, iterations, SDKPasswordHashBytes, sha256.New)
	return subtle.ConstantTimeCompare(got, want) == 1
}

func sdkPasswordIterationsAcceptable(iterations int) bool {
	return iterations >= SDKPasswordMinimumIterations && iterations <= SDKPasswordMaximumIterations
}

func acquireSDKPasswordDerivation(ctx context.Context) (func(), error) {
	select {
	case sdkPasswordDerivations <- struct{}{}:
		return func() { <-sdkPasswordDerivations }, nil
	case <-ctx.Done():
		return nil, ctx.Err()
	}
}

func verifySDKPasswordBounded(ctx context.Context, algorithm string, iterations int, saltHex, hashHex, password string) (bool, error) {
	release, err := acquireSDKPasswordDerivation(ctx)
	if err != nil {
		return false, err
	}
	defer release()
	return VerifySDKPassword(algorithm, iterations, saltHex, hashHex, password), nil
}

// burnSDKPasswordDerivation spends one derivation on a refused login so the
// response time does not tell whether the account exists.
func burnSDKPasswordDerivation(ctx context.Context) error {
	release, err := acquireSDKPasswordDerivation(ctx)
	if err != nil {
		return err
	}
	defer release()
	pbkdf2.Key([]byte("sdk-dummy-password"), sdkDummyPasswordSalt[:], SDKPasswordIterations, SDKPasswordHashBytes, sha256.New)
	return nil
}

// Register creates a normal login, or answers the existing login branch. A
// concurrent insert of the same key makes the loser re-enter the existing
// branch in a fresh transaction, so the PK decides and no account is orphaned.
func (service SDKService) Register(ctx context.Context, request SDKRegisterRequest) (SDKRegisterResult, error) {
	if err := service.validate(); err != nil {
		return SDKRegisterResult{}, err
	}
	login := strings.TrimSpace(request.Login)
	if login == "" || request.Password == "" || request.Password != request.Repassword {
		return SDKRegisterResult{}, ErrSDKInvalidRegistration
	}
	normalized := NormalizeSDKLogin(login)
	release, err := acquireSDKPasswordDerivation(ctx)
	if err != nil {
		return SDKRegisterResult{}, err
	}
	password, err := newSDKPasswordRecord(request.Password)
	release()
	if err != nil {
		return SDKRegisterResult{}, err
	}
	accountID, err := newSDKAccountID()
	if err != nil {
		return SDKRegisterResult{}, err
	}
	op, err := service.Operations.New(policy.Set{})
	if err != nil {
		return SDKRegisterResult{}, err
	}
	var out SDKRegisterResult
	var existing *SDKLoginRecord
	register := func(insert bool) tx.Body {
		return func(txctx context.Context, scope tx.Scope) error {
			found, err := service.Store.FindSDKLoginTx(txctx, scope.Tx, normalized)
			if err != nil {
				return err
			}
			if found != nil {
				existing = found
				return nil
			}
			if !insert {
				return ErrSDKInvalidRegistration
			}
			account := SDKAccountRecord{ID: accountID, UID: accountID.UUID().String(), Kind: SDKAccountKindNormal, Username: login, Active: true, CreatedAt: op.StartedAt}
			if err := service.Store.InsertSDKAccountTx(txctx, scope.Tx, account); err != nil {
				return err
			}
			record := SDKLoginRecord{Normalized: normalized, Display: login, Account: account, Algorithm: password.algorithm, Iterations: password.iterations, SaltHex: password.salt, HashHex: password.hash, CreatedAt: op.StartedAt, PasswordChangedAt: op.StartedAt}
			inserted, err := service.Store.InsertSDKLoginTx(txctx, scope.Tx, record)
			if err != nil {
				return err
			}
			if !inserted {
				return errSDKLoginRace
			}
			out = SDKRegisterResult{UID: account.UID, LoginEmail: login}
			return nil
		}
	}
	_, err = service.Runner.Run(ctx, op, DefaultProfile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, register(true))
	if errors.Is(err, errSDKLoginRace) {
		existing = nil
		_, err = service.Runner.Run(ctx, op, DefaultProfile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, register(false))
	}
	if err != nil {
		return SDKRegisterResult{}, err
	}
	if existing != nil {
		// The read is committed; derive outside it so a slow derivation never
		// holds a pooled connection.
		return sdkRegisterExistingRecord(ctx, existing, login, request.Password)
	}
	return out, nil
}

// sdkRegisterExistingRecord answers the existing-login branch without writing.
func sdkRegisterExistingRecord(ctx context.Context, existing *SDKLoginRecord, login, password string) (SDKRegisterResult, error) {
	if !existing.Account.Active {
		return SDKRegisterResult{}, ErrSDKAccountExists
	}
	valid, err := verifySDKPasswordBounded(ctx, existing.Algorithm, existing.Iterations, existing.SaltHex, existing.HashHex, password)
	if err != nil {
		return SDKRegisterResult{}, err
	}
	if !valid {
		return SDKRegisterResult{}, ErrSDKAccountExists
	}
	return SDKRegisterResult{UID: existing.Account.UID, LoginEmail: login}, nil
}

// Login verifies a normal login and issues one new session.
func (service SDKService) Login(ctx context.Context, request SDKLoginRequest) (SDKIdentity, error) {
	if err := service.validate(); err != nil {
		return SDKIdentity{}, err
	}
	login := strings.TrimSpace(request.Login)
	if login == "" || request.Password == "" {
		return SDKIdentity{}, ErrSDKInvalidAccount
	}
	normalized := NormalizeSDKLogin(login)
	op, err := service.Operations.New(policy.Set{})
	if err != nil {
		return SDKIdentity{}, err
	}
	// The record is read in a short transaction, the password is derived with no
	// transaction open (a login burst must not hold the pool), and the session is
	// issued in a second transaction only if the verified record is unchanged.
	var read *SDKLoginRecord
	_, err = service.Runner.Run(ctx, op, DefaultProfile(), tx.Options{Isolation: tx.ReadCommitted, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(txctx context.Context, scope tx.Scope) error {
		existing, err := service.Store.FindSDKLoginTx(txctx, scope.Tx, normalized)
		if err != nil {
			return err
		}
		read = existing
		return nil
	})
	if err != nil {
		return SDKIdentity{}, err
	}
	if read == nil || !read.Account.Active || read.Account.Kind != SDKAccountKindNormal {
		if err := burnSDKPasswordDerivation(ctx); err != nil {
			return SDKIdentity{}, err
		}
		return SDKIdentity{}, ErrSDKInvalidAccount
	}
	valid, err := verifySDKPasswordBounded(ctx, read.Algorithm, read.Iterations, read.SaltHex, read.HashHex, request.Password)
	if err != nil {
		return SDKIdentity{}, err
	}
	if !valid {
		return SDKIdentity{}, ErrSDKInvalidAccount
	}

	var out SDKIdentity
	_, err = service.Runner.Run(ctx, op, DefaultProfile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(txctx context.Context, scope tx.Scope) error {
		existing, err := service.Store.FindSDKLoginTx(txctx, scope.Tx, normalized)
		if err != nil {
			return err
		}
		// shortcut: the re-read is not FOR UPDATE, so a password change between this read and the session insert is not fenced; upgrade when a password-change command exists and takes the account lock.
		if existing == nil || !existing.Account.Active || existing.Account.Kind != SDKAccountKindNormal ||
			existing.SaltHex != read.SaltHex || existing.HashHex != read.HashHex {
			return ErrSDKInvalidAccount
		}
		session, err := service.issueSession(txctx, scope.Tx, existing.Account, op.StartedAt)
		if err != nil {
			return err
		}
		out = SDKIdentity{UID: existing.Account.UID, SID: session.SID, Token: session.Token, Username: existing.Account.Username, LoginEmail: login}
		return nil
	})
	if err != nil {
		return SDKIdentity{}, err
	}
	return out, nil
}

// Anonymous resolves the account from the live SDK cookie, else the device
// binding, else a new guest bound to the device when one was sent, then issues
// one new session.
func (service SDKService) Anonymous(ctx context.Context, request SDKAnonymousRequest) (SDKIdentity, error) {
	if err := service.validate(); err != nil {
		return SDKIdentity{}, err
	}
	op, err := service.Operations.New(policy.Set{})
	if err != nil {
		return SDKIdentity{}, err
	}
	var out SDKIdentity
	anonymous := func(txctx context.Context, scope tx.Scope) error {
		if request.CookieSID != "" {
			digest, err := identity.DigestCredential(service.DigestSecret, "sid", request.CookieSID)
			if err != nil {
				return err
			}
			account, err := service.Store.FindLiveSDKAccountBySIDDigestTx(txctx, scope.Tx, digest, op.StartedAt)
			if err != nil {
				return err
			}
			if account != nil {
				return service.anonymousIdentity(txctx, scope.Tx, *account, &out, op.StartedAt)
			}
		}
		if request.DeviceID != "" {
			account, err := service.Store.FindSDKAccountByDeviceTx(txctx, scope.Tx, request.DeviceID)
			if err != nil {
				return err
			}
			if account != nil && account.Kind != SDKAccountKindGuest {
				return ErrSDKInvalidAccount
			}
			if account != nil {
				return service.anonymousIdentity(txctx, scope.Tx, *account, &out, op.StartedAt)
			}
		}
		account, err := service.newGuest(txctx, scope.Tx, request.DeviceID, op.StartedAt)
		if err != nil {
			return err
		}
		return service.anonymousIdentity(txctx, scope.Tx, account, &out, op.StartedAt)
	}
	_, err = service.Runner.Run(ctx, op, DefaultProfile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, anonymous)
	if errors.Is(err, errSDKDeviceRace) {
		_, err = service.Runner.Run(ctx, op, DefaultProfile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, anonymous)
	}
	if err != nil {
		return SDKIdentity{}, err
	}
	return out, nil
}

func (service SDKService) newGuest(ctx context.Context, transaction tx.Tx, deviceID string, at time.Time) (SDKAccountRecord, error) {
	accountID, err := newSDKAccountID()
	if err != nil {
		return SDKAccountRecord{}, err
	}
	uid := accountID.UUID().String()
	account := SDKAccountRecord{ID: accountID, UID: uid, Kind: SDKAccountKindGuest, Username: "guest-" + uid[:8], Active: true, CreatedAt: at}
	if err := service.Store.InsertSDKAccountTx(ctx, transaction, account); err != nil {
		return SDKAccountRecord{}, err
	}
	if deviceID == "" {
		return account, nil
	}
	inserted, err := service.Store.InsertSDKDeviceTx(ctx, transaction, deviceID, accountID)
	if err != nil {
		return SDKAccountRecord{}, err
	}
	if !inserted {
		return SDKAccountRecord{}, errSDKDeviceRace
	}
	return account, nil
}

func (service SDKService) anonymousIdentity(ctx context.Context, transaction tx.Tx, account SDKAccountRecord, out *SDKIdentity, at time.Time) error {
	if !account.Active {
		return ErrSDKInvalidAccount
	}
	session, err := service.issueSession(ctx, transaction, account, at)
	if err != nil {
		return err
	}
	username := account.Username
	if username == "" {
		username = "guest-" + account.UID[:8]
	}
	*out = SDKIdentity{UID: account.UID, SID: session.SID, Token: session.Token, Username: username}
	return nil
}

// issueSession mirrors provision.Account: an AuthProductionPair session whose
// SID and LOGIN_TOKEN credentials are digested with the backend's secret.
func (service SDKService) issueSession(ctx context.Context, transaction tx.Tx, account SDKAccountRecord, at time.Time) (sdkRawSession, error) {
	sessionUUID, err := ids.NewUUID()
	if err != nil {
		return sdkRawSession{}, err
	}
	sessionID, err := identity.SessionIDFrom(sessionUUID)
	if err != nil {
		return sdkRawSession{}, err
	}
	raw, err := newSDKRawSession()
	if err != nil {
		return sdkRawSession{}, err
	}
	session := identity.Session{ID: sessionID, AccountID: account.ID, AuthProfile: identity.AuthProductionPair, IssuedAt: at, LastActivityAt: at, LivenessVersion: 1}
	sid, err := newSDKCredential(service.DigestSecret, "sid", raw.SID, sessionID, at)
	if err != nil {
		return sdkRawSession{}, err
	}
	loginToken, err := newSDKCredential(service.DigestSecret, "login_token", raw.Token, sessionID, at)
	if err != nil {
		return sdkRawSession{}, err
	}
	issue, err := identity.NewSessionIssue(session, sid, loginToken)
	if err != nil {
		return sdkRawSession{}, err
	}
	if err := service.Store.InsertSessionTx(ctx, transaction, issue.Session); err != nil {
		return sdkRawSession{}, err
	}
	if err := service.Store.InsertSessionCredentialTx(ctx, transaction, issue.SID); err != nil {
		return sdkRawSession{}, err
	}
	if err := service.Store.InsertSessionCredentialTx(ctx, transaction, issue.LoginToken); err != nil {
		return sdkRawSession{}, err
	}
	return raw, nil
}

// newSDKRawSession makes two independent random credentials: the SID is sent
// as a cookie, so nothing about it may reveal the login token.
func newSDKRawSession() (sdkRawSession, error) {
	sid, err := newSDKSessionSecret("sdk-sid-")
	if err != nil {
		return sdkRawSession{}, err
	}
	token, err := newSDKSessionSecret("sdk-login-")
	if err != nil {
		return sdkRawSession{}, err
	}
	return sdkRawSession{SID: sid, Token: token}, nil
}

func newSDKSessionSecret(prefix string) (string, error) {
	value := make([]byte, SDKSessionSecretBytes)
	if _, err := rand.Read(value); err != nil {
		return "", err
	}
	return prefix + hex.EncodeToString(value), nil
}

func newSDKCredential(secret []byte, label, raw string, session identity.SessionID, at time.Time) (identity.SessionCredential, error) {
	credentialID, err := ids.NewUUID()
	if err != nil {
		return identity.SessionCredential{}, err
	}
	id, err := identity.CredentialIDFrom(credentialID)
	if err != nil {
		return identity.SessionCredential{}, err
	}
	digest, err := identity.DigestCredential(secret, label, raw)
	if err != nil {
		return identity.SessionCredential{}, err
	}
	kind := identity.CredentialSID
	if label == "login_token" {
		kind = identity.CredentialLoginToken
	}
	return identity.SessionCredential{ID: id, SessionID: session, Kind: kind, Digest: digest, IssuedAt: at}, nil
}

type sdkPasswordRecord struct {
	algorithm  string
	iterations int
	salt       string
	hash       string
}

func newSDKPasswordRecord(password string) (sdkPasswordRecord, error) {
	algorithm, iterations, salt, hash, err := HashSDKPassword(password)
	if err != nil {
		return sdkPasswordRecord{}, err
	}
	return sdkPasswordRecord{algorithm: algorithm, iterations: iterations, salt: salt, hash: hash}, nil
}

func newSDKAccountID() (identity.AccountID, error) {
	value, err := ids.NewUUID()
	if err != nil {
		return identity.AccountID{}, err
	}
	return identity.AccountIDFrom(value)
}
