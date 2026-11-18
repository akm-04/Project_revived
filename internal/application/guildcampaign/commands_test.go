package guildcampaign

import (
	"context"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// stubResultReceipts satisfies the mode's receipt surface for tests that never
// settle a result.
type stubResultReceipts struct{ receipt.Store }

func (stubResultReceipts) FindLatestTx(context.Context, tx.Queryer, receipt.LatestIdentity) (receipt.Receipt, bool, error) {
	return receipt.Receipt{}, false, nil
}

func TestResultReplayFamilyIsPerMemberRunCopyWave(t *testing.T) {
	request := Result{ChapterID: 7, CopyID: 3, CurrentIndex: 1, Formation: "1|2", PetID: 4, TotalDamage: 500, Star: 0,
		Enemies: []ResultEnemy{{HeroID: 11, HP: 30, Index: 1}}}
	fingerprint, err := resultFingerprint(request)
	if err != nil {
		t.Fatal(err)
	}
	if again, err := resultFingerprint(request); err != nil || again != fingerprint {
		t.Fatalf("fingerprint changed between identical requests: %v", err)
	}
	member := identity.ActorContext{PlayerID: 1}
	other := identity.ActorContext{PlayerID: 2}
	prefix := resultReplayPrefix(request, 5)
	if prefix != resultReplayPrefix(request, 5) {
		t.Fatal("same member, run, copy and wave produced two families")
	}
	latest := resultReplayLatest(member, prefix)
	if latest == resultReplayLatest(other, prefix) || latest == resultReplayLatest(member, resultReplayPrefix(request, 6)) {
		t.Fatal("another member or run shared the replay family")
	}
	otherWave := request
	otherWave.CurrentIndex = 2
	if latest == resultReplayLatest(member, resultReplayPrefix(otherWave, 5)) {
		t.Fatal("another wave shared the replay family")
	}
	// Each settlement keeps its own key under the family, so a later settlement
	// at the same wave is a new row the latest read can return.
	first := resultAnswerIdentity(member, prefix, operation.Context{ID: ids.UUID{1}})
	second := resultAnswerIdentity(member, prefix, operation.Context{ID: ids.UUID{2}})
	if first == second {
		t.Fatal("two settlements at one wave shared an answer key")
	}
	if !strings.HasPrefix(first.SemanticKey, latest.SemanticKeyPrefix) || !strings.HasPrefix(second.SemanticKey, latest.SemanticKeyPrefix) {
		t.Fatal("a settlement key falls outside the replay family")
	}
}

func TestReplayBodyAddsFightExistCode(t *testing.T) {
	replayed, err := replayBody([]byte(`{"rank_award":{"crystal":3,"guild_coin":4},"coin_award":12}`))
	if err != nil || !replayed.Duplicate || replayed.Body["error_code"] != int64(duplicateResultCode) {
		t.Fatalf("replay body %+v err=%v", replayed, err)
	}
}

func TestClampWavesMarksRecordedRowsAndKeepsDead(t *testing.T) {
	waves := map[int64][]EnemyRow{1: {
		{TableID: 1},
		{TableID: 2},
		{TableID: 3},
	}}
	waves = clampWaves(waves, 1, []ResultEnemy{
		{HeroID: 1, HP: 700, Index: 1},
		{HeroID: 2, HP: 500, Index: 1},
		{HeroID: 99, HP: 100, Index: 1},
	}, false)
	if rows := waves[1]; rows[0].Health != 1 || rows[0].HP != 700 {
		t.Fatalf("damaged row health=%d hp=%d, want health=1 hp=700", rows[0].Health, rows[0].HP)
	}
	if rows := waves[1]; rows[1].Health != 1 || rows[1].HP != 500 {
		t.Fatalf("damaged row health=%d hp=%d, want health=1 hp=500", rows[1].Health, rows[1].HP)
	}
	if rows := waves[1]; rows[2].Health != 0 || rows[2].HP != 0 {
		t.Fatalf("untouched row health=%d hp=%d, want health=0 hp=0", rows[2].Health, rows[2].HP)
	}

	waves = clampWaves(waves, 1, []ResultEnemy{
		{HeroID: 1, HP: 300, Index: 1},
		{HeroID: 2, HP: 0, Index: 1},
	}, false)
	if rows := waves[1]; rows[0].Health != 1 || rows[0].HP != 300 {
		t.Fatalf("known HP did not fall: health=%d hp=%d", rows[0].Health, rows[0].HP)
	}
	if rows := waves[1]; rows[1].Health != 1 || rows[1].HP != 0 {
		t.Fatalf("dead row health=%d hp=%d, want health=1 hp=0", rows[1].Health, rows[1].HP)
	}

	waves = clampWaves(waves, 1, []ResultEnemy{{HeroID: 2, HP: 900, Index: 1}}, false)
	if rows := waves[1]; rows[1].Health != 1 || rows[1].HP != 0 {
		t.Fatalf("dead row revived: health=%d hp=%d", rows[1].Health, rows[1].HP)
	}
}
