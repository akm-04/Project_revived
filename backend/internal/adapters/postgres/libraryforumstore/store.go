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
	e := q.QueryRow(c, listCommentsQuery, key.ForumType, key.TableID, int64(viewer), limit, offset).Scan(&raw)
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
	var comment d.Comment
	var rawAuthor int64
	e := t.QueryRow(c, lockCommentQuery, key.ForumType, key.TableID, int64(author)).Scan(&comment.Key.ForumType, &comment.Key.TableID, &rawAuthor, &comment.Text, &comment.CreatedAt, &comment.UpdatedAt)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return d.Comment{}, false, nil
	}
	if e != nil {
		return d.Comment{}, false, e
	}
	comment.Author = identity.PlayerID(rawAuthor)
	comment.CreatedAt, comment.UpdatedAt = comment.CreatedAt.UTC(), comment.UpdatedAt.UTC()
	return comment, true, comment.Validate()
}

func (Store) UpsertCommentTx(c context.Context, t tx.Tx, comment d.Comment) error {
	if t == nil || comment.Validate() != nil {
		return app.ErrRequest
	}
	tag, e := t.Exec(c, upsertCommentQuery, comment.Key.ForumType, comment.Key.TableID, int64(comment.Author), comment.Text, comment.CreatedAt.UTC(), comment.UpdatedAt.UTC())
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
	e := q.QueryRow(c, findReactionQuery, key.ForumType, key.TableID, int64(author), int64(viewer)).Scan(&one)
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
	tag, e := t.Exec(c, insertReactionQuery, r.Key.ForumType, r.Key.TableID, int64(r.Author), int64(r.Viewer), r.CreatedAt.UTC())
	if e == nil && tag.RowsAffected() != 1 {
		return app.ErrUnavailable
	}
	return e
}

func (Store) DeleteReactionTx(c context.Context, t tx.Tx, key d.Key, author, viewer identity.PlayerID) error {
	if t == nil || key.Validate() != nil || !author.Valid() || !viewer.Valid() {
		return app.ErrRequest
	}
	tag, e := t.Exec(c, deleteReactionQuery, key.ForumType, key.TableID, int64(author), int64(viewer))
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
   WHERE r.forum_type=c.forum_type AND r.table_id=c.table_id AND r.author_player_id=c.author_player_id) AS likes,
  EXISTS(SELECT 1 FROM library_forum_reactions r
   WHERE r.forum_type=c.forum_type AND r.table_id=c.table_id AND r.author_player_id=c.author_player_id AND r.viewer_player_id=$3) AS viewer_liked
 FROM library_forum_comments c
 WHERE c.forum_type=$1 AND c.table_id=$2 AND c.retired_at IS NULL
 ORDER BY likes DESC,c.created_at ASC,c.author_player_id ASC
 LIMIT $4 OFFSET $5
) page`

const lockCommentQuery = `SELECT forum_type,table_id,author_player_id,comment,created_at,updated_at FROM library_forum_comments WHERE forum_type=$1 AND table_id=$2 AND author_player_id=$3 AND retired_at IS NULL FOR UPDATE`

const upsertCommentQuery = `INSERT INTO library_forum_comments(forum_type,table_id,author_player_id,comment,created_at,updated_at) VALUES($1,$2,$3,$4,$5,$6) ON CONFLICT(forum_type,table_id,author_player_id) DO UPDATE SET comment=EXCLUDED.comment,created_at=EXCLUDED.created_at,updated_at=EXCLUDED.updated_at,retired_at=NULL`

const findReactionQuery = `SELECT 1 FROM library_forum_reactions WHERE forum_type=$1 AND table_id=$2 AND author_player_id=$3 AND viewer_player_id=$4`

const insertReactionQuery = `INSERT INTO library_forum_reactions(forum_type,table_id,author_player_id,viewer_player_id,created_at) VALUES($1,$2,$3,$4,$5)`

const deleteReactionQuery = `DELETE FROM library_forum_reactions WHERE forum_type=$1 AND table_id=$2 AND author_player_id=$3 AND viewer_player_id=$4`

// The board row serializes different authors, including the first post on a board.
func (Store) LockBoardTx(ctx context.Context, transaction tx.Tx, key d.Key) error {
	if transaction == nil || key.Validate() != nil {
		return app.ErrRequest
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO library_forum_boards(forum_type,table_id) VALUES($1,$2) ON CONFLICT DO NOTHING`, key.ForumType, key.TableID); err != nil {
		return err
	}
	var tableID int64
	return transaction.QueryRow(ctx, `SELECT table_id FROM library_forum_boards WHERE forum_type=$1 AND table_id=$2 FOR UPDATE`, key.ForumType, key.TableID).Scan(&tableID)
}

func (Store) CountLiveCommentsTx(ctx context.Context, query tx.Queryer, key d.Key) (int64, error) {
	if query == nil || key.Validate() != nil {
		return 0, app.ErrRequest
	}
	var count int64
	err := query.QueryRow(ctx, `SELECT count(*) FROM library_forum_comments WHERE forum_type=$1 AND table_id=$2 AND retired_at IS NULL`, key.ForumType, key.TableID).Scan(&count)
	return count, err
}

func (Store) RetireOldestCommentsTx(ctx context.Context, transaction tx.Tx, key d.Key, count int64, at time.Time) error {
	if transaction == nil || key.Validate() != nil || count < 1 || count > d.MaxLiveComments || at.IsZero() {
		return app.ErrRequest
	}
	// The board lock serializes writers; a locking LIMIT subquery can reselect rows during UPDATE.
	tag, err := transaction.Exec(ctx, `UPDATE library_forum_comments SET retired_at=GREATEST($4,created_at,updated_at) WHERE forum_type=$1 AND table_id=$2 AND author_player_id IN (SELECT author_player_id FROM library_forum_comments WHERE forum_type=$1 AND table_id=$2 AND retired_at IS NULL ORDER BY created_at,author_player_id LIMIT $3)`, key.ForumType, key.TableID, count, at.UTC())
	if err == nil && tag.RowsAffected() != count {
		return app.ErrUnavailable
	}
	return err
}

func (Store) ClearAuthorReactionsTx(ctx context.Context, transaction tx.Tx, key d.Key, author identity.PlayerID) error {
	if transaction == nil || key.Validate() != nil || !author.Valid() {
		return app.ErrRequest
	}
	_, err := transaction.Exec(ctx, `DELETE FROM library_forum_reactions WHERE forum_type=$1 AND table_id=$2 AND author_player_id=$3`, key.ForumType, key.TableID, int64(author))
	return err
}
