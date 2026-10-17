package contentstore

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{ Queryer tx.Queryer }

func (Store) LockRegistry(ctx context.Context, t tx.Tx) error {
	if t == nil {
		return errors.New("content store: nil transaction")
	}
	_, err := t.Exec(ctx, contentqueries.LockContentRegistry)
	return err
}
func (Store) TryInsertRevision(ctx context.Context, t tx.Tx, b registry.Bundle) (bool, error) {
	if t == nil {
		return false, errors.New("content store: nil transaction")
	}
	var inserted bool
	err := t.QueryRow(ctx, contentqueries.TryInsertContentRevision, b.RevisionID(), b.SchemaVersion(), b.CompilerVersion(), b.ParserVersion(), string(b.ManifestJSON())).Scan(&inserted)
	return inserted, err
}
func (Store) InsertResources(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	if t == nil {
		return 0, errors.New("content store: nil transaction")
	}
	var n int64
	err := t.QueryRow(ctx, contentqueries.InsertContentResources, b.RevisionID(), string(b.ResourcesJSON())).Scan(&n)
	return n, err
}
func (Store) InsertProgression(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	if t == nil {
		return 0, errors.New("content store: nil transaction")
	}
	var n int64
	err := t.QueryRow(ctx, contentqueries.InsertContentPlayerProgression, b.RevisionID(), string(b.ProgressionJSON())).Scan(&n)
	return n, err
}
func (Store) InsertFunctionGates(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	if t == nil {
		return 0, errors.New("content store: nil transaction")
	}
	var n int64
	err := t.QueryRow(ctx, contentqueries.InsertContentFunctionGates, b.RevisionID(), string(b.FunctionGatesJSON())).Scan(&n)
	return n, err
}
func (Store) InsertObjectives(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	if t == nil {
		return 0, errors.New("content store: nil transaction")
	}
	var n int64
	err := t.QueryRow(ctx, contentqueries.InsertContentObjectives, b.RevisionID(), string(b.ObjectivesJSON())).Scan(&n)
	return n, err
}
func (Store) InsertHeroCore(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	if t == nil {
		return 0, errors.New("content store: nil transaction")
	}
	var n int64
	err := t.QueryRow(ctx, contentqueries.InsertContentHeroCore, b.RevisionID(), string(b.HeroCoreJSON())).Scan(&n)
	return n, err
}
func (Store) InsertPetCore(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	if t == nil {
		return 0, errors.New("content store: nil transaction")
	}
	var n int64
	err := t.QueryRow(ctx, contentqueries.InsertContentPetCore, b.RevisionID(), string(b.PetCoreJSON())).Scan(&n)
	return n, err
}
func (Store) InsertPetAcquisition(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	if t == nil {
		return 0, errors.New("content store: nil transaction")
	}
	var n int64
	err := t.QueryRow(ctx, contentqueries.InsertContentPetAcquisition, b.RevisionID(), string(b.PetAcquisitionJSON())).Scan(&n)
	return n, err
}
func (Store) InsertPetProgression(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	if t == nil {
		return 0, errors.New("content store: nil transaction")
	}
	var n int64
	err := t.QueryRow(ctx, contentqueries.InsertContentPetProgression, b.RevisionID(), string(b.PetProgressionJSON())).Scan(&n)
	return n, err
}
func (Store) InsertEquipmentPrimitives(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	if t == nil {
		return 0, errors.New("content store: nil transaction")
	}
	var n int64
	err := t.QueryRow(ctx, contentqueries.InsertContentEquipmentPrimitives, b.RevisionID(), string(b.EquipmentPrimitivesJSON())).Scan(&n)
	return n, err
}

func (Store) InsertHeroEquipment(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	if t == nil {
		return 0, errors.New("content store: nil transaction")
	}
	var n int64
	err := t.QueryRow(ctx, contentqueries.InsertContentHeroEquipment, b.RevisionID(), string(b.HeroEquipmentJSON())).Scan(&n)
	return n, err
}

func (Store) InsertSuperEquipment(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	if t == nil {
		return 0, errors.New("content store: nil transaction")
	}
	var n int64
	err := t.QueryRow(ctx, contentqueries.InsertContentSuperEquipment, b.RevisionID(), string(b.SuperEquipmentJSON())).Scan(&n)
	return n, err
}

func (Store) InsertHeroFumo(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, int64, error) {
	if t == nil {
		return 0, 0, errors.New("content store: nil transaction")
	}
	var targets, materials int64
	err := t.QueryRow(ctx, contentqueries.InsertContentHeroFumo, b.RevisionID(), string(b.HeroFumoJSON())).Scan(&targets, &materials)
	return targets, materials, err
}

func (Store) InsertHeroPromotionRestoration(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, int64, int64, error) {
	if t == nil {
		return 0, 0, 0, errors.New("content store: nil transaction")
	}
	var equipment, fractions, denominations int64
	err := t.QueryRow(ctx, contentqueries.InsertContentHeroPromotionRestoration, b.RevisionID(), string(b.HeroPromotionRestorationJSON())).Scan(&equipment, &fractions, &denominations)
	return equipment, fractions, denominations, err
}

func (Store) InsertPetEquipment(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	if t == nil {
		return 0, errors.New("content store: nil transaction")
	}
	var n int64
	err := t.QueryRow(ctx, contentqueries.InsertContentPetEquipment, b.RevisionID(), string(b.PetEquipmentJSON())).Scan(&n)
	return n, err
}

func (Store) InsertPetPromotionRestoration(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	if t == nil {
		return 0, errors.New("content store: nil transaction")
	}
	var n int64
	err := t.QueryRow(ctx, contentqueries.InsertContentPetPromotionRestoration, b.RevisionID(), string(b.PetPromotionRestorationJSON())).Scan(&n)
	return n, err
}

func (Store) InsertPractice(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	if t == nil {
		return 0, errors.New("content store: nil transaction")
	}
	var n int64
	err := t.QueryRow(ctx, contentqueries.InsertContentPractice, b.RevisionID(), string(b.PracticeJSON())).Scan(&n)
	return n, err
}

func (Store) InsertAppearance(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	if t == nil {
		return 0, errors.New("content store: nil transaction")
	}
	var n int64
	err := t.QueryRow(ctx, contentqueries.InsertContentAppearance, b.RevisionID(), string(b.AppearanceJSON())).Scan(&n)
	return n, err
}

const verifyGuildInviteSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_guild_invite_policies WHERE revision_id=$1`

const verifyGuildBroadcastSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_guild_broadcast_policies WHERE revision_id=$1`

const verifySocialGiftSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false) FROM content_social_gift_catalogs WHERE revision_id=$1`

func (Store) VerifyRevision(ctx context.Context, q tx.Queryer, b registry.Bundle) (registry.Verification, error) {
	if q == nil {
		return registry.Verification{}, errors.New("content store: nil queryer")
	}
	var v registry.Verification
	err := q.QueryRow(ctx, contentqueries.VerifyContentRevision, b.RevisionID(), b.SchemaVersion(), b.CompilerVersion(), b.ParserVersion(), string(b.ManifestJSON()), string(b.ResourcesJSON()), string(b.ProgressionJSON()), string(b.FunctionGatesJSON()), string(b.ObjectivesJSON()), string(b.HeroCoreJSON()), string(b.PetCoreJSON()), string(b.PetAcquisitionJSON()), string(b.PetProgressionJSON()), string(b.EquipmentPrimitivesJSON()), string(b.HeroEquipmentJSON()), string(b.HeroFumoJSON()), string(b.HeroPromotionRestorationJSON()), string(b.PetEquipmentJSON()), string(b.PetPromotionRestorationJSON()), string(b.SuperEquipmentJSON()), string(b.PracticeJSON()), string(b.AppearanceJSON())).Scan(&v.Exact, &v.ResourceCount, &v.ProgressionCount, &v.FunctionGateCount, &v.ObjectiveCount, &v.HeroCount, &v.PetCount, &v.PetAcquisitionCount, &v.PetProgressionCount, &v.EquipmentPrimitiveCount, &v.HeroEquipmentCount, &v.SuperEquipmentCount, &v.HeroFumoTargetCount, &v.HeroFumoMaterialCount, &v.HeroPromotionRestorationEquipmentCount, &v.HeroPromotionRestorationFractionCount, &v.HeroPromotionRestorationDenominationCount, &v.PetEquipmentCount, &v.PetPromotionRestorationEquipmentCount, &v.PracticeCount, &v.AppearanceCount)
	if err != nil {
		return v, err
	}
	var displayExact bool
	var dormExact bool
	var bookExact bool
	var privilegeExact bool
	err = q.QueryRow(ctx, verifyPrivilegeSQL, b.RevisionID(), string(b.PrivilegeJSON())).Scan(&privilegeExact, &v.PrivilegeCount)
	if err != nil {
		return registry.Verification{}, err
	}
	v.Exact = v.Exact && privilegeExact
	var statInputsExact bool
	err = q.QueryRow(ctx, verifyStatInputsSQL, b.RevisionID(), string(b.StatInputsJSON())).Scan(&statInputsExact, &v.StatInputsCount)
	if err != nil {
		return registry.Verification{}, err
	}
	v.Exact = v.Exact && statInputsExact
	var statExact bool
	err = q.QueryRow(ctx, verifyStatRulesSQL, b.RevisionID(), string(b.StatRulesJSON())).Scan(&statExact, &v.StatRulesCount)
	if err != nil {
		return registry.Verification{}, err
	}
	v.Exact = v.Exact && statExact
	var conquerExact bool
	err = q.QueryRow(ctx, verifyConquerInputsSQL, b.RevisionID(), string(b.ConquerInputsJSON())).Scan(&conquerExact, &v.ConquerInputsCount)
	if err != nil {
		return registry.Verification{}, err
	}
	v.Exact = v.Exact && conquerExact
	var evolutionExact bool
	err = q.QueryRow(ctx, verifyEvolutionInputsSQL, b.RevisionID(), string(b.EvolutionInputsJSON())).Scan(&evolutionExact, &v.EvolutionInputsCount)
	if err != nil {
		return registry.Verification{}, err
	}
	v.Exact = v.Exact && evolutionExact
	var spiritExact bool
	err = q.QueryRow(ctx, verifySpiritInputsSQL, b.RevisionID(), string(b.SpiritInputsJSON())).Scan(&spiritExact, &v.SpiritInputsCount)
	if err != nil {
		return registry.Verification{}, err
	}
	v.Exact = v.Exact && spiritExact
	var elementExact bool
	err = q.QueryRow(ctx, verifyElementInputsSQL, b.RevisionID(), string(b.ElementInputsJSON())).Scan(&elementExact, &v.ElementInputsCount)
	if err != nil {
		return registry.Verification{}, err
	}
	v.Exact = v.Exact && elementExact
	var inscriptionExact bool
	err = q.QueryRow(ctx, verifyInscriptionInputsSQL, b.RevisionID(), string(b.InscriptionInputsJSON())).Scan(&inscriptionExact, &v.InscriptionInputsCount)
	if err != nil {
		return registry.Verification{}, err
	}
	v.Exact = v.Exact && inscriptionExact
	var courseExact bool
	err = q.QueryRow(ctx, verifyCourseInputsSQL, b.RevisionID(), string(b.CourseInputsJSON())).Scan(&courseExact, &v.CourseInputsCount)
	if err != nil {
		return v, err
	}
	v.Exact = v.Exact && courseExact
	err = q.QueryRow(ctx, verifyBookInputsSQL, b.RevisionID(), string(b.BookInputsJSON())).Scan(&bookExact, &v.BookInputsCount)
	if err != nil {
		return v, err
	}
	v.Exact = v.Exact && bookExact
	err = q.QueryRow(ctx, verifyDormInputsSQL, b.RevisionID(), string(b.DormInputsJSON())).Scan(&dormExact, &v.DormInputsCount)
	if err != nil {
		return v, err
	}
	v.Exact = v.Exact && dormExact
	var libraryExact bool
	err = q.QueryRow(ctx, verifyLibraryInputsSQL, b.RevisionID(), string(b.LibraryInputsJSON())).Scan(&libraryExact, &v.LibraryInputsCount)
	v.Exact = v.Exact && libraryExact
	if err != nil {
		return v, err
	}
	err = q.QueryRow(ctx, verifyPlayerDisplaySQL, b.RevisionID(), string(b.PlayerDisplayJSON())).Scan(&displayExact, &v.PlayerDisplayCount)
	if err != nil {
		return v, err
	}
	v.Exact = v.Exact && displayExact
	var showcaseExact bool
	err = q.QueryRow(ctx, verifyPublicShowcaseSQL, b.RevisionID(), string(b.PublicShowcaseJSON())).Scan(&showcaseExact, &v.PublicShowcaseCount)
	if err != nil {
		return v, err
	}
	v.Exact = v.Exact && showcaseExact
	var profileExact bool
	err = q.QueryRow(ctx, verifyPublicProfileSQL, b.RevisionID(), string(b.PublicProfileJSON())).Scan(&profileExact, &v.PublicProfileCount)
	if err != nil {
		return v, err
	}
	v.Exact = v.Exact && profileExact
	var exact bool
	err = q.QueryRow(ctx, contentqueries.VerifyContentEmoticons, b.RevisionID(), string(b.EmoticonsJSON())).Scan(&exact, &v.EmoticonCount)
	v.Exact = v.Exact && exact
	if err != nil {
		return v, err
	}
	var giftExact bool
	err = q.QueryRow(ctx, verifySocialGiftSQL, b.RevisionID(), string(b.SocialGiftJSON())).Scan(&giftExact)
	v.Exact = v.Exact && giftExact
	if err != nil {
		return v, err
	}
	var broadcastExact bool
	err = q.QueryRow(ctx, verifyGuildBroadcastSQL, b.RevisionID(), string(b.GuildBroadcastJSON())).Scan(&broadcastExact, &v.GuildBroadcastCount)
	v.Exact = v.Exact && broadcastExact
	if err != nil {
		return v, err
	}
	var inviteExact bool
	err = q.QueryRow(ctx, verifyGuildInviteSQL, b.RevisionID(), string(b.GuildInviteJSON())).Scan(&inviteExact, &v.GuildInviteCount)
	v.Exact = v.Exact && inviteExact
	return v, err
}

// HeroKind resolves immutable Hero projection metadata from the exact revision
// that created the Hero. Character persistence does not duplicate this content fact.
func (s Store) HeroKind(ctx context.Context, revision string, tableID int64) (character.HeroKind, error) {
	if s.Queryer == nil {
		return "", errors.New("content store: nil Hero kind queryer")
	}
	return (Store{}).HeroKindTx(ctx, s.Queryer, revision, tableID)
}

// HeroKindTx resolves immutable Hero projection metadata through the caller's
// transaction/queryer. Bootstrap projections use this to avoid opening a
// second persistence scope while reconstructing stock MID49 state.
func (Store) HeroKindTx(ctx context.Context, q tx.Queryer, revision string, tableID int64) (character.HeroKind, error) {
	if q == nil || len(revision) != 64 || tableID <= 0 {
		return "", errors.New("content store: invalid Hero kind lookup")
	}
	var raw string
	if err := q.QueryRow(ctx, contentqueries.ReadHeroTemplateKind, revision, tableID).Scan(&raw); err != nil {
		return "", err
	}
	k := character.HeroKind(raw)
	if k != character.NormalHero && k != character.SuperHero {
		return "", errors.New("content store: invalid Hero kind")
	}
	return k, nil
}

// HeroCoreActive reports whether the current immutable revision explicitly
// advertises the sealed CA2 Hero capability. Older schema-v1 revisions remain
// startup-valid; Hero routes fail closed until explicit host activation.
func (s Store) HeroCoreActive(ctx context.Context) (string, bool, error) {
	return s.HeroCoreActiveTx(ctx, s.Queryer)
}
func (Store) HeroCoreActiveTx(ctx context.Context, q tx.Queryer) (string, bool, error) {
	if q == nil {
		return "", false, errors.New("content store: nil Hero capability queryer")
	}
	summary, ok, err := (Store{}).ReadActiveSummary(ctx, q)
	if err != nil || !ok {
		return "", false, err
	}
	m, err := registry.DecodeManifestStrict(summary.ManifestJSON)
	if err != nil {
		return "", false, err
	}
	if m.RevisionID != summary.Activation.RevisionID {
		return "", false, errors.New("content store: active Hero manifest revision mismatch")
	}
	for _, c := range m.EnabledCapabilities {
		if c == "HERO_CORE_CA2" {
			return m.RevisionID, true, nil
		}
	}
	return m.RevisionID, false, nil
}

func (Store) ReadActivation(ctx context.Context, q tx.Queryer) (registry.ActivationIdentity, bool, error) {
	if q == nil {
		return registry.ActivationIdentity{}, false, errors.New("content store: nil queryer")
	}
	var exists bool
	var a registry.ActivationIdentity
	err := q.QueryRow(ctx, contentqueries.ReadContentActivation).Scan(&exists, &a.RevisionID, &a.Version, &a.ActivatedAt, &a.ActivatedBy)
	if err != nil {
		return registry.ActivationIdentity{}, false, err
	}
	if !exists {
		return registry.ActivationIdentity{}, false, nil
	}
	a.ActivatedAt = a.ActivatedAt.UTC()
	return a, true, nil
}
func (Store) ReadActiveSummary(ctx context.Context, q tx.Queryer) (registry.ActiveSummary, bool, error) {
	if q == nil {
		return registry.ActiveSummary{}, false, errors.New("content store: nil queryer")
	}
	var exists bool
	var s registry.ActiveSummary
	var raw string
	err := q.QueryRow(ctx, contentqueries.ReadActiveContentSummary).Scan(&exists, &s.Activation.RevisionID, &s.Activation.Version, &s.Activation.ActivatedAt, &s.Activation.ActivatedBy, &s.SchemaVersion, &raw)
	if err != nil {
		return registry.ActiveSummary{}, false, err
	}
	if !exists {
		return registry.ActiveSummary{}, false, nil
	}
	s.Activation.ActivatedAt = s.Activation.ActivatedAt.UTC()
	s.ManifestJSON = []byte(raw)
	return s, true, nil
}
func (Store) BootstrapActivation(ctx context.Context, t tx.Tx, revision string, at time.Time, actor string) (bool, error) {
	if t == nil {
		return false, errors.New("content store: nil transaction")
	}
	tag, err := t.Exec(ctx, contentqueries.BootstrapContentActivation, revision, at.UTC(), actor)
	if err != nil {
		return false, err
	}
	n := tag.RowsAffected()
	if n < 0 || n > 1 {
		return false, fmt.Errorf("content store: bootstrap rows affected %d", n)
	}
	return n == 1, nil
}
func (Store) ActivateCAS(ctx context.Context, t tx.Tx, target string, at time.Time, actor string, expected registry.ActivationIdentity) (bool, error) {
	if t == nil {
		return false, errors.New("content store: nil transaction")
	}
	tag, err := t.Exec(ctx, contentqueries.ActivateContentCAS, target, at.UTC(), actor, expected.RevisionID, expected.Version)
	if err != nil {
		return false, err
	}
	n := tag.RowsAffected()
	if n < 0 || n > 1 {
		return false, fmt.Errorf("content store: activation rows affected %d", n)
	}
	return n == 1, nil
}

// ActiveRevision is the R4D owning-command admission read. Callers must retain
// the returned immutable revision in operation.Context.Policies and never use
// this method as an implicit lookup from resource/objective reads.
func (Store) ActiveRevision(ctx context.Context, q tx.Queryer) (string, error) {
	if q == nil {
		return "", errors.New("content store: nil active-revision queryer")
	}
	a, ok, err := (Store{}).ReadActivation(ctx, q)
	if err != nil {
		return "", err
	}
	if !ok || a.RevisionID == "" {
		return "", errors.New("content store: active content revision unavailable")
	}
	return a.RevisionID, nil
}

func (Store) ResolveResourceTx(ctx context.Context, q tx.Queryer, revision string, line grant.Line) (appi5.ResourcePolicy, error) {
	if q == nil || revision == "" {
		return appi5.ResourcePolicy{}, errors.New("content store: exact resource lookup requires queryer and revision")
	}
	if err := line.Validate(); err != nil {
		return appi5.ResourcePolicy{}, err
	}
	var class, catalogStatus, activation, resourceKey, capRule, specializedOwner, reason string
	var itemID, stackCap, regenSeconds, regenAmount, staticCap int64
	var overflow bool
	var row tx.Row
	switch line.Kind {
	case grant.ScalarCurrency:
		row = q.QueryRow(ctx, contentqueries.ReadContentResourceByResourceKey, revision, string(grant.ScalarCurrency), line.ResourceKey)
	case grant.Temporal:
		row = q.QueryRow(ctx, contentqueries.ReadContentResourceByResourceKey, revision, string(grant.Temporal), line.ResourceKey)
	case grant.PlayerExp:
		row = q.QueryRow(ctx, contentqueries.ReadContentResourceByResourceKey, revision, string(grant.PlayerExp), "exp")
	case grant.StackItem:
		row = q.QueryRow(ctx, contentqueries.ReadContentResourceByItemID, revision, line.ItemID)
	default:
		return appi5.ResourcePolicy{}, economy.ErrUnknownResource
	}
	if err := row.Scan(&class, &catalogStatus, &activation, &resourceKey, &itemID, &stackCap, &overflow, &regenSeconds, &regenAmount, &capRule, &staticCap, &specializedOwner, &reason); err != nil {
		if errors.Is(err, kernelstore.ErrNoRows) {
			return appi5.ResourcePolicy{}, economy.ErrUnknownResource
		}
		return appi5.ResourcePolicy{}, err
	}
	_ = catalogStatus
	_ = resourceKey
	_ = specializedOwner
	_ = reason
	if class != string(line.Kind) {
		return appi5.ResourcePolicy{}, economy.ErrUnknownResource
	}
	out := appi5.ResourcePolicy{Kind: line.Kind, PolicyVersion: revision}
	switch line.Kind {
	case grant.ScalarCurrency:
		if activation != "ENABLED_R4" {
			return appi5.ResourcePolicy{}, economy.ErrUnknownResource
		}
		return out, nil
	case grant.StackItem:
		if activation != "ENABLED_R4" || itemID != line.ItemID {
			return appi5.ResourcePolicy{}, economy.ErrUnknownResource
		}
		def := economy.StackDefinition{ItemID: itemID, StackCap: stackCap, OverflowToMail: overflow}
		if err := def.Validate(); err != nil {
			return appi5.ResourcePolicy{}, err
		}
		out.WireTableID = itemID
		out.Stack = &def
		return out, nil
	case grant.PlayerExp:
		if activation != "ENABLED_R5" {
			return appi5.ResourcePolicy{}, economy.ErrUnknownResource
		}
		return out, nil
	case grant.Temporal:
		if activation != "ENABLED_R5" || regenSeconds <= 0 || regenAmount <= 0 || capRule == "" {
			return appi5.ResourcePolicy{}, economy.ErrUnknownResource
		}
		d := appi5.TemporalDescriptor{Revision: revision, ResourceKey: resourceKey, RegenEvery: time.Duration(regenSeconds) * time.Second, RegenAmount: regenAmount, CapRule: capRule, StaticCap: staticCap, AllowExplicitGrantAboveNaturalCap: true}
		out.Descriptor = &d
		return out, nil
	default:
		return appi5.ResourcePolicy{}, economy.ErrUnknownResource
	}
}

func (Store) ResolveProgressionPolicyTx(ctx context.Context, q tx.Queryer, revision string) (player.ProgressionPolicy, error) {
	if q == nil || revision == "" {
		return player.ProgressionPolicy{}, errors.New("content store: exact progression lookup requires queryer and revision")
	}
	var raw string
	if err := q.QueryRow(ctx, contentqueries.ReadContentPlayerProgressionPolicy, revision).Scan(&raw); err != nil {
		return player.ProgressionPolicy{}, err
	}
	var rows []struct {
		Level       int64 `json:"level"`
		MaxEnergy   int64 `json:"max_energy"`
		AwardEnergy int64 `json:"award_energy"`
		TotalExp    int64 `json:"total_exp"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return player.ProgressionPolicy{}, err
	}
	if len(rows) == 0 {
		return player.ProgressionPolicy{}, economy.ErrUnknownResource
	}
	out := player.ProgressionPolicy{Revision: revision, Rows: make([]player.ProgressionRow, 0, len(rows))}
	for _, r := range rows {
		out.Rows = append(out.Rows, player.ProgressionRow{Level: r.Level, MaxEnergy: r.MaxEnergy, AwardEnergy: r.AwardEnergy, TotalExp: r.TotalExp})
	}
	if err := out.Validate(); err != nil {
		return player.ProgressionPolicy{}, err
	}
	return out, nil
}

func (Store) ResolveFunctionGatePolicyTx(ctx context.Context, q tx.Queryer, revision string) (appi5.FunctionGatePolicy, error) {
	if q == nil || revision == "" {
		return appi5.FunctionGatePolicy{}, errors.New("content store: exact function lookup requires queryer and revision")
	}
	var raw string
	if err := q.QueryRow(ctx, contentqueries.ReadContentFunctionGatePolicy, revision).Scan(&raw); err != nil {
		return appi5.FunctionGatePolicy{}, err
	}
	var rows []struct {
		FunctionID             int64  `json:"function_id"`
		GateKind               string `json:"gate_kind"`
		RequiredLevel          *int64 `json:"required_level"`
		RawOpenValue           string `json:"raw_open_value"`
		SourceFactKey          string `json:"source_fact_key"`
		AnnouncementCapability string `json:"announcement_capability"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return appi5.FunctionGatePolicy{}, err
	}
	if len(rows) == 0 {
		return appi5.FunctionGatePolicy{}, economy.ErrUnknownResource
	}
	out := appi5.FunctionGatePolicy{Revision: revision, Gates: make([]appi5.FunctionGate, 0, len(rows))}
	for _, r := range rows {
		level := int64(0)
		if r.RequiredLevel != nil {
			level = *r.RequiredLevel
		}
		out.Gates = append(out.Gates, appi5.FunctionGate{FunctionID: r.FunctionID, GateKind: r.GateKind, RequiredLevel: level, RawOpenValue: r.RawOpenValue, SourceFactKey: r.SourceFactKey, AnnouncementCapability: r.AnnouncementCapability})
	}
	return out, nil
}

func (s Store) ResolveObjective(ctx context.Context, revision, program string, objectiveID int64, definitionRevision string) (appi5.ObjectiveDefinition, error) {
	if s.Queryer == nil {
		return appi5.ObjectiveDefinition{}, errors.New("content store: nil runtime queryer")
	}
	return s.ResolveObjectiveTx(ctx, s.Queryer, revision, program, objectiveID, definitionRevision)
}

func (Store) ResolveObjectiveTx(ctx context.Context, q tx.Queryer, revision, program string, objectiveID int64, definitionRevision string) (appi5.ObjectiveDefinition, error) {
	if q == nil || revision == "" || program == "" || objectiveID <= 0 || definitionRevision == "" {
		return appi5.ObjectiveDefinition{}, errors.New("content store: exact objective lookup incomplete")
	}
	var family, target, huoyue int64
	var strategy, fact, rewardJSON string
	if err := q.QueryRow(ctx, contentqueries.ReadContentObjectiveDefinition, revision, program, objectiveID, definitionRevision).Scan(&family, &strategy, &fact, &target, &rewardJSON, &huoyue); err != nil {
		if errors.Is(err, kernelstore.ErrNoRows) {
			return appi5.ObjectiveDefinition{}, appi5.ErrObjectiveNotFound
		}
		return appi5.ObjectiveDefinition{}, err
	}
	st, err := contentObjectiveStrategy(strategy)
	if err != nil {
		return appi5.ObjectiveDefinition{}, err
	}
	plan, err := decodeContentGrantPlan([]byte(rewardJSON))
	if err != nil {
		return appi5.ObjectiveDefinition{}, err
	}
	out := appi5.ObjectiveDefinition{
		Family:     objective.StockFamily(family),
		Definition: objective.Definition{ProgramID: program, ObjectiveID: objectiveID, DefinitionRevision: definitionRevision, Strategy: st, AcceptedFactKind: fact, Target: target},
		Reward:     plan,
		Huoyue:     huoyue,
	}
	if err := out.Definition.Validate(); err != nil {
		return appi5.ObjectiveDefinition{}, err
	}
	return out, nil
}

func contentObjectiveStrategy(s string) (objective.Strategy, error) {
	switch s {
	case "HIGH_WATER":
		return objective.HighWaterFromCanonicalState, nil
	case "COMMITTED_DELTA":
		return objective.CommittedDeltaFact, nil
	case "TEMPORAL_ENTITLEMENT":
		return objective.TemporalEntitlement, nil
	case "DOMAIN_VALIDATED":
		return objective.DomainSpecificValidatedFact, nil
	default:
		return 0, errors.New("content store: unknown objective strategy")
	}
}

func decodeContentGrantPlan(raw []byte) (grant.Plan, error) {
	var p grant.Plan
	if err := json.Unmarshal(raw, &p); err != nil {
		return grant.Plan{}, err
	}
	if p.Source.PolicyVersion == "" || len(p.Lines) == 0 {
		return grant.Plan{}, errors.New("content store: objective reward plan incomplete")
	}
	for _, line := range p.Lines {
		if err := line.Validate(); err != nil {
			return grant.Plan{}, err
		}
	}
	return p, nil
}

func (Store) InsertEmoticons(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	var n int64
	err := t.QueryRow(ctx, contentqueries.InsertContentEmoticons, b.RevisionID(), string(b.EmoticonsJSON())).Scan(&n)
	return n, err
}

func (Store) InsertSocialGift(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_social_gift_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.SocialGiftJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

func (Store) InsertGuildBroadcast(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	if t == nil {
		return 0, errors.New("content store: nil transaction")
	}
	tag, e := t.Exec(ctx, `INSERT INTO content_guild_broadcast_policies(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.GuildBroadcastJSON()))
	return tag.RowsAffected(), e
}

func (Store) InsertGuildInvite(c context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	if t == nil {
		return 0, errors.New("content store: nil transaction")
	}
	tag, e := t.Exec(c, `INSERT INTO content_guild_invite_policies(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.GuildInviteJSON()))
	if e != nil {
		return 0, e
	}
	if tag == nil {
		return 0, errors.New("content store: missing insert count")
	}
	return tag.RowsAffected(), nil
}
