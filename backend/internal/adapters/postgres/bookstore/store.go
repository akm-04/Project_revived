package bookstore

import (
	"context"
	"encoding/json"
	"errors"
	book "gxb.local/backend/v2/internal/domain/bookskill"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store struct{ Queryer tx.Queryer }
type Root = book.Root

func scan(row tx.Row) (Root, error) {
	var r Root
	var p int64
	var raw string
	e := row.Scan(&p, &r.Version, &r.Revision, &raw, &r.CreatedAt, &r.UpdatedAt)
	if e != nil {
		return r, e
	}
	r.Player = identity.PlayerID(p)
	e = json.Unmarshal([]byte(raw), &r.Facts)
	if e != nil || !r.Player.Valid() || r.Version < 1 || len(r.Revision) != 64 || r.CreatedAt.IsZero() || r.UpdatedAt.Before(r.CreatedAt) {
		return r, book.ErrUnqualified
	}
	return r, nil
}

const cols = `player_id,state_version,creation_revision,facts::text,created_at,updated_at`

func (Store) ReadRootTx(c context.Context, q tx.Queryer, p identity.PlayerID) (Root, error) {
	return scan(q.QueryRow(c, `SELECT `+cols+` FROM player_book_roots WHERE player_id=$1`, int64(p)))
}
func (Store) LockRootTx(c context.Context, t tx.Tx, p identity.PlayerID) (Root, error) {
	return scan(t.QueryRow(c, `SELECT `+cols+` FROM player_book_roots WHERE player_id=$1 FOR UPDATE`, int64(p)))
}
func (Store) SaveRootTx(c context.Context, t tx.Tx, r Root, old int64) error {
	if r.Version != old+1 {
		return book.ErrUnqualified
	}
	raw, e := json.Marshal(r.Facts)
	if e != nil {
		return e
	}
	tag, e := t.Exec(c, `UPDATE player_book_roots SET facts=$2::jsonb,state_version=$3,updated_at=$4 WHERE player_id=$1 AND state_version=$5`, int64(r.Player), string(raw), r.Version, r.UpdatedAt, old)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return errors.New("book: stale root write")
	}
	return nil
}
func (Store) EnsureRootTx(c context.Context, t tx.Tx, p identity.PlayerID, rev string, at time.Time) error {
	if !p.Valid() || len(rev) != 64 || at.IsZero() {
		return book.ErrUnqualified
	}
	raw, _ := json.Marshal(book.Seed())
	_, e := t.Exec(c, `INSERT INTO player_book_roots(player_id,state_version,creation_revision,facts,created_at,updated_at)VALUES($1,1,$2,$3::jsonb,$4,$4)ON CONFLICT(player_id)DO NOTHING`, int64(p), rev, string(raw), at)
	return e
}
