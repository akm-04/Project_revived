package i4store

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	appidentity "gxb.local/backend/v2/internal/application/identitylifecycle"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/projection/lobby"
)

const (
	sidDigestLabel   = "sid"
	loginDigestLabel = "login_token"

	selectCredentialByDigest = `
SELECT credential_id::text,session_id::text,kind,digest,issued_at,expires_at,revoked_at
FROM account_session_credentials WHERE digest=$1`

	selectAccountSession = `
SELECT a.account_id::text,a.account_uid,a.status,a.created_at,a.disabled_at,a.liveness_version,
       s.session_id::text,s.auth_profile,s.issued_at,s.absolute_expires_at,s.idle_timeout_seconds,s.last_activity_at,s.revoked_at,s.revocation_reason,s.liveness_version
FROM account_sessions s JOIN accounts a ON a.account_id=s.account_id WHERE s.session_id=$1`

	selectAccountSessionForUpdate = `
SELECT a.account_id::text,a.account_uid,a.status,a.created_at,a.disabled_at,a.liveness_version,
       s.session_id::text,s.auth_profile,s.issued_at,s.absolute_expires_at,s.idle_timeout_seconds,s.last_activity_at,s.revoked_at,s.revocation_reason,s.liveness_version
FROM account_sessions s JOIN accounts a ON a.account_id=s.account_id WHERE s.session_id=$1 FOR UPDATE OF s`

	selectVisibleServersJSON = `
SELECT COALESCE(jsonb_agg(jsonb_build_object(
  'logical_server_id',logical_server_id,'name',name,'first_opened_at',first_opened_at,
  'directory_visible',directory_visible,'existing_login_allowed',existing_login_allowed,
  'new_character_allowed',new_character_allowed,'next_player_id',next_player_id,
  'max_player_id',max_player_id,'state_version',state_version,'created_at',created_at,
  'retired_at',retired_at) ORDER BY logical_server_id),'[]'::jsonb)::text
FROM logical_servers WHERE directory_visible=true`

	selectOwnedPlayersJSON = `
SELECT jsonb_build_object(
  'root_count', count(p.player_id),
  'players', COALESCE(jsonb_agg(jsonb_build_object(
    'player_id',p.player_id,'logical_server_id',p.logical_server_id,
    'profile_present',(d.player_id IS NOT NULL),'name',d.name,'lev',d.lev,'vip',d.vip,
    'avatar_id',d.avatar_id,'avatar_frame_id',d.avatar_frame_id,
    'conquer_lev',d.conquer_lev,'conquer_loop_id',d.conquer_loop_id
  ) ORDER BY p.logical_server_id) FILTER (WHERE p.player_id IS NOT NULL),'[]'::jsonb)
)::text
FROM players p LEFT JOIN player_directory_profiles d ON d.player_id=p.player_id
WHERE p.account_id=$1`

	upsertObservation = `
INSERT INTO account_session_server_observations(session_id,logical_server_id,observed_at)
VALUES($1,$2,$3)
ON CONFLICT(session_id,logical_server_id) DO UPDATE SET observed_at=EXCLUDED.observed_at`

	selectPlayerByAccountServer = `
SELECT player_id,account_id::text,logical_server_id,created_at,bootstrap_profile_version,first_entry_pending,state_version
FROM players WHERE account_id=$1 AND logical_server_id=$2`

	selectLogicalServer = `
SELECT logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at,retired_at
FROM logical_servers WHERE logical_server_id=$1`

	lockLogicalServerShared = `
SELECT logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at,retired_at
FROM logical_servers WHERE logical_server_id=$1 FOR SHARE`

	lockLogicalServer = `
SELECT logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at,retired_at
FROM logical_servers WHERE logical_server_id=$1 FOR UPDATE`

	hasObservation = `SELECT EXISTS(SELECT 1 FROM account_session_server_observations WHERE session_id=$1 AND logical_server_id=$2)`

	selectLiveContext = `
SELECT context_id::text,session_id::text,account_id::text,logical_server_id,player_id,context_generation,created_at,ended_at,end_reason,liveness_version
FROM gameplay_contexts WHERE session_id=$1 AND ended_at IS NULL`

	insertPlayer = `
INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version,first_entry_pending,state_version)
VALUES($1,$2,$3,$4,$5,$6,1)`

	insertPlayerDirectoryProfile = `
INSERT INTO player_directory_profiles(
  player_id,name,lev,vip,avatar_id,avatar_frame_id,conquer_lev,conquer_loop_id,state_version,created_at,updated_at)
VALUES($1,'',1,0,$2,0,0,1,1,$3,$3)`

	advanceServerCursor = `
UPDATE logical_servers SET next_player_id=$2,state_version=state_version+1
WHERE logical_server_id=$1 AND next_player_id=$3`

	endContext = `
UPDATE gameplay_contexts SET ended_at=$2,end_reason=$3,liveness_version=liveness_version+1
WHERE context_id=$1 AND ended_at IS NULL`

	revokeContextCredentials = `
UPDATE gameplay_context_credentials SET revoked_at=$2 WHERE context_id=$1 AND revoked_at IS NULL`

	insertContext = `
INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at,liveness_version)
VALUES($1,$2,$3,$4,$5,$6,$7,1)`

	insertGameplayCredential = `
INSERT INTO gameplay_context_credentials(credential_id,context_id,session_id,digest,credential_generation,derivation_key_id,issued_at)
VALUES($1,$2,$3,$4,$5,$6,$7)`

	verifyGameplayCredential = `
SELECT EXISTS(SELECT 1 FROM gameplay_context_credentials
 WHERE context_id=$1 AND session_id=$2 AND digest=$3 AND credential_generation=$4 AND derivation_key_id=$5 AND revoked_at IS NULL)`

	selectGameplayCredentialForContext = `
SELECT digest,derivation_key_id FROM gameplay_context_credentials
WHERE context_id=$1 AND session_id=$2 AND credential_generation=$3 AND revoked_at IS NULL`
)

type BootstrapService struct {
	Runner                  tx.Runner
	Receipts                receipt.Store
	ReceiptReader           receipt.Reader // must use an authoritative fresh connection in production/W1
	DigestSecret            []byte
	BearerSecret            []byte
	DerivationKeyID         string
	BearerKeys              appidentity.BearerKeyResolver
	BootstrapProfileVersion string
	Contributors            []logicalserver.BootstrapContributor
	PersistenceContributors []appboot.CharacterBootstrapPersistenceContributor
	LoginReconcilers        []appboot.CharacterLoginReconciler
	OperationBinder         appboot.CharacterBootstrapOperationBinder
	DetailContributors      []appboot.MID1DetailContributor
	DirectoryReconciler     appboot.MID1DirectoryReconciler
	Profile                 tx.Profile
	Retry                   tx.RetryPolicy
}

const (
	mid1ReceiptSchemaV1 = "gxb.mid1.stock.v1"
	mid1ReceiptSchemaV2 = "gxb.mid1.select.v2"
)

// mid1SelectionReceiptPayload is immutable selection/effect evidence only. It
// deliberately contains neither the raw gameplay bearer nor mutable MID1 Detail.
// Current hydration is reconstructed from canonical owners on every replay.
type mid1SelectionReceiptPayload struct {
	Region                  int32               `json:"region"`
	UID                     identity.AccountUID `json:"uid"`
	PlayerID                int64               `json:"player_id"`
	ContextID               string              `json:"context_id"`
	ContextGeneration       int64               `json:"context_generation"`
	DerivationKeyID         string              `json:"derivation_key_id"`
	BootstrapProfileVersion string              `json:"bootstrap_profile_version"`
}

// legacyMID1ReceiptPayload is intentionally minimal: historical v1 receipts
// may contain raw token/detail fields, but repair code never materializes or
// returns those fields. They remain retention/migration-only evidence.
type legacyMID1ReceiptPayload struct {
	Region int32               `json:"region"`
	UID    identity.AccountUID `json:"uid"`
}

func DefaultI4Profile() tx.Profile {
	return tx.Profile{Name: "I4_BOOTSTRAP", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 12 * time.Second}
}

func (s BootstrapService) validate() error {
	if s.Runner.DB == nil || s.Receipts == nil || s.ReceiptReader == nil {
		return errors.New("bootstrap persistence requires runner, receipt store and fresh receipt reader")
	}
	if len(s.DigestSecret) < 16 || strings.TrimSpace(s.DerivationKeyID) == "" {
		return errors.New("bootstrap credential configuration incomplete")
	}
	if s.BearerKeys == nil && len(s.BearerSecret) < 16 {
		return errors.New("bootstrap bearer key configuration incomplete")
	}
	if s.BootstrapProfileVersion == "" {
		return errors.New("bootstrap profile version required")
	}
	if err := appboot.ValidatePersistenceContributors(s.PersistenceContributors); err != nil {
		return err
	}
	if err := appboot.ValidateDetailContributors(s.DetailContributors); err != nil {
		return err
	}
	return resolvedProfile(s.Profile).Validate()
}

func (s BootstrapService) resolveBearerKey(ctx context.Context, id string) (appidentity.BearerDerivationKey, error) {
	if s.BearerKeys != nil {
		return s.BearerKeys.ResolveBearerKey(ctx, id)
	}
	return (appidentity.StaticBearerKeyResolver{Key: appidentity.BearerDerivationKey{ID: s.DerivationKeyID, Secret: s.BearerSecret}}).ResolveBearerKey(ctx, id)
}

func resolvedProfile(p tx.Profile) tx.Profile {
	if p.Name == "" {
		return DefaultI4Profile()
	}
	return p
}

func resolvedRetry(r tx.RetryPolicy) tx.RetryPolicy {
	if r.MaxAttempts == 0 {
		return tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: true}
	}
	return r
}

func (s BootstrapService) MID18(ctx context.Context, creds appboot.AccountCredentials, op operation.Context) (appboot.MID18Result, error) {
	if err := s.validate(); err != nil {
		return appboot.MID18Result{}, err
	}
	if creds.SID == "" || creds.LoginToken == "" {
		return appboot.MID18Result{}, appboot.ErrAccountAuth
	}
	var out appboot.MID18Result
	_, err := s.Runner.Run(ctx, op, resolvedProfile(s.Profile), tx.Options{Isolation: tx.ReadCommitted}, resolvedRetry(s.Retry), nil, func(txctx context.Context, scope tx.Scope) error {
		account, session, err := s.authenticatePair(txctx, scope.Tx, creds, op.StartedAt, false)
		if err != nil {
			return err
		}
		servers, err := loadVisibleServers(txctx, scope.Tx)
		if err != nil {
			return err
		}
		players, err := loadOwnedPlayerSummaries(txctx, scope.Tx, account.ID)
		if err != nil {
			return err
		}
		for _, obs := range logicalserver.ObserveVisible(session.ID, servers) {
			if _, err := scope.Tx.Exec(txctx, upsertObservation, session.ID.UUID().String(), int32(obs.LogicalServerID), op.StartedAt.UTC()); err != nil {
				return err
			}
		}
		out = appboot.ProjectMID18(servers, players)
		return nil
	})
	return out, err
}

func (s BootstrapService) MID1(ctx context.Context, req appboot.RuntimeMID1Request) (appboot.MID1Result, error) {
	if err := s.validate(); err != nil {
		return appboot.MID1Result{}, err
	}
	if req.Credentials.SID == "" || req.Credentials.LoginToken == "" || !req.Region.Valid() {
		return appboot.MID1Result{}, appboot.ErrAccountAuth
	}
	if req.Operation.StartedAt.IsZero() {
		return appboot.MID1Result{}, errors.New("operation start required")
	}

	contextID, err := contextIDFromOperation(req.Operation)
	if err != nil {
		return appboot.MID1Result{}, err
	}
	credentialID, err := credentialIDFromOperation(req.Operation)
	if err != nil {
		return appboot.MID1Result{}, err
	}

	dynamic := &dynamicReceiptResolver{Reader: s.ReceiptReader}
	var out appboot.MID1Result
	boundOp := req.Operation
	runResult, runErr := s.Runner.Run(ctx, req.Operation, resolvedProfile(s.Profile), tx.Options{Isolation: tx.Serializable}, resolvedRetry(s.Retry), dynamic, func(txctx context.Context, scope tx.Scope) error {
		account, session, err := s.authenticatePair(txctx, scope.Tx, req.Credentials, req.Operation.StartedAt, true)
		if err != nil {
			return err
		}
		fp, err := appboot.MID1Fingerprint(session.ID, req.Region)
		if err != nil {
			return err
		}
		dynamic.SetFingerprint(fp)
		existingPlayer, err := loadPlayer(txctx, scope.Tx, account.ID, req.Region)
		if err != nil {
			return err
		}
		server, existingPlayer, err := loadServerForMID1Admission(txctx, scope.Tx, req.Region, account.ID, existingPlayer)
		if err != nil {
			return err
		}
		observed := false
		if existingPlayer == nil {
			if err := scope.Tx.QueryRow(txctx, hasObservation, session.ID.UUID().String(), int32(req.Region)).Scan(&observed); err != nil {
				return err
			}
		}
		existingContext, err := loadLiveContext(txctx, scope.Tx, session.ID)
		if err != nil {
			return err
		}

		activeKey, err := s.resolveBearerKey(txctx, s.DerivationKeyID)
		if err != nil {
			return err
		}
		planned, err := appboot.PlanMID1(appboot.MID1Command{
			Account: account, Session: session, Server: server, ExistingPlayer: existingPlayer,
			Observed: observed, ExistingContext: existingContext, NewContextID: contextID,
			Operation: req.Operation, BootstrapProfileVersion: s.BootstrapProfileVersion,
			Contributors: s.Contributors, BearerSecret: activeKey.Secret,
		})
		if err != nil {
			return err
		}
		selectedKey := activeKey
		if planned.ContextPlan.Kind == identity.SelectionCoalesced {
			var persistedKeyID string
			if err := scope.Tx.QueryRow(txctx, `SELECT derivation_key_id FROM gameplay_context_credentials WHERE context_id=$1 AND session_id=$2 AND credential_generation=$3 AND revoked_at IS NULL`, planned.ContextPlan.Selected.ID.UUID().String(), planned.ContextPlan.Selected.SessionID.UUID().String(), int32(planned.ContextPlan.Selected.ContextGeneration)).Scan(&persistedKeyID); err != nil {
				return err
			}
			selectedKey, err = s.resolveBearerKey(txctx, persistedKeyID)
			if err != nil {
				return err
			}
			planned.Token, err = identity.DeriveGameplayBearer(selectedKey.Secret, planned.ContextPlan.Selected)
			if err != nil {
				return err
			}
		}
		actor, err := identity.ActorFrom(account, session, planned.ContextPlan.Selected, req.Operation.StartedAt)
		if err != nil {
			return err
		}

		semanticID := mid1ReceiptIdentity(session.ID, req.Region, planned.ContextPlan.Selected.ContextGeneration)
		dynamic.SetIdentity(semanticID)

		// A pre-existing matching receipt is immutable selection evidence only.
		// It must never be used to hydrate mutable player state. A committed
		// receipt without its selected player root is corruption and fails closed.
		if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, semanticID); err != nil {
			return err
		} else if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
				return &receipt.ConflictError{Identity: semanticID}
			}
			if planned.PlayerCreated {
				return errors.New("stored MID1 receipt exists without canonical player root")
			}
			if err := validateStoredMID1Selection(prior, planned, selectedKey.ID); err != nil {
				return err
			}
			if err := appboot.ApplyLoginReconcilers(txctx, scope.Tx, actor, boundOp, s.LoginReconcilers); err != nil {
				return err
			}
			if s.DirectoryReconciler != nil {
				if err := s.DirectoryReconciler.ReconcileDirectoryTx(txctx, scope.Tx, planned.Player.PlayerID, req.Operation); err != nil {
					return err
				}
			}
			if err := s.projectMID1Detail(txctx, scope.Tx, actor, req.Operation.StartedAt, &planned); err != nil {
				return err
			}
			out = planned
			return nil
		}

		if planned.PlayerCreated {
			if s.OperationBinder == nil {
				return errors.New("new character requires bootstrap operation binder")
			}
			boundOp, err = s.OperationBinder.BindCharacterBootstrapOperation(txctx, scope.Tx, boundOp)
			if err != nil {
				return err
			}
			if err := applyMID1PlayerRoot(txctx, scope.Tx, planned); err != nil {
				return err
			}
			bctx := logicalserver.BootstrapContext{
				AccountID: planned.Player.AccountID, SessionID: session.ID,
				LogicalServerID: planned.Player.LogicalServerID, PlayerID: planned.Player.PlayerID,
				Operation: boundOp, BootstrapProfileVersion: planned.Player.BootstrapProfileVersion,
			}
			if err := appboot.ApplyPersistenceContributors(txctx, scope.Tx, bctx, s.PersistenceContributors); err != nil {
				return err
			}
		}

		if err := appboot.ApplyLoginReconcilers(txctx, scope.Tx, actor, boundOp, s.LoginReconcilers); err != nil {
			return err
		}

		// R6 directory reconciliation reads canonical I5 ownership and updates only
		// I4-owned directory columns inside this same SERIALIZABLE transaction.
		if s.DirectoryReconciler != nil {
			if err := s.DirectoryReconciler.ReconcileDirectoryTx(txctx, scope.Tx, planned.Player.PlayerID, req.Operation); err != nil {
				return err
			}
		}

		// Projection happens only after all required canonical owner rows exist in
		// this transaction, so a fresh player is hydrated from persisted truth.
		if err := s.projectMID1Detail(txctx, scope.Tx, actor, req.Operation.StartedAt, &planned); err != nil {
			return err
		}

		payload, err := buildMID1SelectionPayload(planned, selectedKey.ID)
		if err != nil {
			return err
		}
		raw, err := json.Marshal(payload)
		if err != nil {
			return err
		}
		rr, err := buildMID1Receipt(boundOp, semanticID, fp, raw, account.UID, planned.ContextPlan.Selected.ID)
		if err != nil {
			return err
		}

		if err := applyMID1ContextPlan(txctx, scope.Tx, planned, credentialID, s.DigestSecret, selectedKey.ID); err != nil {
			return err
		}
		if _, err := s.Receipts.PutTx(txctx, scope.Tx, rr); err != nil {
			return err
		}
		out = planned
		return nil
	})
	if runErr != nil {
		return appboot.MID1Result{}, runErr
	}
	if runResult.Reconciled {
		if stored, ok := runResult.Evidence.(receipt.Receipt); ok {
			return s.hydrateCommittedMID1(ctx, req, stored)
		}
	}
	return out, nil
}

func (s BootstrapService) projectMID1Detail(ctx context.Context, q tx.Queryer, actor identity.ActorContext, now time.Time, planned *appboot.MID1Result) error {
	if planned == nil || !planned.Player.PlayerID.Valid() {
		return errors.New("invalid MID1 projection plan")
	}
	detail, err := lobby.BuildMID1Detail(lobby.BootstrapView{Actor: actor, RegionName: planned.Server.Name, Now: now})
	if err != nil {
		return err
	}
	for _, c := range s.DetailContributors {
		if err := c.OverlayMID1(ctx, q, actor, planned.PlayerCreated, now, detail); err != nil {
			return fmt.Errorf("MID1 detail contributor %s: %w", c.Name(), err)
		}
	}
	planned.Detail = detail
	return nil
}

func (s BootstrapService) authenticatePair(ctx context.Context, q tx.Queryer, raw appboot.AccountCredentials, now time.Time, lockSession bool) (identity.Account, identity.Session, error) {
	sidWant, err := identity.DigestCredential(s.DigestSecret, sidDigestLabel, raw.SID)
	if err != nil {
		return identity.Account{}, identity.Session{}, appboot.ErrAccountAuth
	}
	loginWant, err := identity.DigestCredential(s.DigestSecret, loginDigestLabel, raw.LoginToken)
	if err != nil {
		return identity.Account{}, identity.Session{}, appboot.ErrAccountAuth
	}
	sid, err := loadSessionCredential(ctx, q, sidWant)
	if err != nil {
		return identity.Account{}, identity.Session{}, appboot.ErrAccountAuth
	}
	login, err := loadSessionCredential(ctx, q, loginWant)
	if err != nil {
		return identity.Account{}, identity.Session{}, appboot.ErrAccountAuth
	}
	if sid.Kind != identity.CredentialSID || login.Kind != identity.CredentialLoginToken || sid.SessionID != login.SessionID {
		return identity.Account{}, identity.Session{}, appboot.ErrAccountAuth
	}
	query := selectAccountSession
	if lockSession {
		query = selectAccountSessionForUpdate
	}
	account, session, err := loadAccountSession(ctx, q, sid.SessionID, query)
	if err != nil {
		return identity.Account{}, identity.Session{}, appboot.ErrAccountAuth
	}
	if _, err := identity.AuthenticatePair(account, session, sid, login, sidWant, loginWant, now.UTC()); err != nil {
		return identity.Account{}, identity.Session{}, appboot.ErrAccountAuth
	}
	return account, session, nil
}

func loadSessionCredential(ctx context.Context, q tx.Queryer, digest identity.CredentialDigest) (identity.SessionCredential, error) {
	var credID, sessionID, kind string
	var gotDigest []byte
	var issued time.Time
	var expiresRaw, revokedRaw any
	err := q.QueryRow(ctx, selectCredentialByDigest, digest[:]).Scan(&credID, &sessionID, &kind, &gotDigest, &issued, &expiresRaw, &revokedRaw)
	if err != nil {
		return identity.SessionCredential{}, err
	}
	cid, err := parseCredentialID(credID)
	if err != nil {
		return identity.SessionCredential{}, err
	}
	sid, err := parseSessionID(sessionID)
	if err != nil {
		return identity.SessionCredential{}, err
	}
	var kd identity.CredentialKind
	switch kind {
	case "SID":
		kd = identity.CredentialSID
	case "LOGIN_TOKEN":
		kd = identity.CredentialLoginToken
	default:
		return identity.SessionCredential{}, errors.New("unknown credential kind")
	}
	if len(gotDigest) != 32 {
		return identity.SessionCredential{}, errors.New("stored credential digest invalid")
	}
	var d identity.CredentialDigest
	copy(d[:], gotDigest)
	expires, err := nullableTime(expiresRaw)
	if err != nil {
		return identity.SessionCredential{}, err
	}
	revoked, err := nullableTime(revokedRaw)
	if err != nil {
		return identity.SessionCredential{}, err
	}
	return identity.SessionCredential{ID: cid, SessionID: sid, Kind: kd, Digest: d, IssuedAt: issued.UTC(), ExpiresAt: expires, RevokedAt: revoked}, nil
}

func loadAccountSession(ctx context.Context, q tx.Queryer, sid identity.SessionID, query string) (identity.Account, identity.Session, error) {
	var accountID, accountUID, accountStatus, sessionID, authProfile string
	var accountCreated, sessionIssued, sessionActivity time.Time
	var accountDisabledRaw, sessionAbsRaw, idleRaw, sessionRevokedRaw, sessionReasonRaw any
	var accountLV, sessionLV int64
	err := q.QueryRow(ctx, query, sid.UUID().String()).Scan(
		&accountID, &accountUID, &accountStatus, &accountCreated, &accountDisabledRaw, &accountLV,
		&sessionID, &authProfile, &sessionIssued, &sessionAbsRaw, &idleRaw, &sessionActivity, &sessionRevokedRaw, &sessionReasonRaw, &sessionLV,
	)
	if err != nil {
		return identity.Account{}, identity.Session{}, err
	}
	aid, err := parseAccountID(accountID)
	if err != nil {
		return identity.Account{}, identity.Session{}, err
	}
	gotSID, err := parseSessionID(sessionID)
	if err != nil {
		return identity.Account{}, identity.Session{}, err
	}
	if gotSID != sid {
		return identity.Account{}, identity.Session{}, errors.New("session lookup mismatch")
	}
	disabled, err := nullableTime(accountDisabledRaw)
	if err != nil {
		return identity.Account{}, identity.Session{}, err
	}
	abs, err := nullableTime(sessionAbsRaw)
	if err != nil {
		return identity.Account{}, identity.Session{}, err
	}
	idle, err := nullableInt64(idleRaw)
	if err != nil {
		return identity.Account{}, identity.Session{}, err
	}
	revoked, err := nullableTime(sessionRevokedRaw)
	if err != nil {
		return identity.Account{}, identity.Session{}, err
	}
	reason, err := nullableString(sessionReasonRaw)
	if err != nil {
		return identity.Account{}, identity.Session{}, err
	}
	account := identity.Account{ID: aid, UID: identity.AccountUID(accountUID), Status: accountStatusValue(accountStatus), CreatedAt: accountCreated.UTC(), DisabledAt: disabled, LivenessVersion: accountLV}
	session := identity.Session{ID: gotSID, AccountID: aid, AuthProfile: identity.AuthProfile(authProfile), IssuedAt: sessionIssued.UTC(), AbsoluteExpiresAt: abs, IdleTimeoutSeconds: idle, LastActivityAt: sessionActivity.UTC(), RevokedAt: revoked, RevocationReason: reason, LivenessVersion: sessionLV}
	return account, session, nil
}

type serverJSON struct {
	ID                   int32      `json:"logical_server_id"`
	Name                 string     `json:"name"`
	FirstOpenedAt        *time.Time `json:"first_opened_at"`
	DirectoryVisible     bool       `json:"directory_visible"`
	ExistingLoginAllowed bool       `json:"existing_login_allowed"`
	NewCharacterAllowed  bool       `json:"new_character_allowed"`
	NextPlayerID         int64      `json:"next_player_id"`
	MaxPlayerID          int64      `json:"max_player_id"`
	StateVersion         int64      `json:"state_version"`
	CreatedAt            time.Time  `json:"created_at"`
	RetiredAt            *time.Time `json:"retired_at"`
}

func loadVisibleServers(ctx context.Context, q tx.Queryer) ([]logicalserver.Server, error) {
	var raw string
	if err := q.QueryRow(ctx, selectVisibleServersJSON).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []serverJSON
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]logicalserver.Server, 0, len(rows))
	for _, r := range rows {
		s := logicalserver.Server{ID: identity.LogicalServerID(r.ID), Name: r.Name, FirstOpenedAt: r.FirstOpenedAt, DirectoryVisible: r.DirectoryVisible, ExistingLoginAllowed: r.ExistingLoginAllowed, NewCharacterAllowed: r.NewCharacterAllowed, NextPlayerID: identity.PlayerID(r.NextPlayerID), MaxPlayerID: identity.PlayerID(r.MaxPlayerID), StateVersion: r.StateVersion, CreatedAt: r.CreatedAt.UTC(), RetiredAt: r.RetiredAt}
		if err := s.Validate(); err != nil {
			return nil, err
		}
		out = append(out, s)
	}
	return out, nil
}

type ownedPlayerJSON struct {
	PlayerID        int64  `json:"player_id"`
	LogicalServerID int32  `json:"logical_server_id"`
	ProfilePresent  bool   `json:"profile_present"`
	Name            string `json:"name"`
	Level           int64  `json:"lev"`
	VIP             int64  `json:"vip"`
	AvatarID        int64  `json:"avatar_id"`
	AvatarFrameID   int64  `json:"avatar_frame_id"`
	ConquerLevel    int64  `json:"conquer_lev"`
	ConquerLoopID   int64  `json:"conquer_loop_id"`
}

type ownedPlayersEnvelope struct {
	RootCount int               `json:"root_count"`
	Players   []ownedPlayerJSON `json:"players"`
}

func decodeOwnedPlayerSummaries(raw string) ([]logicalserver.PlayerSummary, error) {
	var env ownedPlayersEnvelope
	if err := json.Unmarshal([]byte(raw), &env); err != nil {
		return nil, err
	}
	if env.RootCount != len(env.Players) {
		return nil, errors.New("player directory projection root/profile count mismatch")
	}
	out := make([]logicalserver.PlayerSummary, 0, len(env.Players))
	for _, r := range env.Players {
		if !r.ProfilePresent {
			return nil, fmt.Errorf("player %d missing required directory profile", r.PlayerID)
		}
		if r.PlayerID <= 0 || r.LogicalServerID <= 0 || r.Level < 1 || r.AvatarID <= 0 || r.ConquerLoopID < 1 {
			return nil, fmt.Errorf("player %d has invalid directory profile", r.PlayerID)
		}
		out = append(out, logicalserver.PlayerSummary{
			ID: r.PlayerID, Region: r.LogicalServerID, Level: r.Level, VIP: r.VIP, Name: r.Name,
			AvatarID: r.AvatarID, AvatarFrameID: r.AvatarFrameID, ConquerLevel: r.ConquerLevel, ConquerLoopID: r.ConquerLoopID,
		})
	}
	return out, nil
}

func loadOwnedPlayerSummaries(ctx context.Context, q tx.Queryer, aid identity.AccountID) ([]logicalserver.PlayerSummary, error) {
	var raw string
	if err := q.QueryRow(ctx, selectOwnedPlayersJSON, aid.UUID().String()).Scan(&raw); err != nil {
		return nil, err
	}
	return decodeOwnedPlayerSummaries(raw)
}

func loadServerWithQuery(ctx context.Context, q tx.Queryer, id identity.LogicalServerID, query string) (logicalserver.Server, error) {
	var s logicalserver.Server
	var rawID int32
	var next, max int64
	var firstRaw, retiredRaw any
	err := q.QueryRow(ctx, query, int32(id)).Scan(&rawID, &s.Name, &firstRaw, &s.DirectoryVisible, &s.ExistingLoginAllowed, &s.NewCharacterAllowed, &next, &max, &s.StateVersion, &s.CreatedAt, &retiredRaw)
	if err != nil {
		return s, err
	}
	first, err := nullableTime(firstRaw)
	if err != nil {
		return s, err
	}
	retired, err := nullableTime(retiredRaw)
	if err != nil {
		return s, err
	}
	s.ID = identity.LogicalServerID(rawID)
	s.NextPlayerID = identity.PlayerID(next)
	s.MaxPlayerID = identity.PlayerID(max)
	s.FirstOpenedAt = first
	s.RetiredAt = retired
	s.CreatedAt = s.CreatedAt.UTC()
	return s, s.Validate()
}

func loadServerForUpdate(ctx context.Context, q tx.Queryer, id identity.LogicalServerID) (logicalserver.Server, error) {
	return loadServerWithQuery(ctx, q, id, lockLogicalServer)
}

func loadServerForShare(ctx context.Context, q tx.Queryer, id identity.LogicalServerID) (logicalserver.Server, error) {
	return loadServerWithQuery(ctx, q, id, lockLogicalServerShared)
}

func loadServer(ctx context.Context, q tx.Queryer, id identity.LogicalServerID) (logicalserver.Server, error) {
	return loadServerWithQuery(ctx, q, id, selectLogicalServer)
}

// loadServerForMID1Admission keeps the server-wide allocator lock off ordinary
// existing-player logins. A tentative creation path takes the exclusive fence,
// then rechecks the account/server player row after acquiring it. Under the
// SERIALIZABLE MID1 transaction a concurrent creator may still force a
// serialization/uniqueness abort rather than become visible in the original
// snapshot; that is a definite-abort retry, not duplicate creation.
func serverAdmissionFenceQuery(existing bool) string {
	if existing {
		return lockLogicalServerShared
	}
	return lockLogicalServer
}

func loadServerForMID1Admission(ctx context.Context, q tx.Queryer, region identity.LogicalServerID, aid identity.AccountID, existing *logicalserver.PlayerRoot) (logicalserver.Server, *logicalserver.PlayerRoot, error) {
	if existing != nil {
		srv, err := loadServerWithQuery(ctx, q, region, serverAdmissionFenceQuery(true))
		return srv, existing, err
	}
	srv, err := loadServerWithQuery(ctx, q, region, serverAdmissionFenceQuery(false))
	if err != nil {
		return logicalserver.Server{}, nil, err
	}
	rechecked, err := loadPlayer(ctx, q, aid, region)
	if err != nil {
		return logicalserver.Server{}, nil, err
	}
	return srv, rechecked, nil
}

func loadPlayer(ctx context.Context, q tx.Queryer, aid identity.AccountID, region identity.LogicalServerID) (*logicalserver.PlayerRoot, error) {
	var p logicalserver.PlayerRoot
	var accountID string
	var rawRegion int32
	err := q.QueryRow(ctx, selectPlayerByAccountServer, aid.UUID().String(), int32(region)).Scan(&p.PlayerID, &accountID, &rawRegion, &p.CreatedAt, &p.BootstrapProfileVersion, &p.FirstEntryPending, &p.StateVersion)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	gotAid, err := parseAccountID(accountID)
	if err != nil {
		return nil, err
	}
	p.AccountID = gotAid
	p.LogicalServerID = identity.LogicalServerID(rawRegion)
	p.CreatedAt = p.CreatedAt.UTC()
	return &p, nil
}

func loadLiveContext(ctx context.Context, q tx.Queryer, sid identity.SessionID) (*identity.GameplayContext, error) {
	var contextID, sessionID, accountID string
	var rawRegion int32
	var rawPlayer int64
	var c identity.GameplayContext
	var endedRaw, reasonRaw any
	err := q.QueryRow(ctx, selectLiveContext, sid.UUID().String()).Scan(&contextID, &sessionID, &accountID, &rawRegion, &rawPlayer, &c.ContextGeneration, &c.CreatedAt, &endedRaw, &reasonRaw, &c.LivenessVersion)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	cid, err := parseContextID(contextID)
	if err != nil {
		return nil, err
	}
	gotSID, err := parseSessionID(sessionID)
	if err != nil {
		return nil, err
	}
	aid, err := parseAccountID(accountID)
	if err != nil {
		return nil, err
	}
	ended, err := nullableTime(endedRaw)
	if err != nil {
		return nil, err
	}
	reason, err := nullableString(reasonRaw)
	if err != nil {
		return nil, err
	}
	c.ID = cid
	c.SessionID = gotSID
	c.AccountID = aid
	c.LogicalServerID = identity.LogicalServerID(rawRegion)
	c.PlayerID = identity.PlayerID(rawPlayer)
	c.CreatedAt = c.CreatedAt.UTC()
	c.EndedAt = ended
	c.EndReason = reason
	return &c, nil
}

func applyMID1PlayerRoot(ctx context.Context, t tx.Tx, r appboot.MID1Result) error {
	if !r.PlayerCreated {
		return nil
	}
	if r.Player.PlayerID == 0 || r.Server.ID == 0 {
		return errors.New("invalid MID1 player-root persistence plan")
	}
	expectedOldCursor := int64(r.Player.PlayerID)
	if int64(r.Server.NextPlayerID) != expectedOldCursor+1 {
		return errors.New("new-player allocator plan is not contiguous")
	}
	if _, err := t.Exec(ctx, insertPlayer, int64(r.Player.PlayerID), r.Player.AccountID.UUID().String(), int32(r.Player.LogicalServerID), r.Player.CreatedAt.UTC(), r.Player.BootstrapProfileVersion, r.Player.FirstEntryPending); err != nil {
		return err
	}
	// Wave-D owns the narrow MID18 directory projection and seeds it atomically
	// with the root. Later-domain canonical owners are created only through
	// transaction-aware owner contributors.
	if _, err := t.Exec(ctx, insertPlayerDirectoryProfile, int64(r.Player.PlayerID), logicalserver.BootstrapDirectoryAvatarID, r.Player.CreatedAt.UTC()); err != nil {
		return err
	}
	tag, err := t.Exec(ctx, advanceServerCursor, int32(r.Server.ID), int64(r.Server.NextPlayerID), expectedOldCursor)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("logical-server allocator cursor lost")
	}
	return nil
}

func applyMID1ContextPlan(ctx context.Context, t tx.Tx, r appboot.MID1Result, credentialID identity.CredentialID, digestSecret []byte, keyID string) error {
	if r.ContextPlan.Selected.ContextGeneration > int64(^uint32(0)>>1) {
		return errors.New("context generation exceeds credential field")
	}
	selected := r.ContextPlan.Selected
	digest, err := identity.DigestGameplayBearer(digestSecret, r.Token)
	if err != nil {
		return err
	}
	if r.ContextPlan.Kind == identity.SelectionCoalesced {
		var exists bool
		if err := t.QueryRow(ctx, verifyGameplayCredential, selected.ID.UUID().String(), selected.SessionID.UUID().String(), digest[:], int32(selected.ContextGeneration), keyID).Scan(&exists); err != nil {
			return err
		}
		if !exists {
			return errors.New("coalesced context missing matching gameplay credential")
		}
		return nil
	}
	if r.ContextPlan.Previous != nil {
		prev := r.ContextPlan.Previous
		tag, err := t.Exec(ctx, endContext, prev.ID.UUID().String(), selected.CreatedAt.UTC(), "superseded")
		if err != nil {
			return err
		}
		if tag.RowsAffected() != 1 {
			return errors.New("previous gameplay context lost before supersession")
		}
		if _, err := t.Exec(ctx, revokeContextCredentials, prev.ID.UUID().String(), selected.CreatedAt.UTC()); err != nil {
			return err
		}
	}
	if _, err := t.Exec(ctx, insertContext, selected.ID.UUID().String(), selected.SessionID.UUID().String(), selected.AccountID.UUID().String(), int32(selected.LogicalServerID), int64(selected.PlayerID), selected.ContextGeneration, selected.CreatedAt.UTC()); err != nil {
		return err
	}
	if _, err := t.Exec(ctx, insertGameplayCredential, credentialID.UUID().String(), selected.ID.UUID().String(), selected.SessionID.UUID().String(), digest[:], int32(selected.ContextGeneration), keyID, selected.CreatedAt.UTC()); err != nil {
		return err
	}
	return nil
}

func contextIDFromOperation(op operation.Context) (identity.ContextID, error) {
	u := uuidFromDerived(op.Derive("i4.mid1.context-id", 0))
	return identity.ContextIDFrom(u)
}
func credentialIDFromOperation(op operation.Context) (identity.CredentialID, error) {
	u := uuidFromDerived(op.Derive("i4.mid1.gameplay-credential-id", 0))
	return identity.CredentialIDFrom(u)
}
func uuidFromDerived(d [32]byte) ids.UUID {
	var u ids.UUID
	copy(u[:], d[:16])
	u[6] = (u[6] & 0x0f) | 0x40
	u[8] = (u[8] & 0x3f) | 0x80
	return u
}
func parseCredentialID(s string) (identity.CredentialID, error) {
	u, e := ids.ParseUUID(s)
	if e != nil {
		return identity.CredentialID{}, e
	}
	return identity.CredentialIDFrom(u)
}

func mid1ReceiptIdentity(sid identity.SessionID, region identity.LogicalServerID, generation int64) receipt.Identity {
	return receipt.Identity{OwnerKind: "session", OwnerKey: sid.UUID().String(), Domain: "identity", Operation: "mid1.select", SemanticKey: fmt.Sprintf("server:%d/generation:%d", region, generation)}
}

func buildMID1SelectionPayload(r appboot.MID1Result, keyID string) (mid1SelectionReceiptPayload, error) {
	selected := r.ContextPlan.Selected
	p := mid1SelectionReceiptPayload{
		Region: int32(selected.LogicalServerID), UID: r.UID, PlayerID: int64(selected.PlayerID),
		ContextID: selected.ID.UUID().String(), ContextGeneration: selected.ContextGeneration,
		DerivationKeyID: keyID, BootstrapProfileVersion: r.Player.BootstrapProfileVersion,
	}
	if p.Region <= 0 || !p.UID.Valid() || p.PlayerID <= 0 || p.ContextID == "" || p.ContextGeneration < 1 || strings.TrimSpace(p.DerivationKeyID) == "" || strings.TrimSpace(p.BootstrapProfileVersion) == "" {
		return mid1SelectionReceiptPayload{}, errors.New("invalid MID1 selection receipt payload")
	}
	return p, nil
}

func buildMID1Receipt(op operation.Context, id receipt.Identity, fp [32]byte, payload json.RawMessage, accountUID identity.AccountUID, cid identity.ContextID) (receipt.Receipt, error) {
	r := receipt.Receipt{ID: uuidFromDerived(op.Derive("i4.mid1.receipt-id", 0)), Identity: id, OperationClass: appboot.MID1ReceiptKind, RequestFingerprint: fp, ResultSchema: mid1ReceiptSchemaV2, ResultPayload: append(json.RawMessage(nil), payload...), OperationStartedAt: op.StartedAt.UTC(), PolicyVersion: "i4-wave-s-v1", ActorAccountUID: string(accountUID), ContextID: cid.UUID()}
	return r, r.Validate()
}

func validateStoredMID1Selection(stored receipt.Receipt, current appboot.MID1Result, keyID string) error {
	selected := current.ContextPlan.Selected
	if stored.ContextID != selected.ID.UUID() || stored.ActorAccountUID != string(current.UID) {
		return errors.New("stored MID1 receipt selection metadata mismatch")
	}
	switch stored.ResultSchema {
	case mid1ReceiptSchemaV2:
		var p mid1SelectionReceiptPayload
		if err := json.Unmarshal(stored.ResultPayload, &p); err != nil {
			return err
		}
		want, err := buildMID1SelectionPayload(current, keyID)
		if err != nil {
			return err
		}
		if p != want {
			return errors.New("stored MID1 v2 selection payload mismatch")
		}
		return nil
	case mid1ReceiptSchemaV1:
		// Legacy v1 may contain token/detail/is_new. Parse only immutable fields;
		// never return or log the historical secret-bearing payload.
		var p legacyMID1ReceiptPayload
		if err := json.Unmarshal(stored.ResultPayload, &p); err != nil {
			return err
		}
		if p.Region != int32(selected.LogicalServerID) || p.UID != current.UID {
			return errors.New("stored MID1 v1 selection payload mismatch")
		}
		return nil
	default:
		return fmt.Errorf("unsupported stored MID1 receipt schema %q", stored.ResultSchema)
	}
}

func (s BootstrapService) hydrateCommittedMID1(ctx context.Context, req appboot.RuntimeMID1Request, stored receipt.Receipt) (appboot.MID1Result, error) {
	var out appboot.MID1Result
	// Reconciliation has already proved the write receipt committed. This second
	// transaction is read-only current hydration; it must not replay the old stock
	// snapshot and must not mint another gameplay context.
	_, err := s.Runner.Run(ctx, req.Operation, resolvedProfile(s.Profile), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(txctx context.Context, scope tx.Scope) error {
		account, session, err := s.authenticatePair(txctx, scope.Tx, req.Credentials, req.Operation.StartedAt, false)
		if err != nil {
			return err
		}
		player, err := loadPlayer(txctx, scope.Tx, account.ID, req.Region)
		if err != nil {
			return err
		}
		if player == nil {
			return errors.New("committed MID1 selection missing canonical player")
		}
		server, err := loadServer(txctx, scope.Tx, req.Region)
		if err != nil {
			return err
		}
		live, err := loadLiveContext(txctx, scope.Tx, session.ID)
		if err != nil {
			return err
		}
		if live == nil || live.ID.UUID() != stored.ContextID || live.AccountID != account.ID || live.LogicalServerID != req.Region || live.PlayerID != player.PlayerID {
			return errors.New("committed MID1 selection is no longer the live target")
		}
		var storedDigest []byte
		var storedKeyID string
		if err := scope.Tx.QueryRow(txctx, selectGameplayCredentialForContext, live.ID.UUID().String(), live.SessionID.UUID().String(), int32(live.ContextGeneration)).Scan(&storedDigest, &storedKeyID); err != nil {
			return err
		}
		key, err := s.resolveBearerKey(txctx, storedKeyID)
		if err != nil {
			return err
		}
		token, err := identity.DeriveGameplayBearer(key.Secret, *live)
		if err != nil {
			return err
		}
		digest, err := identity.DigestGameplayBearer(s.DigestSecret, token)
		if err != nil {
			return err
		}
		if !bytes.Equal(storedDigest, digest[:]) {
			return errors.New("committed MID1 context has no matching derivable gameplay credential")
		}
		actor, err := identity.ActorFrom(account, session, *live, req.Operation.StartedAt)
		if err != nil {
			return err
		}
		out = appboot.MID1Result{Token: token, Region: int32(server.ID), UID: account.UID, IsNew: logicalserver.MID1IsNew(*player), Player: *player, Server: server, ContextPlan: identity.SelectionPlan{Kind: identity.SelectionCoalesced, Selected: *live}}
		if err := s.projectMID1Detail(txctx, scope.Tx, actor, req.Operation.StartedAt, &out); err != nil {
			return err
		}
		return validateStoredMID1Selection(stored, out, storedKeyID)
	})
	return out, err
}

type dynamicReceiptResolver struct {
	Reader      receipt.Reader
	Fingerprint [32]byte
	id          receipt.Identity
}

func (r *dynamicReceiptResolver) SetIdentity(id receipt.Identity) { r.id = id }
func (r *dynamicReceiptResolver) SetFingerprint(fp [32]byte)      { r.Fingerprint = fp }
func (r *dynamicReceiptResolver) Resolve(ctx context.Context, _ tx.ResolutionRequest) (tx.Resolution, error) {
	if r.Reader == nil {
		return tx.Resolution{}, errors.New("nil receipt reader")
	}
	if err := r.id.Validate(); err != nil {
		return tx.Resolution{}, err
	}
	got, ok, err := r.Reader.Find(ctx, r.id)
	if err != nil {
		return tx.Resolution{}, err
	}
	if !ok {
		// A single fresh receipt miss is not authoritative proof that the
		// ambiguous MID1 transaction cannot still become visible.
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	if !bytes.Equal(got.RequestFingerprint[:], r.Fingerprint[:]) {
		return tx.Resolution{}, &receipt.ConflictError{Identity: r.id}
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: got}, nil
}
