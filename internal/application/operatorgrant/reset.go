package operatorgrant

import (
	"context"
	"slices"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// CommandResetCounters resets one or more named per-player counters for the
// target. Every reset runs through the owner's own transaction from a bulk
// target row, so one player and a whole server share one code path.
const CommandResetCounters = "player.reset_counters"

// CodeResetCounters is the refusal of a malformed counter vocabulary.
const CodeResetCounters = "OPERATOR_RESET_COUNTERS"

// Reset counter names (M12_RESETS_DESIGN section R1, table order).
const (
	CounterDailyBuys     = "daily_buys"
	CounterCampaignDaily = "campaign_daily"
	CounterTopFloor      = "top_floor"
	CounterOneOnOne      = "one_on_one"
	CounterWorldBoss     = "world_boss"
	CounterIllusion      = "illusion"
	CounterDormGlue      = "dorm_glue"
	CounterArenaDaily    = "arena_daily"
	CounterSummonFree    = "summon_free"
	CounterOccultTickets = "occult_tickets"
	CounterSkillPoints   = "skill_points"
)

// resetCounterOrder lists the R1 vocabulary in table order, so the per-
// recipient calls always run in the same order whatever the request order.
var resetCounterOrder = []string{
	CounterDailyBuys,
	CounterCampaignDaily,
	CounterTopFloor,
	CounterOneOnOne,
	CounterWorldBoss,
	CounterIllusion,
	CounterDormGlue,
	CounterArenaDaily,
	CounterSummonFree,
	CounterOccultTickets,
	CounterSkillPoints,
}

// resetCounterAvailable is the M12a set; the rest of the vocabulary is refused
// "not available yet" until M12b adds its owners.
var resetCounterAvailable = map[string]bool{
	CounterDailyBuys:     true,
	CounterCampaignDaily: true,
	CounterOccultTickets: true,
	CounterSkillPoints:   true,
}

type resetCountersPayload struct {
	Target   targetPayload `json:"target"`
	Counters []string      `json:"counters"`
}

// DailyBuysResetOwner clears the player's current-day daily consumption counts.
type DailyBuysResetOwner interface {
	ResetOperatorDailyBuys(context.Context, appi5.AdminOperator, identity.PlayerID, string, operation.Context) error
}

// CampaignDailyResetOwner clears the player's current-day campaign wins,
// Super resets and trial wins.
type CampaignDailyResetOwner interface {
	ResetOperatorCampaignDaily(context.Context, appi5.AdminOperator, identity.PlayerID, string, operation.Context) error
}

// OccultTicketsResetOwner refills the player's Occult tickets to the cap.
type OccultTicketsResetOwner interface {
	ResetOperatorOccultTickets(context.Context, appi5.AdminOperator, identity.PlayerID, string, operation.Context) error
}

// SkillPointsResetOwner sets the player's skill points to the privilege cap.
type SkillPointsResetOwner interface {
	ResetOperatorSkillPoints(context.Context, appi5.AdminOperator, identity.PlayerID, string, operation.Context) error
}

// ResetCommands applies player.reset_counters on the operator bus.
type ResetCommands struct {
	Store     BulkStore
	Directory playerdirectory.OperatorRecipients
}

func (commands ResetCommands) Handlers() map[string]operator.Handler {
	return map[string]operator.Handler{CommandResetCounters: commands.resetHandler}
}

func (commands ResetCommands) resetHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	var payload resetCountersPayload
	if err := decodePayload(command.Payload, &payload); err != nil {
		return nil, operator.Refuse(operator.CodePayloadInvalid, err.Error(), nil)
	}
	if _, err := validateResetCounters(payload.Counters); err != nil {
		return nil, err
	}
	selector, recipients, err := resolveTarget(ctx, scope.Tx, commands.Directory, payload.Target)
	if err != nil {
		return nil, err
	}
	if len(recipients) == 0 {
		return nil, operator.Refuse(CodeGrantTarget, "the target matches no players", nil)
	}
	if commands.Store == nil {
		return nil, operator.ErrUnavailable
	}
	target := BulkTarget{
		SemanticKey:     command.Envelope.SemanticKey,
		ModuleCommand:   command.ModuleCommand,
		Selector:        selector,
		PlayerIDs:       recipients,
		PlayerCount:     len(recipients),
		PlayerIDsSHA256: sha256IDs(recipients),
		Payload:         append([]byte(nil), command.Payload...),
		Principal:       command.Envelope.Principal,
		Reason:          command.Envelope.Reason,
		State:           StatePending,
		CreatedAt:       scope.Operation.StartedAt.UTC(),
		UpdatedAt:       scope.Operation.StartedAt.UTC(),
	}
	if err := commands.Store.InsertBulkTx(ctx, scope.Tx, target); err != nil {
		return nil, err
	}
	return GrantResult{Bulk: true, SemanticKey: target.SemanticKey, PlayerCount: target.PlayerCount, State: StatePending}, nil
}

// validateResetCounters refuses an empty, duplicated, unknown or not-yet
// available name and answers the accepted names in the R1 table order.
func validateResetCounters(names []string) ([]string, error) {
	if len(names) == 0 {
		return nil, operator.Refuse(CodeResetCounters, "counters must list at least one name", nil)
	}
	seen := make(map[string]struct{}, len(names))
	requested := make(map[string]struct{}, len(names))
	for _, name := range names {
		if _, duplicate := seen[name]; duplicate {
			return nil, operator.Refuse(CodeResetCounters, "a counter name appears twice", map[string]string{"counter": name})
		}
		seen[name] = struct{}{}
		if _, known := resetCounterAvailable[name]; !known {
			if isKnownResetCounter(name) {
				return nil, operator.Refuse(CodeResetCounters, "not available yet", map[string]string{"counter": name})
			}
			return nil, operator.Refuse(CodeResetCounters, "unknown counter name", map[string]string{"counter": name})
		}
		requested[name] = struct{}{}
	}
	out := make([]string, 0, len(requested))
	for _, name := range resetCounterOrder {
		if _, ok := requested[name]; ok {
			out = append(out, name)
		}
	}
	return out, nil
}

func isKnownResetCounter(name string) bool {
	return slices.Contains(resetCounterOrder, name)
}
