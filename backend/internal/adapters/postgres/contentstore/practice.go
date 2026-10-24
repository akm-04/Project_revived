package contentstore

import (
	"context"
	"encoding/json"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	apppractice "gxb.local/backend/v2/internal/application/characterpractice"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const practiceCapability = apppractice.ContentCapability

func (s Store) PracticeActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, errors.New("content store: nil Practice queryer")
	}
	summary, ok, err := (Store{}).ReadActiveSummary(ctx, s.Queryer)
	if err != nil || !ok {
		return "", false, err
	}
	good, err := manifestHasCapability(summary.ManifestJSON, summary.Activation.RevisionID, practiceCapability)
	return summary.Activation.RevisionID, good, err
}

func (s Store) PracticeRevision(ctx context.Context, revision string) (bool, error) {
	if s.Queryer == nil {
		return false, errors.New("content store: nil Practice revision queryer")
	}
	return (Store{}).PracticeRevisionTx(ctx, s.Queryer, revision)
}

func (Store) PracticeRevisionTx(ctx context.Context, q tx.Queryer, revision string) (bool, error) {
	if q == nil || len(revision) != 64 {
		return false, errors.New("content store: invalid Practice revision")
	}
	var raw string
	if err := q.QueryRow(ctx, contentqueries.ReadContentRevisionManifest, revision).Scan(&raw); err != nil {
		return false, err
	}
	return manifestHasCapability([]byte(raw), revision, practiceCapability)
}

func (Store) PracticeMethodTx(ctx context.Context, q tx.Queryer, revision string, methodID int64) (apppractice.Method, error) {
	if q == nil || len(revision) != 64 || methodID < 1 || methodID > 3 {
		return apppractice.Method{}, errors.New("content store: invalid Practice method lookup")
	}
	out := apppractice.Method{ID: methodID}
	if err := q.QueryRow(ctx, contentqueries.ReadPracticeMethod, revision, methodID).Scan(&out.CurrencyType, &out.BaseCost, &out.VIPMin); err != nil {
		return apppractice.Method{}, err
	}
	if out.CurrencyType < 1 || out.CurrencyType > 2 || out.BaseCost < 0 || out.VIPMin < 0 {
		return apppractice.Method{}, errors.New("content store: corrupt Practice method")
	}
	return out, nil
}

func (Store) PracticeLockTx(ctx context.Context, q tx.Queryer, revision string, lockCount int64) (apppractice.LockCost, error) {
	if q == nil || len(revision) != 64 || lockCount < 1 || lockCount > 3 {
		return apppractice.LockCost{}, errors.New("content store: invalid Practice lock lookup")
	}
	out := apppractice.LockCost{Count: lockCount}
	if err := q.QueryRow(ctx, contentqueries.ReadPracticeLock, revision, lockCount).Scan(&out.ManaStep, &out.CrystalStep, &out.BlessCost, &out.SourceUpLimit); err != nil {
		return apppractice.LockCost{}, err
	}
	if out.ManaStep < 0 || out.CrystalStep < 0 || out.BlessCost < 0 || out.SourceUpLimit < 0 {
		return apppractice.LockCost{}, errors.New("content store: corrupt Practice lock")
	}
	return out, nil
}

func (Store) PracticeVIPBlessTx(ctx context.Context, q tx.Queryer, revision string, vipLevel int64) (int64, error) {
	if q == nil || len(revision) != 64 || vipLevel < 0 || vipLevel > 15 {
		return 0, errors.New("content store: invalid Practice VIP Bless lookup")
	}
	var v int64
	if err := q.QueryRow(ctx, contentqueries.ReadPracticeVIPBless, revision, vipLevel).Scan(&v); err != nil {
		return 0, err
	}
	if v < 0 {
		return 0, errors.New("content store: corrupt Practice VIP Bless")
	}
	return v, nil
}

func (Store) PracticePolicyFactsTx(ctx context.Context, q tx.Queryer, revision string) (apppractice.PolicyFacts, error) {
	if q == nil || len(revision) != 64 {
		return apppractice.PolicyFacts{}, errors.New("content store: invalid Practice policy lookup")
	}
	var out apppractice.PolicyFacts
	if err := q.QueryRow(ctx, contentqueries.ReadPracticePolicyFacts, revision).Scan(&out.UnlockLevel, &out.AttrCap, &out.FreeIntervalSeconds, &out.LegendaryVIPMin, &out.TicketItemID, &out.TicketAdd[0], &out.TicketAdd[1], &out.TicketAdd[2]); err != nil {
		return apppractice.PolicyFacts{}, err
	}
	if err := out.Validate(); err != nil {
		return apppractice.PolicyFacts{}, err
	}
	return out, nil
}

type thresholdWire struct {
	Ordinal        int64 `json:"ordinal"`
	NeedValue      int64 `json:"need_value"`
	TargetAttrType int64 `json:"target_attr_type"`
	BonusValue     int64 `json:"bonus_value"`
}

func parseThresholds(raw string) ([]apppractice.Threshold, error) {
	var w []thresholdWire
	if err := json.Unmarshal([]byte(raw), &w); err != nil {
		return nil, err
	}
	if len(w) != 3 {
		return nil, errors.New("content store: Practice threshold cardinality mismatch")
	}
	out := make([]apppractice.Threshold, len(w))
	for i, x := range w {
		if x.Ordinal != int64(i+1) || x.NeedValue < 0 || x.TargetAttrType < 0 || x.BonusValue < 0 {
			return nil, errors.New("content store: corrupt Practice threshold")
		}
		out[i] = apppractice.Threshold{Ordinal: x.Ordinal, NeedValue: x.NeedValue, TargetAttrType: x.TargetAttrType, BonusValue: x.BonusValue}
	}
	return out, nil
}

func (Store) HeroPracticeThresholdsTx(ctx context.Context, q tx.Queryer, revision string, tableID int64) ([]apppractice.Threshold, error) {
	if q == nil || len(revision) != 64 || tableID <= 0 {
		return nil, errors.New("content store: invalid Hero Practice threshold lookup")
	}
	var raw string
	if err := q.QueryRow(ctx, contentqueries.ReadHeroPracticeThresholds, revision, tableID).Scan(&raw); err != nil {
		return nil, err
	}
	return parseThresholds(raw)
}
func (Store) PetPracticeThresholdsTx(ctx context.Context, q tx.Queryer, revision string, tableID int64) ([]apppractice.Threshold, error) {
	if q == nil || len(revision) != 64 || tableID <= 0 {
		return nil, errors.New("content store: invalid Pet Practice threshold lookup")
	}
	var raw string
	if err := q.QueryRow(ctx, contentqueries.ReadPetPracticeThresholds, revision, tableID).Scan(&raw); err != nil {
		return nil, err
	}
	return parseThresholds(raw)
}
func (Store) HeroTemplateAwakenedTx(ctx context.Context, q tx.Queryer, revision string, tableID int64) (bool, error) {
	if q == nil || len(revision) != 64 || tableID <= 0 {
		return false, errors.New("content store: invalid Hero awakened-template lookup")
	}
	var v bool
	if err := q.QueryRow(ctx, contentqueries.ReadHeroTemplateAwakened, revision, tableID).Scan(&v); err != nil {
		return false, err
	}
	return v, nil
}

var _ apppractice.Content = Store{}
