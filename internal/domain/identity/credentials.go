package identity

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"time"
)

func DigestCredential(secret []byte, label, raw string) (CredentialDigest, error) {
	if len(secret) < 16 {
		return CredentialDigest{}, errors.New("credential digest secret too short")
	}
	if label == "" || raw == "" {
		return CredentialDigest{}, errors.New("empty credential input")
	}
	h := hmac.New(sha256.New, secret)
	h.Write([]byte("gxb-v2/credential/v1\x00"))
	h.Write([]byte(label))
	h.Write([]byte{0})
	h.Write([]byte(raw))
	var out CredentialDigest
	copy(out[:], h.Sum(nil))
	return out, nil
}

const GameplayBearerDigestLabel = "GAMEPLAY_BEARER"

// DigestGameplayBearer is the stable at-rest lookup digest for the raw bearer
// injected into stock HTTP/TCP requests. The raw bearer is never persisted.
func DigestGameplayBearer(secret []byte, raw string) (CredentialDigest, error) {
	return DigestCredential(secret, GameplayBearerDigestLabel, raw)
}

// AuthenticatePair enforces the production stock account-auth profile. A generic
// gameplay bearer injected by Backend is intentionally not an input.
func AuthenticatePair(account Account, session Session, sid, login SessionCredential, wantSID, wantLogin CredentialDigest, now time.Time) (Session, error) {
	if !account.Live() || !account.UID.Valid() {
		return Session{}, errors.New("account not live")
	}
	if session.AccountID != account.ID || session.AuthProfile != AuthProductionPair || !session.Live(now) {
		return Session{}, errors.New("session not live")
	}
	if sid.SessionID != session.ID || login.SessionID != session.ID || sid.Kind != CredentialSID || login.Kind != CredentialLoginToken {
		return Session{}, errors.New("credential/session mismatch")
	}
	if !sid.Live(now) || !login.Live(now) || !hmac.Equal(sid.Digest[:], wantSID[:]) || !hmac.Equal(login.Digest[:], wantLogin[:]) {
		return Session{}, errors.New("invalid credential pair")
	}
	return session, nil
}

// DeriveGameplayBearer reconstructs a stable raw bearer from immutable context
// identity and generation. The bearer itself never needs persistence.
func DeriveGameplayBearer(secret []byte, c GameplayContext) (string, error) {
	if len(secret) < 16 || c.ID.UUID().IsZero() || c.ContextGeneration < 1 {
		return "", errors.New("invalid bearer derivation input")
	}
	h := hmac.New(sha256.New, secret)
	h.Write([]byte("gxb-v2/gameplay-bearer/v1\x00"))
	b := c.ID.UUID().Bytes()
	h.Write(b[:])
	h.Write([]byte{0})
	var gen [8]byte
	for i := 7; i >= 0; i-- {
		gen[i] = byte(c.ContextGeneration)
		c.ContextGeneration >>= 8
	}
	h.Write(gen[:])
	return base64.RawURLEncoding.EncodeToString(h.Sum(nil)), nil
}
