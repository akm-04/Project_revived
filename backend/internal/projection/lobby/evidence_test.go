package lobby

import (
	"errors"
	"path/filepath"
	"testing"
	"time"
)

func testEvidencePath(dir, run, role string) string {
	return filepath.Join(dir, run+"-"+role+".jsonl")
}

func newCapturedForTest(t *testing.T, dir, run, role, pid string, started time.Time, maxEvents, ring int) *BootTracker {
	t.Helper()
	if maxEvents == 0 {
		maxEvents = 1000
	}
	if ring == 0 {
		ring = maxEvents
	}
	tr, err := NewCapturedBootTracker(EvidenceConfig{
		RunID:       run,
		ProcessRole: role,
		ProcessID:   pid,
		SinkPath:    testEvidencePath(dir, run, role),
		MaxEvents:   maxEvents,
		RingEvents:  ring,
		StartedAt:   started,
	})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = tr.Close() })
	return tr
}

func corr(tr *BootTracker, e BootEvent) BootEvent {
	return tr.Correlate(e, "session-1", "context-1", e.ConnectionTag)
}

func recordServerS0(t *testing.T, api, rt *BootTracker, base time.Time) {
	t.Helper()
	for _, mid := range EmbeddedMID1Records {
		if err := api.Record(corr(api, BootEvent{MID: mid, Kind: BootEmbedded, Phase: PhaseServerIntent, At: base})); err != nil {
			t.Fatal(err)
		}
	}
	for _, mid := range []uint16{2784, 56, 1344, 176, 2754, 1302} {
		if err := api.Record(corr(api, BootEvent{MID: mid, Kind: BootExplicitHTTP, Phase: PhaseClientRequestObserved, At: base})); err != nil {
			t.Fatal(err)
		}
	}
	for i, role := range []string{"WORLD", "SERVICE"} {
		conn := "conn-" + role
		if err := api.Record(corr(api, BootEvent{MID: 192, Kind: BootDiscovery, Phase: PhaseClientRequestObserved, At: base, Key: role})); err != nil {
			t.Fatal(err)
		}
		if err := rt.Record(corr(rt, BootEvent{MID: 32771, Kind: BootTCPLogin, Phase: PhaseClientRequestObserved, At: base, Key: role, ConnectionTag: conn})); err != nil {
			t.Fatal(err)
		}
		if err := rt.Record(corr(rt, BootEvent{Kind: BootClientConnected, Phase: PhaseClientState, At: base.Add(time.Duration(i) * time.Millisecond), Key: role, ConnectionTag: conn})); err != nil {
			t.Fatal(err)
		}
		if err := rt.Record(corr(rt, BootEvent{MID: 32779, Kind: BootRoomEntered, Phase: PhaseTransportWriteRecorded, At: base, Key: role, ConnectionTag: conn})); err != nil {
			t.Fatal(err)
		}
	}
}

func addClientProof(t *testing.T, client *BootTracker, base time.Time) {
	t.Helper()
	for _, mid := range EmbeddedMID1Records {
		if err := client.Record(corr(client, BootEvent{MID: mid, Kind: BootEmbedded, Phase: PhaseClientConsumed, At: base.Add(time.Second)})); err != nil {
			t.Fatal(err)
		}
	}
	for _, role := range []string{"WORLD", "SERVICE"} {
		if err := client.Record(corr(client, BootEvent{MID: 32779, Kind: BootRoomEntered, Phase: PhaseClientConsumed, At: base.Add(time.Second), Key: role})); err != nil {
			t.Fatal(err)
		}
	}
}

func TestCaptureDisabledRetainsNoDetailedEvents(t *testing.T) {
	tr := NewBootTracker()
	base := time.Unix(1_700_000_000, 0).UTC()
	for i := 0; i < 200000; i++ {
		if err := tr.Record(BootEvent{MID: 1056, Kind: BootLegitTimer, Phase: PhaseClientRequestObserved, At: base.Add(time.Duration(i) * time.Millisecond)}); err != nil {
			t.Fatal(err)
		}
	}
	if got := len(tr.Events()); got != 0 {
		t.Fatalf("capture-disabled detailed events=%d", got)
	}
	if got := tr.TotalEvents(); got != 200000 {
		t.Fatalf("total=%d", got)
	}
	if !tr.Health().Healthy {
		t.Fatalf("health=%+v", tr.Health())
	}
}

func TestCapturedRingBoundAndOverflowHealth(t *testing.T) {
	base := time.Unix(1_700_000_000, 0).UTC()
	tr := newCapturedForTest(t, t.TempDir(), "run-ring", ProcessAPI, "api-1", base, 20, 4)
	for i := 0; i < 19; i++ { // capture-start + 19 protocol records = max
		err := tr.Record(BootEvent{MID: 1056, Kind: BootLegitTimer, Phase: PhaseClientRequestObserved, At: base.Add(time.Duration(i+1) * time.Second)})
		if err != nil {
			t.Fatal(err)
		}
	}
	if len(tr.Events()) > 4 {
		t.Fatalf("ring retained %d", len(tr.Events()))
	}
	err := tr.Record(BootEvent{MID: 1056, Kind: BootLegitTimer, Phase: PhaseClientRequestObserved, At: base.Add(30 * time.Second)})
	if !errors.Is(err, ErrEvidenceOverflow) {
		t.Fatalf("err=%v", err)
	}
	if tr.Health().Healthy {
		t.Fatalf("overflow must poison evidence health: %+v", tr.Health())
	}
	if len(tr.Events()) > 4 {
		t.Fatalf("ring exceeded after overflow: %d", len(tr.Events()))
	}
}

func TestLoadRejectsMixedRunIDs(t *testing.T) {
	base := time.Unix(1_700_000_000, 0).UTC()
	dir := t.TempDir()
	a := newCapturedForTest(t, dir, "run-a", ProcessAPI, "api-a", base, 100, 100)
	b := newCapturedForTest(t, dir, "run-b", ProcessRealtime, "rt-b", base, 100, 100)
	_ = a.RecordHealth(base.Add(time.Second))
	_ = b.RecordHealth(base.Add(time.Second))
	_, err := LoadBootTrackerJSONL(testEvidencePath(dir, "run-a", ProcessAPI), testEvidencePath(dir, "run-b", ProcessRealtime))
	if !errors.Is(err, ErrEvidenceCorrelation) {
		t.Fatalf("expected correlation error, got %v", err)
	}
}

func TestServerEvidenceCannotBecomeClientProof(t *testing.T) {
	base := time.Unix(1_700_000_000, 0).UTC()
	dir := t.TempDir()
	api := newCapturedForTest(t, dir, "run-one", ProcessAPI, "api-1", base, 1000, 1000)
	rt := newCapturedForTest(t, dir, "run-one", ProcessRealtime, "rt-1", base, 1000, 1000)
	recordServerS0(t, api, rt, base)
	for i := 1; i <= 60; i++ {
		if err := api.Record(corr(api, BootEvent{MID: 1056, Kind: BootLegitTimer, Phase: PhaseClientRequestObserved, At: base.Add(time.Duration(i) * time.Second), Key: "building"})); err != nil {
			t.Fatal(err)
		}
	}
	_ = api.RecordHealth(base.Add(60 * time.Second))
	_ = rt.RecordHealth(base.Add(60 * time.Second))
	combined, err := LoadBootTrackerJSONL(testEvidencePath(dir, "run-one", ProcessAPI), testEvidencePath(dir, "run-one", ProcessRealtime))
	if err != nil {
		t.Fatal(err)
	}
	out := combined.EvaluateWaveS("run-one", base.Add(61*time.Second), 60*time.Second)
	if !out.ServerGreen {
		t.Fatalf("server evidence should be green: %+v", out)
	}
	if out.AcceptanceGreen || out.ClientProof.Complete || out.Verdict != "NON_GREEN_CLIENT_PROOF_REQUIRED" {
		t.Fatalf("server evidence overclaimed client proof: %+v", out)
	}
}

func TestCorrelatedClientProofCanSatisfyModel(t *testing.T) {
	base := time.Unix(1_700_000_000, 0).UTC()
	dir := t.TempDir()
	api := newCapturedForTest(t, dir, "run-green", ProcessAPI, "api-1", base, 1000, 1000)
	rt := newCapturedForTest(t, dir, "run-green", ProcessRealtime, "rt-1", base, 1000, 1000)
	client := newCapturedForTest(t, dir, "run-green", ProcessClient, "client-1", base, 1000, 1000)
	recordServerS0(t, api, rt, base)
	addClientProof(t, client, base)
	for i := 1; i <= 60; i++ {
		if err := api.Record(corr(api, BootEvent{MID: 1056, Kind: BootLegitTimer, Phase: PhaseClientRequestObserved, At: base.Add(time.Duration(i) * time.Second), Key: "building"})); err != nil {
			t.Fatal(err)
		}
	}
	for _, tr := range []*BootTracker{api, rt, client} {
		if err := tr.RecordHealth(base.Add(60 * time.Second)); err != nil {
			t.Fatal(err)
		}
	}
	combined, err := LoadBootTrackerJSONL(
		testEvidencePath(dir, "run-green", ProcessAPI),
		testEvidencePath(dir, "run-green", ProcessRealtime),
		testEvidencePath(dir, "run-green", ProcessClient),
	)
	if err != nil {
		t.Fatal(err)
	}
	out := combined.EvaluateWaveS("run-green", base.Add(61*time.Second), 60*time.Second)
	if !out.AcceptanceGreen || out.Verdict != "GREEN" {
		t.Fatalf("expected synthetic fully-correlated model green: %+v", out)
	}
}

func TestDisconnectIsNotHealthyQuiescence(t *testing.T) {
	base := time.Unix(1_700_000_000, 0).UTC()
	dir := t.TempDir()
	api := newCapturedForTest(t, dir, "run-disc", ProcessAPI, "api-1", base, 1000, 1000)
	rt := newCapturedForTest(t, dir, "run-disc", ProcessRealtime, "rt-1", base, 1000, 1000)
	recordServerS0(t, api, rt, base)
	if err := rt.Record(corr(rt, BootEvent{Kind: BootClientClosed, Phase: PhaseClientState, At: base.Add(30 * time.Second), Key: "WORLD", ConnectionTag: "conn-WORLD"})); err != nil {
		t.Fatal(err)
	}
	_ = api.RecordHealth(base.Add(60 * time.Second))
	_ = rt.RecordHealth(base.Add(60 * time.Second))
	combined, err := LoadBootTrackerJSONL(testEvidencePath(dir, "run-disc", ProcessAPI), testEvidencePath(dir, "run-disc", ProcessRealtime))
	if err != nil {
		t.Fatal(err)
	}
	q := combined.Quiescence(base.Add(61*time.Second), 60*time.Second)
	if q.Stable || q.ClientLive {
		t.Fatalf("disconnect classified as quiescent/live: %+v", q)
	}
}

func TestStaleCaptureHealthIsNotQuiescence(t *testing.T) {
	base := time.Unix(1_700_000_000, 0).UTC()
	dir := t.TempDir()
	api := newCapturedForTest(t, dir, "run-stale", ProcessAPI, "api-1", base, 1000, 1000)
	rt := newCapturedForTest(t, dir, "run-stale", ProcessRealtime, "rt-1", base, 1000, 1000)
	recordServerS0(t, api, rt, base)
	// No capture-health pulses: silence must fail closed.
	combined, err := LoadBootTrackerJSONL(testEvidencePath(dir, "run-stale", ProcessAPI), testEvidencePath(dir, "run-stale", ProcessRealtime))
	if err != nil {
		t.Fatal(err)
	}
	q := combined.Quiescence(base.Add(61*time.Second), 60*time.Second)
	if q.Stable || q.Evidence.Healthy {
		t.Fatalf("stale capture became healthy silence: %+v", q)
	}
}

func TestMultipleContextsCannotComposeOneManifest(t *testing.T) {
	base := time.Unix(1_700_000_000, 0).UTC()
	dir := t.TempDir()
	api := newCapturedForTest(t, dir, "run-multi", ProcessAPI, "api-1", base, 1000, 1000)
	rt := newCapturedForTest(t, dir, "run-multi", ProcessRealtime, "rt-1", base, 1000, 1000)
	recordServerS0(t, api, rt, base)
	s2, c2 := api.CorrelationTags("session-2", "context-2")
	if err := api.Record(BootEvent{MID: 56, Kind: BootExplicitHTTP, Phase: PhaseClientRequestObserved, At: base, SessionTag: s2, ContextTag: c2}); err != nil {
		t.Fatal(err)
	}
	combined, err := LoadBootTrackerJSONL(testEvidencePath(dir, "run-multi", ProcessAPI), testEvidencePath(dir, "run-multi", ProcessRealtime))
	if err != nil {
		t.Fatal(err)
	}
	m := combined.S0Manifest()
	if m.Complete() || len(m.CorrelationErrors) == 0 {
		t.Fatalf("multiple contexts composed: %+v", m)
	}
}

func TestClientLuaExceptionMakesAcceptanceNonGreen(t *testing.T) {
	base := time.Unix(1_700_000_000, 0).UTC()
	dir := t.TempDir()
	api := newCapturedForTest(t, dir, "run-lua", ProcessAPI, "api-1", base, 1000, 1000)
	rt := newCapturedForTest(t, dir, "run-lua", ProcessRealtime, "rt-1", base, 1000, 1000)
	client := newCapturedForTest(t, dir, "run-lua", ProcessClient, "client-1", base, 1000, 1000)
	recordServerS0(t, api, rt, base)
	addClientProof(t, client, base)
	if err := client.Record(corr(client, BootEvent{Kind: BootLuaException, Phase: PhaseClientObserved, At: base.Add(10 * time.Second), Detail: "synthetic lua error"})); err != nil {
		t.Fatal(err)
	}
	for _, tr := range []*BootTracker{api, rt, client} {
		_ = tr.RecordHealth(base.Add(60 * time.Second))
	}
	combined, err := LoadBootTrackerJSONL(testEvidencePath(dir, "run-lua", ProcessAPI), testEvidencePath(dir, "run-lua", ProcessRealtime), testEvidencePath(dir, "run-lua", ProcessClient))
	if err != nil {
		t.Fatal(err)
	}
	out := combined.EvaluateWaveS("run-lua", base.Add(61*time.Second), 60*time.Second)
	if out.AcceptanceGreen || out.ClientProof.LuaExceptions != 1 {
		t.Fatalf("Lua exception did not poison acceptance: %+v", out)
	}
}

func TestEvidenceConfigFromEnvIsFiniteAndOptIn(t *testing.T) {
	env := map[string]string{}
	get := func(k string) string { return env[k] }
	if _, enabled, err := EvidenceConfigFromEnv(ProcessAPI, get); err != nil || enabled {
		t.Fatalf("disabled env: enabled=%v err=%v", enabled, err)
	}
	env["GXB_WAVE_S_EVIDENCE_DIR"] = t.TempDir()
	env["GXB_WAVE_S_RUN_ID"] = "run-env"
	env["GXB_WAVE_S_MAX_EVENTS"] = "500"
	env["GXB_WAVE_S_RING_EVENTS"] = "20"
	cfg, enabled, err := EvidenceConfigFromEnv(ProcessAPI, get)
	if err != nil || !enabled {
		t.Fatalf("enabled env: %+v %v %v", cfg, enabled, err)
	}
	if cfg.MaxEvents != 500 || cfg.RingEvents != 20 || cfg.ProcessID == "" {
		t.Fatalf("cfg=%+v", cfg)
	}
}
