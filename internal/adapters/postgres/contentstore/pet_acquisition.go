package contentstore

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	apppet "gxb.local/backend/v2/internal/application/characterpet"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (s Store) PetAcquisitionActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, errors.New("content store: nil Pet acquisition queryer")
	}
	summary, ok, err := (Store{}).ReadActiveSummary(ctx, s.Queryer)
	if err != nil || !ok {
		return "", false, err
	}
	good, err := manifestHasCapability(summary.ManifestJSON, summary.Activation.RevisionID, "PET_ACQUISITION_CA3")
	return summary.Activation.RevisionID, good, err
}

func (s Store) PetAcquisitionRevision(ctx context.Context, revision string) (bool, error) {
	return s.PetAcquisitionRevisionTx(ctx, s.Queryer, revision)
}

func (Store) PetAcquisitionRevisionTx(ctx context.Context, q tx.Queryer, revision string) (bool, error) {
	if q == nil || len(revision) != 64 {
		return false, errors.New("content store: invalid Pet acquisition revision")
	}
	var raw string
	if err := q.QueryRow(ctx, contentqueries.ReadContentRevisionManifest, revision).Scan(&raw); err != nil {
		return false, err
	}
	return manifestHasCapability([]byte(raw), revision, "PET_ACQUISITION_CA3")
}

func (Store) PetAcquisitionTx(ctx context.Context, q tx.Queryer, revision string, tableID int64) (apppet.AcquisitionTemplate, error) {
	if q == nil || len(revision) != 64 || tableID <= 0 {
		return apppet.AcquisitionTemplate{}, errors.New("content store: invalid Pet acquisition lookup")
	}
	var out apppet.AcquisitionTemplate
	out.TableID = tableID
	if err := q.QueryRow(ctx, contentqueries.ReadPetAcquisition, revision, tableID).Scan(&out.OriginTableID, &out.InitialStar, &out.EggItemID, &out.EssenceItemID, &out.FragmentCount, &out.HatchSeconds, &out.SummonType); err != nil {
		return apppet.AcquisitionTemplate{}, err
	}
	if err := out.Validate(); err != nil {
		return apppet.AcquisitionTemplate{}, err
	}
	return out, nil
}

func (Store) PetAcquisitionPolicyTx(ctx context.Context, q tx.Queryer, revision string) (apppet.AcquisitionPolicy, error) {
	if q == nil || len(revision) != 64 {
		return apppet.AcquisitionPolicy{}, errors.New("content store: invalid Pet acquisition policy lookup")
	}
	var out apppet.AcquisitionPolicy
	if err := q.QueryRow(ctx, contentqueries.ReadPetAcquisitionPolicy, revision).Scan(&out.StarterEggItemID, &out.HatchCostParam); err != nil {
		return apppet.AcquisitionPolicy{}, err
	}
	if err := out.Validate(); err != nil {
		return apppet.AcquisitionPolicy{}, err
	}
	return out, nil
}

func (Store) ResolvePetStarterPolicyTx(ctx context.Context, q tx.Queryer, revision string) (appi5.PetStarterPolicy, error) {
	if q == nil || len(revision) != 64 {
		return appi5.PetStarterPolicy{}, errors.New("content store: invalid Pet starter policy lookup")
	}
	var itemID, coeff int64
	if err := q.QueryRow(ctx, contentqueries.ReadPetAcquisitionPolicy, revision).Scan(&itemID, &coeff); err != nil {
		return appi5.PetStarterPolicy{}, err
	}
	if itemID <= 0 || coeff <= 0 {
		return appi5.PetStarterPolicy{}, errors.New("content store: invalid Pet starter policy")
	}
	return appi5.PetStarterPolicy{StarterEggItemID: itemID}, nil
}
