package librarylocal

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPartnerLogMapMatches836Sources(t *testing.T) {
	created := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	explicit := created.Add(24 * time.Hour)
	at := explicit.AddDate(0, 0, 100)
	rows := []lib.HeroLogFact{
		{PlayerID: 1, PartnerID: 1, LogID: lib.LogAcquired, OccurredAt: explicit},
		{PlayerID: 1, PartnerID: 2, LogID: 20001, OccurredAt: at},
	}
	logs := partnerLogMap(rows, 1, 250, 0, created, at)
	if entry, ok := logs["10001"].(map[string]any); !ok || entry["time"] != explicit.Unix() {
		t.Fatalf("explicit acquisition %#v", logs["10001"])
	}
	for _, id := range []string{"80001", "80006"} {
		if entry, ok := logs[id].(map[string]any); !ok || entry["time"] != explicit.Unix() {
			t.Fatalf("favor milestone %s %#v", id, logs[id])
		}
	}
	if _, present := logs["80002"]; present {
		t.Fatalf("favor 250 crossed 300 %#v", logs)
	}
	for _, id := range []string{"50001", "50002"} {
		if _, present := logs[id]; !present {
			t.Fatalf("hold-time milestone %s missing %#v", id, logs)
		}
	}
	if _, present := logs["50003"]; present {
		t.Fatalf("100 days reached 180 %#v", logs)
	}
	if _, present := logs["20001"]; present {
		t.Fatal("the projection leaked another partner's row into partner 1")
	}

	// Any type-1 source row is the acquisition row; a soul-stone summon must
	// not also get a synthetic Vending entry, and its time dates the hold-time
	// milestones.
	soulStone := partnerLogMap([]lib.HeroLogFact{{PlayerID: 1, PartnerID: 1, LogID: lib.LogAcquiredSoulStone, OccurredAt: explicit}}, 1, 0, 0, created, at)
	if entry, ok := soulStone["10004"].(map[string]any); !ok || entry["time"] != explicit.Unix() {
		t.Fatalf("soul-stone acquisition %#v", soulStone["10004"])
	}
	if _, present := soulStone["10001"]; present {
		t.Fatalf("synthetic Vending source beside the soul-stone row %#v", soulStone)
	}
	if _, present := soulStone["50001"]; !present {
		t.Fatalf("hold-time milestone from acquisition time missing %#v", soulStone)
	}

	// A facet without an explicit acquisition row is dated from creation.
	fallback := partnerLogMap(nil, 1, 0, 0, created, created.AddDate(0, 0, 30))
	if entry, ok := fallback["10001"].(map[string]any); !ok || entry["time"] != created.Unix() {
		t.Fatalf("creation fallback %#v", fallback["10001"])
	}
	if _, present := fallback["50001"]; !present {
		t.Fatalf("30 days from creation missing 50001 %#v", fallback)
	}

	// The durable completion counter supplies the type-7 entries even when no
	// milestone row was written, and a written row keeps its own time.
	completed := partnerLogMap([]lib.HeroLogFact{{PlayerID: 1, PartnerID: 1, LogID: 70001, OccurredAt: explicit}}, 1, 0, 30, created, at)
	if entry, ok := completed["70001"].(map[string]any); !ok || entry["time"] != explicit.Unix() {
		t.Fatalf("written dialogue milestone %#v", completed["70001"])
	}
	for _, id := range []string{"70002", "70003"} {
		if entry, ok := completed[id].(map[string]any); !ok || entry["time"] != created.Unix() {
			t.Fatalf("counter dialogue milestone %s %#v", id, completed[id])
		}
	}
	if _, present := completed["70004"]; present {
		t.Fatalf("30 completions reached 50 %#v", completed)
	}
}

type noticeLogPort struct {
	rows     []lib.HeroLogFact
	facts    lib.HeroFacts
	dialogue map[int64]int64
}

func (p noticeLogPort) ListHeroLogsTx(context.Context, tx.Queryer, identity.PlayerID) ([]lib.HeroLogFact, error) {
	return p.rows, nil
}

func (p noticeLogPort) ListHeroDialogueCountsTx(context.Context, tx.Queryer, identity.PlayerID) (map[int64]int64, error) {
	return p.dialogue, nil
}

func (p noticeLogPort) ReadHeroTx(context.Context, tx.Queryer, character.HeroRef) (lib.HeroFacts, error) {
	return p.facts, nil
}

func TestPartnerLogReaderUsesTheSharedProjection(t *testing.T) {
	created := time.Date(2026, 2, 1, 0, 0, 0, 0, time.UTC)
	at := created.AddDate(0, 0, 31)
	reader := PartnerLogReader{Queryer: noticeQueryer{}, Library: noticeLogPort{
		rows:     []lib.HeroLogFact{{PlayerID: 7, PartnerID: 3, LogID: lib.LogAcquired, OccurredAt: created}},
		facts:    lib.HeroFacts{Favor: 100, CreatedAt: created},
		dialogue: map[int64]int64{3: 30},
	}}
	logs, err := reader.ReadPartnerLog(context.Background(), 7, 3, at)
	if err != nil {
		t.Fatal(err)
	}
	want := partnerLogMap([]lib.HeroLogFact{{PlayerID: 7, PartnerID: 3, LogID: lib.LogAcquired, OccurredAt: created}}, 3, 100, 30, created, at)
	if len(logs) != len(want) {
		t.Fatalf("reader projection %#v, want %#v", logs, want)
	}
	for id, entry := range want {
		got, present := logs[id].(map[string]any)
		if !present || got["time"] != entry.(map[string]any)["time"] {
			t.Fatalf("entry %s %#v", id, logs[id])
		}
	}
	if PartnerLogRef(7, 3) != "7:3" {
		t.Fatalf("ref %q", PartnerLogRef(7, 3))
	}
}

type noticeQueryer struct{}

func (noticeQueryer) QueryRow(context.Context, string, ...any) tx.Row { return nil }
