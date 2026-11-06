package socialrecall

import (
	"context"
	"errors"
	"slices"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	domain "gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrAwardFacts = errors.New("social recall: unqualified award facts")
var ErrAwardRefused = errors.New("social recall: award not eligible or already claimed")

type AwardSpec struct {
	ID, GiftID, Threshold int64
	Category              domain.Category
	Lines                 []grant.Line
}

func (spec AwardSpec) Validate() error {
	if spec.ID <= 0 || spec.GiftID <= 0 || spec.Threshold <= 0 || len(spec.Lines) == 0 {
		return ErrAwardFacts
	}
	if _, err := (domain.CompletionSummary{}).Achieved(spec.Category); err != nil {
		return ErrAwardFacts
	}
	for _, line := range spec.Lines {
		if line.Validate() != nil || (line.Kind != grant.ScalarCurrency && line.Kind != grant.StackItem) {
			return ErrAwardFacts
		}
	}
	return nil
}

type AwardCatalog map[int64]AwardSpec

func (catalog AwardCatalog) Validate() error {
	if len(catalog) == 0 {
		return ErrAwardFacts
	}
	for identifier, spec := range catalog {
		if identifier != spec.ID || spec.Validate() != nil {
			return ErrAwardFacts
		}
	}
	return nil
}

type AwardRecord struct {
	Player                            identity.PlayerID
	Server                            identity.LogicalServerID
	AwardID, GiftID                   int64
	OperationID                       ids.UUID
	Revision, PolicyVersion, GrantKey string
	EarnedAt                          time.Time
}

func awardSource(player identity.PlayerID, identifier int64) grant.SourceIdentity {
	return grant.SourceIdentity{Domain: "socialrecall", Operation: "milestone_award", BusinessKey: strconv.FormatInt(int64(player), 10) + ":" + strconv.FormatInt(identifier, 10), PolicyVersion: RecallPolicyVersion}
}
func (record AwardRecord) Validate() error {
	if !record.Player.Valid() || !record.Server.Valid() || logicalserver.PlayerRegion(record.Player) != record.Server || record.AwardID <= 0 || record.GiftID <= 0 || record.OperationID.IsZero() || record.PolicyVersion != RecallPolicyVersion || record.EarnedAt.IsZero() || record.EarnedAt.Location() != time.UTC || characterasset.ValidateExactRevisionID(record.Revision) != nil || record.GrantKey != awardSource(record.Player, record.AwardID).SemanticKey() {
		return ErrAwardFacts
	}
	return nil
}

type AwardOwner interface {
	CompletedTasksTx(context.Context, tx.Queryer, identity.PlayerID, identity.LogicalServerID, time.Time) ([]TaskRecord, error)
	AwardedIDsTx(context.Context, tx.Queryer, identity.PlayerID, identity.LogicalServerID) ([]int64, error)
	InsertAwardTx(context.Context, tx.Tx, AwardRecord) error
}
type AwardContent interface {
	SocialRecallAwardCatalogTx(context.Context, tx.Queryer, string) (AwardCatalog, error)
}
type CurrentFactsReader interface {
	ReadRecallCurrentTx(context.Context, tx.Scope, identity.PlayerID, string, time.Time) (TargetSnapshot, error)
}
type AwardGranter interface {
	SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error)
}
type AwardResult struct {
	AwardID, GiftID int64
	Revision        string
	Awarded         []int64
	Grant           i5.GrantResult
}
type Awarder struct {
	Players playerroot.TxLocker
	Owner   AwardOwner
	Content AwardContent
	Current CurrentFactsReader
	Grants  AwardGranter
}

func (awarder Awarder) AwardTx(ctx context.Context, scope tx.Scope, actor identity.ActorContext, awardID int64, revision string, at time.Time) (AwardResult, error) {
	var out AwardResult
	if awarder.Players == nil || awarder.Owner == nil || awarder.Content == nil || awarder.Current == nil || awarder.Grants == nil || scope.Tx == nil || scope.Options.Isolation != tx.Serializable || scope.Options.ReadOnly || scope.Operation.ID.IsZero() || scope.Operation.StartedAt.IsZero() || at.IsZero() || awardID <= 0 || !actor.PlayerID.Valid() || !actor.LogicalServerID.Valid() || logicalserver.PlayerRegion(actor.PlayerID) != actor.LogicalServerID || actor.AccountUID == "" || actor.ContextID.UUID().IsZero() || characterasset.ValidateExactRevisionID(revision) != nil {
		return out, ErrAwardFacts
	}
	contentPin, contentBound := scope.Operation.Policies.Get("content")
	recallPin, recallBound := scope.Operation.Policies.Get("socialrecall")
	rosterPin, rosterBound := scope.Operation.Policies.Get("roster-metrics")
	if !contentBound || contentPin != revision || !recallBound || recallPin != RecallPolicyVersion || !rosterBound || rosterPin != characterasset.RosterMetricPolicy {
		return out, ErrAwardFacts
	}
	roots, err := awarder.Players.LockPlayerRootsTx(ctx, scope.Tx, actor.LogicalServerID, []identity.PlayerID{actor.PlayerID})
	if err != nil {
		return out, err
	}
	if len(roots) != 1 || roots[0].Validate() != nil || roots[0].PlayerID != actor.PlayerID || roots[0].LogicalServerID != actor.LogicalServerID {
		return out, ErrAwardFacts
	}
	catalog, err := awarder.Content.SocialRecallAwardCatalogTx(ctx, scope.Tx, revision)
	if err != nil {
		return out, err
	}
	if catalog.Validate() != nil {
		return out, ErrAwardFacts
	}
	spec, found := catalog[awardID]
	if !found {
		return out, ErrAwardRefused
	}
	claimed, err := awarder.Owner.AwardedIDsTx(ctx, scope.Tx, actor.PlayerID, actor.LogicalServerID)
	if err != nil {
		return out, err
	}
	previous := int64(0)
	for _, identifier := range claimed {
		if _, known := catalog[identifier]; !known || identifier <= previous {
			return out, ErrAwardFacts
		}
		if identifier == awardID {
			return out, ErrAwardRefused
		}
		previous = identifier
	}
	records, err := awarder.Owner.CompletedTasksTx(ctx, scope.Tx, actor.PlayerID, actor.LogicalServerID, at)
	if err != nil {
		return out, err
	}
	completed := make([]domain.CompletedTarget, 0, len(records))
	for _, record := range records {
		task := record.Task
		if task.Validate() != nil || task.Status != domain.StatusCompleted || task.Caller != actor.PlayerID || task.LogicalServerID != actor.LogicalServerID || task.CompletedAt.After(at) || record.UpdatedAt.After(at) || record.StateVersion < 1 || record.PolicyVersion != RecallPolicyVersion || characterasset.ValidateExactRevisionID(record.ContentRevision) != nil {
			return out, ErrAwardFacts
		}
		current, err := awarder.Current.ReadRecallCurrentTx(ctx, scope, task.Target, revision, at)
		if err != nil {
			return out, err
		}
		if current.PlayerID != task.Target || current.Revision != revision || !current.ObservedAt.Equal(at) || current.Baseline.Validate() != nil {
			return out, ErrAwardFacts
		}
		completed = append(completed, domain.CompletedTarget{Task: task, Current: current.Baseline})
	}
	summary, err := domain.SummarizeCompleted(actor.PlayerID, actor.LogicalServerID, completed)
	if err != nil {
		return out, err
	}
	achieved, err := summary.Achieved(spec.Category)
	if err != nil {
		return out, err
	}
	if achieved < spec.Threshold {
		return out, ErrAwardRefused
	}
	plan := grant.Plan{PlayerID: actor.PlayerID, Source: awardSource(actor.PlayerID, awardID), Lines: spec.Lines}
	if plan.Validate() != nil {
		return out, ErrAwardFacts
	}
	marker := AwardRecord{Player: actor.PlayerID, Server: actor.LogicalServerID, AwardID: awardID, GiftID: spec.GiftID, OperationID: scope.Operation.ID, Revision: revision, PolicyVersion: RecallPolicyVersion, GrantKey: plan.Source.SemanticKey(), EarnedAt: at}
	if err := awarder.Owner.InsertAwardTx(ctx, scope.Tx, marker); err != nil {
		return out, err
	}
	settled, err := awarder.Grants.SettleGrantTx(ctx, scope.Tx, actor, plan, scope.Operation, i5.GrantTxOptions{AllowOverflowMail: true})
	if err != nil {
		return out, err
	}
	awarded, err := awarder.Owner.AwardedIDsTx(ctx, scope.Tx, actor.PlayerID, actor.LogicalServerID)
	if err != nil {
		return out, err
	}
	expected := append(append([]int64(nil), claimed...), awardID)
	slices.Sort(expected)
	if !slices.Equal(awarded, expected) || settled.ReceiptID == "" {
		return out, ErrAwardFacts
	}

	return AwardResult{AwardID: awardID, GiftID: spec.GiftID, Revision: revision, Awarded: awarded, Grant: settled}, nil
}
