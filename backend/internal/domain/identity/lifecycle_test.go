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
