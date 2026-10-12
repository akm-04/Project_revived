package builtin

import (
	"crypto/sha256"
	"embed"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/domain/player"
	"reflect"
	"sort"
	"strings"
)

const (
	SchemaVersion               = 1
	ExpectedSourceArchiveSHA256 = "c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf"
	PolicyRefName               = "content"
)

//go:embed generated/*.json
var generatedFS embed.FS

type Source struct {
	Path   string `json:"path"`
	Role   string `json:"role"`
	SHA256 string `json:"sha256"`
}

type Manifest struct {
	ArtifactSHA256s     map[string]string   `json:"artifact_sha256s"`
	CompilerVersion     string              `json:"compiler_version"`
	Dependencies        map[string][]string `json:"dependencies"`
	Diagnostics         map[string]int      `json:"diagnostics"`
	EnabledCapabilities []string            `json:"enabled_capabilities"`
	ParserVersion       string              `json:"parser_version"`
	RevisionDigestScope string              `json:"revision_digest_scope"`
	RevisionID          string              `json:"revision_id"`
	SchemaVersion       int                 `json:"schema_version"`
	SourceArchiveSHA256 string              `json:"source_archive_sha256"`
	Sources             []Source            `json:"sources"`
}

type ResourceDefinition struct {
	CapRule              string `json:"cap_rule,omitempty"`
	CatalogStatus        string `json:"catalog_status"`
	Class                string `json:"class"`
	DefinitionKey        string `json:"definition_key"`
	ItemID               int64  `json:"item_id,omitempty"`
	ItemType             int64  `json:"item_type,omitempty"`
	OverflowToMail       bool   `json:"overflow_to_mail,omitempty"`
	PartnerID            int64  `json:"partner_id,omitempty"`
	Reason               string `json:"reason,omitempty"`
	RegenAmount          int64  `json:"regen_amount,omitempty"`
	RegenSeconds         int64  `json:"regen_seconds,omitempty"`
	ResourceKey          string `json:"resource_key,omitempty"`
	SettlementActivation string `json:"settlement_activation"`
	SourceAssetID        *int64 `json:"source_asset_id,omitempty"`
	SpecializedOwner     string `json:"specialized_owner,omitempty"`
	StackCap             int64  `json:"stack_cap,omitempty"`
	StaticCap            int64  `json:"static_cap,omitempty"`
}

type ResourceCatalog struct {
	Resources     []ResourceDefinition `json:"resources"`
	SchemaVersion int                  `json:"schema_version"`
}

type PlayerProgressionRow struct {
	AwardEnergy    int64 `json:"award_energy"`
	Energy         int64 `json:"energy"`
	Exp            int64 `json:"exp"`
	ExpeditionMana int64 `json:"expedition_mana"`
	HeroLev        int64 `json:"hero_lev"`
	Lev            int64 `json:"lev"`
	Power          int64 `json:"power"`
	TotalExp       int64 `json:"total_exp"`
}

type PlayerProgressionCatalog struct {
	Rows          []PlayerProgressionRow `json:"rows"`
	SchemaVersion int                    `json:"schema_version"`
	Source        string                 `json:"source"`
}

type FunctionGate struct {
	AnnouncementCapability string `json:"announcement_capability"`
	FunctionID             int64  `json:"function_id"`
	GateKind               string `json:"gate_kind"`
	RawOpenValue           string `json:"raw_open_value"`
	RequiredLevel          *int64 `json:"required_level"`
	SourceFactKey          string `json:"source_fact_key"`
}

type FunctionGateCatalog struct {
	Gates         []FunctionGate `json:"gates"`
	SchemaVersion int            `json:"schema_version"`
	Source        string         `json:"source"`
}

type ObjectiveDefinition struct{}

type ObjectiveCatalog struct {
	Definitions   []ObjectiveDefinition `json:"definitions"`
	SchemaVersion int                   `json:"schema_version"`
	Status        string                `json:"status"`
}

type HeroTemplate struct {
	AwakenTableID int64  `json:"awaken_table_id"`
	FirstTableID  int64  `json:"first_table_id"`
	HeroKind      string `json:"hero_kind"`
	InitialStar   int64  `json:"initial_star"`
	OriginTableID int64  `json:"origin_table_id"`
	StoneItemID   int64  `json:"stone_item_id"`
	TableID       int64  `json:"table_id"`
}
type HeroExpRow struct {
	Level    int64 `json:"level"`
	ExpDelta int64 `json:"exp_delta"`
	TotalExp int64 `json:"total_exp"`
}
type HeroExpItem struct {
	ItemID   int64 `json:"item_id"`
	ExpValue int64 `json:"exp_value"`
}
type HeroNormalStarRow struct {
	Star       int64 `json:"star"`
	EvolveNum  int64 `json:"evolve_num"`
	EvolveMana int64 `json:"evolve_mana"`
	SummonNum  int64 `json:"summon_num"`
	SummonMana int64 `json:"summon_mana"`
}
type HeroSuperStarRow struct {
	Star                     int64 `json:"star"`
	ManaCost                 int64 `json:"mana_cost"`
	StoneCost                int64 `json:"stone_cost"`
	NeedHeroNum              int64 `json:"need_hero_num"`
	EffectiveClientReachable bool  `json:"effective_client_reachable"`
}
type HeroPrerequisite struct {
	SuperTableID  int64 `json:"super_table_id"`
	Ordinal       int64 `json:"ordinal"`
	OriginTableID int64 `json:"origin_table_id"`
}
type HeroAcquisitionItem struct {
	ItemID        int64 `json:"item_id"`
	OriginTableID int64 `json:"origin_table_id"`
}
type HeroCoreCatalog struct {
	AcquisitionItems   []HeroAcquisitionItem `json:"acquisition_items"`
	ExpItems           []HeroExpItem         `json:"exp_items"`
	ExpRows            []HeroExpRow          `json:"exp_rows"`
	NormalStarRows     []HeroNormalStarRow   `json:"normal_star_rows"`
	SchemaVersion      int                   `json:"schema_version"`
	Source             string                `json:"source"`
	SuperPrerequisites []HeroPrerequisite    `json:"super_prerequisites"`
	SuperStarRows      []HeroSuperStarRow    `json:"super_star_rows"`
	Templates          []HeroTemplate        `json:"templates"`
}

type PetTemplate struct {
	TableID       int64 `json:"table_id"`
	OriginTableID int64 `json:"origin_table_id"`
	IsAwakened    bool  `json:"is_awakened"`
	AwakenTableID int64 `json:"awaken_table_id"`
	InitialStar   int64 `json:"initial_star"`
}

type PetCoreCatalog struct {
	SchemaVersion int           `json:"schema_version"`
	Source        string        `json:"source"`
	Templates     []PetTemplate `json:"templates"`
}

type PetAcquisitionTemplate struct {
	EggItemID     int64 `json:"egg_item_id"`
	EssenceItemID int64 `json:"essence_item_id"`
	FragmentCount int64 `json:"fragment_count"`
	HatchSeconds  int64 `json:"hatch_seconds"`
	InitialStar   int64 `json:"initial_star"`
	OriginTableID int64 `json:"origin_table_id"`
	SummonType    int64 `json:"summon_type"`
	TableID       int64 `json:"table_id"`
}

type PetAcquisitionPolicy struct {
	FragmentCostsByInitialStar map[string]int64 `json:"fragment_costs_by_initial_star"`
	HatchCostParam             int64            `json:"hatch_cost_param"`
	StarterEggItemID           int64            `json:"starter_egg_item_id"`
}

type PetAcquisitionCatalog struct {
	Policy        PetAcquisitionPolicy     `json:"policy"`
	SchemaVersion int                      `json:"schema_version"`
	Source        string                   `json:"source"`
	Templates     []PetAcquisitionTemplate `json:"templates"`
}

type PetProgressionTemplate struct {
	StoneItemID int64 `json:"stone_item_id"`
	TableID     int64 `json:"table_id"`
}
type PetSkillSlot struct {
	Slot          int64 `json:"slot"`
	SourceSkillID int64 `json:"source_skill_id"`
	StarBonus     int64 `json:"star_bonus"`
	TableID       int64 `json:"table_id"`
}
type PetExpRow struct {
	ExpDelta int64 `json:"exp_delta"`
	Level    int64 `json:"level"`
	TotalExp int64 `json:"total_exp"`
}
type PetExpItem struct {
	ExpValue int64 `json:"exp_value"`
	ItemID   int64 `json:"item_id"`
}
type PetSkillBookRow struct {
	BookCount      int64 `json:"book_count"`
	EffectiveLevel int64 `json:"effective_level"`
}
type PetSkillSlotPolicy struct {
	EffectiveOffset  int64 `json:"effective_offset"`
	MinColor         int64 `json:"min_color"`
	RequiresAwakened bool  `json:"requires_awakened"`
	Slot             int64 `json:"slot"`
}
type PetEvolutionRow struct {
	StoneCount int64 `json:"stone_count"`
	TargetStar int64 `json:"target_star"`
}
type PetProgressionPolicy struct {
	SkillBookItemID int64 `json:"skill_book_item_id"`
}
type PetProgressionCatalog struct {
	EvolutionRows []PetEvolutionRow        `json:"evolution_rows"`
	ExpItems      []PetExpItem             `json:"exp_items"`
	ExpRows       []PetExpRow              `json:"exp_rows"`
	Policy        PetProgressionPolicy     `json:"policy"`
	SchemaVersion int                      `json:"schema_version"`
	SkillBooks    []PetSkillBookRow        `json:"skill_books"`
	SkillSlots    []PetSkillSlot           `json:"skill_slots"`
	SlotPolicy    []PetSkillSlotPolicy     `json:"slot_policy"`
	Source        string                   `json:"source"`
	Templates     []PetProgressionTemplate `json:"templates"`
}

type EquipmentPrimitive struct {
	ComposeMana    int64 `json:"compose_mana"`
	ItemID         int64 `json:"item_id"`
	RequiredLevel  int64 `json:"required_level"`
	SourceItemType int64 `json:"source_item_type"`
}

type EquipmentRecipeEdge struct {
	ComponentCount  int64 `json:"component_count"`
	ComponentItemID int64 `json:"component_item_id"`
	Ordinal         int64 `json:"ordinal"`
	ParentItemID    int64 `json:"parent_item_id"`
}

type EquipmentPrimitivesCatalog struct {
	Items         []EquipmentPrimitive  `json:"items"`
	RecipeEdges   []EquipmentRecipeEdge `json:"recipe_edges"`
	RootItemIDs   []int64               `json:"root_item_ids"`
	SchemaVersion int                   `json:"schema_version"`
	Source        string                `json:"source"`
}

type HeroEquipmentPosition struct {
	Color            int64 `json:"color"`
	HeroTableID      int64 `json:"hero_table_id"`
	ItemID           int64 `json:"item_id"`
	OrdinaryEligible bool  `json:"ordinary_eligible"`
	Slot             int64 `json:"slot"`
}

type HeroEquipmentCatalog struct {
	Positions     []HeroEquipmentPosition `json:"positions"`
	SchemaVersion int                     `json:"schema_version"`
	Source        string                  `json:"source"`
}

type SuperEquipmentPosition struct {
	HeroTableID int64 `json:"hero_table_id"`
	ItemID      int64 `json:"item_id"`
	Slot        int64 `json:"slot"`
}

type SuperEquipmentEnhancementCap struct {
	EffectiveClientReachable bool  `json:"effective_client_reachable"`
	MaxEnhancement           int64 `json:"max_enhancement"`
	Star                     int64 `json:"star"`
}

type SuperEquipmentEnhancementTier struct {
	DuplicateCount           int64 `json:"duplicate_count"`
	EffectiveClientReachable bool  `json:"effective_client_reachable"`
	MinStar                  int64 `json:"min_star"`
	Tier                     int64 `json:"tier"`
}

type SuperEquipmentCatalog struct {
	EnhancementCaps  []SuperEquipmentEnhancementCap  `json:"enhancement_caps"`
	EnhancementTiers []SuperEquipmentEnhancementTier `json:"enhancement_tiers"`
	Positions        []SuperEquipmentPosition        `json:"positions"`
	SchemaVersion    int                             `json:"schema_version"`
	Source           string                          `json:"source"`
}

type PetEquipmentPosition struct {
	Classification string `json:"classification"`
	Color          int64  `json:"color"`
	ItemID         int64  `json:"item_id"`
	PetTableID     int64  `json:"pet_table_id"`
	Slot           int64  `json:"slot"`
}

type PetEquipmentCatalog struct {
	Positions     []PetEquipmentPosition `json:"positions"`
	SchemaVersion int                    `json:"schema_version"`
	Source        string                 `json:"source"`
}

type PetPromotionRestorationEquipment struct {
	EquipmentItemID int64 `json:"equipment_item_id"`
	SourceQuality   int64 `json:"source_quality"`
}

type PetPromotionRestorationCatalog struct {
	EligibleEquipment []PetPromotionRestorationEquipment `json:"eligible_equipment"`
	SchemaVersion     int                                `json:"schema_version"`
	Source            string                             `json:"source"`
}

type HeroFumoTarget struct {
	AttrIDs             []int64             `json:"attr_ids"`
	ItemID              int64               `json:"item_id"`
	ManaPerFumo         int64               `json:"mana_per_fumo"`
	StageDeltaByAttr    []map[string]string `json:"stage_delta_by_attr"`
	ThresholdIncrements []int64             `json:"threshold_increments"`
	TotalCap            int64               `json:"total_cap"`
}
type HeroFumoMaterial struct {
	ItemID   int64 `json:"item_id"`
	ItemType int64 `json:"item_type"`
	Moneng   int64 `json:"moneng"`
}
type HeroFumoCatalog struct {
	Materials     []HeroFumoMaterial `json:"materials"`
	SchemaVersion int                `json:"schema_version"`
	Source        string             `json:"source"`
	Targets       []HeroFumoTarget   `json:"targets"`
}

type HeroPromotionRestorationEquipment struct {
	EquipmentItemID int64 `json:"equipment_item_id"`
	SourceQuality   int64 `json:"source_quality"`
}
type HeroPromotionRestorationFraction struct {
	Denominator int64 `json:"denominator"`
	Numerator   int64 `json:"numerator"`
	Quality     int64 `json:"quality"`
}
type HeroPromotionRestorationDenomination struct {
	ItemID  int64 `json:"item_id"`
	Ordinal int64 `json:"ordinal"`
	Value   int64 `json:"value"`
}
type HeroPromotionRestorationCatalog struct {
	Denominations     []HeroPromotionRestorationDenomination `json:"denominations"`
	EligibleEquipment []HeroPromotionRestorationEquipment    `json:"eligible_equipment"`
	QualityFractions  []HeroPromotionRestorationFraction     `json:"quality_fractions"`
	SchemaVersion     int                                    `json:"schema_version"`
	Source            string                                 `json:"source"`
}

type AppearanceSkinDefinition struct {
	HeroOriginTableID int64 `json:"hero_origin_table_id"`
	ModelID           int64 `json:"model_id"`
	SkinSkillID       int64 `json:"skin_skill_id"`
	SourceSkinID      int64 `json:"source_skin_id"`
}

type AppearanceSkinAcquisitionItem struct {
	DurationSeconds   *int64 `json:"duration_seconds"`
	HeroOriginTableID int64  `json:"hero_origin_table_id"`
	ItemID            int64  `json:"item_id"`
	ModelID           int64  `json:"model_id"`
}

type AppearancePaidLIVEDefinition struct {
	ActivationItemCount int64 `json:"activation_item_count"`
	ActivationItemID    int64 `json:"activation_item_id"`
	CrystalCost         int64 `json:"crystal_cost"`
	HeroOriginTableID   int64 `json:"hero_origin_table_id"`
	ModelID             int64 `json:"model_id"`
}

type AppearancePetHomeStyleDefinition struct {
	PetOriginTableID int64 `json:"pet_origin_table_id"`
	StyleItemID      int64 `json:"style_item_id"`
}

type AppearanceCatalog struct {
	PaidLIVEDefinitions           []AppearancePaidLIVEDefinition     `json:"paid_live_definitions"`
	PetHomeStyleDefinitions       []AppearancePetHomeStyleDefinition `json:"pet_home_style_definitions"`
	QualifiedSkinAcquisitionItems []AppearanceSkinAcquisitionItem    `json:"qualified_skin_acquisition_items"`
	QualifiedSkinDefinitions      []AppearanceSkinDefinition         `json:"qualified_skin_definitions"`
	SchemaVersion                 int                                `json:"schema_version"`
	Source                        string                             `json:"source"`
}

type PracticeMethod struct {
	MethodID     int64 `json:"method_id"`
	CurrencyType int64 `json:"currency_type"`
	BaseCost     int64 `json:"base_cost"`
	VIPMin       int64 `json:"vip_min"`
}

type PracticeLock struct {
	LockCount     int64 `json:"lock_count"`
	ManaStep      int64 `json:"mana_step"`
	CrystalStep   int64 `json:"crystal_step"`
	BlessCost     int64 `json:"bless_cost"`
	SourceUpLimit int64 `json:"source_up_limit"`
}

type PracticeVIPBless struct {
	VIPLevel   int64 `json:"vip_level"`
	BlessValue int64 `json:"bless_value"`
}

type HeroPracticeThreshold struct {
	HeroTableID    int64 `json:"hero_table_id"`
	Ordinal        int64 `json:"ordinal"`
	NeedValue      int64 `json:"need_value"`
	TargetAttrType int64 `json:"target_attr_type"`
	BonusValue     int64 `json:"bonus_value"`
}

type PetPracticeThreshold struct {
	PetTableID     int64 `json:"pet_table_id"`
	Ordinal        int64 `json:"ordinal"`
	NeedValue      int64 `json:"need_value"`
	TargetAttrType int64 `json:"target_attr_type"`
	BonusValue     int64 `json:"bonus_value"`
}

type PracticePolicyFacts struct {
	UnlockLevel         int64 `json:"unlock_level"`
	AttrCap             int64 `json:"attr_cap"`
	FreeIntervalSeconds int64 `json:"free_interval_seconds"`
	LegendaryVIPMin     int64 `json:"legendary_vip_min"`
	TicketItemID        int64 `json:"ticket_item_id"`
	TicketAddStr        int64 `json:"ticket_add_str"`
	TicketAddInt        int64 `json:"ticket_add_int"`
	TicketAddAgi        int64 `json:"ticket_add_agi"`
}

type PracticeCatalog struct {
	HeroThresholds []HeroPracticeThreshold `json:"hero_thresholds"`
	Locks          []PracticeLock          `json:"locks"`
	Methods        []PracticeMethod        `json:"methods"`
	PetThresholds  []PetPracticeThreshold  `json:"pet_thresholds"`
	PolicyFacts    PracticePolicyFacts     `json:"policy_facts"`
	SchemaVersion  int                     `json:"schema_version"`
	Source         string                  `json:"source"`
	VIPBless       []PracticeVIPBless      `json:"vip_bless"`
}

type EmoticonDefinition struct {
	ID     int64 `json:"id"`
	ItemID int64 `json:"item_id"`
}
type EmoticonCatalog struct {
	Definitions   []EmoticonDefinition `json:"definitions"`
	SchemaVersion int                  `json:"schema_version"`
	Source        string               `json:"source"`
}
type Catalog struct {
	PlayerDisplay            player.DisplayCatalog
	PublicShowcase           PublicShowcasePolicy
	PublicProfile            PublicProfilePolicy
	GuildInvite              GuildInvitePolicy
	GuildBroadcast           GuildBroadcastPolicy
	SocialGift               SocialGiftCatalog
	Emoticons                EmoticonCatalog
	Manifest                 Manifest
	Resources                ResourceCatalog
	PlayerProgression        PlayerProgressionCatalog
	FunctionGates            FunctionGateCatalog
	Objectives               ObjectiveCatalog
	HeroCore                 HeroCoreCatalog
	PetCore                  PetCoreCatalog
	PetAcquisition           PetAcquisitionCatalog
	PetProgression           PetProgressionCatalog
	EquipmentPrimitives      EquipmentPrimitivesCatalog
	HeroEquipment            HeroEquipmentCatalog
	SuperEquipment           SuperEquipmentCatalog
	PetEquipment             PetEquipmentCatalog
	PetPromotionRestoration  PetPromotionRestorationCatalog
	HeroFumo                 HeroFumoCatalog
	HeroPromotionRestoration HeroPromotionRestorationCatalog
	Practice                 PracticeCatalog
	Appearance               AppearanceCatalog
}

func GeneratedFile(name string) ([]byte, error) {
	if strings.Contains(name, "/") || strings.Contains(name, "\\") || name == "" {
		return nil, fmt.Errorf("builtin content: invalid generated filename %q", name)
	}
	b, err := generatedFS.ReadFile("generated/" + name)
	if err != nil {
		return nil, fmt.Errorf("builtin content: read %s: %w", name, err)
	}
	return b, nil
}

func Load() (*Catalog, error) {
	manifestBytes, err := GeneratedFile("manifest.json")
	if err != nil {
		return nil, err
	}
	var manifest Manifest
	if err := json.Unmarshal(manifestBytes, &manifest); err != nil {
		return nil, fmt.Errorf("builtin content: decode manifest: %w", err)
	}
	if err := validateManifest(manifestBytes, &manifest); err != nil {
		return nil, err
	}

	var resources ResourceCatalog
	if err := decodeAndVerify("resource_catalog.json", manifest.ArtifactSHA256s, &resources); err != nil {
		return nil, err
	}
	var progression PlayerProgressionCatalog
	if err := decodeAndVerify("player_progression.json", manifest.ArtifactSHA256s, &progression); err != nil {
		return nil, err
	}
	var functions FunctionGateCatalog
	if err := decodeAndVerify("function_gates.json", manifest.ArtifactSHA256s, &functions); err != nil {
		return nil, err
	}
	var objectives ObjectiveCatalog
	if err := decodeAndVerify("objective_catalog.json", manifest.ArtifactSHA256s, &objectives); err != nil {
		return nil, err
	}
	var heroCore HeroCoreCatalog
	if err := decodeAndVerify("hero_core_catalog.json", manifest.ArtifactSHA256s, &heroCore); err != nil {
		return nil, err
	}
	var petCore PetCoreCatalog
	if err := decodeAndVerify("pet_core_catalog.json", manifest.ArtifactSHA256s, &petCore); err != nil {
		return nil, err
	}
	var petAcquisition PetAcquisitionCatalog
	if err := decodeAndVerify("pet_acquisition_catalog.json", manifest.ArtifactSHA256s, &petAcquisition); err != nil {
		return nil, err
	}
	var petProgression PetProgressionCatalog
	if err := decodeAndVerify("pet_progression_catalog.json", manifest.ArtifactSHA256s, &petProgression); err != nil {
		return nil, err
	}
	var equipmentPrimitives EquipmentPrimitivesCatalog
	if err := decodeAndVerify("equipment_primitives_catalog.json", manifest.ArtifactSHA256s, &equipmentPrimitives); err != nil {
		return nil, err
	}
	var heroEquipment HeroEquipmentCatalog
	if err := decodeAndVerify("hero_equipment_catalog.json", manifest.ArtifactSHA256s, &heroEquipment); err != nil {
		return nil, err
	}
	var superEquipment SuperEquipmentCatalog
	if err := decodeAndVerify("super_equipment_catalog.json", manifest.ArtifactSHA256s, &superEquipment); err != nil {
		return nil, err
	}
	var petEquipment PetEquipmentCatalog
	if err := decodeAndVerify("pet_equipment_catalog.json", manifest.ArtifactSHA256s, &petEquipment); err != nil {
		return nil, err
	}
	var petPromotionRestoration PetPromotionRestorationCatalog
	if err := decodeAndVerify("pet_promotion_restoration_catalog.json", manifest.ArtifactSHA256s, &petPromotionRestoration); err != nil {
		return nil, err
	}
	var heroFumo HeroFumoCatalog
	if err := decodeAndVerify("hero_fumo_catalog.json", manifest.ArtifactSHA256s, &heroFumo); err != nil {
		return nil, err
	}
	var heroPromotionRestoration HeroPromotionRestorationCatalog
	if err := decodeAndVerify("hero_promotion_restoration_catalog.json", manifest.ArtifactSHA256s, &heroPromotionRestoration); err != nil {
		return nil, err
	}
	var practice PracticeCatalog
	if err := decodeAndVerify("practice_catalog.json", manifest.ArtifactSHA256s, &practice); err != nil {
		return nil, err
	}
	var appearance AppearanceCatalog
	if err := decodeAndVerify("appearance_catalog.json", manifest.ArtifactSHA256s, &appearance); err != nil {
		return nil, err
	}

	var playerDisplay player.DisplayCatalog
	if err := decodeAndVerify("player_display_catalog.json", manifest.ArtifactSHA256s, &playerDisplay); err != nil {
		return nil, err
	}
	var publicShowcase PublicShowcasePolicy
	if err := decodeAndVerify("public_showcase_policy.json", manifest.ArtifactSHA256s, &publicShowcase); err != nil {
		return nil, err
	}
	var publicProfile PublicProfilePolicy
	if err := decodeAndVerify("public_profile_policy.json", manifest.ArtifactSHA256s, &publicProfile); err != nil {
		return nil, err
	}
	var invite GuildInvitePolicy
	if err := decodeAndVerify("guild_invite_policy.json", manifest.ArtifactSHA256s, &invite); err != nil {
		return nil, err
	}
	var broadcast GuildBroadcastPolicy
	if err := decodeAndVerify("guild_broadcast_policy.json", manifest.ArtifactSHA256s, &broadcast); err != nil {
		return nil, err
	}
	var socialGift SocialGiftCatalog
	if err := decodeAndVerify("social_gift_catalog.json", manifest.ArtifactSHA256s, &socialGift); err != nil {
		return nil, err
	}
	var emoticons EmoticonCatalog
	if err := decodeAndVerify("emoticon_catalog.json", manifest.ArtifactSHA256s, &emoticons); err != nil {
		return nil, err
	}
	catalog := &Catalog{
		PlayerDisplay:            playerDisplay,
		PublicShowcase:           publicShowcase,
		PublicProfile:            publicProfile,
		GuildInvite:              invite,
		GuildBroadcast:           broadcast,
		SocialGift:               socialGift,
		Emoticons:                emoticons,
		Manifest:                 manifest,
		Resources:                resources,
		PlayerProgression:        progression,
		FunctionGates:            functions,
		Objectives:               objectives,
		HeroCore:                 heroCore,
		PetCore:                  petCore,
		PetAcquisition:           petAcquisition,
		PetProgression:           petProgression,
		EquipmentPrimitives:      equipmentPrimitives,
		HeroEquipment:            heroEquipment,
		SuperEquipment:           superEquipment,
		PetEquipment:             petEquipment,
		PetPromotionRestoration:  petPromotionRestoration,
		HeroFumo:                 heroFumo,
		HeroPromotionRestoration: heroPromotionRestoration,
		Practice:                 practice,
		Appearance:               appearance,
	}
	if err := validateCatalog(catalog); err != nil {
		return nil, err
	}
	return catalog, nil
}

func decodeAndVerify(name string, hashes map[string]string, dst any) error {
	want, ok := hashes[name]
	if !ok || want == "" {
		return fmt.Errorf("builtin content: manifest missing hash for %s", name)
	}
	b, err := GeneratedFile(name)
	if err != nil {
		return err
	}
	sum := sha256.Sum256(b)
	if got := hex.EncodeToString(sum[:]); got != want {
		return fmt.Errorf("builtin content: %s SHA-256 mismatch: want %s got %s", name, want, got)
	}
	if err := json.Unmarshal(b, dst); err != nil {
		return fmt.Errorf("builtin content: decode %s: %w", name, err)
	}
	return nil
}

func validateManifest(raw []byte, manifest *Manifest) error {
	if manifest.SchemaVersion != SchemaVersion {
		return fmt.Errorf("builtin content: unsupported manifest schema %d", manifest.SchemaVersion)
	}
	if manifest.SourceArchiveSHA256 != ExpectedSourceArchiveSHA256 {
		return fmt.Errorf("builtin content: source archive drift: %s", manifest.SourceArchiveSHA256)
	}
	if manifest.CompilerVersion == "" || manifest.ParserVersion == "" {
		return errors.New("builtin content: compiler/parser version missing")
	}
	if manifest.RevisionDigestScope != "canonical_manifest_without_revision_id" {
		return fmt.Errorf("builtin content: unsupported revision digest scope %q", manifest.RevisionDigestScope)
	}
	if len(manifest.RevisionID) != 64 {
		return fmt.Errorf("builtin content: invalid revision id length %d", len(manifest.RevisionID))
	}
	if _, err := hex.DecodeString(manifest.RevisionID); err != nil || strings.ToLower(manifest.RevisionID) != manifest.RevisionID {
		return fmt.Errorf("builtin content: revision id must be lowercase SHA-256 hex")
	}
	expectedSources, expectedArtifacts := 71, 23
	if manifest.CompilerVersion == "i7b6a-player-display" {
		expectedSources, expectedArtifacts = 75, 24
	}
	if len(manifest.Sources) != expectedSources {
		return fmt.Errorf("builtin content: expected 71 source records, got %d", len(manifest.Sources))
	}
	if len(manifest.ArtifactSHA256s) != expectedArtifacts {
		return fmt.Errorf("builtin content: expected 23 hashed payload artifacts, got %d", len(manifest.ArtifactSHA256s))
	}

	var basis map[string]any
	if err := json.Unmarshal(raw, &basis); err != nil {
		return fmt.Errorf("builtin content: decode manifest basis: %w", err)
	}
	delete(basis, "revision_id")
	canonical, err := json.Marshal(basis)
	if err != nil {
		return fmt.Errorf("builtin content: encode manifest basis: %w", err)
	}
	sum := sha256.Sum256(canonical)
	if got := hex.EncodeToString(sum[:]); got != manifest.RevisionID {
		return fmt.Errorf("builtin content: revision digest mismatch: want %s got %s", manifest.RevisionID, got)
	}
	return nil
}

func validateCatalog(c *Catalog) error {
	if e := c.PlayerDisplay.Validate(); e != nil {
		return e
	}
	if e := c.PublicShowcase.Validate(); e != nil {
		return e
	}
	if e := c.PublicProfile.Validate(); e != nil {
		return e
	}
	if err := c.GuildInvite.Validate(); err != nil {
		return err
	}
	if err := c.GuildBroadcast.Validate(); err != nil {
		return err
	}
	if err := c.SocialGift.Validate(); err != nil {
		return err
	}

	if c.Emoticons.SchemaVersion != SchemaVersion || c.Emoticons.Source != "data/tables/emoticon.lua" || len(c.Emoticons.Definitions) != 85 {
		return errors.New("builtin content: emoticon schema/source/count drift")
	}
	lastEmoticon := int64(0)
	free := 0
	paidItems := map[int64]bool{}
	for _, e := range c.Emoticons.Definitions {
		if e.ID <= lastEmoticon || e.ItemID < 0 {
			return errors.New("builtin content: emoticon identity drift")
		}
		lastEmoticon = e.ID
		if e.ItemID == 0 {
			free++
			continue
		}
		qualified := false
		for _, r := range c.Resources.Resources {
			if r.ItemID == e.ItemID && r.Class == "STACK_ITEM" && r.SettlementActivation == "ENABLED_R4" && r.StackCap == 1 {
				qualified = true
			}
		}
		if !qualified {
			return errors.New("builtin content: emoticon item unqualified")
		}
		paidItems[e.ItemID] = true
	}
	if free != 25 || len(paidItems) != 47 {
		return errors.New("builtin content: emoticon entitlement counts drift")
	}

	if c.Resources.SchemaVersion != SchemaVersion || c.PlayerProgression.SchemaVersion != SchemaVersion || c.FunctionGates.SchemaVersion != SchemaVersion || c.Objectives.SchemaVersion != SchemaVersion || c.HeroCore.SchemaVersion != SchemaVersion || c.PetCore.SchemaVersion != SchemaVersion || c.PetAcquisition.SchemaVersion != SchemaVersion || c.PetProgression.SchemaVersion != SchemaVersion || c.EquipmentPrimitives.SchemaVersion != SchemaVersion || c.HeroEquipment.SchemaVersion != SchemaVersion || c.SuperEquipment.SchemaVersion != SchemaVersion || c.PetEquipment.SchemaVersion != SchemaVersion || c.PetPromotionRestoration.SchemaVersion != SchemaVersion || c.HeroFumo.SchemaVersion != SchemaVersion || c.HeroPromotionRestoration.SchemaVersion != SchemaVersion || c.Practice.SchemaVersion != SchemaVersion || c.Appearance.SchemaVersion != SchemaVersion {
		return errors.New("builtin content: payload schema version mismatch")
	}
	if c.Appearance.Source != "CA7 exact src_64 Character appearance content facts" || len(c.Appearance.QualifiedSkinDefinitions) != 262 || len(c.Appearance.QualifiedSkinAcquisitionItems) != 264 || len(c.Appearance.PaidLIVEDefinitions) != 12 || len(c.Appearance.PetHomeStyleDefinitions) != 4 {
		return errors.New("builtin content: CA7 appearance source/count drift")
	}
	lastAppearanceModel := int64(0)
	skillBearingAppearance := 0
	appearanceModels := make(map[int64]int64, 262)
	for _, row := range c.Appearance.QualifiedSkinDefinitions {
		if row.ModelID <= lastAppearanceModel || row.HeroOriginTableID <= 0 || row.SourceSkinID <= 0 || row.SkinSkillID < 0 {
			return errors.New("builtin content: invalid/sort-drift CA7 skin definition")
		}
		lastAppearanceModel = row.ModelID
		appearanceModels[row.ModelID] = row.HeroOriginTableID
		if row.SkinSkillID > 0 {
			skillBearingAppearance++
		}
	}
	if skillBearingAppearance != 225 {
		return errors.New("builtin content: CA7 skin-skill count drift")
	}
	lastAppearanceItem := int64(0)
	timedAppearanceItems := 0
	for _, row := range c.Appearance.QualifiedSkinAcquisitionItems {
		if row.ItemID <= lastAppearanceItem || row.ModelID <= 0 || row.HeroOriginTableID <= 0 || appearanceModels[row.ModelID] != row.HeroOriginTableID {
			return errors.New("builtin content: invalid/sort-drift CA7 skin acquisition item")
		}
		lastAppearanceItem = row.ItemID
		if row.DurationSeconds != nil {
			if *row.DurationSeconds != 259200 {
				return errors.New("builtin content: CA7 timed skin duration drift")
			}
			timedAppearanceItems++
		}
	}
	if timedAppearanceItems != 2 {
		return errors.New("builtin content: CA7 timed skin item count drift")
	}
	lastLIVEModel := int64(0)
	for _, row := range c.Appearance.PaidLIVEDefinitions {
		if row.ModelID <= lastLIVEModel || row.HeroOriginTableID <= 0 || row.CrystalCost <= 0 || row.ActivationItemID != 50005171 || row.ActivationItemCount <= 0 {
			return errors.New("builtin content: invalid/sort-drift CA7 paid LIVE definition")
		}
		lastLIVEModel = row.ModelID
	}
	lastPetStyle := int64(0)
	for _, row := range c.Appearance.PetHomeStyleDefinitions {
		if row.StyleItemID <= lastPetStyle || row.PetOriginTableID <= 0 {
			return errors.New("builtin content: invalid/sort-drift CA7 Pet-style definition")
		}
		lastPetStyle = row.StyleItemID
	}

	if c.PlayerProgression.Source != "data/tables/player.lua" {
		return fmt.Errorf("builtin content: unexpected progression source %q", c.PlayerProgression.Source)
	}
	if c.FunctionGates.Source != "data/tables/function.lua" {
		return fmt.Errorf("builtin content: unexpected function source %q", c.FunctionGates.Source)
	}
	if c.Objectives.Status != "BUILTIN_ACTIVATION_EMPTY_UNQUALIFIED_MAPPING" || len(c.Objectives.Definitions) != 0 {
		return errors.New("builtin content: built-in objective activation must remain empty")
	}
	if c.HeroCore.Source != "CA2 exact src_64 Hero core" || len(c.HeroCore.Templates) != 568 || len(c.HeroCore.ExpItems) != 5 || len(c.HeroCore.ExpRows) != 100 || len(c.HeroCore.NormalStarRows) != 5 || len(c.HeroCore.SuperStarRows) != 10 || len(c.HeroCore.SuperPrerequisites) != 70 || len(c.HeroCore.AcquisitionItems) != 291 {
		return errors.New("builtin content: CA2 Hero core source/count drift")
	}
	lastHero := int64(0)
	origins := make(map[int64]struct{}, 291)
	for _, h := range c.HeroCore.Templates {
		if h.TableID <= lastHero || h.OriginTableID <= 0 || (h.HeroKind != "NORMAL" && h.HeroKind != "SUPER") || h.InitialStar <= 0 {
			return errors.New("builtin content: invalid/sort-drift Hero template")
		}
		lastHero = h.TableID
		if h.TableID == h.OriginTableID {
			origins[h.OriginTableID] = struct{}{}
		}
	}
	for _, a := range c.HeroCore.AcquisitionItems {
		if a.ItemID <= 0 || a.OriginTableID <= 0 {
			return errors.New("builtin content: invalid Hero acquisition mapping")
		}
	}
	wantHeroExp := []HeroExpItem{{50001001, 60}, {50001002, 300}, {50001004, 1500}, {50001005, 7500}, {50005182, 10000}}
	for i, x := range c.HeroCore.ExpItems {
		if i >= len(wantHeroExp) || x != wantHeroExp[i] {
			return errors.New("builtin content: Hero EXP item/value drift")
		}
	}
	if c.PetCore.Source != "CA3-1 exact src_64 Pet core" || len(c.PetCore.Templates) != 54 {
		return errors.New("builtin content: CA3-1 Pet core source/count drift")
	}
	lastPet := int64(0)
	petOrigins := make(map[int64]int, 27)
	baseAwaken := make(map[int64]int64, 27)
	for _, x := range c.PetCore.Templates {
		if x.TableID <= lastPet || x.OriginTableID <= 0 || x.InitialStar <= 0 || x.InitialStar > 5 {
			return errors.New("builtin content: invalid/sort-drift Pet template")
		}
		lastPet = x.TableID
		if x.IsAwakened {
			if x.TableID == x.OriginTableID || x.AwakenTableID != 0 {
				return errors.New("builtin content: invalid awakened Pet lineage")
			}
		} else {
			if x.TableID != x.OriginTableID || x.AwakenTableID <= 0 {
				return errors.New("builtin content: invalid base Pet lineage")
			}
			baseAwaken[x.OriginTableID] = x.AwakenTableID
		}
		petOrigins[x.OriginTableID]++
	}
	if len(petOrigins) != 27 || len(baseAwaken) != 27 {
		return errors.New("builtin content: Pet origin-family drift")
	}
	for _, x := range c.PetCore.Templates {
		if petOrigins[x.OriginTableID] != 2 {
			return errors.New("builtin content: Pet lineage member-count drift")
		}
		if x.IsAwakened && baseAwaken[x.OriginTableID] != x.TableID {
			return errors.New("builtin content: Pet awaken-pair drift")
		}
	}
	if c.PetAcquisition.Source != "CA3-2 exact src_64 Pet acquisition/incubation" || len(c.PetAcquisition.Templates) != 27 {
		return errors.New("builtin content: CA3-2 Pet acquisition source/count drift")
	}
	wantFragmentCosts := map[string]int64{"1": 10, "2": 30, "3": 80, "4": 180, "5": 330}
	if len(c.PetAcquisition.Policy.FragmentCostsByInitialStar) != len(wantFragmentCosts) {
		return errors.New("builtin content: Pet fragment-cost policy drift")
	}
	for k, want := range wantFragmentCosts {
		if c.PetAcquisition.Policy.FragmentCostsByInitialStar[k] != want {
			return errors.New("builtin content: Pet fragment-cost policy drift")
		}
	}
	if c.PetAcquisition.Policy.StarterEggItemID != 50001050 || c.PetAcquisition.Policy.HatchCostParam != 12960000 {
		return errors.New("builtin content: Pet starter/hatch policy drift")
	}
	baseByID := make(map[int64]PetTemplate, 27)
	for _, x := range c.PetCore.Templates {
		if !x.IsAwakened {
			baseByID[x.TableID] = x
		}
	}
	lastAcquisitionPet := int64(0)
	seenAcquisitionOrigins := make(map[int64]struct{}, 27)
	starterFound := false
	for _, x := range c.PetAcquisition.Templates {
		base, ok := baseByID[x.TableID]
		if !ok || x.TableID <= lastAcquisitionPet || x.OriginTableID != x.TableID || x.OriginTableID != base.OriginTableID || x.InitialStar != base.InitialStar {
			return errors.New("builtin content: invalid/sort-drift Pet acquisition template")
		}
		lastAcquisitionPet = x.TableID
		if _, exists := seenAcquisitionOrigins[x.OriginTableID]; exists {
			return errors.New("builtin content: duplicate Pet acquisition origin")
		}
		seenAcquisitionOrigins[x.OriginTableID] = struct{}{}
		if x.EggItemID <= 0 || x.EssenceItemID <= 0 || x.FragmentCount != wantFragmentCosts[fmt.Sprint(x.InitialStar)] || x.HatchSeconds != 86400 || x.SummonType != 4 {
			return errors.New("builtin content: Pet acquisition field drift")
		}
		if x.EggItemID == c.PetAcquisition.Policy.StarterEggItemID {
			starterFound = true
		}
	}
	if len(seenAcquisitionOrigins) != 27 || !starterFound {
		return errors.New("builtin content: Pet acquisition origin/starter drift")
	}

	if c.PetProgression.Source != "CA3-3 exact src_64 Pet progression" || len(c.PetProgression.Templates) != 54 || len(c.PetProgression.SkillSlots) != 270 || len(c.PetProgression.ExpRows) != 100 || len(c.PetProgression.ExpItems) != 3 || len(c.PetProgression.SkillBooks) != 130 || len(c.PetProgression.SlotPolicy) != 5 || len(c.PetProgression.EvolutionRows) != 4 {
		return errors.New("builtin content: CA3-3 Pet progression source/count drift")
	}
	if c.PetProgression.Policy.SkillBookItemID != 50001090 {
		return errors.New("builtin content: Pet Skill Book item drift")
	}
	for i, row := range c.PetProgression.ExpRows {
		if row.Level != int64(i+1) || row.TotalExp < 0 || (i > 0 && row.TotalExp < c.PetProgression.ExpRows[i-1].TotalExp) {
			return errors.New("builtin content: Pet EXP progression drift")
		}
	}
	if c.PetProgression.ExpRows[99].TotalExp != 1980095 {
		return errors.New("builtin content: Pet EXP cap drift")
	}
	for i, row := range c.PetProgression.SkillBooks {
		lev := int64(i + 1)
		if row.EffectiveLevel != lev || row.BookCount != (lev+9)/10 {
			return errors.New("builtin content: Pet Skill Book curve drift")
		}
	}
	wantSlot := []PetSkillSlotPolicy{{0, 1, false, 1}, {0, 2, false, 2}, {20, 4, false, 3}, {40, 7, false, 4}, {60, 0, true, 5}}
	for i, want := range wantSlot {
		if c.PetProgression.SlotPolicy[i] != want {
			return errors.New("builtin content: Pet skill-slot policy drift")
		}
	}
	wantEvolution := []PetEvolutionRow{{20, 2}, {50, 3}, {100, 4}, {150, 5}}
	for i, want := range wantEvolution {
		if c.PetProgression.EvolutionRows[i] != want {
			return errors.New("builtin content: Pet evolution curve drift")
		}
	}
	forms := make(map[int64]PetProgressionTemplate, 54)
	for _, row := range c.PetProgression.Templates {
		if row.TableID <= 0 || row.StoneItemID <= 0 {
			return errors.New("builtin content: invalid Pet progression template")
		}
		forms[row.TableID] = row
	}
	counts := make(map[int64]int, 54)
	for _, row := range c.PetProgression.SkillSlots {
		if _, ok := forms[row.TableID]; !ok || row.Slot < 1 || row.Slot > 5 || row.SourceSkillID < 0 || (row.StarBonus != 0 && row.StarBonus != 10) {
			return errors.New("builtin content: invalid Pet source-skill slot")
		}
		counts[row.TableID]++
	}
	for id := range forms {
		if counts[id] != 5 {
			return errors.New("builtin content: Pet source-skill arity drift")
		}
	}

	lastKey := ""
	seenItems := make(map[int64]struct{})
	byKey := make(map[string]ResourceDefinition, len(c.Resources.Resources))
	for i, row := range c.Resources.Resources {
		if row.DefinitionKey == "" || row.Class == "" || row.CatalogStatus == "" || row.SettlementActivation == "" {
			return fmt.Errorf("builtin content: incomplete resource row %d", i)
		}
		if i > 0 && row.DefinitionKey <= lastKey {
			return fmt.Errorf("builtin content: resource definitions not strictly sorted at %q", row.DefinitionKey)
		}
		lastKey = row.DefinitionKey
		if _, exists := byKey[row.DefinitionKey]; exists {
			return fmt.Errorf("builtin content: duplicate definition key %q", row.DefinitionKey)
		}
		byKey[row.DefinitionKey] = row
		if row.ItemID != 0 {
			if _, exists := seenItems[row.ItemID]; exists {
				return fmt.Errorf("builtin content: duplicate item id %d", row.ItemID)
			}
			seenItems[row.ItemID] = struct{}{}
		}
	}

	mustResource := func(key, class, activation string) (ResourceDefinition, error) {
		row, ok := byKey[key]
		if !ok {
			return ResourceDefinition{}, fmt.Errorf("builtin content: missing required resource %q", key)
		}
		if row.Class != class || row.SettlementActivation != activation {
			return ResourceDefinition{}, fmt.Errorf("builtin content: resource %q class/activation drift", key)
		}
		return row, nil
	}
	coin, err := mustResource("scalar_currency:friendship_coin", "SCALAR_CURRENCY", "ENABLED_R4")
	if err != nil || coin.SourceAssetID != nil || coin.ItemID != 0 {
		return errors.New("builtin content: named Friendship Coin identity drift")
	}
	mana, err := mustResource("scalar_currency:mana", "SCALAR_CURRENCY", "ENABLED_R4")
	if err != nil {
		return err
	}
	crystal, err := mustResource("scalar_currency:crystal", "SCALAR_CURRENCY", "ENABLED_R4")
	if err != nil {
		return err
	}
	if mana.SourceAssetID == nil || *mana.SourceAssetID != -2 || crystal.SourceAssetID == nil || *crystal.SourceAssetID != -1 {
		return errors.New("builtin content: Mana/Crystal source asset identity drift")
	}
	energy, err := mustResource("temporal:energy", "TEMPORAL", "ENABLED_R5")
	if err != nil {
		return err
	}
	spirit, err := mustResource("temporal:spirit_energy", "TEMPORAL", "ENABLED_R5")
	if err != nil {
		return err
	}
	skill, err := mustResource("temporal:skill_point", "TEMPORAL", "ENABLED_R5")
	if err != nil {
		return err
	}
	invitation, err := mustResource("temporal:invitation", "TEMPORAL", "FAIL_CLOSED")
	if err != nil {
		return err
	}
	if energy.RegenSeconds != 300 || energy.CapRule != "PLAYER_LEVEL_ENERGY" {
		return errors.New("builtin content: Energy temporal definition drift")
	}
	if spirit.RegenSeconds != 360 || spirit.CapRule != "STATIC" || spirit.StaticCap != 180 {
		return errors.New("builtin content: Spirit Energy temporal definition drift")
	}
	if skill.RegenSeconds != 300 || skill.CapRule != "VIP_PLUS_MONTHLY_PRIVILEGE" {
		return errors.New("builtin content: Skill Point temporal definition drift")
	}
	if invitation.RegenSeconds != 1800 || invitation.CapRule != "UNRESOLVED" {
		return errors.New("builtin content: Invitation temporal definition drift")
	}

	rows := c.PlayerProgression.Rows
	if len(rows) == 0 {
		return errors.New("builtin content: empty player progression")
	}
	var lastTotal int64 = -1
	for i, row := range rows {
		if row.Lev != int64(i+1) {
			return fmt.Errorf("builtin content: non-contiguous player level at index %d: %d", i, row.Lev)
		}
		if row.TotalExp < lastTotal {
			return fmt.Errorf("builtin content: non-monotonic total EXP at level %d", row.Lev)
		}
		lastTotal = row.TotalExp
	}

	exp, err := mustResource("player_exp:exp", "PLAYER_EXP", "ENABLED_R5")
	if err != nil {
		return err
	}
	_ = exp

	if len(c.FunctionGates.Gates) != 99 {
		return fmt.Errorf("builtin content: function gate count drift: %d", len(c.FunctionGates.Gates))
	}
	lastFunctionID := int64(0)
	for _, gate := range c.FunctionGates.Gates {
		if gate.FunctionID <= lastFunctionID || gate.SourceFactKey == "" || gate.RawOpenValue == "" {
			return errors.New("builtin content: invalid function gate catalog")
		}
		if gate.FunctionID == 38 {
			if gate.AnnouncementCapability != "PET_STARTER_CA3" || gate.RequiredLevel == nil || *gate.RequiredLevel != 40 || gate.GateKind != "PURE_LEVEL" {
				return errors.New("builtin content: Pet Function 38 announcement/gate drift")
			}
		} else if gate.AnnouncementCapability != "NONE" {
			return errors.New("builtin content: unexpected function announcement capability")
		}
		lastFunctionID = gate.FunctionID
		switch gate.GateKind {
		case "PURE_LEVEL":
			if gate.RequiredLevel == nil || *gate.RequiredLevel <= 0 {
				return errors.New("builtin content: invalid pure-level function gate")
			}
		case "UNSUPPORTED_COMPOSITE":
			if gate.RequiredLevel != nil {
				return errors.New("builtin content: composite function gate unexpectedly has level")
			}
		default:
			return fmt.Errorf("builtin content: unknown function gate kind %q", gate.GateKind)
		}
	}

	if c.EquipmentPrimitives.Source != "CA4-1 authoritative app-assets item.lua equipment/composition closure" || len(c.EquipmentPrimitives.RootItemIDs) != 604 || len(c.EquipmentPrimitives.Items) != 1176 || len(c.EquipmentPrimitives.RecipeEdges) != 1934 {
		return errors.New("builtin content: CA4-1 equipment primitive source/count drift")
	}
	itemSet := make(map[int64]EquipmentPrimitive, len(c.EquipmentPrimitives.Items))
	lastEquipmentItem := int64(0)
	rootCount := 0
	for _, x := range c.EquipmentPrimitives.Items {
		if x.ItemID <= lastEquipmentItem || x.ItemID <= 0 || x.RequiredLevel < 0 || x.ComposeMana < 0 {
			return errors.New("builtin content: invalid/sort-drift equipment primitive")
		}
		lastEquipmentItem = x.ItemID
		itemSet[x.ItemID] = x
		if x.SourceItemType == 1 || x.SourceItemType == 8 {
			rootCount++
		}
	}
	if rootCount != 604 {
		return errors.New("builtin content: equipment root type count drift")
	}
	if len(c.EquipmentPrimitives.RootItemIDs) != rootCount {
		return errors.New("builtin content: equipment root list count drift")
	}
	for i, id := range c.EquipmentPrimitives.RootItemIDs {
		if i > 0 && id <= c.EquipmentPrimitives.RootItemIDs[i-1] {
			return errors.New("builtin content: equipment roots not strictly sorted")
		}
		x, ok := itemSet[id]
		if !ok || (x.SourceItemType != 1 && x.SourceItemType != 8) {
			return errors.New("builtin content: invalid equipment root")
		}
	}
	parents := make(map[int64]map[int64]struct{})
	repeatedParents := make(map[int64]struct{})
	lastParent, lastOrdinal := int64(0), int64(0)
	for _, e := range c.EquipmentPrimitives.RecipeEdges {
		if e.ParentItemID <= 0 || e.ComponentItemID <= 0 || e.Ordinal <= 0 || e.ComponentCount <= 0 {
			return errors.New("builtin content: invalid equipment recipe edge")
		}
		if _, ok := itemSet[e.ParentItemID]; !ok {
			return errors.New("builtin content: equipment recipe parent outside closure")
		}
		if _, ok := itemSet[e.ComponentItemID]; !ok {
			return errors.New("builtin content: equipment recipe component outside closure")
		}
		if e.ParentItemID < lastParent || (e.ParentItemID == lastParent && e.Ordinal <= lastOrdinal) {
			return errors.New("builtin content: equipment recipe order drift")
		}
		if e.ParentItemID != lastParent {
			lastParent, lastOrdinal = e.ParentItemID, 0
		}
		lastOrdinal = e.Ordinal
		m := parents[e.ParentItemID]
		if m == nil {
			m = map[int64]struct{}{}
			parents[e.ParentItemID] = m
		}
		if _, exists := m[e.ComponentItemID]; exists {
			repeatedParents[e.ParentItemID] = struct{}{}
		}
		m[e.ComponentItemID] = struct{}{}
	}
	if len(parents) != 797 || len(repeatedParents) != 29 {
		return errors.New("builtin content: equipment recipe topology drift")
	}

	if c.HeroEquipment.Source != "CA4-2 exact src_64 partner.lua Normal-Hero equipment mapping" || len(c.HeroEquipment.Positions) != 53280 {
		return errors.New("builtin content: CA4-2 Hero equipment source/count drift")
	}
	lastHeroTable, lastColor, lastSlot := int64(0), int64(0), int64(0)
	zeroPositions, ordinaryPositions, specialPositions := 0, 0, 0
	ordinaryIDs, specialIDs := map[int64]struct{}{}, map[int64]struct{}{}
	perHero := map[int64]int{}
	for _, x := range c.HeroEquipment.Positions {
		if x.HeroTableID <= 0 || x.Color < 1 || x.Color > 16 || x.Slot < 1 || x.Slot > 6 || x.ItemID < 0 {
			return errors.New("builtin content: invalid Hero equipment position")
		}
		if x.HeroTableID < lastHeroTable || (x.HeroTableID == lastHeroTable && (x.Color < lastColor || (x.Color == lastColor && x.Slot <= lastSlot))) {
			return errors.New("builtin content: Hero equipment positions not strictly sorted")
		}
		if x.HeroTableID != lastHeroTable {
			lastHeroTable, lastColor, lastSlot = x.HeroTableID, 0, 0
		}
		if x.Color != lastColor {
			lastColor, lastSlot = x.Color, 0
		}
		lastSlot = x.Slot
		perHero[x.HeroTableID]++
		if x.ItemID == 0 {
			if x.OrdinaryEligible {
				return errors.New("builtin content: zero Hero equipment position cannot be ordinary-eligible")
			}
			zeroPositions++
			continue
		}
		if _, ok := itemSet[x.ItemID]; !ok {
			return errors.New("builtin content: Hero equipment item outside CA4-1 primitive closure")
		}
		if x.OrdinaryEligible {
			ordinaryPositions++
			ordinaryIDs[x.ItemID] = struct{}{}
		} else {
			specialPositions++
			specialIDs[x.ItemID] = struct{}{}
		}
	}
	if len(perHero) != 555 || zeroPositions != 1130 || ordinaryPositions != 50504 || specialPositions != 1646 || len(ordinaryIDs) != 214 || len(specialIDs) != 164 {
		return errors.New("builtin content: Hero equipment topology drift")
	}
	for _, n := range perHero {
		if n != 96 {
			return errors.New("builtin content: Hero equipment row arity drift")
		}
	}

	if c.SuperEquipment.Source != "CA4-5 exact src_64 Super Hero fixed equipment topology and enhancement policy" || len(c.SuperEquipment.Positions) != 84 || len(c.SuperEquipment.EnhancementCaps) != 10 || len(c.SuperEquipment.EnhancementTiers) != 6 {
		return errors.New("builtin content: CA4-5 Super equipment source/count drift")
	}
	perSuper := map[int64]int{}
	baseIDs := map[int64]struct{}{}
	lastSuper, lastSuperSlot := int64(0), int64(0)
	for _, x := range c.SuperEquipment.Positions {
		if x.HeroTableID < 11001 || x.HeroTableID > 11014 || x.Slot < 1 || x.Slot > 6 || x.ItemID < 20001366 || x.ItemID > 20001377 {
			return errors.New("builtin content: invalid CA4-5 Super equipment position")
		}
		if x.HeroTableID < lastSuper || (x.HeroTableID == lastSuper && x.Slot <= lastSuperSlot) {
			return errors.New("builtin content: CA4-5 Super equipment positions not strictly sorted")
		}
		if x.HeroTableID != lastSuper {
			lastSuper, lastSuperSlot = x.HeroTableID, 0
		}
		lastSuperSlot = x.Slot
		primitive, ok := itemSet[x.ItemID]
		if !ok || primitive.SourceItemType != 1 || primitive.RequiredLevel != 89 {
			return errors.New("builtin content: CA4-5 Super base item primitive drift")
		}
		perSuper[x.HeroTableID]++
		baseIDs[x.ItemID] = struct{}{}
	}
	if len(perSuper) != 14 || len(baseIDs) != 12 {
		return errors.New("builtin content: CA4-5 Super topology drift")
	}
	for _, n := range perSuper {
		if n != 6 {
			return errors.New("builtin content: CA4-5 Super slot arity drift")
		}
	}
	wantSuperCaps := []int64{10, 10, 10, 10, 10, 20, 30, 40, 50, 60}
	for i, x := range c.SuperEquipment.EnhancementCaps {
		if x.Star != int64(i+1) || x.MaxEnhancement != wantSuperCaps[i] || x.EffectiveClientReachable != (x.Star <= 8) {
			return errors.New("builtin content: CA4-5 Super enhancement cap drift")
		}
	}
	wantTierStar := []int64{1, 6, 7, 8, 9, 10}
	wantTierCount := []int64{1, 1, 1, 1, 2, 2}
	for i, x := range c.SuperEquipment.EnhancementTiers {
		if x.Tier != int64(i+1) || x.MinStar != wantTierStar[i] || x.DuplicateCount != wantTierCount[i] || x.EffectiveClientReachable != (x.MinStar <= 8) {
			return errors.New("builtin content: CA4-5 Super enhancement tier drift")
		}
	}

	if c.PetEquipment.Source != "CA4-4A exact src_64 pet.lua Pet equipment mapping" || len(c.PetEquipment.Positions) != 2592 {
		return errors.New("builtin content: CA4-4A Pet equipment source/count drift")
	}
	lastPetTable, lastPetColor, lastPetSlot := int64(0), int64(0), int64(0)
	petZero, petOrdinary, petSpecial := 0, 0, 0
	petOrdinaryIDs, petSpecialIDs := map[int64]struct{}{}, map[int64]struct{}{}
	perPet := map[int64]int{}
	petTopology := map[int64][]PetEquipmentPosition{}
	for _, x := range c.PetEquipment.Positions {
		if x.PetTableID <= 0 || x.Color < 1 || x.Color > 16 || x.Slot < 1 || x.Slot > 3 || x.ItemID < 0 {
			return errors.New("builtin content: invalid Pet equipment position")
		}
		if x.PetTableID < lastPetTable || (x.PetTableID == lastPetTable && (x.Color < lastPetColor || (x.Color == lastPetColor && x.Slot <= lastPetSlot))) {
			return errors.New("builtin content: Pet equipment positions not strictly sorted")
		}
		if x.PetTableID != lastPetTable {
			lastPetTable, lastPetColor, lastPetSlot = x.PetTableID, 0, 0
		}
		if x.Color != lastPetColor {
			lastPetColor, lastPetSlot = x.Color, 0
		}
		lastPetSlot = x.Slot
		perPet[x.PetTableID]++
		petTopology[x.PetTableID] = append(petTopology[x.PetTableID], x)
		switch x.Classification {
		case "EMPTY":
			if x.ItemID != 0 {
				return errors.New("builtin content: nonzero Pet equipment classified EMPTY")
			}
			petZero++
		case "ORDINARY":
			primitive, ok := itemSet[x.ItemID]
			if !ok || primitive.SourceItemType != 8 {
				return errors.New("builtin content: ordinary Pet equipment outside type-8 CA4-1 roots")
			}
			petOrdinary++
			petOrdinaryIDs[x.ItemID] = struct{}{}
		case "AWAKENING":
			primitive, ok := itemSet[x.ItemID]
			if !ok || primitive.SourceItemType != 8 || x.Slot != 1 || x.Color < 12 || primitive.RequiredLevel != 90 {
				return errors.New("builtin content: invalid Pet Awakening equipment position")
			}
			petSpecial++
			petSpecialIDs[x.ItemID] = struct{}{}
		default:
			return errors.New("builtin content: invalid Pet equipment classification")
		}
	}
	if len(perPet) != 54 || petZero != 70 || petOrdinary != 2322 || petSpecial != 200 || len(petOrdinaryIDs) != 73 || len(petSpecialIDs) != 20 {
		return errors.New("builtin content: Pet equipment topology drift")
	}
	for _, n := range perPet {
		if n != 48 {
			return errors.New("builtin content: Pet equipment row arity drift")
		}
	}
	for baseID, awakeID := range baseAwaken {
		b, bok := petTopology[baseID]
		a, aok := petTopology[awakeID]
		if !bok || !aok || len(b) != len(a) {
			return errors.New("builtin content: Pet equipment awaken-pair missing")
		}
		for i := range b {
			if b[i].Color != a[i].Color || b[i].Slot != a[i].Slot || b[i].ItemID != a[i].ItemID || b[i].Classification != a[i].Classification {
				return errors.New("builtin content: Pet equipment base/awaken topology drift")
			}
		}
	}

	if c.HeroFumo.Source != "CA4-3A exact src_64 Hero Fumo target/material policy" || len(c.HeroFumo.Targets) != 359 || len(c.HeroFumo.Materials) != 516 {
		return errors.New("builtin content: CA4-3A Hero Fumo source/count drift")
	}
	lastFumoTarget := int64(0)
	for _, x := range c.HeroFumo.Targets {
		if x.ItemID <= lastFumoTarget || x.ItemID <= 0 || len(x.ThresholdIncrements) == 0 || len(x.StageDeltaByAttr) != len(x.ThresholdIncrements) || x.TotalCap <= 0 || x.ManaPerFumo < 0 {
			return errors.New("builtin content: invalid/sort-drift Hero Fumo target")
		}
		lastFumoTarget = x.ItemID
		total := int64(0)
		for _, v := range x.ThresholdIncrements {
			if v <= 0 {
				return errors.New("builtin content: invalid Hero Fumo threshold")
			}
			total += v
		}
		if total != x.TotalCap {
			return errors.New("builtin content: Hero Fumo total cap drift")
		}
	}
	lastFumoMaterial := int64(0)
	for _, x := range c.HeroFumo.Materials {
		if x.ItemID <= lastFumoMaterial || x.ItemID <= 0 || x.Moneng <= 0 || (x.ItemType != 1 && x.ItemType != 2 && x.ItemType != 4 && x.ItemType != 5 && x.ItemType != 6) {
			return errors.New("builtin content: invalid/sort-drift Hero Fumo material")
		}
		lastFumoMaterial = x.ItemID
	}

	caps := append([]string(nil), c.Manifest.EnabledCapabilities...)
	sort.Strings(caps)
	wantCaps := []string{"CHARACTER_APPEARANCE_CA7", "EQUIPMENT_PRIMITIVES_CA4", "FRIEND_DM_EMOTICON_I7A6A", "FUNCTION_LEVEL_ELIGIBILITY_R5", "GUILD_BROADCAST_I7A8A", "GUILD_INVITE_PRESENTATION_I7A8B", "HERO_CORE_CA2", "HERO_EQUIPMENT_CA4_2", "HERO_FUMO_CA4_3A", "HERO_PROGRESSION_CA2", "HERO_PROMOTION_RESTORATION_CA4_3B", "PET_ACQUISITION_CA3", "PET_CORE_CA3", "PET_EQUIPMENT_CA4_4A", "PET_PROGRESSION_CA3", "PET_PROMOTION_RESTORATION_CA4_4B", "PLAYER_DISPLAY_I7B6A", "PLAYER_EXP_R5", "PRACTICE_CA6", "PUBLIC_PROFILE_PREFERENCES_I7B2B", "PUBLIC_PROFILE_SHOWCASE_SELECTION_I7B3A", "QUALIFIED_ORDINARY_STACK_ITEM_DEFINITIONS", "SCALAR_CRYSTAL", "SCALAR_MANA", "SOCIAL_GIFT_I7A7A", "SUPER_EQUIPMENT_CA4_5", "TEMPORAL_ENERGY_R5", "TEMPORAL_SKILL_POINT_R5", "TEMPORAL_SPIRIT_ENERGY_R5"}
	if len(caps) != len(wantCaps) {
		return fmt.Errorf("builtin content: enabled capability count drift: %v", caps)
	}
	for i := range wantCaps {
		if caps[i] != wantCaps[i] {
			return fmt.Errorf("builtin content: enabled capability drift: %v", caps)
		}
	}
	if c.PetPromotionRestoration.Source != "CA4-4B exact src_64 Pet ordinary promotion-restoration eligibility" || len(c.PetPromotionRestoration.EligibleEquipment) != 73 {
		return errors.New("builtin content: CA4-4B Pet promotion restoration eligibility drift")
	}
	petRestoreSeen := map[int64]bool{}
	petRestoreQualities := map[int64]int{}
	for _, row := range c.PetPromotionRestoration.EligibleEquipment {
		if row.EquipmentItemID <= 0 || row.SourceQuality < 1 || row.SourceQuality > 6 || petRestoreSeen[row.EquipmentItemID] {
			return errors.New("builtin content: invalid CA4-4B Pet promotion restoration row")
		}
		petRestoreSeen[row.EquipmentItemID] = true
		petRestoreQualities[row.SourceQuality]++
	}
	wantPetRestoreQualities := map[int64]int{1: 3, 2: 13, 3: 11, 4: 24, 5: 15, 6: 7}
	if !reflect.DeepEqual(petRestoreQualities, wantPetRestoreQualities) {
		return errors.New("builtin content: CA4-4B Pet promotion restoration quality distribution drift")
	}
	for _, id := range []int64{80001001, 80001006, 80001010} {
		if !petRestoreSeen[id] {
			return errors.New("builtin content: CA4-4B Pet q1 restoration identity missing")
		}
	}

	if c.HeroPromotionRestoration.Source != "CA4-3B exact src_64 Normal-Hero promotion restoration source facts" || len(c.HeroPromotionRestoration.EligibleEquipment) != 195 || len(c.HeroPromotionRestoration.QualityFractions) != 5 || len(c.HeroPromotionRestoration.Denominations) != 3 {
		return errors.New("builtin content: CA4-3B Hero promotion restoration source/count drift")
	}
	qualityCounts := map[int64]int{}
	lastRestorationItem := int64(0)
	for _, row := range c.HeroPromotionRestoration.EligibleEquipment {
		if row.EquipmentItemID <= lastRestorationItem || row.SourceQuality < 2 || row.SourceQuality > 6 {
			return errors.New("builtin content: invalid/sort-drift CA4-3B restoration equipment")
		}
		lastRestorationItem = row.EquipmentItemID
		qualityCounts[row.SourceQuality]++
	}
	wantQualityCounts := map[int64]int{2: 35, 3: 35, 4: 65, 5: 42, 6: 18}
	for q, want := range wantQualityCounts {
		if qualityCounts[q] != want {
			return errors.New("builtin content: CA4-3B restoration quality distribution drift")
		}
	}
	wantFractions := []HeroPromotionRestorationFraction{{1, 1, 2}, {8, 3, 3}, {50, 9, 4}, {100, 9, 5}, {200, 9, 6}}
	for i, want := range wantFractions {
		if c.HeroPromotionRestoration.QualityFractions[i] != want {
			return errors.New("builtin content: CA4-3B restoration fraction drift")
		}
	}
	wantDenoms := []HeroPromotionRestorationDenomination{{50001007, 0, 200}, {50001006, 1, 60}, {50001003, 2, 10}}
	for i, want := range wantDenoms {
		if c.HeroPromotionRestoration.Denominations[i] != want {
			return errors.New("builtin content: CA4-3B restoration denomination drift")
		}
	}

	if c.Practice.Source != "CA6 exact src_64 Practice source facts; RNG compatibility policy excluded" || len(c.Practice.Methods) != 3 || len(c.Practice.Locks) != 3 || len(c.Practice.VIPBless) != 16 || len(c.Practice.HeroThresholds) != 1704 || len(c.Practice.PetThresholds) != 162 {
		return errors.New("builtin content: CA6 Practice source/count drift")
	}
	if c.Practice.PolicyFacts.UnlockLevel != 90 || c.Practice.PolicyFacts.AttrCap != 200 || c.Practice.PolicyFacts.FreeIntervalSeconds != 79200 || c.Practice.PolicyFacts.LegendaryVIPMin != 5 || c.Practice.PolicyFacts.TicketItemID != 50001181 || c.Practice.PolicyFacts.TicketAddStr != 1 || c.Practice.PolicyFacts.TicketAddInt != 1 || c.Practice.PolicyFacts.TicketAddAgi != 1 {
		return errors.New("builtin content: CA6 Practice policy source facts drift")
	}
	for i, m := range c.Practice.Methods {
		if m.MethodID != int64(i+1) || m.CurrencyType < 1 || m.CurrencyType > 2 || m.BaseCost < 0 || m.VIPMin < 0 {
			return errors.New("builtin content: invalid CA6 Practice method row")
		}
	}
	for i, l := range c.Practice.Locks {
		if l.LockCount != int64(i+1) || l.ManaStep < 0 || l.CrystalStep < 0 || l.BlessCost < 0 || l.SourceUpLimit < 0 {
			return errors.New("builtin content: invalid CA6 Practice lock row")
		}
	}
	for i, v := range c.Practice.VIPBless {
		if v.VIPLevel != int64(i) || v.BlessValue < 0 {
			return errors.New("builtin content: invalid CA6 Practice VIP Bless row")
		}
	}

	return nil
}

func (c *Catalog) RevisionID() string {
	if c == nil {
		return ""
	}
	return c.Manifest.RevisionID
}

func (c *Catalog) ResourceByDefinitionKey(key string) (ResourceDefinition, bool) {
	if c == nil || key == "" {
		return ResourceDefinition{}, false
	}
	i := sort.Search(len(c.Resources.Resources), func(i int) bool {
		return c.Resources.Resources[i].DefinitionKey >= key
	})
	if i >= len(c.Resources.Resources) || c.Resources.Resources[i].DefinitionKey != key {
		return ResourceDefinition{}, false
	}
	return c.Resources.Resources[i], true
}
