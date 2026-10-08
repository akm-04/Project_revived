// Package socialgiftstore persists only SocialGift-owned facts.
package socialgiftstore

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	sg "gxb.local/backend/v2/internal/application/socialgift"
	"gxb.local/backend/v2/internal/application/socialinbox"
	dg "gxb.local/backend/v2/internal/domain/generation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store struct{}
type transferWire struct {
	ID              string               `json:"transfer_id"`
	Sender          identity.PlayerID    `json:"sender_player_id"`
	Recipient       identity.PlayerID    `json:"recipient_player_id"`
	Policy          string               `json:"policy_id"`
	Day             string               `json:"sender_day"`
	Generation      string               `json:"sender_generation_id"`
	SendOperation   string               `json:"send_operation_id"`
	Fingerprint     string               `json:"request_fingerprint"`
	StartedAt       time.Time            `json:"send_started_at"`
	IssuedAt        time.Time            `json:"issued_at"`
	Friendship      int64                `json:"friendship_generation"`
	Block           int64                `json:"recipient_block_version"`
	Revision        string               `json:"reward_revision"`
	Vector          string               `json:"vector_fingerprint"`
	Key             string               `json:"resource_key"`
	Amount          int64                `json:"amount"`
	NoticeID        socialinbox.NoticeID `json:"notice_id"`
	Version         int64                `json:"state_version"`
	ClaimOperation  string               `json:"claim_operation_id"`
	ClaimDay        string               `json:"claim_day"`
	ClaimGeneration string               `json:"claim_generation_id"`
	ClaimedAt       *time.Time           `json:"claimed_at"`
	GrantReceipt    string               `json:"grant_receipt_id"`
	ClaimRevision   string               `json:"claim_content_revision"`
}

func generation(s string) (dg.GenerationID, error) {
	u, e := ids.ParseUUID(s)
	if e != nil {
		return dg.GenerationID{}, e
	}
	return dg.GenerationIDFrom(u)
}
func (w transferWire) value() (sg.Transfer, error) {
	var v sg.Transfer
	var e error
	v.ID, e = ids.ParseUUID(w.ID)
	if e != nil {
		return v, e
	}
	v.SendOperation, e = ids.ParseUUID(w.SendOperation)
	if e != nil {
		return v, e
	}
	v.SenderGeneration, e = generation(w.Generation)
	if e != nil {
		return v, e
	}
	v.Sender = w.Sender
	v.Recipient = w.Recipient
	v.SenderDay = w.Day
	v.RequestFingerprint = w.Fingerprint
	v.StartedAt = w.StartedAt.UTC()
	v.IssuedAt = w.IssuedAt.UTC()
	v.FriendshipGeneration = w.Friendship
	v.RecipientBlockVersion = w.Block
	v.RewardRevision = w.Revision
	v.VectorFingerprint = w.Vector
	v.Amount = w.Amount
	v.NoticeID = w.NoticeID
	v.Version = w.Version
	v.ClaimDay = w.ClaimDay
	v.ClaimedAt = w.ClaimedAt
	v.GrantReceiptID = w.GrantReceipt
	v.ClaimContentRevision = w.ClaimRevision
	if w.Policy != sg.DayPolicy || w.Key != "friendship_coin" {
		return v, sg.ErrConflict
	}
	if w.ClaimOperation != "" {
		v.ClaimOperation, e = ids.ParseUUID(w.ClaimOperation)
		if e != nil {
			return v, e
		}
		v.ClaimGeneration, e = generation(w.ClaimGeneration)
		if e != nil {
			return v, e
		}
	} else if w.ClaimGeneration != "" {
		return v, sg.ErrConflict
	}
	return v, v.Validate()
}
func read(c context.Context, q tx.Queryer, sql string, args ...any) (sg.Transfer, bool, error) {
	if q == nil {
		return sg.Transfer{}, false, sg.ErrInvalid
	}
	var raw []byte
	e := q.QueryRow(c, sql, args...).Scan(&raw)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return sg.Transfer{}, false, nil
	}
	if e != nil {
		return sg.Transfer{}, false, e
	}
	var w transferWire
	if e = json.Unmarshal(raw, &w); e != nil {
		return sg.Transfer{}, false, e
	}
	v, e := w.value()
	return v, e == nil, e
}
func (Store) ReadSend(c context.Context, q tx.Queryer, id ids.UUID) (sg.Transfer, bool, error) {
	return read(c, q, `SELECT to_jsonb(g) FROM social_gift_transfers g WHERE send_operation_id=$1::uuid`, id.String())
}
func (Store) ReadTransfer(c context.Context, q tx.Queryer, id ids.UUID) (sg.Transfer, bool, error) {
	return read(c, q, `SELECT to_jsonb(g) FROM social_gift_transfers g WHERE transfer_id=$1::uuid`, id.String())
}
func (Store) LockTransfer(c context.Context, t tx.Tx, a, b identity.PlayerID, day string) (sg.Transfer, bool, error) {
	return read(c, t, `SELECT to_jsonb(g) FROM social_gift_transfers g WHERE sender_player_id=$1 AND recipient_player_id=$2 AND policy_id=$3 AND sender_day=$4 FOR UPDATE`, int64(a), int64(b), sg.DayPolicy, day)
}

type epochWire struct {
	Player     identity.PlayerID `json:"player_id"`
	Policy     string            `json:"policy_id"`
	Day        string            `json:"day_token"`
	Generation string            `json:"generation_id"`
	Version    int64             `json:"state_version"`
	CreatedAt  time.Time         `json:"created_at"`
	UpdatedAt  time.Time         `json:"updated_at"`
}

func (w epochWire) value() (sg.Epoch, error) {
	g, e := generation(w.Generation)
	v := sg.Epoch{Player: w.Player, Day: w.Day, Generation: g, Version: w.Version, CreatedAt: w.CreatedAt.UTC(), UpdatedAt: w.UpdatedAt.UTC()}
	if e != nil || w.Policy != sg.DayPolicy {
		return v, sg.ErrConflict
	}
	return v, v.Validate()
}

// The held Social root fences absent epochs. Lock current and latest at 371;
// no row is inserted until the complete notice/epoch/transfer plan is held.
func (Store) LockEpoch(c context.Context, t tx.Tx, p identity.PlayerID, day string) (sg.Epoch, bool, sg.Epoch, bool, error) {
	var raw []byte
	e := t.QueryRow(c, `SELECT coalesce(jsonb_agg(to_jsonb(e) ORDER BY day_token DESC),'[]'::jsonb) FROM (SELECT * FROM social_gift_epochs WHERE player_id=$1 AND policy_id=$2 AND (day_token=$3 OR day_token=(SELECT max(day_token) FROM social_gift_epochs WHERE player_id=$1 AND policy_id=$2)) ORDER BY day_token ASC FOR UPDATE) e`, int64(p), sg.DayPolicy, day).Scan(&raw)
	if e != nil {
		return sg.Epoch{}, false, sg.Epoch{}, false, e
	}
	var w []epochWire
	if e = json.Unmarshal(raw, &w); e != nil {
		return sg.Epoch{}, false, sg.Epoch{}, false, e
	}
	var current, latest sg.Epoch
	var have bool
	for i, x := range w {
		v, e := x.value()
		if e != nil || v.Player != p {
			return current, false, latest, false, sg.ErrConflict
		}
		if i == 0 {
			latest = v
		}
		if v.Day == day {
			current = v
			have = true
		}
	}
	return current, have, latest, len(w) > 0, nil
}
func (Store) Counts(c context.Context, q tx.Queryer, p identity.PlayerID, day string) (int64, int64, error) {
	var a, b int64
	e := q.QueryRow(c, `SELECT (SELECT count(*) FROM social_gift_transfers WHERE sender_player_id=$1 AND policy_id=$2 AND sender_day=$3),(SELECT count(*) FROM social_gift_transfers WHERE recipient_player_id=$1 AND claim_day=$3 AND claim_operation_id IS NOT NULL)`, int64(p), sg.DayPolicy, day).Scan(&a, &b)
	return a, b, e
}
func (Store) PutEpoch(c context.Context, t tx.Tx, e sg.Epoch, exists bool, at time.Time) error {
	if e.Validate() != nil || at.Before(e.UpdatedAt) {
		return sg.ErrClock
	}
	var tag tx.CommandTag
	var err error
	if exists {
		tag, err = t.Exec(c, `UPDATE social_gift_epochs SET state_version=state_version+1,updated_at=$5 WHERE player_id=$1 AND policy_id=$2 AND day_token=$3 AND state_version=$4 AND generation_id=$6::uuid`, int64(e.Player), sg.DayPolicy, e.Day, e.Version, at, e.Generation.UUID().String())
	} else {
		tag, err = t.Exec(c, `INSERT INTO social_gift_epochs(player_id,policy_id,day_token,generation_id,state_version,created_at,updated_at) VALUES($1,$2,$3,$4::uuid,1,$5,$5)`, int64(e.Player), sg.DayPolicy, e.Day, e.Generation.UUID().String(), at)
	}
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return sg.ErrConflict
	}
	return nil
}
func (Store) InsertTransfer(c context.Context, t tx.Tx, v sg.Transfer) error {
	if v.Validate() != nil || !v.ClaimOperation.IsZero() {
		return sg.ErrConflict
	}
	_, e := t.Exec(c, `INSERT INTO social_gift_transfers(transfer_id,sender_player_id,recipient_player_id,policy_id,sender_day,sender_generation_id,send_operation_id,request_fingerprint,send_started_at,issued_at,friendship_generation,recipient_block_version,reward_revision,vector_fingerprint,resource_key,amount,notice_id,state_version) VALUES($1::uuid,$2,$3,$4,$5,$6::uuid,$7::uuid,$8,$9,$10,$11,$12,$13,$14,'friendship_coin',5,$15,1)`, v.ID.String(), int64(v.Sender), int64(v.Recipient), sg.DayPolicy, v.SenderDay, v.SenderGeneration.UUID().String(), v.SendOperation.String(), v.RequestFingerprint, v.StartedAt, v.IssuedAt, v.FriendshipGeneration, v.RecipientBlockVersion, v.RewardRevision, v.VectorFingerprint, int64(v.NoticeID))
	return e
}
func (Store) ClaimTransfer(c context.Context, t tx.Tx, v sg.Transfer, old int64) error {
	if v.Validate() != nil || v.ClaimOperation.IsZero() || v.Version != old+1 {
		return sg.ErrConflict
	}
	tag, e := t.Exec(c, `UPDATE social_gift_transfers SET claim_operation_id=$2::uuid,claim_day=$3,claim_generation_id=$4::uuid,claimed_at=$5,grant_receipt_id=$6,claim_content_revision=$7,state_version=state_version+1 WHERE transfer_id=$1::uuid AND state_version=$8 AND claim_operation_id IS NULL`, v.ID.String(), v.ClaimOperation.String(), v.ClaimDay, v.ClaimGeneration.UUID().String(), v.ClaimedAt, v.GrantReceiptID, v.ClaimContentRevision, old)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return sg.ErrConflict
	}
	return nil
}

type claimWire struct {
	Policy      string            `json:"policy_version"`
	CreatedAt   time.Time         `json:"created_at"`
	ID          string            `json:"operation_id"`
	Recipient   identity.PlayerID `json:"recipient_player_id"`
	Fingerprint string            `json:"request_fingerprint"`
	StartedAt   time.Time         `json:"operation_started_at"`
	DecisionAt  time.Time         `json:"decision_at"`
	Day         string            `json:"claim_day"`
	Generation  string            `json:"claim_generation_id"`
	Revision    string            `json:"content_revision"`
	Grant       string            `json:"grant_receipt_id"`
	Result      sg.Result         `json:"semantic_result"`
}

func (Store) ReadClaim(c context.Context, q tx.Queryer, id ids.UUID) (sg.ClaimOperation, bool, error) {
	var raw []byte
	e := q.QueryRow(c, `SELECT to_jsonb(o) FROM social_gift_claim_operations o WHERE operation_id=$1::uuid`, id.String()).Scan(&raw)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return sg.ClaimOperation{}, false, nil
	}
	if e != nil {
		return sg.ClaimOperation{}, false, e
	}
	var w claimWire
	if e = json.Unmarshal(raw, &w); e != nil {
		return sg.ClaimOperation{}, false, e
	}
	u, e := ids.ParseUUID(w.ID)
	v := sg.ClaimOperation{ID: u, Recipient: w.Recipient, Fingerprint: w.Fingerprint, StartedAt: w.StartedAt.UTC(), DecisionAt: w.DecisionAt.UTC(), Day: w.Day, Revision: w.Revision, Result: w.Result}
	if e != nil || u != id || w.Policy != sg.ClaimPolicy || !w.CreatedAt.Equal(w.DecisionAt) || w.Grant != w.Result.GrantReceiptID {
		return v, false, sg.ErrConflict
	}
	if w.Generation != "" {
		v.Generation, e = generation(w.Generation)
	}
	if e != nil || !v.Recipient.Valid() || len(v.Fingerprint) != 64 || v.StartedAt.IsZero() || v.DecisionAt.IsZero() || v.Revision != v.Result.Revision {
		return v, false, sg.ErrConflict
	}
	return v, true, nil
}
func (Store) ClaimTransfers(c context.Context, q tx.Queryer, id ids.UUID) ([]sg.Transfer, error) {
	var raw []byte
	e := q.QueryRow(c, `SELECT coalesce(jsonb_agg(to_jsonb(g) ORDER BY transfer_id),'[]'::jsonb) FROM social_gift_transfers g WHERE claim_operation_id=$1::uuid`, id.String()).Scan(&raw)
	if e != nil {
		return nil, e
	}
	var w []transferWire
	if e = json.Unmarshal(raw, &w); e != nil {
		return nil, e
	}
	v := make([]sg.Transfer, len(w))
	for i, x := range w {
		v[i], e = x.value()
		if e != nil {
			return nil, e
		}
	}
	return v, nil
}
func (Store) InsertClaim(c context.Context, t tx.Tx, v sg.ClaimOperation) error {
	raw, e := json.Marshal(v.Result)
	if e != nil {
		return e
	}
	var gen, receipt any
	if v.Generation.Valid() {
		gen = v.Generation.UUID().String()
	}
	if v.Result.GrantReceiptID != "" {
		receipt = v.Result.GrantReceiptID
	}
	_, e = t.Exec(c, `INSERT INTO social_gift_claim_operations(operation_id,recipient_player_id,request_fingerprint,operation_started_at,decision_at,claim_day,claim_generation_id,content_revision,grant_receipt_id,semantic_result,created_at) VALUES($1::uuid,$2,$3,$4,$5,$6,$7::uuid,$8,$9,$10::jsonb,$5)`, v.ID.String(), int64(v.Recipient), v.Fingerprint, v.StartedAt, v.DecisionAt, v.Day, gen, v.Revision, receipt, string(raw))
	return e
}

var _ sg.Store = Store{}

func (Store) SentRecipients(c context.Context, q tx.Queryer, p identity.PlayerID, day string) ([]identity.PlayerID, error) {
	var raw []byte
	e := q.QueryRow(c, `SELECT coalesce(jsonb_agg(recipient_player_id ORDER BY recipient_player_id),'[]'::jsonb) FROM social_gift_transfers WHERE sender_player_id=$1 AND policy_id=$2 AND sender_day=$3`, int64(p), sg.DayPolicy, day).Scan(&raw)
	if e != nil {
		return nil, e
	}
	var ids []identity.PlayerID
	e = json.Unmarshal(raw, &ids)
	return ids, e
}
