// Package adventure owns Adventure event occurrences, their trigger rule and
// lifetime, the defense try counter, and the attestation bounds of its solo
// fights. Rooms and awards stay with SharedRoom and I5.
package adventure

import (
	"errors"
	"slices"

	"gxb.local/backend/v2/internal/domain/objective"
)

const (
	ContractID    = "I9_ADVENTURE_V1"
	PolicyID      = "I9_ADVENTURE_POLICY_V1"
	PolicyVersion = 1

	FunctionID       = 68
	OpenAcademyLevel = 11
	FantasyOpenLevel = 65

	EventDefense  int64 = 10001
	EventFavor    int64 = 10002
	EventShop     int64 = 10003
	EventBattle   int64 = 10004
	EventSummon   int64 = 10005
	EventIllusion int64 = 10006

	SweepFactKind    = objective.CampaignSweepKind
	BattleFactKind   = objective.PVPFightKind
	SummonFactKind   = "SUMMON"
	IllusionFactKind = "FANTASY"

	DefenseRoomCapacity     = 6
	DefenseMonsterCount     = 3
	DefenseTriesPerPosition = 3
	LevelBand               = 5
	DefenseSelectionSeconds = 60
	DefenseBattleSeconds    = 90
	PVPRankingSection       = 3
	FavorExtra              = 100
	FavorLimit              = 2000
	IllusionChallengeTimes  = 1
	IllusionHiddenBoss      = 100011
	IllusionTotalDamage     = 5000000
	MaxSoloStar             = 1
	MaxTriggerRate          = 100
)

// OccurrenceLockRank sits above every I5 rank (the frozen maximum is the
// directory rank 740, D369); the observer only inserts this family's rows and
// never waits on another family lock.
const OccurrenceLockRank uint16 = 750

var (
	ErrInvalid     = errors.New("adventure invalid request")
	ErrRefused     = errors.New("adventure refused")
	ErrExpired     = errors.New("adventure occurrence expired")
	ErrUnavailable = errors.New("adventure unavailable")
)

// Event is one adventure_event row plus the trigger fields the server owns.
type Event struct {
	ID                int64  `json:"id"`
	Title             string `json:"title"`
	Description       string `json:"description"`
	Rate              int64  `json:"rate"`
	TimeLimitSeconds  int64  `json:"time_limit_seconds"`
	WindowName        string `json:"window_name"`
	TitlePicture      string `json:"title_picture"`
	TitleBackground   string `json:"title_background"`
	ContentBackground string `json:"content_background"`
}

var sourceEvents = [...]Event{
	{ID: EventDefense, Rate: 3, TimeLimitSeconds: 10800, WindowName: "adventure_defense"},
	{ID: EventFavor, Rate: 1, TimeLimitSeconds: 3600, WindowName: "adventure_favor"},
	{ID: EventShop, Rate: 6, TimeLimitSeconds: 3600, WindowName: "adventure_shop"},
	{ID: EventBattle, Rate: 7, TimeLimitSeconds: 7200, WindowName: "adventure_battle"},
	{ID: EventSummon, Rate: 4, TimeLimitSeconds: 3600, WindowName: "adventure_summon"},
	{ID: EventIllusion, Rate: 10, TimeLimitSeconds: 10800, WindowName: "adventure_illusion"},
}

// Profile answers the source trigger profile of one event type.
func Profile(id int64) (Event, bool) {
	index := slices.IndexFunc(sourceEvents[:], func(event Event) bool { return event.ID == id })
	if index < 0 {
		return Event{}, false
	}
	return sourceEvents[index], true
}

// EventForFactKind is the one fact-kind to event map. 10002 and 10003 have no
// producer yet (C4, D368) and are deliberately absent.
func EventForFactKind(kind string) (Event, bool) {
	switch kind {
	case SweepFactKind:
		return Profile(EventDefense)
	case BattleFactKind:
		return Profile(EventBattle)
	case SummonFactKind:
		return Profile(EventSummon)
	case IllusionFactKind:
		return Profile(EventIllusion)
	default:
		return Event{}, false
	}
}

type ShopItem struct {
	ID    int64 `json:"id"`
	Item  int64 `json:"item"`
	Price int64 `json:"price"`
	Rate  int64 `json:"rate"`
}

type CardItem struct {
	ID    int64 `json:"id"`
	Item  int64 `json:"item"`
	Price int64 `json:"price"`
	Rate  int64 `json:"rate"`
}

type Gift struct {
	ID       int64   `json:"id"`
	Items    []int64 `json:"items"`
	ItemNums []int64 `json:"item_nums"`
}

type DefenseCampaign struct {
	ID           int64   `json:"id"`
	MinimumLevel int64   `json:"minimum_level"`
	MaximumLevel int64   `json:"maximum_level"`
	BattleIDs    []int64 `json:"battle_ids"`
	Gift         int64   `json:"gift"`
	Models       []int64 `json:"models"`
}

type Limits struct {
	DefenseTriesPerPosition     int64   `json:"defense_tries_per_position"`
	DefenseLevelBand            int64   `json:"defense_level_band"`
	DefenseSelectionSeconds     int64   `json:"defense_selection_seconds"`
	DefenseRoomCapacity         int64   `json:"defense_room_capacity"`
	DefenseMonsterCount         int64   `json:"defense_monster_count"`
	DefenseBattleSeconds        int64   `json:"defense_battle_seconds"`
	PVPRankingSection           int64   `json:"pvp_ranking_section"`
	FavorExtra                  int64   `json:"favor_extra"`
	FavorLimit                  int64   `json:"favor_limit"`
	IllusionChallengeTimes      int64   `json:"illusion_challenge_times"`
	IllusionHiddenBoss          int64   `json:"illusion_hidden_boss"`
	IllusionGiftSingle          int64   `json:"illusion_gift_single"`
	IllusionGiftCoop            int64   `json:"illusion_gift_coop"`
	IllusionTotalDamage         int64   `json:"illusion_total_damage"`
	IllusionAliceChallengeTimes int64   `json:"illusion_alice_challenge_times"`
	MonsterTotalChallengeTimes  int64   `json:"monster_total_challenge_times"`
	MonsterDamageParameter      int64   `json:"monster_damage_parameter"`
	IllusionCoinsReward         int64   `json:"illusion_coins_reward"`
	IllusionManaReward          string  `json:"illusion_mana_reward"`
	PVPGift                     int64   `json:"pvp_gift"`
	FavorGiftRandom             []int64 `json:"favor_gift_random"`
	SweepCardItem               int64   `json:"sweep_card_item"`
}

type Catalog struct {
	Schema           int               `json:"schema_version"`
	Contract         string            `json:"contract_id"`
	PolicyID         string            `json:"policy_id"`
	PolicyVersion    int               `json:"policy_version"`
	OpenAcademyLevel int64             `json:"open_academy_level"`
	FantasyOpenLevel int64             `json:"fantasy_open_level"`
	Events           []Event           `json:"events"`
	Shop             []ShopItem        `json:"shop"`
	Cards            []CardItem        `json:"cards"`
	Campaigns        []DefenseCampaign `json:"campaigns"`
	Gifts            []Gift            `json:"gifts"`
	Limits           Limits            `json:"limits"`
}

func (c Catalog) Validate() error {
	if c.Schema != 1 || c.Contract != ContractID || c.PolicyID != PolicyID || c.PolicyVersion != PolicyVersion {
		return ErrUnavailable
	}
	if c.OpenAcademyLevel != OpenAcademyLevel || c.FantasyOpenLevel != FantasyOpenLevel {
		return ErrUnavailable
	}
	if len(c.Events) != len(sourceEvents) || len(c.Shop) != 7 || len(c.Cards) != 72 || len(c.Campaigns) != 19 || len(c.Gifts) != 21 {
		return ErrUnavailable
	}
	for index, event := range c.Events {
		if event.ID != sourceEvents[index].ID || event.Rate != sourceEvents[index].Rate || event.TimeLimitSeconds != sourceEvents[index].TimeLimitSeconds || event.WindowName != sourceEvents[index].WindowName {
			return ErrUnavailable
		}
	}
	for _, item := range c.Shop {
		if item.ID <= 0 || item.Item <= 0 || item.Price <= 0 || item.Rate <= 0 {
			return ErrUnavailable
		}
	}
	for _, card := range c.Cards {
		if card.ID <= 0 || card.Item <= 0 || card.Price <= 0 || card.Rate < 0 {
			return ErrUnavailable
		}
	}
	for _, campaign := range c.Campaigns {
		if campaign.ID <= 0 || campaign.MinimumLevel > campaign.MaximumLevel || len(campaign.BattleIDs) != DefenseMonsterCount || len(campaign.Models) != DefenseMonsterCount || campaign.Gift <= 0 {
			return ErrUnavailable
		}
	}
	for _, gift := range c.Gifts {
		if gift.ID <= 0 || len(gift.Items) == 0 || len(gift.Items) != len(gift.ItemNums) {
			return ErrUnavailable
		}
	}
	if !c.Limits.matchesSource() {
		return ErrUnavailable
	}
	return nil
}

func (l Limits) matchesSource() bool {
	if l.DefenseTriesPerPosition != DefenseTriesPerPosition || l.DefenseLevelBand != LevelBand || l.DefenseSelectionSeconds != DefenseSelectionSeconds {
		return false
	}
	if l.DefenseRoomCapacity != DefenseRoomCapacity || l.DefenseMonsterCount != DefenseMonsterCount || l.DefenseBattleSeconds != DefenseBattleSeconds {
		return false
	}
	if l.PVPRankingSection != PVPRankingSection || l.FavorExtra != FavorExtra || l.FavorLimit != FavorLimit {
		return false
	}
	if l.IllusionChallengeTimes != IllusionChallengeTimes || l.IllusionHiddenBoss != IllusionHiddenBoss || l.IllusionTotalDamage != IllusionTotalDamage {
		return false
	}
	if l.IllusionManaReward != "0.2" || len(l.FavorGiftRandom) != 9 || l.SweepCardItem <= 0 {
		return false
	}
	return true
}

// ShopEntry answers one adventure_shop row; a client price is never an input
// (C8).
func (c Catalog) ShopEntry(id int64) (ShopItem, bool) {
	index := slices.IndexFunc(c.Shop, func(item ShopItem) bool { return item.ID == id })
	if index < 0 {
		return ShopItem{}, false
	}
	return c.Shop[index], true
}

// CardEntry answers one adventure_cards_dropbox row (C8).
func (c Catalog) CardEntry(id int64) (CardItem, bool) {
	index := slices.IndexFunc(c.Cards, func(card CardItem) bool { return card.ID == id })
	if index < 0 {
		return CardItem{}, false
	}
	return c.Cards[index], true
}

// ShopPrice is the server price of an adventure_shop id; a client number is
// never an input (C8).
func (c Catalog) ShopPrice(id int64) (int64, bool) {
	index := slices.IndexFunc(c.Shop, func(item ShopItem) bool { return item.ID == id })
	if index < 0 {
		return 0, false
	}
	return c.Shop[index].Price, true
}

// Gift answers the source award vector of a gift row; awards are granted
// through I5, never written by this family.
func (c Catalog) Gift(id int64) (Gift, bool) {
	index := slices.IndexFunc(c.Gifts, func(gift Gift) bool { return gift.ID == id })
	if index < 0 {
		return Gift{}, false
	}
	return c.Gifts[index], true
}

// CardPrice is the server price of an adventure_cards_dropbox id (C8).
func (c Catalog) CardPrice(id int64) (int64, bool) {
	index := slices.IndexFunc(c.Cards, func(card CardItem) bool { return card.ID == id })
	if index < 0 {
		return 0, false
	}
	return c.Cards[index].Price, true
}

// ClampSolo bounds one reported solo result: star 0..1 and damage to the pool
// left, as C6 requires for the attested 2421/2422 summary.
func ClampSolo(star, damage, poolHP, poolHurt int64) (int64, int64) {
	if star < 0 {
		star = 0
	}
	if star > MaxSoloStar {
		star = MaxSoloStar
	}
	if damage <= 0 || poolHP <= 0 || poolHurt < 0 || poolHP <= poolHurt {
		return star, 0
	}
	remaining := poolHP - poolHurt
	if damage > remaining {
		damage = remaining
	}
	return star, damage
}

// IsWin is the C7 rule: the adventure fight reply carries is_win as star>0.
func IsWin(star int64) bool { return star > 0 }
