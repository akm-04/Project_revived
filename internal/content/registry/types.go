package registry

import (
	"bytes"
	"context"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"sort"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	ActivationSlot = "content"
	BootstrapActor = "builtin-bootstrap"
)

var supportedCapabilities = [...]string{
	"DORM_INPUTS_I7C2C",
	"LIBRARY_INPUTS_I7C2B",
	"PLAYER_DISPLAY_I7B6A",
	"PUBLIC_PROFILE_SHOWCASE_SELECTION_I7B3A",
	"PUBLIC_PROFILE_PREFERENCES_I7B2B",
	"GUILD_BROADCAST_I7A8A",
	"GUILD_INVITE_PRESENTATION_I7A8B",
	"QUALIFIED_ORDINARY_STACK_ITEM_DEFINITIONS",
	"SCALAR_CRYSTAL",
	"SCALAR_MANA",
	"PLAYER_EXP_R5",
	"TEMPORAL_ENERGY_R5",
	"TEMPORAL_SPIRIT_ENERGY_R5",
	"TEMPORAL_SKILL_POINT_R5",
	"FUNCTION_LEVEL_ELIGIBILITY_R5",
	"HERO_CORE_CA2", "HERO_RAW_SKILLS_I7C2A",
	"HERO_PROGRESSION_CA2",
	"PET_CORE_CA3",
	"PET_ACQUISITION_CA3",
	"PET_PROGRESSION_CA3",
	"EQUIPMENT_PRIMITIVES_CA4",
	"HERO_EQUIPMENT_CA4_2",
	"HERO_FUMO_CA4_3A",
	"HERO_PROMOTION_RESTORATION_CA4_3B",
	"PET_EQUIPMENT_CA4_4A",
	"PET_PROMOTION_RESTORATION_CA4_4B",
	"SUPER_EQUIPMENT_CA4_5",
	"PRACTICE_CA6",
	"CHARACTER_APPEARANCE_CA7",
	"FRIEND_DM_EMOTICON_I7A6A",
	"SOCIAL_GIFT_I7A7A",
}

type Bundle struct {
	dormInputsJSON                            []byte
	libraryInputsJSON                         []byte
	playerDisplayJSON                         []byte
	publicShowcaseJSON                        []byte
	publicProfileJSON                         []byte
	guildInviteJSON                           []byte
	guildBroadcastJSON                        []byte
	socialGiftJSON                            []byte
	emoticonsJSON                             []byte
	manifest                                  builtin.Manifest
	manifestJSON                              []byte
	resourcesJSON                             []byte
	progressionJSON                           []byte
	functionGatesJSON                         []byte
	objectivesJSON                            []byte
	heroCoreJSON                              []byte
	petCoreJSON                               []byte
	petAcquisitionJSON                        []byte
	petProgressionJSON                        []byte
	equipmentPrimitivesJSON                   []byte
	heroEquipmentJSON                         []byte
	superEquipmentJSON                        []byte
	heroFumoJSON                              []byte
	heroPromotionRestorationJSON              []byte
	petEquipmentJSON                          []byte
	petPromotionRestorationJSON               []byte
	practiceJSON                              []byte
	appearanceJSON                            []byte
	resourceCount                             int64
	progressionCount                          int64
	functionGateCount                         int64
	objectiveCount                            int64
	heroCount                                 int64
	petCount                                  int64
	petAcquisitionCount                       int64
	petProgressionCount                       int64
	equipmentPrimitiveCount                   int64
	heroEquipmentCount                        int64
	superEquipmentCount                       int64
	heroFumoTargetCount                       int64
	heroFumoMaterialCount                     int64
	heroPromotionRestorationEquipmentCount    int64
	heroPromotionRestorationFractionCount     int64
	heroPromotionRestorationDenominationCount int64
	petEquipmentCount                         int64
	petPromotionRestorationEquipmentCount     int64
	practiceCount                             int64
	appearanceCount                           int64
}

func LoadBuiltinBundle() (Bundle, error) {
	cat, err := builtin.Load()
	if err != nil {
		return Bundle{}, err
	}
	manifest, err := builtin.GeneratedFile("manifest.json")
	if err != nil {
		return Bundle{}, err
	}
	resources, err := builtin.GeneratedFile("resource_catalog.json")
	if err != nil {
		return Bundle{}, err
	}
	progression, err := builtin.GeneratedFile("player_progression.json")
	if err != nil {
		return Bundle{}, err
	}
	functions, err := builtin.GeneratedFile("function_gates.json")
	if err != nil {
		return Bundle{}, err
	}
	objectives, err := builtin.GeneratedFile("objective_catalog.json")
	if err != nil {
		return Bundle{}, err
	}
	heroCore, err := builtin.GeneratedFile("hero_core_catalog.json")
	if err != nil {
		return Bundle{}, err
	}
	petCore, err := builtin.GeneratedFile("pet_core_catalog.json")
	if err != nil {
		return Bundle{}, err
	}
	petAcquisition, err := builtin.GeneratedFile("pet_acquisition_catalog.json")
	if err != nil {
		return Bundle{}, err
	}
	petProgression, err := builtin.GeneratedFile("pet_progression_catalog.json")
	if err != nil {
		return Bundle{}, err
	}
	equipmentPrimitives, err := builtin.GeneratedFile("equipment_primitives_catalog.json")
	if err != nil {
		return Bundle{}, err
	}
	heroEquipment, err := builtin.GeneratedFile("hero_equipment_catalog.json")
	if err != nil {
		return Bundle{}, err
	}
	superEquipment, err := builtin.GeneratedFile("super_equipment_catalog.json")
	if err != nil {
		return Bundle{}, err
	}
	heroFumo, err := builtin.GeneratedFile("hero_fumo_catalog.json")
	if err != nil {
		return Bundle{}, err
	}
	heroPromotionRestoration, err := builtin.GeneratedFile("hero_promotion_restoration_catalog.json")
	if err != nil {
		return Bundle{}, err
	}
	petEquipment, err := builtin.GeneratedFile("pet_equipment_catalog.json")
	if err != nil {
		return Bundle{}, err
	}
	petPromotionRestoration, err := builtin.GeneratedFile("pet_promotion_restoration_catalog.json")
	if err != nil {
		return Bundle{}, err
	}
	practice, err := builtin.GeneratedFile("practice_catalog.json")
	if err != nil {
		return Bundle{}, err
	}
	appearance, err := builtin.GeneratedFile("appearance_catalog.json")
	if err != nil {
		return Bundle{}, err
	}
	emoticons, err := builtin.GeneratedFile("emoticon_catalog.json")
	if err != nil {
		return Bundle{}, err
	}
	broadcast, err := builtin.GeneratedFile("guild_broadcast_policy.json")
	if err != nil {
		return Bundle{}, err
	}
	socialGift, err := builtin.GeneratedFile("social_gift_catalog.json")
	if err != nil {
		return Bundle{}, err
	}
	invite, err := builtin.GeneratedFile("guild_invite_policy.json")
	if err != nil {
		return Bundle{}, err
	}
	publicShowcase, err := builtin.GeneratedFile("public_showcase_policy.json")
	if err != nil {
		return Bundle{}, err
	}
	var showcase builtin.PublicShowcasePolicy
	decoder := json.NewDecoder(bytes.NewReader(publicShowcase))
	decoder.DisallowUnknownFields()
	if err = decoder.Decode(&showcase); err != nil {
		return Bundle{}, err
	}
	if err = showcase.Validate(); err != nil {
		return Bundle{}, err
	}
	publicProfile, err := builtin.GeneratedFile("public_profile_policy.json")
	if err != nil {
		return Bundle{}, err
	}
	display, err := builtin.GeneratedFile("player_display_catalog.json")
	if err != nil {
		return Bundle{}, err
	}
	dormInputs, err := builtin.GeneratedFile("dorm_input_catalog.json")
	if err != nil {
		return Bundle{}, err
	}
	libraryInputs, err := builtin.GeneratedFile("library_input_catalog.json")
	if err != nil {
		return Bundle{}, err
	}
	b := Bundle{
		dormInputsJSON:                         append([]byte(nil), dormInputs...),
		libraryInputsJSON:                      append([]byte(nil), libraryInputs...),
		playerDisplayJSON:                      append([]byte(nil), display...),
		publicShowcaseJSON:                     append([]byte(nil), publicShowcase...),
		publicProfileJSON:                      append([]byte(nil), publicProfile...),
		guildInviteJSON:                        append([]byte(nil), invite...),
		guildBroadcastJSON:                     append([]byte(nil), broadcast...),
		socialGiftJSON:                         append([]byte(nil), socialGift...),
		emoticonsJSON:                          append([]byte(nil), emoticons...),
		manifest:                               cat.Manifest,
		manifestJSON:                           append([]byte(nil), manifest...),
		resourcesJSON:                          append([]byte(nil), resources...),
		progressionJSON:                        append([]byte(nil), progression...),
		functionGatesJSON:                      append([]byte(nil), functions...),
		objectivesJSON:                         append([]byte(nil), objectives...),
		heroCoreJSON:                           append([]byte(nil), heroCore...),
		petCoreJSON:                            append([]byte(nil), petCore...),
		petAcquisitionJSON:                     append([]byte(nil), petAcquisition...),
		petProgressionJSON:                     append([]byte(nil), petProgression...),
		equipmentPrimitivesJSON:                append([]byte(nil), equipmentPrimitives...),
		heroEquipmentJSON:                      append([]byte(nil), heroEquipment...),
		superEquipmentJSON:                     append([]byte(nil), superEquipment...),
		heroFumoJSON:                           append([]byte(nil), heroFumo...),
		heroPromotionRestorationJSON:           append([]byte(nil), heroPromotionRestoration...),
		petEquipmentJSON:                       append([]byte(nil), petEquipment...),
		petPromotionRestorationJSON:            append([]byte(nil), petPromotionRestoration...),
		practiceJSON:                           append([]byte(nil), practice...),
		appearanceJSON:                         append([]byte(nil), appearance...),
		resourceCount:                          int64(len(cat.Resources.Resources)),
		progressionCount:                       int64(len(cat.PlayerProgression.Rows)),
		functionGateCount:                      int64(len(cat.FunctionGates.Gates)),
		objectiveCount:                         int64(len(cat.Objectives.Definitions)),
		heroCount:                              int64(len(cat.HeroCore.Templates)),
		petCount:                               int64(len(cat.PetCore.Templates)),
		petAcquisitionCount:                    int64(len(cat.PetAcquisition.Templates)),
		petProgressionCount:                    int64(len(cat.PetProgression.Templates)),
		equipmentPrimitiveCount:                int64(len(cat.EquipmentPrimitives.Items)),
		heroEquipmentCount:                     int64(len(cat.HeroEquipment.Positions)),
		superEquipmentCount:                    int64(len(cat.SuperEquipment.Positions)),
		heroFumoTargetCount:                    int64(len(cat.HeroFumo.Targets)),
		heroFumoMaterialCount:                  int64(len(cat.HeroFumo.Materials)),
		heroPromotionRestorationEquipmentCount: int64(len(cat.HeroPromotionRestoration.EligibleEquipment)),
		heroPromotionRestorationFractionCount:  int64(len(cat.HeroPromotionRestoration.QualityFractions)),
		heroPromotionRestorationDenominationCount: int64(len(cat.HeroPromotionRestoration.Denominations)),
		petEquipmentCount:                         int64(len(cat.PetEquipment.Positions)),
		petPromotionRestorationEquipmentCount:     int64(len(cat.PetPromotionRestoration.EligibleEquipment)),
		practiceCount:                             int64(len(cat.Practice.Methods) + len(cat.Practice.Locks) + len(cat.Practice.VIPBless) + len(cat.Practice.HeroThresholds) + len(cat.Practice.PetThresholds) + 1),
		appearanceCount:                           int64(len(cat.Appearance.QualifiedSkinDefinitions) + len(cat.Appearance.QualifiedSkinAcquisitionItems) + len(cat.Appearance.PaidLIVEDefinitions) + len(cat.Appearance.PetHomeStyleDefinitions)),
	}
	if err := b.Validate(); err != nil {
		return Bundle{}, err
	}
	return b, nil
}

func (b Bundle) Validate() error {
	if len(b.manifest.RevisionID) != 64 || strings.ToLower(b.manifest.RevisionID) != b.manifest.RevisionID {
		return errors.New("content registry: invalid bundle revision id")
	}
	if raw, err := hex.DecodeString(b.manifest.RevisionID); err != nil || len(raw) != 32 {
		return errors.New("content registry: bundle revision id is not SHA-256 hex")
	}
	if b.manifest.SchemaVersion != builtin.SchemaVersion {
		return fmt.Errorf("content registry: unsupported bundle schema %d", b.manifest.SchemaVersion)
	}
	for name, raw := range map[string][]byte{"dorm-inputs": b.dormInputsJSON, "library-inputs": b.libraryInputsJSON, "manifest": b.manifestJSON, "resources": b.resourcesJSON, "progression": b.progressionJSON, "functions": b.functionGatesJSON, "objectives": b.objectivesJSON, "hero-core": b.heroCoreJSON, "pet-core": b.petCoreJSON, "pet-acquisition": b.petAcquisitionJSON, "pet-progression": b.petProgressionJSON, "equipment-primitives": b.equipmentPrimitivesJSON, "hero-equipment": b.heroEquipmentJSON, "super-equipment": b.superEquipmentJSON, "hero-fumo": b.heroFumoJSON, "hero-promotion-restoration": b.heroPromotionRestorationJSON, "pet-equipment": b.petEquipmentJSON, "pet-promotion-restoration": b.petPromotionRestorationJSON, "practice": b.practiceJSON, "appearance": b.appearanceJSON, "emoticons": b.emoticonsJSON, "social-gift": b.socialGiftJSON, "guild-invite": b.guildInviteJSON, "guild-broadcast": b.guildBroadcastJSON} {
		if len(raw) == 0 || !json.Valid(raw) {
			return fmt.Errorf("content registry: invalid %s JSON", name)
		}
	}
	if b.resourceCount < 0 || b.progressionCount < 0 || b.functionGateCount < 0 || b.objectiveCount < 0 || b.heroCount < 0 || b.petCount < 0 || b.petAcquisitionCount < 0 || b.petProgressionCount < 0 || b.equipmentPrimitiveCount < 0 || b.heroEquipmentCount < 0 || b.superEquipmentCount < 0 || b.heroFumoTargetCount < 0 || b.heroFumoMaterialCount < 0 || b.heroPromotionRestorationEquipmentCount < 0 || b.heroPromotionRestorationFractionCount < 0 || b.heroPromotionRestorationDenominationCount < 0 || b.petEquipmentCount < 0 || b.petPromotionRestorationEquipmentCount < 0 || b.practiceCount < 0 || b.appearanceCount < 0 {
		return errors.New("content registry: invalid negative catalog count")
	}
	return nil
}

func (b Bundle) GuildInviteJSON() []byte    { return append([]byte(nil), b.guildInviteJSON...) }
func (b Bundle) DormInputsJSON() []byte     { return append([]byte(nil), b.dormInputsJSON...) }
func (b Bundle) LibraryInputsJSON() []byte  { return append([]byte(nil), b.libraryInputsJSON...) }
func (b Bundle) PlayerDisplayJSON() []byte  { return append([]byte(nil), b.playerDisplayJSON...) }
func (b Bundle) PublicShowcaseJSON() []byte { return append([]byte(nil), b.publicShowcaseJSON...) }
func (b Bundle) PublicProfileJSON() []byte  { return append([]byte(nil), b.publicProfileJSON...) }
func (b Bundle) GuildBroadcastJSON() []byte { return append([]byte(nil), b.guildBroadcastJSON...) }
func (b Bundle) SocialGiftJSON() []byte     { return append([]byte(nil), b.socialGiftJSON...) }
func (b Bundle) EmoticonsJSON() []byte      { return append([]byte(nil), b.emoticonsJSON...) }
func (b Bundle) RevisionID() string         { return b.manifest.RevisionID }
func (b Bundle) SchemaVersion() int         { return b.manifest.SchemaVersion }
func (b Bundle) CompilerVersion() string    { return b.manifest.CompilerVersion }
func (b Bundle) ParserVersion() string      { return b.manifest.ParserVersion }
func (b Bundle) ManifestJSON() []byte       { return append([]byte(nil), b.manifestJSON...) }
func (b Bundle) ResourcesJSON() []byte      { return append([]byte(nil), b.resourcesJSON...) }
func (b Bundle) ProgressionJSON() []byte    { return append([]byte(nil), b.progressionJSON...) }
func (b Bundle) FunctionGatesJSON() []byte  { return append([]byte(nil), b.functionGatesJSON...) }
func (b Bundle) ObjectivesJSON() []byte     { return append([]byte(nil), b.objectivesJSON...) }
func (b Bundle) HeroCoreJSON() []byte       { return append([]byte(nil), b.heroCoreJSON...) }
func (b Bundle) PetCoreJSON() []byte        { return append([]byte(nil), b.petCoreJSON...) }
func (b Bundle) PetAcquisitionJSON() []byte { return append([]byte(nil), b.petAcquisitionJSON...) }
func (b Bundle) PetProgressionJSON() []byte { return append([]byte(nil), b.petProgressionJSON...) }
func (b Bundle) EquipmentPrimitivesJSON() []byte {
	return append([]byte(nil), b.equipmentPrimitivesJSON...)
}
func (b Bundle) HeroEquipmentJSON() []byte  { return append([]byte(nil), b.heroEquipmentJSON...) }
func (b Bundle) SuperEquipmentJSON() []byte { return append([]byte(nil), b.superEquipmentJSON...) }
func (b Bundle) HeroFumoJSON() []byte       { return append([]byte(nil), b.heroFumoJSON...) }
func (b Bundle) HeroPromotionRestorationJSON() []byte {
	return append([]byte(nil), b.heroPromotionRestorationJSON...)
}
func (b Bundle) PetEquipmentJSON() []byte { return append([]byte(nil), b.petEquipmentJSON...) }
func (b Bundle) PetPromotionRestorationJSON() []byte {
	return append([]byte(nil), b.petPromotionRestorationJSON...)
}
func (b Bundle) PracticeJSON() []byte   { return append([]byte(nil), b.practiceJSON...) }
func (b Bundle) AppearanceJSON() []byte { return append([]byte(nil), b.appearanceJSON...) }
func (b Bundle) ExpectedCounts() (resources, progression, functions, objectives, heroes, pets, petAcquisition, petProgression, equipmentPrimitives, heroEquipment, superEquipment, heroFumoTargets, heroFumoMaterials, heroPromotionRestorationEquipment, heroPromotionRestorationFractions, heroPromotionRestorationDenominations, petEquipment, petPromotionRestorationEquipment, practice, appearance int64) {
	return b.resourceCount, b.progressionCount, b.functionGateCount, b.objectiveCount, b.heroCount, b.petCount, b.petAcquisitionCount, b.petProgressionCount, b.equipmentPrimitiveCount, b.heroEquipmentCount, b.superEquipmentCount, b.heroFumoTargetCount, b.heroFumoMaterialCount, b.heroPromotionRestorationEquipmentCount, b.heroPromotionRestorationFractionCount, b.heroPromotionRestorationDenominationCount, b.petEquipmentCount, b.petPromotionRestorationEquipmentCount, b.practiceCount, b.appearanceCount
}

type ProviderSet struct{ names map[string]struct{} }

func NewProviderSet(names ...string) (ProviderSet, error) {
	m := make(map[string]struct{}, len(names))
	for _, raw := range names {
		n := strings.TrimSpace(raw)
		if n == "" || n != raw {
			return ProviderSet{}, errors.New("content registry: blank capability")
		}
		if _, ok := m[n]; ok {
			return ProviderSet{}, fmt.Errorf("content registry: duplicate capability %q", n)
		}
		m[n] = struct{}{}
	}
	return ProviderSet{names: m}, nil
}

func DefaultProviderSet() ProviderSet {
	p, err := NewProviderSet(supportedCapabilities[:]...)
	if err != nil {
		panic(err)
	}
	return p
}

func (p ProviderSet) SupportsAll(names []string) error {
	seen := make(map[string]struct{}, len(names))
	for _, raw := range names {
		n := strings.TrimSpace(raw)
		if n == "" || n != raw {
			return errors.New("content registry: active manifest contains blank capability")
		}
		if _, ok := seen[n]; ok {
			return fmt.Errorf("content registry: active manifest duplicate capability %q", n)
		}
		seen[n] = struct{}{}
		if _, ok := p.names[n]; !ok {
			return fmt.Errorf("content registry: unsupported capability %q", n)
		}
	}
	return nil
}

func (p ProviderSet) Names() []string {
	out := make([]string, 0, len(p.names))
	for n := range p.names {
		out = append(out, n)
	}
	sort.Strings(out)
	return out
}

type ActivationIdentity struct {
	RevisionID  string
	Version     int64
	ActivatedAt time.Time
	ActivatedBy string
}

func (a ActivationIdentity) Validate() error {
	if a.RevisionID == "" || a.Version <= 0 {
		return errors.New("content registry: invalid activation identity")
	}
	return nil
}

type ActiveSummary struct {
	Activation    ActivationIdentity
	SchemaVersion int
	ManifestJSON  []byte
}

type Verification struct {
	DormInputsCount                           int64
	LibraryInputsCount                        int64
	PlayerDisplayCount                        int64
	PublicShowcaseCount                       int64
	PublicProfileCount                        int64
	GuildInviteCount                          int64
	GuildBroadcastCount                       int64
	EmoticonCount                             int64
	Exact                                     bool
	ResourceCount                             int64
	ProgressionCount                          int64
	FunctionGateCount                         int64
	ObjectiveCount                            int64
	HeroCount                                 int64
	PetCount                                  int64
	PetAcquisitionCount                       int64
	PetProgressionCount                       int64
	EquipmentPrimitiveCount                   int64
	HeroEquipmentCount                        int64
	SuperEquipmentCount                       int64
	HeroFumoTargetCount                       int64
	HeroFumoMaterialCount                     int64
	HeroPromotionRestorationEquipmentCount    int64
	HeroPromotionRestorationFractionCount     int64
	HeroPromotionRestorationDenominationCount int64
	PetEquipmentCount                         int64
	PetPromotionRestorationEquipmentCount     int64
	PracticeCount                             int64
	AppearanceCount                           int64
}

func (v Verification) Matches(b Bundle) bool {
	r, p, f, o, h, pet, petAcquisition, petProgression, equipmentPrimitives, heroEquipment, superEquipment, heroFumoTargets, heroFumoMaterials, restorationEquipment, restorationFractions, restorationDenominations, petEquipment, petRestorationEquipment, practice, appearance := b.ExpectedCounts()
	return v.DormInputsCount == 1 && v.LibraryInputsCount == 1 && v.PlayerDisplayCount == 1 && v.PublicShowcaseCount == 1 && v.PublicProfileCount == 1 && v.GuildInviteCount == 1 && v.GuildBroadcastCount == 1 && v.Exact && v.EmoticonCount == 85 && v.ResourceCount == r && v.ProgressionCount == p && v.FunctionGateCount == f && v.ObjectiveCount == o && v.HeroCount == h && v.PetCount == pet && v.PetAcquisitionCount == petAcquisition && v.PetProgressionCount == petProgression && v.EquipmentPrimitiveCount == equipmentPrimitives && v.HeroEquipmentCount == heroEquipment && v.SuperEquipmentCount == superEquipment && v.HeroFumoTargetCount == heroFumoTargets && v.HeroFumoMaterialCount == heroFumoMaterials && v.HeroPromotionRestorationEquipmentCount == restorationEquipment && v.HeroPromotionRestorationFractionCount == restorationFractions && v.HeroPromotionRestorationDenominationCount == restorationDenominations && v.PetEquipmentCount == petEquipment && v.PetPromotionRestorationEquipmentCount == petRestorationEquipment && v.PracticeCount == practice && v.AppearanceCount == appearance
}

// Repository is the canonical content-registry persistence port. It receives
// caller-owned transactions/queryers and never starts/commits transactions.
type Repository interface {
	LockRegistry(context.Context, tx.Tx) error
	TryInsertRevision(context.Context, tx.Tx, Bundle) (bool, error)
	InsertResources(context.Context, tx.Tx, Bundle) (int64, error)
	InsertProgression(context.Context, tx.Tx, Bundle) (int64, error)
	InsertFunctionGates(context.Context, tx.Tx, Bundle) (int64, error)
	InsertObjectives(context.Context, tx.Tx, Bundle) (int64, error)
	InsertHeroCore(context.Context, tx.Tx, Bundle) (int64, error)
	InsertPetCore(context.Context, tx.Tx, Bundle) (int64, error)
	InsertPetAcquisition(context.Context, tx.Tx, Bundle) (int64, error)
	InsertPetProgression(context.Context, tx.Tx, Bundle) (int64, error)
	InsertEquipmentPrimitives(context.Context, tx.Tx, Bundle) (int64, error)
	InsertHeroEquipment(context.Context, tx.Tx, Bundle) (int64, error)
	InsertSuperEquipment(context.Context, tx.Tx, Bundle) (int64, error)
	InsertHeroFumo(context.Context, tx.Tx, Bundle) (targets int64, materials int64, err error)
	InsertHeroPromotionRestoration(context.Context, tx.Tx, Bundle) (equipment int64, fractions int64, denominations int64, err error)
	InsertPetEquipment(context.Context, tx.Tx, Bundle) (int64, error)
	InsertPetPromotionRestoration(context.Context, tx.Tx, Bundle) (int64, error)
	InsertPractice(context.Context, tx.Tx, Bundle) (int64, error)
	InsertAppearance(context.Context, tx.Tx, Bundle) (int64, error)
	InsertDormInputs(context.Context, tx.Tx, Bundle) (int64, error)
	InsertLibraryInputs(context.Context, tx.Tx, Bundle) (int64, error)
	InsertPlayerDisplay(context.Context, tx.Tx, Bundle) (int64, error)
	InsertPublicShowcase(context.Context, tx.Tx, Bundle) (int64, error)
	InsertPublicProfile(context.Context, tx.Tx, Bundle) (int64, error)
	InsertGuildBroadcast(context.Context, tx.Tx, Bundle) (int64, error)
	InsertGuildInvite(context.Context, tx.Tx, Bundle) (int64, error)
	InsertSocialGift(context.Context, tx.Tx, Bundle) (int64, error)
	InsertEmoticons(context.Context, tx.Tx, Bundle) (int64, error)
	VerifyRevision(context.Context, tx.Queryer, Bundle) (Verification, error)
	ReadActivation(context.Context, tx.Queryer) (ActivationIdentity, bool, error)
	ReadActiveSummary(context.Context, tx.Queryer) (ActiveSummary, bool, error)
	BootstrapActivation(context.Context, tx.Tx, string, time.Time, string) (bool, error)
	ActivateCAS(context.Context, tx.Tx, string, time.Time, string, ActivationIdentity) (bool, error)
}

// DecodeManifestStrict decodes the durable manifest for readiness checks.
func DecodeManifestStrict(raw []byte) (builtin.Manifest, error) {
	var m builtin.Manifest
	dec := json.NewDecoder(bytes.NewReader(raw))
	dec.DisallowUnknownFields()
	if err := dec.Decode(&m); err != nil {
		return m, fmt.Errorf("content registry: decode active manifest: %w", err)
	}
	if err := requireEOF(dec); err != nil {
		return m, err
	}
	if len(m.RevisionID) != 64 || m.SchemaVersion <= 0 || m.EnabledCapabilities == nil {
		return m, errors.New("content registry: active manifest missing revision/schema")
	}
	if _, err := hex.DecodeString(m.RevisionID); err != nil || strings.ToLower(m.RevisionID) != m.RevisionID {
		return m, errors.New("content registry: active revision must be SHA256 hex")
	}
	return m, nil
}
func requireEOF(dec *json.Decoder) error {
	var x any
	err := dec.Decode(&x)
	if err == io.EOF {
		return nil
	}
	if err != nil {
		return fmt.Errorf("content registry: trailing manifest JSON: %w", err)
	}
	return errors.New("content registry: trailing manifest JSON")
}
