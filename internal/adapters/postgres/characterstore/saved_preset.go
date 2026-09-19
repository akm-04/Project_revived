package characterstore

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/characterqueries"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/application/charactersavedpreset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func scanSavedPresetRoot(row tx.Row) (character.SavedPresetRoot, error) {
	var r character.SavedPresetRoot
	var pid int64
	if err := row.Scan(&pid, &r.StateVersion, &r.CreatedAt, &r.UpdatedAt); err != nil {
		if errors.Is(err, kernelstore.ErrNoRows) || errors.Is(err, sql.ErrNoRows) {
			return r, charactersavedpreset.ErrRootMissing
		}
		return r, err
	}
	r.PlayerID = identity.PlayerID(pid)
	r.CreatedAt = r.CreatedAt.UTC()
	r.UpdatedAt = r.UpdatedAt.UTC()
	if err := r.Validate(); err != nil {
		return r, err
	}
	return r, nil
}

func (Store) LockSavedPresetRootTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) (character.SavedPresetRoot, error) {
	if t == nil || !pid.Valid() {
		return character.SavedPresetRoot{}, errors.New("character store: invalid saved-preset root lock")
	}
	return scanSavedPresetRoot(t.QueryRow(ctx, characterqueries.LockSavedPresetRoot, int64(pid)))
}

func (Store) EnsureSavedPresetRootTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, now time.Time) (bool, error) {
	if t == nil || !pid.Valid() || now.IsZero() {
		return false, errors.New("character store: invalid saved-preset root ensure")
	}
	tag, err := t.Exec(ctx, characterqueries.InsertSavedPresetRoot, int64(pid), now.UTC())
	if err != nil {
		return false, err
	}
	n := tag.RowsAffected()
	if n != 0 && n != 1 {
		return false, errors.New("character store: saved-preset root ensure affected unexpected rows")
	}
	return n == 1, nil
}

func (Store) ReadSavedPresetAggregateTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) (character.SavedPresetAggregate, error) {
	if q == nil || !pid.Valid() {
		return character.SavedPresetAggregate{}, errors.New("character store: invalid saved-preset aggregate read")
	}
	var raw string
	var root character.SavedPresetRoot
	var playerID int64
	if err := q.QueryRow(ctx, characterqueries.ReadSavedPresetAggregate, int64(pid)).Scan(&playerID, &root.StateVersion, &root.CreatedAt, &root.UpdatedAt, &raw); err != nil {
		if errors.Is(err, kernelstore.ErrNoRows) || errors.Is(err, sql.ErrNoRows) {
			return character.SavedPresetAggregate{}, charactersavedpreset.ErrRootMissing
		}
		return character.SavedPresetAggregate{}, err
	}
	root.PlayerID = identity.PlayerID(playerID)
	root.CreatedAt, root.UpdatedAt = root.CreatedAt.UTC(), root.UpdatedAt.UTC()
	if err := root.Validate(); err != nil {
		return character.SavedPresetAggregate{}, err
	}
	var rows []struct {
		LaneOrdinal int64  `json:"lane_ordinal"`
		Name        string `json:"name"`
		PetID       *int64 `json:"pet_id"`
		Heroes      []struct {
			HeroOrdinal int64 `json:"hero_ordinal"`
			PartnerID   int64 `json:"partner_id"`
		} `json:"heroes"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return character.SavedPresetAggregate{}, err
	}
	agg := character.SavedPresetAggregate{Root: root, Lanes: make([]character.SavedPresetLane, len(rows))}
	for i, row := range rows {
		if row.LaneOrdinal != int64(i+1) || len(row.Heroes) == 0 {
			return character.SavedPresetAggregate{}, fmt.Errorf("character store: corrupt saved-preset lane ordering")
		}
		lane := character.SavedPresetLane{Name: row.Name, Heroes: make([]character.HeroRef, len(row.Heroes))}
		for j, h := range row.Heroes {
			if h.HeroOrdinal != int64(j+1) {
				return character.SavedPresetAggregate{}, fmt.Errorf("character store: corrupt saved-preset Hero ordering")
			}
			lane.Heroes[j] = character.HeroRef{PlayerID: root.PlayerID, PartnerID: h.PartnerID}
		}
		if row.PetID != nil {
			ref := character.PetRef{PlayerID: root.PlayerID, PetID: *row.PetID}
			lane.Pet = &ref
		}
		agg.Lanes[i] = lane
	}
	if err := agg.Validate(); err != nil {
		return character.SavedPresetAggregate{}, err
	}
	return agg, nil
}

func (Store) ReplaceSavedPresetAggregateTx(ctx context.Context, t tx.Tx, desired character.SavedPresetAggregate, expectedVersion int64) error {
	if t == nil || expectedVersion <= 0 || desired.Validate() != nil || desired.Root.StateVersion != expectedVersion+1 {
		return errors.New("character store: invalid saved-preset replacement")
	}
	if _, err := t.Exec(ctx, characterqueries.DeleteSavedPresetLanes, int64(desired.Root.PlayerID)); err != nil {
		return err
	}
	for li, lane := range desired.Lanes {
		var pet any
		if lane.Pet != nil {
			pet = lane.Pet.PetID
		}
		tag, err := t.Exec(ctx, characterqueries.InsertSavedPresetLane, int64(desired.Root.PlayerID), li+1, lane.Name, pet)
		if err != nil {
			return err
		}
		if tag.RowsAffected() != 1 {
			return errors.New("character store: saved-preset lane insert affected unexpected rows")
		}
		for hi, ref := range lane.Heroes {
			tag, err := t.Exec(ctx, characterqueries.InsertSavedPresetHero, int64(desired.Root.PlayerID), li+1, hi+1, ref.PartnerID)
			if err != nil {
				return err
			}
			if tag.RowsAffected() != 1 {
				return errors.New("character store: saved-preset Hero insert affected unexpected rows")
			}
		}
	}
	tag, err := t.Exec(ctx, characterqueries.SaveSavedPresetRootVersion, int64(desired.Root.PlayerID), desired.Root.UpdatedAt.UTC(), expectedVersion)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return charactersavedpreset.ErrStaleVersion
	}
	return nil
}

type SavedPresetBootstrapContributor struct{}

func (SavedPresetBootstrapContributor) Name() string   { return "ca5.saved-presets" }
func (SavedPresetBootstrapContributor) Required() bool { return true }
func (SavedPresetBootstrapContributor) PersistCharacterBootstrap(ctx context.Context, t tx.Tx, b logicalserver.BootstrapContext) error {
	if t == nil || !b.PlayerID.Valid() || b.Operation.StartedAt.IsZero() {
		return errors.New("character saved preset store: invalid bootstrap")
	}
	created, err := (Store{}).EnsureSavedPresetRootTx(ctx, t, b.PlayerID, b.Operation.StartedAt)
	if err != nil {
		return err
	}
	if !created {
		return errors.New("character saved preset store: bootstrap root not inserted")
	}
	return nil
}

var _ charactersavedpreset.Store = Store{}
var _ appboot.CharacterBootstrapPersistenceContributor = SavedPresetBootstrapContributor{}

func (Store) SavedPresetReferencesHeroTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, partnerID int64) (bool, error) {
	if q == nil || !pid.Valid() || partnerID <= 0 {
		return false, errors.New("character store: invalid saved-preset Hero reference check")
	}
	var exists bool
	if err := q.QueryRow(ctx, characterqueries.SavedPresetReferencesHero, int64(pid), partnerID).Scan(&exists); err != nil {
		return false, err
	}
	return exists, nil
}

func (Store) SavedPresetReferencesPetTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, petID int64) (bool, error) {
	if q == nil || !pid.Valid() || petID <= 0 {
		return false, errors.New("character store: invalid saved-preset Pet reference check")
	}
	var exists bool
	if err := q.QueryRow(ctx, characterqueries.SavedPresetReferencesPet, int64(pid), petID).Scan(&exists); err != nil {
		return false, err
	}
	return exists, nil
}
