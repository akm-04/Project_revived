// Package events owns event definitions, their time-derived lifecycle and the
// shapes the claim path stores (I11A_EVENTS_V1).
package events

import (
	"bytes"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"strings"

	otadomain "gxb.local/backend/v2/internal/domain/otarelease"
)

// Archetype is the event's behaviour family (I11A_EVENTS_V1 ruling 1).
type Archetype string

const (
	ArchetypeRuleModifier Archetype = "RULE_MODIFIER"
	ArchetypeTieredClaim  Archetype = "TIERED_CLAIM"
	ArchetypeExchange     Archetype = "EXCHANGE"
	ArchetypeDisplay      Archetype = "DISPLAY"
)

// HookCampaignDropMultiplier is the first typed hook (ruling 10, EA-8).
const HookCampaignDropMultiplier = "campaign.drop_multiplier"

var ErrInvalidDefinition = errors.New("events: invalid definition")

// RequirementKind is the per-player condition of a TIERED_CLAIM tier (EA-3).
type RequirementKind string

const RequirementPlayerLevel RequirementKind = "player_level"

type Requirement struct {
	Kind  RequirementKind `json:"kind"`
	Value int64           `json:"value"`
}

const (
	RewardKindItem     = "item"
	RewardKindCurrency = "currency"
	// RewardKindHero grants the character entity of a hero acquisition item
	// (client item type -1), not the scroll item itself (EA-3, 1071 tiers).
	RewardKindHero = "hero"
)

// RewardLine is one grant line of a choice.
type RewardLine struct {
	Kind        string `json:"kind"`
	ItemID      int64  `json:"item_id,omitempty"`
	ResourceKey string `json:"resource_key,omitempty"`
	Amount      int64  `json:"amount"`
}

func (line RewardLine) validate() error {
	if line.Amount <= 0 {
		return fmt.Errorf("%w: reward amount must be positive", ErrInvalidDefinition)
	}
	switch line.Kind {
	case RewardKindItem:
		if line.ItemID <= 0 || line.ResourceKey != "" {
			return fmt.Errorf("%w: an item reward needs item_id and no resource_key", ErrInvalidDefinition)
		}
	case RewardKindCurrency:
		if strings.TrimSpace(line.ResourceKey) == "" || line.ItemID != 0 {
			return fmt.Errorf("%w: a currency reward needs resource_key and no item_id", ErrInvalidDefinition)
		}
	case RewardKindHero:
		if line.ItemID <= 0 || line.ResourceKey != "" || line.Amount != 1 {
			return fmt.Errorf("%w: a hero reward needs one acquisition item and no resource_key", ErrInvalidDefinition)
		}
	default:
		return fmt.Errorf("%w: unknown reward kind %q", ErrInvalidDefinition, line.Kind)
	}
	return nil
}

// Choice is one award option of a tier (EA-3); exactly one of lines or gift_id.
type Choice struct {
	Lines  []RewardLine `json:"lines,omitempty"`
	GiftID int64        `json:"gift_id,omitempty"`
}

func (choice Choice) validate() error {
	if choice.GiftID > 0 {
		if len(choice.Lines) != 0 {
			return fmt.Errorf("%w: a choice carries lines or gift_id, not both", ErrInvalidDefinition)
		}
		return nil
	}
	if len(choice.Lines) == 0 {
		return fmt.Errorf("%w: a choice has no lines and no gift_id", ErrInvalidDefinition)
	}
	for _, line := range choice.Lines {
		if err := line.validate(); err != nil {
			return err
		}
	}
	return nil
}

type Tier struct {
	ID          int64       `json:"id"`
	Requirement Requirement `json:"requirement"`
	Choices     []Choice    `json:"choices"`
}

func (tier Tier) validate() error {
	if tier.ID <= 0 {
		return fmt.Errorf("%w: a tier id must be positive", ErrInvalidDefinition)
	}
	if tier.Requirement.Kind != RequirementPlayerLevel {
		return fmt.Errorf("%w: tier %d has unknown requirement kind %q", ErrInvalidDefinition, tier.ID, tier.Requirement.Kind)
	}
	if tier.Requirement.Value < 0 {
		return fmt.Errorf("%w: tier %d has no requirement", ErrInvalidDefinition, tier.ID)
	}
	if len(tier.Choices) < 1 || len(tier.Choices) > 3 {
		return fmt.Errorf("%w: tier %d needs one to three choices", ErrInvalidDefinition, tier.ID)
	}
	for _, choice := range tier.Choices {
		if err := choice.validate(); err != nil {
			return err
		}
	}
	return nil
}

// Hook is one typed rule-modifier hook (ruling 9, EA-8). The decoder refuses
// fields this server does not understand, so a definition cannot smuggle a
// rule the owner ignores.
type Hook struct {
	Kind       string  `json:"hook"`
	Scope      string  `json:"scope,omitempty"`
	ItemKinds  []int64 `json:"item_kinds,omitempty"`
	Multiplier int64   `json:"multiplier,omitempty"`
}

func (hook Hook) validate() error {
	if strings.TrimSpace(hook.Kind) == "" {
		return fmt.Errorf("%w: a hook needs a kind", ErrInvalidDefinition)
	}
	if hook.Kind != HookCampaignDropMultiplier {
		return nil
	}
	if hook.Scope != "normal" && hook.Scope != "elite" {
		return fmt.Errorf("%w: %s scope must be normal or elite", ErrInvalidDefinition, hook.Kind)
	}
	if hook.Multiplier < 1 {
		return fmt.Errorf("%w: %s needs a multiplier of at least 1", ErrInvalidDefinition, hook.Kind)
	}
	if len(hook.ItemKinds) == 0 {
		return fmt.Errorf("%w: %s needs item_kinds", ErrInvalidDefinition, hook.Kind)
	}
	seen := make(map[int64]struct{}, len(hook.ItemKinds))
	for _, kind := range hook.ItemKinds {
		if kind <= 0 {
			return fmt.Errorf("%w: %s item_kinds must be positive", ErrInvalidDefinition, hook.Kind)
		}
		if _, duplicate := seen[kind]; duplicate {
			return fmt.Errorf("%w: %s repeats item_kind %d", ErrInvalidDefinition, hook.Kind, kind)
		}
		seen[kind] = struct{}{}
	}
	return nil
}

// ClientRequirements is the OTA content an occurrence needs before it may run
// (ruling 4); it maps directly to otarelease.CoversRequest.
type ClientRequirements struct {
	ClientPaths    []string              `json:"client_paths,omitempty"`
	LazyAssets     []otadomain.LazyAsset `json:"lazy_assets,omitempty"`
	MinCodeVersion string                `json:"min_code_version,omitempty"`
}

func (requirements ClientRequirements) validate() error {
	for _, path := range requirements.ClientPaths {
		if strings.TrimSpace(path) == "" {
			return fmt.Errorf("%w: an empty client path", ErrInvalidDefinition)
		}
	}
	for _, asset := range requirements.LazyAssets {
		if strings.TrimSpace(asset.Path) == "" || !validMD5(asset.MD5) {
			return fmt.Errorf("%w: a lazy asset needs a path and a lowercase MD5", ErrInvalidDefinition)
		}
	}
	if requirements.MinCodeVersion != "" {
		if _, err := otadomain.ParseVersion(requirements.MinCodeVersion); err != nil {
			return fmt.Errorf("%w: minimum code version %q: %v", ErrInvalidDefinition, requirements.MinCodeVersion, err)
		}
	}
	return nil
}

func validMD5(text string) bool {
	if len(text) != 32 || strings.ToLower(text) != text {
		return false
	}
	_, err := hex.DecodeString(text)
	return err == nil
}

// CoversRequest is the OTA gate input of this definition.
func (requirements ClientRequirements) CoversRequest() otadomain.CoversRequest {
	return otadomain.CoversRequest{ClientPaths: requirements.ClientPaths, LazyAssets: requirements.LazyAssets, MinCodeVersion: requirements.MinCodeVersion}
}

// Definition is one immutable deployed event revision (ruling 1).
type Definition struct {
	ActivityID         int64              `json:"activity_id"`
	Revision           int64              `json:"revision"`
	Archetype          Archetype          `json:"archetype"`
	Hooks              []Hook             `json:"hooks,omitempty"`
	Tiers              []Tier             `json:"tiers,omitempty"`
	ClientRequirements ClientRequirements `json:"client_requirements"`
	DefaultDays        int64              `json:"default_days"`
}

// ParseDefinition decodes the one strict JSON value a deploy stores.
func ParseDefinition(raw []byte) (Definition, error) {
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.DisallowUnknownFields()
	var definition Definition
	if err := decoder.Decode(&definition); err != nil {
		return Definition{}, fmt.Errorf("%w: %v", ErrInvalidDefinition, err)
	}
	if err := decoder.Decode(&struct{}{}); err == nil {
		return Definition{}, fmt.Errorf("%w: trailing data after the definition", ErrInvalidDefinition)
	}
	if err := definition.Validate(); err != nil {
		return Definition{}, err
	}
	return definition, nil
}

// Validate refuses a definition the server could not schedule or serve.
func (definition Definition) Validate() error {
	if definition.ActivityID <= 0 || definition.ActivityID > math.MaxInt32 {
		return fmt.Errorf("%w: activity_id must be a client table id", ErrInvalidDefinition)
	}
	if definition.Revision <= 0 {
		return fmt.Errorf("%w: revision must be positive", ErrInvalidDefinition)
	}
	switch definition.Archetype {
	case ArchetypeRuleModifier:
		if len(definition.Hooks) == 0 {
			return fmt.Errorf("%w: a RULE_MODIFIER needs at least one hook", ErrInvalidDefinition)
		}
	case ArchetypeTieredClaim:
		if len(definition.Tiers) == 0 {
			return fmt.Errorf("%w: a TIERED_CLAIM needs at least one tier", ErrInvalidDefinition)
		}
	case ArchetypeExchange, ArchetypeDisplay:
	default:
		return fmt.Errorf("%w: unknown archetype %q", ErrInvalidDefinition, definition.Archetype)
	}
	for _, hook := range definition.Hooks {
		if err := hook.validate(); err != nil {
			return err
		}
	}
	seenTiers := make(map[int64]struct{}, len(definition.Tiers))
	for _, tier := range definition.Tiers {
		if err := tier.validate(); err != nil {
			return err
		}
		if _, duplicate := seenTiers[tier.ID]; duplicate {
			return fmt.Errorf("%w: duplicate tier id %d", ErrInvalidDefinition, tier.ID)
		}
		seenTiers[tier.ID] = struct{}{}
	}
	if err := definition.ClientRequirements.validate(); err != nil {
		return err
	}
	return nil
}

// GiftIDs lists the gift ids the deploy must expand (EA-4).
func (definition Definition) GiftIDs() []int64 {
	seen := make(map[int64]struct{})
	var ids []int64
	for _, tier := range definition.Tiers {
		for _, choice := range tier.Choices {
			if choice.GiftID <= 0 {
				continue
			}
			if _, duplicate := seen[choice.GiftID]; duplicate {
				continue
			}
			seen[choice.GiftID] = struct{}{}
			ids = append(ids, choice.GiftID)
		}
	}
	return ids
}

// ExpandGift replaces every choice of giftID with the content's lines, so the
// stored revision never needs the gift row again.
func (definition Definition) ExpandGift(giftID int64, lines []RewardLine) {
	for tierIndex := range definition.Tiers {
		for choiceIndex := range definition.Tiers[tierIndex].Choices {
			choice := &definition.Tiers[tierIndex].Choices[choiceIndex]
			if choice.GiftID != giftID {
				continue
			}
			choice.Lines = append([]RewardLine(nil), lines...)
			choice.GiftID = 0
		}
	}
}

// HooksOfKind lists the hooks of one kind (the scheduling gate and the
// ActiveModifiers read use it).
func (definition Definition) HooksOfKind(kind string) []Hook {
	var out []Hook
	for _, hook := range definition.Hooks {
		if hook.Kind == kind {
			out = append(out, hook)
		}
	}
	return out
}

// Body is the canonical stored form of the definition.
func (definition Definition) Body() ([]byte, error) {
	return json.Marshal(definition)
}
