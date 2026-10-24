package i4store

import (
	"context"
	"errors"
	"fmt"

	appdir "gxb.local/backend/v2/internal/application/directorysync"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// DirectoryLevelProjection is the narrow I4-owned R5 projection seam. It owns
// only player_directory_profiles.lev synchronization; broader directory repair
// remains R6/RF-024.
type DirectoryLevelProjection struct{}

func (DirectoryLevelProjection) LockTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) (appi5.DirectoryLevelProjection, error) {
	if t == nil || !pid.Valid() {
		return appi5.DirectoryLevelProjection{}, errors.New("invalid directory level lock")
	}
	var out appi5.DirectoryLevelProjection
	if err := t.QueryRow(ctx, `SELECT lev,state_version FROM player_directory_profiles WHERE player_id=$1 FOR UPDATE`, int64(pid)).Scan(&out.Level, &out.StateVersion); err != nil {
		return appi5.DirectoryLevelProjection{}, err
	}
	if out.Level < 1 || out.StateVersion <= 0 {
		return appi5.DirectoryLevelProjection{}, errors.New("invalid directory level projection")
	}
	return out, nil
}

func (DirectoryLevelProjection) SetLevelTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, expectedVersion, newLevel int64, op operation.Context) error {
	if t == nil || !pid.Valid() || expectedVersion <= 0 || newLevel < 1 || op.StartedAt.IsZero() {
		return errors.New("invalid directory level update")
	}
	tag, err := t.Exec(ctx, `UPDATE player_directory_profiles SET lev=$3,state_version=state_version+1,updated_at=$4 WHERE player_id=$1 AND state_version=$2`, int64(pid), expectedVersion, newLevel, op.StartedAt.UTC())
	if err != nil {
		return err
	}
	if tag == nil || tag.RowsAffected() != 1 {
		var n int64
		if tag != nil {
			n = tag.RowsAffected()
		}
		return fmt.Errorf("directory level optimistic write affected %d rows", n)
	}
	return nil
}

func (DirectoryLevelProjection) LockOwnedDirectoryTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) (appdir.ProjectionSnapshot, error) {
	if t == nil || !pid.Valid() {
		return appdir.ProjectionSnapshot{}, errors.New("invalid directory reconciliation lock")
	}
	var out appdir.ProjectionSnapshot
	if err := t.QueryRow(ctx, `SELECT name,lev,avatar_id,avatar_frame_id,state_version FROM player_directory_profiles WHERE player_id=$1 FOR UPDATE`, int64(pid)).Scan(&out.Name, &out.Level, &out.AvatarID, &out.AvatarFrameID, &out.StateVersion); err != nil {
		return appdir.ProjectionSnapshot{}, err
	}
	if err := out.Validate(); err != nil {
		return appdir.ProjectionSnapshot{}, err
	}
	return out, nil
}

func (DirectoryLevelProjection) ApplyOwnedDirectoryTx(ctx context.Context, t tx.Tx, canonical appdir.CanonicalSnapshot, expectedVersion int64, op operation.Context) error {
	if t == nil || expectedVersion <= 0 || op.StartedAt.IsZero() {
		return errors.New("invalid directory reconciliation update")
	}
	if err := canonical.Validate(); err != nil {
		return err
	}
	tag, err := t.Exec(ctx, `UPDATE player_directory_profiles SET name=$3,lev=$4,avatar_id=$5,avatar_frame_id=$6,state_version=state_version+1,updated_at=$7 WHERE player_id=$1 AND state_version=$2`, int64(canonical.PlayerID), expectedVersion, canonical.Name, canonical.Level, canonical.AvatarID, canonical.AvatarFrameID, op.StartedAt.UTC())
	if err != nil {
		return err
	}
	if tag == nil || tag.RowsAffected() != 1 {
		var n int64
		if tag != nil {
			n = tag.RowsAffected()
		}
		return fmt.Errorf("directory reconciliation optimistic write affected %d rows", n)
	}
	return nil
}
