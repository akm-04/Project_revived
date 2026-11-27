package otastore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	appota "gxb.local/backend/v2/internal/application/otarelease"
	"gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var errInvalid = errors.New("otastore: invalid input")

// Store owns the ota_settings history row and the ota.status ledger read. The
// release and activation rows themselves live in the OTA root's releases.json.
type Store struct{}

const (
	seedSettings = `INSERT INTO ota_settings (settings, revision, updated_at) VALUES ($1::jsonb, 0, $2) ON CONFLICT (singleton) DO NOTHING`
	lockSettings = `SELECT settings::text, revision FROM ota_settings WHERE singleton FOR UPDATE`
	saveSettings = `UPDATE ota_settings SET settings=$1::jsonb, revision=$2, command_key=$3, updated_at=$4 WHERE singleton AND revision=$2-1`
)

// LockSettingsTx seeds the row from the current settings.json value when it
// is missing, then locks it (OA-6).
func (Store) LockSettingsTx(ctx context.Context, transaction tx.Tx, seed otarelease.Settings, at time.Time) (appota.SettingsRecord, error) {
	if transaction == nil {
		return appota.SettingsRecord{}, errInvalid
	}
	seedJSON, err := json.Marshal(seed)
	if err != nil {
		return appota.SettingsRecord{}, err
	}
	if _, err := transaction.Exec(ctx, seedSettings, string(seedJSON), at.UTC()); err != nil {
		return appota.SettingsRecord{}, err
	}
	record, err := scanSettings(transaction.QueryRow(ctx, lockSettings))
	if err != nil {
		return appota.SettingsRecord{}, err
	}
	return *record, nil
}

// SaveSettingsTx writes the next revision; the row must still hold the one
// before it, or the write is an error (the caller holds the row lock).
func (Store) SaveSettingsTx(ctx context.Context, transaction tx.Tx, record appota.SettingsRecord, commandKey string, at time.Time) error {
	if transaction == nil || commandKey == "" || record.Revision < 1 {
		return errInvalid
	}
	settingsJSON, err := json.Marshal(record.Settings)
	if err != nil {
		return err
	}
	tag, err := transaction.Exec(ctx, saveSettings, string(settingsJSON), record.Revision, commandKey, at.UTC())
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("otastore: ota_settings revision moved under the row lock")
	}
	return nil
}

func scanSettings(row tx.Row) (*appota.SettingsRecord, error) {
	var raw string
	var record appota.SettingsRecord
	if err := row.Scan(&raw, &record.Revision); err != nil {
		return nil, err
	}
	settings, err := otarelease.ParseSettings([]byte(raw))
	if err != nil {
		return nil, err
	}
	record.Settings = settings
	return &record, nil
}
