package identity

import (
	"errors"
	"testing"
	"time"
)

func TestProviderBindingIsIdempotentButNeverCrossMerges(t *testing.T) {
	p := ProviderPrincipal{"publisher", "subject"}
	a := ProviderBinding{ID: func() BindingID { x, _ := BindingIDFrom(uid(7)); return x }(), AccountID: aid(1), Principal: p, LinkedAt: time.Unix(10, 0).UTC()}
	got, created, e := BindPrincipal(nil, a)
	if e != nil || !created || got.AccountID != a.AccountID {
		t.Fatal(e)
	}
	got, created, e = BindPrincipal(&a, a)
	if e != nil || created {
		t.Fatal("idempotent bind failed")
	}
	b := a
	b.AccountID = aid(2)
	if _, _, e = BindPrincipal(&a, b); !errors.Is(e, ErrPrincipalAlreadyBound) {
		t.Fatalf("%v", e)
	}
}
func TestNewSessionIssueDefaultsTheIdleTimeout(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	s := Session{ID: sid(2), AccountID: aid(1), AuthProfile: AuthProductionPair, IssuedAt: now, LastActivityAt: now, LivenessVersion: 1}
	sidCredential := SessionCredential{ID: crid(4), SessionID: s.ID, Kind: CredentialSID, Digest: CredentialDigest{1}, IssuedAt: now}
	loginCredential := SessionCredential{ID: crid(5), SessionID: s.ID, Kind: CredentialLoginToken, Digest: CredentialDigest{2}, IssuedAt: now}
	issue, e := NewSessionIssue(s, sidCredential, loginCredential)
	if e != nil {
		t.Fatal(e)
	}
	if issue.Session.IdleTimeoutSeconds == nil || *issue.Session.IdleTimeoutSeconds != DefaultIdleTimeoutSeconds {
		t.Fatalf("idle timeout = %v, want %d", issue.Session.IdleTimeoutSeconds, DefaultIdleTimeoutSeconds)
	}
	explicit := int64(60)
	s.IdleTimeoutSeconds = &explicit
	issue, e = NewSessionIssue(s, sidCredential, loginCredential)
	if e != nil || issue.Session.IdleTimeoutSeconds == nil || *issue.Session.IdleTimeoutSeconds != explicit {
		t.Fatalf("explicit idle timeout overwritten: %v %v", issue.Session.IdleTimeoutSeconds, e)
	}
}

func TestAuthenticatePairRefusesAnIdleExpiredSession(t *testing.T) {
	now := time.Unix(100000, 0).UTC()
	account := Account{ID: aid(1), UID: AccountUID("idle-account"), Status: AccountActive}
	idle := int64(3600)
	session := Session{ID: sid(2), AccountID: account.ID, AuthProfile: AuthProductionPair, IssuedAt: now.Add(-2 * time.Hour), IdleTimeoutSeconds: &idle, LastActivityAt: now.Add(-2 * time.Hour), LivenessVersion: 1}
	digest := CredentialDigest{1}
	sidCredential := SessionCredential{ID: crid(3), SessionID: session.ID, Kind: CredentialSID, Digest: digest, IssuedAt: session.IssuedAt}
	loginCredential := SessionCredential{ID: crid(4), SessionID: session.ID, Kind: CredentialLoginToken, Digest: digest, IssuedAt: session.IssuedAt}
	if _, err := AuthenticatePair(account, session, sidCredential, loginCredential, digest, digest, now); err == nil {
		t.Fatal("SID/login pair accepted a session idle past its timeout")
	}
}

func TestRevocationDurablyEndsChildren(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	s := Session{ID: sid(2), AccountID: aid(1), AuthProfile: AuthProductionPair, IssuedAt: time.Unix(10, 0).UTC(), LastActivityAt: time.Unix(10, 0).UTC(), LivenessVersion: 1}
	c := GameplayContext{ID: cid(3), SessionID: s.ID, AccountID: s.AccountID, LogicalServerID: 1, PlayerID: 100001, ContextGeneration: 1, CreatedAt: time.Unix(20, 0).UTC(), LivenessVersion: 1}
	sc := []SessionCredential{{ID: crid(4), SessionID: s.ID, Kind: CredentialSID}}
	gc := []GameplayCredential{{ID: crid(5), ContextID: c.ID, SessionID: s.ID, CredentialGeneration: 1}}
	p, e := RevokeSession(s, &c, sc, gc, now, "logout")
	if e != nil {
		t.Fatal(e)
	}
	if p.Session.RevokedAt == nil || p.Context.EndedAt == nil || p.SessionCredentials[0].RevokedAt == nil || p.GameplayCredentials[0].RevokedAt == nil {
		t.Fatal("incomplete durable revocation")
	}
	if s.RevokedAt != nil || c.EndedAt != nil {
		t.Fatal("pure plan mutated inputs")
	}
}
