package lobby

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/foundation/ids"
)

const (
	DefaultEvidenceMaxEvents      = 100000
	DefaultEvidenceRingEvents     = 2048
	DefaultEvidenceHealthInterval = 5 * time.Second
	MaxEvidenceLoadEvents         = 200000
)

type EvidenceConfig struct {
	RunID       string
	ProcessRole string
	ProcessID   string
	SinkPath    string
	MaxEvents   int
	RingEvents  int
	StartedAt   time.Time
}

func (c EvidenceConfig) validate() error {
	if c.RunID == "" || filepath.Base(c.RunID) != c.RunID || len(c.RunID) > 128 {
		return errors.New("path-safe non-empty run id required")
	}
	if c.ProcessRole != ProcessAPI && c.ProcessRole != ProcessRealtime && c.ProcessRole != ProcessClient {
		return errors.New("invalid evidence process role")
	}
	if c.ProcessID == "" || len(c.ProcessID) > 128 {
		return errors.New("process id required")
	}
	if strings.TrimSpace(c.SinkPath) == "" {
		return errors.New("evidence sink path required")
	}
	if c.MaxEvents <= 0 || c.MaxEvents > MaxEvidenceLoadEvents {
		return errors.New("invalid evidence max events")
	}
	if c.RingEvents <= 0 || c.RingEvents > c.MaxEvents {
		return errors.New("invalid evidence ring events")
	}
	return nil
}

func NewEvidenceProcessID() (string, error) {
	id, err := ids.NewUUID()
	if err != nil {
		return "", err
	}
	return id.String(), nil
}

func EvidenceConfigFromEnv(processRole string, getenv func(string) string) (EvidenceConfig, bool, error) {
	if getenv == nil {
		return EvidenceConfig{}, false, errors.New("nil getenv")
	}
	dir := strings.TrimSpace(getenv("GXB_WAVE_S_EVIDENCE_DIR"))
	if dir == "" {
		return EvidenceConfig{}, false, nil
	}
	runID := strings.TrimSpace(getenv("GXB_WAVE_S_RUN_ID"))
	if runID == "" || filepath.Base(runID) != runID {
		return EvidenceConfig{}, false, errors.New("GXB_WAVE_S_RUN_ID must be path-safe and non-empty")
	}
	pid, err := NewEvidenceProcessID()
	if err != nil {
		return EvidenceConfig{}, false, err
	}
	maxEvents, err := envPositiveInt(getenv("GXB_WAVE_S_MAX_EVENTS"), DefaultEvidenceMaxEvents)
	if err != nil {
		return EvidenceConfig{}, false, fmt.Errorf("GXB_WAVE_S_MAX_EVENTS: %w", err)
	}
	ringEvents, err := envPositiveInt(getenv("GXB_WAVE_S_RING_EVENTS"), DefaultEvidenceRingEvents)
	if err != nil {
		return EvidenceConfig{}, false, fmt.Errorf("GXB_WAVE_S_RING_EVENTS: %w", err)
	}
	if ringEvents > maxEvents {
		return EvidenceConfig{}, false, errors.New("GXB_WAVE_S_RING_EVENTS exceeds max events")
	}
	suffix := strings.ToLower(processRole)
	cfg := EvidenceConfig{RunID: runID, ProcessRole: processRole, ProcessID: pid, SinkPath: filepath.Join(dir, runID+"-"+suffix+".jsonl"), MaxEvents: maxEvents, RingEvents: ringEvents}
	return cfg, true, cfg.validate()
}

func envPositiveInt(raw string, def int) (int, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return def, nil
	}
	n, err := strconv.Atoi(raw)
	if err != nil || n <= 0 {
		return 0, errors.New("positive integer required")
	}
	return n, nil
}

func NewCapturedBootTracker(c EvidenceConfig) (*BootTracker, error) {
	if c.MaxEvents == 0 {
		c.MaxEvents = DefaultEvidenceMaxEvents
	}
	if c.RingEvents == 0 {
		c.RingEvents = DefaultEvidenceRingEvents
	}
	if c.ProcessID == "" {
		id, err := NewEvidenceProcessID()
		if err != nil {
			return nil, err
		}
		c.ProcessID = id
	}
	if err := c.validate(); err != nil {
		return nil, err
	}
	if err := os.MkdirAll(filepath.Dir(c.SinkPath), 0o755); err != nil {
		return nil, fmt.Errorf("create boot evidence directory: %w", err)
	}
	f, err := os.OpenFile(c.SinkPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o600)
	if err != nil {
		return nil, fmt.Errorf("open boot evidence file: %w", err)
	}
	t := &BootTracker{captureEnabled: true, runID: c.RunID, processRole: c.ProcessRole, processID: c.ProcessID, maxEvents: uint64(c.MaxEvents), ringCapacity: c.RingEvents, healthy: true, sink: f}
	started := c.StartedAt.UTC()
	if started.IsZero() {
		started = time.Now().UTC()
	}
	if err := t.Record(BootEvent{Kind: BootCaptureStart, Phase: PhaseCaptureHealth, At: started}); err != nil {
		_ = f.Close()
		return nil, err
	}
	return t, nil
}

// NewBootTrackerWithJSONL is retained for internal compatibility. Production
// binaries use EvidenceConfigFromEnv + NewCapturedBootTracker so run/process
// correlation is never omitted accidentally.
func NewBootTrackerWithJSONL(path string) (*BootTracker, error) {
	id, err := NewEvidenceProcessID()
	if err != nil {
		return nil, err
	}
	return NewCapturedBootTracker(EvidenceConfig{RunID: "legacy", ProcessRole: ProcessAPI, ProcessID: id, SinkPath: path, MaxEvents: DefaultEvidenceMaxEvents, RingEvents: DefaultEvidenceRingEvents})
}

func (t *BootTracker) appendSinkLocked(e BootEvent) error {
	if t.sink == nil {
		return nil
	}
	b, err := json.Marshal(e)
	if err != nil {
		return fmt.Errorf("marshal boot evidence: %w", err)
	}
	b = append(b, '\n')
	if _, err = t.sink.Write(b); err != nil {
		return fmt.Errorf("write boot evidence: %w", err)
	}
	return nil
}

func (t *BootTracker) RecordHealth(at time.Time) error {
	return t.Record(BootEvent{Kind: BootCaptureHealth, Phase: PhaseCaptureHealth, At: at.UTC()})
}

func (t *BootTracker) RunHealthPulses(ctx context.Context, interval time.Duration) error {
	if t == nil || !t.CaptureEnabled() {
		return nil
	}
	if interval <= 0 {
		interval = DefaultEvidenceHealthInterval
	}
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return nil
		case now := <-ticker.C:
			if err := t.RecordHealth(now.UTC()); err != nil {
				return err
			}
		}
	}
}

func (t *BootTracker) Close() error {
	if t == nil {
		return nil
	}
	t.mu.Lock()
	if t.closed {
		t.mu.Unlock()
		return nil
	}
	capture := t.captureEnabled
	if capture && t.sink != nil {
		e := BootEvent{RunID: t.runID, ProcessRole: t.processRole, ProcessID: t.processID, Kind: BootCaptureStop, Phase: PhaseCaptureHealth, At: time.Now().UTC()}
		_ = t.appendSinkLocked(e)
		t.pushRingLocked(e)
	}
	t.closed = true
	sink := t.sink
	t.sink = nil
	t.mu.Unlock()
	if sink != nil {
		return sink.Close()
	}
	return nil
}

// LoadBootTrackerJSONL loads finite evidence into a bounded in-memory tracker.
// Files from different run IDs fail closed rather than composing one manifest.
func LoadBootTrackerJSONL(paths ...string) (*BootTracker, error) {
	t := &BootTracker{captureEnabled: true, maxEvents: MaxEvidenceLoadEvents, ringCapacity: MaxEvidenceLoadEvents, healthy: true}
	var runID string
	count := 0
	for _, path := range paths {
		f, err := os.Open(path)
		if err != nil {
			return nil, fmt.Errorf("open boot evidence %q: %w", path, err)
		}
		s := bufio.NewScanner(f)
		s.Buffer(make([]byte, 4096), 16*1024)
		for line := 1; s.Scan(); line++ {
			count++
			if count > MaxEvidenceLoadEvents {
				_ = f.Close()
				return nil, ErrEvidenceOverflow
			}
			var e BootEvent
			if err := json.Unmarshal(s.Bytes(), &e); err != nil {
				_ = f.Close()
				return nil, fmt.Errorf("decode boot evidence %q line %d: %w", path, line, err)
			}
			if err := validateEvent(e); err != nil {
				_ = f.Close()
				return nil, fmt.Errorf("invalid boot evidence %q line %d: %w", path, line, err)
			}
			if e.RunID == "" || e.ProcessRole == "" || e.ProcessID == "" {
				_ = f.Close()
				return nil, fmt.Errorf("uncorrelated boot evidence %q line %d", path, line)
			}
			if runID == "" {
				runID = e.RunID
			} else if runID != e.RunID {
				_ = f.Close()
				return nil, fmt.Errorf("%w: run %q mixed with %q", ErrEvidenceCorrelation, runID, e.RunID)
			}
			t.runID = runID
			t.totalEvents++
			t.lastRecordAt = e.At.UTC()
			t.pushRingLocked(e)
		}
		if err := s.Err(); err != nil {
			_ = f.Close()
			return nil, fmt.Errorf("read boot evidence %q: %w", path, err)
		}
		if err := f.Close(); err != nil {
			return nil, fmt.Errorf("close boot evidence %q: %w", path, err)
		}
	}
	return t, nil
}
