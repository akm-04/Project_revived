// Package identitystore is the PostgreSQL adapter for canonical identity
// lifecycle tables. It intentionally exposes owner-specific operations only.
package identitystore

import (
	"context"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	lockAccount               = `SELECT account_id::text,account_uid,status,created_at,disabled_at,liveness_version FROM accounts WHERE account_id=$1 FOR UPDATE`
	findBinding               = `SELECT binding_id::text,account_id::text,provider_key,subject_normalized,linked_at,disabled_at FROM account_provider_bindings WHERE provider_key=$1 AND subject_normalized=$2 FOR UPDATE`
	insertBinding             = `INSERT INTO account_provider_bindings(binding_id,account_id,provider_key,subject_normalized,linked_at,disabled_at) VALUES($1,$2,$3,$4,$5,$6)`
	insertSession             = `INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,absolute_expires_at,idle_timeout_seconds,last_activity_at,revoked_at,revocation_reason,liveness_version) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`
	insertSessionCredential   = `INSERT INTO account_session_credentials(credential_id,session_id,kind,digest,issued_at,expires_at,revoked_at) VALUES($1,$2,$3,$4,$5,$6,$7)`
	lockSession               = `SELECT session_id::text,account_id::text,auth_profile,issued_at,absolute_expires_at,idle_timeout_seconds,last_activity_at,revoked_at,revocation_reason,liveness_version FROM account_sessions WHERE session_id=$1 FOR UPDATE`
	lockLiveContext           = `SELECT context_id::text,session_id::text,account_id::text,logical_server_id,player_id,context_generation,created_at,ended_at,end_reason,liveness_version FROM gameplay_contexts WHERE session_id=$1 AND ended_at IS NULL FOR UPDATE`
	saveRevokedSession        = `UPDATE account_sessions SET revoked_at=$2,revocation_reason=$3,liveness_version=$4 WHERE session_id=$1 AND liveness_version=$5`
	saveEndedContext          = `UPDATE gameplay_contexts SET ended_at=$2,end_reason=$3,liveness_version=$4 WHERE context_id=$1 AND liveness_version=$5 AND ended_at IS NULL`
	revokeSessionCredentials  = `UPDATE account_session_credentials SET revoked_at=$2 WHERE session_id=$1 AND revoked_at IS NULL`
	revokeGameplayCredentials = `UPDATE gameplay_context_credentials SET revoked_at=$2 WHERE session_id=$1 AND revoked_at IS NULL`
	touchSessionActivity      = `UPDATE account_sessions SET last_activity_at=$3 WHERE session_id=$1 AND revoked_at IS NULL AND idle_timeout_seconds IS NOT NULL AND last_activity_at <= $2`
)

type Store struct{}

func (Store) LockAccountTx(ctx context.Context, t tx.Tx, id identity.AccountID) (identity.Account, error) {
	if t == nil {
		return identity.Account{}, errors.New("nil transaction")
	}
	var aid, uid, status string
	var created time.Time
	var disabled any
	var lv int64
	if err := t.QueryRow(ctx, lockAccount, id.UUID().String()).Scan(&aid, &uid, &status, &created, &disabled, &lv); err != nil {
		return identity.Account{}, err
	}
	parsed, err := parseAccountID(aid)
	if err != nil {
		return identity.Account{}, err
	}
	dis, err := nullableTime(disabled)
	if err != nil {
		return identity.Account{}, err
	}
	st := identity.AccountStatus(0)
	switch status {
	case "ACTIVE":
		st = identity.AccountActive
	case "DISABLED":
		st = identity.AccountDisabled
	default:
		return identity.Account{}, errors.New("stored account status invalid")
	}
	return identity.Account{ID: parsed, UID: identity.AccountUID(uid), Status: st, CreatedAt: created.UTC(), DisabledAt: dis, LivenessVersion: lv}, nil
}
func (Store) FindProviderBindingTx(ctx context.Context, t tx.Tx, p identity.ProviderPrincipal) (*identity.ProviderBinding, error) {
	var bid, aid, provider, subject string
	var linked time.Time
	var disabled any
	err := t.QueryRow(ctx, findBinding, p.ProviderKey, p.SubjectNormalized).Scan(&bid, &aid, &provider, &subject, &linked, &disabled)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	bID, err := parseBindingID(bid)
	if err != nil {
		return nil, err
	}
	aID, err := parseAccountID(aid)
	if err != nil {
		return nil, err
	}
	dis, err := nullableTime(disabled)
	if err != nil {
		return nil, err
	}
	b := identity.ProviderBinding{ID: bID, AccountID: aID, Principal: identity.ProviderPrincipal{ProviderKey: provider, SubjectNormalized: subject}, LinkedAt: linked.UTC(), DisabledAt: dis}
	return &b, nil
}
func (Store) InsertProviderBindingTx(ctx context.Context, t tx.Tx, b identity.ProviderBinding) error {
	_, err := t.Exec(ctx, insertBinding, b.ID.UUID().String(), b.AccountID.UUID().String(), b.Principal.ProviderKey, b.Principal.SubjectNormalized, b.LinkedAt.UTC(), optionalTime(b.DisabledAt))
	return err
}
func (Store) InsertSessionTx(ctx context.Context, t tx.Tx, s identity.Session) error {
	var idle any
	if s.IdleTimeoutSeconds != nil {
		idle = *s.IdleTimeoutSeconds
	}
	_, err := t.Exec(ctx, insertSession, s.ID.UUID().String(), s.AccountID.UUID().String(), string(s.AuthProfile), s.IssuedAt.UTC(), optionalTime(s.AbsoluteExpiresAt), idle, s.LastActivityAt.UTC(), optionalTime(s.RevokedAt), optionalString(s.RevocationReason), s.LivenessVersion)
	return err
}
func (Store) InsertSessionCredentialTx(ctx context.Context, t tx.Tx, c identity.SessionCredential) error {
	kind := ""
	switch c.Kind {
	case identity.CredentialSID:
		kind = "SID"
	case identity.CredentialLoginToken:
		kind = "LOGIN_TOKEN"
	default:
		return errors.New("invalid session credential kind")
	}
	_, err := t.Exec(ctx, insertSessionCredential, c.ID.UUID().String(), c.SessionID.UUID().String(), kind, c.Digest[:], c.IssuedAt.UTC(), optionalTime(c.ExpiresAt), optionalTime(c.RevokedAt))
	return err
}
func (Store) LockSessionTx(ctx context.Context, t tx.Tx, id identity.SessionID) (identity.Session, error) {
	var sid, aid, profile string
	var issued, last time.Time
	var abs, idle, revoked, reason any
	var lv int64
	if err := t.QueryRow(ctx, lockSession, id.UUID().String()).Scan(&sid, &aid, &profile, &issued, &abs, &idle, &last, &revoked, &reason, &lv); err != nil {
		return identity.Session{}, err
	}
	sID, err := parseSessionID(sid)
	if err != nil {
		return identity.Session{}, err
	}
	aID, err := parseAccountID(aid)
	if err != nil {
		return identity.Session{}, err
	}
	at, err := nullableTime(abs)
	if err != nil {
		return identity.Session{}, err
	}
	rt, err := nullableTime(revoked)
	if err != nil {
		return identity.Session{}, err
	}
	idleSec, err := nullableInt64(idle)
	if err != nil {
		return identity.Session{}, err
	}
	rsn, err := nullableString(reason)
	if err != nil {
		return identity.Session{}, err
	}
	return identity.Session{ID: sID, AccountID: aID, AuthProfile: identity.AuthProfile(profile), IssuedAt: issued.UTC(), AbsoluteExpiresAt: at, IdleTimeoutSeconds: idleSec, LastActivityAt: last.UTC(), RevokedAt: rt, RevocationReason: rsn, LivenessVersion: lv}, nil
}
func (Store) LockLiveContextTx(ctx context.Context, t tx.Tx, sid identity.SessionID) (*identity.GameplayContext, error) {
	var cid, session, account string
	var region int32
	var player, generation, lv int64
	var created time.Time
	var ended, reason any
	err := t.QueryRow(ctx, lockLiveContext, sid.UUID().String()).Scan(&cid, &session, &account, &region, &player, &generation, &created, &ended, &reason, &lv)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	cID, err := parseContextID(cid)
	if err != nil {
		return nil, err
	}
	sID, err := parseSessionID(session)
	if err != nil {
		return nil, err
	}
	aID, err := parseAccountID(account)
	if err != nil {
		return nil, err
	}
	et, err := nullableTime(ended)
	if err != nil {
		return nil, err
	}
	rsn, err := nullableString(reason)
	if err != nil {
		return nil, err
	}
	c := identity.GameplayContext{ID: cID, SessionID: sID, AccountID: aID, LogicalServerID: identity.LogicalServerID(region), PlayerID: identity.PlayerID(player), ContextGeneration: generation, CreatedAt: created.UTC(), EndedAt: et, EndReason: rsn, LivenessVersion: lv}
	return &c, nil
}
func (Store) SaveRevokedSessionTx(ctx context.Context, t tx.Tx, s identity.Session, expected int64) error {
	tag, err := t.Exec(ctx, saveRevokedSession, s.ID.UUID().String(), optionalTime(s.RevokedAt), optionalString(s.RevocationReason), s.LivenessVersion, expected)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("session revocation version lost")
	}
	return nil
}
func (Store) SaveEndedContextTx(ctx context.Context, t tx.Tx, c identity.GameplayContext, expected int64) error {
	tag, err := t.Exec(ctx, saveEndedContext, c.ID.UUID().String(), optionalTime(c.EndedAt), optionalString(c.EndReason), c.LivenessVersion, expected)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("context revocation version lost")
	}
	return nil
}
func (Store) RevokeSessionCredentialsTx(ctx context.Context, t tx.Tx, sid identity.SessionID, at time.Time) error {
	_, err := t.Exec(ctx, revokeSessionCredentials, sid.UUID().String(), at.UTC())
	return err
}
func (Store) RevokeGameplayCredentialsTx(ctx context.Context, t tx.Tx, sid identity.SessionID, at time.Time) error {
	_, err := t.Exec(ctx, revokeGameplayCredentials, sid.UUID().String(), at.UTC())
	return err
}
func (Store) TouchSessionActivityTx(ctx context.Context, t tx.Tx, sid identity.SessionID, cutoff, now time.Time) (bool, error) {
	tag, err := t.Exec(ctx, touchSessionActivity, sid.UUID().String(), cutoff.UTC(), now.UTC())
	if err != nil {
		return false, err
	}
	return tag.RowsAffected() == 1, nil
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
func parseBindingID(s string) (identity.BindingID, error) {
	u, e := ids.ParseUUID(s)
	if e != nil {
		return identity.BindingID{}, fmt.Errorf("binding uuid: %w", e)
	}
	return identity.BindingIDFrom(u)
}
func optionalTime(t *time.Time) any {
	if t == nil {
		return nil
	}
	return t.UTC()
}
func optionalString(s string) any {
	if s == "" {
		return nil
	}
	return s
}
func nullableTime(v any) (*time.Time, error) {
	if v == nil {
		return nil, nil
	}
	switch x := v.(type) {
	case time.Time:
		y := x.UTC()
		return &y, nil
	case *time.Time:
		if x == nil {
			return nil, nil
		}
		y := x.UTC()
		return &y, nil
	default:
		return nil, fmt.Errorf("unexpected nullable time %T", v)
	}
}
func nullableString(v any) (string, error) {
	if v == nil {
		return "", nil
	}
	switch x := v.(type) {
	case string:
		return x, nil
	case *string:
		if x == nil {
			return "", nil
		}
		return *x, nil
	default:
		return "", fmt.Errorf("unexpected nullable string %T", v)
	}
}
func nullableInt64(v any) (*int64, error) {
	if v == nil {
		return nil, nil
	}
	switch x := v.(type) {
	case int64:
		y := x
		return &y, nil
	case int32:
		y := int64(x)
		return &y, nil
	case *int64:
		if x == nil {
			return nil, nil
		}
		y := *x
		return &y, nil
	default:
		return nil, fmt.Errorf("unexpected nullable int64 %T", v)
	}
}
