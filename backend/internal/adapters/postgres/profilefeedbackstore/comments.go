package profilefeedbackstore

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/profilefeedback"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/profilefeedback"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
	"time"
)

var _ app.CommentStore = Store{}

const commentJSON = `jsonb_build_object('ID',c.comment_id,'Target',c.target_player_id,'Author',c.author_player_id,'Content',c.content,'CreatedAt',c.created_at,'CreatedVersion',c.created_root_version,'DeletedAt',c.deleted_at,'DeletedVersion',c.deleted_root_version,'PraiseCount',(SELECT count(*) FROM player_profile_comment_reactions r WHERE r.comment_id=c.comment_id),'HasPraised',EXISTS(SELECT 1 FROM player_profile_comment_reactions r WHERE r.comment_id=c.comment_id AND r.actor_player_id=$2))`

func decodeComment(raw string) (d.Comment, error) {
	var r d.Comment
	e := json.Unmarshal([]byte(raw), &r)
	r.CreatedAt = r.CreatedAt.UTC()
	if r.DeletedAt != nil {
		v := r.DeletedAt.UTC()
		r.DeletedAt = &v
	}
	if e != nil {
		return r, e
	}
	return r, r.Validate()
}
func (Store) FindCommentTx(c context.Context, q tx.Queryer, id int64, actor identity.PlayerID) (d.Comment, bool, error) {
	if q == nil || id <= 0 || id > d.MaxWireCommentID || !actor.Valid() {
		return d.Comment{}, false, app.ErrInvalid
	}
	var raw string
	e := q.QueryRow(c, `SELECT `+commentJSON+`::text FROM player_profile_comments c WHERE c.comment_id=$1`, id, int64(actor)).Scan(&raw)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return d.Comment{}, false, nil
	}
	if e != nil {
		return d.Comment{}, false, e
	}
	r, e := decodeComment(raw)
	if r.ID != id {
		return r, true, app.ErrInvalid
	}
	return r, true, e
}
func (Store) InsertCommentTx(c context.Context, t tx.Tx, r d.Comment) (d.Comment, error) {
	// ID is allocated by the owned noncycling sequence, not by content IDs.
	if t == nil || r.ID != 0 || !r.Target.Valid() || !r.Author.Valid() || r.Target == r.Author || r.CreatedVersion <= 0 || r.CreatedAt.IsZero() || r.DeletedAt != nil {
		return r, app.ErrInvalid
	}
	if _, e := d.ModerateComment(r.Content, nil); e != nil {
		return r, e
	}
	e := t.QueryRow(c, `INSERT INTO player_profile_comments(target_player_id,author_player_id,content,created_at,created_root_version) VALUES($1,$2,$3,$4,$5) RETURNING comment_id`, int64(r.Target), int64(r.Author), r.Content, r.CreatedAt, r.CreatedVersion).Scan(&r.ID)
	if e != nil {
		return r, e
	}
	return r, r.Validate()
}
func (Store) DeleteCommentTx(c context.Context, t tx.Tx, r d.Comment, at time.Time, v int64) error {
	if t == nil || r.Validate() != nil || r.DeletedAt != nil || at.IsZero() || v <= r.CreatedVersion {
		return app.ErrInvalid
	}
	tag, e := t.Exec(c, `UPDATE player_profile_comments SET deleted_at=$2,deleted_root_version=$3 WHERE comment_id=$1 AND target_player_id=$4 AND deleted_at IS NULL`, r.ID, at.UTC(), v, int64(r.Target))
	if e == nil && tag.RowsAffected() != 1 {
		return app.ErrConflict
	}
	return e
}
func (Store) FindReactionTx(c context.Context, q tx.Queryer, id int64, actor identity.PlayerID) (d.CommentReaction, bool, error) {
	var r d.CommentReaction
	r.CommentID = id
	r.Actor = actor
	e := q.QueryRow(c, `SELECT first_at,root_version FROM player_profile_comment_reactions WHERE comment_id=$1 AND actor_player_id=$2`, id, int64(actor)).Scan(&r.FirstAt, &r.RootVersion)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return r, false, nil
	}
	if e != nil {
		return r, false, e
	}
	r.FirstAt = r.FirstAt.UTC()
	return r, true, r.Validate()
}
func (Store) InsertReactionTx(c context.Context, t tx.Tx, r d.CommentReaction) error {
	if t == nil || r.Validate() != nil {
		return app.ErrInvalid
	}
	tag, e := t.Exec(c, `INSERT INTO player_profile_comment_reactions(comment_id,actor_player_id,first_at,root_version) VALUES($1,$2,$3,$4)`, r.CommentID, int64(r.Actor), r.FirstAt, r.RootVersion)
	if e == nil && tag.RowsAffected() != 1 {
		return app.ErrConflict
	}
	return e
}
func (Store) CountCommentsTx(c context.Context, q tx.Queryer, target identity.PlayerID) (int64, error) {
	var n int64
	e := q.QueryRow(c, `SELECT count(*) FROM player_profile_comments WHERE target_player_id=$1 AND deleted_at IS NULL`, int64(target)).Scan(&n)
	if e == nil && (n < 0 || n > d.MaxWireCommentID) {
		e = app.ErrInvalid
	}
	return n, e
}
func (Store) ListCommentsTx(c context.Context, q tx.Queryer, target, actor identity.PlayerID, start, offset int64, best bool) ([]d.Comment, error) {
	out := []d.Comment{}
	if q == nil || !target.Valid() || !actor.Valid() || start < 0 || start > d.MaxWireCommentID || offset < 1 || offset > 20 {
		return nil, app.ErrRequest
	}
	// Count ranking is read-local to the caller's exact coherent snapshot.
	bestCTE := `WITH best AS (SELECT c.comment_id FROM player_profile_comments c WHERE c.target_player_id=$1 AND c.deleted_at IS NULL ORDER BY (SELECT count(*) FROM player_profile_comment_reactions r WHERE r.comment_id=c.comment_id) DESC,c.created_at DESC,c.comment_id DESC LIMIT 2) `
	filter := ` AND c.comment_id NOT IN(SELECT comment_id FROM best)`
	order := `c.created_at DESC,c.comment_id DESC`
	limit := `LIMIT $3 OFFSET $4`
	if best {
		filter = ` AND c.comment_id IN(SELECT comment_id FROM best)`
		order = `(SELECT count(*) FROM player_profile_comment_reactions r WHERE r.comment_id=c.comment_id) DESC,c.created_at DESC,c.comment_id DESC`
		offset = 2
		start = 0
	}
	sql := bestCTE + `SELECT COALESCE(jsonb_agg(page.row ORDER BY page.ordinal),'[]'::jsonb)::text FROM(SELECT ` + commentJSON + ` AS row,row_number()OVER(ORDER BY ` + order + `)AS ordinal FROM player_profile_comments c WHERE c.target_player_id=$1 AND c.deleted_at IS NULL` + filter + ` ORDER BY ` + order + ` ` + limit + `)page`
	var raw string
	e := q.QueryRow(c, sql, int64(target), int64(actor), offset, start).Scan(&raw)
	if e != nil {
		return nil, e
	}
	if e = json.Unmarshal([]byte(raw), &out); e != nil {
		return nil, e
	}
	for i := range out {
		out[i].CreatedAt = out[i].CreatedAt.UTC()
		if out[i].Validate() != nil || out[i].Target != target || out[i].DeletedAt != nil {
			return nil, app.ErrInvalid
		}
	}
	return out, nil
}
func admission(c context.Context, q tx.Queryer, sql string, args ...any) (app.CommentAdmission, bool, error) {
	var out app.CommentAdmission
	var raw, state, op, account string
	var actor, target int64
	e := q.QueryRow(c, sql, args...).Scan(&op, &actor, &target, &account, &raw, &state)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return out, false, nil
	}
	if e != nil {
		return out, false, e
	}
	dec := json.NewDecoder(bytes.NewReader([]byte(raw)))
	dec.DisallowUnknownFields()
	if e = dec.Decode(&out); e != nil {
		return out, true, e
	}
	var extra any
	if dec.Decode(&extra) != io.EOF {
		return out, true, app.ErrConflict
	}
	fp, e := receipt.FingerprintRequest(out.Command)
	if e != nil || fp != out.Fingerprint {
		return out, true, app.ErrConflict
	}
	content, yes := out.Operation.Policies.Get("content")
	if !yes || content != out.Revision {
		return out, true, app.ErrConflict
	}
	cp, yes := out.Operation.Policies.Get("profile-comment")
	if !yes || cp != d.CommentPolicyVersion {
		return out, true, app.ErrConflict
	}
	if out.Operation.ID.String() != op || int64(out.Actor) != actor || int64(out.Target) != target || out.Account != account || out.State != "PENDING" || out.Operation.ID.IsZero() || out.Operation.StartedAt.IsZero() || out.DecisionAt.IsZero() || out.Revision == "" || out.Command.Kind != "post" || out.Command.Target != out.Target {
		return out, true, app.ErrConflict
	}
	out.State = state
	out.DecisionAt = out.DecisionAt.UTC()
	out.Operation.StartedAt = out.Operation.StartedAt.UTC()
	return out, true, nil
}

const admissionFields = `operation_id::text,actor_player_id,target_player_id,account_uid,admission_payload::text,state`

func (Store) ReadAdmissionTx(c context.Context, q tx.Queryer, id string, lock bool) (app.CommentAdmission, bool, error) {
	sql := `SELECT ` + admissionFields + ` FROM player_profile_comment_operations WHERE operation_id=$1::uuid`
	if lock {
		sql += ` FOR UPDATE`
	}
	return admission(c, q, sql, id)
}
func (Store) PendingAdmissionTx(c context.Context, t tx.Tx, actor identity.PlayerID) (app.CommentAdmission, bool, error) {
	return admission(c, t, `SELECT `+admissionFields+` FROM player_profile_comment_operations WHERE actor_player_id=$1 AND state='PENDING' FOR UPDATE`, int64(actor))
}
func (Store) InsertAdmissionTx(c context.Context, t tx.Tx, a app.CommentAdmission) error {
	if t == nil || a.State != "PENDING" || a.Operation.ID.IsZero() || a.DecisionAt.IsZero() || !a.Actor.Valid() || a.Command.Kind != "post" || a.Target != a.Command.Target || a.Account == "" || a.Context == "" || a.Revision == "" {
		return app.ErrInvalid
	}
	raw, e := json.Marshal(a)
	if e != nil {
		return e
	}
	tag, e := t.Exec(c, `INSERT INTO player_profile_comment_operations(operation_id,actor_player_id,target_player_id,account_uid,admission_payload,state) VALUES($1::uuid,$2,$3,$4,$5::jsonb,'PENDING')`, a.Operation.ID.String(), int64(a.Actor), int64(a.Target), a.Account, string(raw))
	if e == nil && tag.RowsAffected() != 1 {
		return app.ErrConflict
	}
	return e
}
func (Store) SetAdmissionStateTx(c context.Context, t tx.Tx, id, from, to string) error {
	if t == nil || from != "PENDING" || (to != "ABORTED" && to != "COMMITTED") {
		return app.ErrInvalid
	}
	tag, e := t.Exec(c, `UPDATE player_profile_comment_operations SET state=$3 WHERE operation_id=$1::uuid AND state=$2`, id, from, to)
	if e == nil && tag.RowsAffected() != 1 {
		return app.ErrConflict
	}
	return e
}
