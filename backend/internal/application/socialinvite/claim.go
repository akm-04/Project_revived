package socialinvite

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type ClaimGranter interface {
	SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error)
}

// ClaimService is the MID 385 boundary: once-only invitation mission outcomes.
type ClaimService struct {
	Timed         generation.TimedRunner
	Fence         ActorFence
	Players       playerroot.TxLocker
	Content       Content
	Owner         Owner
	Reader        InviteReader
	Grants        ClaimGranter
	Settings      Settings
	Receipts      receipt.Store
	ReceiptReader receipt.Reader
}

type claimTerminal struct {
	OperationID    string          `json:"operation_id"`
	StartedAt      time.Time       `json:"started_at"`
	EntropySeed    [32]byte        `json:"entropy_seed"`
	MissionID      int64           `json:"mission_id"`
	Diamond        int64           `json:"diamond"`
	Revision       string          `json:"content_revision"`
	GrantKey       string          `json:"grant_key"`
	GrantReceiptID string          `json:"grant_receipt_id"`
	Body           json.RawMessage `json:"body"`
}

func claimProfile() tx.Profile {
	return tx.Profile{Name: "social-invite-claim", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 45 * time.Second}
}

func claimSource(player identity.PlayerID, mission int64) grant.SourceIdentity {
	return grant.SourceIdentity{Domain: "socialinvite", Operation: "mission_claim", BusinessKey: strconv.FormatInt(int64(player), 10) + ":" + strconv.FormatInt(mission, 10), PolicyVersion: PolicyVersion}
}

func (service ClaimService) Claim(ctx context.Context, actor identity.ActorContext, missionID int64, current operation.Context) (map[string]any, error) {
	if service.Timed.Runner.DB == nil || service.Timed.Binder.Time == nil || service.Fence == nil || service.Players == nil || service.Content == nil || service.Owner == nil || service.Reader == nil || service.Grants == nil || service.Settings == nil || service.Receipts == nil || service.ReceiptReader == nil {
		return nil, ErrUnavailable
	}
	if !actor.PlayerID.Valid() || !actor.LogicalServerID.Valid() || logicalserver.PlayerRegion(actor.PlayerID) != actor.LogicalServerID || actor.AccountUID == "" || actor.ContextID.UUID().IsZero() || current.ID.IsZero() || current.StartedAt.IsZero() || missionID <= 0 {
		return nil, ErrFacts
	}
	identityValue := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: "socialinvite", Operation: "claim", SemanticKey: current.ID.String()}
	fingerprint, err := receipt.FingerprintRequest(struct {
		Player  identity.PlayerID
		Server  identity.LogicalServerID
		Mission int64
		Policy  string
	}{actor.PlayerID, actor.LogicalServerID, missionID, PolicyVersion})
	if err != nil {
		return nil, err
	}
	recovery := claimRecovery{reader: service.ReceiptReader, identity: identityValue, fingerprint: fingerprint, actor: actor, missionID: missionID, current: current}
	var output map[string]any
	_, result, err := service.Timed.Run(ctx, current, claimProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 8, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 160 * time.Millisecond}, recovery, func(ctx context.Context, scope generation.TimedScope) error {
		at := scope.Operation.DecisionAt()
		if err := service.Fence.FenceActorTx(ctx, scope.Tx, actor, at); err != nil {
			return err
		}
		roots, err := service.Players.LockPlayerRootsTx(ctx, scope.Tx, actor.LogicalServerID, []identity.PlayerID{actor.PlayerID})
		if err != nil {
			return err
		}
		if len(roots) != 1 || roots[0].Validate() != nil || roots[0].PlayerID != actor.PlayerID || roots[0].LogicalServerID != actor.LogicalServerID {
			return ErrFacts
		}
		stored, found, err := service.Receipts.FindTx(ctx, scope.Tx, identityValue)
		if err != nil {
			return err
		}
		if found {
			output, err = recovery.decode(stored)
			return err
		}
		tuning, err := service.Settings.TuningTx(ctx, scope.Tx)
		if err != nil {
			return err
		}
		if invitationOff(tuning) {
			return ErrClaimRefused
		}
		revision, pinned := current.Policies.Get("content")
		if !pinned {
			revision, err = service.Content.ActiveRevision(ctx, scope.Tx)
			if err != nil {
				return err
			}
		}
		if characterasset.ValidateExactRevisionID(revision) != nil {
			return ErrProof
		}
		bound, err := BindInvitePolicies(scope.Operation.Operation(), revision)
		if err != nil {
			return err
		}
		catalog, err := service.Content.SocialInvitationMissionsTx(ctx, scope.Tx, revision)
		if err != nil {
			return err
		}
		mission, known := catalog.Find(missionID)
		if !known || mission.Validate() != nil {
			return ErrClaimRefused
		}
		snapshot, err := service.Reader.ReadInviteTx(ctx, tx.Scope{Tx: scope.Tx, Operation: bound, Attempt: scope.Attempt, Options: scope.Options}, actor, revision, at)
		if err != nil {
			return err
		}
		for _, claimed := range snapshot.Claimed {
			if claimed == missionID {
				return ErrClaimRefused
			}
		}
		projection, err := BuildProjection(snapshot, catalog)
		if err != nil {
			return err
		}
		if !claimable(projection, missionID) {
			return ErrClaimRefused
		}
		plan := grant.Plan{PlayerID: actor.PlayerID, Source: claimSource(actor.PlayerID, missionID), Lines: []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: mission.Diamond}}}
		if plan.Validate() != nil {
			return ErrFacts
		}
		record := ClaimRecord{Player: int64(actor.PlayerID), Mission: missionID, LogicalServerID: actor.LogicalServerID, OperationID: scope.Operation.Operation().ID, ContentRevision: revision, PolicyVersion: PolicyVersion, GrantKey: plan.Source.SemanticKey(), ClaimedAt: at}
		if err := service.Owner.InsertClaimTx(ctx, scope.Tx, record); err != nil {
			if errors.Is(err, ErrClaimRefused) {
				return ErrClaimRefused
			}
			return err
		}
		settled, err := service.Grants.SettleGrantTx(ctx, scope.Tx, actor, plan, bound, i5.GrantTxOptions{AllowOverflowMail: true})
		if err != nil {
			return err
		}
		if settled.ReceiptID == "" {
			return ErrProof
		}
		snapshot, err = service.Reader.ReadInviteTx(ctx, tx.Scope{Tx: scope.Tx, Operation: bound, Attempt: scope.Attempt, Options: scope.Options}, actor, revision, at)
		if err != nil {
			return err
		}
		projection, err = BuildProjection(snapshot, catalog)
		if err != nil {
			return err
		}
		body, err := json.Marshal(claimBody(projection, mission))
		if err != nil {
			return err
		}
		terminal := claimTerminal{OperationID: scope.Operation.Operation().ID.String(), StartedAt: scope.Operation.Operation().StartedAt, EntropySeed: scope.Operation.Operation().EntropySeed, MissionID: missionID, Diamond: mission.Diamond, Revision: revision, GrantKey: plan.Source.SemanticKey(), GrantReceiptID: settled.ReceiptID, Body: body}
		encoded, err := json.Marshal(terminal)
		if err != nil {
			return err
		}
		value, err := receipt.New(bound, identityValue, claimOperationClass, claimResultSchema, encoded, fingerprint)
		if err != nil {
			return err
		}
		value.PolicyVersion = PolicyVersion
		value.ActorAccountUID = string(actor.AccountUID)
		value.ContextID = actor.ContextID.UUID()
		output, err = recovery.decode(value)
		if err != nil {
			return err
		}
		inserted, err := service.Receipts.PutTx(ctx, scope.Tx, value)
		if err != nil {
			return err
		}
		if !inserted.Inserted {
			return &receipt.ConflictError{Identity: identityValue}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	if result.Reconciled {
		stored, valid := result.Evidence.(receipt.Receipt)
		if !valid {
			return nil, ErrProof
		}
		return recovery.decode(stored)
	}
	return output, nil
}

func claimable(projection Projection, missionID int64) bool {
	for _, mission := range projection.Missions {
		if mission.MissionID == missionID {
			return mission.CanAward
		}
	}
	return false
}

func claimBody(projection Projection, mission Mission) map[string]any {
	return map[string]any{
		"awards":       []any{map[string]any{"table_id": int64(-1), "item_num": mission.Diamond, "crystal": mission.Diamond}},
		"new_missions": projection.MissionList(),
		"new_infos":    projection.NewInfos(),
	}
}

type claimRecovery struct {
	reader      receipt.Reader
	identity    receipt.Identity
	fingerprint [32]byte
	actor       identity.ActorContext
	missionID   int64
	current     operation.Context
}

func (recovery claimRecovery) decode(stored receipt.Receipt) (map[string]any, error) {
	if stored.RequestFingerprint != recovery.fingerprint {
		return nil, &receipt.ConflictError{Identity: recovery.identity}
	}
	if stored.Validate() != nil || stored.Identity != recovery.identity || stored.OperationClass != claimOperationClass || stored.ResultSchema != claimResultSchema || stored.PolicyVersion != PolicyVersion || stored.ActorAccountUID != string(recovery.actor.AccountUID) || stored.ContextID != recovery.actor.ContextID.UUID() || stored.OperationStartedAt.UnixMicro() != recovery.current.StartedAt.UnixMicro() || stored.RetainUntil != nil {
		return nil, ErrProof
	}
	content, found := stored.OperationPolicyRefs.Get("content")
	if !found || characterasset.ValidateExactRevisionID(content) != nil {
		return nil, ErrProof
	}
	version, found := stored.OperationPolicyRefs.Get("socialinvite")
	if !found || version != PolicyVersion {
		return nil, ErrProof
	}
	var terminal claimTerminal
	decoder := json.NewDecoder(bytes.NewReader(stored.ResultPayload))
	decoder.DisallowUnknownFields()
	if decoder.Decode(&terminal) != nil {
		return nil, ErrProof
	}
	var extra any
	if decoder.Decode(&extra) != io.EOF {
		return nil, ErrProof
	}
	if terminal.OperationID != recovery.current.ID.String() || !terminal.StartedAt.Equal(recovery.current.StartedAt) || terminal.EntropySeed != recovery.current.EntropySeed || terminal.MissionID != recovery.missionID || terminal.Diamond <= 0 || terminal.GrantReceiptID == "" || terminal.Revision != content || terminal.GrantKey != claimSource(recovery.actor.PlayerID, terminal.MissionID).SemanticKey() {
		return nil, ErrProof
	}
	return decodeClaimBody(terminal.Body)
}

func decodeClaimBody(raw json.RawMessage) (map[string]any, error) {
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.UseNumber()
	var body map[string]any
	if decoder.Decode(&body) != nil {
		return nil, ErrProof
	}
	var extra any
	if decoder.Decode(&extra) != io.EOF || body == nil {
		return nil, ErrProof
	}
	if len(body) != 3 {
		return nil, ErrProof
	}
	for _, key := range []string{"awards", "new_missions", "new_infos"} {
		if _, found := body[key]; !found {
			return nil, ErrProof
		}
	}
	awards, ok := body["awards"].([]any)
	if !ok || len(awards) != 1 {
		return nil, ErrProof
	}
	row, ok := awards[0].(map[string]any)
	if !ok || len(row) != 3 {
		return nil, ErrProof
	}
	if _, ok := body["new_infos"].(map[string]any); !ok {
		return nil, ErrProof
	}
	return body, nil
}

func (recovery claimRecovery) ResolveTimed(ctx context.Context, _ generation.TimedResolutionRequest) (tx.Resolution, error) {
	stored, found, err := recovery.reader.Find(ctx, recovery.identity)
	if err != nil {
		return tx.Resolution{}, err
	}
	if !found {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	if _, err := recovery.decode(stored); err != nil {
		return tx.Resolution{}, err
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: stored}, nil
}
