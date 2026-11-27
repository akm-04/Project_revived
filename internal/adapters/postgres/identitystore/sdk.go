package identitystore

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	appidentity "gxb.local/backend/v2/internal/application/identitylifecycle"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	insertSDKAccount = `INSERT INTO accounts(account_id,account_uid,status,created_at,account_kind,display_username) VALUES($1,$2,'ACTIVE',$3,$4,$5)`
	// Uses no conflict target so both the account id and the stock uid unique
	// constraint skip an account that already exists.
	insertSDKAccountIfAbsent = `INSERT INTO accounts(account_id,account_uid,status,created_at,account_kind,display_username) VALUES($1,$2,'ACTIVE',$3,$4,$5) ON CONFLICT DO NOTHING`
	// Only a column still at its migration default is written, so a value
	// another writer already set is never overwritten.
	backfillSDKAccountMetadata = `UPDATE accounts
SET account_kind = CASE WHEN account_kind='normal' THEN $2 ELSE account_kind END,
    display_username = CASE WHEN display_username='' THEN $3 ELSE display_username END
WHERE account_id=$1
  AND ((account_kind='normal' AND account_kind<>$2) OR (display_username='' AND display_username<>$3))`
	findSDKAccountByUID    = `SELECT account_id::text,account_uid,account_kind,display_username,status,created_at FROM accounts WHERE account_uid=$1`
	findSDKAccountByDevice = `SELECT a.account_id::text,a.account_uid,a.account_kind,a.display_username,a.status,a.created_at FROM sdk_devices d JOIN accounts a ON a.account_id=d.account_id WHERE d.device_id=$1`
	findLiveAccountBySID   = `SELECT a.account_id::text,a.account_uid,a.account_kind,a.display_username,a.status,a.created_at
FROM account_session_credentials c
JOIN account_sessions s ON s.session_id=c.session_id
JOIN accounts a ON a.account_id=s.account_id
WHERE c.digest=$1 AND c.kind='SID' AND c.revoked_at IS NULL
  AND (c.expires_at IS NULL OR c.expires_at > $2)
  AND s.revoked_at IS NULL
  AND (s.absolute_expires_at IS NULL OR s.absolute_expires_at > $2)
  AND (s.idle_timeout_seconds IS NULL OR s.last_activity_at + make_interval(secs => s.idle_timeout_seconds::double precision) > $2)`
	findSDKLogin = `SELECT l.login_normalized,l.login_display,l.password_algorithm,l.password_iterations,l.password_salt,l.password_hash,l.created_at,l.password_changed_at,
       a.account_id::text,a.account_uid,a.account_kind,a.display_username,a.status,a.created_at
FROM sdk_logins l JOIN accounts a ON a.account_id=l.account_id WHERE l.login_normalized=$1`
	insertSDKLogin = `INSERT INTO sdk_logins(login_normalized,login_display,account_id,password_algorithm,password_iterations,password_salt,password_hash,created_at,password_changed_at)
VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9) ON CONFLICT (login_normalized) DO NOTHING`
	insertSDKDevice = `INSERT INTO sdk_devices(device_id,account_id) VALUES($1,$2) ON CONFLICT (device_id) DO NOTHING`
)

func (Store) InsertSDKAccountTx(ctx context.Context, transaction tx.Tx, account appidentity.SDKAccountRecord) error {
	if transaction == nil || account.ID.UUID().IsZero() || account.UID == "" || account.Kind == "" {
		return errors.New("invalid sdk account insert")
	}
	_, err := transaction.Exec(ctx, insertSDKAccount, account.ID.UUID().String(), account.UID, account.CreatedAt.UTC(), account.Kind, account.Username)
	return err
}

func (Store) InsertSDKAccountIfAbsentTx(ctx context.Context, transaction tx.Tx, account appidentity.SDKAccountRecord) (bool, error) {
	if transaction == nil || account.ID.UUID().IsZero() || account.UID == "" || account.Kind == "" {
		return false, errors.New("invalid sdk account insert")
	}
	tag, err := transaction.Exec(ctx, insertSDKAccountIfAbsent, account.ID.UUID().String(), account.UID, account.CreatedAt.UTC(), account.Kind, account.Username)
	if err != nil {
		return false, err
	}
	return tag.RowsAffected() == 1, nil
}

func (Store) BackfillSDKAccountMetadataTx(ctx context.Context, transaction tx.Tx, account appidentity.SDKAccountRecord) error {
	if transaction == nil || account.ID.UUID().IsZero() || account.Kind == "" {
		return errors.New("invalid sdk account backfill")
	}
	_, err := transaction.Exec(ctx, backfillSDKAccountMetadata, account.ID.UUID().String(), account.Kind, account.Username)
	return err
}

func (Store) FindSDKAccountByUIDTx(ctx context.Context, query tx.Queryer, uid string) (*appidentity.SDKAccountRecord, error) {
	if query == nil || uid == "" {
		return nil, errors.New("sdk account uid required")
	}
	account, err := scanSDKAccount(query.QueryRow(ctx, findSDKAccountByUID, uid))
	if errors.Is(err, kernelstore.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &account, nil
}

func (Store) FindSDKAccountByDeviceTx(ctx context.Context, query tx.Queryer, deviceID string) (*appidentity.SDKAccountRecord, error) {
	if query == nil || deviceID == "" {
		return nil, errors.New("sdk device id required")
	}
	account, err := scanSDKAccount(query.QueryRow(ctx, findSDKAccountByDevice, deviceID))
	if errors.Is(err, kernelstore.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &account, nil
}

func (Store) FindLiveSDKAccountBySIDDigestTx(ctx context.Context, query tx.Queryer, digest identity.CredentialDigest, at time.Time) (*appidentity.SDKAccountRecord, error) {
	if query == nil || digest == (identity.CredentialDigest{}) || at.IsZero() {
		return nil, errors.New("invalid sdk sid lookup")
	}
	account, err := scanSDKAccount(query.QueryRow(ctx, findLiveAccountBySID, digest[:], at.UTC()))
	if errors.Is(err, kernelstore.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &account, nil
}

func (Store) FindSDKLoginTx(ctx context.Context, query tx.Queryer, normalized string) (*appidentity.SDKLoginRecord, error) {
	if query == nil || normalized == "" {
		return nil, errors.New("sdk login key required")
	}
	var login appidentity.SDKLoginRecord
	var accountID, accountUID, kind, username, status string
	var iterations int
	var created, changed, accountCreated time.Time
	err := query.QueryRow(ctx, findSDKLogin, normalized).Scan(
		&login.Normalized, &login.Display, &login.Algorithm, &iterations, &login.SaltHex, &login.HashHex, &created, &changed,
		&accountID, &accountUID, &kind, &username, &status, &accountCreated)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	parsed, err := parseAccountID(accountID)
	if err != nil {
		return nil, err
	}
	login.Iterations = iterations
	login.CreatedAt = created.UTC()
	login.PasswordChangedAt = changed.UTC()
	login.Account = appidentity.SDKAccountRecord{ID: parsed, UID: accountUID, Kind: kind, Username: username, Active: status == "ACTIVE", CreatedAt: accountCreated.UTC()}
	return &login, nil
}

func (Store) InsertSDKLoginTx(ctx context.Context, transaction tx.Tx, login appidentity.SDKLoginRecord) (bool, error) {
	if transaction == nil || login.Normalized == "" || login.Account.ID.UUID().IsZero() {
		return false, errors.New("invalid sdk login insert")
	}
	tag, err := transaction.Exec(ctx, insertSDKLogin, login.Normalized, login.Display, login.Account.ID.UUID().String(), login.Algorithm, login.Iterations, login.SaltHex, login.HashHex, login.CreatedAt.UTC(), login.PasswordChangedAt.UTC())
	if err != nil {
		return false, err
	}
	return tag.RowsAffected() == 1, nil
}

func (Store) InsertSDKDeviceTx(ctx context.Context, transaction tx.Tx, deviceID string, account identity.AccountID) (bool, error) {
	if transaction == nil || deviceID == "" || account.UUID().IsZero() {
		return false, errors.New("invalid sdk device insert")
	}
	tag, err := transaction.Exec(ctx, insertSDKDevice, deviceID, account.UUID().String())
	if err != nil {
		return false, err
	}
	return tag.RowsAffected() == 1, nil
}

type sdkAccountRow interface {
	Scan(dest ...any) error
}

func scanSDKAccount(row sdkAccountRow) (appidentity.SDKAccountRecord, error) {
	var accountID, uid, kind, username, status string
	var created time.Time
	if err := row.Scan(&accountID, &uid, &kind, &username, &status, &created); err != nil {
		return appidentity.SDKAccountRecord{}, err
	}
	parsed, err := parseAccountID(accountID)
	if err != nil {
		return appidentity.SDKAccountRecord{}, err
	}
	return appidentity.SDKAccountRecord{ID: parsed, UID: uid, Kind: kind, Username: username, Active: status == "ACTIVE", CreatedAt: created.UTC()}, nil
}
