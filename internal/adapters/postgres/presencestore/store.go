package presencestore

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/socialpresence"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{ Queryer tx.Queryer }

const activateRealtimeOwnerFenceSQL = `
INSERT INTO realtime_presence_owner_state(singleton,owner_fence,activated_at)
VALUES(TRUE,nextval('realtime_presence_owner_fence_seq'),clock_timestamp())
ON CONFLICT(singleton) DO UPDATE SET
  owner_fence=EXCLUDED.owner_fence,
  activated_at=EXCLUDED.activated_at
RETURNING owner_fence`

// ActivateRealtimeOwnerFence advances the Presence writer epoch after the
// process has acquired the accepted R6 PostgreSQL advisory realtime-owner lock.
// The UPDATE waits for any in-flight Presence mutation holding the singleton
// row FOR SHARE, producing a linear handoff boundary without becoming gameplay
// authority. Sequence gaps are valid.
func (s Store) ActivateRealtimeOwnerFence(ctx context.Context) (int64, error) {
	if s.Queryer == nil {
		return 0, errors.New("presence store: nil owner-fence queryer")
	}
	var fence int64
	if err := s.Queryer.QueryRow(ctx, activateRealtimeOwnerFenceSQL).Scan(&fence); err != nil {
		return 0, err
	}
	if fence <= 0 {
		return 0, errors.New("presence store: invalid owner fence")
	}
	return fence, nil
}

const assertOwnerFenceSQL = `
SELECT owner_fence
FROM realtime_presence_owner_state
WHERE singleton=TRUE
FOR SHARE`

// AssertOwnerFenceTx establishes a transaction-scoped writer fence. FOR SHARE
// allows concurrent current-owner player transactions but forces the next
// owner activation UPDATE to wait until all earlier Presence mutations finish.
func (Store) AssertOwnerFenceTx(ctx context.Context, t tx.Tx, expected int64) error {
	if t == nil || expected <= 0 {
		return socialpresence.ErrStaleRealtimeOwner
	}
	var current int64
	if err := t.QueryRow(ctx, assertOwnerFenceSQL).Scan(&current); err != nil {
		if noRows(err) {
			return socialpresence.ErrStaleRealtimeOwner
		}
		return err
	}
	if current != expected {
		return socialpresence.ErrStaleRealtimeOwner
	}
	return nil
}

func noRows(err error) bool { return errors.Is(err, kernelstore.ErrNoRows) }

const ensureRootSQL = `
INSERT INTO player_social_presence(player_id,last_seen_at,state_version,created_at,updated_at)
VALUES($1,NULL,1,$2,$2)
ON CONFLICT(player_id) DO NOTHING`

const lockRootSQL = `
SELECT state_version
FROM player_social_presence
WHERE player_id=$1
FOR UPDATE`

func (Store) EnsureAndLockRootTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, at time.Time) error {
	if t == nil || !pid.Valid() || at.IsZero() {
		return errors.New("presence store: invalid root lock")
	}
	if _, err := t.Exec(ctx, ensureRootSQL, int64(pid), at.UTC()); err != nil {
		return err
	}
	var version int64
	if err := t.QueryRow(ctx, lockRootSQL, int64(pid)).Scan(&version); err != nil {
		return err
	}
	if version <= 0 {
		return errors.New("presence store: invalid root version")
	}
	return nil
}

const settleExpiredSQL = `
WITH expired AS (
  DELETE FROM realtime_presence_leases
  WHERE player_id=$1 AND lease_expires_at <= $2
  RETURNING lease_expires_at
)
SELECT (SELECT max(lease_expires_at) FROM expired),
       EXISTS(SELECT 1 FROM realtime_presence_leases WHERE player_id=$1 AND lease_expires_at > $2)`

func (Store) SettleExpiredTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, at time.Time) (socialpresence.ExpiredSummary, error) {
	if t == nil || !pid.Valid() || at.IsZero() {
		return socialpresence.ExpiredSummary{}, errors.New("presence store: invalid expiry settlement")
	}
	var rawMax any
	var live bool
	if err := t.QueryRow(ctx, settleExpiredSQL, int64(pid), at.UTC()).Scan(&rawMax, &live); err != nil {
		return socialpresence.ExpiredSummary{}, err
	}
	maxAt, err := nullableTime(rawMax)
	if err != nil {
		return socialpresence.ExpiredSummary{}, err
	}
	return socialpresence.ExpiredSummary{MaxExpiredAt: maxAt, HasLiveLease: live}, nil
}

const upsertLeaseSQL = `
INSERT INTO realtime_presence_leases(
  gameplay_context_id,physical_role,player_id,realtime_owner_fence,realtime_instance_id,connection_generation,
  connected_at,last_renewed_at,lease_expires_at
) VALUES($1::uuid,$2,$3,$4,$5::uuid,$6,$7,$7,$8)
ON CONFLICT(gameplay_context_id,physical_role) DO UPDATE SET
  player_id=EXCLUDED.player_id,
  realtime_owner_fence=EXCLUDED.realtime_owner_fence,
  realtime_instance_id=EXCLUDED.realtime_instance_id,
  connection_generation=EXCLUDED.connection_generation,
  connected_at=CASE
    WHEN realtime_presence_leases.realtime_owner_fence=EXCLUDED.realtime_owner_fence
     AND realtime_presence_leases.realtime_instance_id=EXCLUDED.realtime_instance_id
     AND realtime_presence_leases.connection_generation=EXCLUDED.connection_generation
    THEN realtime_presence_leases.connected_at ELSE EXCLUDED.connected_at END,
  last_renewed_at=CASE
    WHEN realtime_presence_leases.realtime_owner_fence=EXCLUDED.realtime_owner_fence
     AND realtime_presence_leases.realtime_instance_id=EXCLUDED.realtime_instance_id
     AND realtime_presence_leases.connection_generation=EXCLUDED.connection_generation
    THEN GREATEST(realtime_presence_leases.last_renewed_at,EXCLUDED.last_renewed_at)
    ELSE EXCLUDED.last_renewed_at END,
  lease_expires_at=CASE
    WHEN realtime_presence_leases.realtime_owner_fence=EXCLUDED.realtime_owner_fence
     AND realtime_presence_leases.realtime_instance_id=EXCLUDED.realtime_instance_id
     AND realtime_presence_leases.connection_generation=EXCLUDED.connection_generation
    THEN GREATEST(realtime_presence_leases.lease_expires_at,EXCLUDED.lease_expires_at)
    ELSE EXCLUDED.lease_expires_at END
WHERE realtime_presence_leases.player_id=EXCLUDED.player_id
  AND (
    realtime_presence_leases.realtime_owner_fence < EXCLUDED.realtime_owner_fence
    OR (
      realtime_presence_leases.realtime_owner_fence = EXCLUDED.realtime_owner_fence
      AND realtime_presence_leases.realtime_instance_id = EXCLUDED.realtime_instance_id
      AND realtime_presence_leases.connection_generation <= EXCLUDED.connection_generation
    )
  )`

func (Store) UpsertLeaseTx(ctx context.Context, t tx.Tx, ref socialpresence.LeaseRef, connectedAt, expiresAt time.Time) error {
	generation, err := ref.GenerationInt64()
	if err != nil || t == nil || connectedAt.IsZero() || !expiresAt.After(connectedAt) {
		if err != nil {
			return err
		}
		return socialpresence.ErrInvalidLease
	}
	tag, err := t.Exec(ctx, upsertLeaseSQL,
		ref.ContextID.UUID().String(), string(ref.Role), int64(ref.PlayerID), ref.RealtimeOwnerFence, ref.RealtimeInstanceID.String(), generation,
		connectedAt.UTC(), expiresAt.UTC(),
	)
	if err != nil {
		return err
	}
	if tag == nil || tag.RowsAffected() != 1 {
		return socialpresence.ErrStaleLeaseGeneration
	}
	return nil
}

const deleteExactLeaseSQL = `
DELETE FROM realtime_presence_leases
WHERE gameplay_context_id=$1::uuid AND physical_role=$2 AND player_id=$3
  AND realtime_owner_fence=$4 AND realtime_instance_id=$5::uuid AND connection_generation=$6
RETURNING lease_expires_at`

func (Store) DeleteExactLeaseTx(ctx context.Context, t tx.Tx, ref socialpresence.LeaseRef) (time.Time, bool, error) {
	generation, err := ref.GenerationInt64()
	if err != nil || t == nil {
		return time.Time{}, false, err
	}
	var expiry time.Time
	err = t.QueryRow(ctx, deleteExactLeaseSQL,
		ref.ContextID.UUID().String(), string(ref.Role), int64(ref.PlayerID), ref.RealtimeOwnerFence, ref.RealtimeInstanceID.String(), generation,
	).Scan(&expiry)
	if noRows(err) {
		return time.Time{}, false, nil
	}
	if err != nil {
		return time.Time{}, false, err
	}
	return expiry.UTC(), true, nil
}

const advanceLastSeenSQL = `
UPDATE player_social_presence
SET last_seen_at=$2,
    state_version=state_version+1,
    updated_at=$3
WHERE player_id=$1
  AND (last_seen_at IS NULL OR last_seen_at < $2)`

func (Store) AdvanceLastSeenTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, candidate, updatedAt time.Time) (bool, error) {
	if t == nil || !pid.Valid() || candidate.IsZero() || updatedAt.IsZero() {
		return false, errors.New("presence store: invalid last-seen advance")
	}
	tag, err := t.Exec(ctx, advanceLastSeenSQL, int64(pid), candidate.UTC(), updatedAt.UTC())
	if err != nil {
		return false, err
	}
	if tag == nil {
		return false, errors.New("presence store: nil last-seen command tag")
	}
	switch tag.RowsAffected() {
	case 0:
		return false, nil
	case 1:
		return true, nil
	default:
		return false, fmt.Errorf("presence store: last-seen affected %d rows", tag.RowsAffected())
	}
}

const readManySQL = `
WITH requested(player_id) AS (SELECT unnest($1::bigint[])),
observed AS (
  SELECT r.player_id,
         p.last_seen_at,
         max(l.connected_at) FILTER (WHERE l.lease_expires_at > $2) AS latest_connected_at
  FROM requested r
  LEFT JOIN player_social_presence p ON p.player_id=r.player_id
  LEFT JOIN realtime_presence_leases l ON l.player_id=r.player_id
  GROUP BY r.player_id,p.last_seen_at
)
SELECT COALESCE(jsonb_agg(jsonb_build_object(
  'player_id',player_id,
  'last_seen_at',last_seen_at,
  'latest_connected_at',latest_connected_at
) ORDER BY player_id),'[]'::jsonb)::text
FROM observed`

func (s Store) ReadManyAt(ctx context.Context, playerIDs []identity.PlayerID, observedAt time.Time) (map[identity.PlayerID]socialpresence.Observation, error) {
	if s.Queryer == nil || observedAt.IsZero() {
		return nil, errors.New("presence store: invalid observation query")
	}
	ids := make([]int64, len(playerIDs))
	for i, pid := range playerIDs {
		if !pid.Valid() {
			return nil, socialpresence.ErrInvalidObservation
		}
		ids[i] = int64(pid)
	}
	if len(ids) == 0 {
		return map[identity.PlayerID]socialpresence.Observation{}, nil
	}
	var raw string
	if err := s.Queryer.QueryRow(ctx, readManySQL, ids, observedAt.UTC()).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []struct {
		PlayerID          int64      `json:"player_id"`
		LastSeenAt        *time.Time `json:"last_seen_at"`
		LatestConnectedAt *time.Time `json:"latest_connected_at"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make(map[identity.PlayerID]socialpresence.Observation, len(playerIDs))
	for _, pid := range playerIDs {
		out[pid] = socialpresence.Observation{PlayerID: pid}
	}
	for _, row := range rows {
		pid := identity.PlayerID(row.PlayerID)
		obs := socialpresence.Observation{PlayerID: pid, LastSeenAt: utcPtr(row.LastSeenAt), LatestConnectedAt: utcPtr(row.LatestConnectedAt), IsOnline: row.LatestConnectedAt != nil}
		if err := obs.Validate(); err != nil {
			return nil, err
		}
		out[pid] = obs
	}
	return out, nil
}

const expiredPlayersSQL = `
SELECT COALESCE(jsonb_agg(player_id ORDER BY player_id),'[]'::jsonb)::text
FROM (
  SELECT DISTINCT player_id
  FROM realtime_presence_leases
  WHERE lease_expires_at <= $1
  ORDER BY player_id
  LIMIT $2
) q`

func (s Store) ExpiredPlayerIDs(ctx context.Context, at time.Time, limit int) ([]identity.PlayerID, error) {
	if s.Queryer == nil || at.IsZero() || limit <= 0 {
		return nil, errors.New("presence store: invalid expired-player query")
	}
	var raw string
	if err := s.Queryer.QueryRow(ctx, expiredPlayersSQL, at.UTC(), limit).Scan(&raw); err != nil {
		return nil, err
	}
	var values []int64
	if err := json.Unmarshal([]byte(raw), &values); err != nil {
		return nil, err
	}
	out := make([]identity.PlayerID, 0, len(values))
	for _, rawID := range values {
		pid := identity.PlayerID(rawID)
		if !pid.Valid() {
			return nil, errors.New("presence store: invalid expired player id")
		}
		out = append(out, pid)
	}
	return out, nil
}

func nullableTime(v any) (*time.Time, error) {
	if v == nil {
		return nil, nil
	}
	t, ok := v.(time.Time)
	if !ok {
		return nil, fmt.Errorf("presence store: unexpected nullable time %T", v)
	}
	t = t.UTC()
	return &t, nil
}

func utcPtr(v *time.Time) *time.Time {
	if v == nil {
		return nil
	}
	t := v.UTC()
	return &t
}

// ReadOwnerFenceTx observes the current canonical realtime epoch in the caller
// snapshot. Offline projection uses it to exclude only the current owner's lease.
func (Store) ReadOwnerFenceTx(ctx context.Context, q tx.Queryer) (int64, error) {
	var current int64
	if q == nil {
		return 0, socialpresence.ErrStaleRealtimeOwner
	}
	err := q.QueryRow(ctx, `SELECT owner_fence FROM realtime_presence_owner_state WHERE singleton=true`).Scan(&current)
	if noRows(err) {
		return 0, nil
	}
	if err != nil {
		return 0, err
	}
	if current < 1 {
		return 0, socialpresence.ErrStaleRealtimeOwner
	}
	return current, nil
}
