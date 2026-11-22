package eventstore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	appevents "gxb.local/backend/v2/internal/application/events"
	"gxb.local/backend/v2/internal/domain/events"
	"gxb.local/backend/v2/internal/foundation/tx"

	"github.com/jackc/pgx/v5/pgconn"
)

const insertCycleSavepoint = "SAVEPOINT events_cycle_slot"

// InsertCycleOccurrenceTx inserts one CYCLE occurrence and reports skipped when
// its slot or interval is already taken. The savepoint keeps the caller's
// transaction usable after the unique or exclusion constraint fires, so a job
// can skip one slot and keep materialising the rest (ruling 8: never shift).
func (Store) InsertCycleOccurrenceTx(ctx context.Context, transaction tx.Tx, occurrence events.Occurrence, at time.Time) (bool, error) {
	if transaction == nil || at.IsZero() || occurrence.LogicalServerID <= 0 || occurrence.ActivityID <= 0 || occurrence.DefinitionRevision <= 0 || occurrence.StartsAt.IsZero() || occurrence.Source != "CYCLE" || occurrence.Revision <= 0 {
		return false, errInvalid
	}
	if _, err := transaction.Exec(ctx, insertCycleSavepoint); err != nil {
		return false, err
	}
	_, err := transaction.Exec(ctx, insertOccurrence,
		occurrence.LogicalServerID, occurrence.ActivityID, occurrence.DefinitionRevision, occurrence.StartsAt.UTC(),
		utcPtr(occurrence.EndsAt), utcPtr(occurrence.ClaimUntil), occurrence.Source, occurrence.Revision,
		nil, occurrence.CreatedAt.UTC(),
	)
	if err != nil {
		if _, rollbackErr := transaction.Exec(ctx, "ROLLBACK TO SAVEPOINT events_cycle_slot"); rollbackErr != nil {
			return false, rollbackErr
		}
		if isSkippedCycleSlot(err) {
			return false, nil
		}
		return false, err
	}
	if _, err := transaction.Exec(ctx, "RELEASE SAVEPOINT events_cycle_slot"); err != nil {
		return false, err
	}
	return true, nil
}

func isSkippedCycleSlot(err error) bool {
	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) {
		return false
	}
	switch {
	case pgErr.Code == "23505" && pgErr.ConstraintName == "event_occurrences_cycle_slot":
		return true
	case pgErr.Code == "23P01" && pgErr.ConstraintName == "event_occurrences_no_overlap":
		return true
	}
	return false
}

const cycleSlotTaken = `SELECT EXISTS(
	SELECT 1 FROM event_occurrences
	WHERE logical_server_id=$1 AND source='CYCLE' AND cancelled_at IS NULL AND starts_at=$2
)`

// CycleSlotTakenTx reports whether any non-cancelled CYCLE occurrence of any
// activity already starts at the instant. Such a slot stays taken, so a new
// cycle body never doubles it and a cancelled slot is never recreated (E4b
// decision 2).
func (Store) CycleSlotTakenTx(ctx context.Context, query tx.Queryer, server int64, startsAt time.Time) (bool, error) {
	if query == nil || server <= 0 || startsAt.IsZero() {
		return false, errInvalid
	}
	var taken bool
	if err := query.QueryRow(ctx, cycleSlotTaken, server, startsAt.UTC()).Scan(&taken); err != nil {
		return false, err
	}
	return taken, nil
}

const setCycleMode = `UPDATE event_cycle_settings SET mode=$2,command_key=$3,updated_at=$4 WHERE logical_server_id=$1`

// SetCycleModeTx writes AUTO or OFF for one server (F1: OFF stops new rows only).
func (Store) SetCycleModeTx(ctx context.Context, transaction tx.Tx, server int64, mode, commandKey string, at time.Time) (appevents.Settings, error) {
	if transaction == nil || server <= 0 || (mode != appevents.CycleModeAuto && mode != appevents.CycleModeOff) || commandKey == "" || at.IsZero() {
		return appevents.Settings{}, errInvalid
	}
	if _, err := (Store{}).EnsureSettingsTx(ctx, transaction, server, at); err != nil {
		return appevents.Settings{}, err
	}
	effect, err := transaction.Exec(ctx, setCycleMode, server, mode, commandKey, at.UTC())
	if err != nil {
		return appevents.Settings{}, mapWriteError(err)
	}
	if effect == nil || effect.RowsAffected() != 1 {
		return appevents.Settings{}, errInvalid
	}
	settings, found, err := (Store{}).SettingsTx(ctx, transaction, server)
	if err != nil {
		return appevents.Settings{}, err
	}
	if !found {
		return appevents.Settings{}, errInvalid
	}
	return settings, nil
}

// setCycleBody is a compare-and-swap on the stored revision, so two operators
// cannot both apply a body from the same expected revision.
const setCycleBody = `UPDATE event_cycle_settings SET cycle_revision=$2,cycle_body=$3::jsonb,command_key=$4,updated_at=$5
WHERE logical_server_id=$1 AND cycle_revision=$6`

// SetCycleBodyTx stores a new cycle body (revision > 0) or resets to the shipped
// file (revision 0, body nil). applied is false when the expected revision is
// stale; the current settings are still returned.
func (Store) SetCycleBodyTx(ctx context.Context, transaction tx.Tx, server, expectedRevision, revision int64, body json.RawMessage, commandKey string, at time.Time) (appevents.Settings, bool, error) {
	if transaction == nil || server <= 0 || expectedRevision < 0 || revision < 0 || commandKey == "" || at.IsZero() {
		return appevents.Settings{}, false, errInvalid
	}
	if revision == 0 {
		if len(body) != 0 {
			return appevents.Settings{}, false, errInvalid
		}
	} else if len(body) == 0 || !json.Valid(body) {
		return appevents.Settings{}, false, errInvalid
	}
	if _, err := (Store{}).EnsureSettingsTx(ctx, transaction, server, at); err != nil {
		return appevents.Settings{}, false, err
	}
	var stored any
	if revision > 0 {
		stored = string(body)
	}
	effect, err := transaction.Exec(ctx, setCycleBody, server, revision, stored, commandKey, at.UTC(), expectedRevision)
	if err != nil {
		return appevents.Settings{}, false, mapWriteError(err)
	}
	settings, found, err := (Store{}).SettingsTx(ctx, transaction, server)
	if err != nil {
		return appevents.Settings{}, false, err
	}
	if !found {
		return appevents.Settings{}, false, errInvalid
	}
	return settings, effect != nil && effect.RowsAffected() == 1, nil
}
