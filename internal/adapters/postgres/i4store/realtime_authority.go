package i4store

import (
	"context"
	"crypto/subtle"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	appidentity "gxb.local/backend/v2/internal/application/identitylifecycle"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrGameplayBearerNotLive = errors.New("gameplay bearer does not resolve to a live context")

const selectGameplayAuthority = `
SELECT a.account_id::text,a.account_uid,a.status,a.created_at,a.disabled_at,a.liveness_version,
       s.session_id::text,s.auth_profile,s.issued_at,s.absolute_expires_at,s.idle_timeout_seconds,s.last_activity_at,s.revoked_at,s.revocation_reason,s.liveness_version,
       c.context_id::text,c.logical_server_id,c.player_id,c.context_generation,c.created_at,c.ended_at,c.end_reason,c.liveness_version,
       gc.credential_generation,gc.derivation_key_id
FROM gameplay_context_credentials gc
JOIN gameplay_contexts c ON c.context_id=gc.context_id
JOIN account_sessions s ON s.session_id=c.session_id
JOIN accounts a ON a.account_id=c.account_id
WHERE gc.digest=$1 AND gc.revoked_at IS NULL AND c.ended_at IS NULL`

const validateActorLiveness = `
SELECT EXISTS(
 SELECT 1
 FROM gameplay_contexts c
 JOIN account_sessions s ON s.session_id=c.session_id
 JOIN accounts a ON a.account_id=c.account_id
 WHERE c.context_id=$1 AND c.session_id=$2 AND c.account_id=$3
   AND c.logical_server_id=$4 AND c.player_id=$5 AND c.context_generation=$6
   AND c.liveness_version=$7 AND s.liveness_version=$8
   AND a.account_uid=$10 AND a.status='ACTIVE' AND a.disabled_at IS NULL
   AND c.ended_at IS NULL AND s.revoked_at IS NULL
   AND (s.absolute_expires_at IS NULL OR $9 < s.absolute_expires_at)
   AND (s.idle_timeout_seconds IS NULL OR $9 < s.last_activity_at + make_interval(secs => s.idle_timeout_seconds::double precision))
)`

// validateActorsLiveness keeps the single-actor predicate field for field. The
// expected CTE supplies every actor of one message so the fan-out costs one
// read instead of one transaction per recipient.
const validateActorsLiveness = `
WITH expected(context_id,session_id,account_id,logical_server_id,player_id,context_generation,context_liveness_version,session_liveness_version,account_uid) AS (
 SELECT * FROM unnest($1::uuid[],$2::uuid[],$3::uuid[],$4::int[],$5::bigint[],$6::bigint[],$7::bigint[],$8::bigint[],$9::text[])
)
SELECT COALESCE(array_agg(DISTINCT c.context_id::text), '{}'::text[])
FROM expected e
JOIN gameplay_contexts c ON c.context_id=e.context_id
JOIN account_sessions s ON s.session_id=c.session_id
JOIN accounts a ON a.account_id=c.account_id
WHERE c.session_id=e.session_id AND c.account_id=e.account_id
  AND c.logical_server_id=e.logical_server_id AND c.player_id=e.player_id
  AND c.context_generation=e.context_generation
  AND c.liveness_version=e.context_liveness_version
  AND s.liveness_version=e.session_liveness_version
  AND a.account_uid=e.account_uid
  AND a.status='ACTIVE' AND a.disabled_at IS NULL
  AND c.ended_at IS NULL AND s.revoked_at IS NULL
  AND (s.absolute_expires_at IS NULL OR $10 < s.absolute_expires_at)
  AND (s.idle_timeout_seconds IS NULL OR $10 < s.last_activity_at + make_interval(secs => s.idle_timeout_seconds::double precision))`

type RealtimeAuthority struct {
	Queryer         tx.Queryer
	DigestSecret    []byte
	BearerSecret    []byte
	DerivationKeyID string
	BearerKeys      appidentity.BearerKeyResolver
}

func (a RealtimeAuthority) resolveBearerKey(ctx context.Context, id string) (appidentity.BearerDerivationKey, error) {
	if a.BearerKeys != nil {
		return a.BearerKeys.ResolveBearerKey(ctx, id)
	}
	return (appidentity.StaticBearerKeyResolver{Key: appidentity.BearerDerivationKey{ID: a.DerivationKeyID, Secret: a.BearerSecret}}).ResolveBearerKey(ctx, id)
}

func (a RealtimeAuthority) ResolveGameplayBearer(ctx context.Context, raw string, now time.Time) (identity.ActorContext, error) {
	if a.Queryer == nil {
		return identity.ActorContext{}, errors.New("incomplete realtime authority adapter")
	}
	return a.resolveGameplayBearer(ctx, a.Queryer, raw, now)
}

// ResolveGameplayBearerTx reads the same credential through a caller snapshot.
func (a RealtimeAuthority) ResolveGameplayBearerTx(ctx context.Context, q tx.Queryer, raw string, now time.Time) (identity.ActorContext, error) {
	if q == nil {
		return identity.ActorContext{}, errors.New("incomplete realtime authority adapter")
	}
	return a.resolveGameplayBearer(ctx, q, raw, now)
}

func (a RealtimeAuthority) resolveGameplayBearer(ctx context.Context, q tx.Queryer, raw string, now time.Time) (identity.ActorContext, error) {
	if len(a.DigestSecret) < 16 {
		return identity.ActorContext{}, errors.New("incomplete realtime authority adapter")
	}
	if a.BearerKeys == nil && (a.DerivationKeyID == "" || len(a.BearerSecret) < 16) {
		return identity.ActorContext{}, errors.New("incomplete realtime bearer key configuration")
	}
	digest, err := identity.DigestGameplayBearer(a.DigestSecret, raw)
	if err != nil {
		return identity.ActorContext{}, err
	}
	var accountID, accountUID, accountStatus, sessionID, authProfile, contextID, keyID string
	var accountCreated, sessionIssued, sessionActivity, contextCreated time.Time
	var accountDisabledRaw, sessionAbsRaw, idleRaw, sessionRevokedRaw, sessionReasonRaw any
	var contextEndedRaw, contextReasonRaw any
	var accountLV, sessionLV, contextGeneration, contextLV int64
	var logicalServer int32
	var playerID int64
	var credentialGeneration int32
	err = q.QueryRow(ctx, selectGameplayAuthority, digest[:]).Scan(
		&accountID, &accountUID, &accountStatus, &accountCreated, &accountDisabledRaw, &accountLV,
		&sessionID, &authProfile, &sessionIssued, &sessionAbsRaw, &idleRaw, &sessionActivity, &sessionRevokedRaw, &sessionReasonRaw, &sessionLV,
		&contextID, &logicalServer, &playerID, &contextGeneration, &contextCreated, &contextEndedRaw, &contextReasonRaw, &contextLV,
		&credentialGeneration, &keyID,
	)
	if err != nil {
		if errors.Is(err, kernelstore.ErrNoRows) {
			return identity.ActorContext{}, ErrGameplayBearerNotLive
		}
		return identity.ActorContext{}, err
	}
	if int64(credentialGeneration) != contextGeneration {
		return identity.ActorContext{}, ErrGameplayBearerNotLive
	}
	accountDisabled, err := nullableTime(accountDisabledRaw)
	if err != nil {
		return identity.ActorContext{}, err
	}
	sessionAbs, err := nullableTime(sessionAbsRaw)
	if err != nil {
		return identity.ActorContext{}, err
	}
	idle, err := nullableInt64(idleRaw)
	if err != nil {
		return identity.ActorContext{}, err
	}
	sessionRevoked, err := nullableTime(sessionRevokedRaw)
	if err != nil {
		return identity.ActorContext{}, err
	}
	sessionReason, err := nullableString(sessionReasonRaw)
	if err != nil {
		return identity.ActorContext{}, err
	}
	contextEnded, err := nullableTime(contextEndedRaw)
	if err != nil {
		return identity.ActorContext{}, err
	}
	contextReason, err := nullableString(contextReasonRaw)
	if err != nil {
		return identity.ActorContext{}, err
	}
	aid, err := parseAccountID(accountID)
	if err != nil {
		return identity.ActorContext{}, err
	}
	sid, err := parseSessionID(sessionID)
	if err != nil {
		return identity.ActorContext{}, err
	}
	cid, err := parseContextID(contextID)
	if err != nil {
		return identity.ActorContext{}, err
	}
	account := identity.Account{ID: aid, UID: identity.AccountUID(accountUID), Status: accountStatusValue(accountStatus), CreatedAt: accountCreated, DisabledAt: accountDisabled, LivenessVersion: accountLV}
	session := identity.Session{ID: sid, AccountID: aid, AuthProfile: identity.AuthProfile(authProfile), IssuedAt: sessionIssued, AbsoluteExpiresAt: sessionAbs, IdleTimeoutSeconds: idle, LastActivityAt: sessionActivity, RevokedAt: sessionRevoked, RevocationReason: sessionReason, LivenessVersion: sessionLV}
	gc := identity.GameplayContext{ID: cid, SessionID: sid, AccountID: aid, LogicalServerID: identity.LogicalServerID(logicalServer), PlayerID: identity.PlayerID(playerID), ContextGeneration: contextGeneration, CreatedAt: contextCreated, EndedAt: contextEnded, EndReason: contextReason, LivenessVersion: contextLV}
	key, err := a.resolveBearerKey(ctx, keyID)
	if err != nil {
		return identity.ActorContext{}, ErrGameplayBearerNotLive
	}
	want, err := identity.DeriveGameplayBearer(key.Secret, gc)
	if err != nil {
		return identity.ActorContext{}, err
	}
	if subtle.ConstantTimeCompare([]byte(want), []byte(raw)) != 1 {
		return identity.ActorContext{}, ErrGameplayBearerNotLive
	}
	actor, err := identity.ActorFrom(account, session, gc, now)
	if err != nil {
		return identity.ActorContext{}, ErrGameplayBearerNotLive
	}
	observability.NoteActor(ctx, observability.RequestActor{AccountUID: string(actor.AccountUID), PlayerID: int64(actor.PlayerID), SessionID: actor.SessionID.UUID().String()})
	return actor, nil
}

func parseAccountID(s string) (identity.AccountID, error) {
	u, e := ids.ParseUUID(s)
	if e != nil {
		return identity.AccountID{}, fmt.Errorf("account uuid: %w", e)
	}
	return identity.AccountIDFrom(u)
}
func parseSessionID(s string) (identity.SessionID, error) {
	u, e := ids.ParseUUID(s)
	if e != nil {
		return identity.SessionID{}, fmt.Errorf("session uuid: %w", e)
	}
	return identity.SessionIDFrom(u)
}
func parseContextID(s string) (identity.ContextID, error) {
	u, e := ids.ParseUUID(s)
	if e != nil {
		return identity.ContextID{}, fmt.Errorf("context uuid: %w", e)
	}
	return identity.ContextIDFrom(u)
}
func accountStatusValue(s string) identity.AccountStatus {
	if s == "ACTIVE" {
		return identity.AccountActive
	}
	return identity.AccountDisabled
}

func (a RealtimeAuthority) ValidateActor(ctx context.Context, actor identity.ActorContext, now time.Time) error {
	if a.Queryer == nil || actor.ContextID.UUID().IsZero() || actor.SessionID.UUID().IsZero() || actor.AccountID.UUID().IsZero() {
		return ErrGameplayBearerNotLive
	}
	var live bool
	err := a.Queryer.QueryRow(ctx, validateActorLiveness,
		actor.ContextID.UUID().String(), actor.SessionID.UUID().String(), actor.AccountID.UUID().String(),
		int32(actor.LogicalServerID), int64(actor.PlayerID), actor.ContextGeneration,
		actor.ContextLivenessVersion, actor.SessionLivenessVersion, now.UTC(), string(actor.AccountUID),
	).Scan(&live)
	if err != nil || !live {
		return ErrGameplayBearerNotLive
	}
	return nil
}

// ValidateActors reports, in input order, which actors pass the same liveness
// fence as ValidateActor. An empty actor set performs no database read.
func (a RealtimeAuthority) ValidateActors(ctx context.Context, actors []identity.ActorContext, now time.Time) ([]bool, error) {
	live := make([]bool, len(actors))
	if len(actors) == 0 {
		return live, nil
	}
	if a.Queryer == nil {
		return nil, errors.New("incomplete realtime authority adapter")
	}
	contextIDs := make([]string, 0, len(actors))
	sessionIDs := make([]string, 0, len(actors))
	accountIDs := make([]string, 0, len(actors))
	logicalServers := make([]int32, 0, len(actors))
	playerIDs := make([]int64, 0, len(actors))
	contextGenerations := make([]int64, 0, len(actors))
	contextLivenessVersions := make([]int64, 0, len(actors))
	sessionLivenessVersions := make([]int64, 0, len(actors))
	accountUIDs := make([]string, 0, len(actors))
	indexes := make([]int, 0, len(actors))
	for i, actor := range actors {
		if actor.ContextID.UUID().IsZero() || actor.SessionID.UUID().IsZero() || actor.AccountID.UUID().IsZero() {
			continue
		}
		contextIDs = append(contextIDs, actor.ContextID.UUID().String())
		sessionIDs = append(sessionIDs, actor.SessionID.UUID().String())
		accountIDs = append(accountIDs, actor.AccountID.UUID().String())
		logicalServers = append(logicalServers, int32(actor.LogicalServerID))
		playerIDs = append(playerIDs, int64(actor.PlayerID))
		contextGenerations = append(contextGenerations, actor.ContextGeneration)
		contextLivenessVersions = append(contextLivenessVersions, actor.ContextLivenessVersion)
		sessionLivenessVersions = append(sessionLivenessVersions, actor.SessionLivenessVersion)
		accountUIDs = append(accountUIDs, string(actor.AccountUID))
		indexes = append(indexes, i)
	}
	if len(indexes) == 0 {
		return live, nil
	}
	var liveContexts []string
	err := a.Queryer.QueryRow(ctx, validateActorsLiveness,
		contextIDs, sessionIDs, accountIDs, logicalServers, playerIDs, contextGenerations,
		contextLivenessVersions, sessionLivenessVersions, accountUIDs, now.UTC(),
	).Scan(&liveContexts)
	if err != nil {
		return nil, err
	}
	liveSet := make(map[string]bool, len(liveContexts))
	for _, contextID := range liveContexts {
		liveSet[contextID] = true
	}
	for position, actorIndex := range indexes {
		live[actorIndex] = liveSet[contextIDs[position]]
	}
	return live, nil
}

func nullableTime(v any) (*time.Time, error) {
	if v == nil {
		return nil, nil
	}
	t, ok := v.(time.Time)
	if !ok {
		return nil, fmt.Errorf("unexpected nullable time type %T", v)
	}
	t = t.UTC()
	return &t, nil
}

func nullableInt64(v any) (*int64, error) {
	if v == nil {
		return nil, nil
	}
	switch n := v.(type) {
	case int64:
		return &n, nil
	case int32:
		x := int64(n)
		return &x, nil
	case int:
		x := int64(n)
		return &x, nil
	default:
		return nil, fmt.Errorf("unexpected nullable int64 type %T", v)
	}
}

func nullableString(v any) (string, error) {
	if v == nil {
		return "", nil
	}
	s, ok := v.(string)
	if !ok {
		return "", fmt.Errorf("unexpected nullable string type %T", v)
	}
	return s, nil
}
