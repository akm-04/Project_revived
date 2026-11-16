package librarystore

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{ Queryer tx.Queryer }

const rootColumns = `player_id,state_version,special_claims::text,payload_version,seed_policy_id,created_at,updated_at,married_high_water,board_partner,board_card,board_model_id,bg_main,bg_room`
const heroColumns = `player_id,partner_id,state_version,favor_degree,is_married,feed_attrs::text,collect_quality_stage,collect_star_stage,pending_candidate::text,payload_version,seed_policy_id,created_at,updated_at`

func scanRoot(row tx.Row) (library.PlayerFacts, error) {
	var f library.PlayerFacts
	var pid int64
	var raw string
	var version int16
	if e := row.Scan(&pid, &f.StateVersion, &raw, &version, &f.SeedPolicy, &f.CreatedAt, &f.UpdatedAt, &f.MarriedHighWater, &f.BoardPartner, &f.BoardCard, &f.BoardModelID, &f.BgMain, &f.BgRoom); e != nil {
		return f, e
	}
	f.PlayerID = identity.PlayerID(pid)
	f.CreatedAt = f.CreatedAt.UTC()
	f.UpdatedAt = f.UpdatedAt.UTC()
	var bits []bool
	if e := payload.Decode("player_library_roots", version, []byte(raw), &bits); e != nil {
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
	var version int16
	if e := row.Scan(&pid, &f.Ref.PartnerID, &f.StateVersion, &f.Favor, &f.Married, &raw, &f.QualityStage, &f.StarStage, &pending, &version, &f.SeedPolicy, &f.CreatedAt, &f.UpdatedAt); e != nil {
		return f, e
	}
	f.Ref.PlayerID = identity.PlayerID(pid)
	f.CreatedAt = f.CreatedAt.UTC()
	f.UpdatedAt = f.UpdatedAt.UTC()
	var attrs []int64
	if e := payload.Decode("player_library_heroes", version, []byte(raw), &attrs); e != nil {
		return f, e
	}
	if len(attrs) != library.AxisCount {
		return f, library.ErrInvalidFacts
	}
	copy(f.Applied[:], attrs)
	if pending != nil {
		var c library.Candidate
		if e := payload.Decode("player_library_heroes", version, []byte(*pending), &c); e != nil {
			return f, e
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

// ListHeroesTx returns every Library Hero facet of one player in one owner read.
func (Store) ListHeroesTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) ([]library.HeroFacts, error) {
	if q == nil || !pid.Valid() {
		return nil, library.ErrInvalidFacts
	}
	var raw string
	if e := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY partner_id),'[]'::jsonb)::text FROM player_library_heroes t WHERE player_id=$1`, int64(pid)).Scan(&raw); e != nil {
		return nil, e
	}
	var rows []struct {
		PlayerID            int64           `json:"player_id"`
		PartnerID           int64           `json:"partner_id"`
		StateVersion        int64           `json:"state_version"`
		FavorDegree         int64           `json:"favor_degree"`
		IsMarried           bool            `json:"is_married"`
		FeedAttrs           json.RawMessage `json:"feed_attrs"`
		CollectQualityStage int64           `json:"collect_quality_stage"`
		CollectStarStage    int64           `json:"collect_star_stage"`
		PendingCandidate    json.RawMessage `json:"pending_candidate"`
		PayloadVersion      int16           `json:"payload_version"`
		SeedPolicyID        string          `json:"seed_policy_id"`
		CreatedAt           time.Time       `json:"created_at"`
		UpdatedAt           time.Time       `json:"updated_at"`
	}
	if e := json.Unmarshal([]byte(raw), &rows); e != nil {
		return nil, e
	}
	out := make([]library.HeroFacts, 0, len(rows))
	for _, row := range rows {
		var f library.HeroFacts
		f.Ref.PlayerID, f.Ref.PartnerID, f.StateVersion = identity.PlayerID(row.PlayerID), row.PartnerID, row.StateVersion
		f.Favor, f.Married, f.QualityStage, f.StarStage, f.SeedPolicy = row.FavorDegree, row.IsMarried, row.CollectQualityStage, row.CollectStarStage, row.SeedPolicyID
		f.CreatedAt, f.UpdatedAt = row.CreatedAt.UTC(), row.UpdatedAt.UTC()
		var attrs []int64
		if e := payload.Decode("player_library_heroes", row.PayloadVersion, row.FeedAttrs, &attrs); e != nil {
			return nil, e
		}
		if len(attrs) != library.AxisCount {
			return nil, library.ErrInvalidFacts
		}
		copy(f.Applied[:], attrs)
		if len(row.PendingCandidate) > 0 && !bytes.Equal(row.PendingCandidate, []byte("null")) {
			var c library.Candidate
			if e := payload.Decode("player_library_heroes", row.PayloadVersion, row.PendingCandidate, &c); e != nil {
				return nil, e
			}
			f.Pending = &c
		}
		if e := f.Validate(); e != nil {
			return nil, e
		}
		out = append(out, f)
	}
	return out, nil
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
	bits, version, e := payload.Encode(f.SpecialClaims)
	if e != nil {
		return e
	}
	_, e = t.Exec(ctx, `INSERT INTO player_library_roots(player_id,state_version,special_claims,payload_version,seed_policy_id,created_at,updated_at)VALUES($1,1,$2::jsonb,$3,$4,$5,$5)ON CONFLICT(player_id)DO NOTHING`, int64(pid), string(bits), version, f.SeedPolicy, now.UTC())
	return e
}

const insertHero = `INSERT INTO player_library_heroes(player_id,partner_id,state_version,favor_degree,is_married,feed_attrs,payload_version,collect_quality_stage,collect_star_stage,seed_policy_id,created_at,updated_at)VALUES($1,$2,1,0,false,'[0,0,0,0,0,0]'::jsonb,1,0,0,$3,$4,$4)`

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
	// A new hero starts the Girls Log with its acquisition entry (type 1).
	// PRIVATE_POLICY: every owned creation path records the Vending source.
	_, e = t.Exec(ctx, `INSERT INTO player_library_hero_logs(player_id,partner_id,log_id,occurred_at)VALUES($1,$2,$3,$4)ON CONFLICT(player_id,partner_id,log_id)DO NOTHING`, int64(ref.PlayerID), ref.PartnerID, library.LogAcquired, now.UTC())
	return e
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
	if tag.RowsAffected() != 1 {
		return false, nil
	}
	// A backfilled facet gets the same acquisition entry as a fresh one.
	// PRIVATE_POLICY: every owned creation path records the Vending source.
	_, e = t.Exec(ctx, `INSERT INTO player_library_hero_logs(player_id,partner_id,log_id,occurred_at)VALUES($1,$2,$3,$4)ON CONFLICT(player_id,partner_id,log_id)DO NOTHING`, int64(ref.PlayerID), ref.PartnerID, library.LogAcquired, now.UTC())
	return true, e
}

// SaveHeroTx requires the preplanned Library root and record locks. The root
// version advances for provider coherence; fresh insertion instead advances Hero's population version.
func (Store) SaveHeroTx(ctx context.Context, t tx.Tx, f library.HeroFacts, oldVersion int64) error {
	if t == nil || f.Validate() != nil || oldVersion <= 0 || f.StateVersion != oldVersion+1 {
		return library.ErrInvalidFacts
	}
	attrs, version, e := payload.Encode(f.Applied)
	if e != nil {
		return e
	}
	var pending any
	if f.Pending != nil {
		raw, _, e := payload.Encode(f.Pending)
		if e != nil {
			return e
		}
		pending = string(raw)
	}
	tag, e := t.Exec(ctx, `UPDATE player_library_heroes SET state_version=$3,favor_degree=$4,is_married=$5,feed_attrs=$6::jsonb,collect_quality_stage=$7,collect_star_stage=$8,pending_candidate=$9::jsonb,payload_version=$10,updated_at=$11 WHERE player_id=$1 AND partner_id=$2 AND state_version=$12`, int64(f.Ref.PlayerID), f.Ref.PartnerID, f.StateVersion, f.Favor, f.Married, string(attrs), f.QualityStage, f.StarStage, pending, version, f.UpdatedAt.UTC(), oldVersion)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return errors.New("library: facet update lost version")
	}
	tag, e = t.Exec(ctx, `UPDATE player_library_roots SET state_version=state_version+1,updated_at=$2,married_high_water=GREATEST(married_high_water,(SELECT count(*) FROM player_library_heroes WHERE player_id=$1 AND is_married)) WHERE player_id=$1`, int64(f.Ref.PlayerID), f.UpdatedAt.UTC())
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
	bits, version, e := payload.Encode(f.SpecialClaims)
	if e != nil {
		return e
	}
	tag, e := t.Exec(ctx, `UPDATE player_library_roots SET state_version=$2,special_claims=$3::jsonb,payload_version=$4,board_partner=$5,board_card=$6,board_model_id=$7,bg_main=$8,bg_room=$9,updated_at=$10 WHERE player_id=$1 AND state_version=$11`, int64(f.PlayerID), f.StateVersion, string(bits), version, f.BoardPartner, f.BoardCard, f.BoardModelID, f.BgMain, f.BgRoom, f.UpdatedAt.UTC(), oldVersion)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return errors.New("library: root update lost version")
	}
	return nil
}
