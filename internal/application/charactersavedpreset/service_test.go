package charactersavedpreset

import (
	"context"
	"errors"
	"fmt"
	"reflect"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type presetTestTag int64

func (t presetTestTag) RowsAffected() int64 { return int64(t) }

type presetTestRow struct{ err error }

func (r presetTestRow) Scan(...any) error { return r.err }

type presetTestTx struct{ commitErr error }

func (*presetTestTx) QueryRow(context.Context, string, ...any) tx.Row {
	return presetTestRow{err: errors.New("unexpected query")}
}
func (*presetTestTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return presetTestTag(1), nil
}
func (t *presetTestTx) Commit(context.Context) error { return t.commitErr }
func (*presetTestTx) Rollback(context.Context) error { return nil }

type presetTestDB struct {
	commitErrors []error
	begins       int
	options      []tx.Options
}

func (d *presetTestDB) Begin(_ context.Context, opts tx.Options) (tx.Tx, error) {
	var err error
	if d.begins < len(d.commitErrors) {
		err = d.commitErrors[d.begins]
	}
	d.begins++
	d.options = append(d.options, opts)
	return &presetTestTx{commitErr: err}, nil
}

type presetFence struct{ calls atomic.Int64 }

func (f *presetFence) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	f.calls.Add(1)
	return nil
}

type presetReceipts struct {
	mu           sync.Mutex
	m            map[receipt.Identity]receipt.Receipt
	hideExternal bool
}

func (r *presetReceipts) PutTx(_ context.Context, _ tx.Tx, x receipt.Receipt) (receipt.PutResult, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.m == nil {
		r.m = map[receipt.Identity]receipt.Receipt{}
	}
	if got, ok := r.m[x.Identity]; ok {
		return receipt.PutResult{Receipt: got, Inserted: false}, nil
	}
	r.m[x.Identity] = x
	return receipt.PutResult{Receipt: x, Inserted: true}, nil
}
func (r *presetReceipts) FindTx(_ context.Context, _ tx.Queryer, id receipt.Identity) (receipt.Receipt, bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	x, ok := r.m[id]
	return x, ok, nil
}
func (r *presetReceipts) Find(_ context.Context, id receipt.Identity) (receipt.Receipt, bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.hideExternal {
		return receipt.Receipt{}, false, nil
	}
	x, ok := r.m[id]
	return x, ok, nil
}

type presetMutationStore struct {
	reads        []character.SavedPresetAggregate
	readIndex    int
	replacements []character.SavedPresetAggregate
	expected     []int64
	events       *[]string
}

func (s *presetMutationStore) ReadSavedPresetAggregateTx(context.Context, tx.Queryer, identity.PlayerID) (character.SavedPresetAggregate, error) {
	if s.readIndex >= len(s.reads) {
		return character.SavedPresetAggregate{}, errors.New("saved preset test: unexpected aggregate read")
	}
	a := s.reads[s.readIndex]
	s.readIndex++
	if s.events != nil {
		*s.events = append(*s.events, fmt.Sprintf("read:v%d", a.Root.StateVersion))
	}
	return a, nil
}
func (s *presetMutationStore) LockSavedPresetRootTx(context.Context, tx.Tx, identity.PlayerID) (character.SavedPresetRoot, error) {
	if s.readIndex >= len(s.reads) {
		return character.SavedPresetRoot{}, errors.New("saved preset test: root lock without locked read fixture")
	}
	r := s.reads[s.readIndex].Root
	if s.events != nil {
		*s.events = append(*s.events, fmt.Sprintf("root:v%d", r.StateVersion))
	}
	return r, nil
}
func (s *presetMutationStore) ReplaceSavedPresetAggregateTx(_ context.Context, _ tx.Tx, a character.SavedPresetAggregate, expected int64) error {
	s.replacements = append(s.replacements, a)
	s.expected = append(s.expected, expected)
	if s.events != nil {
		*s.events = append(*s.events, fmt.Sprintf("replace:%d->%d", expected, a.Root.StateVersion))
	}
	return nil
}
func (*presetMutationStore) EnsureSavedPresetRootTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (bool, error) {
	return false, nil
}

type presetHeroOwner struct{ events *[]string }

func (o presetHeroOwner) HeroReferenceLockKey(r character.HeroRef) (lockkey.Key, error) {
	return characterasset.HeroReferenceLockKey(r)
}
func (o presetHeroOwner) LockHeroReferenceKeyTx(_ context.Context, _ tx.Tx, _ lockkey.Key, r character.HeroRef) error {
	if o.events != nil {
		*o.events = append(*o.events, fmt.Sprintf("hero:%d", r.PartnerID))
	}
	return nil
}

type presetPetOwner struct{ events *[]string }

func (o presetPetOwner) PetReferenceLockKey(r character.PetRef) (lockkey.Key, error) {
	return characterasset.PetReferenceLockKey(r)
}
func (o presetPetOwner) LockPetReferenceKeyTx(_ context.Context, _ tx.Tx, _ lockkey.Key, r character.PetRef) error {
	if o.events != nil {
		*o.events = append(*o.events, fmt.Sprintf("pet:%d", r.PetID))
	}
	return nil
}

type presetRejectHeroOwner struct {
	rejectID int64
}

func (o presetRejectHeroOwner) HeroReferenceLockKey(r character.HeroRef) (lockkey.Key, error) {
	return characterasset.HeroReferenceLockKey(r)
}
func (o presetRejectHeroOwner) LockHeroReferenceKeyTx(_ context.Context, _ tx.Tx, _ lockkey.Key, r character.HeroRef) error {
	if r.PartnerID == o.rejectID {
		return characterasset.ErrReferenceNotFound
	}
	return nil
}

type presetRejectPetOwner struct {
	rejectID int64
}

func (o presetRejectPetOwner) PetReferenceLockKey(r character.PetRef) (lockkey.Key, error) {
	return characterasset.PetReferenceLockKey(r)
}
func (o presetRejectPetOwner) LockPetReferenceKeyTx(_ context.Context, _ tx.Tx, _ lockkey.Key, r character.PetRef) error {
	if r.PetID == o.rejectID {
		return characterasset.ErrReferenceNotFound
	}
	return nil
}

type presetLockingTx struct {
	mu      sync.Mutex
	unlocks []func()
}

func (*presetLockingTx) QueryRow(context.Context, string, ...any) tx.Row {
	return presetTestRow{err: errors.New("unexpected query")}
}
func (*presetLockingTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return presetTestTag(1), nil
}
func (t *presetLockingTx) Commit(context.Context) error {
	t.release()
	return nil
}
func (t *presetLockingTx) Rollback(context.Context) error {
	t.release()
	return nil
}
func (t *presetLockingTx) acquire(m *sync.Mutex) {
	m.Lock()
	t.mu.Lock()
	t.unlocks = append(t.unlocks, m.Unlock)
	t.mu.Unlock()
}
func (t *presetLockingTx) release() {
	t.mu.Lock()
	unlocks := t.unlocks
	t.unlocks = nil
	t.mu.Unlock()
	for i := len(unlocks) - 1; i >= 0; i-- {
		unlocks[i]()
	}
}

type presetLockingDB struct {
	mu     sync.Mutex
	begins int
}

func (d *presetLockingDB) Begin(context.Context, tx.Options) (tx.Tx, error) {
	d.mu.Lock()
	d.begins++
	d.mu.Unlock()
	return &presetLockingTx{}, nil
}
func (d *presetLockingDB) beginCount() int {
	d.mu.Lock()
	defer d.mu.Unlock()
	return d.begins
}

type presetKeyLocks struct {
	mu sync.Mutex
	m  map[string]*sync.Mutex
}

func (l *presetKeyLocks) forKey(k lockkey.Key) *sync.Mutex {
	id := fmt.Sprintf("%d/%s/%d/%x", k.DomainRank, k.OwnerKind, k.Identity.Kind, k.Identity.Raw())
	l.mu.Lock()
	defer l.mu.Unlock()
	if l.m == nil {
		l.m = map[string]*sync.Mutex{}
	}
	if l.m[id] == nil {
		l.m[id] = &sync.Mutex{}
	}
	return l.m[id]
}

type presetConcurrentOwner struct{ locks *presetKeyLocks }

func (o presetConcurrentOwner) HeroReferenceLockKey(r character.HeroRef) (lockkey.Key, error) {
	return characterasset.HeroReferenceLockKey(r)
}
func (o presetConcurrentOwner) LockHeroReferenceKeyTx(_ context.Context, t tx.Tx, k lockkey.Key, _ character.HeroRef) error {
	lt, ok := t.(*presetLockingTx)
	if !ok {
		return errors.New("unexpected tx type")
	}
	lt.acquire(o.locks.forKey(k))
	return nil
}
func (o presetConcurrentOwner) PetReferenceLockKey(r character.PetRef) (lockkey.Key, error) {
	return characterasset.PetReferenceLockKey(r)
}
func (o presetConcurrentOwner) LockPetReferenceKeyTx(_ context.Context, t tx.Tx, k lockkey.Key, _ character.PetRef) error {
	lt, ok := t.(*presetLockingTx)
	if !ok {
		return errors.New("unexpected tx type")
	}
	lt.acquire(o.locks.forKey(k))
	return nil
}

type presetConcurrentStore struct {
	stateMu    sync.RWMutex
	rootMu     sync.Mutex
	state      character.SavedPresetAggregate
	barrierMu  sync.Mutex
	firstReads int
	bothRead   chan struct{}
}

func newPresetConcurrentStore(initial character.SavedPresetAggregate) *presetConcurrentStore {
	return &presetConcurrentStore{state: initial, bothRead: make(chan struct{})}
}
func (s *presetConcurrentStore) ReadSavedPresetAggregateTx(context.Context, tx.Queryer, identity.PlayerID) (character.SavedPresetAggregate, error) {
	s.barrierMu.Lock()
	s.firstReads++
	n := s.firstReads
	s.barrierMu.Unlock()

	// Freeze both first-attempt preflight snapshots before releasing either
	// goroutine. This forces the second edit to demonstrate locked-reread drift
	// handling instead of merely observing the first commit during preflight.
	s.stateMu.RLock()
	snapshot := character.SavedPresetAggregate{Root: s.state.Root, Lanes: cloneSavedPresetLanes(s.state.Lanes)}
	s.stateMu.RUnlock()
	if n <= 2 {
		s.barrierMu.Lock()
		if n == 2 {
			close(s.bothRead)
		}
		s.barrierMu.Unlock()
		<-s.bothRead
	}
	return snapshot, nil
}
func (s *presetConcurrentStore) LockSavedPresetRootTx(_ context.Context, t tx.Tx, _ identity.PlayerID) (character.SavedPresetRoot, error) {
	lt, ok := t.(*presetLockingTx)
	if !ok {
		return character.SavedPresetRoot{}, errors.New("unexpected tx type")
	}
	lt.acquire(&s.rootMu)
	s.stateMu.RLock()
	defer s.stateMu.RUnlock()
	return s.state.Root, nil
}
func (s *presetConcurrentStore) ReplaceSavedPresetAggregateTx(_ context.Context, _ tx.Tx, desired character.SavedPresetAggregate, expected int64) error {
	s.stateMu.Lock()
	defer s.stateMu.Unlock()
	if s.state.Root.StateVersion != expected {
		return ErrStaleVersion
	}
	s.state = character.SavedPresetAggregate{Root: desired.Root, Lanes: cloneSavedPresetLanes(desired.Lanes)}
	return nil
}
func (*presetConcurrentStore) EnsureSavedPresetRootTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (bool, error) {
	return false, nil
}
func (s *presetConcurrentStore) snapshot() character.SavedPresetAggregate {
	s.stateMu.RLock()
	defer s.stateMu.RUnlock()
	return character.SavedPresetAggregate{Root: s.state.Root, Lanes: cloneSavedPresetLanes(s.state.Lanes)}
}

func presetTestActor(t *testing.T) identity.ActorContext {
	t.Helper()
	u, err := ids.ParseUUID("11111111-1111-4111-8111-111111111111")
	if err != nil {
		t.Fatal(err)
	}
	a, _ := identity.AccountIDFrom(u)
	s, _ := identity.SessionIDFrom(u)
	c, _ := identity.ContextIDFrom(u)
	return identity.ActorContext{AccountID: a, AccountUID: "u", SessionID: s, ContextID: c, LogicalServerID: 1, PlayerID: 7, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}

func presetTestOp(t *testing.T, raw string) operation.Context {
	t.Helper()
	u, err := ids.ParseUUID(raw)
	if err != nil {
		t.Fatal(err)
	}
	return operation.Context{ID: u, StartedAt: time.Unix(500, 0).UTC()}
}

func aggregateVersion(pid identity.PlayerID, version int64, lanes ...character.SavedPresetLane) character.SavedPresetAggregate {
	now := time.Unix(100, 0).UTC()
	return character.SavedPresetAggregate{Root: character.SavedPresetRoot{PlayerID: pid, StateVersion: version, CreatedAt: now, UpdatedAt: now}, Lanes: lanes}
}

func mutationServiceFor(db tx.Beginner, st Store, fence ActorFencer, hero characterasset.HeroReferenceOwner, pet characterasset.PetReferenceOwner, receipts *presetReceipts) MutationService {
	return MutationService{
		Runner: tx.Runner{DB: db}, Store: st, Fencer: fence,
		References: ReferenceOwners{Heroes: hero, Pets: pet}, Receipts: receipts, ReceiptRead: receipts,
	}
}

func TestMutationUsesFoundationReadCommittedIsolation(t *testing.T) {
	current := aggregateVersion(7, 5, presetLane(7, "A", []int64{1}, 8))
	st := &presetMutationStore{reads: []character.SavedPresetAggregate{current, current}}
	db := &presetTestDB{}
	rr := &presetReceipts{}
	svc := mutationServiceFor(db, st, &presetFence{}, presetHeroOwner{}, presetPetOwner{}, rr)

	_, err := svc.Replace(context.Background(), presetTestActor(t), Command{TeamString: "1", TeamNameString: "A", PetPresent: true, PetString: "8"}, presetTestOp(t, "12121212-1212-4212-8212-121212121212"))
	if err != nil {
		t.Fatal(err)
	}
	if len(db.options) != 1 || db.options[0].Isolation != tx.ReadCommitted {
		t.Fatalf("transaction options=%+v, want one READ COMMITTED transaction", db.options)
	}
}

func TestMutationReplaceReplansWholeBodyWhenLockedRereadAddsOldReference(t *testing.T) {
	events := []string{}
	v1 := aggregateVersion(7, 1, presetLane(7, "A", []int64{1}, 8))
	v2 := aggregateVersion(7, 2, presetLane(7, "A", []int64{1}, 8), presetLane(7, "C", []int64{3}, 10))
	st := &presetMutationStore{reads: []character.SavedPresetAggregate{v1, v2, v2, v2}, events: &events}
	db := &presetTestDB{}
	rr := &presetReceipts{}
	fence := &presetFence{}
	svc := mutationServiceFor(db, st, fence, presetHeroOwner{&events}, presetPetOwner{&events}, rr)

	out, err := svc.Replace(context.Background(), presetTestActor(t), Command{TeamString: "2", TeamNameString: "B", PetPresent: true, PetString: "9"}, presetTestOp(t, "22222222-2222-4222-8222-222222222222"))
	if err != nil {
		t.Fatal(err)
	}
	if db.begins != 2 || fence.calls.Load() != 2 {
		t.Fatalf("begins=%d fences=%d events=%v", db.begins, fence.calls.Load(), events)
	}
	if len(st.replacements) != 1 || st.expected[0] != 2 || st.replacements[0].Root.StateVersion != 3 {
		t.Fatalf("replacements=%+v expected=%v", st.replacements, st.expected)
	}
	if out.Wire != (WireProjection{SaveTeam: "2", SaveTeamName: "B", SavePet: "9"}) || out.StateVersion != 3 || !out.Mutated {
		t.Fatalf("out=%+v", out)
	}
	// The first attempt did not know Hero3/Pet10. The second attempt must
	// rediscover and lock them before the eventual replacement.
	wantSubsequence := []string{"read:v1", "hero:1", "hero:2", "pet:8", "pet:9", "root:v2", "read:v2", "read:v2", "hero:1", "hero:2", "hero:3", "pet:8", "pet:9", "pet:10", "root:v2", "read:v2", "replace:2->3"}
	if !reflect.DeepEqual(events, wantSubsequence) {
		t.Fatalf("events=%v\nwant=%v", events, wantSubsequence)
	}
}

func TestMutationConvergenceKeepsRevisionAndWritesReplayableReceipt(t *testing.T) {
	current := aggregateVersion(7, 5, presetLane(7, "A", []int64{1}, 8))
	st := &presetMutationStore{reads: []character.SavedPresetAggregate{current, current}}
	db := &presetTestDB{}
	rr := &presetReceipts{}
	fence := &presetFence{}
	svc := mutationServiceFor(db, st, fence, presetHeroOwner{}, presetPetOwner{}, rr)
	op := presetTestOp(t, "33333333-3333-4333-8333-333333333333")
	cmd := Command{TeamString: "1", TeamNameString: "A", PetPresent: true, PetString: "8"}

	first, err := svc.Replace(context.Background(), presetTestActor(t), cmd, op)
	if err != nil {
		t.Fatal(err)
	}
	if first.Mutated || first.StateVersion != 5 || first.Replayed || len(st.replacements) != 0 || len(rr.m) != 1 {
		t.Fatalf("first=%+v replacements=%d receipts=%d", first, len(st.replacements), len(rr.m))
	}
	reads := st.readIndex
	second, err := svc.Replace(context.Background(), presetTestActor(t), cmd, op)
	if err != nil {
		t.Fatal(err)
	}
	if !second.Replayed || second.Mutated || second.StateVersion != 5 || st.readIndex != reads {
		t.Fatalf("second=%+v reads=%d/%d", second, reads, st.readIndex)
	}
}

func TestMutationLegacyAmbiguityFailsClosedAfterLocksWithoutReceiptOrWrite(t *testing.T) {
	current := aggregateVersion(7, 4,
		presetLane(7, "A", []int64{1}, 8),
		presetLane(7, "A", []int64{1}, 9),
	)
	st := &presetMutationStore{reads: []character.SavedPresetAggregate{current, current}}
	db := &presetTestDB{}
	rr := &presetReceipts{}
	svc := mutationServiceFor(db, st, &presetFence{}, presetHeroOwner{}, presetPetOwner{}, rr)
	_, err := svc.Replace(context.Background(), presetTestActor(t), Command{TeamString: "1", TeamNameString: "A"}, presetTestOp(t, "44444444-4444-4444-8444-444444444444"))
	if !errors.Is(err, ErrAmbiguousLegacyDelete) {
		t.Fatalf("err=%v", err)
	}
	if len(st.replacements) != 0 || len(rr.m) != 0 {
		t.Fatalf("writes=%d receipts=%d", len(st.replacements), len(rr.m))
	}
}

func TestMutationUnknownCommitReconcilesFromSameAttemptReceipt(t *testing.T) {
	current := aggregateVersion(7, 2, presetLane(7, "A", []int64{1}, 8))
	st := &presetMutationStore{reads: []character.SavedPresetAggregate{current, current}}
	db := &presetTestDB{commitErrors: []error{errors.New("transport lost after COMMIT")}}
	rr := &presetReceipts{}
	svc := mutationServiceFor(db, st, &presetFence{}, presetHeroOwner{}, presetPetOwner{}, rr)
	out, err := svc.Replace(context.Background(), presetTestActor(t), Command{TeamString: "2", TeamNameString: "B", PetPresent: true, PetString: "9"}, presetTestOp(t, "55555555-5555-4555-8555-555555555555"))
	if err != nil {
		t.Fatal(err)
	}
	if !out.Replayed || !out.Mutated || out.StateVersion != 3 || out.Wire.SaveTeam != "2" {
		t.Fatalf("out=%+v", out)
	}
}

func TestMutationFingerprintDistinguishesMissingAndPresentEmptyPet(t *testing.T) {
	a, err := savedPresetFingerprint(Command{TeamString: "", TeamNameString: "", PetPresent: false})
	if err != nil {
		t.Fatal(err)
	}
	b, err := savedPresetFingerprint(Command{TeamString: "", TeamNameString: "", PetPresent: true, PetString: ""})
	if err != nil {
		t.Fatal(err)
	}
	if a == b {
		t.Fatal("missing pet_str collapsed with present-empty pet_str")
	}
}

func TestMutationCoveredLockedDriftContinuesWithoutRetry(t *testing.T) {
	events := []string{}
	v1 := aggregateVersion(7, 1, presetLane(7, "A", []int64{1}, 8))
	v2 := aggregateVersion(7, 2, presetLane(7, "B", []int64{2}, 9))
	st := &presetMutationStore{reads: []character.SavedPresetAggregate{v1, v2}, events: &events}
	db := &presetTestDB{}
	rr := &presetReceipts{}
	svc := mutationServiceFor(db, st, &presetFence{}, presetHeroOwner{events: &events}, presetPetOwner{events: &events}, rr)

	out, err := svc.Replace(context.Background(), presetTestActor(t), Command{TeamString: "2", TeamNameString: "B", PetPresent: true, PetString: "9"}, presetTestOp(t, "66666666-6666-4666-8666-666666666666"))
	if err != nil {
		t.Fatal(err)
	}
	if db.begins != 1 || st.readIndex != 2 || len(st.replacements) != 0 || out.Mutated || out.StateVersion != 2 {
		t.Fatalf("begins=%d reads=%d replacements=%d out=%+v events=%v", db.begins, st.readIndex, len(st.replacements), out, events)
	}
	want := []string{"read:v1", "hero:1", "hero:2", "pet:8", "pet:9", "root:v2", "read:v2"}
	if !reflect.DeepEqual(events, want) {
		t.Fatalf("events=%v want=%v", events, want)
	}
}

func TestMutationMissingHeroOrPetReferenceFailsClosedBeforeRootMutation(t *testing.T) {
	current := aggregateVersion(7, 1, presetLane(7, "A", []int64{1}, 8))
	cmd := Command{TeamString: "2", TeamNameString: "B", PetPresent: true, PetString: "9"}
	for _, tc := range []struct {
		name string
		hero characterasset.HeroReferenceOwner
		pet  characterasset.PetReferenceOwner
	}{
		{name: "hero", hero: presetRejectHeroOwner{rejectID: 2}, pet: presetPetOwner{}},
		{name: "pet", hero: presetHeroOwner{}, pet: presetRejectPetOwner{rejectID: 9}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			st := &presetMutationStore{reads: []character.SavedPresetAggregate{current}}
			db := &presetTestDB{}
			rr := &presetReceipts{}
			svc := mutationServiceFor(db, st, &presetFence{}, tc.hero, tc.pet, rr)
			_, err := svc.Replace(context.Background(), presetTestActor(t), cmd, presetTestOp(t, "77777777-7777-4777-8777-777777777777"))
			if !errors.Is(err, characterasset.ErrReferenceNotFound) {
				t.Fatalf("err=%v", err)
			}
			if len(st.replacements) != 0 || len(rr.m) != 0 {
				t.Fatalf("writes=%d receipts=%d", len(st.replacements), len(rr.m))
			}
		})
	}
}

func TestBuildLockPlanRejectsForeignActorScopedReferences(t *testing.T) {
	svc := MutationService{References: ReferenceOwners{Heroes: presetHeroOwner{}, Pets: presetPetOwner{}}}
	foreignHero := presetLane(8, "A", []int64{1}, 0)
	if _, err := svc.buildLockPlan(7, []character.SavedPresetLane{foreignHero}, nil); err == nil {
		t.Fatal("foreign Hero reference was accepted")
	}
	foreignPet := presetLane(8, "A", []int64{1}, 9)
	foreignPet.Heroes[0].PlayerID = 7
	if _, err := svc.buildLockPlan(7, []character.SavedPresetLane{foreignPet}, nil); err == nil {
		t.Fatal("foreign Pet reference was accepted")
	}
}

func TestMutationSameOperationDifferentFingerprintConflictsBeforeTransaction(t *testing.T) {
	current := aggregateVersion(7, 2, presetLane(7, "A", []int64{1}, 8))
	st := &presetMutationStore{reads: []character.SavedPresetAggregate{current, current}}
	db := &presetTestDB{}
	rr := &presetReceipts{}
	svc := mutationServiceFor(db, st, &presetFence{}, presetHeroOwner{}, presetPetOwner{}, rr)
	op := presetTestOp(t, "88888888-8888-4888-8888-888888888888")
	if _, err := svc.Replace(context.Background(), presetTestActor(t), Command{TeamString: "1", TeamNameString: "A", PetPresent: true, PetString: "8"}, op); err != nil {
		t.Fatal(err)
	}
	begins := db.begins
	_, err := svc.Replace(context.Background(), presetTestActor(t), Command{TeamString: "1", TeamNameString: "A", PetPresent: true, PetString: "0"}, op)
	var conflict *receipt.ConflictError
	if !errors.As(err, &conflict) {
		t.Fatalf("err=%v", err)
	}
	if db.begins != begins {
		t.Fatalf("conflict entered transaction begins=%d want=%d", db.begins, begins)
	}
}

func TestMutationUnknownCommitWithoutVisibleReceiptRemainsUnknownAndDoesNotReplay(t *testing.T) {
	current := aggregateVersion(7, 2, presetLane(7, "A", []int64{1}, 8))
	st := &presetMutationStore{reads: []character.SavedPresetAggregate{current, current}}
	db := &presetTestDB{commitErrors: []error{errors.New("ambiguous COMMIT")}}
	rr := &presetReceipts{hideExternal: true}
	svc := mutationServiceFor(db, st, &presetFence{}, presetHeroOwner{}, presetPetOwner{}, rr)
	_, err := svc.Replace(context.Background(), presetTestActor(t), Command{TeamString: "2", TeamNameString: "B", PetPresent: true, PetString: "9"}, presetTestOp(t, "99999999-9999-4999-8999-999999999999"))
	var unknown *tx.UnknownCommitError
	if !errors.As(err, &unknown) {
		t.Fatalf("err=%v", err)
	}
	if db.begins != 1 || len(st.replacements) != 1 {
		t.Fatalf("unknown COMMIT was replayed: begins=%d replacements=%d", db.begins, len(st.replacements))
	}
}

func TestMutationLaterOperationConvergesAndABARemainsTwoRealTransitions(t *testing.T) {
	actor := presetTestActor(t)
	a := aggregateVersion(7, 1, presetLane(7, "A", []int64{1}, 8))
	b := aggregateVersion(7, 2, presetLane(7, "B", []int64{2}, 9))
	rr := &presetReceipts{}

	stAB := &presetMutationStore{reads: []character.SavedPresetAggregate{a, a}}
	dbAB := &presetTestDB{}
	svcAB := mutationServiceFor(dbAB, stAB, &presetFence{}, presetHeroOwner{}, presetPetOwner{}, rr)
	outAB, err := svcAB.Replace(context.Background(), actor, Command{TeamString: "2", TeamNameString: "B", PetPresent: true, PetString: "9"}, presetTestOp(t, "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"))
	if err != nil || !outAB.Mutated || outAB.StateVersion != 2 {
		t.Fatalf("A->B out=%+v err=%v", outAB, err)
	}

	stRetry := &presetMutationStore{reads: []character.SavedPresetAggregate{b, b}}
	dbRetry := &presetTestDB{}
	svcRetry := mutationServiceFor(dbRetry, stRetry, &presetFence{}, presetHeroOwner{}, presetPetOwner{}, rr)
	outRetry, err := svcRetry.Replace(context.Background(), actor, Command{TeamString: "2", TeamNameString: "B", PetPresent: true, PetString: "9"}, presetTestOp(t, "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"))
	if err != nil || outRetry.Mutated || outRetry.Replayed || outRetry.StateVersion != 2 || len(stRetry.replacements) != 0 {
		t.Fatalf("later retry out=%+v err=%v replacements=%d", outRetry, err, len(stRetry.replacements))
	}

	stBA := &presetMutationStore{reads: []character.SavedPresetAggregate{b, b}}
	dbBA := &presetTestDB{}
	svcBA := mutationServiceFor(dbBA, stBA, &presetFence{}, presetHeroOwner{}, presetPetOwner{}, rr)
	outBA, err := svcBA.Replace(context.Background(), actor, Command{TeamString: "1", TeamNameString: "A", PetPresent: true, PetString: "8"}, presetTestOp(t, "cccccccc-cccc-4ccc-8ccc-cccccccccccc"))
	if err != nil || !outBA.Mutated || outBA.StateVersion != 3 || len(stBA.replacements) != 1 {
		t.Fatalf("B->A out=%+v err=%v replacements=%d", outBA, err, len(stBA.replacements))
	}
	if len(rr.m) != 3 {
		t.Fatalf("receipts=%d want=3 distinct operations", len(rr.m))
	}
}

func TestMutationLockPlanUsesSameHeroPetKeysAsFutureRemovalGuards(t *testing.T) {
	old := []character.SavedPresetLane{presetLane(7, "A", []int64{10, 2}, 9)}
	desired := []character.SavedPresetLane{presetLane(7, "B", []int64{3}, 11)}
	svc := MutationService{References: ReferenceOwners{Heroes: presetHeroOwner{}, Pets: presetPetOwner{}}}
	plan, err := svc.buildLockPlan(7, old, desired)
	if err != nil {
		t.Fatal(err)
	}
	wantHeroes := []character.HeroRef{{PlayerID: 7, PartnerID: 2}, {PlayerID: 7, PartnerID: 3}, {PlayerID: 7, PartnerID: 10}}
	if len(plan.Heroes) != len(wantHeroes) {
		t.Fatalf("Hero locks=%v", plan.Heroes)
	}
	for i, want := range wantHeroes {
		wk, _ := characterasset.HeroReferenceLockKey(want)
		if plan.Heroes[i].ref != want || lockkey.Compare(plan.Heroes[i].key, wk) != 0 {
			t.Fatalf("Hero lock[%d]=%+v want ref=%+v key=%+v", i, plan.Heroes[i], want, wk)
		}
	}
	wantPets := []character.PetRef{{PlayerID: 7, PetID: 9}, {PlayerID: 7, PetID: 11}}
	if len(plan.Pets) != len(wantPets) {
		t.Fatalf("Pet locks=%v", plan.Pets)
	}
	for i, want := range wantPets {
		wk, _ := characterasset.PetReferenceLockKey(want)
		if plan.Pets[i].ref != want || lockkey.Compare(plan.Pets[i].key, wk) != 0 {
			t.Fatalf("Pet lock[%d]=%+v want ref=%+v key=%+v", i, plan.Pets[i], want, wk)
		}
	}
	if plan.Root.DomainRank != characterasset.SavedPresetRootLockRank || plan.Root.DomainRank <= plan.Pets[len(plan.Pets)-1].key.DomainRank {
		t.Fatalf("root lock=%+v pets=%+v", plan.Root, plan.Pets)
	}
}

func TestMutationConcurrentEditsSerializeThroughSharedOldReferenceAndReplan(t *testing.T) {
	initial := aggregateVersion(7, 1, presetLane(7, "A", []int64{1}, 8))
	st := newPresetConcurrentStore(initial)
	db := &presetLockingDB{}
	locks := &presetKeyLocks{}
	owner := presetConcurrentOwner{locks: locks}
	rr := &presetReceipts{}
	svc := mutationServiceFor(db, st, &presetFence{}, owner, owner, rr)
	actor := presetTestActor(t)

	type result struct {
		out MutationResult
		err error
	}
	results := make(chan result, 2)
	go func() {
		out, err := svc.Replace(context.Background(), actor, Command{TeamString: "2", TeamNameString: "B", PetPresent: true, PetString: "9"}, presetTestOp(t, "dddddddd-dddd-4ddd-8ddd-dddddddddddd"))
		results <- result{out: out, err: err}
	}()
	go func() {
		out, err := svc.Replace(context.Background(), actor, Command{TeamString: "3", TeamNameString: "C", PetPresent: true, PetString: "10"}, presetTestOp(t, "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee"))
		results <- result{out: out, err: err}
	}()

	r1, r2 := <-results, <-results
	if r1.err != nil || r2.err != nil {
		t.Fatalf("results: %+v %+v", r1, r2)
	}
	versions := map[int64]bool{r1.out.StateVersion: true, r2.out.StateVersion: true}
	if !r1.out.Mutated || !r2.out.Mutated || !versions[2] || !versions[3] {
		t.Fatalf("out1=%+v out2=%+v", r1.out, r2.out)
	}
	if db.beginCount() != 3 {
		t.Fatalf("begins=%d want=3 (one edit must replan after uncovered drift)", db.beginCount())
	}
	final := st.snapshot()
	if final.Root.StateVersion != 3 || len(final.Lanes) != 1 {
		t.Fatalf("final=%+v", final)
	}
	wire, err := ProjectWire(final)
	if err != nil {
		t.Fatal(err)
	}
	if wire.SaveTeam != "2" && wire.SaveTeam != "3" {
		t.Fatalf("unexpected final wire=%+v", wire)
	}
	rr.mu.Lock()
	receipts := len(rr.m)
	rr.mu.Unlock()
	if receipts != 2 {
		t.Fatalf("receipts=%d want=2", receipts)
	}
}
