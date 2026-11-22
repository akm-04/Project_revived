// Package eventstore owns the I11A events tables (migration 00186): the
// immutable definitions, per-server occurrences and cycle settings, and the
// player claim ledger.
package eventstore

import (
	"context"
	"encoding/json"
	"errors"
	"strconv"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	appevents "gxb.local/backend/v2/internal/application/events"
	"gxb.local/backend/v2/internal/domain/events"
	"gxb.local/backend/v2/internal/foundation/tx"

	"github.com/jackc/pgx/v5/pgconn"
)

var errInvalid = errors.New("eventstore: invalid input")

// Store reads and writes the events tables.
type Store struct{}

type occurrenceRow struct {
	ID                  int64      `json:"id"`
	LogicalServerID     int64      `json:"logical_server_id"`
	ActivityID          int64      `json:"activity_id"`
	DefinitionRevision  int64      `json:"definition_revision"`
	StartsAt            time.Time  `json:"starts_at"`
	EndsAt              *time.Time `json:"ends_at"`
	ClaimUntil          *time.Time `json:"claim_until"`
	Source              string     `json:"source"`
	Revision            int64      `json:"revision"`
	CreatedByCommand    string     `json:"created_by_command"`
	EndedEarlyByCommand string     `json:"ended_early_by_command"`
	CancelledByCommand  string     `json:"cancelled_by_command"`
	CancelledAt         *time.Time `json:"cancelled_at"`
	SettledAt           *time.Time `json:"settled_at"`
	CreatedAt           time.Time  `json:"created_at"`
}

func (row occurrenceRow) domain() events.Occurrence {
	return events.Occurrence{
		ID: row.ID, LogicalServerID: row.LogicalServerID, ActivityID: row.ActivityID, DefinitionRevision: row.DefinitionRevision,
		StartsAt: row.StartsAt.UTC(), EndsAt: utcPtr(row.EndsAt), ClaimUntil: utcPtr(row.ClaimUntil), Source: row.Source,
		Revision: row.Revision, CreatedByCommand: row.CreatedByCommand, EndedEarlyByCommand: row.EndedEarlyByCommand,
		CancelledByCommand: row.CancelledByCommand, CancelledAt: utcPtr(row.CancelledAt), SettledAt: utcPtr(row.SettledAt), CreatedAt: row.CreatedAt.UTC(),
	}
}

func utcPtr(value *time.Time) *time.Time {
	if value == nil {
		return nil
	}
	at := value.UTC()
	return &at
}

const occurrenceColumns = `jsonb_build_object(
	'id',id,'logical_server_id',logical_server_id,'activity_id',activity_id,
	'definition_revision',definition_revision,'starts_at',starts_at,'ends_at',ends_at,
	'claim_until',claim_until,'source',source,'revision',revision,
	'created_by_command',created_by_command,'ended_early_by_command',ended_early_by_command,
	'cancelled_by_command',cancelled_by_command,'cancelled_at',cancelled_at,
	'settled_at',settled_at,'created_at',created_at)`

func decodeOccurrences(raw string) ([]events.Occurrence, error) {
	var rows []occurrenceRow
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]events.Occurrence, 0, len(rows))
	for _, row := range rows {
		out = append(out, row.domain())
	}
	return out, nil
}

func mapWriteError(err error) error {
	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) {
		return err
	}
	switch {
	case pgErr.Code == "23P01" && pgErr.ConstraintName == "event_occurrences_no_overlap":
		return appevents.ErrOccurrenceOverlap
	case pgErr.Code == "23505" && pgErr.ConstraintName == "event_definitions_pkey":
		return appevents.ErrRevisionExists
	}
	return err
}

const selectDefinition = `SELECT activity_id,revision,body::text,sha256,deployed_by_command,deployed_at FROM event_definitions WHERE activity_id=$1 AND revision=$2`

type definitionRow struct {
	ActivityID        int64     `json:"activity_id"`
	Revision          int64     `json:"revision"`
	Body              string    `json:"body"`
	SHA256            string    `json:"sha256"`
	DeployedByCommand string    `json:"deployed_by_command"`
	DeployedAt        time.Time `json:"deployed_at"`
}

func scanDefinition(row *definitionRow) (*appevents.DefinitionRecord, error) {
	definition, err := events.ParseDefinition([]byte(row.Body))
	if err != nil {
		return nil, err
	}
	return &appevents.DefinitionRecord{ActivityID: row.ActivityID, Revision: row.Revision, Body: definition, SHA256: row.SHA256, DeployedByCommand: row.DeployedByCommand, DeployedAt: row.DeployedAt.UTC()}, nil
}

// DefinitionTx reads one immutable revision.
func (Store) DefinitionTx(ctx context.Context, query tx.Queryer, activityID, revision int64) (*appevents.DefinitionRecord, error) {
	if query == nil || activityID <= 0 || revision <= 0 {
		return nil, errInvalid
	}
	var row definitionRow
	if err := query.QueryRow(ctx, selectDefinition, activityID, revision).Scan(&row.ActivityID, &row.Revision, &row.Body, &row.SHA256, &row.DeployedByCommand, &row.DeployedAt); err != nil {
		if errors.Is(err, kernelstore.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	return scanDefinition(&row)
}

const selectLatestDefinition = `SELECT activity_id,revision,body::text,sha256,deployed_by_command,deployed_at FROM event_definitions WHERE activity_id=$1 ORDER BY revision DESC LIMIT 1`

// LatestDefinitionTx reads the newest deployed revision of an activity.
func (Store) LatestDefinitionTx(ctx context.Context, query tx.Queryer, activityID int64) (*appevents.DefinitionRecord, error) {
	if query == nil || activityID <= 0 {
		return nil, errInvalid
	}
	var row definitionRow
	if err := query.QueryRow(ctx, selectLatestDefinition, activityID).Scan(&row.ActivityID, &row.Revision, &row.Body, &row.SHA256, &row.DeployedByCommand, &row.DeployedAt); err != nil {
		if errors.Is(err, kernelstore.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	return scanDefinition(&row)
}

const listDefinitions = `SELECT COALESCE(jsonb_agg(jsonb_build_object(
	'activity_id',activity_id,'revision',revision,'body',body::text,'sha256',sha256,
	'deployed_by_command',deployed_by_command,'deployed_at',deployed_at) ORDER BY activity_id,revision DESC),'[]'::jsonb)::text
FROM (
	SELECT activity_id,revision,body,sha256,deployed_by_command,deployed_at
	FROM event_definitions
	WHERE ($1=0 OR activity_id=$1)
	ORDER BY activity_id,revision DESC LIMIT $2
) listed`

// ListDefinitionsTx reads the newest revisions first, optionally for one
// activity (activityID 0 = every activity).
func (Store) ListDefinitionsTx(ctx context.Context, query tx.Queryer, activityID int64, limit int) ([]appevents.DefinitionRecord, error) {
	if query == nil || activityID < 0 || limit < 1 || limit > 200 {
		return nil, errInvalid
	}
	var raw string
	if err := query.QueryRow(ctx, listDefinitions, activityID, limit).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []definitionRow
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]appevents.DefinitionRecord, 0, len(rows))
	for _, row := range rows {
		record, err := scanDefinition(&row)
		if err != nil {
			return nil, err
		}
		out = append(out, *record)
	}
	return out, nil
}

const insertDefinition = `INSERT INTO event_definitions(activity_id,revision,body,sha256,deployed_by_command,deployed_at)
VALUES($1,$2,$3::jsonb,$4,$5,$6)`

// InsertDefinitionTx stores one immutable revision; a duplicate revision is
// appevents.ErrRevisionExists.
func (Store) InsertDefinitionTx(ctx context.Context, transaction tx.Tx, record appevents.DefinitionRecord, commandKey string, at time.Time) error {
	if transaction == nil || commandKey == "" || at.IsZero() || record.ActivityID <= 0 || record.Revision <= 0 || record.SHA256 == "" {
		return errInvalid
	}
	body, err := record.Body.Body()
	if err != nil {
		return err
	}
	effect, err := transaction.Exec(ctx, insertDefinition, record.ActivityID, record.Revision, string(body), record.SHA256, commandKey, at.UTC())
	if err != nil {
		return mapWriteError(err)
	}
	if effect == nil || effect.RowsAffected() != 1 {
		return errors.New("eventstore: definition insert wrote no row")
	}
	return nil
}

const lockOccurrences = `SELECT COALESCE(jsonb_agg(` + occurrenceColumns + ` ORDER BY starts_at,id),'[]'::jsonb)::text
FROM (
	SELECT * FROM event_occurrences
	WHERE logical_server_id=$1 AND activity_id=$2 AND cancelled_at IS NULL AND settled_at IS NULL
	ORDER BY starts_at,id FOR SHARE
) locked`

// LockOccurrencesTx takes the occurrence FOR SHARE lock of one server and
// activity (rank 350); the exclusion constraint decides a concurrent insert.
func (Store) LockOccurrencesTx(ctx context.Context, transaction tx.Tx, server, activityID int64) ([]events.Occurrence, error) {
	if transaction == nil || server <= 0 || activityID <= 0 {
		return nil, errInvalid
	}
	var raw string
	if err := transaction.QueryRow(ctx, lockOccurrences, server, activityID).Scan(&raw); err != nil {
		return nil, err
	}
	return decodeOccurrences(raw)
}

const overlaps = `SELECT EXISTS(
	SELECT 1 FROM event_occurrences
	WHERE logical_server_id=$1 AND activity_id=$2 AND cancelled_at IS NULL AND settled_at IS NULL
	AND tstzrange(starts_at, coalesce(claim_until, 'infinity'::timestamptz), '[)') && tstzrange($3, coalesce($4, 'infinity'::timestamptz), '[)')
)`

// OverlapsTx asks whether an occurrence of the same activity meets the new
// interval; nil end means permanent.
func (Store) OverlapsTx(ctx context.Context, query tx.Queryer, server, activityID int64, start time.Time, end *time.Time) (bool, error) {
	if query == nil || server <= 0 || activityID <= 0 || start.IsZero() {
		return false, errInvalid
	}
	var found bool
	if err := query.QueryRow(ctx, overlaps, server, activityID, start.UTC(), utcPtr(end)).Scan(&found); err != nil {
		return false, err
	}
	return found, nil
}

const insertOccurrence = `INSERT INTO event_occurrences(
	logical_server_id,activity_id,definition_revision,starts_at,ends_at,claim_until,source,revision,
	created_by_command,cancelled_by_command,cancelled_at,settled_at,created_at)
VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,NULL,NULL,NULL,$10) RETURNING id`

// InsertOccurrenceTx stores one occurrence; the overlap exclusion maps to
// appevents.ErrOccurrenceOverlap.
func (Store) InsertOccurrenceTx(ctx context.Context, transaction tx.Tx, occurrence events.Occurrence, commandKey string, at time.Time) (int64, error) {
	if transaction == nil || at.IsZero() || occurrence.LogicalServerID <= 0 || occurrence.ActivityID <= 0 || occurrence.DefinitionRevision <= 0 || occurrence.StartsAt.IsZero() || occurrence.Revision <= 0 {
		return 0, errInvalid
	}
	var command *string
	if commandKey != "" {
		command = &commandKey
	}
	var id int64
	err := transaction.QueryRow(ctx, insertOccurrence,
		occurrence.LogicalServerID, occurrence.ActivityID, occurrence.DefinitionRevision, occurrence.StartsAt.UTC(),
		utcPtr(occurrence.EndsAt), utcPtr(occurrence.ClaimUntil), occurrence.Source, occurrence.Revision,
		command, occurrence.CreatedAt.UTC(),
	).Scan(&id)
	if err != nil {
		return 0, mapWriteError(err)
	}
	return id, nil
}

const selectOccurrence = `SELECT ` + occurrenceColumns + ` FROM event_occurrences WHERE id=$1`

// OccurrenceTx reads one occurrence without locking it.
func (Store) OccurrenceTx(ctx context.Context, query tx.Queryer, occurrenceID int64) (*events.Occurrence, error) {
	if query == nil || occurrenceID <= 0 {
		return nil, errInvalid
	}
	var raw string
	if err := query.QueryRow(ctx, selectOccurrence, occurrenceID).Scan(&raw); err != nil {
		if errors.Is(err, kernelstore.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	var row occurrenceRow
	if err := json.Unmarshal([]byte(raw), &row); err != nil {
		return nil, err
	}
	occurrence := row.domain()
	return &occurrence, nil
}

const lockOccurrence = `SELECT ` + occurrenceColumns + ` FROM event_occurrences WHERE id=$1 FOR UPDATE`

// LockOccurrenceTx locks one occurrence FOR UPDATE; nil when it does not exist.
func (Store) LockOccurrenceTx(ctx context.Context, transaction tx.Tx, occurrenceID int64) (*events.Occurrence, error) {
	if transaction == nil || occurrenceID <= 0 {
		return nil, errInvalid
	}
	var raw string
	if err := transaction.QueryRow(ctx, lockOccurrence, occurrenceID).Scan(&raw); err != nil {
		if errors.Is(err, kernelstore.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	var row occurrenceRow
	if err := json.Unmarshal([]byte(raw), &row); err != nil {
		return nil, err
	}
	occurrence := row.domain()
	return &occurrence, nil
}

const saveOccurrence = `UPDATE event_occurrences SET ends_at=$2,claim_until=$3,revision=$4,
	ended_early_by_command=$5,cancelled_by_command=$6,cancelled_at=$7,settled_at=$8
WHERE id=$1`

// SaveOccurrenceTx writes the mutated lifecycle columns; the caller holds the
// row lock.
func (Store) SaveOccurrenceTx(ctx context.Context, transaction tx.Tx, occurrence events.Occurrence) error {
	if transaction == nil || occurrence.ID <= 0 || occurrence.Revision <= 0 {
		return errInvalid
	}
	effect, err := transaction.Exec(ctx, saveOccurrence, occurrence.ID, utcPtr(occurrence.EndsAt), utcPtr(occurrence.ClaimUntil),
		occurrence.Revision, nullableText(occurrence.EndedEarlyByCommand), nullableText(occurrence.CancelledByCommand),
		utcPtr(occurrence.CancelledAt), utcPtr(occurrence.SettledAt))
	if err != nil {
		return err
	}
	if effect == nil || effect.RowsAffected() != 1 {
		return errors.New("eventstore: occurrence row disappeared under its lock")
	}
	return nil
}

func nullableText(value string) *string {
	if value == "" {
		return nil
	}
	return &value
}

// phasePredicate returns the derived-state SQL fragment for a phase (the state
// is not stored, so a bounded list filters the same way domain State computes).
// needsTime reports whether the fragment uses $2, the decision instant.
func phasePredicate(phase events.Phase) (predicate string, needsTime bool, ok bool) {
	switch phase {
	case events.PhaseCancelled:
		return "cancelled_at IS NOT NULL", false, true
	case events.PhaseArchived:
		return "(cancelled_at IS NULL AND settled_at IS NOT NULL)", false, true
	case events.PhaseScheduled:
		return "(cancelled_at IS NULL AND settled_at IS NULL AND starts_at > $2)", true, true
	case events.PhaseRunning:
		return "(cancelled_at IS NULL AND settled_at IS NULL AND starts_at <= $2 AND (ends_at IS NULL OR ends_at > $2))", true, true
	case events.PhaseClaimWindow:
		return "(cancelled_at IS NULL AND settled_at IS NULL AND ends_at <= $2 AND claim_until > $2)", true, true
	case events.PhaseEnded:
		return "(cancelled_at IS NULL AND settled_at IS NULL AND claim_until <= $2)", true, true
	default:
		return "", false, false
	}
}

// OccurrencesTx reads one bounded, newest-first page plus the caller's one
// extra row, filtered by the same derived state domain State computes.
func (Store) OccurrencesTx(ctx context.Context, query tx.Queryer, filter appevents.OccurrenceFilter) ([]events.Occurrence, error) {
	if query == nil || filter.LogicalServerID <= 0 || filter.Limit < 1 || filter.DecisionAt.IsZero() {
		return nil, errInvalid
	}
	args := []any{filter.LogicalServerID}
	conditions := []string{"logical_server_id=$1"}
	if filter.Phase != nil {
		if predicate, needsTime, ok := phasePredicate(*filter.Phase); ok {
			if needsTime {
				args = append(args, filter.DecisionAt.UTC())
			}
			conditions = append(conditions, predicate)
		}
	}
	if filter.From != nil {
		args = append(args, filter.From.UTC())
		conditions = append(conditions, "starts_at >= $"+strconv.Itoa(len(args)))
	}
	if filter.To != nil {
		args = append(args, filter.To.UTC())
		conditions = append(conditions, "starts_at < $"+strconv.Itoa(len(args)))
	}
	if filter.Cursor != nil {
		args = append(args, filter.Cursor.StartsAt.UTC(), filter.Cursor.ID)
		conditions = append(conditions, "(starts_at,id) < ($"+strconv.Itoa(len(args)-1)+",$"+strconv.Itoa(len(args))+")")
	}
	args = append(args, filter.Limit)
	statement := `SELECT COALESCE(jsonb_agg(` + occurrenceColumns + ` ORDER BY starts_at DESC,id DESC),'[]'::jsonb)::text FROM (
	SELECT * FROM event_occurrences WHERE ` + strings.Join(conditions, " AND ") + `
	ORDER BY starts_at DESC,id DESC LIMIT $` + strconv.Itoa(len(args)) + `) listed`
	var raw string
	if err := query.QueryRow(ctx, statement, args...).Scan(&raw); err != nil {
		return nil, err
	}
	return decodeOccurrences(raw)
}

const selectSettings = `SELECT mode,cycle_revision,COALESCE(cycle_body::text,''),claim_window_hours,lookahead FROM event_cycle_settings WHERE logical_server_id=$1`

// SettingsTx reads one server's settings; found is false when the server has
// no row yet, and the caller then uses the defaults.
func (Store) SettingsTx(ctx context.Context, query tx.Queryer, server int64) (appevents.Settings, bool, error) {
	if query == nil || server <= 0 {
		return appevents.Settings{}, false, errInvalid
	}
	var mode string
	var cycleRevision int64
	var cycleBody string
	var claimWindowHours int
	var lookahead int
	err := query.QueryRow(ctx, selectSettings, server).Scan(&mode, &cycleRevision, &cycleBody, &claimWindowHours, &lookahead)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return appevents.Settings{}, false, nil
	}
	if err != nil {
		return appevents.Settings{}, false, err
	}
	settings := appevents.Settings{Mode: mode, CycleRevision: cycleRevision, ClaimWindow: time.Duration(claimWindowHours) * time.Hour, Lookahead: lookahead}
	if cycleBody != "" {
		settings.CycleBody = json.RawMessage(cycleBody)
	}
	return settings, true, nil
}

const selectOccurrenceClaims = `SELECT COALESCE(jsonb_agg(jsonb_build_object(
	'player_id',player_id,'occurrence_id',occurrence_id,'tier',tier,'period',period,
	'choice',choice,'claimed_at',claimed_at,'grant_receipt',grant_receipt) ORDER BY claimed_at,player_id,tier,period),'[]'::jsonb)::text
FROM (
	SELECT player_id,occurrence_id,tier,period,choice,claimed_at,grant_receipt
	FROM player_event_claims WHERE occurrence_id=$1 ORDER BY claimed_at,player_id,tier,period LIMIT $2
) listed`

type claimRow struct {
	PlayerID     int64     `json:"player_id"`
	OccurrenceID int64     `json:"occurrence_id"`
	Tier         int64     `json:"tier"`
	Period       string    `json:"period"`
	Choice       int       `json:"choice"`
	ClaimedAt    time.Time `json:"claimed_at"`
	GrantReceipt string    `json:"grant_receipt"`
}

func (row claimRow) domain() appevents.Claim {
	return appevents.Claim{PlayerID: row.PlayerID, OccurrenceID: row.OccurrenceID, Tier: row.Tier, Period: row.Period, Choice: row.Choice, ClaimedAt: row.ClaimedAt.UTC(), GrantReceipt: row.GrantReceipt}
}

// OccurrenceClaimsTx reads a bounded claim page of one occurrence.
func (Store) OccurrenceClaimsTx(ctx context.Context, query tx.Queryer, occurrenceID int64, limit int) ([]appevents.Claim, error) {
	if query == nil || occurrenceID <= 0 || limit < 1 || limit > 201 {
		return nil, errInvalid
	}
	var raw string
	if err := query.QueryRow(ctx, selectOccurrenceClaims, occurrenceID, limit).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []claimRow
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]appevents.Claim, 0, len(rows))
	for _, row := range rows {
		out = append(out, row.domain())
	}
	return out, nil
}

const activeHooks = `SELECT COALESCE(jsonb_agg(hook ORDER BY occurrence_id,ordinality),'[]'::jsonb)::text FROM (
	SELECT o.id AS occurrence_id,h.hook,h.ord AS ordinality
	FROM event_occurrences o
	JOIN event_definitions d ON d.activity_id=o.activity_id AND d.revision=o.definition_revision
	CROSS JOIN LATERAL jsonb_array_elements(COALESCE(d.body->'hooks','[]'::jsonb)) WITH ORDINALITY AS h(hook,ord)
	WHERE o.logical_server_id=$1 AND o.cancelled_at IS NULL AND o.settled_at IS NULL
	AND o.starts_at <= $2 AND (o.ends_at IS NULL OR o.ends_at > $2)
	AND h.hook->>'hook'=$3
	ORDER BY o.id,h.ord
) active`

// ActiveHooksTx reads the hook payloads of the server's occurrences that are
// RUNNING at at (the ActiveModifiers seam, ruling 9).
func (Store) ActiveHooksTx(ctx context.Context, query tx.Queryer, server int64, at time.Time, hookKind string) ([]json.RawMessage, error) {
	if query == nil || server <= 0 || at.IsZero() || hookKind == "" {
		return nil, errInvalid
	}
	var raw string
	if err := query.QueryRow(ctx, activeHooks, server, at.UTC(), hookKind).Scan(&raw); err != nil {
		return nil, err
	}
	var hooks []json.RawMessage
	if err := json.Unmarshal([]byte(raw), &hooks); err != nil {
		return nil, err
	}
	return hooks, nil
}

const selectClaim = `SELECT player_id,occurrence_id,tier,period,choice,claimed_at,grant_receipt
FROM player_event_claims WHERE player_id=$1 AND occurrence_id=$2 ORDER BY tier,period`

// InsertClaimTx inserts a claim; on the unique (player, occurrence, tier,
// period) key it returns the existing row with inserted false.
func (Store) InsertClaimTx(ctx context.Context, transaction tx.Tx, claim appevents.Claim) (appevents.Claim, bool, error) {
	if transaction == nil || claim.PlayerID <= 0 || claim.OccurrenceID <= 0 || claim.Tier <= 0 || claim.Period == "" || claim.Choice < 1 || claim.Choice > 3 || claim.ClaimedAt.IsZero() || claim.GrantReceipt == "" {
		return appevents.Claim{}, false, errInvalid
	}
	var row claimRow
	err := transaction.QueryRow(ctx, `INSERT INTO player_event_claims(player_id,occurrence_id,tier,period,choice,claimed_at,grant_receipt)
		VALUES($1,$2,$3,$4,$5,$6,$7)
		ON CONFLICT (player_id,occurrence_id,tier,period) DO NOTHING
		RETURNING player_id,occurrence_id,tier,period,choice,claimed_at,grant_receipt`,
		claim.PlayerID, claim.OccurrenceID, claim.Tier, claim.Period, claim.Choice, claim.ClaimedAt.UTC(), claim.GrantReceipt).
		Scan(&row.PlayerID, &row.OccurrenceID, &row.Tier, &row.Period, &row.Choice, &row.ClaimedAt, &row.GrantReceipt)
	if err == nil {
		return row.domain(), true, nil
	}
	if !errors.Is(err, kernelstore.ErrNoRows) {
		return appevents.Claim{}, false, err
	}
	existing := claimRow{}
	if err := transaction.QueryRow(ctx, selectClaim, claim.PlayerID, claim.OccurrenceID).Scan(&existing.PlayerID, &existing.OccurrenceID, &existing.Tier, &existing.Period, &existing.Choice, &existing.ClaimedAt, &existing.GrantReceipt); err != nil {
		return appevents.Claim{}, false, err
	}
	return existing.domain(), false, nil
}

const selectPlayerClaims = `SELECT COALESCE(jsonb_agg(jsonb_build_object(
	'player_id',player_id,'occurrence_id',occurrence_id,'tier',tier,'period',period,
	'choice',choice,'claimed_at',claimed_at,'grant_receipt',grant_receipt) ORDER BY tier,period),'[]'::jsonb)::text
FROM player_event_claims WHERE player_id=$1 AND occurrence_id=$2`

// ClaimsForPlayerTx reads one player's claims of an occurrence.
func (Store) ClaimsForPlayerTx(ctx context.Context, query tx.Queryer, playerID, occurrenceID int64) ([]appevents.Claim, error) {
	if query == nil || playerID <= 0 || occurrenceID <= 0 {
		return nil, errInvalid
	}
	var raw string
	if err := query.QueryRow(ctx, selectPlayerClaims, playerID, occurrenceID).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []claimRow
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]appevents.Claim, 0, len(rows))
	for _, row := range rows {
		out = append(out, row.domain())
	}
	return out, nil
}
