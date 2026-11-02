package guildrental

import (
	"context"
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type guardTx struct{}
type guardRow struct{}

func (guardTx) QueryRow(context.Context, string, ...any) tx.Row             { return guardRow{} }
func (guardTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return guardTag{}, nil }
func (guardTx) Commit(context.Context) error                                { return nil }
func (guardTx) Rollback(context.Context) error                              { return nil }
func (guardRow) Scan(...any) error                                          { return errors.New("unexpected scan") }

type guardTag struct{}

func (guardTag) RowsAffected() int64 { return 1 }

type offeredStore struct{ offered bool }

func (s offeredStore) LockRentalOfferTx(context.Context, tx.Tx, identity.PlayerID, guild.RentalKind, int64) (guild.RentalOffer, bool, error) {
	return guild.RentalOffer{}, s.offered, nil
}

func TestReferenceGuardRefusesOnlyAnOpenOffer(t *testing.T) {
	ref := character.HeroRef{PlayerID: 7, PartnerID: 11}
	for _, offered := range []bool{true, false} {
		guard := ReferenceGuard{Store: offeredStore{offered: offered}, PlayerID: ref.PlayerID}
		plan, err := guard.PreflightHeroRemovalTx(context.Background(), nil, ref)
		if err != nil {
			t.Fatal("preflight", offered, err)
		}
		err = guard.ValidateHeroRemovalLockedTx(context.Background(), guardTx{}, ref, plan)
		if offered && !errors.Is(err, characterasset.ErrReferenceInUse) {
			t.Fatal("open offer must block removal", err)
		}
		if !offered && err != nil {
			t.Fatal("closed offer must allow removal", err)
		}
	}
}
