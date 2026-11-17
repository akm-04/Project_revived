// Package latency is the only way a test asserts a wall-clock budget (contract GATE_LATENCY_SECTION_V1).
package latency

import (
	"os"
	"strconv"
	"testing"
	"time"
)

const (
	// SectionEnvironment is set to "1" only by the gate's latency section.
	SectionEnvironment = "GXB_LATENCY_SECTION"
	// DeferredReason is the exact skip reason the gate's latency_deferred allowlist kind recognises.
	DeferredReason       = "latency: deferred to latency section"
	ceilingEnvironment   = "GXB_LATENCY_GENERAL_CEILING_FACTOR"
	defaultCeilingFactor = 10
)

// Kind separates a test whose whole purpose is the budget from a functional test that incidentally bounds a duration.
type Kind int

const (
	// Dedicated latency tests skip outside the latency section.
	Dedicated Kind = iota
	// Incidental budgets stay active in the general section below a liveness ceiling.
	Incidental
)

func section() bool {
	return os.Getenv(SectionEnvironment) == "1"
}

func deferred(kind Kind) bool {
	return kind == Dedicated && !section()
}

func ceilingFactor() float64 {
	value := os.Getenv(ceilingEnvironment)
	if value == "" {
		return defaultCeilingFactor
	}
	factor, err := strconv.ParseFloat(value, 64)
	if err != nil || factor < 1 {
		return defaultCeilingFactor
	}
	return factor
}

func effectiveBudget(kind Kind, budget time.Duration) time.Duration {
	if section() || kind == Dedicated {
		return budget
	}
	return time.Duration(float64(budget) * ceilingFactor())
}

// Require skips a dedicated latency test outside the latency section. Call it first so measured work never runs there.
func Require(t testing.TB, kind Kind) {
	t.Helper()
	if deferred(kind) {
		t.Skip(DeferredReason)
	}
}

// Enforce fails when measured exceeds the budget: exactly inside the latency section, and above the liveness ceiling otherwise.
func Enforce(t testing.TB, kind Kind, measured, budget time.Duration) {
	t.Helper()
	if deferred(kind) {
		t.Skip(DeferredReason)
	}
	if measured > effectiveBudget(kind, budget) {
		t.Fatalf("latency: %s exceeds budget %s", measured, budget)
	}
}

// EnforceRate fails when a duration-derived rate falls below minimum: exactly inside the section, catastrophically low otherwise.
func EnforceRate(t testing.TB, kind Kind, measured, minimum float64) {
	t.Helper()
	if deferred(kind) {
		t.Skip(DeferredReason)
	}
	ceiling := minimum
	if !section() && kind == Incidental {
		ceiling = minimum / ceilingFactor()
	}
	if measured < ceiling {
		t.Fatalf("latency: %.0f per second is below the required %.0f", measured, minimum)
	}
}

// Within reports whether measured is within budget under the section and ceiling rule, for callbacks that return an error.
func Within(kind Kind, measured, budget time.Duration) bool {
	if deferred(kind) {
		return true
	}
	return measured <= effectiveBudget(kind, budget)
}
