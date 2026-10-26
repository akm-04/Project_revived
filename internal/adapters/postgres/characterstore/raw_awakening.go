package characterstore

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
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
	e := q.QueryRow(c, `SELECT player_id,partner_id,state_version,raw_stage,birth_policy,creation_content_revision,birth_at,created_at,updated_at,producer_reference FROM player_hero_raw_awakening WHERE player_id=$1 AND partner_id=$2`, int64(ref.PlayerID), ref.PartnerID).Scan(&pid, &f.Ref.PartnerID, &f.Version, &f.RawStage, &f.BirthPolicy, &f.CreationContentRevision, &f.BirthAt, &f.CreatedAt, &f.UpdatedAt, &f.ProducerReference)
	if e != nil {
		return f, e
	}
	f.Ref.PlayerID = identity.PlayerID(pid)
	if f.Ref != ref {
		return f, character.ErrRawAwakeningUnavailable
	}
	return f, f.Validate()
}

// SaveRawAwakeningTx requires the caller's locked Hero; birth provenance never changes.
func (RawAwakeningStore) SaveRawAwakeningTx(c context.Context, t tx.Tx, f character.RawAwakeningBirth, old int64) error {
	if t == nil || f.Validate() != nil || f.Version != old+1 {
		return character.ErrRawAwakeningUnavailable
	}
	tag, e := t.Exec(c, `UPDATE player_hero_raw_awakening SET state_version=$3,raw_stage=$4,updated_at=$5,producer_reference=$6 WHERE player_id=$1 AND partner_id=$2 AND state_version=$7 AND birth_policy=$8 AND creation_content_revision=$9 AND birth_at=$10`, int64(f.Ref.PlayerID), f.Ref.PartnerID, f.Version, f.RawStage, f.UpdatedAt, f.ProducerReference, old, f.BirthPolicy, f.CreationContentRevision, f.BirthAt)
	if e != nil {
		return e
	}
	if tag == nil || tag.RowsAffected() != 1 {
		return character.ErrRawAwakeningUnavailable
	}
	return nil
}

func (Store) SaveHeroAwakeningTx(c context.Context, t tx.Tx, h character.Hero, old int64) error {
	if t == nil || h.ValidatePersistent() != nil || h.StateVersion != old+1 {
		return character.ErrRawAwakeningUnavailable
	}
	tag, e := t.Exec(c, `UPDATE player_heroes SET table_id=$3,state_version=$4,updated_at=$5 WHERE player_id=$1 AND partner_id=$2 AND state_version=$6 AND origin_table_id=$7`, int64(h.PlayerID), h.PartnerID, h.TableID, h.StateVersion, h.UpdatedAt, old, h.OriginTableID)
	if e != nil {
		return e
	}
	if tag == nil || tag.RowsAffected() != 1 {
		return character.ErrRawAwakeningUnavailable
	}
	return nil
}

func (Store) SavePetAwakeningTx(c context.Context, t tx.Tx, p character.Pet, old int64) error {
	if t == nil || p.ValidatePersistent() != nil || p.StateVersion != old+1 {
		return character.ErrRawAwakeningUnavailable
	}
	tag, e := t.Exec(c, `UPDATE player_pets SET table_id=$3,state_version=$4,updated_at=$5 WHERE player_id=$1 AND pet_id=$2 AND state_version=$6 AND origin_table_id=$7`, int64(p.PlayerID), p.PetID, p.TableID, p.StateVersion, p.UpdatedAt, old, p.OriginTableID)
	if e != nil {
		return e
	}
	if tag == nil || tag.RowsAffected() != 1 {
		return character.ErrRawAwakeningUnavailable
	}
	return nil
}

func (s RawAwakeningStore) FindRawAwakeningTx(c context.Context, q tx.Queryer, ref character.HeroRef) (character.RawAwakeningBirth, bool, error) {
	f, e := s.ReadRawAwakeningBirthTx(c, q, ref)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return f, false, nil
	}
	return f, e == nil, e
}
