package characterstore

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// RawAwakeningStore is an intrinsic CharacterHero facet. Its initializer only
// inserts a new unpublished facet; it discovers no additional existing lock.
type RawAwakeningStore struct{}

func (RawAwakeningStore) InitFreshHeroTx(c context.Context, t tx.Tx, ref character.HeroRef, at time.Time) error {
	if t == nil || ref.Validate() != nil || at.IsZero() {
		return character.ErrRawAwakeningUnavailable
	}
	h, e := (Store{}).ReadHeroByPartnerIDTx(c, t, ref.PlayerID, ref.PartnerID)
	if e != nil {
		return e
	}
	if h.Ref() != ref || h.CreatedAt.UnixMicro() != at.UnixMicro() {
		return character.ErrRawAwakeningUnavailable
	}
	f, e := character.NewRawAwakeningBirth(h)
	if e != nil {
		return e
	}
	tag, e := t.Exec(c, `INSERT INTO player_hero_raw_awakening(player_id,partner_id,state_version,raw_stage,birth_policy,creation_content_revision,birth_at,created_at,updated_at)VALUES($1,$2,1,0,$3,$4,$5,$5,$5)`, int64(ref.PlayerID), ref.PartnerID, f.BirthPolicy, f.CreationContentRevision, f.BirthAt)
	if e != nil {
		return e
	}
	if tag == nil || tag.RowsAffected() != 1 {
		return character.ErrRawAwakeningUnavailable
	}
	return nil
}
func (RawAwakeningStore) ReadRawAwakeningBirthTx(c context.Context, q tx.Queryer, ref character.HeroRef) (character.RawAwakeningBirth, error) {
	var f character.RawAwakeningBirth
	if q == nil || ref.Validate() != nil {
		return f, character.ErrRawAwakeningUnavailable
	}
	var pid int64
	e := q.QueryRow(c, `SELECT player_id,partner_id,state_version,raw_stage,birth_policy,creation_content_revision,birth_at,created_at,updated_at FROM player_hero_raw_awakening WHERE player_id=$1 AND partner_id=$2`, int64(ref.PlayerID), ref.PartnerID).Scan(&pid, &f.Ref.PartnerID, &f.Version, &f.RawStage, &f.BirthPolicy, &f.CreationContentRevision, &f.BirthAt, &f.CreatedAt, &f.UpdatedAt)
	if e != nil {
		return f, e
	}
	f.Ref.PlayerID = identity.PlayerID(pid)
	if f.Ref != ref {
		return f, character.ErrRawAwakeningUnavailable
	}
	return f, f.Validate()
}
