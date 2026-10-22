// Package provision stands in for the stock login SDK: it creates the live account session whose sid and login_token the SDK would hand the client.
package provision

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

// Session is one SDK login: the raw credentials stock LoadingScene receives from xydNewLogin.
type Session struct {
	AccountID  string
	SID        string
	LoginToken string
}

// Account inserts a fresh ACTIVE account with a SID_LOGIN_TOKEN_PAIR session, as the I7C2J API test provisions one.
// digestSecret must be the backend's GXB_CREDENTIAL_DIGEST_SECRET.
func Account(context context.Context, databaseURL string, digestSecret []byte) (Session, error) {
	account, err := ids.NewUUID()
	if err != nil {
		return Session{}, err
	}
	session, err := ids.NewUUID()
	if err != nil {
		return Session{}, err
	}
	result := Session{AccountID: account.String(), SID: "vc-sid-" + session.String(), LoginToken: "vc-login-" + session.String()}
	connection, err := pgx.Connect(context, databaseURL)
	if err != nil {
		return Session{}, err
	}
	defer connection.Close(context)
	transaction, err := connection.Begin(context)
	if err != nil {
		return Session{}, err
	}
	defer transaction.Rollback(context)
	if _, err := transaction.Exec(context, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp())`, account.String(), account.String()); err != nil {
		return Session{}, fmt.Errorf("account: %w", err)
	}
	if _, err := transaction.Exec(context, `INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,$3,clock_timestamp(),clock_timestamp())`, session.String(), account.String(), string(identity.AuthProductionPair)); err != nil {
		return Session{}, fmt.Errorf("session: %w", err)
	}
	credentials := []struct{ kind, label, raw string }{{"SID", "sid", result.SID}, {"LOGIN_TOKEN", "login_token", result.LoginToken}}
	for _, credential := range credentials {
		digest, err := identity.DigestCredential(digestSecret, credential.label, credential.raw)
		if err != nil {
			return Session{}, err
		}
		credentialID, err := ids.NewUUID()
		if err != nil {
			return Session{}, err
		}
		if _, err := transaction.Exec(context, `INSERT INTO account_session_credentials(credential_id,session_id,kind,digest,issued_at)VALUES($1,$2,$3,$4,clock_timestamp())`, credentialID.String(), session.String(), credential.kind, digest[:]); err != nil {
			return Session{}, fmt.Errorf("credential %s: %w", credential.kind, err)
		}
	}
	return result, transaction.Commit(context)
}
