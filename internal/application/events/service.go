// Package events applies the I11A event owner commands and serves its bounded
// reads (I11A_EVENTS_V1). Time-derived state lives in internal/domain/events.
package events

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/operatorcatalog"
	"gxb.local/backend/v2/internal/domain/events"
	"gxb.local/backend/v2/internal/domain/modes"
	otadomain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrUnavailable = errors.New("events: unavailable")

// ErrOccurrenceOverlap and ErrRevisionExists are what the store reports for the
// two uniqueness laws; the commands turn them into EVENT_OVERLAP and
// EVENT_REVISION_EXISTS.
var (
	ErrOccurrenceOverlap = errors.New("events: occurrence overlap")
	ErrRevisionExists    = errors.New("events: definition revision exists")
	ErrServerUnknown     = errors.New("events: logical server does not exist")
	ErrGroupUnknown      = errors.New("events: global group does not exist")
)

// Refusal codes (I11A_OPERATOR_COMMANDS_V1 ruling 4; I11A_EVENTS_V1).
const (
	CodePayloadInvalid         = "EVENT_PAYLOAD_INVALID"
	CodeDefinitionInvalid      = "EVENT_DEFINITION_INVALID"
	CodeDefinitionsNotComposed = "EVENT_DEFINITIONS_NOT_COMPOSED"
	CodeDefinitionUnknown      = "EVENT_DEFINITION_NOT_FOUND"
	CodeRevisionExists         = "EVENT_REVISION_EXISTS"
	CodeOverlap                = "EVENT_OVERLAP"
	CodeClientContentMissed    = "EVENT_CLIENT_CONTENT_MISSING"
	CodeHookUnbuilt            = "EVENT_HOOK_UNBUILT"
	CodeGiftUnsupported        = "EVENT_GIFT_UNSUPPORTED"
	CodeOccurrenceUnknown      = "EVENT_OCCURRENCE_NOT_FOUND"
	CodeServerUnknown          = "EVENT_SERVER_UNKNOWN"
	CodeStateInvalid           = "EVENT_STATE_INVALID"
	CodeStale                  = "EVENT_STALE"
	CodeGroupUnknown           = "EVENT_GROUP_NOT_FOUND"
)

// OccurrenceLockRank is the events occurrence row lock (EA-9, EA-10): after the
// player root 315 and the Guild audit rank 350, before the i5 grant ranks 610+.
const OccurrenceLockRank uint16 = 355

// DefinitionRecord is one stored immutable revision. SyncConflictSHA256 is the
// shipped file sha that last conflicted with it (EA-13), empty when none.
type DefinitionRecord struct {
	ActivityID         int64
	Revision           int64
	Body               events.Definition
	SHA256             string
	DeployedByCommand  string
	DeployedAt         time.Time
	SyncConflictSHA256 string
}

// GlobalGroup is one event group shared by every logical server (EA-15). Its
// occurrences are the per-server rows created with or joined to it.
type GlobalGroup struct {
	events.GlobalGroup
	Occurrences []events.Occurrence
}

// Settings is the per-server event settings row, defaulted when absent.
type Settings struct {
	Mode          string
	CycleRevision int64
	CycleBody     json.RawMessage
	ClaimWindow   time.Duration
	Lookahead     int
}

// OccurrenceFilter is the bounded events.list query (OPERATOR_COMMANDS reads).
// LogicalServerID 0 asks for the global view: groups plus server-only rows.
type OccurrenceFilter struct {
	LogicalServerID int64
	Phase           *events.Phase
	From            *time.Time
	To              *time.Time
	Limit           int
	Cursor          *OccurrenceCursor
	DecisionAt      time.Time
}

// OccurrenceCursor is the (starts_at, id) position of the last row.
type OccurrenceCursor struct {
	StartsAt time.Time
	ID       int64
}

func (cursor OccurrenceCursor) String() string {
	return cursor.StartsAt.UTC().Format(time.RFC3339Nano) + "|" + strconv.FormatInt(cursor.ID, 10)
}

// ParseOccurrenceCursor reads the opaque cursor a page returned.
func ParseOccurrenceCursor(text string) (*OccurrenceCursor, error) {
	startText, idText, found := strings.Cut(text, "|")
	if !found {
		return nil, errors.New("cursor is not a (starts_at, id) position")
	}
	startsAt, err := time.Parse(time.RFC3339Nano, startText)
	if err != nil {
		return nil, fmt.Errorf("cursor time %q is not RFC3339: %w", startText, err)
	}
	id, err := strconv.ParseInt(idText, 10, 64)
	if err != nil || id <= 0 {
		return nil, errors.New("cursor id is not a positive integer")
	}
	return &OccurrenceCursor{StartsAt: startsAt, ID: id}, nil
}

const (
	DefaultListLimit = 50
	MaxListLimit     = 200

	// Operator reads page below these bounds (I11A_OPERATOR_COMMANDS_V1 reads).
	DefaultClaimsLimit = 200
	MaxClaimsLimit     = 1000
)

func boundedClaimsLimit(limit int) (int, error) {
	if limit == 0 {
		return DefaultClaimsLimit, nil
	}
	if limit < 1 || limit > MaxClaimsLimit {
		return 0, fmt.Errorf("limit must be between 1 and %d", MaxClaimsLimit)
	}
	return limit, nil
}

func boundedLimit(limit int) (int, error) {
	if limit == 0 {
		return DefaultListLimit, nil
	}
	if limit < 1 || limit > MaxListLimit {
		return 0, fmt.Errorf("limit must be between 1 and %d", MaxListLimit)
	}
	return limit, nil
}

// OccurrenceView is the operator reply for one occurrence.
type OccurrenceView struct {
	ID                 int64      `json:"id"`
	LogicalServerID    int64      `json:"logical_server_id"`
	ActivityID         int64      `json:"activity_id"`
	DefinitionRevision int64      `json:"definition_revision"`
	State              string     `json:"state"`
	StartsAt           time.Time  `json:"starts_at"`
	EndsAt             *time.Time `json:"ends_at"`
	ClaimUntil         *time.Time `json:"claim_until"`
	Source             string     `json:"source"`
	Revision           int64      `json:"revision"`
	GlobalGroupID      *int64     `json:"global_group_id"`
}

func viewOf(occurrence events.Occurrence, at time.Time) OccurrenceView {
	return OccurrenceView{
		ID: occurrence.ID, LogicalServerID: occurrence.LogicalServerID, ActivityID: occurrence.ActivityID,
		DefinitionRevision: occurrence.DefinitionRevision, State: string(occurrence.State(at)),
		StartsAt: occurrence.StartsAt.UTC(), EndsAt: utcPtr(occurrence.EndsAt), ClaimUntil: utcPtr(occurrence.ClaimUntil),
		Source: occurrence.Source, Revision: occurrence.Revision, GlobalGroupID: occurrence.GlobalGroupID,
	}
}

func utcPtr(value *time.Time) *time.Time {
	if value == nil {
		return nil
	}
	at := value.UTC()
	return &at
}

// OccurrencePage is one events.list page. The per-server view fills
// Occurrences; the global view fills Groups with the server-only rows in
// Occurrences (EA-15 item 5), newest start first.
type OccurrencePage struct {
	Occurrences []OccurrenceView `json:"occurrences"`
	Groups      []GroupView      `json:"groups,omitempty"`
	NextCursor  string           `json:"next_cursor,omitempty"`
}

// GroupView is one global group row of the global events.list. ServerCount is
// the number of current logical servers; JoinedCount the number holding an
// occurrence; MissingServers names the rest and why they lack one.
type GroupView struct {
	ID                 int64               `json:"id"`
	ActivityID         int64               `json:"activity_id"`
	DefinitionRevision int64               `json:"definition_revision"`
	State              string              `json:"state"`
	StartsAt           time.Time           `json:"starts_at"`
	EndsAt             *time.Time          `json:"ends_at"`
	Revision           int64               `json:"revision"`
	ServerCount        int                 `json:"server_count"`
	JoinedCount        int                 `json:"joined_count"`
	MissingServers     []MissingServerView `json:"missing_servers"`
	Occurrences        []OccurrenceView    `json:"occurrences"`
}

// MissingServerView is a current server without an occurrence of the group.
// Reason is "runs its own event" when an overlapping occurrence blocks the
// join, "not joined yet" when the maintenance tick has not reached it.
type MissingServerView struct {
	ServerID int64  `json:"server_id"`
	Name     string `json:"name"`
	Reason   string `json:"reason"`
}

const (
	missingRunsOwn      = "runs its own event"
	missingNotJoinedYet = "not joined yet"
)

// Claim is one claim-ledger row (ruling 12); kept forever (P4). AwardBody is
// the stored MID 231 reply, so a repeat of the same claim re-answers exactly
// what the first command granted (EA-7).
type Claim struct {
	PlayerID       int64
	OccurrenceID   int64
	Tier           int64
	Period         string
	Choice         int
	ClaimedAt      time.Time
	GrantReceipt   string
	AwardBody      json.RawMessage
	PayloadVersion int16
}

// Store is the events owner persistence port. Every write method takes the
// caller's transaction; reads take a queryer.
type Store interface {
	DefinitionTx(context.Context, tx.Queryer, int64, int64) (*DefinitionRecord, error)
	LatestDefinitionTx(context.Context, tx.Queryer, int64) (*DefinitionRecord, error)
	ListDefinitionsTx(context.Context, tx.Queryer, int64, int) ([]DefinitionRecord, error)
	InsertDefinitionTx(context.Context, tx.Tx, DefinitionRecord, string, time.Time) error
	RecordDefinitionConflictTx(context.Context, tx.Tx, int64, int64, string, time.Time) error
	ClearDefinitionConflictTx(context.Context, tx.Tx, int64, int64) error

	LockOccurrencesTx(context.Context, tx.Tx, int64, int64) ([]events.Occurrence, error)
	OverlapsTx(context.Context, tx.Queryer, int64, int64, time.Time, *time.Time, int64) (bool, error)
	CycleSlotTakenTx(context.Context, tx.Queryer, int64, time.Time) (bool, error)
	InsertOccurrenceTx(context.Context, tx.Tx, events.Occurrence, string, time.Time) (int64, error)
	InsertGroupOccurrenceTx(context.Context, tx.Tx, events.Occurrence, string, time.Time) (int64, bool, error)
	InsertCycleOccurrenceTx(context.Context, tx.Tx, events.Occurrence, time.Time) (bool, error)
	LockOccurrenceTx(context.Context, tx.Tx, int64) (*events.Occurrence, error)
	LockOccurrenceSharedTx(context.Context, tx.Tx, int64) (*events.Occurrence, error)
	ActiveOccurrenceTx(context.Context, tx.Queryer, int64, int64, time.Time) (*events.Occurrence, error)
	ClaimOccurrenceTx(context.Context, tx.Queryer, int64, int64, time.Time) (*events.Occurrence, error)
	OccurrenceTx(context.Context, tx.Queryer, int64) (*events.Occurrence, error)
	SaveOccurrenceTx(context.Context, tx.Tx, events.Occurrence) error
	OccurrencesTx(context.Context, tx.Queryer, OccurrenceFilter) ([]events.Occurrence, error)
	ServerOnlyOccurrencesTx(context.Context, tx.Queryer, OccurrenceFilter) ([]events.Occurrence, error)
	DueOccurrencesAfterTx(context.Context, tx.Queryer, time.Time, int64, int) ([]events.Occurrence, error)
	MarkSettledTx(context.Context, tx.Tx, int64, time.Time) (bool, error)
	EnsureSettingsTx(context.Context, tx.Tx, int64, time.Time) (Settings, error)

	InsertGlobalGroupTx(context.Context, tx.Tx, GlobalGroup, string, time.Time) (int64, error)
	LockGlobalGroupTx(context.Context, tx.Tx, int64) (*GlobalGroup, error)
	SaveGlobalGroupTx(context.Context, tx.Tx, GlobalGroup) error
	LockGroupOccurrencesTx(context.Context, tx.Tx, int64) ([]events.Occurrence, error)
	ListJoinableGroupsAfterTx(context.Context, tx.Queryer, time.Time, int64, int) ([]GlobalGroup, error)
	ListGlobalGroupsTx(context.Context, tx.Queryer, int) ([]GlobalGroup, error)
	SetCycleModeTx(context.Context, tx.Tx, int64, string, string, time.Time) (Settings, error)
	SetCycleBodyTx(context.Context, tx.Tx, int64, int64, int64, json.RawMessage, string, time.Time) (Settings, bool, error)
	OccurrenceClaimsTx(context.Context, tx.Queryer, int64, int) ([]Claim, error)
	CountOccurrenceClaimsTx(context.Context, tx.Queryer, int64) (int, error)

	ActiveHooksTx(context.Context, tx.Queryer, int64, time.Time, string) ([]json.RawMessage, error)

	InsertClaimTx(context.Context, tx.Tx, Claim) (Claim, bool, error)
	HasClaimTx(context.Context, tx.Queryer, int64, int64, int64) (bool, error)
	UpdateClaimReplyTx(context.Context, tx.Tx, Claim, json.RawMessage) error
	ClaimsForPlayerTx(context.Context, tx.Queryer, int64, int64, int) ([]Claim, error)
}

// Coverage is the OTA Covers seam (I11A_OTA_RELEASE_V1 ruling 5).
type Coverage interface {
	Covers(context.Context, otadomain.CoversRequest) (otadomain.CoversResult, error)
}

// ServerDirectory enumerates every registered logical server (the I4 owner
// read; no events code reads another owner's table).
type ServerDirectory interface {
	OperatorServersTx(context.Context, tx.Queryer) ([]operator.OperatorServer, error)
}

// GiftSource resolves a client gift id to item lines from backend content
// (EA-4). found is false when the content cannot expand the gift.
type GiftSource interface {
	GiftTx(context.Context, tx.Queryer, int64) ([]events.RewardLine, bool, error)
}

// RewardCatalogue checks reward lines against the operator item catalogue.
type RewardCatalogue interface {
	CheckRewardsTx(context.Context, tx.Queryer, []events.RewardLine) error
}

// HookRegistry names the hook kinds a built owner can apply. It is empty in E1
// because the campaign hook lands in E2; a definition with any hook is then
// refused at schedule time with EVENT_HOOK_UNBUILT.
type HookRegistry struct {
	kinds map[string]struct{}
}

func NewHookRegistry(kinds ...string) (HookRegistry, error) {
	registry := HookRegistry{kinds: make(map[string]struct{}, len(kinds))}
	for _, kind := range kinds {
		trimmed := strings.TrimSpace(kind)
		if trimmed == "" || trimmed != kind {
			return HookRegistry{}, errors.New("events: invalid hook kind")
		}
		if _, duplicate := registry.kinds[kind]; duplicate {
			return HookRegistry{}, fmt.Errorf("events: duplicate hook kind %q", kind)
		}
		registry.kinds[kind] = struct{}{}
	}
	return registry, nil
}

func (registry HookRegistry) Registered(kind string) bool {
	_, ok := registry.kinds[kind]
	return ok
}

// Commands applies the events.* command handlers on the operator bus. Audit
// records the operator_commands row a system-principal sync deploy references
// (EA-13; the definition command key is a foreign key).
type Commands struct {
	Store             Store
	Coverage          Coverage
	Gifts             GiftSource
	Catalogue         RewardCatalogue
	Hooks             HookRegistry
	OperatorCatalogue operatorcatalog.Document
	Audit             operator.Store
	// Content reads the active content revision that keys a shipped-file sync
	// (EA-14.3); it is the ContentRevision seam MID 231 already uses.
	Content ContentRevision
	// Shipped are the definition files compiled into the API (EA-13); composition
	// loads them from the content layer.
	Shipped []DefinitionFile
	// Servers enumerates every logical server a global schedule covers (EA-15).
	Servers ServerDirectory
}

// Service serves the bounded reads and the ActiveModifiers seam.
type Service struct {
	Runner     tx.Runner
	Operations operation.Factory
	Store      Store
	Clock      clock.Clock
	Servers    ServerDirectory
}

func readProfile(name string) tx.Profile {
	return tx.Profile{Name: name, AcquireTimeout: 500 * time.Millisecond, LockTimeout: 500 * time.Millisecond, StatementTimeout: 1500 * time.Millisecond, TransactionTimeout: 2 * time.Second, CleanupTimeout: 500 * time.Millisecond, ReconcileTimeout: 500 * time.Millisecond, OperationTimeout: 3 * time.Second}
}

// List returns one bounded events.list page.
func (s Service) List(ctx context.Context, filter OccurrenceFilter) (OccurrencePage, error) {
	if s.Store == nil || s.Runner.DB == nil || s.Clock == nil {
		return OccurrencePage{}, ErrUnavailable
	}
	if filter.LogicalServerID < 0 {
		return OccurrencePage{}, errors.New("server must not be negative")
	}
	if filter.LogicalServerID == 0 {
		return s.listGlobal(ctx, filter)
	}
	limit, err := boundedLimit(filter.Limit)
	if err != nil {
		return OccurrencePage{}, err
	}
	requested := limit
	filter.Limit = requested + 1
	at := s.Clock.Now().UTC()
	filter.DecisionAt = at
	current, err := s.Operations.New(policy.Set{})
	if err != nil {
		return OccurrencePage{}, err
	}
	var rows []events.Occurrence
	_, err = s.Runner.Run(ctx, current, readProfile("events-list"), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		loaded, readErr := s.Store.OccurrencesTx(ctx, scope.Tx, filter)
		if readErr == nil {
			rows = loaded
		}
		return readErr
	})
	if err != nil {
		return OccurrencePage{}, err
	}
	page := OccurrencePage{Occurrences: make([]OccurrenceView, 0, requested)}
	if len(rows) > requested {
		rows = rows[:requested]
		last := rows[len(rows)-1]
		page.NextCursor = OccurrenceCursor{StartsAt: last.StartsAt, ID: last.ID}.String()
	}
	for _, row := range rows {
		page.Occurrences = append(page.Occurrences, viewOf(row, at))
	}
	return page, nil
}

// listGlobal serves events.list without a server: the global groups with their
// per-server occurrences, plus the server-only occurrences (EA-15 item 5).
func (s Service) listGlobal(ctx context.Context, filter OccurrenceFilter) (OccurrencePage, error) {
	if s.Store == nil || s.Runner.DB == nil || s.Clock == nil || s.Servers == nil {
		return OccurrencePage{}, ErrUnavailable
	}
	limit, err := boundedLimit(filter.Limit)
	if err != nil {
		return OccurrencePage{}, err
	}
	at := s.Clock.Now().UTC()
	filter.DecisionAt = at
	filter.Limit = limit + 1
	current, err := s.Operations.New(policy.Set{})
	if err != nil {
		return OccurrencePage{}, err
	}
	var groups []GlobalGroup
	var rows []events.Occurrence
	var views []GroupView
	_, err = s.Runner.Run(ctx, current, readProfile("events-list-global"), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		loadedGroups, readErr := s.Store.ListGlobalGroupsTx(ctx, scope.Tx, limit)
		if readErr != nil {
			return readErr
		}
		groups = loadedGroups
		loadedRows, readErr := s.Store.ServerOnlyOccurrencesTx(ctx, scope.Tx, filter)
		if readErr != nil {
			return readErr
		}
		rows = loadedRows
		servers, readErr := s.Servers.OperatorServersTx(ctx, scope.Tx)
		if readErr != nil {
			return readErr
		}
		names := make(map[int64]string, len(servers))
		for _, server := range servers {
			names[server.ServerID] = server.Name
		}
		for _, group := range groups {
			view, viewErr := s.groupView(ctx, scope.Tx, group, servers, names, at)
			if viewErr != nil {
				return viewErr
			}
			views = append(views, view)
		}
		return nil
	})
	if err != nil {
		return OccurrencePage{}, err
	}
	page := OccurrencePage{Occurrences: make([]OccurrenceView, 0, limit), Groups: make([]GroupView, 0, len(views))}
	if len(rows) > limit {
		rows = rows[:limit]
		last := rows[len(rows)-1]
		page.NextCursor = OccurrenceCursor{StartsAt: last.StartsAt, ID: last.ID}.String()
	}
	for _, row := range rows {
		page.Occurrences = append(page.Occurrences, viewOf(row, at))
	}
	page.Groups = views
	return page, nil
}

func (s Service) groupView(ctx context.Context, q tx.Queryer, group GlobalGroup, servers []operator.OperatorServer, names map[int64]string, at time.Time) (GroupView, error) {
	view := GroupView{
		ID: group.ID, ActivityID: group.ActivityID, DefinitionRevision: group.DefinitionRevision,
		State: string(group.Phase(at)), StartsAt: group.StartsAt.UTC(), EndsAt: utcPtr(group.EndsAt), Revision: group.Revision,
		ServerCount: len(servers), MissingServers: []MissingServerView{},
		Occurrences: make([]OccurrenceView, 0, len(group.Occurrences)),
	}
	joined := make(map[int64]struct{}, len(group.Occurrences))
	for _, occurrence := range group.Occurrences {
		view.Occurrences = append(view.Occurrences, viewOf(occurrence, at))
		joined[occurrence.LogicalServerID] = struct{}{}
	}
	view.JoinedCount = len(joined)
	for _, server := range servers {
		if _, present := joined[server.ServerID]; present {
			continue
		}
		reason := missingNotJoinedYet
		if group.Joinable(at) {
			blocked, err := s.Store.OverlapsTx(ctx, q, server.ServerID, group.ActivityID, group.StartsAt, group.EndsAt, 0)
			if err != nil {
				return GroupView{}, err
			}
			if blocked {
				reason = missingRunsOwn
			}
		}
		view.MissingServers = append(view.MissingServers, MissingServerView{ServerID: server.ServerID, Name: nameOf(names, server.ServerID), Reason: reason})
	}
	return view, nil
}

func nameOf(names map[int64]string, serverID int64) string {
	if name := names[serverID]; name != "" {
		return name
	}
	return "unknown"
}

// ActiveModifiers reads the RUNNING occurrences' hooks of one kind inside the
// caller's transaction (I11A_EVENTS_V1 ruling 9). The caller applies the
// modifier and freezes it with its own state.
func (s Service) ActiveModifiers(ctx context.Context, q tx.Queryer, server int64, at time.Time, hookKind string) ([]json.RawMessage, error) {
	if s.Store == nil || q == nil || server <= 0 || at.IsZero() || strings.TrimSpace(hookKind) == "" {
		return nil, ErrUnavailable
	}
	return s.Store.ActiveHooksTx(ctx, q, server, at.UTC(), hookKind)
}

// ClaimLedger is the claim-ledger seam E3 claims through (ruling 12).
type ClaimLedger struct {
	Store Store
}

// InsertClaimTx inserts one claim after taking the occurrence shared lock
// (EA-9 rank 355). The caller must already hold the player root lock. The
// locked row is re-read so a claim cannot land after the state it validated.
// inserted is false when the unique (player, occurrence, tier, period) key
// already existed, and the existing row is returned so a replay can answer
// with the stored award.
func (ledger ClaimLedger) InsertClaimTx(ctx context.Context, transaction tx.Tx, claim Claim) (Claim, bool, error) {
	if ledger.Store == nil {
		return Claim{}, false, ErrUnavailable
	}
	if transaction == nil || claim.OccurrenceID <= 0 || claim.ClaimedAt.IsZero() {
		return Claim{}, false, ErrUnavailable
	}
	occurrence, err := ledger.Store.LockOccurrenceSharedTx(ctx, transaction, claim.OccurrenceID)
	if err != nil {
		return Claim{}, false, err
	}
	if occurrence == nil {
		return Claim{}, false, operator.Refuse(CodeOccurrenceUnknown, "the occurrence does not exist", map[string]int64{"occurrence_id": claim.OccurrenceID})
	}
	if phase := occurrence.State(claim.ClaimedAt.UTC()); phase != events.PhaseRunning && phase != events.PhaseClaimWindow {
		return Claim{}, false, operator.Refuse(CodeStateInvalid, "the occurrence is not open for claims", map[string]string{"state": string(phase)})
	}
	return ledger.Store.InsertClaimTx(ctx, transaction, claim)
}

// ClaimsForPlayerTx reads one bounded page of one player's claims of an
// occurrence, in (tier, period) order.
func (ledger ClaimLedger) ClaimsForPlayerTx(ctx context.Context, q tx.Queryer, playerID, occurrenceID int64, limit int) ([]Claim, error) {
	if ledger.Store == nil {
		return nil, ErrUnavailable
	}
	bounded, err := boundedClaimsLimit(limit)
	if err != nil {
		return nil, err
	}
	return ledger.Store.ClaimsForPlayerTx(ctx, q, playerID, occurrenceID, bounded)
}

// Duration is a schedule/extend span (ruling 5, EA-1), parsed by the domain.
type Duration = events.Duration

var ErrInvalidDuration = events.ErrInvalidDuration

// ParseDuration accepts the five shipped spans, custom whole hours and
// "permanent".
func ParseDuration(text string) (Duration, error) {
	return events.ParseDuration(text)
}

// NextDayBoundary is the default start: the next 05:00 GMT+8 day boundary
// (ruling 5), which is one day after the game day of now.
func NextDayBoundary(now time.Time) time.Time {
	return modes.DayBegins(modes.Day(now.UTC()) + 1)
}
