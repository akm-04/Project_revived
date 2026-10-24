package lobby

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"sort"
	"strings"
	"sync"
	"time"

	"gxb.local/backend/v2/internal/foundation/ids"
)

type BootEventKind string

type EvidencePhase string

const (
	BootPrelogin     BootEventKind = "PRELOGIN_HTTP"
	BootEmbedded     BootEventKind = "MID1_EMBEDDED"
	BootExplicitHTTP BootEventKind = "EXPLICIT_HTTP"
	BootDiscovery    BootEventKind = "MID192_DISCOVERY"
	BootTCPLogin     BootEventKind = "TCP_LOGIN"
	BootRoomEntered  BootEventKind = "CHAT_ROOM_ENTERED"
	BootHeartbeat    BootEventKind = "SOCKET_HEARTBEAT"
	BootLegitTimer   BootEventKind = "LEGIT_TIMER"

	BootCaptureStart    BootEventKind = "CAPTURE_START"
	BootCaptureHealth   BootEventKind = "CAPTURE_HEALTH"
	BootCaptureStop     BootEventKind = "CAPTURE_STOP"
	BootCaptureOverflow BootEventKind = "CAPTURE_OVERFLOW"
	BootCaptureFailure  BootEventKind = "CAPTURE_FAILURE"
	BootClientConnected BootEventKind = "CLIENT_CONNECTED"
	BootClientClosed    BootEventKind = "CLIENT_DISCONNECTED"
	BootLuaException    BootEventKind = "CLIENT_LUA_EXCEPTION"
)

const (
	PhaseServerIntent           EvidencePhase = "SERVER_INTENT"
	PhaseTransportWriteRecorded EvidencePhase = "TRANSPORT_WRITE_RECORDED"
	// PhaseServerWrite is retained only to decode historical pre-R6 evidence.
	// New server evidence must use PhaseTransportWriteRecorded.
	PhaseServerWrite           EvidencePhase = "SERVER_WRITE"
	PhaseClientRequestObserved EvidencePhase = "CLIENT_REQUEST_OBSERVED"
	PhaseClientObserved        EvidencePhase = "CLIENT_OBSERVED"
	PhaseClientConsumed        EvidencePhase = "CLIENT_CONSUMED"
	PhaseCaptureHealth         EvidencePhase = "CAPTURE_HEALTH"
	PhaseClientState           EvidencePhase = "CLIENT_STATE"
)

const (
	ProcessAPI      = "API"
	ProcessRealtime = "REALTIME"
	ProcessClient   = "CLIENT"
)

var (
	ErrEvidenceOverflow    = errors.New("wave-s evidence event cap exceeded")
	ErrEvidenceClosed      = errors.New("wave-s evidence tracker closed")
	ErrEvidenceCorrelation = errors.New("wave-s evidence correlation mismatch")
)

// BootEvent is deliberately secret-free. SessionTag/ContextTag are per-run
// one-way correlation tags, never raw session/context identifiers or bearers.
// ProcessID and ConnectionTag are random opaque run-local identifiers.
type BootEvent struct {
	RunID         string        `json:"run_id,omitempty"`
	ProcessRole   string        `json:"process_role,omitempty"`
	ProcessID     string        `json:"process_id,omitempty"`
	SessionTag    string        `json:"session_tag,omitempty"`
	ContextTag    string        `json:"context_tag,omitempty"`
	ConnectionTag string        `json:"connection_tag,omitempty"`
	MID           uint16        `json:"mid,omitempty"`
	Kind          BootEventKind `json:"kind"`
	Phase         EvidencePhase `json:"phase"`
	At            time.Time     `json:"at"`
	Key           string        `json:"key,omitempty"` // finite role/socket semantic, never bearer/identity
	Detail        string        `json:"detail,omitempty"`
}

type TrackerHealth struct {
	CaptureEnabled bool      `json:"capture_enabled"`
	Healthy        bool      `json:"healthy"`
	Error          string    `json:"error,omitempty"`
	RunID          string    `json:"run_id,omitempty"`
	ProcessRole    string    `json:"process_role,omitempty"`
	ProcessID      string    `json:"process_id,omitempty"`
	TotalEvents    uint64    `json:"total_events"`
	RetainedEvents int       `json:"retained_events"`
	DroppedEvents  uint64    `json:"dropped_events"`
	LastRecordAt   time.Time `json:"last_record_at,omitempty"`
	Closed         bool      `json:"closed"`
}

type BootTracker struct {
	mu sync.Mutex

	captureEnabled bool
	runID          string
	processRole    string
	processID      string
	maxEvents      uint64
	ringCapacity   int
	events         []BootEvent
	ringStart      int
	ringCount      int
	totalEvents    uint64
	droppedEvents  uint64
	healthy        bool
	healthErr      string
	lastRecordAt   time.Time
	closed         bool

	// sink is defined in evidence.go. Keeping it on the tracker allows one
	// serialized append path without per-event open/close churn.
	sink evidenceSink
}

// evidenceSink is intentionally tiny so manifest.go does not depend on os.File.
type evidenceSink interface {
	Write([]byte) (int, error)
	Close() error
}

// NewBootTracker returns production-safe aggregate-only telemetry. Detailed
// events are not retained when capture is disabled, so timers cannot grow an
// unbounded per-event slice during ordinary operation.
func NewBootTracker() *BootTracker {
	return &BootTracker{healthy: true}
}

func (t *BootTracker) CaptureEnabled() bool {
	if t == nil {
		return false
	}
	t.mu.Lock()
	defer t.mu.Unlock()
	return t.captureEnabled
}

func (t *BootTracker) Health() TrackerHealth {
	if t == nil {
		return TrackerHealth{}
	}
	t.mu.Lock()
	defer t.mu.Unlock()
	return t.healthLocked()
}

func (t *BootTracker) healthLocked() TrackerHealth {
	return TrackerHealth{
		CaptureEnabled: t.captureEnabled,
		Healthy:        t.healthy,
		Error:          t.healthErr,
		RunID:          t.runID,
		ProcessRole:    t.processRole,
		ProcessID:      t.processID,
		TotalEvents:    t.totalEvents,
		RetainedEvents: t.ringCount,
		DroppedEvents:  t.droppedEvents,
		LastRecordAt:   t.lastRecordAt,
		Closed:         t.closed,
	}
}

func (t *BootTracker) markUnhealthyLocked(msg string) {
	t.healthy = false
	if t.healthErr == "" {
		t.healthErr = strings.TrimSpace(msg)
	}
}

func validateEvent(e BootEvent) error {
	if e.At.IsZero() || e.Kind == "" || e.Phase == "" {
		return errors.New("invalid boot event")
	}
	if kindRequiresMID(e.Kind) && e.MID == 0 {
		return errors.New("boot event requires MID")
	}
	for name, value := range map[string]string{
		"run_id": e.RunID, "process_role": e.ProcessRole, "process_id": e.ProcessID,
		"session_tag": e.SessionTag, "context_tag": e.ContextTag, "connection_tag": e.ConnectionTag,
		"key": e.Key,
	} {
		if len(value) > 128 {
			return fmt.Errorf("%s too long", name)
		}
	}
	if len(e.Detail) > 256 {
		return errors.New("detail too long")
	}
	return nil
}

func kindRequiresMID(k BootEventKind) bool {
	switch k {
	case BootPrelogin, BootEmbedded, BootExplicitHTTP, BootDiscovery, BootTCPLogin, BootRoomEntered, BootHeartbeat, BootLegitTimer:
		return true
	default:
		return false
	}
}

// Record updates aggregate status in all modes. Detailed event retention and
// JSONL output happen only during explicit capture.
func (t *BootTracker) Record(e BootEvent) error {
	if t == nil {
		return nil
	}
	if err := validateEvent(e); err != nil {
		t.mu.Lock()
		t.markUnhealthyLocked(err.Error())
		t.mu.Unlock()
		return err
	}
	t.mu.Lock()
	defer t.mu.Unlock()
	if t.closed {
		return ErrEvidenceClosed
	}
	if !t.captureEnabled {
		t.totalEvents++
		t.lastRecordAt = e.At.UTC()
		return nil
	}
	if e.RunID == "" {
		e.RunID = t.runID
	}
	if e.ProcessRole == "" {
		e.ProcessRole = t.processRole
	}
	if e.ProcessID == "" {
		e.ProcessID = t.processID
	}
	if e.RunID != t.runID || e.ProcessRole != t.processRole || e.ProcessID != t.processID {
		t.markUnhealthyLocked(ErrEvidenceCorrelation.Error())
		return ErrEvidenceCorrelation
	}
	if t.totalEvents >= t.maxEvents {
		t.droppedEvents++
		if t.healthy {
			t.markUnhealthyLocked(ErrEvidenceOverflow.Error())
			marker := BootEvent{RunID: t.runID, ProcessRole: t.processRole, ProcessID: t.processID, Kind: BootCaptureOverflow, Phase: PhaseCaptureHealth, At: e.At.UTC(), Detail: "event cap exceeded"}
			_ = t.appendSinkLocked(marker) // best effort terminal evidence marker
			t.pushRingLocked(marker)
		}
		return ErrEvidenceOverflow
	}
	if err := t.appendSinkLocked(e); err != nil {
		t.markUnhealthyLocked(err.Error())
		return err
	}
	t.totalEvents++
	t.lastRecordAt = e.At.UTC()
	t.pushRingLocked(e)
	return nil
}

func (t *BootTracker) pushRingLocked(e BootEvent) {
	if t.ringCapacity <= 0 {
		return
	}
	if len(t.events) < t.ringCapacity {
		t.events = append(t.events, e)
		t.ringCount = len(t.events)
		return
	}
	t.events[t.ringStart] = e
	t.ringStart = (t.ringStart + 1) % t.ringCapacity
	t.ringCount = t.ringCapacity
}

func (t *BootTracker) Events() []BootEvent {
	if t == nil {
		return nil
	}
	t.mu.Lock()
	defer t.mu.Unlock()
	out := make([]BootEvent, 0, t.ringCount)
	if t.ringCount == 0 {
		return out
	}
	if len(t.events) < t.ringCapacity || t.ringStart == 0 {
		return append(out, t.events[:t.ringCount]...)
	}
	out = append(out, t.events[t.ringStart:]...)
	out = append(out, t.events[:t.ringStart]...)
	return out
}

func (t *BootTracker) TotalEvents() uint64 {
	if t == nil {
		return 0
	}
	t.mu.Lock()
	defer t.mu.Unlock()
	return t.totalEvents
}

// CorrelationTags turns canonical random identifiers into run-local opaque
// tags. The raw values are never stored in BootEvent.
func (t *BootTracker) CorrelationTags(sessionID, contextID string) (sessionTag, contextTag string) {
	if t == nil || !t.CaptureEnabled() {
		return "", ""
	}
	t.mu.Lock()
	runID := t.runID
	t.mu.Unlock()
	return correlationTag(runID, "session", sessionID), correlationTag(runID, "context", contextID)
}

func correlationTag(runID, namespace, raw string) string {
	if runID == "" || raw == "" {
		return ""
	}
	h := sha256.Sum256([]byte(runID + "\x00" + namespace + "\x00" + raw))
	return hex.EncodeToString(h[:16])
}

func (t *BootTracker) Correlate(e BootEvent, sessionID, contextID, connectionTag string) BootEvent {
	if t == nil {
		return e
	}
	e.SessionTag, e.ContextTag = t.CorrelationTags(sessionID, contextID)
	e.ConnectionTag = connectionTag
	return e
}

func (t *BootTracker) NewConnectionTag() string {
	if t == nil || !t.CaptureEnabled() {
		return ""
	}
	id, err := ids.NewUUID()
	if err != nil {
		t.mu.Lock()
		t.markUnhealthyLocked("connection correlation id generation failed")
		t.mu.Unlock()
		return ""
	}
	return id.String()
}

type ManifestReport struct {
	Missing           []string    `json:"missing,omitempty"`
	Unexpected        []BootEvent `json:"unexpected,omitempty"`
	ContextTag        string      `json:"context_tag,omitempty"`
	CorrelationErrors []string    `json:"correlation_errors,omitempty"`
}

func (r ManifestReport) Complete() bool {
	return len(r.Missing) == 0 && len(r.CorrelationErrors) == 0 && r.ContextTag != ""
}

// S0Manifest is a server-evidence manifest only. It proves one correlated
// context reached the expected server-observed/request/write surfaces. It does
// not claim Lua consumption; ClientProof is separate.
func (t *BootTracker) S0Manifest() ManifestReport {
	events := t.Events()
	contexts := map[string]struct{}{}
	for _, e := range events {
		if isManifestProtocolEvent(e) && e.ContextTag != "" {
			contexts[e.ContextTag] = struct{}{}
		}
	}
	var correlationErrors []string
	var contextTag string
	if len(contexts) == 0 {
		correlationErrors = append(correlationErrors, "no correlated gameplay context")
	} else if len(contexts) > 1 {
		correlationErrors = append(correlationErrors, fmt.Sprintf("multiple gameplay contexts in one acceptance run: %d", len(contexts)))
	} else {
		for k := range contexts {
			contextTag = k
		}
	}
	seen := map[string]bool{}
	for _, e := range events {
		if e.ContextTag != contextTag || !manifestPhaseValid(e) {
			continue
		}
		seen[eventKey(e)] = true
	}
	var need []string
	for _, mid := range EmbeddedMID1Records {
		need = append(need, fmt.Sprintf("%s:%d", BootEmbedded, mid))
	}
	for _, mid := range []uint16{2784, 56, 1344, 176, 2754, 1302} {
		need = append(need, fmt.Sprintf("%s:%d", BootExplicitHTTP, mid))
	}
	for _, role := range []string{"WORLD", "SERVICE"} {
		need = append(need, fmt.Sprintf("%s:192:%s", BootDiscovery, role))
		need = append(need, fmt.Sprintf("%s:32771:%s", BootTCPLogin, role))
		need = append(need, fmt.Sprintf("%s:32779:%s", BootRoomEntered, role))
	}
	var missing []string
	for _, k := range need {
		if !seen[k] {
			missing = append(missing, k)
		}
	}
	sort.Strings(missing)
	return ManifestReport{Missing: missing, ContextTag: contextTag, CorrelationErrors: correlationErrors}
}

func isManifestProtocolEvent(e BootEvent) bool {
	switch e.Kind {
	case BootEmbedded, BootExplicitHTTP, BootDiscovery, BootTCPLogin, BootRoomEntered, BootHeartbeat, BootLegitTimer:
		return true
	default:
		return false
	}
}

func manifestPhaseValid(e BootEvent) bool {
	switch e.Kind {
	case BootEmbedded:
		return e.Phase == PhaseServerIntent
	case BootRoomEntered:
		return e.Phase == PhaseTransportWriteRecorded || e.Phase == PhaseServerWrite
	case BootExplicitHTTP, BootDiscovery, BootTCPLogin, BootHeartbeat, BootLegitTimer:
		return e.Phase == PhaseClientRequestObserved
	default:
		return false
	}
}

func eventKey(e BootEvent) string {
	if e.Key != "" {
		return fmt.Sprintf("%s:%d:%s", e.Kind, e.MID, e.Key)
	}
	return fmt.Sprintf("%s:%d", e.Kind, e.MID)
}

type EvidenceHealthReport struct {
	Healthy       bool              `json:"healthy"`
	RunID         string            `json:"run_id,omitempty"`
	ProcessIDs    map[string]string `json:"process_ids,omitempty"`
	Failures      []string          `json:"failures,omitempty"`
	WindowStart   time.Time         `json:"window_start"`
	ObservedUntil time.Time         `json:"observed_until"`
}

type QuiescenceReport struct {
	Stable         bool                 `json:"stable"`
	QuietFor       time.Duration        `json:"quiet_for"`
	Storms         []string             `json:"storms,omitempty"`
	LastActive     time.Time            `json:"last_active,omitempty"`
	Evidence       EvidenceHealthReport `json:"evidence"`
	ClientLive     bool                 `json:"client_live"`
	ClientFailures []string             `json:"client_failures,omitempty"`
	ContextTag     string               `json:"context_tag,omitempty"`
}

// Quiescence requires healthy capture and continuously live WORLD/SERVICE
// client connections for the entire window. Silence after capture failure or
// disconnect can therefore never be misclassified as healthy quiescence.
func (t *BootTracker) Quiescence(now time.Time, required time.Duration) QuiescenceReport {
	if required <= 0 {
		required = 60 * time.Second
	}
	events := t.Events()
	manifest := t.S0Manifest()
	contextTag := manifest.ContextTag
	windowStart := now.Add(-required)
	var last time.Time
	counts := map[string]int{}
	for _, e := range events {
		if e.ContextTag != contextTag || !isManifestProtocolEvent(e) {
			continue
		}
		passive := e.Kind == BootHeartbeat || (e.Kind == BootLegitTimer && (e.MID == 1056 || e.MID == 124))
		if !passive && (last.IsZero() || e.At.After(last)) {
			last = e.At
		}
		if !e.At.Before(windowStart) && !e.At.After(now) {
			counts[eventKey(e)]++
		}
	}
	quiet := time.Duration(0)
	if !last.IsZero() && now.After(last) {
		quiet = now.Sub(last)
	}
	var storms []string
	for k, n := range counts {
		limit := 5
		if containsKind(k, string(BootLegitTimer)) {
			limit = int(required/time.Second) + 10
		}
		if containsKind(k, string(BootHeartbeat)) {
			limit = 3
		}
		if n > limit {
			storms = append(storms, fmt.Sprintf("%s=%d>%d", k, n, limit))
		}
	}
	sort.Strings(storms)
	health := evidenceHealth(events, now, required)
	clientLive, clientFailures := clientLiveThrough(events, contextTag, windowStart, now)
	stable := manifest.Complete() && quiet >= required && len(storms) == 0 && health.Healthy && clientLive
	return QuiescenceReport{Stable: stable, QuietFor: quiet, Storms: storms, LastActive: last, Evidence: health, ClientLive: clientLive, ClientFailures: clientFailures, ContextTag: contextTag}
}

func evidenceHealth(events []BootEvent, now time.Time, required time.Duration) EvidenceHealthReport {
	windowStart := now.Add(-required)
	runIDs := map[string]struct{}{}
	roles := map[string]map[string]struct{}{ProcessAPI: {}, ProcessRealtime: {}}
	startAt := map[string]time.Time{}
	lastPulse := map[string]time.Time{}
	stopped := map[string]bool{}
	var failures []string
	for _, e := range events {
		if e.RunID != "" {
			runIDs[e.RunID] = struct{}{}
		}
		if _, ok := roles[e.ProcessRole]; ok && e.ProcessID != "" {
			roles[e.ProcessRole][e.ProcessID] = struct{}{}
		}
		key := e.ProcessRole + "/" + e.ProcessID
		switch e.Kind {
		case BootCaptureStart:
			if old, ok := startAt[key]; !ok || e.At.Before(old) {
				startAt[key] = e.At
			}
		case BootCaptureHealth:
			if e.At.After(lastPulse[key]) {
				lastPulse[key] = e.At
			}
		case BootCaptureStop:
			if !e.At.After(now) {
				stopped[key] = true
			}
		case BootCaptureOverflow, BootCaptureFailure:
			failures = append(failures, fmt.Sprintf("%s %s", key, e.Kind))
		}
	}
	runID := ""
	if len(runIDs) != 1 {
		failures = append(failures, fmt.Sprintf("expected one run_id, got %d", len(runIDs)))
	} else {
		for r := range runIDs {
			runID = r
		}
	}
	processIDs := map[string]string{}
	const pulseGrace = 15 * time.Second
	for _, role := range []string{ProcessAPI, ProcessRealtime} {
		idsForRole := roles[role]
		if len(idsForRole) != 1 {
			failures = append(failures, fmt.Sprintf("%s requires exactly one process instance, got %d", role, len(idsForRole)))
			continue
		}
		var pid string
		for x := range idsForRole {
			pid = x
		}
		processIDs[role] = pid
		key := role + "/" + pid
		if s := startAt[key]; s.IsZero() || s.After(windowStart) {
			failures = append(failures, fmt.Sprintf("%s capture did not cover full quiescence window", role))
		}
		if p := lastPulse[key]; p.IsZero() || now.Sub(p) > pulseGrace || p.After(now) {
			failures = append(failures, fmt.Sprintf("%s capture health pulse stale or missing", role))
		}
		if stopped[key] {
			failures = append(failures, fmt.Sprintf("%s capture stopped before report", role))
		}
	}
	return EvidenceHealthReport{Healthy: len(failures) == 0, RunID: runID, ProcessIDs: processIDs, Failures: failures, WindowStart: windowStart, ObservedUntil: now}
}

func clientLiveThrough(events []BootEvent, contextTag string, windowStart, now time.Time) (bool, []string) {
	var failures []string
	for _, role := range []string{"WORLD", "SERVICE"} {
		var connected *BootEvent
		for i := range events {
			e := &events[i]
			if e.ContextTag != contextTag || e.Key != role || e.Phase != PhaseClientState || e.At.After(now) {
				continue
			}
			if e.Kind == BootClientConnected || e.Kind == BootClientClosed {
				if connected == nil || e.At.After(connected.At) {
					copy := *e
					connected = &copy
				}
			}
		}
		if connected == nil || connected.Kind != BootClientConnected {
			failures = append(failures, role+" connection not live")
			continue
		}
		if connected.At.After(windowStart) {
			failures = append(failures, role+" connection not live for full quiescence window")
		}
	}
	return len(failures) == 0, failures
}

type ClientProofReport struct {
	Complete          bool     `json:"complete"`
	ContextTag        string   `json:"context_tag,omitempty"`
	MissingConsumed   []string `json:"missing_consumed,omitempty"`
	LuaExceptions     int      `json:"lua_exceptions"`
	ClientProcessSeen bool     `json:"client_process_seen"`
	Failures          []string `json:"failures,omitempty"`
}

// ClientProof requires records produced by a real client-side harness. Server
// intent/write records are never counted as consumption evidence.
func (t *BootTracker) ClientProof(now time.Time) ClientProofReport {
	events := t.Events()
	manifest := t.S0Manifest()
	ctx := manifest.ContextTag
	seen := map[string]bool{}
	clientProcesses := map[string]struct{}{}
	luaExceptions := 0
	startAt := map[string]time.Time{}
	lastPulse := map[string]time.Time{}
	badHealth := map[string]bool{}
	for _, e := range events {
		if e.ProcessRole == ProcessClient && e.ProcessID != "" {
			clientProcesses[e.ProcessID] = struct{}{}
			key := e.ProcessID
			switch e.Kind {
			case BootCaptureStart:
				if old, ok := startAt[key]; !ok || e.At.Before(old) {
					startAt[key] = e.At
				}
			case BootCaptureHealth:
				if e.At.After(lastPulse[key]) {
					lastPulse[key] = e.At
				}
			case BootCaptureStop, BootCaptureOverflow, BootCaptureFailure:
				if !e.At.After(now) {
					badHealth[key] = true
				}
			}
		}
		if e.ContextTag != ctx || e.ProcessRole != ProcessClient {
			continue
		}
		if e.Kind == BootLuaException {
			luaExceptions++
		}
		if e.Phase == PhaseClientConsumed {
			seen[eventKey(e)] = true
		}
	}
	var missing []string
	for _, mid := range EmbeddedMID1Records {
		k := fmt.Sprintf("%s:%d", BootEmbedded, mid)
		if !seen[k] {
			missing = append(missing, k)
		}
	}
	for _, role := range []string{"WORLD", "SERVICE"} {
		k := fmt.Sprintf("%s:32779:%s", BootRoomEntered, role)
		if !seen[k] {
			missing = append(missing, k)
		}
	}
	sort.Strings(missing)
	var failures []string
	if len(clientProcesses) != 1 {
		failures = append(failures, fmt.Sprintf("expected one client evidence process, got %d", len(clientProcesses)))
	} else {
		var pid string
		for x := range clientProcesses {
			pid = x
		}
		if startAt[pid].IsZero() {
			failures = append(failures, "client capture start missing")
		}
		if lastPulse[pid].IsZero() || now.Sub(lastPulse[pid]) > 15*time.Second || lastPulse[pid].After(now) {
			failures = append(failures, "client capture health pulse stale or missing")
		}
		if badHealth[pid] {
			failures = append(failures, "client capture stopped/failed before report")
		}
	}
	if luaExceptions > 0 {
		failures = append(failures, fmt.Sprintf("lua exceptions=%d", luaExceptions))
	}
	if len(missing) > 0 {
		failures = append(failures, "required client consumption evidence missing")
	}
	complete := manifest.Complete() && len(failures) == 0
	return ClientProofReport{Complete: complete, ContextTag: ctx, MissingConsumed: missing, LuaExceptions: luaExceptions, ClientProcessSeen: len(clientProcesses) == 1, Failures: failures}
}

type WaveSReport struct {
	RunID           string            `json:"run_id"`
	GeneratedAt     time.Time         `json:"generated_at"`
	EventCount      uint64            `json:"event_count"`
	ServerManifest  ManifestReport    `json:"server_manifest"`
	Quiescence      QuiescenceReport  `json:"quiescence"`
	ClientProof     ClientProofReport `json:"client_proof"`
	ServerGreen     bool              `json:"server_green"`
	AcceptanceGreen bool              `json:"acceptance_green"`
	Verdict         string            `json:"verdict"`
}

func (t *BootTracker) EvaluateWaveS(runID string, now time.Time, required time.Duration) WaveSReport {
	manifest := t.S0Manifest()
	q := t.Quiescence(now, required)
	cp := t.ClientProof(now)
	if q.Evidence.RunID != "" && q.Evidence.RunID != runID {
		q.Evidence.Healthy = false
		q.Evidence.Failures = append(q.Evidence.Failures, fmt.Sprintf("report run_id %q does not match evidence run_id %q", runID, q.Evidence.RunID))
		q.Stable = false
	}
	serverGreen := manifest.Complete() && q.Stable
	acceptanceGreen := serverGreen && cp.Complete
	verdict := "GREEN"
	switch {
	case !serverGreen:
		verdict = "NON_GREEN_SERVER_EVIDENCE"
	case !cp.Complete:
		verdict = "NON_GREEN_CLIENT_PROOF_REQUIRED"
	}
	return WaveSReport{RunID: runID, GeneratedAt: now.UTC(), EventCount: t.TotalEvents(), ServerManifest: manifest, Quiescence: q, ClientProof: cp, ServerGreen: serverGreen, AcceptanceGreen: acceptanceGreen, Verdict: verdict}
}

func containsKind(s, k string) bool { return len(s) >= len(k) && s[:len(k)] == k }
