package i4store

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type PlayerLoginActivity struct{}

var _ bootstrap.CharacterLoginReconciler = PlayerLoginActivity{}
var _ bootstrap.PlayerActivityReader = PlayerLoginActivity{}

func (PlayerLoginActivity) Name() string { return "i4.canonical-login-activity" }

func (PlayerLoginActivity) ReconcileCharacterLogin(ctx context.Context, transaction tx.Tx, actor identity.ActorContext, current operation.Context, at time.Time) error {
	if transaction == nil || !actor.PlayerID.Valid() || !actor.LogicalServerID.Valid() || logicalserver.PlayerRegion(actor.PlayerID) != actor.LogicalServerID || current.ID.IsZero() || current.StartedAt.IsZero() || at.IsZero() {
		return bootstrap.ErrPlayerActivity
	}
	roots, err := (PlayerRootLocker{}).LockPlayerRootsTx(ctx, transaction, actor.LogicalServerID, []identity.PlayerID{actor.PlayerID})
	if err != nil {
		return err
	}
	if len(roots) != 1 || roots[0].PlayerID != actor.PlayerID || roots[0].LogicalServerID != actor.LogicalServerID {
		return bootstrap.ErrPlayerActivity
	}
	at = at.UTC()
	effect, err := transaction.Exec(ctx, `INSERT INTO player_login_observations(player_id,logical_server_id,last_login_at,source_operation_id,state_version) VALUES($1,$2,$3,$4,1) ON CONFLICT(player_id) DO UPDATE SET last_login_at=EXCLUDED.last_login_at,source_operation_id=EXCLUDED.source_operation_id,state_version=player_login_observations.state_version+1 WHERE player_login_observations.logical_server_id=EXCLUDED.logical_server_id AND player_login_observations.last_login_at<EXCLUDED.last_login_at AND player_login_observations.state_version<9223372036854775807`, int64(actor.PlayerID), int32(actor.LogicalServerID), at, current.ID.String())
	if err != nil {
		return err
	}
	if effect == nil {
		return bootstrap.ErrPlayerActivity
	}
	if effect.RowsAffected() == 1 {
		return nil
	}
	var server int32
	var lastLogin time.Time
	if err := transaction.QueryRow(ctx, `SELECT logical_server_id,last_login_at FROM player_login_observations WHERE player_id=$1`, int64(actor.PlayerID)).Scan(&server, &lastLogin); err != nil {
		return err
	}
	if identity.LogicalServerID(server) != actor.LogicalServerID || lastLogin.Before(at) {
		return bootstrap.ErrPlayerActivity
	}
	return nil
}

func (PlayerLoginActivity) ReadPlayerActivityTx(ctx context.Context, query tx.Queryer, player identity.PlayerID, at time.Time) (bootstrap.PlayerActivityObservation, bool, error) {
	if query == nil || !player.Valid() || !logicalserver.PlayerRegion(player).Valid() || at.IsZero() {
		return bootstrap.PlayerActivityObservation{}, false, bootstrap.ErrPlayerActivity
	}
	out := bootstrap.PlayerActivityObservation{ObservedAt: at.UTC()}
	var invalidBinding bool
	err := query.QueryRow(ctx, `SELECT o.player_id,o.logical_server_id,o.last_login_at,o.state_version,
 GREATEST(o.last_login_at,COALESCE((SELECT max(GREATEST(c.created_at,c.ended_at,CASE WHEN c.ended_at IS NULL THEN s.last_activity_at END)) FROM gameplay_contexts c JOIN account_sessions s ON s.session_id=c.session_id WHERE c.player_id=o.player_id),o.last_login_at)),
 o.logical_server_id<>p.logical_server_id OR EXISTS(SELECT 1 FROM gameplay_contexts c JOIN account_sessions s ON s.session_id=c.session_id WHERE c.player_id=o.player_id AND (c.account_id<>p.account_id OR s.account_id<>p.account_id OR c.logical_server_id<>p.logical_server_id OR c.ended_at<c.created_at))
 FROM player_login_observations o JOIN players p ON p.player_id=o.player_id WHERE o.player_id=$1`, int64(player)).Scan(&out.PlayerID, &out.LogicalServerID, &out.LastLoginAt, &out.StateVersion, &out.LatestActivityAt, &invalidBinding)
	if errors.Is(err, kernelErrNoRows()) {
		return bootstrap.PlayerActivityObservation{}, false, nil
	}
	if err != nil {
		return bootstrap.PlayerActivityObservation{}, false, err
	}
	out.LastLoginAt = out.LastLoginAt.UTC()
	out.LatestActivityAt = out.LatestActivityAt.UTC()
	if invalidBinding || out.PlayerID != player || out.Validate() != nil {
		return bootstrap.PlayerActivityObservation{}, false, bootstrap.ErrPlayerActivity
	}
	return out, true, nil
}
