package operatoragent

import (
	"crypto/rand"
	"encoding/hex"
	"sync"
)

// tokenBytes is the size of every agent token (session token and per-start
// operator token): 32 random bytes, hex-encoded.
const tokenBytes = 32

// NewToken returns a fresh random token as 64 hex characters.
func NewToken() (string, error) {
	value := make([]byte, tokenBytes)
	if _, err := rand.Read(value); err != nil {
		return "", err
	}
	return hex.EncodeToString(value), nil
}

// TokenHolder carries the per-start secret the agent hands gxb-api and sends on
// every operator call. The backend replaces it on each start, so the previous
// value is dead the moment a new one is set.
type TokenHolder struct {
	mutex sync.RWMutex
	value string
}

func (holder *TokenHolder) Set(token string) {
	holder.mutex.Lock()
	defer holder.mutex.Unlock()
	holder.value = token
}

func (holder *TokenHolder) Get() string {
	holder.mutex.RLock()
	defer holder.mutex.RUnlock()
	return holder.value
}
