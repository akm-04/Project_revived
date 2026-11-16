package oneonone

import (
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/oneonone"
)

func TestStartFingerprintIgnoresFormations(t *testing.T) {
	player := identity.PlayerID(7)
	base := StartCommand{Formations: []d.Team{{Heroes: []int64{11, 12}}}, Enemy: identity.PlayerID(9)}
	changedChoice := base
	changedChoice.Formations = []d.Team{{Heroes: []int64{12, 11}}, {Heroes: []int64{13}}}
	if fingerprint(player, base) != fingerprint(player, changedChoice) {
		t.Fatal("a changed formation is the same stage: I8_PARENT_CONTRACT_V1 generation_supersede")
	}
	changedEnemy := base
	changedEnemy.Enemy = identity.PlayerID(10)
	if fingerprint(player, base) == fingerprint(player, changedEnemy) {
		t.Fatal("a changed opponent must be a different stage")
	}
	if fingerprint(player, base) == fingerprint(identity.PlayerID(8), base) {
		t.Fatal("a different player must be a different stage")
	}
}
