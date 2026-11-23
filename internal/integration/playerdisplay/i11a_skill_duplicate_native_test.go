//go:build postgres

package playerdisplay_test

import (
	"errors"
	"testing"
	"time"

	apphero "gxb.local/backend/v2/internal/application/characterhero"
)

// TestI11AHeroSkillDuplicateBatchReplaysCommittedAnswer is bug #145: the stock
// client fires byte-identical MID 39 requests while its first reply is in
// flight (HeroMainWindow.lua:3065-3081, skill_speed_up = 0.03 s), so the
// duplicates that reach the capped plan must answer the committed success, not
// 409+35028 "Not Available". The settlement stays at-most-once.
func TestI11AHeroSkillDuplicateBatchReplaysCommittedAnswer(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	actor := heroSkillLevelFixture(t, database, revision, 100000000, 1000, time.Now().UTC())
	exec(t, database, `UPDATE player_heroes SET level=100 WHERE player_id=$1 AND partner_id=1`, int64(actor.PlayerID))
	service := heroSkillLevelService(database)

	firstOperation := op()
	changes := []apphero.HeroSkillLevelChange{{Slot: 1, Count: 100}}
	first, err := service.SetAllSkillLevels(ctx, actor, 1, changes, firstOperation)
	if err != nil || !first.Success || first.SkillLevels[0] != 101 {
		t.Fatal("first batch", first, err)
	}

	duplicate, err := service.SetAllSkillLevels(ctx, actor, 1, changes, op())
	if err != nil || !duplicate.Success || duplicate.SkillLevels != first.SkillLevels || duplicate.SkillPoint != first.SkillPoint || duplicate.StateVersion != first.StateVersion {
		t.Fatal("in-flight duplicate batch must replay the committed answer", duplicate, err)
	}
	afterDuplicate := skillRead(t, database, actor, 1)
	if afterDuplicate.RawSkills.Levels[0] != 101 || afterDuplicate.StateVersion != first.StateVersion {
		t.Fatal("duplicate batch applied or charged again", afterDuplicate)
	}

	lateOperation := op()
	lateOperation.StartedAt = firstOperation.StartedAt.Add(10 * time.Second)
	late, err := service.SetAllSkillLevels(ctx, actor, 1, changes, lateOperation)
	var lateRefusal apphero.HeroSkillLevelRefusalError
	if !errors.As(err, &lateRefusal) || lateRefusal.Reason != apphero.HeroSkillLevelRefusalNoChange || late.Success {
		t.Fatal("an identical batch after the duplicate window is new intent, not a replay", late, err)
	}
	if after := skillRead(t, database, actor, 1); after.RawSkills.Levels[0] != 101 || after.StateVersion != first.StateVersion {
		t.Fatal("late request changed state", after)
	}
}

// MID 53 is sent once per tap with the button disabled until the reply; two
// identical single-skill requests are two real upgrades and must both apply.
func TestI11AHeroSkillDuplicateDoesNotReplaySingleSkill(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	actor := heroSkillLevelFixture(t, database, revision, 100000000, 1000, time.Now().UTC())
	exec(t, database, `UPDATE player_heroes SET level=100 WHERE player_id=$1 AND partner_id=1`, int64(actor.PlayerID))
	service := heroSkillLevelService(database)

	if first, err := service.SetSkillLevel(ctx, actor, 1, 1, op()); err != nil || !first.Success || first.SkillLevels[0] != 2 {
		t.Fatal("first single upgrade", first, err)
	}
	second, err := service.SetSkillLevel(ctx, actor, 1, 1, op())
	if err != nil || !second.Success || second.SkillLevels[0] != 3 {
		t.Fatal("a second identical single upgrade is a new intent", second, err)
	}
	if after := skillRead(t, database, actor, 1); after.RawSkills.Levels[0] != 3 {
		t.Fatal("second single upgrade lost", after.RawSkills.Levels)
	}
}

// A duplicate that still fits under the cap is the same over-charge hazard; it
// must replay too, not add the delta a second time.
func TestI11AHeroSkillDuplicateBelowCapDoesNotDoubleApply(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	actor := heroSkillLevelFixture(t, database, revision, 100000000, 1000, time.Now().UTC())
	exec(t, database, `UPDATE player_heroes SET level=100 WHERE player_id=$1 AND partner_id=1`, int64(actor.PlayerID))
	service := heroSkillLevelService(database)

	changes := []apphero.HeroSkillLevelChange{{Slot: 1, Count: 10}}
	first, err := service.SetAllSkillLevels(ctx, actor, 1, changes, op())
	if err != nil || !first.Success || first.SkillLevels[0] != 11 {
		t.Fatal("first small batch", first, err)
	}
	duplicate, err := service.SetAllSkillLevels(ctx, actor, 1, changes, op())
	if err != nil || !duplicate.Success || duplicate.SkillLevels[0] != 11 || duplicate.SkillPoint != first.SkillPoint {
		t.Fatal("duplicate small batch", duplicate, err)
	}
	if after := skillRead(t, database, actor, 1); after.RawSkills.Levels[0] != 11 {
		t.Fatal("duplicate below the cap double-applied", after.RawSkills.Levels)
	}
}
