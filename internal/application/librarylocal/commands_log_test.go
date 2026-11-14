package librarylocal

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type rejectingLogLibrary struct {
	LibraryPort
	dialogs []library.DialogFact
}

func (l rejectingLogLibrary) ListDialogsTx(context.Context, tx.Queryer, identity.PlayerID) ([]library.DialogFact, error) {
	return l.dialogs, nil
}
func (rejectingLogLibrary) InsertHeroLogTx(context.Context, tx.Tx, library.HeroLogFact) (bool, error) {
	return false, library.ErrInvalidFacts
}

type dropCounter map[string]uint64

func (c dropCounter) Counter(name string, _ observability.Labels, delta uint64) { c[name] += delta }
func (dropCounter) Observe(string, observability.Labels, time.Duration)         {}

// A-023 (D1): the dialogue milestone goes through RecordHeroLogTx, so a row
// that fails its own validation is dropped and counted, not fatal to the award.
func TestDialogueLogDropsInvalidRowAndKeepsAward(t *testing.T) {
	counter := dropCounter{}
	service := Service{Library: rejectingLogLibrary{dialogs: []library.DialogFact{{PlayerID: 7, PartnerID: 3, DialogID: 1, IsAwarded: true}}}, Metrics: counter}
	if err := service.recordDialogueLogsTx(context.Background(), nil, 7, 3, time.Now()); err != nil {
		t.Fatalf("invalid diary row failed the award: %v", err)
	}
	if counter["girls_log_dropped"] != 1 {
		t.Fatalf("dropped counter=%d want 1", counter["girls_log_dropped"])
	}
}
