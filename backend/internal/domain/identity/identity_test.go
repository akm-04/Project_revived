package identity

import (
	"gxb.local/backend/v2/internal/foundation/ids"
	"testing"
	"time"
)

func uid(b byte) ids.UUID      { var x ids.UUID; x[15] = b; return x }
func aid(b byte) AccountID     { x, _ := AccountIDFrom(uid(b)); return x }
func sid(b byte) SessionID     { x, _ := SessionIDFrom(uid(b)); return x }
func cid(b byte) ContextID     { x, _ := ContextIDFrom(uid(b)); return x }
func crid(b byte) CredentialID { x, _ := CredentialIDFrom(uid(b)); return x }
func TestStrictCredentialPairAndNoGameplayBearerFallback(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	a := Account{ID: aid(1), UID: AccountUID("20000007"), Status: AccountActive}
	s := Session{ID: sid(2), AccountID: a.ID, AuthProfile: AuthProductionPair, IssuedAt: now, LastActivityAt: now}
	sec := []byte("0123456789abcdef0123456789abcdef")
	sd, _ := DigestCredential(sec, "sid", "S")
	ld, _ := DigestCredential(sec, "login_token", "L")
	sc := SessionCredential{ID: crid(3), SessionID: s.ID, Kind: CredentialSID, Digest: sd}
	lc := SessionCredential{ID: crid(4), SessionID: s.ID, Kind: CredentialLoginToken, Digest: ld}
	if _, err := AuthenticatePair(a, s, sc, lc, sd, ld, now); err != nil {
		t.Fatal(err)
	}
	bad, _ := DigestCredential(sec, "login_token", "gameplay-bearer")
	if _, err := AuthenticatePair(a, s, sc, lc, sd, bad, now); err == nil {
		t.Fatal("generic gameplay bearer authenticated account session")
	}
}
func TestSameTargetCoalescesStableBearerAndTargetChangeIsPlanned(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	s := Session{ID: sid(2), AccountID: aid(1), AuthProfile: AuthProductionPair, LastActivityAt: now}
	old := GameplayContext{ID: cid(5), SessionID: s.ID, AccountID: s.AccountID, LogicalServerID: 1, PlayerID: 100001, ContextGeneration: 7, CreatedAt: now, LivenessVersion: 1}
	p, err := PlanSelection(&old, s, Target{1, 100001}, cid(6), now)
	if err != nil {
		t.Fatal(err)
	}
	if p.Kind != SelectionCoalesced || p.Selected.ID != old.ID {
		t.Fatal("same target rotated context")
	}
	sec := []byte("0123456789abcdef0123456789abcdef")
	a, _ := DeriveGameplayBearer(sec, p.Selected)
	b, _ := DeriveGameplayBearer(sec, old)
	if a != b {
		t.Fatal("same context bearer unstable")
	}
	p, err = PlanSelection(&old, s, Target{2, 200001}, cid(6), now.Add(time.Second))
	if err != nil {
		t.Fatal(err)
	}
	if p.Kind != SelectionCreated || p.Previous == nil || p.Previous.EndedAt == nil || p.Selected.ContextGeneration != 8 {
		t.Fatalf("bad target-change plan %+v", p)
	}
	if old.EndedAt != nil {
		t.Fatal("pure planning mutated old context before admission commit")
	}
}
func TestRevokedParentFailsActorFence(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	r := now
	a := Account{ID: aid(1), UID: AccountUID("20000007"), Status: AccountActive}
	s := Session{ID: sid(2), AccountID: a.ID, AuthProfile: AuthProductionPair, LastActivityAt: now, RevokedAt: &r}
	c := GameplayContext{ID: cid(3), SessionID: s.ID, AccountID: a.ID, LogicalServerID: 1, PlayerID: 100001, ContextGeneration: 1}
	if _, err := ActorFrom(a, s, c, now); err == nil {
		t.Fatal("revoked session admitted")
	}
}

func TestGameplayBearerDigestStableAndDomainSeparated(t *testing.T) {
	secret := []byte("0123456789abcdef0123456789abcdef")
	a, err := DigestGameplayBearer(secret, "bearer")
	if err != nil {
		t.Fatal(err)
	}
	b, _ := DigestCredential(secret, GameplayBearerDigestLabel, "bearer")
	c, _ := DigestCredential(secret, "SID", "bearer")
	if a != b || a == c {
		t.Fatal("gameplay bearer digest domain separation failed")
	}
}
