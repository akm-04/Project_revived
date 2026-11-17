package latency

import (
	"testing"
	"time"
)

func TestDeferredOnlyOutsideTheSection(t *testing.T) {
	t.Setenv(SectionEnvironment, "")
	if !deferred(Dedicated) {
		t.Fatal("a dedicated budget must defer outside the latency section")
	}
	if deferred(Incidental) {
		t.Fatal("an incidental budget must stay in the general section")
	}
	if DeferredReason != "latency: deferred to latency section" {
		t.Fatalf("fixed skip reason changed: %q", DeferredReason)
	}
	t.Setenv(SectionEnvironment, "1")
	if deferred(Dedicated) || deferred(Incidental) {
		t.Fatal("nothing defers inside the latency section")
	}
}

func TestIncidentalBudgetUsesTheGeneralCeiling(t *testing.T) {
	t.Setenv(SectionEnvironment, "")
	t.Setenv(ceilingEnvironment, "10")
	if got := effectiveBudget(Incidental, time.Second); got != 10*time.Second {
		t.Fatalf("incidental general budget %s, want 10s", got)
	}
	if got := effectiveBudget(Dedicated, time.Second); got != time.Second {
		t.Fatalf("dedicated general budget %s, want the unchanged 1s", got)
	}
	t.Setenv(ceilingEnvironment, "4")
	if got := effectiveBudget(Incidental, 250*time.Millisecond); got != time.Second {
		t.Fatalf("tunable ceiling ignored: %s", got)
	}
	t.Setenv(SectionEnvironment, "1")
	if got := effectiveBudget(Incidental, time.Second); got != time.Second {
		t.Fatalf("incidental section budget %s, want the unchanged 1s", got)
	}
}

func TestWithinHonoursTheCeilingAndTheSection(t *testing.T) {
	t.Setenv(SectionEnvironment, "")
	t.Setenv(ceilingEnvironment, "10")
	if !Within(Incidental, 5*time.Second, time.Second) {
		t.Fatal("an incidental miss below the general ceiling must stay green")
	}
	if Within(Incidental, 11*time.Second, time.Second) {
		t.Fatal("an incidental miss above the general ceiling must fail")
	}
	t.Setenv(SectionEnvironment, "1")
	if Within(Incidental, 5*time.Second, time.Second) {
		t.Fatal("the latency section enforces the unchanged budget")
	}
}
