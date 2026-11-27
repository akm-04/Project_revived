package identitylifecycle

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// sdkLegacyImportStore models the account row the SDK cut-over meets: the row
// predates the SDK columns, so the insert does nothing and the row still holds
// the migration defaults.
type sdkLegacyImportStore struct {
	sdkProbeStore
	account   SDKAccountRecord
	backfills int
}

func (*sdkLegacyImportStore) InsertSDKAccountIfAbsentTx(context.Context, tx.Tx, SDKAccountRecord) (bool, error) {
	return false, nil
}

func (store *sdkLegacyImportStore) FindSDKAccountByUIDTx(context.Context, tx.Queryer, string) (*SDKAccountRecord, error) {
	return &store.account, nil
}

func (store *sdkLegacyImportStore) BackfillSDKAccountMetadataTx(_ context.Context, _ tx.Tx, account SDKAccountRecord) error {
	store.account.Kind = account.Kind
	store.account.Username = account.Username
	store.backfills++
	return nil
}

func runSDKLegacyImport(t *testing.T, store *sdkLegacyImportStore, kind string) SDKImportResult {
	t.Helper()
	importer := SDKImporter{
		Runner:     tx.Runner{DB: sdkProbeBeginner{commits: make(chan struct{}, 8)}},
		Store:      store,
		Operations: operation.Factory{Clock: clock.System{}},
	}
	result, err := importer.Import(context.Background(), SDKImportInput{Accounts: []SDKImportAccount{{
		UID: store.account.UID, Type: kind, Username: "imported-name", Created: time.Now(),
	}}})
	if err != nil {
		t.Fatal(err)
	}
	return result
}

func TestSDKImportBackfillsLegacyAccountDefaults(t *testing.T) {
	for _, kind := range []string{SDKAccountKindNormal, SDKAccountKindGuest} {
		t.Run(kind, func(t *testing.T) {
			accountID, err := newSDKAccountID()
			if err != nil {
				t.Fatal(err)
			}
			store := &sdkLegacyImportStore{account: SDKAccountRecord{
				ID: accountID, UID: accountID.UUID().String(),
				Kind: SDKAccountKindNormal, Active: true, CreatedAt: time.Now(),
			}}
			result := runSDKLegacyImport(t, store, kind)
			if store.account.Kind != kind || store.account.Username != "imported-name" {
				t.Fatalf("legacy account metadata not backfilled: kind=%s username=%q conflicts=%d",
					store.account.Kind, store.account.Username, result.Conflicts)
			}
			if result.Conflicts != 0 || store.backfills != 1 {
				t.Fatalf("import = %+v backfills=%d, want no conflict and one backfill", result, store.backfills)
			}
		})
	}
}

// sdkDeviceImportStore answers the account lookup and counts device inserts.
type sdkDeviceImportStore struct {
	sdkProbeStore
	account       SDKAccountRecord
	deviceInserts int
}

func (store *sdkDeviceImportStore) FindSDKAccountByUIDTx(context.Context, tx.Queryer, string) (*SDKAccountRecord, error) {
	return &store.account, nil
}

func (store *sdkDeviceImportStore) InsertSDKDeviceTx(context.Context, tx.Tx, string, identity.AccountID) (bool, error) {
	store.deviceInserts++
	return true, nil
}

func (*sdkDeviceImportStore) BackfillSDKAccountMetadataTx(context.Context, tx.Tx, SDKAccountRecord) error {
	return nil
}

func runSDKDeviceImport(t *testing.T, kind string) (*sdkDeviceImportStore, SDKImportResult) {
	t.Helper()
	accountID, err := newSDKAccountID()
	if err != nil {
		t.Fatal(err)
	}
	account := SDKAccountRecord{ID: accountID, UID: accountID.UUID().String(), Kind: kind, Username: "imported", Active: true, CreatedAt: time.Now()}
	store := &sdkDeviceImportStore{account: account}
	importer := SDKImporter{
		Runner:     tx.Runner{DB: sdkProbeBeginner{commits: make(chan struct{}, 8)}},
		Store:      store,
		Operations: operation.Factory{Clock: clock.System{}},
	}
	result, err := importer.Import(context.Background(), SDKImportInput{
		Devices: []SDKImportDevice{{DeviceID: "import-device", AccountUID: account.UID}},
	})
	if err != nil {
		t.Fatal(err)
	}
	return store, result
}

// TestSDKImportRefusesADeviceBindingForAPasswordAccount is A-207: the same
// guest-only rule applies to imported device bindings.
func TestSDKImportRefusesADeviceBindingForAPasswordAccount(t *testing.T) {
	store, result := runSDKDeviceImport(t, SDKAccountKindNormal)
	if result.Conflicts != 1 || result.DevicesImported != 0 || store.deviceInserts != 0 {
		t.Fatalf("import = %+v inserts=%d, want a conflict and no binding", result, store.deviceInserts)
	}
}

func TestSDKImportKeepsADeviceBindingForAGuest(t *testing.T) {
	store, result := runSDKDeviceImport(t, SDKAccountKindGuest)
	if result.DevicesImported != 1 || result.Conflicts != 0 || store.deviceInserts != 1 {
		t.Fatalf("import = %+v inserts=%d, want one guest binding", result, store.deviceInserts)
	}
}

func TestSDKImportKeepsGenuineAccountConflicts(t *testing.T) {
	cases := map[string]SDKAccountRecord{
		"guest kind and another name":  {Kind: SDKAccountKindGuest, Username: "other-name"},
		"normal kind and another name": {Kind: SDKAccountKindNormal, Username: "other-name"},
	}
	for name, existing := range cases {
		t.Run(name, func(t *testing.T) {
			accountID, err := newSDKAccountID()
			if err != nil {
				t.Fatal(err)
			}
			existing.ID = accountID
			existing.UID = accountID.UUID().String()
			existing.Active = true
			existing.CreatedAt = time.Now()
			store := &sdkLegacyImportStore{account: existing}
			kind := SDKAccountKindNormal
			if existing.Kind == SDKAccountKindNormal {
				kind = SDKAccountKindGuest
			}
			result := runSDKLegacyImport(t, store, kind)
			if result.Conflicts != 1 || store.backfills != 0 {
				t.Fatalf("import = %+v backfills=%d, want one conflict and no backfill", result, store.backfills)
			}
			if store.account.Kind != existing.Kind || store.account.Username != existing.Username {
				t.Fatalf("a conflicting import changed the account: %+v", store.account)
			}
		})
	}
}
