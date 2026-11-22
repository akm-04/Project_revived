package operatoragent

import (
	"sync"
	"time"
)

// SessionLifetime is how long an agent session token stays valid. The token
// lives only in agent memory, so an agent restart logs every CLI out.
const SessionLifetime = 12 * time.Hour

// Sessions holds the live CLI sessions.
type Sessions struct {
	mutex  sync.Mutex
	tokens map[string]time.Time
	now    func() time.Time
}

// NewSessions takes the clock so expiry is testable.
func NewSessions(now func() time.Time) *Sessions {
	return &Sessions{tokens: map[string]time.Time{}, now: now}
}

// Login mints a session token and returns its expiry.
func (sessions *Sessions) Login() (string, time.Time, error) {
	token, err := NewToken()
	if err != nil {
		return "", time.Time{}, err
	}
	expiresAt := sessions.now().Add(SessionLifetime)
	sessions.mutex.Lock()
	defer sessions.mutex.Unlock()
	sessions.tokens[token] = expiresAt
	return token, expiresAt, nil
}

// Authorize accepts only an unexpired token.
func (sessions *Sessions) Authorize(token string) bool {
	if token == "" {
		return false
	}
	sessions.mutex.Lock()
	defer sessions.mutex.Unlock()
	expiresAt, found := sessions.tokens[token]
	if !found {
		return false
	}
	if !sessions.now().Before(expiresAt) {
		delete(sessions.tokens, token)
		return false
	}
	return true
}

// Logout forgets a token.
func (sessions *Sessions) Logout(token string) {
	sessions.mutex.Lock()
	defer sessions.mutex.Unlock()
	delete(sessions.tokens, token)
}
