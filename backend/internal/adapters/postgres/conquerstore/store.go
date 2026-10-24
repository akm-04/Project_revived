package conquerstore

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	d "gxb.local/backend/v2/internal/domain/conquerschool"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
	"time"
)

type Store struct{}

const cols = `player_id,state_version,content_revision,payload::text,created_at,updated_at`

func scan(r tx.Row) (d.Facts, error) {
	var f d.Facts
	var pid int64
	var raw string
	if e := r.Scan(&pid, &f.Version, &f.ContentRevision, &raw, &f.CreatedAt, &f.UpdatedAt); e != nil {
		if errors.Is(e, kernelstore.ErrNoRows) {
			e = d.ErrUnavailable
		}
		return f, e
	}
	f.Player = identity.PlayerID(pid)
	dec := json.NewDecoder(bytes.NewBufferString(raw))
	dec.DisallowUnknownFields()
	if e := dec.Decode(&f.Payload); e != nil {
		return f, e
	}
	var x any
	if dec.Decode(&x) != io.EOF {
		return f, d.ErrUnqualified
	}
	return f, nil
}
func (Store) ReadFactsTx(c context.Context, q tx.Queryer, p identity.PlayerID) (d.Facts, error) {
	if q == nil || !p.Valid() {
		return d.Facts{}, d.ErrUnqualified
	}
	return scan(q.QueryRow(c, `SELECT `+cols+` FROM player_conquer_facts WHERE player_id=$1`, int64(p)))
}

// Caller has acquired I4 Player315 before this owner row and all later roots.
func (Store) LockFactsTx(c context.Context, t tx.Tx, p identity.PlayerID) (d.Facts, error) {
	return scan(t.QueryRow(c, `SELECT `+cols+` FROM player_conquer_facts WHERE player_id=$1 FOR UPDATE`, int64(p)))
}
func (Store) SaveFactsTx(c context.Context, t tx.Tx, f d.Facts, old int64, cat d.Catalog) error {
	if t == nil || old < 1 || f.Version != old+1 || f.Validate(cat) != nil {
		return d.ErrUnqualified
	}
	raw, e := json.Marshal(f.Payload)
	if e != nil {
		return e
	}
	tag, e := t.Exec(c, `UPDATE player_conquer_facts SET state_version=$2,content_revision=$3,payload=$4::jsonb,updated_at=$5 WHERE player_id=$1 AND state_version=$6 AND updated_at<=$5`, int64(f.Player), f.Version, f.ContentRevision, string(raw), f.UpdatedAt, old)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return d.ErrConflict
	}
	return nil
}
func insert(c context.Context, t tx.Tx, p identity.PlayerID, rev string, op operation.Context, kind, ref string, at time.Time, missingOnly bool) error {
	pin, ok := op.Policies.Get("content")
	if t == nil || !p.Valid() || len(rev) != 64 || !ok || pin != rev || op.ID.IsZero() || at.IsZero() || ref == "" {
		return d.ErrUnqualified
	}
	payload := d.Payload{Kind: kind, Policy: d.Policy, OriginOperation: op.ID, OriginRef: ref}
	if kind == d.Initial {
		payload.Progress = &d.Progress{Level: 0, Loop: 1}
	}
	raw, e := json.Marshal(payload)
	if e != nil {
		return e
	}
	suffix := ""
	if missingOnly {
		suffix = " ON CONFLICT(player_id)DO NOTHING"
	}
	_, e = t.Exec(c, `INSERT INTO player_conquer_facts(player_id,state_version,content_revision,payload,created_at,updated_at)VALUES($1,1,$2,$3::jsonb,$4,$4)`+suffix, int64(p), rev, string(raw), at)
	return e
}
func (Store) InsertLegacyUnknownTx(c context.Context, t tx.Tx, p identity.PlayerID, rev string, op operation.Context, at time.Time) error {
	return insert(c, t, p, rev, op, d.Unknown, "legacy-unproven-no-directory-inference", at, true)
}

type BootstrapContributor struct{ Revision string }

func (BootstrapContributor) Name() string   { return "i7c2j.conquer-fact-initialization" }
func (BootstrapContributor) Required() bool { return true }
func (s BootstrapContributor) PersistCharacterBootstrap(c context.Context, t tx.Tx, b logicalserver.BootstrapContext) error {
	return insert(c, t, b.PlayerID, s.Revision, b.Operation, d.Initial, "MID1/"+b.BootstrapProfileVersion, b.Operation.StartedAt, false)
}

var _ appboot.CharacterBootstrapPersistenceContributor = BootstrapContributor{}
