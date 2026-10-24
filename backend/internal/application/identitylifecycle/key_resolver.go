package identitylifecycle

import (
	"context"
	"errors"
)

// BearerDerivationKey is server-held secret material selected by immutable key
// ID. Secret bytes must never be persisted in gameplay/session rows or receipts.
type BearerDerivationKey struct {
	ID     string
	Secret []byte
}

func (k BearerDerivationKey) Validate() error {
	if k.ID == "" {
		return errors.New("bearer derivation key id required")
	}
	if len(k.Secret) < 16 {
		return errors.New("bearer derivation secret too short")
	}
	return nil
}

// BearerKeyResolver is the typed seam required for restart-safe/versioned
// bearer re-derivation. Rotation policy and provider integration remain later
// concerns; unsupported historical keys fail closed.
type BearerKeyResolver interface {
	ResolveBearerKey(context.Context, string) (BearerDerivationKey, error)
}

// StaticBearerKeyResolver is suitable for the current single-key deployment
// and tests. R2A exposes the seam without inventing a rotation schedule.
type StaticBearerKeyResolver struct{ Key BearerDerivationKey }

func (r StaticBearerKeyResolver) ResolveBearerKey(_ context.Context, id string) (BearerDerivationKey, error) {
	if err := r.Key.Validate(); err != nil {
		return BearerDerivationKey{}, err
	}
	if id != r.Key.ID {
		return BearerDerivationKey{}, errors.New("unknown bearer derivation key")
	}
	out := r.Key
	out.Secret = append([]byte(nil), r.Key.Secret...)
	return out, nil
}

// KeyringBearerKeyResolver is a bounded in-process resolver for active plus
// retained verify-only derivation keys. It defines no rotation schedule or
// external secret provider; those remain operational concerns outside R6.
type KeyringBearerKeyResolver struct {
	Keys map[string]BearerDerivationKey
}

func (r KeyringBearerKeyResolver) ResolveBearerKey(_ context.Context, id string) (BearerDerivationKey, error) {
	k, ok := r.Keys[id]
	if !ok {
		return BearerDerivationKey{}, errors.New("unknown bearer derivation key")
	}
	if err := k.Validate(); err != nil {
		return BearerDerivationKey{}, err
	}
	if k.ID != id {
		return BearerDerivationKey{}, errors.New("bearer derivation key id mismatch")
	}
	out := k
	out.Secret = append([]byte(nil), k.Secret...)
	return out, nil
}
