package contentstore

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"
	"math/big"
	"strconv"
	"sync"

	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/registry"
	eventcentre "gxb.local/backend/v2/internal/domain/eventcentre"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	workshopArtifact      = "workshop_input_catalog.json"
	administratorArtifact = "administrator_input_catalog.json"
)

var workshopCatalogs sync.Map

func artifactHash(name string) (string, error) {
	raw, err := builtin.GeneratedFile(name)
	if err != nil {
		return "", err
	}
	sum := sha256.Sum256(raw)
	return hex.EncodeToString(sum[:]), nil
}

func manifestPinsWorkshop(manifest builtin.Manifest) (bool, error) {
	workshopHash, err := artifactHash(workshopArtifact)
	if err != nil {
		return false, err
	}
	administratorHash, err := artifactHash(administratorArtifact)
	if err != nil {
		return false, err
	}
	return manifest.ArtifactSHA256s[workshopArtifact] == workshopHash && manifest.ArtifactSHA256s[administratorArtifact] == administratorHash, nil
}

func (s Store) WorkshopInputsActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, eventcentre.ErrUnqualified
	}
	summary, ok, err := s.ReadActiveSummary(ctx, s.Queryer)
	if err != nil || !ok {
		return "", false, err
	}
	manifest, err := registry.DecodeManifestStrict(summary.ManifestJSON)
	if err != nil {
		return "", false, err
	}
	if manifest.RevisionID != summary.Activation.RevisionID {
		return "", false, errors.New("content store: active Workshop manifest revision mismatch")
	}
	pinned, err := manifestPinsWorkshop(manifest)
	if err != nil {
		return "", false, err
	}
	return summary.Activation.RevisionID, pinned, nil
}

func (s Store) WorkshopInputsTx(ctx context.Context, q tx.Queryer, revision string) (eventcentre.Catalog, error) {
	return memoCatalog(&workshopCatalogs, revision, func() (eventcentre.Catalog, error) {
		return s.workshopInputsTx(ctx, q, revision)
	})
}

func (s Store) workshopInputsTx(ctx context.Context, q tx.Queryer, revision string) (eventcentre.Catalog, error) {
	var out eventcentre.Catalog
	if q == nil || len(revision) != 64 {
		return out, eventcentre.ErrUnqualified
	}
	var raw string
	if err := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&raw); err != nil {
		return out, err
	}
	manifest, err := registry.DecodeManifestStrict([]byte(raw))
	if err != nil {
		return out, err
	}
	if manifest.RevisionID != revision {
		return out, eventcentre.ErrUnqualified
	}
	pinned, err := manifestPinsWorkshop(manifest)
	if err != nil {
		return out, err
	}
	if !pinned {
		return out, eventcentre.ErrUnqualified
	}
	var workshop builtin.WorkshopInputCatalog
	if err := decodeGenerated(workshopArtifact, &workshop); err != nil {
		return out, err
	}
	var administrator builtin.AdministratorInputCatalog
	if err := decodeGenerated(administratorArtifact, &administrator); err != nil {
		return out, err
	}
	return workshopCatalogDomain(workshop, administrator)
}

func decodeGenerated(name string, dst any) error {
	raw, err := builtin.GeneratedFile(name)
	if err != nil {
		return err
	}
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(dst); err != nil {
		return err
	}
	var trailing any
	if decoder.Decode(&trailing) != io.EOF {
		return eventcentre.ErrUnqualified
	}
	return nil
}

func workshopCatalogDomain(workshop builtin.WorkshopInputCatalog, administrator builtin.AdministratorInputCatalog) (eventcentre.Catalog, error) {
	out := eventcentre.Catalog{
		Desk:        map[int64]eventcentre.DeskRule{},
		Recycle:     map[int64]eventcentre.RecycleRule{},
		Admin:       map[[2]int64]eventcentre.AdminRule{},
		AdminLevels: map[int64][]int64{},
		Recipes:     map[int64]eventcentre.Recipe{},
		PetCrafting: map[int64][][]int64{},
	}
	if err := workshop.Validate(); err != nil {
		return out, eventcentre.ErrUnqualified
	}
	if err := administrator.Validate(); err != nil {
		return out, eventcentre.ErrUnqualified
	}
	for _, rule := range workshop.Desk {
		out.Desk[rule.Level] = eventcentre.DeskRule{Level: rule.Level, CutMaketime: rule.CutMaketime, Craftable: append([]int64(nil), rule.CraftableItemIDs...)}
	}
	for _, rule := range workshop.Recycle {
		cutCost, err := eventcentre.ParseDecimal(rule.CutCostEnergy)
		if err != nil {
			return out, err
		}
		critUp, err := eventcentre.ParseDecimal(rule.CritUp)
		if err != nil {
			return out, err
		}
		out.Recycle[rule.Level] = eventcentre.RecycleRule{Level: rule.Level, EnergyLimit: rule.EnergyLimit, CutCostEnergy: cutCost, CritUp: critUp, Recount: append([]int64(nil), rule.RecountItemIDs...)}
	}
	for _, rule := range administrator.Rules {
		costs := map[int64]int64{}
		for key, amount := range rule.Costs {
			identifier, err := strconv.ParseInt(key, 10, 64)
			if err != nil {
				return out, eventcentre.ErrUnqualified
			}
			costs[identifier] = amount
		}
		out.Admin[[2]int64{rule.Destination, rule.Ordinal}] = eventcentre.AdminRule{Destination: rule.Destination, Ordinal: rule.Ordinal, Credit: rule.Credit, Costs: costs}
	}
	for _, level := range administrator.LevelUnlocks {
		out.AdminLevels[level.Level] = append([]int64(nil), level.Unlock...)
	}
	for _, rule := range workshop.ItemRecipes {
		recipe := eventcentre.Recipe{ItemID: rule.ItemID, MakeTime: rule.MakeTime, ResolveEnergy: rule.ResolveEnergy}
		for index, identifier := range rule.MakeResourceIDs {
			recipe.Make = append(recipe.Make, eventcentre.ResourceAmount{ID: identifier, Amount: rule.MakeQuantities[index]})
		}
		for index, identifier := range rule.ResolveResourceIDs {
			recipe.Resolve = append(recipe.Resolve, eventcentre.ResourceAmount{ID: identifier, Amount: rule.ResolveQuantities[index]})
		}
		out.Recipes[rule.ItemID] = recipe
	}
	for _, rule := range workshop.PetCrafting {
		out.PetCrafting[rule.TableID] = rule.Levels
	}
	critParam, err := eventcentre.ParseDecimal(workshop.Misc.CritParam)
	if err != nil {
		return out, err
	}
	proportion, err := eventcentre.ParseDecimal(workshop.Misc.CritProportion)
	if err != nil || proportion.Denom().Cmp(big.NewInt(1)) != 0 || !proportion.Num().IsInt64() {
		return out, eventcentre.ErrUnqualified
	}
	out.Misc = eventcentre.Misc{
		CritParam:                 critParam,
		CritMultiplier:            proportion.Num().Int64(),
		SaturationInit:            workshop.Misc.SaturationInit,
		SaturationSeconds:         workshop.Misc.SaturationTimeSeconds,
		AccelerateItemID:          workshop.Misc.AccelerateItemID,
		AccelerateSeconds:         workshop.Misc.AccelerateTimeSeconds,
		PetColorAccelerateSeconds: workshop.Misc.PetColorAccelerateTimeSeconds,
		PetCostItemIDs:            append([]int64(nil), workshop.Misc.PetCostItemIDs...),
	}
	return out, out.Validate()
}
