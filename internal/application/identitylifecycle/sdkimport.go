package identitylifecycle

import (
	"context"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// SDKImportInput is the stand-in's accounts file (G51F F4): accounts, logins
// with their password records copied as-is, and device bindings.
type SDKImportInput struct {
	Accounts []SDKImportAccount `json:"accounts"`
	Logins   []SDKImportLogin   `json:"logins"`
	Devices  []SDKImportDevice  `json:"devices"`
}

type SDKImportAccount struct {
	UID      string    `json:"uid"`
	Type     string    `json:"type"`
	Username string    `json:"username"`
	Created  time.Time `json:"created"`
}

type SDKImportLogin struct {
	Normalized        string    `json:"normalized"`
	Display           string    `json:"display"`
	AccountUID        string    `json:"account_uid"`
	Algorithm         string    `json:"algorithm"`
	Iterations        int       `json:"iterations"`
	Salt              string    `json:"salt"`
	Hash              string    `json:"hash"`
	Created           time.Time `json:"created"`
	PasswordChangedAt time.Time `json:"password_changed_at"`
}

type SDKImportDevice struct {
	DeviceID   string `json:"device_id"`
	AccountUID string `json:"account_uid"`
}

// SDKImportResult is the counts-only output; it never carries a name, secret
// or hash.
type SDKImportResult struct {
	AccountsImported int `json:"accounts_imported"`
	AccountsSkipped  int `json:"accounts_skipped"`
	LoginsImported   int `json:"logins_imported"`
	LoginsSkipped    int `json:"logins_skipped"`
	DevicesImported  int `json:"devices_imported"`
	DevicesSkipped   int `json:"devices_skipped"`
	Conflicts        int `json:"conflicts"`
}

// DecodeSDKImport reads and validates the file. A malformed record refuses the
// whole import before any write.
func DecodeSDKImport(reader io.Reader) (SDKImportInput, error) {
	var input SDKImportInput
	decoder := json.NewDecoder(reader)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&input); err != nil {
		return SDKImportInput{}, fmt.Errorf("sdk import file: %w", err)
	}
	if err := input.validate(); err != nil {
		return SDKImportInput{}, err
	}
	return input, nil
}

func (input SDKImportInput) validate() error {
	logins := map[string]struct{}{}
	for index, account := range input.Accounts {
		if _, err := ids.ParseUUID(account.UID); err != nil {
			return fmt.Errorf("accounts[%d]: uid is not a uuid", index)
		}
		if account.Type != SDKAccountKindNormal && account.Type != SDKAccountKindGuest {
			return fmt.Errorf("accounts[%d]: type must be normal or guest", index)
		}
		if strings.TrimSpace(account.Username) == "" {
			return fmt.Errorf("accounts[%d]: username required", index)
		}
	}
	for index, login := range input.Logins {
		normalized := NormalizeSDKLogin(login.Normalized)
		if normalized == "" || NormalizeSDKLogin(login.Display) == "" {
			return fmt.Errorf("logins[%d]: normalized and display required", index)
		}
		if _, err := ids.ParseUUID(login.AccountUID); err != nil {
			return fmt.Errorf("logins[%d]: account_uid is not a uuid", index)
		}
		if login.Algorithm != SDKPasswordAlgorithm || login.Iterations <= 0 {
			return fmt.Errorf("logins[%d]: unsupported password algorithm or iteration count", index)
		}
		if _, err := hex.DecodeString(login.Salt); err != nil {
			return fmt.Errorf("logins[%d]: salt is not hex", index)
		}
		if _, err := hex.DecodeString(login.Hash); err != nil {
			return fmt.Errorf("logins[%d]: hash is not hex", index)
		}
		if _, duplicate := logins[normalized]; duplicate {
			return fmt.Errorf("logins[%d]: duplicate normalized login", index)
		}
		logins[normalized] = struct{}{}
	}
	devices := map[string]struct{}{}
	for index, device := range input.Devices {
		if strings.TrimSpace(device.DeviceID) == "" {
			return fmt.Errorf("devices[%d]: device_id required", index)
		}
		if _, err := ids.ParseUUID(device.AccountUID); err != nil {
			return fmt.Errorf("devices[%d]: account_uid is not a uuid", index)
		}
		if _, duplicate := devices[device.DeviceID]; duplicate {
			return fmt.Errorf("devices[%d]: duplicate device_id", index)
		}
		devices[device.DeviceID] = struct{}{}
	}
	return nil
}

// SDKImportStore is the import port. It is narrower than SDKStore because the
// one-time import never issues a session.
type SDKImportStore interface {
	InsertSDKAccountIfAbsentTx(context.Context, tx.Tx, SDKAccountRecord) (bool, error)
	FindSDKAccountByUIDTx(context.Context, tx.Queryer, string) (*SDKAccountRecord, error)
	InsertSDKLoginTx(context.Context, tx.Tx, SDKLoginRecord) (bool, error)
	FindSDKLoginTx(context.Context, tx.Queryer, string) (*SDKLoginRecord, error)
	InsertSDKDeviceTx(context.Context, tx.Tx, string, identity.AccountID) (bool, error)
	FindSDKAccountByDeviceTx(context.Context, tx.Queryer, string) (*SDKAccountRecord, error)
}

// SDKImporter applies the stand-in accounts file in one transaction. An
// already present account, login or device with the same binding is skipped; a
// conflicting binding is reported and skipped.
type SDKImporter struct {
	Runner     tx.Runner
	Store      SDKImportStore
	Operations operation.Factory
}

func (importer SDKImporter) Import(ctx context.Context, input SDKImportInput) (SDKImportResult, error) {
	if importer.Runner.DB == nil || importer.Store == nil {
		return SDKImportResult{}, ErrServicePortsIncomplete
	}
	if err := input.validate(); err != nil {
		return SDKImportResult{}, err
	}
	op, err := importer.Operations.New(policy.Set{})
	if err != nil {
		return SDKImportResult{}, err
	}
	var out SDKImportResult
	_, err = importer.Runner.Run(ctx, op, DefaultProfile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(txctx context.Context, scope tx.Scope) error {
		out = SDKImportResult{}
		for _, imported := range input.Accounts {
			if err := importer.importAccount(txctx, scope.Tx, imported, op.StartedAt, &out); err != nil {
				return err
			}
		}
		for _, imported := range input.Logins {
			if err := importer.importLogin(txctx, scope.Tx, imported, op.StartedAt, &out); err != nil {
				return err
			}
		}
		for _, imported := range input.Devices {
			if err := importer.importDevice(txctx, scope.Tx, imported, &out); err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return SDKImportResult{}, err
	}
	return out, nil
}

func (importer SDKImporter) importAccount(ctx context.Context, transaction tx.Tx, imported SDKImportAccount, at time.Time, out *SDKImportResult) error {
	accountID, err := sdkAccountIDFrom(imported.UID)
	if err != nil {
		return err
	}
	created := imported.Created
	if created.IsZero() {
		created = at
	}
	account := SDKAccountRecord{ID: accountID, UID: imported.UID, Kind: imported.Type, Username: imported.Username, Active: true, CreatedAt: created}
	inserted, err := importer.Store.InsertSDKAccountIfAbsentTx(ctx, transaction, account)
	if err != nil {
		return err
	}
	if inserted {
		out.AccountsImported++
		return nil
	}
	existing, err := importer.Store.FindSDKAccountByUIDTx(ctx, transaction, imported.UID)
	if err != nil {
		return err
	}
	if existing != nil && existing.Kind == account.Kind && existing.Username == account.Username {
		out.AccountsSkipped++
		return nil
	}
	out.Conflicts++
	return nil
}

func (importer SDKImporter) importLogin(ctx context.Context, transaction tx.Tx, imported SDKImportLogin, at time.Time, out *SDKImportResult) error {
	account, err := importer.Store.FindSDKAccountByUIDTx(ctx, transaction, imported.AccountUID)
	if err != nil {
		return err
	}
	if account == nil {
		out.Conflicts++
		return nil
	}
	created := imported.Created
	if created.IsZero() {
		created = at
	}
	changed := imported.PasswordChangedAt
	if changed.IsZero() {
		changed = created
	}
	record := SDKLoginRecord{
		Normalized: NormalizeSDKLogin(imported.Normalized), Display: imported.Display, Account: *account,
		Algorithm: imported.Algorithm, Iterations: imported.Iterations, SaltHex: imported.Salt, HashHex: imported.Hash,
		CreatedAt: created, PasswordChangedAt: changed,
	}
	inserted, err := importer.Store.InsertSDKLoginTx(ctx, transaction, record)
	if err != nil {
		return err
	}
	if inserted {
		out.LoginsImported++
		return nil
	}
	existing, err := importer.Store.FindSDKLoginTx(ctx, transaction, record.Normalized)
	if err != nil {
		return err
	}
	if existing != nil && existing.Account.ID == account.ID {
		out.LoginsSkipped++
		return nil
	}
	out.Conflicts++
	return nil
}

func (importer SDKImporter) importDevice(ctx context.Context, transaction tx.Tx, imported SDKImportDevice, out *SDKImportResult) error {
	account, err := importer.Store.FindSDKAccountByUIDTx(ctx, transaction, imported.AccountUID)
	if err != nil {
		return err
	}
	if account == nil {
		out.Conflicts++
		return nil
	}
	inserted, err := importer.Store.InsertSDKDeviceTx(ctx, transaction, imported.DeviceID, account.ID)
	if err != nil {
		return err
	}
	if inserted {
		out.DevicesImported++
		return nil
	}
	existing, err := importer.Store.FindSDKAccountByDeviceTx(ctx, transaction, imported.DeviceID)
	if err != nil {
		return err
	}
	if existing != nil && existing.ID == account.ID {
		out.DevicesSkipped++
		return nil
	}
	out.Conflicts++
	return nil
}

func sdkAccountIDFrom(uid string) (identity.AccountID, error) {
	value, err := ids.ParseUUID(uid)
	if err != nil {
		return identity.AccountID{}, errors.New("sdk import account uid is not a uuid")
	}
	return identity.AccountIDFrom(value)
}
