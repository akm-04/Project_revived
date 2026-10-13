package librarystore

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{ Queryer tx.Queryer }

const rootColumns = `player_id,state_version,special_claims::text,seed_policy_id,created_at,updated_at`
const heroColumns = `player_id,partner_id,state_version,favor_degree,is_married,feed_attrs::text,collect_quality_stage,collect_star_stage,pending_candidate::text,seed_policy_id,created_at,updated_at`

func scanRoot(row tx.Row) (library.PlayerFacts, error) {
	var f library.PlayerFacts
	var pid int64
	var raw string
	if e := row.Scan(&pid, &f.StateVersion, &raw, &f.SeedPolicy, &f.CreatedAt, &f.UpdatedAt); e != nil {
		return f, e
	}
	f.PlayerID = identity.PlayerID(pid)
	f.CreatedAt = f.CreatedAt.UTC()
	f.UpdatedAt = f.UpdatedAt.UTC()
	var bits []bool
	if e := json.Unmarshal([]byte(raw), &bits); e != nil {
		return f, e
	}
	if len(bits) != library.SpecialClaimCount {
		return f, library.ErrInvalidFacts
	}
	copy(f.SpecialClaims[:], bits)
	return f, f.Validate()
}
func scanHero(row tx.Row) (library.HeroFacts, error) {
	var f library.HeroFacts
	var pid int64
	var raw string
	var pending *string
	if e := row.Scan(&pid, &f.Ref.PartnerID, &f.StateVersion, &f.Favor, &f.Married, &raw, &f.QualityStage, &f.StarStage, &pending, &f.SeedPolicy, &f.CreatedAt, &f.UpdatedAt); e != nil {
		return f, e
	}
	f.Ref.PlayerID = identity.PlayerID(pid)
	f.CreatedAt = f.CreatedAt.UTC()
	f.UpdatedAt = f.UpdatedAt.UTC()
	var attrs []int64
	if e := json.Unmarshal([]byte(raw), &attrs); e != nil {
		return f, e
	}
	if len(attrs) != library.AxisCount {
		return f, library.ErrInvalidFacts
	}
	copy(f.Applied[:], attrs)
	if pending != nil {
		var c library.Candidate
		d := json.NewDecoder(bytes.NewBufferString(*pending))
		d.DisallowUnknownFields()
		if e := d.Decode(&c); e != nil {
			return f, e
		}
		var extra any
		if d.Decode(&extra) != io.EOF {
			return f, library.ErrInvalidFacts
		}
		f.Pending = &c
	}
	return f, f.Validate()
}
func (Store) ReadRootTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) (library.PlayerFacts, error) {
	if q == nil || !pid.Valid() {
		return library.PlayerFacts{}, library.ErrInvalidFacts
	}
	return scanRoot(q.QueryRow(ctx, `SELECT `+rootColumns+` FROM player_library_roots WHERE player_id=$1`, int64(pid)))
}
func (Store) LockRootTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) (library.PlayerFacts, error) {
	if t == nil || !pid.Valid() {
		return library.PlayerFacts{}, library.ErrInvalidFacts
	}
	return scanRoot(t.QueryRow(ctx, `SELECT `+rootColumns+` FROM player_library_roots WHERE player_id=$1 FOR UPDATE`, int64(pid)))
}
func (Store) ReadHeroTx(ctx context.Context, q tx.Queryer, ref character.HeroRef) (library.HeroFacts, error) {
	if q == nil || ref.Validate() != nil {
		return library.HeroFacts{}, library.ErrInvalidFacts
	}
	return scanHero(q.QueryRow(ctx, `SELECT `+heroColumns+` FROM player_library_heroes WHERE player_id=$1 AND partner_id=$2`, int64(ref.PlayerID), ref.PartnerID))
}
func (Store) LockHeroTx(ctx context.Context, t tx.Tx, ref character.HeroRef) (library.HeroFacts, error) {
	if t == nil || ref.Validate() != nil {
		return library.HeroFacts{}, library.ErrInvalidFacts
	}
	return scanHero(t.QueryRow(ctx, `SELECT `+heroColumns+` FROM player_library_heroes WHERE player_id=$1 AND partner_id=$2 FOR UPDATE`, int64(ref.PlayerID), ref.PartnerID))
}

// EnsurePlayerRootTx is used only by fresh bootstrap or controlled owner backfill.
func (Store) EnsurePlayerRootTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, now time.Time) error {
	if t == nil {
		return library.ErrInvalidFacts
	}
	f, e := library.NewPlayerFacts(pid, now)
	if e != nil {
		return e
	}
	bits, e := json.Marshal(f.SpecialClaims)
	if e != nil {
		return e
	}
	_, e = t.Exec(ctx, `INSERT INTO player_library_roots(player_id,state_version,special_claims,seed_policy_id,created_at,updated_at)VALUES($1,1,$2::jsonb,$3,$4,$4)ON CONFLICT(player_id)DO NOTHING`, int64(pid), string(bits), f.SeedPolicy, now.UTC())
	return e
}

const insertHero = `INSERT INTO player_library_heroes(player_id,partner_id,state_version,favor_degree,is_married,feed_attrs,collect_quality_stage,collect_star_stage,seed_policy_id,created_at,updated_at)VALUES($1,$2,1,0,false,'[0,0,0,0,0,0]'::jsonb,0,0,$3,$4,$4)`

// InitFreshHeroTx only inserts a unique unpublished facet. It does not take an
// existing Library root lock after I5 locks; bootstrap must already own its root.
func (Store) InitFreshHeroTx(ctx context.Context, t tx.Tx, ref character.HeroRef, now time.Time) error {
	if t == nil {
		return library.ErrInvalidFacts
	}
	f, e := library.NewHeroFacts(ref, now)
	if e != nil {
		return e
	}
	tag, e := t.Exec(ctx, insertHero, int64(ref.PlayerID), ref.PartnerID, f.SeedPolicy, now.UTC())
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return errors.New("library: fresh facet insert count")
	}
	return nil
}

// BackfillMissingHeroTx preserves an explicit existing facet, including previews.
func (Store) BackfillMissingHeroTx(ctx context.Context, t tx.Tx, ref character.HeroRef, now time.Time) (bool, error) {
	if t == nil {
		return false, library.ErrInvalidFacts
	}
	f, e := library.NewHeroFacts(ref, now)
	if e != nil {
		return false, e
	}
	tag, e := t.Exec(ctx, insertHero+` ON CONFLICT(player_id,partner_id)DO NOTHING`, int64(ref.PlayerID), ref.PartnerID, f.SeedPolicy, now.UTC())
	if e != nil {
		return false, e
	}
	return tag.RowsAffected() == 1, nil
}

// SaveHeroTx requires the preplanned Library root and record locks. The root
// version advances for provider coherence; fresh insertion instead advances Hero's population version.
func (Store) SaveHeroTx(ctx context.Context, t tx.Tx, f library.HeroFacts, oldVersion int64) error {
	if t == nil || f.Validate() != nil || oldVersion <= 0 || f.StateVersion != oldVersion+1 {
		return library.ErrInvalidFacts
	}
	attrs, e := json.Marshal(f.Applied)
	if e != nil {
		return e
	}
	var pending any
	if f.Pending != nil {
		raw, e := json.Marshal(f.Pending)
		if e != nil {
			return e
		}
		pending = string(raw)
	}
	tag, e := t.Exec(ctx, `UPDATE player_library_heroes SET state_version=$3,favor_degree=$4,is_married=$5,feed_attrs=$6::jsonb,collect_quality_stage=$7,collect_star_stage=$8,pending_candidate=$9::jsonb,updated_at=$10 WHERE player_id=$1 AND partner_id=$2 AND state_version=$11`, int64(f.Ref.PlayerID), f.Ref.PartnerID, f.StateVersion, f.Favor, f.Married, string(attrs), f.QualityStage, f.StarStage, pending, f.UpdatedAt.UTC(), oldVersion)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return errors.New("library: facet update lost version")
	}
	tag, e = t.Exec(ctx, `UPDATE player_library_roots SET state_version=state_version+1,updated_at=$2 WHERE player_id=$1`, int64(f.Ref.PlayerID), f.UpdatedAt.UTC())
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return errors.New("library: provider root missing")
	}
	return nil
}
func (Store) SavePlayerTx(ctx context.Context, t tx.Tx, f library.PlayerFacts, oldVersion int64) error {
	if t == nil || f.Validate() != nil || oldVersion <= 0 || f.StateVersion != oldVersion+1 {
		return library.ErrInvalidFacts
	}
	bits, e := json.Marshal(f.SpecialClaims)
	if e != nil {
		return e
	}
	tag, e := t.Exec(ctx, `UPDATE player_library_roots SET state_version=$2,special_claims=$3::jsonb,updated_at=$4 WHERE player_id=$1 AND state_version=$5`, int64(f.PlayerID), f.StateVersion, string(bits), f.UpdatedAt.UTC(), oldVersion)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return errors.New("library: root update lost version")
	}
	return nil
}
