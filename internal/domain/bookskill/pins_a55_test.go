package bookskill

import (
	"errors"
	"strings"
	"testing"
	"time"
)

func a55ExtensionState(current, jobPin string, target int64) State {
	at := time.Unix(1000, 0).UTC()
	state := Seed()
	state.Buildings[2] = Building{Level: 1, CatalogRevision: current, Job: &Job{Occurrence: "a55", Revision: jobPin, StartedAt: at, Duration: 60, Target: target, Subject: 2, Cost: EmptyCost()}}
	return state
}

func TestA55ValidateWithCatalogsRequiresCompletePins(t *testing.T) {
	current := strings.Repeat("a", 64)
	jobPin := strings.Repeat("b", 64)
	full := a44Catalog(true)
	caller := a44Catalog(false)
	for name, test := range map[string]struct {
		state  func() State
		pinned map[string]Catalog
	}{
		"both pins": {
			func() State { return a55ExtensionState(current, jobPin, 2) },
			map[string]Catalog{current: full, jobPin: full},
		},
		"missing current pin": {
			func() State { return a55ExtensionState(current, jobPin, 2) },
			map[string]Catalog{jobPin: full},
		},
		"missing job pin": {
			func() State { return a55ExtensionState(current, jobPin, 2) },
			map[string]Catalog{current: full},
		},
		"job target row absent": {
			func() State {
				state := a55ExtensionState(current, jobPin, 9)
				building := state.Buildings[2]
				building.Level = 8
				state.Buildings[2] = building
				return state
			},
			map[string]Catalog{current: full, jobPin: full},
		},
		"legacy carries a pin": {
			func() State {
				state := Seed()
				state.Buildings[1] = Building{Level: 1, CatalogRevision: current}
				return state
			},
			map[string]Catalog{current: full},
		},
		"unknown type": {
			func() State {
				state := Seed()
				state.Buildings[9] = Building{Level: 1, CatalogRevision: current}
				return state
			},
			map[string]Catalog{current: full},
		},
		"current level row absent": {
			func() State {
				state := Seed()
				state.Buildings[2] = Building{Level: 9, CatalogRevision: current}
				return state
			},
			map[string]Catalog{current: full},
		},
		"job subject differs": {
			func() State {
				state := a55ExtensionState(current, jobPin, 2)
				state.Buildings[2].Job.Subject = 5
				return state
			},
			map[string]Catalog{current: full, jobPin: full},
		},
	} {
		t.Run(name, func(t *testing.T) {
			err := test.state().ValidateWithCatalogs(caller, test.pinned)
			if name == "both pins" {
				if err != nil {
					t.Fatalf("complete state refused: %v", err)
				}
				return
			}
			if !errors.Is(err, ErrUnqualified) {
				t.Fatalf("incomplete provenance admitted: %v", err)
			}
		})
	}
}

// The legacy entry point has no pin resolver, so it may never silently accept
// an extension fact or fall back to the caller catalog.
func TestA55LegacyValidateRefusesExtensionWithoutPins(t *testing.T) {
	state := Seed()
	state.Buildings[2] = Building{Level: 1, CatalogRevision: strings.Repeat("a", 64)}
	if err := state.Validate(a44Catalog(true)); !errors.Is(err, ErrUnqualified) {
		t.Fatalf("unresolved extension admitted: %v", err)
	}
}
