package observability

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

// Metric labels are deliberately bounded. High-cardinality identities belong
// in logs/traces, never metrics.
type Labels struct{ pairs []Pair }
type Pair struct{ Key, Value string }

var allowedMetricKeys = map[string]bool{"process_role": true, "operation_class": true, "mid_family": true, "outcome": true, "phase": true, "profile": true, "sql_class": true, "queue": true, "domain": true}
var forbiddenMetricFragments = []string{"player", "account", "request", "trace", "receipt", "job_id", "connection_id", "semantic_key", "operation_id"}

func NewLabels(pairs ...Pair) (Labels, error) {
	cp := append([]Pair(nil), pairs...)
	sort.Slice(cp, func(i, j int) bool { return cp[i].Key < cp[j].Key })
	seen := map[string]bool{}
	for _, p := range cp {
		k := strings.ToLower(p.Key)
		if !allowedMetricKeys[k] {
			return Labels{}, fmt.Errorf("metric label key %q not bounded/approved", p.Key)
		}
		for _, f := range forbiddenMetricFragments {
			if strings.Contains(k, f) {
				return Labels{}, fmt.Errorf("high-cardinality metric label %q", p.Key)
			}
		}
		if p.Value == "" || len(p.Value) > 96 {
			return Labels{}, errors.New("invalid metric label value")
		}
		if seen[k] {
			return Labels{}, errors.New("duplicate metric label")
		}
		seen[k] = true
	}
	return Labels{pairs: cp}, nil
}
func (l Labels) Pairs() []Pair { return append([]Pair(nil), l.pairs...) }

type Metrics interface {
	Counter(name string, labels Labels, delta uint64)
	Observe(name string, labels Labels, value time.Duration)
}
type NopMetrics struct{}

func (NopMetrics) Counter(string, Labels, uint64)        {}
func (NopMetrics) Observe(string, Labels, time.Duration) {}
