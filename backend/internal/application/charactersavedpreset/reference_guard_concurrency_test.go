package charactersavedpreset

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// guardRaceStore is a test-only future-consumer fixture. It models the same
// saved-preset owner state and rank-440 root mutex used by CA5-3 and CA5-4; it
// does not add a production destructive endpoint.
type guardRaceStore struct {
	stateMu sync.RWMutex
	rootMu  sync.Mutex
	state   character.SavedPresetAggregate

	blockFirstRoot bool
	rootOnce       sync.Once
	firstRootHeld  chan struct{}
	releaseRoot    chan struct{}
}

func newGuardRaceStore(initial character.SavedPresetAggregate) *guardRaceStore {
	return &guardRaceStore{state: initial, firstRootHeld: make(chan struct{}), releaseRoot: make(chan struct{})}
}

func (s *guardRaceStore) ReadSavedPresetAggregateTx(context.Context, tx.Queryer, identity.PlayerID) (character.SavedPresetAggregate, error) {
	s.stateMu.RLock()
	defer s.stateMu.RUnlock()
	return character.SavedPresetAggregate{Root: s.state.Root, Lanes: cloneSavedPresetLanes(s.state.Lanes)}, nil
}

func (s *guardRaceStore) LockSavedPresetRootTx(_ context.Context, t tx.Tx, pid identity.PlayerID) (character.SavedPresetRoot, error) {
	lt, ok := t.(*presetLockingTx)
	if !ok || pid != s.state.Root.PlayerID {
		return character.SavedPresetRoot{}, errors.New("guard race: invalid root lock")
	}
	lt.acquire(&s.rootMu)
	if s.blockFirstRoot {
		s.rootOnce.Do(func() {
			close(s.firstRootHeld)
			<-s.releaseRoot
		})
	}
	s.stateMu.RLock()
	defer s.stateMu.RUnlock()
	return s.state.Root, nil
}

func (s *guardRaceStore) ReplaceSavedPresetAggregateTx(_ context.Context, _ tx.Tx, desired character.SavedPresetAggregate, expected int64) error {
	s.stateMu.Lock()
	defer s.stateMu.Unlock()
	if s.state.Root.StateVersion != expected {
		return ErrStaleVersion
	}
	s.state = character.SavedPresetAggregate{Root: desired.Root, Lanes: cloneSavedPresetLanes(desired.Lanes)}
	return nil
}

func (*guardRaceStore) EnsureSavedPresetRootTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (bool, error) {
	return false, nil
}

func (s *guardRaceStore) SavedPresetReferencesHeroTx(_ context.Context, _ tx.Queryer, pid identity.PlayerID, partnerID int64) (bool, error) {
	s.stateMu.RLock()
	defer s.stateMu.RUnlock()
	if pid != s.state.Root.PlayerID {
		return false, errors.New("guard race: foreign Hero query")
	}
	for _, lane := range s.state.Lanes {
		for _, ref := range lane.Heroes {
			if ref.PlayerID == pid && ref.PartnerID == partnerID {
				return true, nil
			}
		}
	}
	return false, nil
}

func (s *guardRaceStore) SavedPresetReferencesPetTx(_ context.Context, _ tx.Queryer, pid identity.PlayerID, petID int64) (bool, error) {
	s.stateMu.RLock()
	defer s.stateMu.RUnlock()
	if pid != s.state.Root.PlayerID {
		return false, errors.New("guard race: foreign Pet query")
	}
	for _, lane := range s.state.Lanes {
		if lane.Pet != nil && lane.Pet.PlayerID == pid && lane.Pet.PetID == petID {
			return true, nil
		}
	}
	return false, nil
}

func (s *guardRaceStore) snapshotGuardRace() character.SavedPresetAggregate {
	s.stateMu.RLock()
	defer s.stateMu.RUnlock()
	return character.SavedPresetAggregate{Root: s.state.Root, Lanes: cloneSavedPresetLanes(s.state.Lanes)}
}

type removalAwareHeroOwner struct {
	locks *presetKeyLocks
	mu    sync.Mutex
	alive map[character.HeroRef]bool
}

func newRemovalAwareHeroOwner(locks *presetKeyLocks, refs ...character.HeroRef) *removalAwareHeroOwner {
	o := &removalAwareHeroOwner{locks: locks, alive: map[character.HeroRef]bool{}}
	for _, ref := range refs {
		o.alive[ref] = true
	}
	return o
}

func (o *removalAwareHeroOwner) HeroReferenceLockKey(r character.HeroRef) (lockkey.Key, error) {
	return characterasset.HeroReferenceLockKey(r)
}
func (o *removalAwareHeroOwner) LockHeroReferenceKeyTx(_ context.Context, t tx.Tx, k lockkey.Key, r character.HeroRef) error {
	lt, ok := t.(*presetLockingTx)
	if !ok {
		return errors.New("guard race: unexpected tx type")
	}
	lt.acquire(o.locks.forKey(k))
	o.mu.Lock()
	alive := o.alive[r]
	o.mu.Unlock()
	if !alive {
		return characterasset.ErrReferenceNotFound
	}
	return nil
}
func (o *removalAwareHeroOwner) deleteLocked(r character.HeroRef) {
	o.mu.Lock()
	o.alive[r] = false
	o.mu.Unlock()
}
func (o *removalAwareHeroOwner) exists(r character.HeroRef) bool {
	o.mu.Lock()
	defer o.mu.Unlock()
	return o.alive[r]
}

// consumeHeroFixture is deliberately test-only future-owner choreography. It
// proves the CA5-1 contract without activating MID66 or production deletion.
func consumeHeroFixture(ctx context.Context, db *presetLockingDB, owner *removalAwareHeroOwner, guard SavedPresetReferenceGuard, ref character.HeroRef, deleted chan<- struct{}, release <-chan struct{}) error {
	plan, err := guard.PreflightHeroRemovalTx(ctx, nil, ref)
	if err != nil {
		return err
	}
	providerPlan, err := characterasset.CanonicalizeReferenceGuardPlans([]characterasset.ReferenceGuardPlan{plan})
	if err != nil {
		return err
	}
	target, err := owner.HeroReferenceLockKey(ref)
	if err != nil {
		return err
	}
	all, err := lockkey.Canonical(append([]lockkey.Key{target}, providerPlan.Locks...))
	if err != nil || len(all) != 2 || lockkey.Compare(all[0], target) != 0 {
		return errors.New("guard race: invalid future consume lock composition")
	}
	txv, err := db.Begin(ctx, tx.Options{})
	if err != nil {
		return err
	}
	if err := owner.LockHeroReferenceKeyTx(ctx, txv, target, ref); err != nil {
		_ = txv.Rollback(ctx)
		return err
	}
	for _, key := range providerPlan.Locks {
		if err := guard.LockReferenceGuardKeyTx(ctx, txv, key); err != nil {
			_ = txv.Rollback(ctx)
			return err
		}
	}
	if err := guard.ValidateHeroRemovalLockedTx(ctx, txv, ref, plan); err != nil {
		_ = txv.Rollback(ctx)
		return err
	}
	owner.deleteLocked(ref)
	if deleted != nil {
		close(deleted)
	}
	if release != nil {
		<-release
	}
	return txv.Commit(ctx)
}

func TestCA54HeroConsumeRaceAddWinsThenConsumeRejects(t *testing.T) {
	pid := identity.PlayerID(7)
	href := character.HeroRef{PlayerID: pid, PartnerID: 2}
	initial := aggregateVersion(pid, 1)
	store := newGuardRaceStore(initial)
	store.blockFirstRoot = true
	locks := &presetKeyLocks{}
	heroes := newRemovalAwareHeroOwner(locks, href)
	pets := presetConcurrentOwner{locks: locks}
	db := &presetLockingDB{}
	receipts := &presetReceipts{}
	svc := mutationServiceFor(db, store, &presetFence{}, heroes, pets, receipts)
	guard := SavedPresetReferenceGuard{Store: store, PlayerID: pid}

	type mutationResult struct {
		out MutationResult
		err error
	}
	addDone := make(chan mutationResult, 1)
	go func() {
		out, err := svc.Replace(context.Background(), presetTestActor(t), Command{TeamString: "2", TeamNameString: "A", PetPresent: true, PetString: "0"}, presetTestOp(t, "12121212-1212-4212-8212-121212121212"))
		addDone <- mutationResult{out: out, err: err}
	}()

	<-store.firstRootHeld // add holds Hero source lock + rank440 root
	consumeDone := make(chan error, 1)
	go func() { consumeDone <- consumeHeroFixture(context.Background(), db, heroes, guard, href, nil, nil) }()
	close(store.releaseRoot)

	add := <-addDone
	if add.err != nil || !add.out.Mutated || add.out.StateVersion != 2 {
		t.Fatalf("add=%+v", add)
	}
	if err := <-consumeDone; !errors.Is(err, characterasset.ErrReferenceInUse) {
		t.Fatalf("consume err=%v want ErrReferenceInUse", err)
	}
	if !heroes.exists(href) {
		t.Fatal("referenced Hero was removed")
	}
	state := store.snapshotGuardRace()
	if len(state.Lanes) != 1 || state.Lanes[0].Heroes[0] != href {
		t.Fatalf("saved state=%+v", state)
	}
}

func TestCA54HeroConsumeRaceConsumeWinsThenAddFailsOwnerValidation(t *testing.T) {
	pid := identity.PlayerID(7)
	href := character.HeroRef{PlayerID: pid, PartnerID: 2}
	initial := aggregateVersion(pid, 1)
	store := newGuardRaceStore(initial)
	locks := &presetKeyLocks{}
	heroes := newRemovalAwareHeroOwner(locks, href)
	pets := presetConcurrentOwner{locks: locks}
	db := &presetLockingDB{}
	receipts := &presetReceipts{}
	svc := mutationServiceFor(db, store, &presetFence{}, heroes, pets, receipts)
	guard := SavedPresetReferenceGuard{Store: store, PlayerID: pid}

	deleted := make(chan struct{})
	release := make(chan struct{})
	consumeDone := make(chan error, 1)
	go func() {
		consumeDone <- consumeHeroFixture(context.Background(), db, heroes, guard, href, deleted, release)
	}()
	<-deleted // consume holds Hero + root locks and has deleted source in the fixture

	addDone := make(chan error, 1)
	go func() {
		_, err := svc.Replace(context.Background(), presetTestActor(t), Command{TeamString: "2", TeamNameString: "A", PetPresent: true, PetString: "0"}, presetTestOp(t, "34343434-3434-4434-8434-343434343434"))
		addDone <- err
	}()
	close(release)
	if err := <-consumeDone; err != nil {
		t.Fatalf("consume err=%v", err)
	}
	if err := <-addDone; !errors.Is(err, characterasset.ErrReferenceNotFound) {
		t.Fatalf("add err=%v want ErrReferenceNotFound", err)
	}
	if heroes.exists(href) {
		t.Fatal("future consume fixture did not remove Hero")
	}
	if state := store.snapshotGuardRace(); len(state.Lanes) != 0 || state.Root.StateVersion != 1 {
		t.Fatalf("failed add mutated saved presets: %+v", state)
	}
}

func TestCA54PetGuardUsesSharedPetThenRootOrder(t *testing.T) {
	pid := identity.PlayerID(7)
	pref := character.PetRef{PlayerID: pid, PetID: 9}
	store := newGuardRaceStore(aggregateVersion(pid, 1))
	guard := SavedPresetReferenceGuard{Store: store, PlayerID: pid}
	plan, err := guard.PreflightPetRemovalTx(context.Background(), nil, pref)
	if err != nil {
		t.Fatal(err)
	}
	petKey, err := characterasset.PetReferenceLockKey(pref)
	if err != nil {
		t.Fatal(err)
	}
	locks, err := lockkey.Canonical(append([]lockkey.Key{petKey}, plan.Locks...))
	if err != nil {
		t.Fatal(err)
	}
	if len(locks) != 2 || locks[0].DomainRank != character.PetInstanceLockRank || locks[1].DomainRank != characterasset.SavedPresetRootLockRank {
		t.Fatalf("locks=%+v", locks)
	}
}
