package registry

import (
	"context"
	"encoding/json"
	"errors"
	"reflect"
	"strings"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Transactional model tests verify service semantics, never PostgreSQL lock/JSON behavior.
type model struct {
	mu              sync.Mutex
	installed       map[string]Verification
	active          ActivationIdentity
	manifests       map[string][]byte
	failChild       bool
	commitFault     string
	begins, inserts int
	ats             []time.Time
}
type modelTx struct {
	db        *model
	installed map[string]Verification
	active    ActivationIdentity
	manifests map[string][]byte
	closed    bool
}
type tag int64

func (t tag) RowsAffected() int64 { return int64(t) }

type row struct{}

func (row) Scan(...any) error                                                  { return errors.New("unexpected row query") }
func (m *model) QueryRow(context.Context, string, ...any) tx.Row               { return row{} }
func (t *modelTx) QueryRow(context.Context, string, ...any) tx.Row             { return row{} }
func (t *modelTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return tag(1), nil }
func (m *model) Begin(_ context.Context, o tx.Options) (tx.Tx, error) {
	m.mu.Lock()
	m.begins++
	if o.Isolation != tx.Serializable {
		m.mu.Unlock()
		return nil, errors.New("wrong isolation")
	}
	t := &modelTx{db: m, active: m.active, installed: map[string]Verification{}, manifests: map[string][]byte{}}
	for k, v := range m.installed {
		t.installed[k] = v
	}
	for k, v := range m.manifests {
		t.manifests[k] = v
	}
	return t, nil
}

type abort string

func (a abort) Error() string    { return string(a) }
func (a abort) SQLState() string { return string(a) }
func (t *modelTx) Commit(context.Context) error {
	mode := t.db.commitFault
	t.db.commitFault = ""
	if mode != "abort" && mode != "unknown_absent" {
		t.db.installed = t.installed
		t.db.manifests = t.manifests
		t.db.active = t.active
	}
	t.closed = true
	t.db.mu.Unlock()
	if mode == "abort" {
		return abort("40001")
	}
	if strings.HasPrefix(mode, "unknown") {
		return errors.New("connection lost")
	}
	return nil
}
func (t *modelTx) Rollback(context.Context) error {
	if !t.closed {
		t.closed = true
		t.db.mu.Unlock()
	}
	return nil
}

type repo struct{ m *model }

func (r repo) LockRegistry(context.Context, tx.Tx) error { return nil } // serialized by model Begin
func (r repo) TryInsertRevision(_ context.Context, x tx.Tx, b Bundle) (bool, error) {
	t := x.(*modelTx)
	if _, ok := t.installed[b.RevisionID()]; ok {
		return false, nil
	}
	r.m.inserts++
	t.installed[b.RevisionID()] = Verification{Exact: true}
	t.manifests[b.RevisionID()] = b.ManifestJSON()
	return true, nil
}
func (r repo) InsertResources(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.ResourceCount = b.resourceCount
	t.installed[b.RevisionID()] = v
	return b.resourceCount, nil
}
func (r repo) InsertProgression(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	if r.m.failChild {
		return 0, errors.New("child insert")
	}
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.ProgressionCount = b.progressionCount
	t.installed[b.RevisionID()] = v
	return b.progressionCount, nil
}

func (r repo) InsertFunctionGates(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.FunctionGateCount = b.functionGateCount
	t.installed[b.RevisionID()] = v
	return b.functionGateCount, nil
}

func (r repo) InsertObjectives(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.ObjectiveCount = b.objectiveCount
	t.installed[b.RevisionID()] = v
	return b.objectiveCount, nil
}
func (r repo) InsertHeroCore(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.HeroCount = b.heroCount
	t.installed[b.RevisionID()] = v
	return b.heroCount, nil
}
func (r repo) InsertPetCore(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.PetCount = b.petCount
	t.installed[b.RevisionID()] = v
	return b.petCount, nil
}
func (r repo) InsertPetAcquisition(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.PetAcquisitionCount = b.petAcquisitionCount
	t.installed[b.RevisionID()] = v
	return b.petAcquisitionCount, nil
}
func (r repo) InsertPetProgression(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.PetProgressionCount = b.petProgressionCount
	t.installed[b.RevisionID()] = v
	return b.petProgressionCount, nil
}
func (r repo) InsertEquipmentPrimitives(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.EquipmentPrimitiveCount = b.equipmentPrimitiveCount
	t.installed[b.RevisionID()] = v
	return b.equipmentPrimitiveCount, nil
}
func (r repo) InsertHeroEquipment(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.HeroEquipmentCount = b.heroEquipmentCount
	t.installed[b.RevisionID()] = v
	return b.heroEquipmentCount, nil
}
func (r repo) InsertSuperEquipment(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.SuperEquipmentCount = b.superEquipmentCount
	t.installed[b.RevisionID()] = v
	return b.superEquipmentCount, nil
}
func (r repo) InsertHeroFumo(_ context.Context, x tx.Tx, b Bundle) (int64, int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.HeroFumoTargetCount = b.heroFumoTargetCount
	v.HeroFumoMaterialCount = b.heroFumoMaterialCount
	t.installed[b.RevisionID()] = v
	return b.heroFumoTargetCount, b.heroFumoMaterialCount, nil
}
func (r repo) InsertHeroPromotionRestoration(_ context.Context, x tx.Tx, b Bundle) (int64, int64, int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.HeroPromotionRestorationEquipmentCount = b.heroPromotionRestorationEquipmentCount
	v.HeroPromotionRestorationFractionCount = b.heroPromotionRestorationFractionCount
	v.HeroPromotionRestorationDenominationCount = b.heroPromotionRestorationDenominationCount
	t.installed[b.RevisionID()] = v
	return b.heroPromotionRestorationEquipmentCount, b.heroPromotionRestorationFractionCount, b.heroPromotionRestorationDenominationCount, nil
}
func (r repo) InsertPetEquipment(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.PetEquipmentCount = b.petEquipmentCount
	t.installed[b.RevisionID()] = v
	return b.petEquipmentCount, nil
}
func (r repo) InsertPetPromotionRestoration(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.PetPromotionRestorationEquipmentCount = b.petPromotionRestorationEquipmentCount
	t.installed[b.RevisionID()] = v
	return b.petPromotionRestorationEquipmentCount, nil
}
func (r repo) InsertPractice(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.PracticeCount = b.practiceCount
	t.installed[b.RevisionID()] = v
	return b.practiceCount, nil
}
func (r repo) InsertAppearance(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.AppearanceCount = b.appearanceCount
	t.installed[b.RevisionID()] = v
	return b.appearanceCount, nil
}
func (r repo) VerifyRevision(_ context.Context, q tx.Queryer, b Bundle) (Verification, error) {
	if t, ok := q.(*modelTx); ok {
		return t.installed[b.RevisionID()], nil
	}
	r.m.mu.Lock()
	defer r.m.mu.Unlock()
	return r.m.installed[b.RevisionID()], nil
}
func (r repo) ReadActivation(_ context.Context, q tx.Queryer) (ActivationIdentity, bool, error) {
	if t, ok := q.(*modelTx); ok {
		return t.active, t.active.Version > 0, nil
	}
	r.m.mu.Lock()
	defer r.m.mu.Unlock()
	return r.m.active, r.m.active.Version > 0, nil
}
func (r repo) ReadActiveSummary(_ context.Context, q tx.Queryer) (ActiveSummary, bool, error) {
	if t, ok := q.(*modelTx); ok {
		return ActiveSummary{Activation: t.active, SchemaVersion: 1, ManifestJSON: t.manifests[t.active.RevisionID]}, t.active.Version > 0, nil
	}
	r.m.mu.Lock()
	defer r.m.mu.Unlock()
	return ActiveSummary{Activation: r.m.active, SchemaVersion: 1, ManifestJSON: r.m.manifests[r.m.active.RevisionID]}, r.m.active.Version > 0, nil
}
func (r repo) BootstrapActivation(_ context.Context, x tx.Tx, id string, at time.Time, actor string) (bool, error) {
	t := x.(*modelTx)
	r.m.ats = append(r.m.ats, at)
	if t.active.Version > 0 {
		return false, nil
	}
	t.active = ActivationIdentity{RevisionID: id, Version: 1, ActivatedAt: at, ActivatedBy: actor}
	return true, nil
}
func (r repo) ActivateCAS(_ context.Context, x tx.Tx, id string, at time.Time, actor string, e ActivationIdentity) (bool, error) {
	t := x.(*modelTx)
	if t.active.RevisionID != e.RevisionID || t.active.Version != e.Version {
		return false, nil
	}
	t.active = ActivationIdentity{RevisionID: id, Version: e.Version + 1, ActivatedAt: at, ActivatedBy: actor}
	return true, nil
}
func setup(t *testing.T) (Service, *model, Bundle, operation.Context) {
	t.Helper()
	b, err := LoadBuiltinBundle()
	if err != nil {
		t.Fatal(err)
	}
	m := &model{installed: map[string]Verification{}, manifests: map[string][]byte{}}
	return Service{Runner: tx.Runner{DB: m}, Repo: repo{m}, Fresh: m, Providers: DefaultProviderSet()}, m, b, operation.Context{StartedAt: time.Unix(1770000000, 0).UTC()}
}
func install(t *testing.T, s Service, b Bundle, op operation.Context) {
	t.Helper()
	if _, err := s.EnsureBuiltinInstalled(context.Background(), op, b); err != nil {
		t.Fatal(err)
	}
}
func TestExactInstallAndCorruptSameID(t *testing.T) {
	s, m, b, op := setup(t)
	install(t, s, b, op)
	install(t, s, b, op)
	if m.inserts != 1 || !m.installed[b.RevisionID()].Matches(b) {
		t.Fatal("not exact/no-op")
	}
	v := m.installed[b.RevisionID()]
	v.ResourceCount--
	m.installed[b.RevisionID()] = v
	if _, err := s.EnsureBuiltinInstalled(context.Background(), op, b); err == nil {
		t.Fatal("corruption accepted")
	}
	if m.inserts != 1 {
		t.Fatal("repaired in place")
	}
}
func TestInstallRollback(t *testing.T) {
	s, m, b, op := setup(t)
	m.failChild = true
	if _, err := s.EnsureBuiltinInstalled(context.Background(), op, b); err == nil {
		t.Fatal("failure lost")
	}
	if len(m.installed) != 0 {
		t.Fatal("partial install")
	}
}
func TestConcurrentInstallModel(t *testing.T) {
	s, m, b, op := setup(t)
	var wg sync.WaitGroup
	errs := make(chan error, 2)
	for i := 0; i < 2; i++ {
		wg.Add(1)
		go func() { defer wg.Done(); _, err := s.EnsureBuiltinInstalled(context.Background(), op, b); errs <- err }()
	}
	wg.Wait()
	close(errs)
	for err := range errs {
		if err != nil {
			t.Fatal(err)
		}
	}
	if m.inserts != 1 {
		t.Fatal("duplicate install")
	}
}
func TestBootstrapNeverSwitchesAndCAS(t *testing.T) {
	s, m, b, op := setup(t)
	install(t, s, b, op)
	ctx := context.Background()
	if _, err := s.BootstrapActivationIfMissing(ctx, op, b); err != nil {
		t.Fatal(err)
	}
	first := m.active
	if _, err := s.BootstrapActivationIfMissing(ctx, op, b); err != nil || m.active != first {
		t.Fatal("bootstrap bump", err)
	}
	oldID := strings.Repeat("a", 64)
	old := b.manifest
	old.RevisionID = oldID
	raw, _ := json.Marshal(old)
	m.manifests[oldID] = raw
	m.active = ActivationIdentity{RevisionID: oldID, Version: 7}
	previous := m.active
	if _, err := s.BootstrapActivationIfMissing(ctx, op, b); err != nil || m.active != previous {
		t.Fatal("startup switched existing", err)
	}
	if _, err := s.ActivateBuiltin(ctx, op, b, ActivationIdentity{RevisionID: oldID, Version: 6}, "host"); !errors.Is(err, ErrStaleActivation) {
		t.Fatal("stale CAS accepted", err)
	}
	if _, err := s.ActivateBuiltin(ctx, op, b, previous, "host"); err != nil {
		t.Fatal(err)
	}
	if m.active.Version != 8 || m.active.ActivatedBy != "host" {
		t.Fatal("CAS identity")
	}
	accepted := m.active
	if _, err := s.ActivateBuiltin(ctx, op, b, previous, "host"); err != nil || m.active != accepted {
		t.Fatal("target no-op changed state", err)
	}
}
func TestRetryAndPositiveOnlyUnknownCommit(t *testing.T) {
	for _, mode := range []string{"abort", "unknown_committed", "unknown_absent"} {
		t.Run(mode, func(t *testing.T) {
			s, m, b, op := setup(t)
			m.commitFault = mode
			res, err := s.EnsureBuiltinInstalled(context.Background(), op, b)
			if mode == "unknown_absent" {
				if err == nil || m.begins != 1 || res.Outcome != tx.UnknownCommitOutcome {
					t.Fatal("unknown replayed", res, err)
				}
				return
			}
			if err != nil {
				t.Fatal(err)
			}
			if mode == "abort" && m.begins != 2 {
				t.Fatal("no retry")
			}
			if mode == "unknown_committed" && (!res.Reconciled || m.begins != 1) {
				t.Fatal("positive reconciliation", res)
			}
		})
	}
	s, m, b, op := setup(t)
	install(t, s, b, op)
	m.commitFault = "abort"
	if _, err := s.BootstrapActivationIfMissing(context.Background(), op, b); err != nil {
		t.Fatal(err)
	}
	if len(m.ats) != 2 || m.ats[0] != m.ats[1] || m.ats[0] != op.StartedAt {
		t.Fatal("retry time changed")
	}
}
func TestBootstrapAndActivateUnknownResolution(t *testing.T) {
	for _, action := range []string{"bootstrap", "activate"} {
		for _, mode := range []string{"unknown_committed", "unknown_absent"} {
			t.Run(action+mode, func(t *testing.T) {
				s, m, b, op := setup(t)
				install(t, s, b, op)
				expected := ActivationIdentity{RevisionID: strings.Repeat("a", 64), Version: 3}
				if action == "activate" {
					m.active = expected
				}
				before := m.begins
				m.commitFault = mode
				var res tx.Result
				var err error
				if action == "bootstrap" {
					res, err = s.BootstrapActivationIfMissing(context.Background(), op, b)
				} else {
					res, err = s.ActivateBuiltin(context.Background(), op, b, expected, "host")
				}
				if m.begins != before+1 {
					t.Fatal("blind replay")
				}
				if mode == "unknown_committed" {
					if err != nil || !res.Reconciled {
						t.Fatal(res, err)
					}
				} else if err == nil || res.Outcome != tx.UnknownCommitOutcome {
					t.Fatal("unproven success", res, err)
				}
			})
		}
	}
}
func TestManifestAndProviderFailClosed(t *testing.T) {
	s, _, b, _ := setup(t)
	for _, caps := range []any{nil, []string{""}, []string{"SCALAR_MANA", "SCALAR_MANA"}, []string{"UNKNOWN"}, []string{" SCALAR_MANA"}} {
		var obj map[string]any
		_ = json.Unmarshal(b.ManifestJSON(), &obj)
		obj["enabled_capabilities"] = caps
		raw, _ := json.Marshal(obj)
		if err := s.validateActiveSummary(ActiveSummary{Activation: ActivationIdentity{RevisionID: b.RevisionID(), Version: 1}, SchemaVersion: 1, ManifestJSON: raw}); err == nil {
			t.Fatalf("accepted %v", caps)
		}
	}
	if _, err := DecodeManifestStrict(append(b.ManifestJSON(), []byte(" {}")...)); err == nil {
		t.Fatal("trailing JSON")
	}
	if _, err := DecodeManifestStrict([]byte("{}")); err == nil {
		t.Fatal("missing fields")
	}
	if _, err := NewProviderSet("A", "A"); err == nil {
		t.Fatal("duplicates")
	}
	if _, err := NewProviderSet(" "); err == nil {
		t.Fatal("blank")
	}
	s.Providers = ProviderSet{}
	if _, err := s.normalized(); err == nil {
		t.Fatal("implicit provider activation")
	}
}
func TestRawBundleZeroFalseAndIsolation(t *testing.T) {
	_, _, b, _ := setup(t)
	var c struct {
		Resources []map[string]any `json:"resources"`
	}
	if err := json.Unmarshal(b.ResourcesJSON(), &c); err != nil {
		t.Fatal(err)
	}
	zero, noMail := 0, 0
	for _, r := range c.Resources {
		if v, ok := r["item_type"]; ok && v == float64(0) {
			zero++
		}
		if v, ok := r["overflow_to_mail"]; ok && v == false {
			noMail++
		}
	}
	if zero != 3 || noMail != 1117 {
		t.Fatal(zero, noMail)
	}
	r, p, f, o, h, pet, petAcq, petProg, equipment, heroEquipment, superEquipment, heroFumoTargets, heroFumoMaterials, restorationEquipment, restorationFractions, restorationDenominations, petEquipment, petRestorationEquipment, practice, appearance := b.ExpectedCounts()
	if r != 5564 || p != 100 || f != 99 || o != 0 || h != 568 || pet != 54 || petAcq != 27 || petProg != 54 || equipment != 1176 || heroEquipment != 53280 || superEquipment != 84 || heroFumoTargets != 359 || heroFumoMaterials != 516 || restorationEquipment != 195 || restorationFractions != 5 || restorationDenominations != 3 || petEquipment != 2592 || petRestorationEquipment != 73 || practice != 1889 || appearance != 542 {
		t.Fatal(r, p, f, o, h, pet, petAcq, petProg, equipment, heroEquipment, superEquipment, heroFumoTargets, heroFumoMaterials, restorationEquipment, restorationFractions, restorationDenominations, petEquipment, petRestorationEquipment, practice, appearance)
	}
	raw := b.ManifestJSON()
	raw[0] = '!'
	if !json.Valid(b.ManifestJSON()) {
		t.Fatal("mutable bundle bytes")
	}
}

type startupFake struct {
	calls []string
	fail  string
}

func (s *startupFake) EnsureBuiltinInstalled(context.Context, operation.Context, Bundle) (tx.Result, error) {
	s.calls = append(s.calls, "install")
	if s.fail == "install" {
		return tx.Result{}, errors.New("install")
	}
	return tx.Result{}, nil
}
func (s *startupFake) BootstrapActivationIfMissing(context.Context, operation.Context, Bundle) (tx.Result, error) {
	s.calls = append(s.calls, "bootstrap")
	if s.fail == "bootstrap" {
		return tx.Result{}, errors.New("bootstrap")
	}
	return tx.Result{}, nil
}
func (s *startupFake) ValidateActiveReadiness(context.Context) (ActiveSummary, error) {
	s.calls = append(s.calls, "ready")
	if s.fail == "ready" {
		return ActiveSummary{}, errors.New("ready")
	}
	return ActiveSummary{}, nil
}
func TestStartupOrderAndFailure(t *testing.T) {
	for _, fail := range []string{"", "install", "bootstrap", "ready"} {
		f := &startupFake{fail: fail}
		_, err := Initialize(context.Background(), f, operation.Factory{Clock: clock.Fixed{T: time.Now()}})
		want := []string{"install", "bootstrap", "ready"}
		if fail == "install" {
			want = want[:1]
		}
		if fail == "bootstrap" {
			want = want[:2]
		}
		if !reflect.DeepEqual(f.calls, want) || (err != nil) != (fail != "") {
			t.Fatal(f.calls, err)
		}
	}
}

func (r repo) InsertEmoticons(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.EmoticonCount = 85
	t.installed[b.RevisionID()] = v
	return 85, nil
}

func (r repo) InsertSocialGift(_ context.Context, x tx.Tx, b Bundle) (int64, error) { return 1, nil }

func (r repo) InsertDormInputs(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.DormInputsCount = 1
	t.installed[b.RevisionID()] = v
	return 1, nil
}
func (r repo) InsertLibraryInputs(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.LibraryInputsCount = 1
	t.installed[b.RevisionID()] = v
	return 1, nil
}
func (r repo) InsertPlayerDisplay(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.PlayerDisplayCount = 1
	t.installed[b.RevisionID()] = v
	return 1, nil
}
func (r repo) InsertPublicShowcase(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.PublicShowcaseCount = 1
	t.installed[b.RevisionID()] = v
	return 1, nil
}
func (r repo) InsertPublicProfile(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.PublicProfileCount = 1
	t.installed[b.RevisionID()] = v
	return 1, nil
}
func (r repo) InsertGuildBroadcast(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.GuildBroadcastCount = 1
	t.installed[b.RevisionID()] = v
	return 1, nil
}

func (r repo) InsertGuildInvite(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.GuildInviteCount = 1
	t.installed[b.RevisionID()] = v
	return 1, nil
}

func (r repo) InsertBookInputs(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.BookInputsCount = 1
	t.installed[b.RevisionID()] = v
	return 1, nil
}

func (r repo) InsertCourseInputs(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.CourseInputsCount = 1
	t.installed[b.RevisionID()] = v
	return 1, nil
}

func (r repo) InsertElementInputs(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.ElementInputsCount = 1
	t.installed[b.RevisionID()] = v
	return 1, nil
}
func (r repo) InsertInscriptionInputs(_ context.Context, x tx.Tx, b Bundle) (int64, error) {
	t := x.(*modelTx)
	v := t.installed[b.RevisionID()]
	v.InscriptionInputsCount = 1
	t.installed[b.RevisionID()] = v
	return 1, nil
}
