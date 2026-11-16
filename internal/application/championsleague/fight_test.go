package championsleague

import (
	"testing"

	d "gxb.local/backend/v2/internal/domain/championsleague"
	"gxb.local/backend/v2/internal/domain/identity"
)

func TestFightHashHoldsOnlyTheStage(t *testing.T) {
	player := identity.PlayerID(100001)
	stage := Command{Kind: "FIGHT", Enemy: 200007, Lineup: d.Lineup{Heroes: []int64{7, 8}, Pet: 9}}
	changed := stage
	changed.Lineup = d.Lineup{Heroes: []int64{8, 7, 10}, Pet: 11}
	if fightHash(player, 3, stage) != fightHash(player, 3, changed) {
		t.Fatal("a changed lineup is the same stage: I8_PARENT_CONTRACT_V1 generation_supersede")
	}
	if fightHash(player, 3, stage) == fightHash(player, 4, stage) {
		t.Fatal("a changed intent must be a different stage")
	}
	otherEnemy := stage
	otherEnemy.Enemy = 200008
	if fightHash(player, 3, stage) == fightHash(player, 3, otherEnemy) {
		t.Fatal("a changed enemy must be a different stage")
	}
}
