package libraryforumstore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/libraryforum"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/libraryforum"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

var _ app.Store = Store{}

// ListCommentsTx answers one page in D483 order: likes descending, then oldest,
// then author id. The reaction subqueries are scoped to the same board.
func (Store) ListCommentsTx(c context.Context, q tx.Queryer, key d.Key, viewer identity.PlayerID, limit, offset int64) ([]d.Listed, error) {
	if q == nil || key.Validate() != nil || !viewer.Valid() || limit < 1 || limit > d.MaxPageRows || offset < 0 {
		return nil, app.ErrRequest
	}
	var raw string
	e := q.QueryRow(c, listCommentsQuery, int64(key.LogicalServerID), key.ForumType, key.TableID, int64(viewer), limit, offset).Scan(&raw)
	if e != nil {
		return nil, e
	}
	var rows []listedRow
	if e = json.Unmarshal([]byte(raw), &rows); e != nil {
		return nil, e
	}
	out := make([]d.Listed, 0, len(rows))
	for _, row := range rows {
		out = append(out, d.Listed{Author: identity.PlayerID(row.Author), Text: row.Comment, CreatedAt: row.CreatedAt.UTC(), UpdatedAt: row.UpdatedAt.UTC(), Likes: row.Likes, ViewerLiked: row.ViewerLiked})
	}
	return out, nil
}

type listedRow struct {
	Author      int64     `json:"author"`
	Comment     string    `json:"comment"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
	Likes       int64     `json:"likes"`
	ViewerLiked bool      `json:"viewer_liked"`
}

func (Store) LockCommentTx(c context.Context, t tx.Tx, key d.Key, author identity.PlayerID) (d.Comment, bool, error) {
	if t == nil || key.Validate() != nil || !author.Valid() {
		return d.Comment{}, false, app.ErrRequest
	}
	var rawServer int32
	var comment d.Comment
	var rawAuthor int64
	e := t.QueryRow(c, lockCommentQuery, int64(key.LogicalServerID), key.ForumType, key.TableID, int64(author)).Scan(&rawServer, &comment.Key.ForumType, &comment.Key.TableID, &rawAuthor, &comment.Text, &comment.CreatedAt, &comment.UpdatedAt)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return d.Comment{}, false, nil
	}
	if e != nil {
		return d.Comment{}, false, e
	}
	comment.Key.LogicalServerID = identity.LogicalServerID(rawServer)
	comment.Author = identity.PlayerID(rawAuthor)
	comment.CreatedAt, comment.UpdatedAt = comment.CreatedAt.UTC(), comment.UpdatedAt.UTC()
	return comment, true, comment.Validate()
}

func (Store) UpsertCommentTx(c context.Context, t tx.Tx, comment d.Comment) error {
	if t == nil || comment.Validate() != nil {
		return app.ErrRequest
	}
	tag, e := t.Exec(c, upsertCommentQuery, int64(comment.Key.LogicalServerID), comment.Key.ForumType, comment.Key.TableID, int64(comment.Author), comment.Text, comment.CreatedAt.UTC(), comment.UpdatedAt.UTC())
	if e == nil && tag.RowsAffected() != 1 {
		return app.ErrUnavailable
	}
	return e
}

func (Store) FindReactionTx(c context.Context, q tx.Queryer, key d.Key, author, viewer identity.PlayerID) (bool, error) {
	if q == nil || key.Validate() != nil || !author.Valid() || !viewer.Valid() {
		return false, app.ErrRequest
	}
	var one int64
	e := q.QueryRow(c, findReactionQuery, int64(key.LogicalServerID), key.ForumType, key.TableID, int64(author), int64(viewer)).Scan(&one)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return false, nil
	}
	if e != nil {
		return false, e
	}
	return true, nil
}

func (Store) InsertReactionTx(c context.Context, t tx.Tx, r d.Reaction) error {
	if t == nil || r.Validate() != nil {
		return app.ErrRequest
	}
	tag, e := t.Exec(c, insertReactionQuery, int64(r.Key.LogicalServerID), r.Key.ForumType, r.Key.TableID, int64(r.Author), int64(r.Viewer), r.CreatedAt.UTC())
	if e == nil && tag.RowsAffected() != 1 {
		return app.ErrUnavailable
	}
	return e
}

func (Store) DeleteReactionTx(c context.Context, t tx.Tx, key d.Key, author, viewer identity.PlayerID) error {
	if t == nil || key.Validate() != nil || !author.Valid() || !viewer.Valid() {
		return app.ErrRequest
	}
	tag, e := t.Exec(c, deleteReactionQuery, int64(key.LogicalServerID), key.ForumType, key.TableID, int64(author), int64(viewer))
	if e == nil && tag.RowsAffected() != 1 {
		return app.ErrUnavailable
	}
	return e
}

const listCommentsQuery = `
SELECT COALESCE(jsonb_agg(jsonb_build_object(
 'author',author,'comment',comment,'created_at',created_at,'updated_at',updated_at,
 'likes',likes,'viewer_liked',viewer_liked) ORDER BY likes DESC,created_at ASC,author ASC),'[]'::jsonb)::text
FROM (
 SELECT c.author_player_id AS author,c.comment,c.created_at,c.updated_at,
  (SELECT count(*) FROM library_forum_reactions r
   WHERE r.logical_server_id=c.logical_server_id AND r.forum_type=c.forum_type AND r.table_id=c.table_id AND r.author_player_id=c.author_player_id) AS likes,
  EXISTS(SELECT 1 FROM library_forum_reactions r
   WHERE r.logical_server_id=c.logical_server_id AND r.forum_type=c.forum_type AND r.table_id=c.table_id AND r.author_player_id=c.author_player_id AND r.viewer_player_id=$4) AS viewer_liked
 FROM library_forum_comments c
 WHERE c.logical_server_id=$1 AND c.forum_type=$2 AND c.table_id=$3
 ORDER BY likes DESC,c.created_at ASC,c.author_player_id ASC
 LIMIT $5 OFFSET $6
) page`

const lockCommentQuery = `SELECT logical_server_id,forum_type,table_id,author_player_id,comment,created_at,updated_at FROM library_forum_comments WHERE logical_server_id=$1 AND forum_type=$2 AND table_id=$3 AND author_player_id=$4 FOR UPDATE`

const upsertCommentQuery = `INSERT INTO library_forum_comments(logical_server_id,forum_type,table_id,author_player_id,comment,created_at,updated_at) VALUES($1,$2,$3,$4,$5,$6,$7) ON CONFLICT(logical_server_id,forum_type,table_id,author_player_id) DO UPDATE SET comment=EXCLUDED.comment,updated_at=EXCLUDED.updated_at`

const findReactionQuery = `SELECT 1 FROM library_forum_reactions WHERE logical_server_id=$1 AND forum_type=$2 AND table_id=$3 AND author_player_id=$4 AND viewer_player_id=$5`

const insertReactionQuery = `INSERT INTO library_forum_reactions(logical_server_id,forum_type,table_id,author_player_id,viewer_player_id,created_at) VALUES($1,$2,$3,$4,$5,$6)`

const deleteReactionQuery = `DELETE FROM library_forum_reactions WHERE logical_server_id=$1 AND forum_type=$2 AND table_id=$3 AND author_player_id=$4 AND viewer_player_id=$5`
