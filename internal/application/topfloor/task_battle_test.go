package topfloor

import (
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
)

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
