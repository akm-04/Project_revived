package i5

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	EnergyKey               = "energy"
	OccultTicketKey         = "occult_ticket"
	occultEnergyProgressKey = "occult_energy_progress"
)

type occultScalar struct {
	balance economy.ScalarBalance
	exists  bool
}

type occultLedger struct {
	playerID identity.PlayerID
	tickets  occultScalar
	progress occultScalar
}

// lockOccultLedgerTx locks owner 700 and progression 710 before the two scalar
// rows at 720, so the energy row can follow at 721.
func (s Service) lockOccultLedgerTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, op operation.Context) (occultLedger, error) {
	if s.Store == nil || t == nil || !pid.Valid() || op.StartedAt.IsZero() {
		return occultLedger{}, errors.New("invalid occult ledger access")
	}
	now := op.StartedAt.UTC()
	if err := s.Store.LockEconomyOwnerTx(ctx, t, pid); err != nil {
		return occultLedger{}, err
	}
	if _, err := s.Store.LockProgressionTx(ctx, t, pid); err != nil {
		return occultLedger{}, err
	}
	tickets, ticketsExist, err := s.Store.LockScalarTx(ctx, t, pid, OccultTicketKey, now)
	if err != nil {
		return occultLedger{}, err
	}
	progress, progressExists, err := s.Store.LockScalarTx(ctx, t, pid, occultEnergyProgressKey, now)
	if err != nil {
		return occultLedger{}, err
	}
	return occultLedger{playerID: pid, tickets: occultScalar{tickets, ticketsExist}, progress: occultScalar{progress, progressExists}}, nil
}

func (s Service) saveOccultLedgerTx(ctx context.Context, t tx.Tx, ledger occultLedger, spent int64, now time.Time) error {
	tickets, progress := occult.AccrueTickets(ledger.tickets.balance.Amount, ledger.progress.balance.Amount, spent)
	if err := s.writeOccultScalarTx(ctx, t, ledger.playerID, OccultTicketKey, ledger.tickets, tickets, now); err != nil {
		return err
	}
	return s.writeOccultScalarTx(ctx, t, ledger.playerID, occultEnergyProgressKey, ledger.progress, progress, now)
}

func (s Service) writeOccultScalarTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, key string, current occultScalar, amount int64, now time.Time) error {
	unchanged := current.balance.Amount == amount
	if unchanged && (current.exists || amount == 0) {
		return nil
	}
	next := economy.ScalarBalance{PlayerID: pid, ResourceKey: key, Amount: amount, StateVersion: 1, UpdatedAt: now}
	if current.exists {
		next.StateVersion = current.balance.StateVersion + 1
	}
	return s.Store.SaveScalarTx(ctx, t, next, current.exists)
}

// OccultTickets is the ticket count and the energy carried toward the next one.
type OccultTickets struct{ Tickets, Progress int64 }

// OccultTicketPort is the only way a mode reads or spends Occult tickets.
type OccultTicketPort interface {
	OccultTicketsTx(context.Context, tx.Queryer, identity.PlayerID) (OccultTickets, error)
	DebitOccultTicketTx(context.Context, tx.Tx, identity.PlayerID, operation.Context) (OccultTickets, error)
}

func (s Service) OccultTicketsTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) (OccultTickets, error) {
	if s.Store == nil || q == nil || !pid.Valid() {
		return OccultTickets{}, errors.New("invalid occult ledger access")
	}
	tickets, _, err := s.Store.ReadScalarTx(ctx, q, pid, OccultTicketKey)
	if err != nil {
		return OccultTickets{}, err
	}
	progress, _, err := s.Store.ReadScalarTx(ctx, q, pid, occultEnergyProgressKey)
	if err != nil {
		return OccultTickets{}, err
	}
	return OccultTickets{Tickets: tickets.Amount, Progress: progress.Amount}, nil
}

// DebitOccultTicketTx spends one ticket or fails with ErrInsufficientBalance;
// the energy carried toward the next ticket is untouched.
func (s Service) DebitOccultTicketTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, op operation.Context) (OccultTickets, error) {
	ledger, err := s.lockOccultLedgerTx(ctx, t, pid, op)
	if err != nil {
		return OccultTickets{}, err
	}
	if ledger.tickets.balance.Amount < 1 {
		return OccultTickets{}, economy.ErrInsufficientBalance
	}
	remaining := ledger.tickets.balance.Amount - 1
	if err = s.writeOccultScalarTx(ctx, t, pid, OccultTicketKey, ledger.tickets, remaining, op.StartedAt.UTC()); err != nil {
		return OccultTickets{}, err
	}
	return OccultTickets{Tickets: remaining, Progress: ledger.progress.balance.Amount}, nil
}
