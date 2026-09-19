package identity

import (
	"errors"
	"time"

	"gxb.local/backend/v2/internal/foundation/ids"
)

type AccountID struct{ v ids.UUID }
type AccountUID string
type SessionID struct{ v ids.UUID }
type ContextID struct{ v ids.UUID }
type CredentialID struct{ v ids.UUID }
type BindingID struct{ v ids.UUID }
type LogicalServerID int32
type PlayerID int64

func AccountIDFrom(v ids.UUID) (AccountID, error) {
	if v.IsZero() {
		return AccountID{}, errors.New("zero account id")
	}
	return AccountID{v}, nil
}
func SessionIDFrom(v ids.UUID) (SessionID, error) {
	if v.IsZero() {
		return SessionID{}, errors.New("zero session id")
	}
	return SessionID{v}, nil
}
func ContextIDFrom(v ids.UUID) (ContextID, error) {
	if v.IsZero() {
		return ContextID{}, errors.New("zero context id")
	}
	return ContextID{v}, nil
}
func CredentialIDFrom(v ids.UUID) (CredentialID, error) {
	if v.IsZero() {
		return CredentialID{}, errors.New("zero credential id")
	}
	return CredentialID{v}, nil
}
func BindingIDFrom(v ids.UUID) (BindingID, error) {
	if v.IsZero() {
		return BindingID{}, errors.New("zero binding id")
	}
	return BindingID{v}, nil
}
func (x AccountID) UUID() ids.UUID    { return x.v }
func (x AccountUID) Valid() bool      { return x != "" }
func (x SessionID) UUID() ids.UUID    { return x.v }
func (x ContextID) UUID() ids.UUID    { return x.v }
func (x CredentialID) UUID() ids.UUID { return x.v }
func (x BindingID) UUID() ids.UUID    { return x.v }
func (x LogicalServerID) Valid() bool { return x > 0 }
func (x PlayerID) Valid() bool        { return x > 0 }

type AccountStatus uint8

const (
	AccountActive AccountStatus = iota + 1
	AccountDisabled
)

type Account struct {
	ID              AccountID
	UID             AccountUID
	Status          AccountStatus
	CreatedAt       time.Time
	DisabledAt      *time.Time
	LivenessVersion int64
}

func (a Account) Live() bool { return a.Status == AccountActive && a.DisabledAt == nil }

type ProviderPrincipal struct {
	ProviderKey       string
	SubjectNormalized string
}

func (p ProviderPrincipal) Validate() error {
	if p.ProviderKey == "" || p.SubjectNormalized == "" {
		return errors.New("empty provider principal")
	}
	return nil
}

type ProviderBinding struct {
	ID         BindingID
	AccountID  AccountID
	Principal  ProviderPrincipal
	LinkedAt   time.Time
	DisabledAt *time.Time
}

type AuthProfile string

const AuthProductionPair AuthProfile = "SID_LOGIN_TOKEN_PAIR"

type Session struct {
	ID                 SessionID
	AccountID          AccountID
	AuthProfile        AuthProfile
	IssuedAt           time.Time
	AbsoluteExpiresAt  *time.Time
	IdleTimeoutSeconds *int64
	LastActivityAt     time.Time
	RevokedAt          *time.Time
	RevocationReason   string
	LivenessVersion    int64
}

func (s Session) Live(now time.Time) bool {
	if s.RevokedAt != nil {
		return false
	}
	if s.AbsoluteExpiresAt != nil && !now.Before(*s.AbsoluteExpiresAt) {
		return false
	}
	if s.IdleTimeoutSeconds != nil && *s.IdleTimeoutSeconds > 0 && !now.Before(s.LastActivityAt.Add(time.Duration(*s.IdleTimeoutSeconds)*time.Second)) {
		return false
	}
	return true
}

type CredentialKind uint8

const (
	CredentialSID CredentialKind = iota + 1
	CredentialLoginToken
)

type CredentialDigest [32]byte
type SessionCredential struct {
	ID        CredentialID
	SessionID SessionID
	Kind      CredentialKind
	Digest    CredentialDigest
	IssuedAt  time.Time
	ExpiresAt *time.Time
	RevokedAt *time.Time
}

func (c SessionCredential) Live(now time.Time) bool {
	return c.RevokedAt == nil && (c.ExpiresAt == nil || now.Before(*c.ExpiresAt))
}

type GameplayContext struct {
	ID                ContextID
	SessionID         SessionID
	AccountID         AccountID
	LogicalServerID   LogicalServerID
	PlayerID          PlayerID
	ContextGeneration int64
	CreatedAt         time.Time
	EndedAt           *time.Time
	EndReason         string
	LivenessVersion   int64
}

func (c GameplayContext) Live() bool { return c.EndedAt == nil }

type ActorContext struct {
	AccountID              AccountID
	AccountUID             AccountUID
	SessionID              SessionID
	ContextID              ContextID
	LogicalServerID        LogicalServerID
	PlayerID               PlayerID
	ContextGeneration      int64
	SessionLivenessVersion int64
	ContextLivenessVersion int64
}
