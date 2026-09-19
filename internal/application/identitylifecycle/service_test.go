package identitylifecycle

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type testTag int64

func (t testTag) RowsAffected() int64 { return int64(t) }

type testRow struct{ err error }

func (r testRow) Scan(...any) error { return r.err }

type testTx struct {
	commitErr error
	rolled    bool
	onCommit  []func()
}

func (t *testTx) QueryRow(context.Context, string, ...any) tx.Row             { return testRow{} }
func (t *testTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return testTag(1), nil }
func (t *testTx) Commit(context.Context) error {
	if t.commitErr != nil {
		return t.commitErr
	}
	for _, f := range t.onCommit {
		f()
	}
	return nil
}
func (t *testTx) Rollback(context.Context) error { t.rolled = true; return nil }
func (t *testTx) stage(f func())                 { t.onCommit = append(t.onCommit, f) }

type testBeginner struct {
	mu        sync.Mutex
	count     int
	txs       []*testTx
	commitErr error
}

func (b *testBeginner) Begin(context.Context, tx.Options) (tx.Tx, error) {
	b.mu.Lock()
	defer b.mu.Unlock()
	b.count++
	t := &testTx{commitErr: b.commitErr}
	b.txs = append(b.txs, t)
	return t, nil
}

type memReceipts struct {
	mu sync.Mutex
	m  map[receipt.Identity]receipt.Receipt
}

func newMemReceipts() *memReceipts { return &memReceipts{m: map[receipt.Identity]receipt.Receipt{}} }
func (m *memReceipts) PutTx(_ context.Context, t tx.Tx, r receipt.Receipt) (receipt.PutResult, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if old, ok := m.m[r.Identity]; ok {
		return receipt.PutResult{Receipt: old, Inserted: false}, nil
	}
	if tt, ok := t.(*testTx); ok {
		tt.stage(func() { m.mu.Lock(); m.m[r.Identity] = r; m.mu.Unlock() })
	} else {
		m.m[r.Identity] = r
	}
	return receipt.PutResult{Receipt: r, Inserted: true}, nil
}
func (m *memReceipts) FindTx(_ context.Context, _ tx.Queryer, id receipt.Identity) (receipt.Receipt, bool, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	r, ok := m.m[id]
	return r, ok, nil
}
func (m *memReceipts) Find(_ context.Context, id receipt.Identity) (receipt.Receipt, bool, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	r, ok := m.m[id]
	return r, ok, nil
}

type testStore struct {
	Store
	mu                                          sync.Mutex
	account                                     identity.Account
	binding                                     *identity.ProviderBinding
	sessions                                    map[string]identity.Session
	creds                                       map[string][]identity.SessionCredential
	context                                     *identity.GameplayContext
	bindingInserts, sessionInserts, credInserts int
	failCredentialAt                            int
	failSaveContext                             bool
	lockOrder                                   []string
	revokeSessionCreds, revokeGameplayCreds     int
	touches                                     int
}

func (s *testStore) LockAccountTx(context.Context, tx.Tx, identity.AccountID) (identity.Account, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.account, nil
}
func (s *testStore) FindProviderBindingTx(context.Context, tx.Tx, identity.ProviderPrincipal) (*identity.ProviderBinding, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.binding == nil {
		return nil, nil
	}
	c := *s.binding
	return &c, nil
}
func (s *testStore) InsertProviderBindingTx(_ context.Context, t tx.Tx, b identity.ProviderBinding) error {
	s.mu.Lock()
	s.bindingInserts++
	s.mu.Unlock()
	t.(*testTx).stage(func() { s.mu.Lock(); defer s.mu.Unlock(); c := b; s.binding = &c })
	return nil
}
func (s *testStore) InsertSessionTx(_ context.Context, t tx.Tx, v identity.Session) error {
	s.mu.Lock()
	s.sessionInserts++
	s.mu.Unlock()
	t.(*testTx).stage(func() {
		s.mu.Lock()
		defer s.mu.Unlock()
		if s.sessions == nil {
			s.sessions = map[string]identity.Session{}
		}
		s.sessions[v.ID.UUID().String()] = v
	})
	return nil
}
func (s *testStore) InsertSessionCredentialTx(_ context.Context, t tx.Tx, c identity.SessionCredential) error {
	s.mu.Lock()
	s.credInserts++
	n := s.credInserts
	fail := s.failCredentialAt == n
	s.mu.Unlock()
	if fail {
		return errors.New("credential insert failure")
	}
	t.(*testTx).stage(func() {
		s.mu.Lock()
		defer s.mu.Unlock()
		if s.creds == nil {
			s.creds = map[string][]identity.SessionCredential{}
		}
		k := c.SessionID.UUID().String()
		s.creds[k] = append(s.creds[k], c)
	})
	return nil
}
func (s *testStore) LockSessionTx(_ context.Context, _ tx.Tx, id identity.SessionID) (identity.Session, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.lockOrder = append(s.lockOrder, "session")
	return s.sessions[id.UUID().String()], nil
}
func (s *testStore) LockLiveContextTx(context.Context, tx.Tx, identity.SessionID) (*identity.GameplayContext, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.lockOrder = append(s.lockOrder, "context")
	if s.context == nil {
		return nil, nil
	}
	c := *s.context
	return &c, nil
}
func (s *testStore) SaveRevokedSessionTx(_ context.Context, t tx.Tx, v identity.Session, _ int64) error {
	t.(*testTx).stage(func() { s.mu.Lock(); defer s.mu.Unlock(); s.sessions[v.ID.UUID().String()] = v })
	return nil
}
func (s *testStore) SaveEndedContextTx(_ context.Context, t tx.Tx, v identity.GameplayContext, _ int64) error {
	if s.failSaveContext {
		return errors.New("context save failure")
	}
	t.(*testTx).stage(func() { s.mu.Lock(); defer s.mu.Unlock(); c := v; s.context = &c })
	return nil
}
func (s *testStore) RevokeSessionCredentialsTx(_ context.Context, t tx.Tx, sid identity.SessionID, at time.Time) error {
	s.mu.Lock()
	s.lockOrder = append(s.lockOrder, "session_credentials")
	s.mu.Unlock()
	t.(*testTx).stage(func() {
		s.mu.Lock()
		defer s.mu.Unlock()
		k := sid.UUID().String()
		for i := range s.creds[k] {
			if s.creds[k][i].RevokedAt == nil {
				x := at
				s.creds[k][i].RevokedAt = &x
			}
		}
		s.revokeSessionCreds++
	})
	return nil
}
func (s *testStore) RevokeGameplayCredentialsTx(_ context.Context, t tx.Tx, _ identity.SessionID, _ time.Time) error {
	s.mu.Lock()
	s.lockOrder = append(s.lockOrder, "gameplay_credentials")
	s.mu.Unlock()
	t.(*testTx).stage(func() { s.mu.Lock(); s.revokeGameplayCreds++; s.mu.Unlock() })
	return nil
}
func (s *testStore) TouchSessionActivityTx(_ context.Context, t tx.Tx, sid identity.SessionID, cutoff, now time.Time) (bool, error) {
	s.mu.Lock()
	cur := s.sessions[sid.UUID().String()]
	eligible := cur.RevokedAt == nil && cur.IdleTimeoutSeconds != nil && !cur.LastActivityAt.After(cutoff)
	s.mu.Unlock()
	if !eligible {
		return false, nil
	}
	t.(*testTx).stage(func() {
		s.mu.Lock()
		defer s.mu.Unlock()
		v := s.sessions[sid.UUID().String()]
		v.LastActivityAt = now
		s.sessions[sid.UUID().String()] = v
		s.touches++
	})
	return true, nil
}

type testNotifier struct {
	calls     int
	err       error
	committed func() bool
}

func (n *testNotifier) SessionRevoked(context.Context, identity.SessionID, string) error {
	if n.committed != nil && !n.committed() {
		return errors.New("notification before commit")
	}
	n.calls++
	return n.err
}

func uuid(last byte) ids.UUID { var u ids.UUID; u[15] = last; return u }
func aid(t *testing.T, b byte) identity.AccountID {
	x, e := identity.AccountIDFrom(uuid(b))
	if e != nil {
		t.Fatal(e)
	}
	return x
}
func sid(t *testing.T, b byte) identity.SessionID {
	x, e := identity.SessionIDFrom(uuid(b))
	if e != nil {
		t.Fatal(e)
	}
	return x
}
func cid(t *testing.T, b byte) identity.ContextID {
	x, e := identity.ContextIDFrom(uuid(b))
	if e != nil {
		t.Fatal(e)
	}
	return x
}
func bid(t *testing.T, b byte) identity.BindingID {
	x, e := identity.BindingIDFrom(uuid(b))
	if e != nil {
		t.Fatal(e)
	}
	return x
}
func crid(t *testing.T, b byte) identity.CredentialID {
	x, e := identity.CredentialIDFrom(uuid(b))
	if e != nil {
		t.Fatal(e)
	}
	return x
}
func op(b byte) operation.Context {
	return operation.Context{ID: uuid(b), StartedAt: time.Unix(1700000000+int64(b), 0).UTC()}
}
func liveAccount(t *testing.T) identity.Account {
	return identity.Account{ID: aid(t, 1), UID: "20000007", Status: identity.AccountActive, CreatedAt: time.Unix(1, 0).UTC(), LivenessVersion: 1}
}
func service(st *testStore, db *testBeginner, rs *memReceipts) Service {
	return Service{Runner: tx.Runner{DB: db}, Store: st, Receipts: rs, ReceiptRead: rs}
}

func TestBindPrincipalReplayCreatesOnce(t *testing.T) {
	a := liveAccount(t)
	st := &testStore{account: a}
	db := &testBeginner{}
	rs := newMemReceipts()
	svc := service(st, db, rs)
	b := identity.ProviderBinding{ID: bid(t, 9), AccountID: a.ID, Principal: identity.ProviderPrincipal{ProviderKey: "xinyd", SubjectNormalized: "subject-1"}, LinkedAt: op(1).StartedAt}
	first, e := svc.BindPrincipal(context.Background(), BindPrincipalCommand{AccountID: a.ID, Binding: b}, op(1))
	if e != nil {
		t.Fatal(e)
	}
	second, e := svc.BindPrincipal(context.Background(), BindPrincipalCommand{AccountID: a.ID, Binding: b}, op(2))
	if e != nil {
		t.Fatal(e)
	}
	if !first.Created || !second.Created || first.BindingID != second.BindingID {
		t.Fatalf("unexpected replay result: %#v %#v", first, second)
	}
	if st.bindingInserts != 1 {
		t.Fatalf("binding inserted %d times", st.bindingInserts)
	}
}

func TestIssueSessionFailureRollsBackPartialState(t *testing.T) {
	a := liveAccount(t)
	st := &testStore{account: a, failCredentialAt: 2}
	db := &testBeginner{}
	rs := newMemReceipts()
	svc := service(st, db, rs)
	now := op(3).StartedAt
	s := identity.Session{ID: sid(t, 2), AccountID: a.ID, AuthProfile: identity.AuthProductionPair, IssuedAt: now, LastActivityAt: now, LivenessVersion: 1}
	var d1, d2 identity.CredentialDigest
	d1[0] = 1
	d2[0] = 2
	issue := identity.SessionIssue{Session: s, SID: identity.SessionCredential{ID: crid(t, 3), SessionID: s.ID, Kind: identity.CredentialSID, Digest: d1, IssuedAt: now}, LoginToken: identity.SessionCredential{ID: crid(t, 4), SessionID: s.ID, Kind: identity.CredentialLoginToken, Digest: d2, IssuedAt: now}}
	if _, e := svc.IssueSession(context.Background(), IssueSessionCommand{Issue: issue}, op(3)); e == nil {
		t.Fatal("expected credential failure")
	}
	if len(st.sessions) != 0 || len(st.creds) != 0 {
		t.Fatalf("partial session state committed: sessions=%d creds=%d", len(st.sessions), len(st.creds))
	}
	if len(db.txs) != 1 || !db.txs[0].rolled {
		t.Fatal("failed issuance was not rolled back")
	}
}

func TestIssueSessionReplayDoesNotDuplicate(t *testing.T) {
	a := liveAccount(t)
	st := &testStore{account: a}
	db := &testBeginner{}
	rs := newMemReceipts()
	svc := service(st, db, rs)
	now := op(4).StartedAt
	s := identity.Session{ID: sid(t, 2), AccountID: a.ID, AuthProfile: identity.AuthProductionPair, IssuedAt: now, LastActivityAt: now, LivenessVersion: 1}
	var d1, d2 identity.CredentialDigest
	d1[0] = 1
	d2[0] = 2
	issue := identity.SessionIssue{Session: s, SID: identity.SessionCredential{ID: crid(t, 3), SessionID: s.ID, Kind: identity.CredentialSID, Digest: d1, IssuedAt: now}, LoginToken: identity.SessionCredential{ID: crid(t, 4), SessionID: s.ID, Kind: identity.CredentialLoginToken, Digest: d2, IssuedAt: now}}
	if _, e := svc.IssueSession(context.Background(), IssueSessionCommand{Issue: issue}, op(4)); e != nil {
		t.Fatal(e)
	}
	if _, e := svc.IssueSession(context.Background(), IssueSessionCommand{Issue: issue}, op(5)); e != nil {
		t.Fatal(e)
	}
	if st.sessionInserts != 1 || st.credInserts != 2 {
		t.Fatalf("replay duplicated issue: sessions=%d creds=%d", st.sessionInserts, st.credInserts)
	}
}

func TestRevokeSessionAtomicLockOrderAndPostCommitHint(t *testing.T) {
	a := liveAccount(t)
	now := op(6).StartedAt
	s := identity.Session{ID: sid(t, 2), AccountID: a.ID, AuthProfile: identity.AuthProductionPair, IssuedAt: now.Add(-time.Hour), LastActivityAt: now, LivenessVersion: 3}
	c := identity.GameplayContext{ID: cid(t, 5), SessionID: s.ID, AccountID: a.ID, LogicalServerID: 1, PlayerID: 100001, ContextGeneration: 2, CreatedAt: now.Add(-time.Minute), LivenessVersion: 4}
	st := &testStore{account: a, sessions: map[string]identity.Session{s.ID.UUID().String(): s}, context: &c}
	db := &testBeginner{}
	rs := newMemReceipts()
	svc := service(st, db, rs)
	n := &testNotifier{committed: func() bool {
		return len(db.txs) > 0 && !db.txs[0].rolled && st.sessions[s.ID.UUID().String()].RevokedAt != nil
	}}
	svc.Notifier = n
	got, e := svc.RevokeSession(context.Background(), RevokeSessionCommand{SessionID: s.ID, Reason: "logout"}, op(6))
	if e != nil {
		t.Fatal(e)
	}
	if !got.Changed || !got.ContextEnded || got.SessionVersion != 4 || got.ContextVersion != 5 {
		t.Fatalf("bad revocation result: %#v", got)
	}
	want := []string{"session", "context", "session_credentials", "gameplay_credentials"}
	if len(st.lockOrder) != len(want) {
		t.Fatalf("lock order=%v", st.lockOrder)
	}
	for i := range want {
		if st.lockOrder[i] != want[i] {
			t.Fatalf("lock order=%v", st.lockOrder)
		}
	}
	if n.calls != 1 {
		t.Fatalf("post-commit hint calls=%d", n.calls)
	}
}

func TestRevokeSessionFailureRollsBackAllDurableChanges(t *testing.T) {
	a := liveAccount(t)
	now := op(7).StartedAt
	s := identity.Session{ID: sid(t, 2), AccountID: a.ID, AuthProfile: identity.AuthProductionPair, IssuedAt: now.Add(-time.Hour), LastActivityAt: now, LivenessVersion: 1}
	c := identity.GameplayContext{ID: cid(t, 5), SessionID: s.ID, AccountID: a.ID, LogicalServerID: 1, PlayerID: 100001, ContextGeneration: 1, CreatedAt: now.Add(-time.Minute), LivenessVersion: 1}
	st := &testStore{account: a, sessions: map[string]identity.Session{s.ID.UUID().String(): s}, context: &c, failSaveContext: true}
	db := &testBeginner{}
	rs := newMemReceipts()
	svc := service(st, db, rs)
	n := &testNotifier{}
	svc.Notifier = n
	if _, e := svc.RevokeSession(context.Background(), RevokeSessionCommand{SessionID: s.ID, Reason: "logout"}, op(7)); e == nil {
		t.Fatal("expected failure")
	}
	if st.sessions[s.ID.UUID().String()].RevokedAt != nil || st.context.EndedAt != nil || st.revokeSessionCreds != 0 || st.revokeGameplayCreds != 0 {
		t.Fatal("revocation failure leaked durable mutation")
	}
	if n.calls != 0 {
		t.Fatal("notified before canonical commit")
	}
}

func TestActivityTouchDisabledByDefaultAndCoalescedWhenEnabled(t *testing.T) {
	a := liveAccount(t)
	now := op(8).StartedAt
	idle := int64(3600)
	s := identity.Session{ID: sid(t, 2), AccountID: a.ID, AuthProfile: identity.AuthProductionPair, IssuedAt: now.Add(-time.Hour), LastActivityAt: now.Add(-10 * time.Minute), IdleTimeoutSeconds: &idle, LivenessVersion: 1}
	st := &testStore{account: a, sessions: map[string]identity.Session{s.ID.UUID().String(): s}}
	db := &testBeginner{}
	rs := newMemReceipts()
	svc := service(st, db, rs)
	got, e := svc.TouchActivity(context.Background(), s.ID, op(8))
	if e != nil {
		t.Fatal(e)
	}
	if got.PolicyEnabled || db.count != 0 {
		t.Fatalf("default idle policy wrote: %#v begins=%d", got, db.count)
	}
	svc.IdleExpiryEnabled = true
	svc.ActivityTouchInterval = 5 * time.Minute
	got, e = svc.TouchActivity(context.Background(), s.ID, op(8))
	if e != nil {
		t.Fatal(e)
	}
	if !got.PolicyEnabled || !got.Persisted || st.touches != 1 {
		t.Fatalf("expected persisted touch: %#v touches=%d", got, st.touches)
	}
	later := op(8)
	later.StartedAt = now.Add(time.Minute)
	got, e = svc.TouchActivity(context.Background(), s.ID, later)
	if e != nil {
		t.Fatal(e)
	}
	if got.Persisted || st.touches != 1 {
		t.Fatalf("coalescing failed: %#v touches=%d", got, st.touches)
	}
}

func TestStaticBearerKeyResolverFailsClosedForUnknownVersion(t *testing.T) {
	r := StaticBearerKeyResolver{Key: BearerDerivationKey{ID: "k1", Secret: []byte("0123456789abcdef")}}
	if _, e := r.ResolveBearerKey(context.Background(), "old"); e == nil {
		t.Fatal("unknown key unexpectedly resolved")
	}
	got, e := r.ResolveBearerKey(context.Background(), "k1")
	if e != nil || got.ID != "k1" {
		t.Fatalf("resolve current key: %#v %v", got, e)
	}
}

func TestKeyringBearerKeyResolverSupportsRetainedVerifyOnlyKeys(t *testing.T) {
	r := KeyringBearerKeyResolver{Keys: map[string]BearerDerivationKey{
		"k1": {ID: "k1", Secret: []byte("0123456789abcdef")},
		"k2": {ID: "k2", Secret: []byte("abcdef0123456789")},
	}}
	k1, err := r.ResolveBearerKey(context.Background(), "k1")
	if err != nil || k1.ID != "k1" {
		t.Fatalf("k1=%+v err=%v", k1, err)
	}
	k1.Secret[0] ^= 0xff
	k1b, err := r.ResolveBearerKey(context.Background(), "k1")
	if err != nil || string(k1b.Secret) != "0123456789abcdef" {
		t.Fatalf("resolver leaked mutable secret: %+v err=%v", k1b, err)
	}
	if _, err := r.ResolveBearerKey(context.Background(), "revoked"); err == nil {
		t.Fatal("unknown/revoked key must fail closed")
	}
}
