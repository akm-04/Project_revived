// Package restorestore records whole-database restore history epochs and gates
// service writes until external payments are reconciled (D13).
package restorestore

import (
	"context"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	ErrNoTransaction       = errors.New("nil restore epoch transaction")
	ErrUnreconciledRestore = errors.New("database has an unreconciled restore epoch")
)

type Epoch struct {
	Epoch              int64
	RestoredAt         time.Time
	BackupLabel        string
	Operator           string
	ReconciledAt       *time.Time
	ReconciliationNote string
}

const epochColumns = `epoch,restored_at,backup_label,operator,reconciled_at,reconciliation_note`

const insertEpoch = `INSERT INTO restore_epochs(backup_label,operator) VALUES($1,$2) RETURNING ` + epochColumns

const reconcileEpoch = `UPDATE restore_epochs SET reconciled_at=now(),reconciliation_note=$2 WHERE epoch=$1 AND reconciled_at IS NULL RETURNING ` + epochColumns

const findOpenEpoch = `SELECT ` + epochColumns + ` FROM restore_epochs WHERE reconciled_at IS NULL ORDER BY epoch LIMIT 1`

type Store struct{}

// InsertTx records an open restore epoch. A restore operator starts one before
// the services reopen.
func (Store) InsertTx(ctx context.Context, transaction tx.Tx, backupLabel, operator string) (Epoch, error) {
	if transaction == nil {
		return Epoch{}, ErrNoTransaction
	}
	if backupLabel == "" || operator == "" {
		return Epoch{}, errors.New("restore epoch needs a backup label and an operator")
	}
	return scanEpoch(transaction.QueryRow(ctx, insertEpoch, backupLabel, operator))
}

// ReconcileTx closes one open epoch with the operator's attestation that
// external payments were reconciled. It returns kernelstore.ErrNoRows when the
// epoch is unknown or already reconciled.
func (Store) ReconcileTx(ctx context.Context, transaction tx.Tx, epoch int64, operator, note string) (Epoch, error) {
	if transaction == nil {
		return Epoch{}, ErrNoTransaction
	}
	if epoch <= 0 || operator == "" || note == "" {
		return Epoch{}, errors.New("restore epoch reconcile needs an epoch, an operator and a note")
	}
	return scanEpoch(transaction.QueryRow(ctx, reconcileEpoch, epoch, note))
}

func (Store) OpenEpoch(ctx context.Context, queryer tx.Queryer) (*Epoch, error) {
	epoch, err := scanEpoch(queryer.QueryRow(ctx, findOpenEpoch))
	if errors.Is(err, kernelstore.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &epoch, nil
}

// CheckWritable refuses a service start while any restore epoch is still open,
// so no write runs on unreconciled restored data.
func (s Store) CheckWritable(ctx context.Context, queryer tx.Queryer) error {
	open, err := s.OpenEpoch(ctx, queryer)
	if err != nil {
		return fmt.Errorf("restore epoch startup check: %w", err)
	}
	if open == nil {
		return nil
	}
	return fmt.Errorf("%w %d (backup %q, operator %q, restored %s): reconcile external payments with gxb-admin restore-epoch reconcile before starting",
		ErrUnreconciledRestore, open.Epoch, open.BackupLabel, open.Operator, open.RestoredAt.UTC().Format(time.RFC3339))
}

func scanEpoch(row tx.Row) (Epoch, error) {
	var epoch Epoch
	var reconciledAt *time.Time
	var note *string
	if err := row.Scan(&epoch.Epoch, &epoch.RestoredAt, &epoch.BackupLabel, &epoch.Operator, &reconciledAt, &note); err != nil {
		return Epoch{}, err
	}
	epoch.ReconciledAt = reconciledAt
	if note != nil {
		epoch.ReconciliationNote = *note
	}
	return epoch, nil
}
