//go:build postgres

package playerdisplay_test

import (
	"fmt"
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	i5store "gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/objective"
)

// bloodStageFixture drives one Blood mission chain on a hero the harness saw
// (Annie: table 11001013, level 100, colour 16, missions 2013001/2013002).
type bloodStageFixture struct {
	f    bloodNativeFixture
	rev  string
	pool *pg.Pool
}

func newBloodStageFixture(t *testing.T, spec bloodFixtureSpec) bloodStageFixture {
	t.Helper()
	p := pool(t)
	fixture, rev := newBloodFixtureBase(t, p, spec)
	return bloodStageFixture{f: fixture, rev: rev, pool: p}
}

func (a bloodStageFixture) rawStage(t *testing.T) int64 {
	t.Helper()
	raw, e := (characterstore.RawAwakeningStore{}).ReadRawAwakeningBirthTx(ctx, a.pool, a.f.ref)
	if e != nil {
		t.Fatal(e)
	}
	return raw.RawStage
}

func (a bloodStageFixture) root(t *testing.T) objective.AwakeRoot {
	t.Helper()
	root, e := i5store.Store{Queryer: a.pool}.ReadAwakeningTx(ctx, a.pool, a.f.actor.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	return root
}

// openEquipClaim walks 2738 -> 54 -> 161 and asserts each stored transition.
func (a bloodStageFixture) openEquipClaim(t *testing.T, spec bloodFixtureSpec) map[string]any {
	t.Helper()
	if _, e := a.f.owner.ChangeAwakening(ctx, a.f.actor, "open", spec.first, 2, op()); e != nil {
		t.Fatal("open:", e)
	}
	if got := a.rawStage(t); got != 1 {
		t.Fatalf("raw stage after open = %d, want 1", got)
	}
	grantOp := op()
	if _, e := a.f.owner.SettleGrant(ctx, a.f.actor, grant.Plan{PlayerID: a.f.actor.PlayerID, Source: grant.SourceIdentity{Domain: "blood-stage-fixture", Operation: "blood-gear", BusinessKey: grantOp.ID.String(), Occurrence: grantOp.ID.String(), PolicyVersion: "blood-stage-fixture-v1"}, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: spec.bloodItem, Amount: 1}}}, grantOp); e != nil {
		t.Fatal("grant:", e)
	}
	if _, e := a.f.heroes.EquipItem(ctx, a.f.actor, a.f.ref.PartnerID, 1, op()); e != nil {
		t.Fatal("equip:", e)
	}
	if !a.root(t).Active[1].Complete {
		t.Fatal("equip did not complete the stage-1 Blood mission")
	}
	if got := a.rawStage(t); got != 1 {
		t.Fatalf("raw stage after equip = %d, want 1", got)
	}
	body, handled, e := a.f.owner.ClaimAwakening(ctx, a.f.actor, spec.first, op())
	if e != nil || !handled {
		t.Fatal("claim:", handled, e)
	}
	if got := a.rawStage(t); got != 2 {
		t.Fatalf("raw stage after claim = %d, want 2 (claim reply says %#v)", got, body["twice_awake_stage_"])
	}
	if active := a.root(t).Active[1]; active.Mission != spec.second {
		t.Fatalf("active Blood mission after claim = %d, want %d", active.Mission, spec.second)
	}
	return body
}

// TestBloodStageClaimStoresRawStage proves the harness claim write is not lost:
// the reply's stage-2 field is backed by the stored raw row, and a replayed
// claim neither clears the stage nor moves the root.
func TestBloodStageClaimStoresRawStage(t *testing.T) {
	a := newBloodStageFixture(t, bloodFixtureAnnie)
	body := a.openEquipClaim(t, bloodFixtureAnnie)
	stage, ok := body["twice_awake_stage_"].(map[string]any)
	if !ok || stage["stage"] != int64(2) || stage["table_id"] != int64(11001013) {
		t.Fatalf("claim body stage = %#v, want stage 2 table 11001013", body["twice_awake_stage_"])
	}
	// A distinct transport operation for an already-terminal claim replays the
	// stored root body instead of applying the transition again.
	replay, handled, e := a.f.owner.ClaimAwakening(ctx, a.f.actor, bloodFixtureAnnie.first, op())
	if e != nil || !handled {
		t.Fatal("replayed claim:", handled, e)
	}
	replayed, ok := replay["twice_awake_stage_"].(map[string]any)
	if !ok || fmt.Sprint(replayed["stage"]) != "2" {
		t.Fatalf("replayed body stage = %#v, want stage 2", replay["twice_awake_stage_"])
	}
	if got := a.rawStage(t); got != 2 {
		t.Fatalf("raw stage after replayed claim = %d, want 2", got)
	}
	if active := a.root(t).Active[1]; active.Mission != bloodFixtureAnnie.second {
		t.Fatalf("active Blood mission after replayed claim = %d, want %d", active.Mission, bloodFixtureAnnie.second)
	}
}

// TestBloodStageStartBattleAndComplete drives 866/867 through the production
// mode after the stage-2 claim, then the stage 2 -> 3 claim.
func TestBloodStageStartBattleAndComplete(t *testing.T) {
	p := pool(t)
	f := newBloodNativeFixtureFor(t, p, bloodFixtureAnnie)
	mode := f.mode(p, pg.AuthoritativeTime{Queryer: p})
	if _, e := mode.Start(ctx, f.actor, bloodFixtureAnnie.second, op()); e != nil {
		t.Fatalf("MID 866 START refused: %v", e)
	}
	if _, e := mode.Result(ctx, f.actor, bloodFixtureAnnie.second, 20, op()); e != nil {
		t.Fatalf("MID 867 RESULT refused: %v", e)
	}
	if _, e := f.owner.ChangeAwakening(ctx, f.actor, "claim", bloodFixtureAnnie.second, 2, op()); e != nil {
		t.Fatalf("stage 2 -> 3 claim: %v", e)
	}
	raw, e := (characterstore.RawAwakeningStore{}).ReadRawAwakeningBirthTx(ctx, p, f.ref)
	if e != nil || raw.RawStage != 3 {
		t.Fatalf("raw stage after final claim = %d (%v), want 3", raw.RawStage, e)
	}
}

// TestBloodStageCancelFromEachStage proves cancel 1 -> 0 and 2 -> 0 reset only
// the raw stage and clear the active occurrence.
func TestBloodStageCancelFromEachStage(t *testing.T) {
	t.Run("stage1", func(t *testing.T) {
		a := newBloodStageFixture(t, bloodFixtureAnnie)
		if _, e := a.f.owner.ChangeAwakening(ctx, a.f.actor, "open", bloodFixtureAnnie.first, 2, op()); e != nil {
			t.Fatal(e)
		}
		if _, e := a.f.owner.ChangeAwakening(ctx, a.f.actor, "cancel", bloodFixtureAnnie.first, 2, op()); e != nil {
			t.Fatal(e)
		}
		if got := a.rawStage(t); got != 0 {
			t.Fatalf("raw stage after stage-1 cancel = %d, want 0", got)
		}
		if active := a.root(t).Active[1]; active.Mission != 0 {
			t.Fatalf("active Blood mission after stage-1 cancel = %d, want 0", active.Mission)
		}
	})
	t.Run("stage2", func(t *testing.T) {
		a := newBloodStageFixture(t, bloodFixtureAnnie)
		a.openEquipClaim(t, bloodFixtureAnnie)
		if _, e := a.f.owner.ChangeAwakening(ctx, a.f.actor, "cancel", bloodFixtureAnnie.second, 2, op()); e != nil {
			t.Fatal(e)
		}
		if got := a.rawStage(t); got != 0 {
			t.Fatalf("raw stage after stage-2 cancel = %d, want 0", got)
		}
		if active := a.root(t).Active[1]; active.Mission != 0 {
			t.Fatalf("active Blood mission after stage-2 cancel = %d, want 0", active.Mission)
		}
	})
}
