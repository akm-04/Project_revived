package characterstore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/characterqueries"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{ Queryer tx.Queryer }

func scanRoot(row tx.Row) (character.HeroRoot, error) {
	var r character.HeroRoot
	var pid int64
	if err := row.Scan(&pid, &r.NextPartnerID, &r.SortType, &r.StateVersion, &r.CreatedAt, &r.UpdatedAt); err != nil {
		return r, err
	}
	r.PlayerID = identity.PlayerID(pid)
	r.CreatedAt = r.CreatedAt.UTC()
	r.UpdatedAt = r.UpdatedAt.UTC()
	return r, r.Validate()
}
func (s Store) ReadRoot(ctx context.Context, pid identity.PlayerID) (character.HeroRoot, error) {
	if s.Queryer == nil || !pid.Valid() {
		return character.HeroRoot{}, errors.New("character store: invalid root read")
	}
	return s.ReadRootTx(ctx, s.Queryer, pid)
}
func (Store) ReadRootTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) (character.HeroRoot, error) {
	if q == nil || !pid.Valid() {
		return character.HeroRoot{}, errors.New("character store: invalid root read")
	}
	return scanRoot(q.QueryRow(ctx, characterqueries.ReadHeroRoot, int64(pid)))
}
func (Store) LockRootTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) (character.HeroRoot, error) {
	if t == nil || !pid.Valid() {
		return character.HeroRoot{}, errors.New("character store: invalid root lock")
	}
	return scanRoot(t.QueryRow(ctx, characterqueries.LockHeroRoot, int64(pid)))
}
func (Store) SaveSortTypeTx(ctx context.Context, t tx.Tx, r character.HeroRoot, oldVersion int64) error {
	if t == nil || r.Validate() != nil || oldVersion <= 0 {
		return errors.New("character store: invalid sort update")
	}
	tag, err := t.Exec(ctx, characterqueries.SaveHeroSortType, int64(r.PlayerID), r.SortType, r.UpdatedAt.UTC(), oldVersion)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("character store: sort update lost race")
	}
	return nil
}

func (Store) SaveRootAllocatorTx(ctx context.Context, t tx.Tx, r character.HeroRoot, oldVersion int64) error {
	if t == nil || r.Validate() != nil || oldVersion <= 0 || r.StateVersion != oldVersion+1 {
		return errors.New("character store: invalid Hero allocator update")
	}
	tag, err := t.Exec(ctx, characterqueries.SaveHeroRootAllocator, int64(r.PlayerID), r.NextPartnerID, r.UpdatedAt.UTC(), oldVersion)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("character store: Hero allocator update lost race")
	}
	return nil
}

func (Store) InsertHeroTx(ctx context.Context, t tx.Tx, h character.Hero) error {
	if t == nil || h.ValidatePersistent() != nil || h.StateVersion != 1 {
		return errors.New("character store: invalid Hero insert")
	}
	tag, err := t.Exec(ctx, characterqueries.InsertPlayerHero, int64(h.PlayerID), h.PartnerID, h.TableID, h.OriginTableID, h.Star, h.Level, h.Exp, h.Color,
		h.Equipment[0], h.Equipment[1], h.Equipment[2], h.Equipment[3], h.Equipment[4], h.Equipment[5],
		h.Fumo[0], h.Fumo[1], h.Fumo[2], h.Fumo[3], h.Fumo[4], h.Fumo[5],
		h.CurrentSkinID, h.IllusionSkinID, h.CreationContentRevision, h.StateVersion, h.CreatedAt.UTC(), h.UpdatedAt.UTC())
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("character store: Hero insert affected unexpected rows")
	}
	return nil
}

func (s Store) ListHeroes(ctx context.Context, pid identity.PlayerID) ([]character.Hero, error) {
	if s.Queryer == nil || !pid.Valid() {
		return nil, errors.New("character store: invalid hero list")
	}
	return s.ListHeroesTx(ctx, s.Queryer, pid)
}
func (Store) ListHeroesTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) ([]character.Hero, error) {
	if q == nil || !pid.Valid() {
		return nil, errors.New("character store: invalid hero list")
	}
	var raw string
	if err := q.QueryRow(ctx, characterqueries.ListPlayerHeroes, int64(pid)).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []struct {
		PlayerID                int64     `json:"player_id"`
		PartnerID               int64     `json:"partner_id"`
		TableID                 int64     `json:"table_id"`
		OriginTableID           int64     `json:"origin_table_id"`
		Star                    int64     `json:"star"`
		Level                   int64     `json:"level"`
		Exp                     int64     `json:"exp"`
		Color                   int64     `json:"color"`
		Equip1                  int64     `json:"equip_1"`
		Equip2                  int64     `json:"equip_2"`
		Equip3                  int64     `json:"equip_3"`
		Equip4                  int64     `json:"equip_4"`
		Equip5                  int64     `json:"equip_5"`
		Equip6                  int64     `json:"equip_6"`
		Fumo1                   int64     `json:"fumo_1"`
		Fumo2                   int64     `json:"fumo_2"`
		Fumo3                   int64     `json:"fumo_3"`
		Fumo4                   int64     `json:"fumo_4"`
		Fumo5                   int64     `json:"fumo_5"`
		Fumo6                   int64     `json:"fumo_6"`
		PracticeStr             int64     `json:"practice_str"`
		PracticeInt             int64     `json:"practice_int"`
		PracticeAgi             int64     `json:"practice_agi"`
		CurrentSkinID           int64     `json:"current_skin_id"`
		IllusionSkinID          int64     `json:"illusion_skin_id"`
		StateVersion            int64     `json:"state_version"`
		CreationContentRevision string    `json:"creation_content_revision"`
		CreatedAt               time.Time `json:"created_at"`
		UpdatedAt               time.Time `json:"updated_at"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]character.Hero, 0, len(rows))
	for _, x := range rows {
		h := character.Hero{PlayerID: identity.PlayerID(x.PlayerID), PartnerID: x.PartnerID, TableID: x.TableID, OriginTableID: x.OriginTableID, Star: x.Star, Level: x.Level, Exp: x.Exp, Color: x.Color, Equipment: character.HeroEquipmentSlots{x.Equip1, x.Equip2, x.Equip3, x.Equip4, x.Equip5, x.Equip6}, Fumo: character.HeroFumoSlots{x.Fumo1, x.Fumo2, x.Fumo3, x.Fumo4, x.Fumo5, x.Fumo6}, Practice: character.PracticeAttrs{x.PracticeStr, x.PracticeInt, x.PracticeAgi}, CurrentSkinID: x.CurrentSkinID, IllusionSkinID: x.IllusionSkinID, CreationContentRevision: x.CreationContentRevision, StateVersion: x.StateVersion, CreatedAt: x.CreatedAt.UTC(), UpdatedAt: x.UpdatedAt.UTC()}
		if err := h.ValidatePersistent(); err != nil {
			return nil, err
		}
		out = append(out, h)
	}
	return out, nil
}

func scanHero(row tx.Row) (character.Hero, error) {
	var h character.Hero
	var pid int64
	if err := row.Scan(&pid, &h.PartnerID, &h.TableID, &h.OriginTableID, &h.Star, &h.Level, &h.Exp, &h.Color,
		&h.Equipment[0], &h.Equipment[1], &h.Equipment[2], &h.Equipment[3], &h.Equipment[4], &h.Equipment[5],
		&h.Fumo[0], &h.Fumo[1], &h.Fumo[2], &h.Fumo[3], &h.Fumo[4], &h.Fumo[5],
		&h.Practice[0], &h.Practice[1], &h.Practice[2], &h.CurrentSkinID, &h.IllusionSkinID,
		&h.CreationContentRevision, &h.StateVersion, &h.CreatedAt, &h.UpdatedAt); err != nil {
		return h, err
	}
	h.PlayerID = identity.PlayerID(pid)
	h.CreatedAt = h.CreatedAt.UTC()
	h.UpdatedAt = h.UpdatedAt.UTC()
	return h, h.ValidatePersistent()
}

func (Store) ReadHeroByOriginTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, originTableID int64) (character.Hero, error) {
	if q == nil || !pid.Valid() || originTableID <= 0 {
		return character.Hero{}, errors.New("character store: invalid Hero origin read")
	}
	return scanHero(q.QueryRow(ctx, characterqueries.ReadHeroByOrigin, int64(pid), originTableID))
}

func (Store) ReadHeroByPartnerIDTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, partnerID int64) (character.Hero, error) {
	if q == nil || !pid.Valid() || partnerID <= 0 {
		return character.Hero{}, errors.New("character store: invalid Hero read")
	}
	return scanHero(q.QueryRow(ctx, characterqueries.ReadHeroByPartnerID, int64(pid), partnerID))
}

func (Store) LockHeroByPartnerIDTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, partnerID int64) (character.Hero, error) {
	if t == nil || !pid.Valid() || partnerID <= 0 {
		return character.Hero{}, errors.New("character store: invalid Hero lock")
	}
	return scanHero(t.QueryRow(ctx, characterqueries.LockHeroByPartnerID, int64(pid), partnerID))
}

func (Store) SaveHeroProgressionTx(ctx context.Context, t tx.Tx, h character.Hero, oldVersion int64) error {
	if t == nil || h.ValidatePersistent() != nil || oldVersion <= 0 || h.StateVersion != oldVersion+1 {
		return errors.New("character store: invalid Hero progression update")
	}
	tag, err := t.Exec(ctx, characterqueries.SaveHeroProgression, int64(h.PlayerID), h.PartnerID, h.Star, h.Level, h.Exp, h.UpdatedAt.UTC(), oldVersion)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("character store: Hero progression update lost race")
	}
	return nil
}

// SaveHeroStateTx is the cohesive Hero CAS needed by equipment operations that
// may change source EXP and equipment slots in one state-version transition.
func (Store) SaveHeroStateTx(ctx context.Context, t tx.Tx, h character.Hero, oldVersion int64) error {
	if t == nil || h.ValidatePersistent() != nil || oldVersion <= 0 || h.StateVersion != oldVersion+1 {
		return errors.New("character store: invalid Hero state update")
	}
	tag, err := t.Exec(ctx, characterqueries.SaveHeroState, int64(h.PlayerID), h.PartnerID, h.Star, h.Level, h.Exp, h.Color,
		h.Equipment[0], h.Equipment[1], h.Equipment[2], h.Equipment[3], h.Equipment[4], h.Equipment[5],
		h.Fumo[0], h.Fumo[1], h.Fumo[2], h.Fumo[3], h.Fumo[4], h.Fumo[5],
		h.UpdatedAt.UTC(), oldVersion)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("character store: Hero state update lost race")
	}
	return nil
}

type BootstrapContributor struct{}

func (BootstrapContributor) Name() string   { return "ca2.hero-core" }
func (BootstrapContributor) Required() bool { return true }
func (BootstrapContributor) PersistCharacterBootstrap(ctx context.Context, t tx.Tx, b logicalserver.BootstrapContext) error {
	if t == nil || !b.PlayerID.Valid() || b.Operation.StartedAt.IsZero() {
		return errors.New("character store: invalid bootstrap")
	}
	tag, err := t.Exec(ctx, characterqueries.InsertHeroRoot, int64(b.PlayerID), b.Operation.StartedAt.UTC())
	if err != nil {
		return err
	}
	if n := tag.RowsAffected(); n != 1 {
		return errors.New("character store: bootstrap root not inserted")
	}
	return nil
}

var _ appboot.CharacterBootstrapPersistenceContributor = BootstrapContributor{}
