package socialrecallstore

import (
	"context"
	gen "gxb.local/backend/v2/internal/application/generation"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/presencestore"
	"gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/socialrecall"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/domain/privilege"
	domainrecall "gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type ProgressionReader interface {
	ReadProgressionTx(context.Context, tx.Queryer, identity.PlayerID) (player.Progression, error)
}

type CosmeticPrivilegeReader interface {
	ReadCosmeticPrivilegeTx(context.Context, tx.Queryer, identity.PlayerID, string, time.Time) (privilege.Snapshot, error)
}

type RelationReader interface {
	CandidateStatesTx(context.Context, tx.Tx, identity.PlayerID, []identity.PlayerID) ([]socialrelation.CandidateState, error)
}

// TargetReader composes the existing typed owner ports. Every call receives the
// caller's one snapshot queryer; presence is built on that same queryer so it
// cannot fall back to the pool.
type TargetReader struct {
	Activity    bootstrap.PlayerActivityReader
	Progression ProgressionReader
	Roster      characterasset.RosterMetricReader
	Privilege   CosmeticPrivilegeReader
	Relations   RelationReader
}

var _ socialrecall.TargetReader = TargetReader{}

func (reader TargetReader) ReadRecallTargetTx(ctx context.Context, scope tx.Scope, caller, target identity.PlayerID, revision string, at time.Time) (socialrecall.TargetSnapshot, error) {
	var out socialrecall.TargetSnapshot
	if !reader.validRequest(scope, caller, target, revision, at) {
		return out, socialrecall.ErrStartFacts
	}
	at = at.UTC()
	baseline, err := reader.currentFactsTx(ctx, scope, target, revision, at)
	if err != nil {
		return out, err
	}

	states, err := reader.Relations.CandidateStatesTx(ctx, scope.Tx, caller, []identity.PlayerID{target})
	if err != nil {
		return out, err
	}
	if len(states) != 1 || states[0].PlayerID != target {
		return out, socialrecall.ErrStartFacts
	}

	presence, err := (presencestore.Store{Queryer: scope.Tx}).ReadManyAt(ctx, []identity.PlayerID{target}, at)
	if err != nil {
		return out, err
	}
	observation, exists := presence[target]
	if !exists || observation.Validate() != nil || observation.PlayerID != target || futureTime(observation.LastSeenAt, at) || futureTime(observation.LatestConnectedAt, at) {
		return out, socialrecall.ErrStartFacts
	}

	out = socialrecall.TargetSnapshot{
		PlayerID:   target,
		Revision:   revision,
		ObservedAt: at,
		IsFriend:   states[0].Friend && !states[0].Blocked,
		Online:     observation.IsOnline,
		Baseline:   baseline,
	}
	activity, known, err := reader.Activity.ReadPlayerActivityTx(ctx, scope.Tx, target, at)
	if err != nil {
		return socialrecall.TargetSnapshot{}, err
	}
	if known {
		if activity.Validate() != nil || activity.PlayerID != target || activity.LogicalServerID != logicalserver.PlayerRegion(target) || !activity.ObservedAt.Equal(at) {
			return socialrecall.TargetSnapshot{}, socialrecall.ErrStartFacts
		}
		out.OfflineSince = activity.LatestActivityAt
		if observation.LastSeenAt != nil && observation.LastSeenAt.After(out.OfflineSince) {
			out.OfflineSince = observation.LastSeenAt.UTC()
		}
	}
	if known {
		expiredAt, err := (presencestore.Store{}).LatestExpiredLeaseAt(ctx, scope.Tx, target, at)
		if err != nil {
			return socialrecall.TargetSnapshot{}, err
		}
		// Lease expiry is a conservative inactivity bound until presence settlement.
		if expiredAt != nil && expiredAt.After(out.OfflineSince) {
			out.OfflineSince = expiredAt.UTC()
		}
	}

	if out.Baseline.Validate() != nil {
		return socialrecall.TargetSnapshot{}, socialrecall.ErrStartFacts
	}
	return out, nil
}

func (reader TargetReader) validRequest(scope tx.Scope, caller, target identity.PlayerID, revision string, at time.Time) bool {
	if reader.Activity == nil || reader.Progression == nil || reader.Roster == nil || reader.Privilege == nil || reader.Relations == nil {
		return false
	}
	if scope.Tx == nil || scope.Options.Isolation != tx.Serializable || scope.Options.ReadOnly || at.IsZero() {
		return false
	}
	if !caller.Valid() || !target.Valid() || caller == target {
		return false
	}
	if logicalserver.PlayerRegion(caller) != logicalserver.PlayerRegion(target) {
		return false
	}
	if characterasset.ValidateExactRevisionID(revision) != nil {
		return false
	}
	contentPin, contentBound := scope.Operation.Policies.Get("content")
	rosterPin, rosterBound := scope.Operation.Policies.Get("roster-metrics")
	return contentBound && contentPin == revision && rosterBound && rosterPin == characterasset.RosterMetricPolicy
}

func futureTime(value *time.Time, at time.Time) bool {
	return value != nil && value.After(at)
}

func (reader TargetReader) ReadRecallCurrentTx(ctx context.Context, scope tx.Scope, target identity.PlayerID, revision string, at time.Time) (socialrecall.TargetSnapshot, error) {
	baseline, err := reader.currentFactsTx(ctx, scope, target, revision, at)
	if err != nil {
		return socialrecall.TargetSnapshot{}, err
	}
	return socialrecall.TargetSnapshot{PlayerID: target, Revision: revision, ObservedAt: at, Baseline: baseline}, nil
}
func (reader TargetReader) currentFactsTx(ctx context.Context, scope tx.Scope, target identity.PlayerID, revision string, at time.Time) (domainrecall.Baseline, error) {
	if reader.Progression == nil || reader.Roster == nil || reader.Privilege == nil || scope.Tx == nil || (scope.Options.Isolation != tx.Serializable && scope.Options.Isolation != tx.RepeatableRead) || !target.Valid() || at.IsZero() || characterasset.ValidateExactRevisionID(revision) != nil {
		return domainrecall.Baseline{}, socialrecall.ErrStartFacts
	}
	contentPin, contentBound := scope.Operation.Policies.Get("content")
	rosterPin, rosterBound := scope.Operation.Policies.Get("roster-metrics")
	if !contentBound || contentPin != revision || !rosterBound || rosterPin != characterasset.RosterMetricPolicy {
		return domainrecall.Baseline{}, socialrecall.ErrStartFacts
	}
	coherentScope, err := characterasset.NewCoherentReadScope(scope, revision, at)
	if err != nil {
		return domainrecall.Baseline{}, socialrecall.ErrStartFacts
	}

	progression, err := reader.Progression.ReadProgressionTx(ctx, scope.Tx, target)
	if err != nil {
		return domainrecall.Baseline{}, err
	}
	if progression.PlayerID != target || progression.Validate() != nil || progression.UpdatedAt.After(gen.EffectiveObservation(at, progression.UpdatedAt)) {
		return domainrecall.Baseline{}, socialrecall.ErrStartFacts
	}

	population, err := reader.Roster.ReadRosterMetricsTx(ctx, coherentScope, target, "Hero")
	if err != nil {
		return domainrecall.Baseline{}, err
	}
	if population.PlayerID != target || population.Family != "Hero" || population.Revision != revision || !population.ObservedAt.Equal(at) || population.RootVersion <= 0 {
		return domainrecall.Baseline{}, socialrecall.ErrStartFacts
	}
	summary, err := population.Summary()
	if err != nil {
		return domainrecall.Baseline{}, socialrecall.ErrStartFacts
	}

	privilegeSnapshot, err := reader.Privilege.ReadCosmeticPrivilegeTx(ctx, scope.Tx, target, revision, at)
	if err != nil {
		return domainrecall.Baseline{}, err
	}
	if privilegeSnapshot.Validate(target, revision, at) != nil || privilegeSnapshot.State.LogicalServerID != logicalserver.PlayerRegion(target) {
		return domainrecall.Baseline{}, socialrecall.ErrStartFacts
	}

	return domainrecall.Baseline{AcademyLevel: progression.Level, OwnedHeroCount: summary.OwnedCount, ChargeTotal: privilegeSnapshot.State.Charge}, nil
}
