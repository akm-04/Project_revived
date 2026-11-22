package operatoragent

import (
	"crypto/sha256"
	"crypto/subtle"
	"sync"
	"time"
)

// SessionLifetime is how long an agent session token stays valid. The token
// lives only in agent memory, so an agent restart logs every CLI out.
const SessionLifetime = 12 * time.Hour

// Sessions holds the live CLI sessions. The map is keyed by the SHA-256 of the
// token, so a raw token never sits in a map compared at variable time.
type Sessions struct {
	mutex  sync.Mutex
	tokens map[[sha256.Size]byte]session
	now    func() time.Time
}

type session struct {
	hash       [sha256.Size]byte
	generation string
	expiresAt  time.Time
}

// NewSessions takes the clock so expiry is testable.
func NewSessions(now func() time.Time) *Sessions {
	return &Sessions{tokens: map[[sha256.Size]byte]session{}, now: now}
}

// Login mints a session token bound to the password generation it logged in
// with and returns its expiry.
func (sessions *Sessions) Login(generation string) (string, time.Time, error) {
	token, err := NewToken()
	if err != nil {
		return "", time.Time{}, err
	}
	hash := sha256.Sum256([]byte(token))
	expiresAt := sessions.now().Add(SessionLifetime)
	sessions.mutex.Lock()
	defer sessions.mutex.Unlock()
	sessions.tokens[hash] = session{hash: hash, generation: generation, expiresAt: expiresAt}
	return token, expiresAt, nil
}

// Authorize accepts only an unexpired token whose password generation still
// matches; a password change or offline reset therefore ends every live session.
func (sessions *Sessions) Authorize(token, generation string) bool {
	if token == "" {
		return false
	}
	hash := sha256.Sum256([]byte(token))
	sessions.mutex.Lock()
	defer sessions.mutex.Unlock()
	record, found := sessions.tokens[hash]
	if !found {
		return false
	}
	if subtle.ConstantTimeCompare(record.hash[:], hash[:]) != 1 {
		return false
	}
	if subtle.ConstantTimeCompare([]byte(record.generation), []byte(generation)) != 1 {
		return false
	}
	if !sessions.now().Before(record.expiresAt) {
		delete(sessions.tokens, hash)
		return false
	}
	return true
}

// Logout forgets a token.
func (sessions *Sessions) Logout(token string) {
	hash := sha256.Sum256([]byte(token))
	sessions.mutex.Lock()
	defer sessions.mutex.Unlock()
	delete(sessions.tokens, hash)
}
