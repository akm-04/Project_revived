package characterstore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/characterqueries"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func scanPetRoot(row tx.Row) (character.PetRoot, error) {
	var r character.PetRoot
	var pid int64
	if err := row.Scan(&pid, &r.NextPetID, &r.FirstFreeHatchUsed, &r.StateVersion, &r.CreatedAt, &r.UpdatedAt); err != nil {
		return r, err
	}
	r.PlayerID = identity.PlayerID(pid)
	r.CreatedAt, r.UpdatedAt = r.CreatedAt.UTC(), r.UpdatedAt.UTC()
	return r, r.Validate()
}

func (s Store) ReadPetRoot(ctx context.Context, pid identity.PlayerID) (character.PetRoot, error) {
	if s.Queryer == nil || !pid.Valid() {
		return character.PetRoot{}, errors.New("character store: invalid Pet root read")
	}
	return s.ReadPetRootTx(ctx, s.Queryer, pid)
}
func (Store) ReadPetRootTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) (character.PetRoot, error) {
	if q == nil || !pid.Valid() {
		return character.PetRoot{}, errors.New("character store: invalid Pet root read")
	}
	return scanPetRoot(q.QueryRow(ctx, characterqueries.ReadPetRoot, int64(pid)))
}
func (Store) LockPetRootTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) (character.PetRoot, error) {
	if t == nil || !pid.Valid() {
		return character.PetRoot{}, errors.New("character store: invalid Pet root lock")
	}
	return scanPetRoot(t.QueryRow(ctx, characterqueries.LockPetRoot, int64(pid)))
}
func (Store) SavePetRootAllocatorTx(ctx context.Context, t tx.Tx, r character.PetRoot, oldVersion int64) error {
	if t == nil || r.Validate() != nil || oldVersion <= 0 || r.StateVersion != oldVersion+1 {
		return errors.New("character store: invalid Pet allocator update")
	}
	tag, err := t.Exec(ctx, characterqueries.SavePetRootAllocator, int64(r.PlayerID), r.NextPetID, r.UpdatedAt.UTC(), oldVersion)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("character store: Pet allocator update lost race")
	}
	return nil
}
func (Store) SavePetRootFreeHatchTx(ctx context.Context, t tx.Tx, r character.PetRoot, oldVersion int64) error {
	if t == nil || r.Validate() != nil || oldVersion <= 0 || r.StateVersion != oldVersion+1 {
		return errors.New("character store: invalid Pet free-hatch update")
	}
	tag, err := t.Exec(ctx, characterqueries.SavePetRootFreeHatch, int64(r.PlayerID), r.FirstFreeHatchUsed, r.UpdatedAt.UTC(), oldVersion)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("character store: Pet free-hatch update lost race")
	}
	return nil
}

func (Store) SavePetShowStateTx(ctx context.Context, t tx.Tx, p character.Pet, oldVersion int64) error {
	if t == nil || p.ValidatePersistent() != nil || oldVersion <= 0 || p.StateVersion != oldVersion+1 {
		return errors.New("character store: invalid Pet show update")
	}
	tag, err := t.Exec(ctx, characterqueries.SavePetShowState, int64(p.PlayerID), p.PetID, p.IsShow, p.UpdatedAt.UTC(), oldVersion)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("character store: Pet show update lost race")
	}
	return nil
}

func (Store) InsertPetTx(ctx context.Context, t tx.Tx, p character.Pet) error {
	if t == nil || p.ValidatePersistent() != nil || p.StateVersion != 1 {
		return errors.New("character store: invalid Pet insert")
	}
	tag, err := t.Exec(ctx, characterqueries.InsertPlayerPet, int64(p.PlayerID), p.PetID, p.TableID, p.OriginTableID, p.Star, p.Level, p.Exp, p.Color, p.Birthday, p.IsShow, p.Skills[0], p.Skills[1], p.Skills[2], p.Skills[3], p.Skills[4], p.Equipment[0], p.Equipment[1], p.Equipment[2], p.Fumo[0], p.Fumo[1], p.Fumo[2], p.ActiveStyle, p.CreationContentRevision, p.StateVersion, p.CreatedAt.UTC(), p.UpdatedAt.UTC())
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("character store: Pet insert affected unexpected rows")
	}
	return nil
}

func (s Store) ListPets(ctx context.Context, pid identity.PlayerID) ([]character.Pet, error) {
	if s.Queryer == nil || !pid.Valid() {
		return nil, errors.New("character store: invalid Pet list")
	}
	return s.ListPetsTx(ctx, s.Queryer, pid)
}
func (Store) ListPetsTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) ([]character.Pet, error) {
	if q == nil || !pid.Valid() {
		return nil, errors.New("character store: invalid Pet list")
	}
	var raw string
	if err := q.QueryRow(ctx, characterqueries.ListPlayerPets, int64(pid)).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []struct {
		PlayerID                int64     `json:"player_id"`
		PetID                   int64     `json:"pet_id"`
		TableID                 int64     `json:"table_id"`
		OriginTableID           int64     `json:"origin_table_id"`
		Star                    int64     `json:"star"`
		Level                   int64     `json:"level"`
		Exp                     int64     `json:"exp"`
		Color                   int64     `json:"color"`
		Equip1                  int64     `json:"equip_1"`
		Equip2                  int64     `json:"equip_2"`
		Equip3                  int64     `json:"equip_3"`
		Fumo1                   int64     `json:"fumo_1"`
		Fumo2                   int64     `json:"fumo_2"`
		Fumo3                   int64     `json:"fumo_3"`
		Skill1                  int64     `json:"skill_1"`
		Skill2                  int64     `json:"skill_2"`
		Skill3                  int64     `json:"skill_3"`
		Skill4                  int64     `json:"skill_4"`
		Skill5                  int64     `json:"skill_5"`
		Birthday                int64     `json:"birthday"`
		IsShow                  bool      `json:"is_show"`
		PracticeStr             int64     `json:"practice_str"`
		PracticeInt             int64     `json:"practice_int"`
		PracticeAgi             int64     `json:"practice_agi"`
		ActiveStyle             int64     `json:"active_style"`
		CreationContentRevision string    `json:"creation_content_revision"`
		StateVersion            int64     `json:"state_version"`
		CreatedAt               time.Time `json:"created_at"`
		UpdatedAt               time.Time `json:"updated_at"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]character.Pet, 0, len(rows))
	for _, x := range rows {
		p := character.Pet{PlayerID: identity.PlayerID(x.PlayerID), PetID: x.PetID, TableID: x.TableID, OriginTableID: x.OriginTableID, Star: x.Star, Level: x.Level, Exp: x.Exp, Color: x.Color, Equipment: character.PetEquipmentSlots{x.Equip1, x.Equip2, x.Equip3}, Fumo: character.PetFumoSlots{x.Fumo1, x.Fumo2, x.Fumo3}, Skills: character.PetSkillLevels{x.Skill1, x.Skill2, x.Skill3, x.Skill4, x.Skill5}, Birthday: x.Birthday, IsShow: x.IsShow, Practice: character.PracticeAttrs{x.PracticeStr, x.PracticeInt, x.PracticeAgi}, ActiveStyle: x.ActiveStyle, CreationContentRevision: x.CreationContentRevision, StateVersion: x.StateVersion, CreatedAt: x.CreatedAt.UTC(), UpdatedAt: x.UpdatedAt.UTC()}
		if err := p.ValidatePersistent(); err != nil {
			return nil, err
		}
		out = append(out, p)
	}
	return out, nil
}

func scanPet(row tx.Row) (character.Pet, error) {
	var p character.Pet
	var pid int64
	if err := row.Scan(&pid, &p.PetID, &p.TableID, &p.OriginTableID, &p.Star, &p.Level, &p.Exp, &p.Color, &p.Equipment[0], &p.Equipment[1], &p.Equipment[2], &p.Fumo[0], &p.Fumo[1], &p.Fumo[2], &p.Skills[0], &p.Skills[1], &p.Skills[2], &p.Skills[3], &p.Skills[4], &p.Birthday, &p.IsShow, &p.Practice[0], &p.Practice[1], &p.Practice[2], &p.ActiveStyle, &p.CreationContentRevision, &p.StateVersion, &p.CreatedAt, &p.UpdatedAt); err != nil {
		return p, err
	}
	p.PlayerID = identity.PlayerID(pid)
	p.CreatedAt, p.UpdatedAt = p.CreatedAt.UTC(), p.UpdatedAt.UTC()
	return p, p.ValidatePersistent()
}
func (Store) SavePetStateTx(ctx context.Context, t tx.Tx, p character.Pet, oldVersion int64) error {
	if t == nil || p.ValidatePersistent() != nil || oldVersion <= 0 || p.StateVersion != oldVersion+1 {
		return errors.New("character store: invalid Pet state update")
	}
	tag, err := t.Exec(ctx, characterqueries.SavePetState, int64(p.PlayerID), p.PetID, p.Star, p.Level, p.Exp, p.Color, p.Skills[0], p.Skills[1], p.Skills[2], p.Skills[3], p.Skills[4], p.Equipment[0], p.Equipment[1], p.Equipment[2], p.Fumo[0], p.Fumo[1], p.Fumo[2], p.UpdatedAt.UTC(), oldVersion)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("character store: Pet state update lost race")
	}
	return nil
}

// SavePetProgressionTx remains as a compatibility wrapper for older internal
// callers; it persists the entire CharacterPet-owned aggregate through the
// same cohesive CAS so progression can never overwrite equipment state.
func (s Store) SavePetProgressionTx(ctx context.Context, t tx.Tx, p character.Pet, oldVersion int64) error {
	return s.SavePetStateTx(ctx, t, p, oldVersion)
}

func (Store) FindPetByOriginTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, originTableID int64) (character.Pet, bool, error) {
	p, err := (Store{}).ReadPetByOriginTx(ctx, q, pid, originTableID)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return character.Pet{}, false, nil
	}
	if err != nil {
		return character.Pet{}, false, err
	}
	return p, true, nil
}

func (Store) ReadPetByOriginTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, originTableID int64) (character.Pet, error) {
	if q == nil || !pid.Valid() || originTableID <= 0 {
		return character.Pet{}, errors.New("character store: invalid Pet origin read")
	}
	return scanPet(q.QueryRow(ctx, characterqueries.ReadPetByOrigin, int64(pid), originTableID))
}
func (Store) ReadPetByIDTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, petID int64) (character.Pet, error) {
	if q == nil || !pid.Valid() || petID <= 0 {
		return character.Pet{}, errors.New("character store: invalid Pet read")
	}
	return scanPet(q.QueryRow(ctx, characterqueries.ReadPetByID, int64(pid), petID))
}
func (Store) LockPetByIDTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, petID int64) (character.Pet, bool, error) {
	if t == nil || !pid.Valid() || petID <= 0 {
		return character.Pet{}, false, errors.New("character store: invalid Pet lock")
	}
	p, err := scanPet(t.QueryRow(ctx, characterqueries.LockPetByID, int64(pid), petID))
	if errors.Is(err, kernelstore.ErrNoRows) {
		return character.Pet{}, false, nil
	}
	if err != nil {
		return character.Pet{}, false, err
	}
	return p, true, nil
}

type PetBootstrapContributor struct{}

func (PetBootstrapContributor) Name() string   { return "ca3.pet-core" }
func (PetBootstrapContributor) Required() bool { return true }
func (PetBootstrapContributor) PersistCharacterBootstrap(ctx context.Context, t tx.Tx, b logicalserver.BootstrapContext) error {
	if t == nil || !b.PlayerID.Valid() || b.Operation.StartedAt.IsZero() {
		return errors.New("character pet store: invalid bootstrap")
	}
	tag, err := t.Exec(ctx, characterqueries.InsertPetRoot, int64(b.PlayerID), b.Operation.StartedAt.UTC())
	if err != nil {
		return err
	}
	if n := tag.RowsAffected(); n != 1 {
		return errors.New("character pet store: bootstrap root not inserted")
	}
	return nil
}

var _ appboot.CharacterBootstrapPersistenceContributor = PetBootstrapContributor{}
