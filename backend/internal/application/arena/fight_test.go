package arena

import (
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
)

func TestFightFingerprintHoldsOnlyTheStage(t *testing.T) {
	player := identity.PlayerID(100001)
	stage := FightCommand{Enemy: 200007, Practice: false, Formation: []int64{10001001, 10001002}, Pet: 7}
	changed := stage
	changed.Formation = []int64{10001002, 10001001, 10001003}
	changed.Pet = 9
	if fingerprint(player, stage) != fingerprint(player, changed) {
		t.Fatal("a changed formation or pet is the same stage: I8_PARENT_CONTRACT_V1 generation_supersede")
	}
	for name, mutate := range map[string]func(*FightCommand){
		"enemy":    func(c *FightCommand) { c.Enemy = 200008 },
		"practice": func(c *FightCommand) { c.Practice = true },
	} {
		other := stage
		mutate(&other)
		if fingerprint(player, stage) == fingerprint(player, other) {
			t.Fatalf("a changed %s must be a different stage", name)
		}
	}
}
