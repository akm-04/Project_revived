package mentor

import (
	"context"
	"encoding/json"
	"sort"
	"strconv"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	domain "gxb.local/backend/v2/internal/domain/mentor"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// MentorPolicyVersion identifies the reconstruction rules for the coarse
// three-level minimum gap; the other numbers are client misc facts.
const MentorPolicyVersion = domain.MinimumLevelGapPolicy

// FindingScanLimit and FindingResultLimit bound the find list. The client misc
// facts give 20 results and a 100 range; PRIVATE_POLICY D508 uses the range as
// the per-request candidate scan because the stock server's paging is UNKNOWN.
const (
	FindingScanLimit   = 100
	FindingResultLimit = 20
	// FindingRecentPool is twice the result count: PRIVATE_POLICY D508 shuffles
	// the most recently active candidates and returns the first 20.
	FindingRecentPool = FindingResultLimit * 2
)

const dayLayout = "2006-01-02"

type Service struct {
	Timed       gen.TimedRunner
	Players     playerroot.TxLocker
	Store       Store
	Directory   DirectoryReader
	Cards       CardReader
	Friendships FriendshipEnsurer
	Backgrounds BackgroundReader
	Grants      GrantOwner
	Content     ContentReader
	Receipts    receipt.Store
}

const (
	ReceiptDomain         = "mentor"
	ReceiptSchema         = "gxb.mentor.command.v1"
	ReceiptOperationClass = "I9_10F_MENTOR"
)

func DefaultProfile() tx.Profile {
	return tx.Profile{Name: "I9_10F_MENTOR", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 12 * time.Second}
}

func (service Service) validForMutation() bool {
	return service.Timed.Runner.DB != nil && service.Timed.Binder.Time != nil && service.Players != nil && service.Store != nil && service.Directory != nil && service.Cards != nil && service.Friendships != nil && service.Content != nil && service.Receipts != nil
}

func (service Service) validForRead() bool {
	return service.Timed.Runner.DB != nil && service.Timed.Binder.Time != nil && service.Store != nil && service.Directory != nil && service.Cards != nil && service.Content != nil
}

func (service Service) catalog() (Catalog, error) {
	if service.Content == nil {
		return Catalog{}, ErrUnavailable
	}
	catalog, err := service.Content.MentorCatalog()
	if err != nil {
		return Catalog{}, ErrUnavailable
	}
	return catalog, nil
}

func rulesFromCatalog(catalog Catalog) domain.Rules {
	minimumLevel := catalog.Rules.TeacherMinLevel
	if catalog.Rules.TeacherLevel > minimumLevel {
		minimumLevel = catalog.Rules.TeacherLevel
	}
	return domain.Rules{
		MentorMinimumLevel:  minimumLevel,
		StudentMinimumLevel: catalog.Rules.PlayerOpenLevel,
		StudentLevelLimit:   catalog.Rules.StudentLevelLimit,
		LevelGap:            catalog.Rules.LevelRelation,
		ApplicationTTL:      time.Duration(catalog.Rules.RelationSendBrokenSeconds) * time.Second,
		ApplicationDaily:    catalog.Rules.RelationSendTimes,
		BreakCooldown:       time.Duration(catalog.Rules.RelationBrokenSeconds) * time.Second,
		MinimumRelationAge:  time.Duration(catalog.Rules.TerminateTimeLimitSeconds) * time.Second,
		IntimacyDaily:       catalog.Rules.GiftIntimacy,
		IntimacyCap:         catalog.Rules.RelationMax,
		FunctionOpenLevel:   catalog.Rules.PlayerOpenLevel,
		ServerMentorLevel:   catalog.Rules.TeacherMinLevel,
		LevelGapPolicy:      domain.MinimumLevelGapPolicy,
	}
}

func missionsFromCatalog(catalog Catalog) []domain.Mission {
	out := make([]domain.Mission, 0, len(catalog.Missions))
	for _, mission := range catalog.Missions {
		out = append(out, domain.Mission{ID: mission.ID, GiftID: mission.GiftID, Type: mission.Type, Category: mission.Category, Condition: mission.Condition, Level: mission.Level, IsHide: mission.IsHide})
	}
	return out
}

func validActor(actor identity.ActorContext, server identity.LogicalServerID) bool {
	return actor.PlayerID.Valid() && actor.LogicalServerID.Valid() && logicalserver.PlayerRegion(actor.PlayerID) == actor.LogicalServerID && actor.AccountUID.Valid() && !actor.AccountID.UUID().IsZero() && !actor.SessionID.UUID().IsZero() && !actor.ContextID.UUID().IsZero() && actor.ContextGeneration >= 1 && actor.SessionLivenessVersion >= 1 && actor.ContextLivenessVersion >= 1
}

func (service Service) run(ctx context.Context, actor identity.ActorContext, op operation.Context, write bool, body func(context.Context, tx.Tx, time.Time) error) error {
	if !validActor(actor, actor.LogicalServerID) || op.ID.IsZero() || op.StartedAt.IsZero() {
		return ErrInvalid
	}
	options := tx.Options{Isolation: tx.Serializable, ReadOnly: !write}
	if !write {
		options.Isolation = tx.RepeatableRead
	}
	_, outcome, err := service.Timed.Run(ctx, op, DefaultProfile(), options, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(_ context.Context, scope gen.TimedScope) error {
		return body(ctx, scope.Tx, scope.Operation.DecisionAt())
	})
	if err != nil {
		return err
	}
	if outcome.Outcome != tx.DefiniteCommit {
		return domain.ErrRelationshipConflict
	}
	return nil
}

// bindContentRevision pins the active immutable revision on the operation the
// I5 grant settles under; a fresh HTTP operation carries no content ref.
func bindContentRevision(op operation.Context, revision string) (operation.Context, error) {
	if current, ok := op.Policies.Get("content"); ok {
		if current != revision {
			return operation.Context{}, ErrUnavailable
		}
		return op, nil
	}
	refs := append(op.Policies.Refs(), policy.Ref{Name: "content", Version: revision})
	set, err := policy.NewSet(refs...)
	if err != nil {
		return operation.Context{}, err
	}
	op.Policies = set
	return op, nil
}

func commandReceiptID(actor identity.ActorContext, command string, op operation.Context) receipt.Identity {
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: ReceiptDomain, Operation: command, SemanticKey: op.ID.String()}
}

// runReceipted replays an exact operation from its stored reply, so a retry
// after an unknown commit cannot apply the command twice.
func (service Service) runReceipted(ctx context.Context, actor identity.ActorContext, op operation.Context, command string, request any, body *map[string]any, apply func(context.Context, tx.Tx, time.Time) error) error {
	fingerprint, err := receipt.FingerprintRequest(request)
	if err != nil {
		return err
	}
	identity := commandReceiptID(actor, command, op)
	return service.run(ctx, actor, op, true, func(ctx context.Context, t tx.Tx, at time.Time) error {
		prior, found, err := service.Receipts.FindTx(ctx, t, identity)
		if err != nil {
			return err
		}
		if found {
			if prior.RequestFingerprint != fingerprint {
				return &receipt.ConflictError{Identity: identity}
			}
			return json.Unmarshal(prior.ResultPayload, body)
		}
		if err := apply(ctx, t, at); err != nil {
			return err
		}
		raw, err := json.Marshal(*body)
		if err != nil {
			return err
		}
		record, err := receipt.New(op, identity, ReceiptOperationClass, ReceiptSchema, raw, fingerprint)
		if err != nil {
			return err
		}
		record.PolicyVersion = MentorPolicyVersion
		record.RecordedAt = at
		put, err := service.Receipts.PutTx(ctx, t, record)
		if err != nil {
			return err
		}
		if !put.Inserted {
			return &receipt.ConflictError{Identity: identity}
		}
		return nil
	})
}

func lockPlayerRoots(ctx context.Context, locker playerroot.TxLocker, t tx.Tx, server identity.LogicalServerID, players ...identity.PlayerID) error {
	if locker == nil || t == nil {
		return ErrInvalid
	}
	ids := make([]identity.PlayerID, 0, len(players))
	seen := map[identity.PlayerID]bool{}
	for _, player := range players {
		if !player.Valid() || logicalserver.PlayerRegion(player) != server {
			return ErrInvalid
		}
		if seen[player] {
			continue
		}
		seen[player] = true
		ids = append(ids, player)
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	rows, err := locker.LockPlayerRootsTx(ctx, t, server, ids)
	if err != nil {
		return err
	}
	if len(rows) != len(ids) {
		return domain.ErrInvalid
	}
	for index, row := range rows {
		if row.PlayerID != ids[index] || row.LogicalServerID != server {
			return domain.ErrInvalid
		}
	}
	return nil
}

// dayKey is the daily counter boundary. PRIVATE_POLICY D508: UTC day, because
// the stock client sends no timezone and misc.lua has no reset rule.
func dayKey(at time.Time) string { return at.UTC().Format(dayLayout) }

func sameDay(stored time.Time, at time.Time) bool {
	return stored.UTC().Format(dayLayout) == dayKey(at)
}

func advance(version int64) int64 { return version + 1 }

func playerLevel(ctx context.Context, reader DirectoryReader, t tx.Tx, player identity.PlayerID) (int64, error) {
	profile, found, err := reader.ProfileTx(ctx, t, player)
	if err != nil {
		return 0, err
	}
	if !found || profile.PlayerID != player || profile.Validate() != nil {
		return 0, domain.ErrInvalid
	}
	return profile.Level, nil
}

func refusal(code int64) error { return &Refusal{Code: code} }
