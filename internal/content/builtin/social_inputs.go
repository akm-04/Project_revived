package builtin

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
)

// Social content is pure source data. Domain binding belongs to contentstore,
// keeping the accepted content/application boundary intact.
const (
	socialSchemaVersion              = 2
	SocialExchangeLimit              = 10
	socialWeightTotal                = 10000
	socialExpectedProducts           = 3
	socialExpectedDropboxes          = 3
	socialExpectedDropboxRolls       = 52
	socialExpectedRecallMilestones   = 25
	socialExpectedGifts              = 28
	socialExpectedInvitationMissions = 250
	socialExpectedRewardItems        = 59
)

var ErrSocialUnqualified = errors.New("social content: unqualified payload")

type SocialInputCatalog struct {
	SchemaVersion      int                       `json:"schema_version"`
	ExchangeLimit      int64                     `json:"exchange_limit"`
	RecallRules        *SocialRecallRules        `json:"recall_rules,omitempty"`
	ExchangeProducts   []SocialExchangeProduct   `json:"exchange_products"`
	Dropboxes          []SocialDropbox           `json:"dropboxes"`
	RecallMilestones   []SocialRecallMilestone   `json:"recall_milestones"`
	Gifts              []SocialGift              `json:"gifts"`
	InvitationMissions []SocialInvitationMission `json:"invitation_missions"`
}

type SocialRecallRules struct {
	OfflineDays    int64 `json:"offline_days"`
	TaskDays       int64 `json:"task_days"`
	MaxActiveTasks int64 `json:"max_active_tasks"`
}

func (rules SocialRecallRules) Validate() error {
	if rules.OfflineDays != 7 || rules.TaskDays != 3 || rules.MaxActiveTasks != 3 {
		return socialError("recall settings drift")
	}
	return nil
}

type SocialExchangeProduct struct {
	ID        int64 `json:"id"`
	GiftID    int64 `json:"gift_id"`
	SellType  int64 `json:"sell_type"`
	SellPrice int64 `json:"sell_price"`
	ShowItem  int64 `json:"show_item"`
}

type SocialDropbox struct {
	ID    int64               `json:"id"`
	Rolls []SocialDropboxRoll `json:"rolls"`
}

type SocialDropboxRoll struct {
	ID       int64 `json:"id"`
	ItemID   int64 `json:"item_id"`
	ItemNum  int64 `json:"item_num"`
	DropRate int64 `json:"drop_rate"`
	RollType int64 `json:"roll_type"`
}

type SocialRecallMilestone struct {
	ID        int64 `json:"id"`
	Type      int64 `json:"type"`
	Condition int64 `json:"condition"`
	GiftID    int64 `json:"gift_id"`
}

type SocialGift struct {
	ID      int64            `json:"id"`
	Crystal int64            `json:"crystal"`
	Items   []SocialGiftItem `json:"items"`
	Drops   []int64          `json:"drops"`
}

type SocialGiftItem struct {
	ItemID   int64 `json:"item_id"`
	Quantity int64 `json:"quantity"`
}

type SocialInvitationMission struct {
	ID              int64   `json:"id"`
	Type            int64   `json:"type"`
	RequiredCount   int64   `json:"required_count"`
	Threshold       int64   `json:"threshold"`
	Diamond         int64   `json:"diamond"`
	Requirement     int64   `json:"requirement"`
	Extra           int64   `json:"extra"`
	PreviousTaskIDs []int64 `json:"previous_task_ids"`
	NextTaskIDs     []int64 `json:"next_task_ids"`
}

func DecodeSocialInputCatalog(raw []byte) (SocialInputCatalog, error) {
	var catalog SocialInputCatalog
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&catalog); err != nil {
		return SocialInputCatalog{}, fmt.Errorf("%w: %v", ErrSocialUnqualified, err)
	}
	if err := decoder.Decode(&struct{}{}); err != io.EOF {
		return SocialInputCatalog{}, fmt.Errorf("%w: trailing data", ErrSocialUnqualified)
	}
	if err := catalog.Validate(); err != nil {
		return SocialInputCatalog{}, err
	}
	return catalog, nil
}

func (c SocialInputCatalog) Validate() error {
	if (c.SchemaVersion != 1 && c.SchemaVersion != socialSchemaVersion) || c.ExchangeLimit != SocialExchangeLimit {
		return socialError("schema version or exchange limit")
	}
	if c.SchemaVersion == 1 && c.RecallRules != nil {
		return socialError("legacy schema cannot carry recall settings")
	}
	if c.SchemaVersion == socialSchemaVersion && (c.RecallRules == nil || c.RecallRules.Validate() != nil) {
		return socialError("missing or invalid recall settings")
	}
	if len(c.ExchangeProducts) != socialExpectedProducts || len(c.Dropboxes) != socialExpectedDropboxes {
		return socialError("exchange product or dropbox count")
	}
	if len(c.RecallMilestones) != socialExpectedRecallMilestones || len(c.Gifts) != socialExpectedGifts {
		return socialError("recall milestone or gift count")
	}
	if len(c.InvitationMissions) != socialExpectedInvitationMissions {
		return socialError("invitation mission count")
	}
	gifts, err := validateSocialGifts(c.Gifts)
	if err != nil {
		return err
	}
	dropboxes, rollCount, err := validateSocialDropboxes(c.Dropboxes)
	if err != nil {
		return err
	}
	if rollCount != socialExpectedDropboxRolls {
		return socialError("dropbox weighted row count")
	}
	if err := validateSocialProducts(c.ExchangeProducts, gifts); err != nil {
		return err
	}
	if err := validateSocialRecallMilestones(c.RecallMilestones, gifts); err != nil {
		return err
	}
	if err := validateSocialGiftReferences(c.ExchangeProducts, c.RecallMilestones, gifts, dropboxes); err != nil {
		return err
	}
	if err := validateSocialInvitationMissions(c.InvitationMissions); err != nil {
		return err
	}
	return validateSocialRewardItems(dropboxes, gifts)
}

func socialError(format string, arguments ...any) error {
	return fmt.Errorf("%w: "+format, append([]any{ErrSocialUnqualified}, arguments...)...)
}

func validateSocialProducts(products []SocialExchangeProduct, gifts map[int64]SocialGift) error {
	identifiers := make(map[int64]struct{}, len(products))
	giftIdentifiers := make(map[int64]struct{}, len(products))
	for _, product := range products {
		if product.ID <= 0 || product.GiftID <= 0 || product.SellType != 19 || product.SellPrice <= 0 || product.ShowItem <= 0 {
			return socialError("exchange product %d fields", product.ID)
		}
		if _, duplicate := identifiers[product.ID]; duplicate {
			return socialError("duplicate exchange product %d", product.ID)
		}
		identifiers[product.ID] = struct{}{}
		if _, duplicate := giftIdentifiers[product.GiftID]; duplicate {
			return socialError("duplicate exchange gift %d", product.GiftID)
		}
		giftIdentifiers[product.GiftID] = struct{}{}
		gift, found := gifts[product.GiftID]
		if !found {
			return socialError("exchange product %d references missing gift %d", product.ID, product.GiftID)
		}
		if len(gift.Drops) != 1 || gift.Crystal != 0 || len(gift.Items) != 0 {
			return socialError("exchange gift %d is not a single dropbox", product.GiftID)
		}
	}
	if err := requireSocialIdentities(identifiers, []int64{1, 2, 3}, "exchange product"); err != nil {
		return err
	}
	return nil
}

func validateSocialGifts(gifts []SocialGift) (map[int64]SocialGift, error) {
	byID := make(map[int64]SocialGift, len(gifts))
	for _, gift := range gifts {
		if gift.ID <= 0 || gift.Crystal < 0 {
			return nil, socialError("gift %d fields", gift.ID)
		}
		if _, duplicate := byID[gift.ID]; duplicate {
			return nil, socialError("duplicate gift %d", gift.ID)
		}
		for _, item := range gift.Items {
			if item.ItemID <= 0 || item.Quantity <= 0 {
				return nil, socialError("gift %d item quantity", gift.ID)
			}
		}
		if len(gift.Drops) != 0 && (gift.Crystal != 0 || len(gift.Items) != 0) {
			return nil, socialError("gift %d mixes drops with direct rewards", gift.ID)
		}
		if len(gift.Drops) == 0 && gift.Crystal == 0 && len(gift.Items) == 0 {
			return nil, socialError("gift %d has no reward channel", gift.ID)
		}
		drops := make(map[int64]struct{}, len(gift.Drops))
		for _, dropboxID := range gift.Drops {
			if dropboxID <= 0 {
				return nil, socialError("gift %d dropbox identity", gift.ID)
			}
			if _, duplicate := drops[dropboxID]; duplicate {
				return nil, socialError("gift %d duplicate dropbox %d", gift.ID, dropboxID)
			}
			drops[dropboxID] = struct{}{}
		}
		byID[gift.ID] = gift
	}
	return byID, nil
}

func validateSocialDropboxes(dropboxes []SocialDropbox) (map[int64]SocialDropbox, int, error) {
	byID := make(map[int64]SocialDropbox, len(dropboxes))
	identifiers := make(map[int64]struct{}, len(dropboxes))
	rollIdentifiers := make(map[int64]struct{})
	rollCount := 0
	for _, dropbox := range dropboxes {
		if dropbox.ID <= 0 || len(dropbox.Rolls) == 0 {
			return nil, 0, socialError("dropbox %d fields", dropbox.ID)
		}
		identifiers[dropbox.ID] = struct{}{}
		if _, duplicate := byID[dropbox.ID]; duplicate {
			return nil, 0, socialError("duplicate dropbox %d", dropbox.ID)
		}
		items := make(map[int64]struct{}, len(dropbox.Rolls))
		total := int64(0)
		for _, roll := range dropbox.Rolls {
			if roll.ID <= 0 || roll.ItemID <= 0 || roll.ItemNum <= 0 || roll.DropRate < 0 || roll.DropRate > socialWeightTotal || roll.RollType != 1 {
				return nil, 0, socialError("dropbox %d roll %d fields", dropbox.ID, roll.ID)
			}
			if _, duplicate := rollIdentifiers[roll.ID]; duplicate {
				return nil, 0, socialError("duplicate dropbox roll %d", roll.ID)
			}
			rollIdentifiers[roll.ID] = struct{}{}
			if _, duplicate := items[roll.ItemID]; duplicate {
				return nil, 0, socialError("dropbox %d duplicate outcome item %d", dropbox.ID, roll.ItemID)
			}
			items[roll.ItemID] = struct{}{}
			total += roll.DropRate
		}
		if total != socialWeightTotal {
			return nil, 0, socialError("dropbox %d weights", dropbox.ID)
		}
		byID[dropbox.ID] = dropbox
		rollCount += len(dropbox.Rolls)
	}
	if err := requireSocialIdentities(identifiers, []int64{510001, 510002, 510003}, "dropbox"); err != nil {
		return nil, 0, err
	}
	return byID, rollCount, nil
}

func validateSocialRecallMilestones(milestones []SocialRecallMilestone, gifts map[int64]SocialGift) error {
	identifiers := make(map[int64]struct{}, len(milestones))
	typeCounts := map[int64]int{}
	for _, milestone := range milestones {
		if milestone.ID <= 0 || milestone.Type < 1 || milestone.Type > 4 || milestone.Condition <= 0 || milestone.GiftID <= 0 {
			return socialError("recall milestone %d fields", milestone.ID)
		}
		if _, duplicate := identifiers[milestone.ID]; duplicate {
			return socialError("duplicate recall milestone %d", milestone.ID)
		}
		identifiers[milestone.ID] = struct{}{}
		typeCounts[milestone.Type]++
		gift, found := gifts[milestone.GiftID]
		if !found {
			return socialError("recall milestone %d references missing gift %d", milestone.ID, milestone.GiftID)
		}
		if len(gift.Drops) != 0 {
			return socialError("recall milestone %d gift %d is an exchange dropbox", milestone.ID, milestone.GiftID)
		}
	}
	expected := make([]int64, 0, socialExpectedRecallMilestones)
	for identifier := int64(100001); identifier < 100001+socialExpectedRecallMilestones; identifier++ {
		expected = append(expected, identifier)
	}
	if err := requireSocialIdentities(identifiers, expected, "recall milestone"); err != nil {
		return err
	}
	if typeCounts[1] != 4 || typeCounts[2] != 2 || typeCounts[3] != 4 || typeCounts[4] != 15 {
		return socialError("recall milestone type counts")
	}
	return nil
}

func validateSocialInvitationMissions(missions []SocialInvitationMission) error {
	identifiers := make(map[int64]struct{}, len(missions))
	previous := make(map[int64][]int64, len(missions))
	following := make(map[int64][]int64, len(missions))
	typeCounts := map[int64]int{}
	for _, mission := range missions {
		if mission.ID <= 0 || mission.Type < 1 || mission.Type > 4 || mission.RequiredCount < 1 || mission.RequiredCount > 10 {
			return socialError("invitation mission %d fields", mission.ID)
		}
		if mission.Type == 1 && mission.Threshold != 0 {
			return socialError("invitation mission %d type 1 threshold", mission.ID)
		}
		if mission.Type != 1 && mission.Threshold < 1 {
			return socialError("invitation mission %d threshold", mission.ID)
		}
		if mission.Diamond <= 0 || mission.Requirement != 0 || (mission.Extra != 0 && mission.Extra != 1) {
			return socialError("invitation mission %d metadata", mission.ID)
		}
		if _, duplicate := identifiers[mission.ID]; duplicate {
			return socialError("duplicate invitation mission %d", mission.ID)
		}
		identifiers[mission.ID] = struct{}{}
		typeCounts[mission.Type]++
		if err := uniqueSocialReferences(mission.PreviousTaskIDs); err != nil {
			return socialError("invitation mission %d previous references", mission.ID)
		}
		if err := uniqueSocialReferences(mission.NextTaskIDs); err != nil {
			return socialError("invitation mission %d next references", mission.ID)
		}
		previous[mission.ID] = mission.PreviousTaskIDs
		following[mission.ID] = mission.NextTaskIDs
	}
	expected := make([]int64, 0, socialExpectedInvitationMissions)
	for identifier := int64(100001); identifier < 100001+socialExpectedInvitationMissions; identifier++ {
		expected = append(expected, identifier)
	}
	if err := requireSocialIdentities(identifiers, expected, "invitation mission"); err != nil {
		return err
	}
	if typeCounts[1] != 10 || typeCounts[2] != 40 || typeCounts[3] != 50 || typeCounts[4] != 150 {
		return socialError("invitation mission type counts")
	}
	return validateSocialMissionGraph(identifiers, previous, following)
}

func validateSocialMissionGraph(identifiers map[int64]struct{}, previous, following map[int64][]int64) error {
	for missionID := range identifiers {
		for _, target := range following[missionID] {
			if _, found := identifiers[target]; !found || target == missionID {
				return socialError("invitation mission %d next reference %d", missionID, target)
			}
		}
		for _, source := range previous[missionID] {
			if _, found := identifiers[source]; !found || source == missionID {
				return socialError("invitation mission %d previous reference %d", missionID, source)
			}
		}
	}
	for missionID := range identifiers {
		expected := map[int64]struct{}{}
		for source, targets := range previous {
			for _, target := range targets {
				if target == missionID {
					expected[source] = struct{}{}
				}
			}
		}
		actual := map[int64]struct{}{}
		for _, source := range following[missionID] {
			actual[source] = struct{}{}
		}
		if len(expected) != len(actual) {
			return socialError("invitation mission %d graph edges are asymmetric", missionID)
		}
		for source := range expected {
			if _, found := actual[source]; !found {
				return socialError("invitation mission %d graph edges are asymmetric", missionID)
			}
		}
	}
	remaining := make(map[int64]int, len(identifiers))
	ready := make([]int64, 0, len(identifiers))
	for missionID := range identifiers {
		remaining[missionID] = len(previous[missionID])
		if remaining[missionID] == 0 {
			ready = append(ready, missionID)
		}
	}
	visited := 0
	for len(ready) != 0 {
		current := ready[0]
		ready = ready[1:]
		visited++
		for _, target := range following[current] {
			remaining[target]--
			if remaining[target] == 0 {
				ready = append(ready, target)
			}
		}
	}
	if visited != len(identifiers) {
		return socialError("invitation mission graph contains a cycle")
	}
	return nil
}

func validateSocialGiftReferences(products []SocialExchangeProduct, milestones []SocialRecallMilestone, gifts map[int64]SocialGift, dropboxes map[int64]SocialDropbox) error {
	referencedDropboxes := make(map[int64]struct{}, len(dropboxes))
	productGifts := make(map[int64]struct{}, len(products))
	referenced := make(map[int64]struct{}, len(products)+len(milestones))
	for _, product := range products {
		productGifts[product.GiftID] = struct{}{}
		referenced[product.GiftID] = struct{}{}
	}
	for _, milestone := range milestones {
		referenced[milestone.GiftID] = struct{}{}
	}
	if len(referenced) != len(gifts) {
		return socialError("gift reference count")
	}
	for giftID, gift := range gifts {
		for _, dropboxID := range gift.Drops {
			if _, found := dropboxes[dropboxID]; !found {
				return socialError("gift %d references missing dropbox %d", giftID, dropboxID)
			}
			referencedDropboxes[dropboxID] = struct{}{}
		}
		if _, found := referenced[giftID]; !found {
			return socialError("unreferenced gift %d", giftID)
		}
		if len(gift.Drops) != 0 {
			if _, found := productGifts[giftID]; !found {
				return socialError("gift %d drops outside an exchange product", giftID)
			}
		}
	}
	if len(referencedDropboxes) != len(dropboxes) {
		return socialError("unreferenced exchange dropbox")
	}
	return nil
}

func validateSocialRewardItems(dropboxes map[int64]SocialDropbox, gifts map[int64]SocialGift) error {
	rewardItems := make(map[int64]struct{})
	for _, dropbox := range dropboxes {
		for _, roll := range dropbox.Rolls {
			rewardItems[roll.ItemID] = struct{}{}
		}
	}
	for _, gift := range gifts {
		for _, item := range gift.Items {
			rewardItems[item.ItemID] = struct{}{}
		}
	}
	if len(rewardItems) != socialExpectedRewardItems {
		return socialError("reward item count")
	}
	for rewardItem := range rewardItems {
		if _, isGift := gifts[rewardItem]; isGift {
			return socialError("reward item %d collides with a gift identity", rewardItem)
		}
	}
	return nil
}

func uniqueSocialReferences(identifiers []int64) error {
	seen := make(map[int64]struct{}, len(identifiers))
	for _, identifier := range identifiers {
		if identifier <= 0 {
			return socialError("non-positive graph reference")
		}
		if _, duplicate := seen[identifier]; duplicate {
			return socialError("duplicate graph reference")
		}
		seen[identifier] = struct{}{}
	}
	return nil
}

func requireSocialIdentities(actual map[int64]struct{}, expected []int64, label string) error {
	if len(actual) != len(expected) {
		return socialError("%s identities", label)
	}
	for _, identifier := range expected {
		if _, found := actual[identifier]; !found {
			return socialError("%s identities", label)
		}
	}
	return nil
}
