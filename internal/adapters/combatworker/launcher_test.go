package combatworker

import (
	"bytes"
	"context"
	"crypto/sha256"
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/combat"
	"gxb.local/backend/v2/internal/content/combatcorpus"
	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/testsupport/latency"
)

var workerBinary string

func TestMain(m *testing.M) {
	dir, err := os.MkdirTemp("", "combat-worker-test-")
	if err != nil {
		panic(err)
	}
	workerBinary = filepath.Join(dir, "gxb-combat-worker")
	build := exec.Command("go", "build", "-o", workerBinary, "gxb.local/backend/v2/cmd/gxb-combat-worker")
	build.Stderr = os.Stderr
	if err = build.Run(); err != nil {
		panic(err)
	}
	code := m.Run()
	os.RemoveAll(dir)
	os.Exit(code)
}

func limits(t *testing.T) Limits {
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	return Limits{Binary: workerBinary, Deadline: 90 * time.Second, AddressSpace: 4 << 30, CPUSeconds: 120, OpenFiles: 64, MaxOutputBytes: 16 << 20, ExpectedCorpus: corpus.ID()}
}

func pool(t *testing.T, l Limits, workers int, admissionWait time.Duration) *Launcher {
	launcher := New(l, workers, admissionWait, 0)
	t.Cleanup(launcher.Close)
	return launcher
}

func launcher(t *testing.T) *Launcher {
	return pool(t, limits(t), 1, time.Minute)
}

func hero(t *testing.T, tableID int64) d.Actor {
	params, err := d.CanonicalJSON(map[string]any{"player_id": 0, "partner_id": tableID, "table_id": tableID, "star": 3, "lev": 20, "color": 2,
		"skin_ids": map[string]any{}, "spirit_equip": []any{}, "spirit_item": []any{}, "equips": []any{0, 0, 0, 0, 0, 0}, "fumos": []any{0, 0, 0, 0, 0, 0}, "skills": []any{1, 1, 1, 1, 1, 1}})
	if err != nil {
		t.Fatal(err)
	}
	corpus, _ := combatcorpus.Load()
	class, _, _ := corpus.FighterClass("partner", tableID)
	if class == "" {
		class = "Change_Awaken"
	}
	return d.Actor{Origin: d.Template, Kind: d.HeroActor, Identity: tableID, TableID: tableID, FighterClass: class, Params: params}
}

func snapshot(t *testing.T, a, b d.Actor) ([]byte, string) {
	corpus, _ := combatcorpus.Load()
	s := d.Snapshot{Schema: d.SnapshotSchema, ProducerProfile: d.ProducerProfileID, Contract: d.ContractID, ContentRevision: strings.Repeat("b", 64), CorpusID: corpus.ID(), SourceArchiveSHA256: corpus.SourceArchiveSHA256(),
		TrustProfile: d.TrustProfileID, EntropyPolicy: d.EntropyPolicyVersion, AdapterPolicy: d.AdapterPolicyVersion, CollectionPolicy: d.CollectionPolicy,
		DecidedAt: time.Unix(1700000000, 0).UTC(), Battle: d.Battle{CampaignType: 1, TeamA: []d.Actor{a}, WavesB: [][]d.Actor{{b}}, PetsA: []d.Actor{}, PetsB: []d.Actor{}}, Players: []d.PlayerContext{}}
	raw, hash, err := s.Canonical()
	if err != nil {
		t.Fatal(err)
	}
	return raw, hash
}

var root = sha256.Sum256([]byte("worker-test-root"))

// A04: fresh worker processes reproduce identical bytes for one snapshot/root;
// the second attempt runs on a spare prepared before it arrived.
func TestFreshProcessesAreDeterministic(t *testing.T) {
	raw, hash := snapshot(t, hero(t, 10001001), hero(t, 10001002))
	l := launcher(t)
	first, err := l.Resolve(context.Background(), raw, hash, root)
	if err != nil {
		t.Fatal(err)
	}
	second, err := l.Resolve(context.Background(), raw, hash, root)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(first.Report, second.Report) || first.Outcome != second.Outcome || first.EntropyDraws != second.EntropyDraws {
		t.Fatal("fresh processes diverged")
	}
	t.Logf("outcome %+v report %s", first.Outcome, d.ReportHash(first.Report))
}

// Warm starts a spare before any attempt, so the first client fight does not
// pay the worker's one-time preparation.
func TestWarmStartsSpareBeforeFirstAttempt(t *testing.T) {
	l := launcher(t)
	l.Warm()
	var pid string
	for i := 0; i < 500 && pid == ""; i++ {
		time.Sleep(20 * time.Millisecond)
		entries, _ := os.ReadDir("/proc")
		for _, e := range entries {
			cmdline, err := os.ReadFile(filepath.Join("/proc", e.Name(), "cmdline"))
			if err == nil && bytes.HasPrefix(cmdline, []byte(workerBinary+"\x00")) {
				pid = e.Name()
			}
		}
	}
	if pid == "" {
		t.Fatal("warm launcher started no spare process")
	}
}

// A09: limits and isolation are observed on the running process, not assumed.
func TestWorkerIsolationIsExecuted(t *testing.T) {
	raw, hash := snapshot(t, hero(t, 10001001), hero(t, 10001002))
	l := launcher(t)
	done := make(chan error, 1)
	go func() {
		_, err := l.Resolve(context.Background(), raw, hash, root)
		done <- err
	}()
	var pid string
	for i := 0; i < 200 && pid == ""; i++ {
		time.Sleep(20 * time.Millisecond)
		entries, _ := os.ReadDir("/proc")
		for _, e := range entries {
			cmdline, err := os.ReadFile(filepath.Join("/proc", e.Name(), "cmdline"))
			if err == nil && bytes.HasPrefix(cmdline, []byte(workerBinary+"\x00")) {
				pid = e.Name()
			}
		}
	}
	if pid == "" {
		t.Fatal("worker process not observed")
	}
	environ, err := os.ReadFile(filepath.Join("/proc", pid, "environ"))
	if err != nil || len(environ) != 0 {
		t.Fatal("worker environment not empty", len(environ), err)
	}
	cwd, err := os.Readlink(filepath.Join("/proc", pid, "cwd"))
	if err != nil || !strings.Contains(filepath.Base(cwd), "gxb-combat-worker-") {
		t.Fatal("worker cwd", cwd, err)
	}
	if entries, _ := os.ReadDir(cwd); len(entries) != 0 {
		t.Fatal("worker cwd not empty")
	}
	limits, err := os.ReadFile(filepath.Join("/proc", pid, "limits"))
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{"Max cpu time              120                  120", "Max file size             0                    0", "Max open files            64                   64", "Max address space         4294967296           4294967296", "Max core file size        0                    0"} {
		if !strings.Contains(string(limits), want) {
			t.Fatalf("limit not applied: %q\n%s", want, limits)
		}
	}
	if err = <-done; err != nil {
		t.Fatal(err)
	}
}

func TestFailureClassification(t *testing.T) {
	raw, hash := snapshot(t, hero(t, 10001001), hero(t, 10001002))
	cases := []struct {
		name   string
		adjust func(*Limits)
		raw    []byte
		want   error
	}{
		{"wall deadline kill", func(l *Limits) { l.Deadline = 200 * time.Millisecond }, raw, d.ErrResolverRetryable},
		{"address space exhaustion", func(l *Limits) { l.AddressSpace = 96 << 20 }, raw, d.ErrResolverRetryable},
		{"cpu limit kill", func(l *Limits) { l.CPUSeconds = 1 }, raw, d.ErrResolverRetryable},
		{"output cap", func(l *Limits) { l.MaxOutputBytes = 512 }, raw, d.ErrResolverPermanent},
		{"tampered snapshot", func(*Limits) {}, bytes.Replace(raw, []byte(`"star":3`), []byte(`"star":4`), 1), d.ErrResolverPermanent},
	}
	for _, c := range cases {
		l := limits(t)
		c.adjust(&l)
		_, err := pool(t, l, 1, time.Minute).Resolve(context.Background(), c.raw, hash, root)
		if !errors.Is(err, c.want) {
			t.Fatalf("%s: got %v", c.name, err)
		}
	}
	missingRaw, missingHash := snapshot(t, hero(t, 11001042), hero(t, 10001002))
	if _, err := launcher(t).Resolve(context.Background(), missingRaw, missingHash, root); !errors.Is(err, d.ErrResolverPermanent) {
		t.Fatal("absent fighter class must be a permanent script failure", err)
	}
}

// H-39/H-11: a busy pool refuses within the admission wait instead of queueing
// without bound, and admits again once a slot frees.
func TestSaturatedPoolRefusesThenAdmits(t *testing.T) {
	raw, hash := snapshot(t, hero(t, 10001001), hero(t, 10001002))
	l := pool(t, limits(t), 1, 300*time.Millisecond)
	busy := make(chan error, 1)
	go func() {
		_, err := l.Resolve(context.Background(), raw, hash, root)
		busy <- err
	}()
	time.Sleep(100 * time.Millisecond)
	began := time.Now()
	_, err := l.Resolve(context.Background(), raw, hash, root)
	if !errors.Is(err, app.ErrWorkerSaturated) || !errors.Is(err, d.ErrResolverRetryable) {
		t.Fatal("saturated pool admitted or misclassified", err)
	}
	if waited := time.Since(began); !latency.Within(latency.Incidental, waited, 2*time.Second) {
		t.Fatal("refusal took", waited)
	}
	if err = <-busy; err != nil {
		t.Fatal(err)
	}
	admitted := pool(t, limits(t), 1, time.Minute)
	if _, err = admitted.Resolve(context.Background(), raw, hash, root); err != nil {
		t.Fatal(err)
	}
	if _, err = New(limits(t), 0, time.Second, 0).Resolve(context.Background(), raw, hash, root); !errors.Is(err, d.ErrResolverPermanent) {
		t.Fatal("pool without workers must refuse permanently", err)
	}
}

// C1-6: a request waits up to its remaining admission budget; a job without a request keeps the fixed wait, and a
// configured maximum caps the request-derived wait.
func TestAdmissionBoundFollowsRequestBudgetAndCap(t *testing.T) {
	fixed := time.Unix(1000, 0)
	l := &Launcher{admissionWait: 5 * time.Second, now: func() time.Time { return fixed }}
	if got := l.admissionBound(context.Background()); got != 5*time.Second {
		t.Fatalf("background wait=%v want 5s", got)
	}
	request := tx.WithAdmissionDeadline(context.Background(), fixed.Add(18*time.Second))
	if got := l.admissionBound(request); got != 18*time.Second {
		t.Fatalf("request wait=%v want 18s", got)
	}
	l.admissionCap = 7 * time.Second
	if got := l.admissionBound(request); got != 7*time.Second {
		t.Fatalf("capped wait=%v want 7s", got)
	}
	expired := tx.WithAdmissionDeadline(context.Background(), fixed.Add(-time.Second))
	if got := l.admissionBound(expired); got != 0 {
		t.Fatalf("expired request wait=%v want 0", got)
	}
}

// C1-6: the only worker is busy; request N+1 waits, then takes the worker that frees inside the budget.
func TestTakeWaitsWithinRequestBudgetThenAdmits(t *testing.T) {
	fixed := time.Unix(1000, 0)
	l := New(limits(t), 1, 5*time.Second, 0)
	l.now = func() time.Time { return fixed }
	l.slots <- struct{}{}
	spare := &process{}
	admitted := make(chan *process, 1)
	failed := make(chan error, 1)
	go func() {
		p, err := l.take(tx.WithAdmissionDeadline(context.Background(), fixed.Add(10*time.Second)))
		if err != nil {
			failed <- err
			return
		}
		admitted <- p
	}()
	l.spares <- spare
	select {
	case got := <-admitted:
		if got != spare {
			t.Fatalf("admitted %p want the freed spare %p", got, spare)
		}
	case err := <-failed:
		t.Fatal("request inside the budget was refused:", err)
	case <-time.After(5 * time.Second):
		t.Fatal("request inside the budget was not admitted")
	}
}

// C1-6: past the request budget the launcher refuses with ErrWorkerSaturated, which the failure mapper answers
// 503 + 35033.
func TestTakeRefusesPastRequestBudget(t *testing.T) {
	fixed := time.Unix(1000, 0)
	l := New(limits(t), 1, 5*time.Second, 0)
	l.now = func() time.Time { return fixed }
	l.slots <- struct{}{}
	_, err := l.take(tx.WithAdmissionDeadline(context.Background(), fixed.Add(-time.Millisecond)))
	if !errors.Is(err, app.ErrWorkerSaturated) || !errors.Is(err, d.ErrResolverRetryable) {
		t.Fatalf("err=%v want ErrWorkerSaturated wrapping ErrResolverRetryable", err)
	}
}
