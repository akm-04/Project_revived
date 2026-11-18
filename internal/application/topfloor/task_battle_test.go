package topfloor

import (
	"errors"
	"fmt"
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/topfloor"
)

func TestTaskOfferErrorClassifiesVanishedTarget(t *testing.T) {
	if err := taskOfferError(fmt.Errorf("display: %w", errTaskOccupantNotRanked), false); !errors.Is(err, domain.ErrOfferStale) {
		t.Fatalf("vanished selected target must be stale: %v", err)
	}
	if err := taskOfferError(errTaskOccupantNotRanked, true); !errors.Is(err, errTaskOccupantNotRanked) {
		t.Fatalf("revenge opponent keeps its own refusal: %v", err)
	}
	if err := taskOfferError(domain.ErrRefused, false); !errors.Is(err, domain.ErrRefused) {
		t.Fatalf("unrelated refusal changed: %v", err)
	}
}

func TestTaskFingerprintIsStageOnly(t *testing.T) {
	player := identity.PlayerID(7)
	base := TaskStartCommand{StartCommand: StartCommand{Formation: []int64{11, 12}, PetID: 3, Enemy: 9}, Leader: 11}
	for name, mutate := range map[string]func(*TaskStartCommand){
		"formation": func(c *TaskStartCommand) { c.Formation = []int64{12, 11} },
		"pet":       func(c *TaskStartCommand) { c.PetID = 4 },
		"leader":    func(c *TaskStartCommand) { c.Leader = 12 },
	} {
		other := base
		mutate(&other)
		if taskFingerprint(player, base) != taskFingerprint(player, other) {
			t.Fatalf("a changed %s is the same stage: I8_PARENT_CONTRACT_V1 generation_supersede", name)
		}
	}
	for name, mutate := range map[string]func(*TaskStartCommand){
		"enemy":  func(c *TaskStartCommand) { c.Enemy = 10 },
		"avenge": func(c *TaskStartCommand) { c.Avenge = true },
	} {
		other := base
		mutate(&other)
		if taskFingerprint(player, base) == taskFingerprint(player, other) {
			t.Fatalf("%s change must be a different stage", name)
		}
	}
}
