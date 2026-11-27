package identitylifecycle

import (
	"context"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"sort"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// SDKImportInput is the stand-in's accounts file (G51F F4) after decoding:
// accounts, logins with their password records copied as-is, and device
// bindings. The file itself is the map-shaped document that sdk.py writes.
type SDKImportInput struct {
	Accounts []SDKImportAccount
	Logins   []SDKImportLogin
	Devices  []SDKImportDevice
	// UnresolvedLogins counts logins rows whose uid has no account or whose
	// account has no password record; the import reports them as conflicts.
	UnresolvedLogins int
}

const sdkImportVersion = 1

// sdkImportFile mirrors the stand-in's on-disk document: a version plus three
// maps keyed by uid, normalized login and device id.
type sdkImportFile struct {
	Version  int                             `json:"version"`
	Accounts map[string]sdkImportFileAccount `json:"accounts"`
	Logins   map[string]string               `json:"logins"`
	Devices  map[string]string               `json:"devices"`
}

type sdkImportFileAccount struct {
	UID         string             `json:"uid"`
	Login       string             `json:"login"`
	Username    string             `json:"username"`
	AccountType string             `json:"account_type"`
	CreatedAt   int64              `json:"created_at"`
	Password    *sdkImportPassword `json:"password"`
	Session     json.RawMessage    `json:"session"`
}

type sdkImportPassword struct {
	Algorithm  string `json:"algorithm"`
	Iterations int    `json:"iterations"`
	Salt       string `json:"salt"`
	Hash       string `json:"hash"`
}

type SDKImportAccount struct {
	UID      string
	Type     string
	Username string
	Created  time.Time
}

type SDKImportLogin struct {
	Normalized        string
	Display           string
	AccountUID        string
	Algorithm         string
	Iterations        int
	Salt              string
	Hash              string
	Created           time.Time
	PasswordChangedAt time.Time
}

type SDKImportDevice struct {
	DeviceID   string
	AccountUID string
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
	var file sdkImportFile
	decoder := json.NewDecoder(reader)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&file); err != nil {
		return SDKImportInput{}, fmt.Errorf("sdk import file: %w", err)
	}
	if file.Version != sdkImportVersion {
		return SDKImportInput{}, fmt.Errorf("sdk import file: unsupported version %d", file.Version)
	}
	input, err := file.toImportInput()
	if err != nil {
		return SDKImportInput{}, err
	}
	if err := input.validate(); err != nil {
		return SDKImportInput{}, err
	}
	return input, nil
}

// toImportInput turns the stand-in's maps into records. A logins row whose uid
// has no account, or whose account has no password record, is skipped and
// counted; the import reports it as a conflict.
func (file sdkImportFile) toImportInput() (SDKImportInput, error) {
	var input SDKImportInput
	for _, uid := range sortedSDKImportKeys(file.Accounts) {
		account := file.Accounts[uid]
		if account.UID != uid {
			return SDKImportInput{}, fmt.Errorf("sdk import file: account key %q holds uid %q", uid, account.UID)
		}
		input.Accounts = append(input.Accounts, SDKImportAccount{
			UID:      account.UID,
			Type:     account.AccountType,
			Username: account.Username,
			Created:  time.Unix(account.CreatedAt, 0).UTC(),
		})
	}
	for _, normalized := range sortedSDKImportKeys(file.Logins) {
		accountUID := file.Logins[normalized]
		account, found := file.Accounts[accountUID]
		if !found || account.Password == nil {
			input.UnresolvedLogins++
			continue
		}
		created := time.Unix(account.CreatedAt, 0).UTC()
		input.Logins = append(input.Logins, SDKImportLogin{
			Normalized:        normalized,
			Display:           account.Login,
			AccountUID:        accountUID,
			Algorithm:         account.Password.Algorithm,
			Iterations:        account.Password.Iterations,
			Salt:              account.Password.Salt,
			Hash:              account.Password.Hash,
			Created:           created,
			PasswordChangedAt: created,
		})
	}
	for _, deviceID := range sortedSDKImportKeys(file.Devices) {
		input.Devices = append(input.Devices, SDKImportDevice{DeviceID: deviceID, AccountUID: file.Devices[deviceID]})
	}
	return input, nil
}

func sortedSDKImportKeys[Value any](values map[string]Value) []string {
	keys := make([]string, 0, len(values))
	for key := range values {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	return keys
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
		if login.Algorithm != SDKPasswordAlgorithm {
			return fmt.Errorf("logins[%d]: unsupported password algorithm", index)
		}
		salt, err := hex.DecodeString(login.Salt)
		if err != nil {
			return fmt.Errorf("logins[%d]: salt is not hex", index)
		}
		if len(salt) != SDKPasswordSaltBytes {
			return fmt.Errorf("logins[%d]: salt must be %d bytes", index, SDKPasswordSaltBytes)
		}
		hash, err := hex.DecodeString(login.Hash)
		if err != nil {
			return fmt.Errorf("logins[%d]: hash is not hex", index)
		}
		if len(hash) != SDKPasswordHashBytes {
			return fmt.Errorf("logins[%d]: hash must be %d bytes", index, SDKPasswordHashBytes)
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
	// BackfillSDKAccountMetadataTx fills the fields a pre-SDK account still
	// holds at their migration defaults and never overwrites a set value.
	BackfillSDKAccountMetadataTx(context.Context, tx.Tx, SDKAccountRecord) error
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
		out = SDKImportResult{Conflicts: input.UnresolvedLogins}
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
	if existing == nil {
		out.Conflicts++
		return nil
	}
	reconciled := *existing
	if reconciled.Kind == SDKAccountKindNormal {
		reconciled.Kind = account.Kind
	}
	if reconciled.Username == "" {
		reconciled.Username = account.Username
	}
	if reconciled.Kind != account.Kind || reconciled.Username != account.Username {
		out.Conflicts++
		return nil
	}
	if reconciled.Kind != existing.Kind || reconciled.Username != existing.Username {
		if err := importer.Store.BackfillSDKAccountMetadataTx(ctx, transaction, reconciled); err != nil {
			return err
		}
	}
	out.AccountsSkipped++
	return nil
}

func (importer SDKImporter) importLogin(ctx context.Context, transaction tx.Tx, imported SDKImportLogin, at time.Time, out *SDKImportResult) error {
	if !sdkPasswordIterationsAcceptable(imported.Iterations) {
		out.Conflicts++
		return nil
	}
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
	if account.Kind != SDKAccountKindGuest {
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
