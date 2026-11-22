package events

import (
	"context"
	"math"
	"strconv"
	"strings"

	"gxb.local/backend/v2/internal/application/activitydirectory"
	"gxb.local/backend/v2/internal/domain/activity"
	"gxb.local/backend/v2/internal/domain/events"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ServedActivityIDs is the static list of activities the events owner can
// project: 1008 (normal drops double) and 1071 (rookie level gift, EA-2/EA-5).
var ServedActivityIDs = []int64{1008, 1071}

// permanentEndTime is the int32-safe far future a permanent occurrence reports
// so neither stock drop rule fires (EA-1 amendment 3).
const permanentEndTime int64 = math.MaxInt32

// ActivityProvider projects one events activity into the I6B directory. It is
// present only while the server has a RUNNING or CLAIM_WINDOW occurrence, and
// reads the occurrence and the player's claims through the caller's snapshot.
type ActivityProvider struct {
	Store   Store
	TableID int64
	Queryer tx.Queryer
}

// ActivityRegistrations is one registration per served activity id. No other
// owner registers 1008 or 1071 (I6B registry, registry revision 40).
func ActivityRegistrations(store Store, queryer tx.Queryer) []activitydirectory.Registration {
	out := make([]activitydirectory.Registration, 0, len(ServedActivityIDs))
	for _, activityID := range ServedActivityIDs {
		id := strconv.FormatInt(activityID, 10)
		out = append(out, activitydirectory.Registration{
			Name: "events-" + id, TableID: activityID,
			RuntimeCapability: "activity.events." + id,
			Provider:          ActivityProvider{Store: store, TableID: activityID, Queryer: queryer},
		})
	}
	return out
}

func (p ActivityProvider) Project(c context.Context, pc activitydirectory.ProjectionContext) (activity.Projection, bool, error) {
	queryer := p.Queryer
	if carried, ok := activitydirectory.QueryerValue(c); ok {
		if scoped, isQueryer := carried.(tx.Queryer); isQueryer {
			queryer = scoped
		}
	}
	if p.Store == nil || queryer == nil {
		return activity.Projection{}, false, ErrUnavailable
	}
	activityID := p.activityID()
	occurrence, err := p.Store.ActiveOccurrenceTx(c, queryer, int64(pc.Actor.LogicalServerID), activityID, pc.DecisionAt)
	if err != nil {
		return activity.Projection{}, false, err
	}
	if occurrence == nil {
		return activity.Projection{}, false, nil
	}
	definition, err := p.Store.DefinitionTx(c, queryer, occurrence.ActivityID, occurrence.DefinitionRevision)
	if err != nil {
		return activity.Projection{}, false, err
	}
	if definition == nil {
		return activity.Projection{}, false, ErrUnavailable
	}
	start := occurrence.StartsAt.Unix()
	end := permanentEndTime
	if occurrence.EndsAt != nil {
		end = occurrence.EndsAt.Unix()
	}
	details := map[string]any{}
	if activityID == 1071 {
		claims, err := p.Store.ClaimsForPlayerTx(c, queryer, int64(pc.Actor.PlayerID), occurrence.ID, MaxClaimsLimit)
		if err != nil {
			return activity.Projection{}, false, err
		}
		details["is_awards"] = awardFlags(definition.Body, claims)
		details["start_time"] = start
		details["end_time"] = end
	}
	return activity.Projection{TableID: activityID, IsOpen: 1, StartTime: start, EndTime: end, Days: definition.Body.DefaultDays, Details: details}, true, nil
}

// activityID is the registration's table id; the provider is constructed per
// registration, so the store lookup above is the only mutable input.
func (p ActivityProvider) activityID() int64 { return p.TableID }

// awardFlags builds the pipe string the 1071 window indexes by tier row id:
// "0" is claimable, "1" claimed (Activity1071.lua:138,153-158). Positions come
// from the definition's tier ids, so a sparse or high id keeps its slot.
func awardFlags(definition events.Definition, claims []Claim) string {
	tierIDs := make(map[int64]struct{}, len(definition.Tiers))
	maximum := int64(0)
	for _, tier := range definition.Tiers {
		tierIDs[tier.ID] = struct{}{}
		if tier.ID > maximum {
			maximum = tier.ID
		}
	}
	if maximum == 0 {
		maximum = 1
	}
	claimed := make(map[int64]struct{}, len(claims))
	for _, claim := range claims {
		if _, isTier := tierIDs[claim.Tier]; isTier {
			claimed[claim.Tier] = struct{}{}
		}
	}
	flags := make([]string, maximum)
	for id := int64(1); id <= maximum; id++ {
		flags[id-1] = "0"
		if _, isClaimed := claimed[id]; isClaimed {
			flags[id-1] = "1"
		}
	}
	return strings.Join(flags, "|")
}

// compile-time guard that the provider satisfies the directory interface.
var _ activitydirectory.Provider = ActivityProvider{}
