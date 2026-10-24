package identity

import (
	"errors"
	"time"
)

var (
	ErrPrincipalAlreadyBound    = errors.New("provider principal already bound to another account")
	ErrPrincipalBindingDisabled = errors.New("provider principal binding is disabled")
)

func BindPrincipal(existing *ProviderBinding, candidate ProviderBinding) (ProviderBinding, bool, error) {
	if err := candidate.Principal.Validate(); err != nil {
		return ProviderBinding{}, false, err
	}
	if candidate.ID.UUID().IsZero() || candidate.AccountID.UUID().IsZero() || candidate.LinkedAt.IsZero() {
		return ProviderBinding{}, false, errors.New("invalid provider binding")
	}
	if candidate.DisabledAt != nil {
		return ProviderBinding{}, false, ErrPrincipalBindingDisabled
	}
	if existing == nil {
		return candidate, true, nil
	}
	if existing.Principal != candidate.Principal {
		return ProviderBinding{}, false, errors.New("binding lookup principal mismatch")
	}
	if existing.AccountID != candidate.AccountID {
		return ProviderBinding{}, false, ErrPrincipalAlreadyBound
	}
	if existing.DisabledAt != nil {
		return ProviderBinding{}, false, ErrPrincipalBindingDisabled
	}
	return *existing, false, nil
}

type SessionIssue struct {
	Session    Session
	SID        SessionCredential
	LoginToken SessionCredential
}

func NewSessionIssue(session Session, sid, login SessionCredential) (SessionIssue, error) {
	if session.ID.UUID().IsZero() || session.AccountID.UUID().IsZero() || session.AuthProfile != AuthProductionPair || session.IssuedAt.IsZero() || session.LastActivityAt.IsZero() || session.LivenessVersion < 1 || session.RevokedAt != nil || session.RevocationReason != "" {
		return SessionIssue{}, errors.New("invalid session")
	}
	if session.LastActivityAt.Before(session.IssuedAt) {
		return SessionIssue{}, errors.New("session activity precedes issuance")
	}
	if session.AbsoluteExpiresAt != nil && !session.AbsoluteExpiresAt.After(session.IssuedAt) {
		return SessionIssue{}, errors.New("session absolute expiry must follow issuance")
	}
	if session.IdleTimeoutSeconds != nil && *session.IdleTimeoutSeconds <= 0 {
		return SessionIssue{}, errors.New("session idle timeout must be positive")
	}
	if sid.ID.UUID().IsZero() || login.ID.UUID().IsZero() || sid.SessionID != session.ID || login.SessionID != session.ID || sid.Kind != CredentialSID || login.Kind != CredentialLoginToken || sid.RevokedAt != nil || login.RevokedAt != nil || sid.IssuedAt.IsZero() || login.IssuedAt.IsZero() {
		return SessionIssue{}, errors.New("invalid credential pair")
	}
	if sid.Digest == (CredentialDigest{}) || login.Digest == (CredentialDigest{}) {
		return SessionIssue{}, errors.New("empty credential digest")
	}
	if sid.ExpiresAt != nil && !sid.ExpiresAt.After(sid.IssuedAt) {
		return SessionIssue{}, errors.New("sid expiry must follow issuance")
	}
	if login.ExpiresAt != nil && !login.ExpiresAt.After(login.IssuedAt) {
		return SessionIssue{}, errors.New("login token expiry must follow issuance")
	}
	return SessionIssue{session, sid, login}, nil
}

type GameplayCredential struct {
	ID                   CredentialID
	ContextID            ContextID
	SessionID            SessionID
	Digest               CredentialDigest
	CredentialGeneration int32
	DerivationKeyID      string
	IssuedAt             time.Time
	RevokedAt            *time.Time
}

func (c GameplayCredential) Live() bool { return c.RevokedAt == nil }

// RevokeSession returns a fully durable parent/child revocation plan. Socket
// invalidation is explicitly after commit and not part of this canonical state.
type RevocationPlan struct {
	Session             Session
	Context             *GameplayContext
	SessionCredentials  []SessionCredential
	GameplayCredentials []GameplayCredential
}

func RevokeSession(session Session, context *GameplayContext, sc []SessionCredential, gc []GameplayCredential, now time.Time, reason string) (RevocationPlan, error) {
	if reason == "" {
		return RevocationPlan{}, errors.New("revocation reason required")
	}
	if now.IsZero() || (!session.IssuedAt.IsZero() && now.Before(session.IssuedAt)) {
		return RevocationPlan{}, errors.New("invalid revocation time")
	}
	at := now.UTC()
	out := session
	if out.RevokedAt == nil {
		out.RevokedAt = &at
		out.RevocationReason = reason
		out.LivenessVersion++
	}
	var cx *GameplayContext
	if context != nil {
		c := *context
		if c.SessionID != session.ID || c.AccountID != session.AccountID {
			return RevocationPlan{}, errors.New("child context parent mismatch")
		}
		if !c.CreatedAt.IsZero() && at.Before(c.CreatedAt) {
			return RevocationPlan{}, errors.New("revocation precedes context creation")
		}
		if c.EndedAt == nil {
			c.EndedAt = &at
			c.EndReason = reason
			c.LivenessVersion++
		}
		cx = &c
	}
	scc := append([]SessionCredential(nil), sc...)
	for i := range scc {
		if scc[i].SessionID != session.ID {
			return RevocationPlan{}, errors.New("session credential parent mismatch")
		}
		if scc[i].RevokedAt == nil {
			scc[i].RevokedAt = &at
		}
	}
	gcc := append([]GameplayCredential(nil), gc...)
	for i := range gcc {
		if gcc[i].SessionID != session.ID {
			return RevocationPlan{}, errors.New("gameplay credential parent mismatch")
		}
		if gcc[i].RevokedAt == nil {
			gcc[i].RevokedAt = &at
		}
	}
	return RevocationPlan{out, cx, scc, gcc}, nil
}
