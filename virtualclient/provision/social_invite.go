package provision

import (
	"context"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// SocialInviteBindFixture declares one invited peer: it raises the peer's first
// battle girl to level 50 and binds the peer to the driven player's invitation
// code. The virtual client drives one player, so the peer's MID 386 bind is a
// declared fixture; the driven client's own 384/385/386 paths stay stock.
func SocialInviteBindFixture(ctx context.Context, databaseURL, inviterAccount, inviteeAccount string) error {
	pool, err := postgres.Open(ctx, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "vc-social-invite-fixture"})
	if err != nil {
		return err
	}
	defer pool.Close()
	var inviter, invitee int64
	if err := pool.QueryRow(ctx, `SELECT player_id FROM players WHERE account_id=$1`, inviterAccount).Scan(&inviter); err != nil {
		return fmt.Errorf("invite inviter: %w", err)
	}
	if err := pool.QueryRow(ctx, `SELECT player_id FROM players WHERE account_id=$1`, inviteeAccount).Scan(&invitee); err != nil {
		return fmt.Errorf("invite invitee: %w", err)
	}
	transaction, err := pool.Begin(ctx, tx.Options{})
	if err != nil {
		return err
	}
	defer transaction.Rollback(ctx)
	if _, err := transaction.Exec(ctx, `UPDATE player_heroes SET level=50,exp=0,state_version=state_version+1,updated_at=clock_timestamp() WHERE player_id=$1`, invitee); err != nil {
		return fmt.Errorf("invite peer hero: %w", err)
	}
	revision, err := (contentstore.Store{Queryer: pool}).ActiveRevision(ctx, pool)
	if err != nil {
		return fmt.Errorf("invite peer revision: %w", err)
	}
	if _, err := transaction.Exec(ctx, `DELETE FROM commerce_privilege_roots WHERE player_id=$1`, invitee); err != nil {
		return fmt.Errorf("invite peer privilege cleanup: %w", err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO commerce_privilege_roots(player_id,logical_server_id,qualifying_charge,vip_level,monthly_state,content_revision,policy_version,origin_class,issuer,reason,state_version,created_at,updated_at) VALUES($1,$2,100,1,'QUALIFIED_ABSENT',$3,'C4A_MANUAL_PRIVILEGE_SNAPSHOT_V1','MANUAL_PRESERVATION','vc-invite','vc-invite',1,clock_timestamp(),clock_timestamp())`, invitee, invitee/100000, revision); err != nil {
		return fmt.Errorf("invite peer privilege: %w", err)
	}
	operation, err := ids.NewUUID()
	if err != nil {
		return err
	}
	if _, err := transaction.Exec(ctx, `DELETE FROM social_invite_bindings WHERE invitee_player_id=$1`, invitee); err != nil {
		return fmt.Errorf("invite binding cleanup: %w", err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO social_invite_bindings(invitee_player_id,inviter_player_id,logical_server_id,operation_id,policy_version,bound_at) VALUES($1,$2,$3,$4,'I9_10E_SOCIAL_INVITE_V1',$5)`, invitee, inviter, invitee/100000, operation.String(), time.Now().UTC()); err != nil {
		return fmt.Errorf("invite binding: %w", err)
	}
	return transaction.Commit(ctx)
}
