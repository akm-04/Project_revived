package observability

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"
)

const (
	TxMetricsPathEnv     = "GXB_TX_METRICS_JSONL"
	TxMetricsMaxBytesEnv = "GXB_TX_METRICS_MAX_BYTES"
)

type JSONLMetricsConfig struct {
	Path     string
	MaxBytes int64
}

// JSONLMetricsConfigFromEnv returns a bounded transaction metrics capture
// configuration. Capture is disabled when no path is configured. When a path
// is configured a positive byte ceiling is mandatory; R6 deliberately does
// not invent an operator retention size.
func JSONLMetricsConfigFromEnv(getenv func(string) string) (JSONLMetricsConfig, bool, error) {
	if getenv == nil {
		return JSONLMetricsConfig{}, false, errors.New("nil environment reader")
	}
	path := strings.TrimSpace(getenv(TxMetricsPathEnv))
	rawMax := strings.TrimSpace(getenv(TxMetricsMaxBytesEnv))
	if path == "" {
		if rawMax != "" {
			return JSONLMetricsConfig{}, false, fmt.Errorf("%s requires %s", TxMetricsMaxBytesEnv, TxMetricsPathEnv)
		}
		return JSONLMetricsConfig{}, false, nil
	}
	if rawMax == "" {
		return JSONLMetricsConfig{}, false, fmt.Errorf("%s is required when %s is set", TxMetricsMaxBytesEnv, TxMetricsPathEnv)
	}
	maxBytes, err := strconv.ParseInt(rawMax, 10, 64)
	if err != nil || maxBytes <= 0 {
		return JSONLMetricsConfig{}, false, fmt.Errorf("%s must be a positive integer", TxMetricsMaxBytesEnv)
	}
	return JSONLMetricsConfig{Path: path, MaxBytes: maxBytes}, true, nil
}

type JSONLMetrics struct {
	mu       sync.Mutex
	file     *os.File
	maxBytes int64
	written  int64
	full     bool
}

type metricRecord struct {
	RecordedAtUnixMS int64             `json:"recorded_at_unix_ms"`
	Kind             string            `json:"kind"`
	Name             string            `json:"name"`
	Labels           map[string]string `json:"labels"`
	Delta            uint64            `json:"delta,omitempty"`
	DurationNS       int64             `json:"duration_ns,omitempty"`
}

func NewJSONLMetrics(cfg JSONLMetricsConfig) (*JSONLMetrics, error) {
	if strings.TrimSpace(cfg.Path) == "" || cfg.MaxBytes <= 0 {
		return nil, errors.New("transaction metrics path and positive MaxBytes are required")
	}
	f, err := os.OpenFile(cfg.Path, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o600)
	if err != nil {
		return nil, err
	}
	// Existing evidence files must not silently retain broader permissions.
	if err := f.Chmod(0o600); err != nil {
		_ = f.Close()
		return nil, err
	}
	info, err := f.Stat()
	if err != nil {
		_ = f.Close()
		return nil, err
	}
	return &JSONLMetrics{file: f, maxBytes: cfg.MaxBytes, written: info.Size(), full: info.Size() >= cfg.MaxBytes}, nil
}

func (m *JSONLMetrics) Counter(name string, labels Labels, delta uint64) {
	if m == nil {
		return
	}
	m.write(metricRecord{RecordedAtUnixMS: time.Now().UTC().UnixMilli(), Kind: "counter", Name: name, Labels: labelsMap(labels), Delta: delta})
}

func (m *JSONLMetrics) Observe(name string, labels Labels, value time.Duration) {
	if m == nil {
		return
	}
	m.write(metricRecord{RecordedAtUnixMS: time.Now().UTC().UnixMilli(), Kind: "duration", Name: name, Labels: labelsMap(labels), DurationNS: value.Nanoseconds()})
}

func (m *JSONLMetrics) write(record metricRecord) {
	raw, err := json.Marshal(record)
	if err != nil {
		return
	}
	raw = append(raw, '\n')
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.file == nil || m.full {
		return
	}
	if int64(len(raw)) > m.maxBytes-m.written {
		m.full = true
		return
	}
	n, err := m.file.Write(raw)
	m.written += int64(n)
	if err != nil || n != len(raw) || m.written >= m.maxBytes {
		m.full = true
	}
}

func labelsMap(labels Labels) map[string]string {
	pairs := labels.Pairs()
	out := make(map[string]string, len(pairs))
	for _, p := range pairs {
		out[p.Key] = p.Value
	}
	return out
}

func (m *JSONLMetrics) Close() error {
	if m == nil {
		return nil
	}
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.file == nil {
		return nil
	}
	err := m.file.Close()
	m.file = nil
	return err
}

func (m *JSONLMetrics) Full() bool {
	if m == nil {
		return false
	}
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.full
}
