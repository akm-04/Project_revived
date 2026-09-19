package i5store

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	appdir "gxb.local/backend/v2/internal/application/directorysync"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/domain/redeem"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{ Queryer tx.Queryer }

func noRows(err error) bool { return errors.Is(err, kernelstore.ErrNoRows) }
func rowsOne(tag tx.CommandTag, what string) error {
	if tag == nil || tag.RowsAffected() != 1 {
		return fmt.Errorf("%s optimistic write affected %d rows", what, rowsAffected(tag))
	}
	return nil
}
func rowsAffected(tag tx.CommandTag) int64 {
	if tag == nil {
		return 0
	}
	return tag.RowsAffected()
}

const fenceActorSQL = `
SELECT 1
FROM gameplay_contexts gc
JOIN account_sessions s ON s.session_id=gc.session_id AND s.account_id=gc.account_id
JOIN accounts a ON a.account_id=gc.account_id
WHERE gc.context_id=$1::uuid AND gc.session_id=$2::uuid AND gc.account_id=$3::uuid
  AND gc.logical_server_id=$4 AND gc.player_id=$5 AND gc.context_generation=$6
  AND gc.liveness_version=$7 AND s.liveness_version=$8
  AND gc.ended_at IS NULL AND s.revoked_at IS NULL AND a.status='ACTIVE' AND a.disabled_at IS NULL
  AND (s.absolute_expires_at IS NULL OR $9::timestamptz < s.absolute_expires_at)
  AND (s.idle_timeout_seconds IS NULL OR $9::timestamptz < s.last_activity_at + make_interval(secs => s.idle_timeout_seconds))
FOR SHARE OF gc,s,a`

func (Store) FenceActorTx(ctx context.Context, t tx.Tx, a identity.ActorContext, now time.Time) error {
	if t == nil || a.ContextID.UUID().IsZero() || now.IsZero() {
		return errors.New("invalid actor fence")
	}
	var one int
	err := t.QueryRow(ctx, fenceActorSQL, a.ContextID.UUID().String(), a.SessionID.UUID().String(), a.AccountID.UUID().String(), int32(a.LogicalServerID), int64(a.PlayerID), a.ContextGeneration, a.ContextLivenessVersion, a.SessionLivenessVersion, now.UTC()).Scan(&one)
	if err != nil {
		if noRows(err) {
			return errors.New("actor liveness fence rejected")
		}
		return err
	}
	return nil
}

func (Store) LockStoryTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) (player.StoryCursor, error) {
	var out player.StoryCursor
	err := t.QueryRow(ctx, `SELECT player_id,story_id,story_state,guide_id,state_version,updated_at FROM player_story_cursors WHERE player_id=$1 FOR UPDATE`, int64(pid)).Scan((*int64)(&out.PlayerID), &out.StoryID, &out.StoryState, &out.GuideID, &out.StateVersion, &out.UpdatedAt)
	return out, err
}
func (Store) SaveStoryTx(ctx context.Context, t tx.Tx, s player.StoryCursor, old int64) error {
	tag, err := t.Exec(ctx, `UPDATE player_story_cursors SET story_id=$2,story_state=$3,guide_id=$4,state_version=$5,updated_at=$6 WHERE player_id=$1 AND state_version=$7`, int64(s.PlayerID), s.StoryID, s.StoryState, s.GuideID, s.StateVersion, s.UpdatedAt.UTC(), old)
	if err != nil {
		return err
	}
	return rowsOne(tag, "story")
}
func (Store) ClearFirstEntryPendingTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) error {
	_, err := t.Exec(ctx, `UPDATE players SET first_entry_pending=false,state_version=state_version+1 WHERE player_id=$1 AND first_entry_pending=true`, int64(pid))
	return err
}

func (s Store) ListStacks(ctx context.Context, pid identity.PlayerID) ([]economy.StackState, error) {
	if s.Queryer == nil {
		return nil, errors.New("nil stack queryer")
	}
	return s.ListStacksTx(ctx, s.Queryer, pid)
}

func (Store) ListStacksTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) ([]economy.StackState, error) {
	if q == nil || !pid.Valid() {
		return nil, errors.New("invalid stack list query")
	}
	var raw string
	if err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'item_id',item_id,'quantity',quantity,'state_version',state_version,'acquired_at',acquired_at,'updated_at',updated_at) ORDER BY item_id),'[]'::jsonb)::text FROM player_item_stacks WHERE player_id=$1`, int64(pid)).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []struct {
		PlayerID     int64     `json:"player_id"`
		ItemID       int64     `json:"item_id"`
		Quantity     int64     `json:"quantity"`
		StateVersion int64     `json:"state_version"`
		AcquiredAt   time.Time `json:"acquired_at"`
		UpdatedAt    time.Time `json:"updated_at"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]economy.StackState, 0, len(rows))
	for _, r := range rows {
		st := economy.StackState{PlayerID: identity.PlayerID(r.PlayerID), ItemID: r.ItemID, Quantity: r.Quantity, StateVersion: r.StateVersion, AcquiredAt: r.AcquiredAt.UTC(), UpdatedAt: r.UpdatedAt.UTC()}
		if err := st.Validate(); err != nil {
			return nil, err
		}
		out = append(out, st)
	}
	return out, nil
}

func (Store) ReadScalarTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, key string) (economy.ScalarBalance, bool, error) {
	if q == nil {
		return economy.ScalarBalance{}, false, errors.New("nil scalar queryer")
	}
	var b economy.ScalarBalance
	err := q.QueryRow(ctx, `SELECT player_id,resource_key,amount,state_version,updated_at FROM player_currency_balances WHERE player_id=$1 AND resource_key=$2`, int64(pid), key).Scan((*int64)(&b.PlayerID), &b.ResourceKey, &b.Amount, &b.StateVersion, &b.UpdatedAt)
	if noRows(err) {
		return economy.ScalarBalance{}, false, nil
	}
	return b, err == nil, err
}

func (Store) ReadCanonicalDirectoryTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) (appdir.CanonicalSnapshot, error) {
	if q == nil || !pid.Valid() {
		return appdir.CanonicalSnapshot{}, errors.New("invalid canonical directory query")
	}
	var out appdir.CanonicalSnapshot
	var rawPID int64
	err := q.QueryRow(ctx, `SELECT p.player_id,p.display_name,pr.level,p.avatar_id,p.avatar_frame_id FROM player_profiles p JOIN player_progression pr USING(player_id) WHERE p.player_id=$1`, int64(pid)).Scan(&rawPID, &out.Name, &out.Level, &out.AvatarID, &out.AvatarFrameID)
	out.PlayerID = identity.PlayerID(rawPID)
	if err != nil {
		return appdir.CanonicalSnapshot{}, err
	}
	if err := out.Validate(); err != nil {
		return appdir.CanonicalSnapshot{}, err
	}
	return out, nil
}

func (Store) ReadProgressionTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) (player.Progression, error) {
	if q == nil {
		return player.Progression{}, errors.New("nil progression queryer")
	}
	var p player.Progression
	err := q.QueryRow(ctx, `SELECT player_id,level,exp,state_version,updated_at FROM player_progression WHERE player_id=$1`, int64(pid)).Scan((*int64)(&p.PlayerID), &p.Level, &p.Exp, &p.StateVersion, &p.UpdatedAt)
	return p, err
}

func (Store) ReadTemporalTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, key string) (economy.TemporalState, bool, error) {
	if q == nil {
		return economy.TemporalState{}, false, errors.New("nil temporal queryer")
	}
	var out economy.TemporalState
	err := q.QueryRow(ctx, `SELECT player_id,resource_key,stored_amount,regen_anchor_at,policy_version,COALESCE(content_revision,''),state_version,updated_at FROM player_temporal_resources WHERE player_id=$1 AND resource_key=$2`, int64(pid), key).Scan((*int64)(&out.PlayerID), &out.ResourceKey, &out.StoredAmount, &out.RegenAnchorAt, &out.PolicyVersion, &out.ContentRevision, &out.StateVersion, &out.UpdatedAt)
	if noRows(err) {
		return economy.TemporalState{}, false, nil
	}
	return out, err == nil, err
}

func (Store) ResolveLegacyTemporalPolicyTx(ctx context.Context, q tx.Queryer, key, policyVersion string) (appi5.ResourcePolicy, error) {
	if q == nil || key == "" || policyVersion == "" {
		return appi5.ResourcePolicy{}, economy.ErrUnknownResource
	}
	var regenSec, regenAmount, naturalCap int64
	var allowAbove bool
	err := q.QueryRow(ctx, `SELECT COALESCE(temporal_regen_seconds,0),COALESCE(temporal_regen_amount,0),COALESCE(temporal_natural_cap,0),temporal_allow_explicit_above_cap FROM i5_resource_registry WHERE class='TEMPORAL' AND resource_key=$1 AND policy_version=$2`, key, policyVersion).Scan(&regenSec, &regenAmount, &naturalCap, &allowAbove)
	if err != nil {
		if noRows(err) {
			return appi5.ResourcePolicy{}, economy.ErrUnknownResource
		}
		return appi5.ResourcePolicy{}, err
	}
	p := economy.TemporalPolicy{Version: policyVersion, RegenEvery: time.Duration(regenSec) * time.Second, RegenAmount: regenAmount, NaturalCap: naturalCap, AllowExplicitGrantAboveNaturalCap: allowAbove}
	if err := p.Validate(); err != nil {
		return appi5.ResourcePolicy{}, err
	}
	return appi5.ResourcePolicy{Kind: grant.Temporal, Temporal: &p, PolicyVersion: policyVersion}, nil
}

func (Store) LockEconomyOwnerTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) error {
	var one int
	err := t.QueryRow(ctx, `SELECT 1 FROM player_economy_owners WHERE player_id=$1 FOR UPDATE`, int64(pid)).Scan(&one)
	if noRows(err) {
		return errors.New("typed-economy owner root missing")
	}
	return err
}

func (Store) LockMailNamespaceCounterTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, ns mail.Namespace) error {
	// Prepare a stable allocator row before any Grant mutation. Creating the
	// row with next_wire_id=1 allocates no mail id; AllocateMailWireIDTx will
	// advance it and return 1 on the first actual mail creation. The unique
	// (recipient,namespace) key serializes concurrent first preparation.
	if _, err := t.Exec(ctx, `INSERT INTO mail_namespace_counters(recipient_player_id,namespace,next_wire_id,state_version) VALUES($1,$2,1,1) ON CONFLICT(recipient_player_id,namespace) DO NOTHING`, int64(pid), ns.String()); err != nil {
		return err
	}
	var next int64
	err := t.QueryRow(ctx, `SELECT next_wire_id FROM mail_namespace_counters WHERE recipient_player_id=$1 AND namespace=$2 FOR UPDATE`, int64(pid), ns.String()).Scan(&next)
	return err
}

func (Store) LockScalarTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, key string, now time.Time) (economy.ScalarBalance, bool, error) {
	var b economy.ScalarBalance
	err := t.QueryRow(ctx, `SELECT player_id,resource_key,amount,state_version,updated_at FROM player_currency_balances WHERE player_id=$1 AND resource_key=$2 FOR UPDATE`, int64(pid), key).Scan((*int64)(&b.PlayerID), &b.ResourceKey, &b.Amount, &b.StateVersion, &b.UpdatedAt)
	if noRows(err) {
		return economy.ScalarBalance{}, false, nil
	}
	return b, err == nil, err
}
func (Store) SaveScalarTx(ctx context.Context, t tx.Tx, b economy.ScalarBalance, exists bool) error {
	if !exists {
		tag, err := t.Exec(ctx, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at) VALUES($1,$2,$3,$4,$5)`, int64(b.PlayerID), b.ResourceKey, b.Amount, b.StateVersion, b.UpdatedAt.UTC())
		if err != nil {
			return err
		}
		return rowsOne(tag, "scalar insert")
	}
	tag, err := t.Exec(ctx, `UPDATE player_currency_balances SET amount=$3,state_version=$4,updated_at=$5 WHERE player_id=$1 AND resource_key=$2 AND state_version=$6`, int64(b.PlayerID), b.ResourceKey, b.Amount, b.StateVersion, b.UpdatedAt.UTC(), b.StateVersion-1)
	if err != nil {
		return err
	}
	return rowsOne(tag, "scalar update")
}
func (Store) LockTemporalTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, key string) (economy.TemporalState, bool, error) {
	var s economy.TemporalState
	err := t.QueryRow(ctx, `SELECT player_id,resource_key,stored_amount,regen_anchor_at,policy_version,COALESCE(content_revision,''),state_version,updated_at FROM player_temporal_resources WHERE player_id=$1 AND resource_key=$2 FOR UPDATE`, int64(pid), key).Scan((*int64)(&s.PlayerID), &s.ResourceKey, &s.StoredAmount, &s.RegenAnchorAt, &s.PolicyVersion, &s.ContentRevision, &s.StateVersion, &s.UpdatedAt)
	if noRows(err) {
		return economy.TemporalState{}, false, nil
	}
	return s, err == nil, err
}
func (Store) SaveTemporalTx(ctx context.Context, t tx.Tx, s economy.TemporalState) error {
	var anchor any
	if s.RegenAnchorAt != nil {
		anchor = s.RegenAnchorAt.UTC()
	}
	tag, err := t.Exec(ctx, `UPDATE player_temporal_resources SET stored_amount=$3,regen_anchor_at=$4,policy_version=$5,state_version=$6,updated_at=$7 WHERE player_id=$1 AND resource_key=$2 AND state_version=$8`, int64(s.PlayerID), s.ResourceKey, s.StoredAmount, anchor, s.PolicyVersion, s.StateVersion, s.UpdatedAt.UTC(), s.StateVersion-1)
	if err != nil {
		return err
	}
	return rowsOne(tag, "temporal update")
}
func (Store) RebindTemporalTx(ctx context.Context, t tx.Tx, s economy.TemporalState, expectedVersion int64) error {
	if s.ContentRevision == "" || s.PolicyVersion == "" || s.StateVersion != expectedVersion+1 {
		return errors.New("invalid temporal rebind state")
	}
	var anchor any
	if s.RegenAnchorAt != nil {
		anchor = s.RegenAnchorAt.UTC()
	}
	tag, err := t.Exec(ctx, `UPDATE player_temporal_resources
SET stored_amount=$3,regen_anchor_at=$4,policy_version=$5,content_revision=$6,state_version=$7,updated_at=$8
WHERE player_id=$1 AND resource_key=$2 AND state_version=$9 AND content_revision IS NULL`,
		int64(s.PlayerID), s.ResourceKey, s.StoredAmount, anchor, s.PolicyVersion, s.ContentRevision, s.StateVersion, s.UpdatedAt.UTC(), expectedVersion)
	if err != nil {
		return err
	}
	return rowsOne(tag, "temporal legacy rebind")
}

func (Store) LockStackTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, item int64, now time.Time) (economy.StackState, bool, error) {
	var s economy.StackState
	err := t.QueryRow(ctx, `SELECT player_id,item_id,quantity,state_version,acquired_at,updated_at FROM player_item_stacks WHERE player_id=$1 AND item_id=$2 FOR UPDATE`, int64(pid), item).Scan((*int64)(&s.PlayerID), &s.ItemID, &s.Quantity, &s.StateVersion, &s.AcquiredAt, &s.UpdatedAt)
	if noRows(err) {
		return economy.StackState{}, false, nil
	}
	return s, err == nil, err
}
func (Store) SaveStackTx(ctx context.Context, t tx.Tx, s economy.StackState, exists bool) error {
	if err := s.Validate(); err != nil {
		return err
	}
	if s.Quantity == 0 {
		if !exists {
			return nil // An absent zero balance must not manufacture a row.
		}
		tag, err := t.Exec(ctx, `DELETE FROM player_item_stacks WHERE player_id=$1 AND item_id=$2 AND state_version=$3`, int64(s.PlayerID), s.ItemID, s.StateVersion-1)
		if err != nil {
			return err
		}
		return rowsOne(tag, "stack delete")
	}
	if !exists {
		tag, err := t.Exec(ctx, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at) VALUES($1,$2,$3,$4,$5,$6)`, int64(s.PlayerID), s.ItemID, s.Quantity, s.StateVersion, s.AcquiredAt.UTC(), s.UpdatedAt.UTC())
		if err != nil {
			return err
		}
		return rowsOne(tag, "stack insert")
	}
	tag, err := t.Exec(ctx, `UPDATE player_item_stacks SET quantity=$3,state_version=$4,updated_at=$5 WHERE player_id=$1 AND item_id=$2 AND state_version=$6`, int64(s.PlayerID), s.ItemID, s.Quantity, s.StateVersion, s.UpdatedAt.UTC(), s.StateVersion-1)
	if err != nil {
		return err
	}
	return rowsOne(tag, "stack update")
}

func (Store) DeleteStackTx(ctx context.Context, t tx.Tx, s economy.StackState) error {
	tag, err := t.Exec(ctx, `DELETE FROM player_item_stacks WHERE player_id=$1 AND item_id=$2 AND state_version=$3`, int64(s.PlayerID), s.ItemID, s.StateVersion-1)
	if err != nil {
		return err
	}
	return rowsOne(tag, "stack delete")
}

func (Store) LockProgressionTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) (player.Progression, error) {
	var p player.Progression
	err := t.QueryRow(ctx, `SELECT player_id,level,exp,state_version,updated_at FROM player_progression WHERE player_id=$1 FOR UPDATE`, int64(pid)).Scan((*int64)(&p.PlayerID), &p.Level, &p.Exp, &p.StateVersion, &p.UpdatedAt)
	return p, err
}
func (Store) SaveProgressionTx(ctx context.Context, t tx.Tx, p player.Progression, old int64) error {
	tag, err := t.Exec(ctx, `UPDATE player_progression SET level=$2,exp=$3,state_version=$4,updated_at=$5 WHERE player_id=$1 AND state_version=$6`, int64(p.PlayerID), p.Level, p.Exp, p.StateVersion, p.UpdatedAt.UTC(), old)
	if err != nil {
		return err
	}
	return rowsOne(tag, "progression")
}

func (Store) LockFunctionStateTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) (int64, error) {
	var version int64
	err := t.QueryRow(ctx, `SELECT state_version FROM player_function_state_owners WHERE player_id=$1 FOR UPDATE`, int64(pid)).Scan(&version)
	return version, err
}

func (Store) InsertFunctionEligibilityTx(ctx context.Context, t tx.Tx, e player.FunctionEligibility) (bool, error) {
	if err := e.Validate(); err != nil {
		return false, err
	}
	tag, err := t.Exec(ctx, `INSERT INTO player_function_eligibility(player_id,function_id,content_revision,source_fact_key,eligible_at) VALUES($1,$2,$3,$4,$5) ON CONFLICT(player_id,function_id) DO NOTHING`, int64(e.PlayerID), e.FunctionID, e.ContentRevision, e.SourceFactKey, e.EligibleAt.UTC())
	if err != nil {
		return false, err
	}
	n := tag.RowsAffected()
	if n < 0 || n > 1 {
		return false, fmt.Errorf("function eligibility insert affected %d rows", n)
	}
	return n == 1, nil
}

func (Store) InsertFunctionUnlockTx(ctx context.Context, t tx.Tx, u player.FunctionUnlock) (bool, error) {
	if err := u.Validate(); err != nil {
		return false, err
	}
	tag, err := t.Exec(ctx, `INSERT INTO player_function_unlocks(player_id,function_id,opened_at,source_fact_key,state_version) VALUES($1,$2,$3,$4,1) ON CONFLICT(player_id,function_id) DO NOTHING`, int64(u.PlayerID), u.FunctionID, u.OpenedAt.UTC(), u.SourceFactKey)
	if err != nil {
		return false, err
	}
	n := tag.RowsAffected()
	if n < 0 || n > 1 {
		return false, fmt.Errorf("function unlock insert affected %d rows", n)
	}
	return n == 1, nil
}

func (Store) AdvanceFunctionStateTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, expected int64, now time.Time) error {
	if expected <= 0 || now.IsZero() {
		return errors.New("invalid function state advance")
	}
	tag, err := t.Exec(ctx, `UPDATE player_function_state_owners SET state_version=state_version+1,updated_at=$3 WHERE player_id=$1 AND state_version=$2`, int64(pid), expected, now.UTC())
	if err != nil {
		return err
	}
	return rowsOne(tag, "function state")
}

func (Store) AllocateMailWireIDTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, ns mail.Namespace) (int64, error) {
	var id int64
	err := t.QueryRow(ctx, `INSERT INTO mail_namespace_counters(recipient_player_id,namespace,next_wire_id,state_version) VALUES($1,$2,2,1) ON CONFLICT(recipient_player_id,namespace) DO UPDATE SET next_wire_id=mail_namespace_counters.next_wire_id+1,state_version=mail_namespace_counters.state_version+1 RETURNING next_wire_id-1`, int64(pid), ns.String()).Scan(&id)
	return id, err
}
func (Store) InsertMailTx(ctx context.Context, t tx.Tx, r mail.Record) error {
	if err := r.Validate(); err != nil {
		return err
	}
	var expires any
	if r.ExpiresAt != nil {
		expires = r.ExpiresAt.UTC()
	}
	tag, err := t.Exec(ctx, `INSERT INTO mail_records(mail_uuid,recipient_player_id,namespace,wire_id,source_kind,source_key,category,title,sender,body,created_at,expires_at,read_at,shown,claimed_at,platform_eligibility,compatibility_policy_version,state_version) VALUES($1::uuid,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,NULL,$13,NULL,$14,$15,$16)`, r.MailUUID.String(), int64(r.Recipient), r.Address.Namespace.String(), r.Address.WireID, r.SourceKind, r.SourceKey, r.Category, r.Title, r.Sender, r.Body, r.CreatedAt.UTC(), expires, r.Shown, r.Platform.String(), r.CompatibilityPolicyVersion, r.StateVersion)
	if err != nil {
		return err
	}
	if err = rowsOne(tag, "mail insert"); err != nil {
		return err
	}
	for _, a := range r.Attachments {
		meta, err := json.Marshal(a.Line.Metadata)
		if err != nil {
			return err
		}
		var key any
		if a.Line.ResourceKey != "" {
			key = a.Line.ResourceKey
		}
		var item any
		if a.Line.ItemID > 0 {
			item = a.Line.ItemID
		}
		tag, err = t.Exec(ctx, `INSERT INTO mail_attachments(mail_uuid,ordinal,grant_line_kind,resource_key,item_id,amount,metadata) VALUES($1::uuid,$2,$3,$4,$5,$6,$7::jsonb)`, r.MailUUID.String(), a.Ordinal, string(a.Line.Kind), key, item, a.Line.Amount, string(meta))
		if err != nil {
			return err
		}
		if err = rowsOne(tag, "mail attachment"); err != nil {
			return err
		}
	}
	return nil
}

const mailListJSON = `
WITH active AS (
 SELECT * FROM mail_records WHERE recipient_player_id=$1 AND (expires_at IS NULL OR expires_at>$2)
), page AS (
 SELECT * FROM active ORDER BY created_at DESC,namespace,wire_id DESC LIMIT $3
)
SELECT COALESCE((SELECT jsonb_agg(jsonb_build_object(
 'mail_uuid',p.mail_uuid::text,'recipient',p.recipient_player_id,'namespace',p.namespace,'wire_id',p.wire_id,
 'source_kind',p.source_kind,'source_key',p.source_key,'category',p.category,'title',p.title,'sender',p.sender,'body',p.body,
 'created_at',p.created_at,'expires_at',p.expires_at,'read_at',p.read_at,'shown',p.shown,'claimed_at',p.claimed_at,
 'platform',p.platform_eligibility,'policy',p.compatibility_policy_version,'state_version',p.state_version,
 'attachments',COALESCE((SELECT jsonb_agg(jsonb_build_object('ordinal',a.ordinal,'kind',a.grant_line_kind,'resource_key',a.resource_key,'item_id',a.item_id,'amount',a.amount,'metadata',a.metadata) ORDER BY a.ordinal) FROM mail_attachments a WHERE a.mail_uuid=p.mail_uuid),'[]'::jsonb)
 ) ORDER BY p.created_at DESC,p.namespace,p.wire_id DESC)::text FROM page p),'[]'),
 (SELECT count(*) FROM active), (SELECT count(*) FROM active WHERE read_at IS NULL)`

func (s Store) ListMail(ctx context.Context, pid identity.PlayerID, now time.Time, limit int) ([]mail.Record, int64, int64, error) {
	if s.Queryer == nil {
		return nil, 0, 0, errors.New("nil I5 queryer")
	}
	return s.ListMailTx(ctx, s.Queryer, pid, now, limit)
}
func (Store) ListMailTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, now time.Time, limit int) ([]mail.Record, int64, int64, error) {
	var raw string
	var total, fresh int64
	if err := q.QueryRow(ctx, mailListJSON, int64(pid), now.UTC(), limit).Scan(&raw, &total, &fresh); err != nil {
		return nil, 0, 0, err
	}
	r, err := decodeMailRows([]byte(raw))
	return r, total, fresh, err
}

func (Store) LockMailTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, addr mail.Address) (mail.Record, error) {
	var uuid, ns, sourceKind, sourceKey, title, sender, body, platform, policy string
	var rec, wire, category, version int64
	var created time.Time
	var expires, read, claimed *time.Time
	var shown bool
	err := t.QueryRow(ctx, `SELECT mail_uuid::text,recipient_player_id,namespace,wire_id,source_kind,source_key,category,title,sender,body,created_at,expires_at,read_at,shown,claimed_at,platform_eligibility,compatibility_policy_version,state_version FROM mail_records WHERE recipient_player_id=$1 AND namespace=$2 AND wire_id=$3 FOR UPDATE`, int64(pid), addr.Namespace.String(), addr.WireID).Scan(&uuid, &rec, &ns, &wire, &sourceKind, &sourceKey, &category, &title, &sender, &body, &created, &expires, &read, &shown, &claimed, &platform, &policy, &version)
	if err != nil {
		if noRows(err) {
			return mail.Record{}, appi5.ErrMailNotFound
		}
		return mail.Record{}, err
	}
	var ar string
	if err := t.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('ordinal',ordinal,'kind',grant_line_kind,'resource_key',resource_key,'item_id',item_id,'amount',amount,'metadata',metadata) ORDER BY ordinal),'[]'::jsonb)::text FROM mail_attachments WHERE mail_uuid=$1::uuid`, uuid).Scan(&ar); err != nil {
		return mail.Record{}, err
	}
	u, err := ids.ParseUUID(uuid)
	if err != nil {
		return mail.Record{}, err
	}
	n, err := namespace(ns)
	if err != nil {
		return mail.Record{}, err
	}
	p, err := platformValue(platform)
	if err != nil {
		return mail.Record{}, err
	}
	atts, err := decodeAttachments([]byte(ar))
	if err != nil {
		return mail.Record{}, err
	}
	return mail.Record{MailUUID: u, Recipient: identity.PlayerID(rec), Address: mail.Address{Namespace: n, WireID: wire}, SourceKind: sourceKind, SourceKey: sourceKey, Category: category, Title: title, Sender: sender, Body: body, CreatedAt: created.UTC(), ExpiresAt: utcPtr(expires), ReadAt: utcPtr(read), Shown: shown, ClaimedAt: utcPtr(claimed), Platform: p, CompatibilityPolicyVersion: policy, StateVersion: version, Attachments: atts}, nil
}
func (Store) SaveMailStateTx(ctx context.Context, t tx.Tx, r mail.Record, old int64) error {
	tag, err := t.Exec(ctx, `UPDATE mail_records SET read_at=$2,shown=$3,claimed_at=$4,state_version=$5 WHERE mail_uuid=$1::uuid AND state_version=$6`, r.MailUUID.String(), r.ReadAt, r.Shown, r.ClaimedAt, r.StateVersion, old)
	if err != nil {
		return err
	}
	return rowsOne(tag, "mail state")
}

func (s Store) ListObjectives(ctx context.Context, pid identity.PlayerID, family objective.StockFamily, now time.Time) ([]objective.Instance, []appi5.ObjectiveDefinition, error) {
	if s.Queryer == nil {
		return nil, nil, errors.New("nil I5 queryer")
	}
	_ = family // Content-revision rows are family-resolved by the content owner.
	_ = now
	var raw string
	q := `SELECT COALESCE(jsonb_agg(jsonb_build_object(
'player_id',i.player_id,'program_id',i.program_id,'objective_id',i.objective_id,'generation_id',i.generation_id,
'definition_revision',i.definition_revision,'content_revision',COALESCE(i.content_revision,''),'legacy_definition',(i.content_revision IS NULL),
'progress',i.progress,'completed_at',i.completed_at,'claim_state',i.claim_state,'claimed_at',i.claimed_at,'state_version',i.state_version,
'family',COALESCE(d.stock_family,0),'strategy',COALESCE(d.strategy,''),'fact',COALESCE(d.accepted_fact_kind,''),'target',COALESCE(d.target,0),
'reward_plan',COALESCE(d.reward_plan,'{}'::jsonb),'huoyue',COALESCE(d.huoyue,0)) ORDER BY i.objective_id,i.generation_id),'[]'::jsonb)::text
FROM player_mission_instances i
LEFT JOIN objective_definitions d ON i.content_revision IS NULL AND d.program_id=i.program_id AND d.objective_id=i.objective_id AND d.definition_revision=i.definition_revision
WHERE i.player_id=$1`
	if err := s.Queryer.QueryRow(ctx, q, int64(pid)).Scan(&raw); err != nil {
		return nil, nil, err
	}
	return decodeObjectiveRows([]byte(raw))
}

func (Store) LockObjectiveTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, family objective.StockFamily, objectiveID int64, generation string) (objective.Instance, appi5.ObjectiveDefinition, error) {
	_ = family // Verified by the application after exact definition resolution.
	var program, revision, contentRevision, claimState, strategy, fact, rewardJSON, gen string
	var p, oid, progress, version, fam, target, huoyue int64
	var completed, claimed *time.Time
	var legacy bool
	q := `SELECT i.player_id,i.program_id,i.objective_id,i.generation_id,i.definition_revision,COALESCE(i.content_revision,''),i.progress,i.completed_at,i.claim_state,i.claimed_at,i.state_version,
(i.content_revision IS NULL),COALESCE(d.stock_family,0),COALESCE(d.strategy,''),COALESCE(d.accepted_fact_kind,''),COALESCE(d.target,0),COALESCE(d.reward_plan,'{}'::jsonb)::text,COALESCE(d.huoyue,0)
FROM player_mission_instances i
LEFT JOIN objective_definitions d ON i.content_revision IS NULL AND d.program_id=i.program_id AND d.objective_id=i.objective_id AND d.definition_revision=i.definition_revision
WHERE i.player_id=$1 AND i.objective_id=$2 AND i.generation_id=$3
FOR UPDATE OF i`
	err := t.QueryRow(ctx, q, int64(pid), objectiveID, generation).Scan(&p, &program, &oid, &gen, &revision, &contentRevision, &progress, &completed, &claimState, &claimed, &version, &legacy, &fam, &strategy, &fact, &target, &rewardJSON, &huoyue)
	if err != nil {
		if noRows(err) {
			return objective.Instance{}, appi5.ObjectiveDefinition{}, appi5.ErrObjectiveNotFound
		}
		return objective.Instance{}, appi5.ObjectiveDefinition{}, err
	}
	return objectivePair(identity.PlayerID(p), program, oid, gen, revision, contentRevision, progress, completed, claimState, claimed, version, legacy, objective.StockFamily(fam), strategy, fact, target, []byte(rewardJSON), huoyue)
}

const lockObjectiveForClaimQuery = `WITH candidate AS MATERIALIZED (
 SELECT i.*
 FROM player_mission_instances i
 WHERE i.player_id=$1 AND i.objective_id=$2 AND ($3='' OR i.generation_id=$3)
 FOR UPDATE OF i
), unique_candidate AS (
 SELECT * FROM candidate WHERE (SELECT count(*) FROM candidate)=1
)
SELECT i.player_id,i.program_id,i.objective_id,i.generation_id,i.definition_revision,COALESCE(i.content_revision,''),i.progress,i.completed_at,i.claim_state,i.claimed_at,i.state_version,
(i.content_revision IS NULL),COALESCE(d.stock_family,0),COALESCE(d.strategy,''),COALESCE(d.accepted_fact_kind,''),COALESCE(d.target,0),COALESCE(d.reward_plan,'{}'::jsonb)::text,COALESCE(d.huoyue,0)
FROM unique_candidate i
LEFT JOIN objective_definitions d ON i.content_revision IS NULL AND d.program_id=i.program_id AND d.objective_id=i.objective_id AND d.definition_revision=i.definition_revision`

func (Store) LockObjectiveForClaimTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, objectiveID int64, generationHint string) (objective.Instance, appi5.ObjectiveDefinition, error) {
	var program, revision, contentRevision, claimState, strategy, fact, rewardJSON, gen string
	var p, oid, progress, version, fam, target, huoyue int64
	var completed, claimed *time.Time
	var legacy bool
	err := t.QueryRow(ctx, lockObjectiveForClaimQuery, int64(pid), objectiveID, generationHint).Scan(&p, &program, &oid, &gen, &revision, &contentRevision, &progress, &completed, &claimState, &claimed, &version, &legacy, &fam, &strategy, &fact, &target, &rewardJSON, &huoyue)
	if err != nil {
		if noRows(err) {
			return objective.Instance{}, appi5.ObjectiveDefinition{}, appi5.ErrObjectiveNotFound
		}
		return objective.Instance{}, appi5.ObjectiveDefinition{}, err
	}
	return objectivePair(identity.PlayerID(p), program, oid, gen, revision, contentRevision, progress, completed, claimState, claimed, version, legacy, objective.StockFamily(fam), strategy, fact, target, []byte(rewardJSON), huoyue)
}

func (Store) SaveObjectiveTx(ctx context.Context, t tx.Tx, i objective.Instance, old int64) error {
	state := "UNCLAIMED"
	if i.ClaimState == objective.Claimed {
		state = "CLAIMED"
	}
	tag, err := t.Exec(ctx, `UPDATE player_mission_instances SET progress=$5,completed_at=$6,claim_state=$7,claimed_at=$8,state_version=$9 WHERE player_id=$1 AND program_id=$2 AND objective_id=$3 AND generation_id=$4 AND state_version=$10`, int64(i.PlayerID), i.ProgramID, i.ObjectiveID, i.GenerationID, i.Progress, i.CompletedAt, state, i.ClaimedAt, i.StateVersion, old)
	if err != nil {
		return err
	}
	return rowsOne(tag, "objective")
}

func (Store) LockRedeemByDigestTx(ctx context.Context, t tx.Tx, digest [32]byte) (appi5.RedeemCode, appi5.RedeemCampaign, grant.Plan, error) {
	var codeID, campaignID, codeKind, codeStatus, campStatus, subject, policy, rewardID, rewardJSON, audienceJSON string
	var useCount, stateVersion, perSubject int64
	var global, total *int64
	var starts, ends *time.Time
	q := `SELECT rc.code_id::text,rc.campaign_id::text,rc.code_kind,rc.global_use_limit,rc.use_count,rc.status,rc.state_version,c.status,c.redemption_subject,c.starts_at,c.ends_at,c.audience_policy::text,c.reward_bundle_revision_id::text,c.total_cap,c.per_subject_cap,c.policy_version,b.grant_plan::text FROM redeem_codes rc JOIN redeem_campaigns c ON c.campaign_id=rc.campaign_id JOIN redeem_reward_bundle_revisions b ON b.reward_bundle_revision_id=c.reward_bundle_revision_id WHERE rc.lookup_digest=$1 FOR UPDATE OF rc,c`
	err := t.QueryRow(ctx, q, digest[:]).Scan(&codeID, &campaignID, &codeKind, &global, &useCount, &codeStatus, &stateVersion, &campStatus, &subject, &starts, &ends, &audienceJSON, &rewardID, &total, &perSubject, &policy, &rewardJSON)
	if err != nil {
		return appi5.RedeemCode{}, appi5.RedeemCampaign{}, grant.Plan{}, err
	}
	ap, err := decodeAudience([]byte(audienceJSON))
	if err != nil {
		return appi5.RedeemCode{}, appi5.RedeemCampaign{}, grant.Plan{}, err
	}
	st, err := campaignStatus(campStatus)
	if err != nil {
		return appi5.RedeemCode{}, appi5.RedeemCampaign{}, grant.Plan{}, err
	}
	sub, err := subjectType(subject)
	if err != nil {
		return appi5.RedeemCode{}, appi5.RedeemCampaign{}, grant.Plan{}, err
	}
	plan, err := decodeGrantPlan([]byte(rewardJSON))
	if err != nil {
		return appi5.RedeemCode{}, appi5.RedeemCampaign{}, grant.Plan{}, err
	}
	code := appi5.RedeemCode{CodeID: codeID, CampaignID: campaignID, CodeKind: codeKind, GlobalUseLimit: global, UseCount: useCount, Status: codeStatus, StateVersion: stateVersion}
	camp := appi5.RedeemCampaign{CampaignID: campaignID, Campaign: redeem.Campaign{Status: st, Subject: sub, StartsAt: utcPtr(starts), EndsAt: utcPtr(ends), Audience: ap, PolicyVersion: policy}, RewardBundleRevisionID: rewardID, TotalCap: total, PerSubjectCap: perSubject}
	return code, camp, plan, nil
}
func (Store) FindRedemptionTx(ctx context.Context, t tx.Tx, codeID, subjectType, subjectID string, slot int64) (appi5.Redemption, bool, error) {
	var r appi5.Redemption
	var account, server int64
	var accountUUID string
	err := t.QueryRow(ctx, `SELECT redemption_id::text,code_id::text,subject_type,subject_id,redemption_slot,player_id,account_id::text,logical_server_id,reward_bundle_revision_id::text,grant_receipt_id::text,redeemed_at,request_platform_hint,policy_version FROM redeem_redemptions WHERE code_id=$1::uuid AND subject_type=$2 AND subject_id=$3 AND redemption_slot=$4`, codeID, subjectType, subjectID, slot).Scan(&r.RedemptionID, &r.CodeID, &r.SubjectType, &r.SubjectID, &r.Slot, (*int64)(&r.PlayerID), &accountUUID, &server, &r.RewardBundleRevisionID, &r.GrantReceiptID, &r.RedeemedAt, &r.Platform, &r.PolicyVersion)
	_ = account
	if noRows(err) {
		return appi5.Redemption{}, false, nil
	}
	if err != nil {
		return appi5.Redemption{}, false, err
	}
	u, err := ids.ParseUUID(accountUUID)
	if err != nil {
		return appi5.Redemption{}, false, err
	}
	aid, err := identity.AccountIDFrom(u)
	if err != nil {
		return appi5.Redemption{}, false, err
	}
	r.AccountID = aid
	r.LogicalServerID = identity.LogicalServerID(server)
	return r, true, nil
}
func (Store) CountCampaignRedemptionsTx(ctx context.Context, t tx.Tx, campaignID string) (int64, error) {
	var n int64
	err := t.QueryRow(ctx, `SELECT count(*) FROM redeem_redemptions r JOIN redeem_codes c ON c.code_id=r.code_id WHERE c.campaign_id=$1::uuid`, campaignID).Scan(&n)
	return n, err
}
func (Store) AdvanceRedeemCodeTx(ctx context.Context, t tx.Tx, c appi5.RedeemCode) error {
	tag, err := t.Exec(ctx, `UPDATE redeem_codes SET use_count=use_count+1,state_version=state_version+1,status=CASE WHEN global_use_limit IS NOT NULL AND use_count+1>=global_use_limit THEN 'EXHAUSTED' ELSE status END WHERE code_id=$1::uuid AND state_version=$2 AND status='ACTIVE' AND (global_use_limit IS NULL OR use_count<global_use_limit)`, c.CodeID, c.StateVersion)
	if err != nil {
		return err
	}
	return rowsOne(tag, "redeem code")
}
func (Store) InsertRedemptionTx(ctx context.Context, t tx.Tx, r appi5.Redemption) error {
	tag, err := t.Exec(ctx, `INSERT INTO redeem_redemptions(redemption_id,code_id,subject_type,subject_id,redemption_slot,player_id,account_id,logical_server_id,reward_bundle_revision_id,grant_receipt_id,redeemed_at,request_platform_hint,policy_version) VALUES($1::uuid,$2::uuid,$3,$4,$5,$6,$7::uuid,$8,$9::uuid,$10::uuid,$11,$12,$13)`, r.RedemptionID, r.CodeID, r.SubjectType, r.SubjectID, r.Slot, int64(r.PlayerID), r.AccountID.UUID().String(), int32(r.LogicalServerID), r.RewardBundleRevisionID, r.GrantReceiptID, r.RedeemedAt.UTC(), r.Platform, r.PolicyVersion)
	if err != nil {
		return err
	}
	return rowsOne(tag, "redemption")
}

// JSON decode helpers intentionally sit in the adapter: JSON is a PostgreSQL
// storage representation here, not a domain contract.
type attachJSON struct {
	Ordinal     int               `json:"ordinal"`
	Kind        string            `json:"kind"`
	ResourceKey *string           `json:"resource_key"`
	ItemID      *int64            `json:"item_id"`
	Amount      int64             `json:"amount"`
	Metadata    map[string]string `json:"metadata"`
}

func decodeAttachments(raw []byte) ([]mail.Attachment, error) {
	var rows []attachJSON
	if err := json.Unmarshal(raw, &rows); err != nil {
		return nil, err
	}
	out := make([]mail.Attachment, 0, len(rows))
	for _, x := range rows {
		l := grant.Line{Kind: grant.LineKind(x.Kind), Amount: x.Amount, Metadata: x.Metadata}
		if x.ResourceKey != nil {
			l.ResourceKey = *x.ResourceKey
		}
		if x.ItemID != nil {
			l.ItemID = *x.ItemID
		}
		a := mail.Attachment{Ordinal: x.Ordinal, Line: l}
		if err := a.Validate(); err != nil {
			return nil, err
		}
		out = append(out, a)
	}
	return out, nil
}

type mailJSON struct {
	MailUUID     string       `json:"mail_uuid"`
	Recipient    int64        `json:"recipient"`
	Namespace    string       `json:"namespace"`
	WireID       int64        `json:"wire_id"`
	SourceKind   string       `json:"source_kind"`
	SourceKey    string       `json:"source_key"`
	Category     int64        `json:"category"`
	Title        string       `json:"title"`
	Sender       string       `json:"sender"`
	Body         string       `json:"body"`
	CreatedAt    time.Time    `json:"created_at"`
	ExpiresAt    *time.Time   `json:"expires_at"`
	ReadAt       *time.Time   `json:"read_at"`
	Shown        bool         `json:"shown"`
	ClaimedAt    *time.Time   `json:"claimed_at"`
	Platform     string       `json:"platform"`
	Policy       string       `json:"policy"`
	StateVersion int64        `json:"state_version"`
	Attachments  []attachJSON `json:"attachments"`
}

func decodeMailRows(raw []byte) ([]mail.Record, error) {
	var rows []mailJSON
	if err := json.Unmarshal(raw, &rows); err != nil {
		return nil, err
	}
	out := make([]mail.Record, 0, len(rows))
	for _, x := range rows {
		u, err := ids.ParseUUID(x.MailUUID)
		if err != nil {
			return nil, err
		}
		ns, err := namespace(x.Namespace)
		if err != nil {
			return nil, err
		}
		pl, err := platformValue(x.Platform)
		if err != nil {
			return nil, err
		}
		ab, _ := json.Marshal(x.Attachments)
		atts, err := decodeAttachments(ab)
		if err != nil {
			return nil, err
		}
		r := mail.Record{MailUUID: u, Recipient: identity.PlayerID(x.Recipient), Address: mail.Address{Namespace: ns, WireID: x.WireID}, SourceKind: x.SourceKind, SourceKey: x.SourceKey, Category: x.Category, Title: x.Title, Sender: x.Sender, Body: x.Body, CreatedAt: x.CreatedAt.UTC(), ExpiresAt: utcPtr(x.ExpiresAt), ReadAt: utcPtr(x.ReadAt), Shown: x.Shown, ClaimedAt: utcPtr(x.ClaimedAt), Platform: pl, CompatibilityPolicyVersion: x.Policy, StateVersion: x.StateVersion, Attachments: atts}
		if err := r.Validate(); err != nil {
			return nil, err
		}
		out = append(out, r)
	}
	return out, nil
}
func namespace(s string) (mail.Namespace, error) {
	switch s {
	case "NORMAL":
		return mail.Normal, nil
	case "REGION":
		return mail.Region, nil
	default:
		return 0, errors.New("invalid mail namespace")
	}
}
func platformValue(s string) (mail.PlatformEligibility, error) {
	switch s {
	case "ANY":
		return mail.AnyPlatform, nil
	case "ANDROID":
		return mail.AndroidOnly, nil
	case "IOS":
		return mail.IOSOnly, nil
	default:
		return 0, errors.New("invalid mail platform")
	}
}
func utcPtr(p *time.Time) *time.Time {
	if p == nil {
		return nil
	}
	x := p.UTC()
	return &x
}

type objectiveJSON struct {
	PlayerID         int64           `json:"player_id"`
	ProgramID        string          `json:"program_id"`
	ObjectiveID      int64           `json:"objective_id"`
	GenerationID     string          `json:"generation_id"`
	Revision         string          `json:"definition_revision"`
	ContentRevision  string          `json:"content_revision"`
	LegacyDefinition bool            `json:"legacy_definition"`
	Progress         int64           `json:"progress"`
	CompletedAt      *time.Time      `json:"completed_at"`
	ClaimState       string          `json:"claim_state"`
	ClaimedAt        *time.Time      `json:"claimed_at"`
	StateVersion     int64           `json:"state_version"`
	Family           int64           `json:"family"`
	Strategy         string          `json:"strategy"`
	Fact             string          `json:"fact"`
	Target           int64           `json:"target"`
	Reward           json.RawMessage `json:"reward_plan"`
	Huoyue           int64           `json:"huoyue"`
}

func decodeObjectiveRows(raw []byte) ([]objective.Instance, []appi5.ObjectiveDefinition, error) {
	var rows []objectiveJSON
	if err := json.Unmarshal(raw, &rows); err != nil {
		return nil, nil, err
	}
	is := make([]objective.Instance, 0, len(rows))
	ds := make([]appi5.ObjectiveDefinition, 0, len(rows))
	for _, x := range rows {
		i, d, err := objectivePair(identity.PlayerID(x.PlayerID), x.ProgramID, x.ObjectiveID, x.GenerationID, x.Revision, x.ContentRevision, x.Progress, x.CompletedAt, x.ClaimState, x.ClaimedAt, x.StateVersion, x.LegacyDefinition, objective.StockFamily(x.Family), x.Strategy, x.Fact, x.Target, x.Reward, x.Huoyue)
		if err != nil {
			return nil, nil, err
		}
		is = append(is, i)
		ds = append(ds, d)
	}
	return is, ds, nil
}
func objectivePair(pid identity.PlayerID, program string, oid int64, generation, revision, contentRevision string, progress int64, completed *time.Time, claimState string, claimed *time.Time, version int64, legacy bool, family objective.StockFamily, strategy, fact string, target int64, rewardRaw []byte, huoyue int64) (objective.Instance, appi5.ObjectiveDefinition, error) {
	cs := objective.Unclaimed
	if claimState == "CLAIMED" {
		cs = objective.Claimed
	}
	i := objective.Instance{PlayerID: pid, ProgramID: program, ObjectiveID: oid, GenerationID: generation, DefinitionRevision: revision, ContentRevision: contentRevision, Progress: progress, CompletedAt: utcPtr(completed), ClaimState: cs, ClaimedAt: utcPtr(claimed), StateVersion: version}
	if err := i.Validate(); err != nil {
		return objective.Instance{}, appi5.ObjectiveDefinition{}, err
	}
	if contentRevision != "" {
		if legacy {
			return objective.Instance{}, appi5.ObjectiveDefinition{}, errors.New("objective content/legacy marker mismatch")
		}
		return i, appi5.ObjectiveDefinition{}, nil
	}
	if !legacy {
		return objective.Instance{}, appi5.ObjectiveDefinition{}, errors.New("legacy objective definition missing")
	}
	st, err := objectiveStrategy(strategy)
	if err != nil {
		return objective.Instance{}, appi5.ObjectiveDefinition{}, err
	}
	plan, err := decodeGrantPlan(rewardRaw)
	if err != nil {
		return objective.Instance{}, appi5.ObjectiveDefinition{}, err
	}
	d := appi5.ObjectiveDefinition{Family: family, Definition: objective.Definition{ProgramID: program, ObjectiveID: oid, DefinitionRevision: revision, Strategy: st, AcceptedFactKind: fact, Target: target}, GenerationID: generation, Reward: plan, Huoyue: huoyue}
	if err := d.Definition.Validate(); err != nil {
		return objective.Instance{}, appi5.ObjectiveDefinition{}, err
	}
	return i, d, nil
}

func objectiveStrategy(s string) (objective.Strategy, error) {
	switch s {
	case "HIGH_WATER":
		return objective.HighWaterFromCanonicalState, nil
	case "COMMITTED_DELTA":
		return objective.CommittedDeltaFact, nil
	case "TEMPORAL_ENTITLEMENT":
		return objective.TemporalEntitlement, nil
	case "DOMAIN_VALIDATED":
		return objective.DomainSpecificValidatedFact, nil
	default:
		return 0, errors.New("unknown objective strategy")
	}
}
func decodeGrantPlan(raw []byte) (grant.Plan, error) {
	var p grant.Plan
	if err := json.Unmarshal(raw, &p); err != nil {
		return grant.Plan{}, err
	}
	if p.Source.PolicyVersion == "" {
		return grant.Plan{}, errors.New("grant plan policy version missing")
	}
	if len(p.Lines) == 0 {
		return grant.Plan{}, errors.New("grant plan lines missing")
	}
	for _, l := range p.Lines {
		if err := l.Validate(); err != nil {
			return grant.Plan{}, err
		}
	}
	return p, nil
}

type audienceJSON struct {
	MinLevel       *int64  `json:"min_level"`
	MaxLevel       *int64  `json:"max_level"`
	LogicalServers []int32 `json:"logical_servers"`
}

func decodeAudience(raw []byte) (redeem.AudiencePolicy, error) {
	var x audienceJSON
	if len(raw) > 0 {
		if err := json.Unmarshal(raw, &x); err != nil {
			return redeem.AudiencePolicy{}, err
		}
	}
	m := map[identity.LogicalServerID]struct{}{}
	for _, v := range x.LogicalServers {
		ls := identity.LogicalServerID(v)
		if !ls.Valid() {
			return redeem.AudiencePolicy{}, errors.New("invalid campaign logical server")
		}
		m[ls] = struct{}{}
	}
	return redeem.AudiencePolicy{MinLevel: x.MinLevel, MaxLevel: x.MaxLevel, LogicalServers: m}, nil
}
func campaignStatus(s string) (redeem.CampaignStatus, error) {
	switch s {
	case "DRAFT":
		return redeem.Draft, nil
	case "ACTIVE":
		return redeem.Active, nil
	case "DISABLED":
		return redeem.Disabled, nil
	case "EXPIRED":
		return redeem.Expired, nil
	default:
		return "", errors.New("invalid campaign status")
	}
}
func subjectType(s string) (redeem.SubjectType, error) {
	switch s {
	case "PLAYER":
		return redeem.PlayerSubject, nil
	case "ACCOUNT":
		return redeem.AccountSubject, nil
	case "PLAYER_ON_LOGICAL_SERVER":
		return redeem.PlayerOnLogicalServer, nil
	case "GLOBAL_SINGLE_USE":
		return redeem.GlobalSingleUse, nil
	default:
		return "", errors.New("invalid redeem subject")
	}
}

var _ appi5.Store = Store{}
var _ = strconv.IntSize

// LockPlayerLevelTx is the narrow I5-owned cross-domain level read. It locks
// canonical progression so a caller-owned transaction can make a stable
// admission decision without reading player_progression directly.
func (Store) LockPlayerLevelTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) (int64, error) {
	p, err := (Store{}).LockProgressionTx(ctx, t, pid)
	if err != nil {
		return 0, err
	}
	return p.Level, nil
}
