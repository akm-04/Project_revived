package clientlog

import (
	"net/http"
	"testing"

	"gxb.local/backend/v2/internal/foundation/observability"
)

func TestJournalRowCarriesTheReplayFlag(t *testing.T) {
	row := journalRow(observability.RequestRecord{HTTPStatus: http.StatusOK, Replay: true})
	if !row.Replay {
		t.Fatal("replay flag was dropped from the journal row")
	}
	if plain := journalRow(observability.RequestRecord{HTTPStatus: http.StatusOK}); plain.Replay {
		t.Fatal("an ordinary dispatch was marked as a replay")
	}
}
