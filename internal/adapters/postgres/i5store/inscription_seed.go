package i5store

import (
	"context"
	"encoding/hex"
	"errors"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

const InscriptionSeedPolicy = "C2F_EMPTY_ZERO_PRESERVATION_SEED_V1"

func (s Store) EnsureInscriptionCertificatesTx(ctx context.Context, t tx.Tx, p identity.PlayerID, rev string, at time.Time) error {
	if !p.Valid() || len(rev) != 64 || at.IsZero() {
		return errors.New("inscription seed: invalid scope")
	}
	if e := s.LockEconomyOwnerTx(ctx, t, p); e != nil {
		return e
	}
	for _, key := range []string{"degree_cer", "graduate_cer", "patent_cer"} {
		if _, _, e := s.LockScalarTx(ctx, t, p, key, at); e != nil {
			return e
		}
		if _, e := t.Exec(ctx, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,$2,0,1,$3)ON CONFLICT(player_id,resource_key)DO NOTHING`, int64(p), key, at); e != nil {
			return e
		}
	}
	return nil
}

type InscriptionCertificateBootstrap struct{}

func (InscriptionCertificateBootstrap) Name() string   { return "i7c2f.i5-certificate-zero-seed-v1" }
func (InscriptionCertificateBootstrap) Required() bool { return true }
func (InscriptionCertificateBootstrap) PersistCharacterBootstrap(c context.Context, t tx.Tx, b logicalserver.BootstrapContext) error {
	rev, _ := b.Operation.Policies.Get("content")
	return (Store{}).EnsureInscriptionCertificatesTx(c, t, b.PlayerID, rev, b.Operation.StartedAt)
}

var _ appboot.CharacterBootstrapPersistenceContributor = InscriptionCertificateBootstrap{}

// Controlled imports may fill qualified untouched zero seeds once. Gameplay
// never uses this setter; owner receipt/provenance is committed in the caller Tx.
func (s Store) ImportInscriptionCertificatesTx(c context.Context, t tx.Tx, p identity.PlayerID, amounts [3]int64, source string, at time.Time) error {
	raw, e := hex.DecodeString(source)
	if e != nil || len(raw) != 32 || at.IsZero() {
		return errors.New("inscription import: provenance required")
	}
	if e = s.LockEconomyOwnerTx(c, t, p); e != nil {
		return e
	}
	next := []economy.ScalarBalance{}
	for i, key := range []string{"degree_cer", "graduate_cer", "patent_cer"} {
		if amounts[i] < 0 || amounts[i] > 9007199254740991 {
			return errors.New("inscription import: invalid amount")
		}
		b, ok, e := s.LockScalarTx(c, t, p, key, at)
		if e != nil {
			return e
		}
		if !ok || b.Amount != 0 || b.StateVersion != 1 || at.Before(b.UpdatedAt) {
			return errors.New("inscription import: target is not untouched zero seed")
		}
		b.Amount = amounts[i]
		b.StateVersion++
		b.UpdatedAt = at
		next = append(next, b)
	}
	for _, b := range next {
		if e = s.SaveScalarTx(c, t, b, true); e != nil {
			return e
		}
	}
	return nil
}
