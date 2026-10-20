package player

import (
	"errors"
	"math"
	"strings"
	"time"
	"unicode/utf8"
)

const DisplayPolicy = "PLAYER_DISPLAY_V1"

var ErrDisplay = errors.New("invalid player display")
var ErrDisplayUnavailable = errors.New("player display origin unavailable")

// Catalog metadata is not ownership. Icon, catalog identity and picker category
// are separate, including the historical bootstrap display that has no descriptor.
type Cosmetic struct {
	Family    string `json:"family"`
	ID        int64  `json:"id"`
	Icon      int64  `json:"icon"`
	Type      int64  `json:"type"`
	PartnerID int64  `json:"partner_id"`
	Days      int64  `json:"days"`
	VIP       int64  `json:"vip"`
	Price     int64  `json:"price"`
	// Condition is the title_system condition list; other families carry none.
	Condition []int64 `json:"condition,omitempty"`
}
type DisplayHeroTemplate struct {
	TableID      int64  `json:"table_id"`
	BeforeAwaken int64  `json:"before_awaken"`
	Kind         string `json:"kind"`
}
type DisplayCatalog struct {
	HeroTemplates []DisplayHeroTemplate `json:"hero_templates"`
	SchemaVersion int                   `json:"schema_version"`
	PolicyID      string                `json:"policy_id"`
	RenameCost    int64                 `json:"rename_cost"`
	DefaultAvatar int64                 `json:"default_avatar"`
	DefaultFrame  int64                 `json:"default_frame"`
	DefaultBubble int64                 `json:"default_bubble"`
	Cosmetics     []Cosmetic            `json:"cosmetics"`
	Names         []string              `json:"names"`
	Words         []string              `json:"words"`
	Collection    []int64               `json:"collection"`
}

func (p DisplayCatalog) Find(family string, id int64) (Cosmetic, bool) {
	for _, v := range p.Cosmetics {
		if v.Family == family && v.ID == id {
			return v, true
		}
	}
	return Cosmetic{}, false
}
func (p DisplayCatalog) Validate() error {
	if p.SchemaVersion != 1 || p.PolicyID != DisplayPolicy || p.RenameCost != 100 || len(p.Names) != 12 || len(p.Words) == 0 || len(p.Collection) != 4 {
		return ErrDisplay
	}
	seen := map[string]map[int64]bool{}
	for _, v := range p.Cosmetics {
		if v.Family != "avatar" && v.Family != "frame" && v.Family != "title" && v.Family != "bubble" {
			return ErrDisplay
		}
		if v.ID <= 0 || v.ID > 9007199254740991 || v.Icon < 0 || v.Type < 0 || v.PartnerID < 0 || v.Price < 0 {
			return ErrDisplay
		}
		if seen[v.Family] == nil {
			seen[v.Family] = map[int64]bool{}
		}
		if seen[v.Family][v.ID] {
			return ErrDisplay
		}
		seen[v.Family][v.ID] = true
	}
	a, ok := p.Find("avatar", p.DefaultAvatar)
	if !ok || a.Type != 1 || a.Icon <= 0 {
		return ErrDisplay
	}
	f, ok := p.Find("frame", p.DefaultFrame)
	if !ok || f.Type != 1 {
		return ErrDisplay
	}
	if _, ok = p.Find("bubble", p.DefaultBubble); !ok {
		return ErrDisplay
	}
	for _, n := range p.Names {
		if p.ValidateName(n) != nil {
			return ErrDisplay
		}
	}
	return nil
}
func (p DisplayCatalog) ValidateName(n string) error {
	if !utf8.ValidString(n) || strings.ContainsRune(n, 0) || utf8.RuneCountInString(n) < 2 || utf8.RuneCountInString(n) > 16 {
		return ErrDisplay
	}
	for _, word := range p.Words {
		if word != "" && strings.Contains(n, word) {
			return ErrDisplay
		}
	}
	return nil
}

// EndTime returns the source-family validity, never an acquisition-time guess.
// A nil StartsAt means the explicitly qualified no-start inventory branch.
func (c Cosmetic) EndTime(starts *time.Time, end int64) (int64, error) {
	switch c.Family {
	case "title", "bubble":
		if end <= 0 {
			return 0, nil
		}
		return end, nil
	case "avatar":
		if starts == nil || c.Days == -1 {
			return 0, nil
		}
		if c.Days <= 0 || starts.IsZero() {
			return 0, ErrDisplay
		}
	case "frame":
		if starts == nil || c.Days <= 0 {
			return 0, nil
		}
		if starts.IsZero() {
			return 0, ErrDisplay
		}
	default:
		return 0, ErrDisplay
	}
	sec := starts.Unix()
	if sec <= 0 || c.Days > math.MaxInt64/86400 || sec > math.MaxInt64-c.Days*86400 {
		return 0, ErrDisplay
	}
	return sec + c.Days*86400, nil
}
func EligibleAt(end int64, at time.Time) bool { return !at.IsZero() && (end <= 0 || at.Unix() < end) }

// Avatar category is validated against the qualified origin (normal vs super),
// rather than treating the raw catalog type as the picker enum.
func (c Cosmetic) ValidateAvatarTuple(icon, category int64) error {
	if c.Family != "avatar" || c.Icon != icon || category < 1 || category > 5 {
		return ErrDisplay
	}
	if c.Type == 1 && category != 1 {
		return ErrDisplay
	}
	if c.Type == 2 && category != 2 && category != 3 {
		return ErrDisplay
	}
	if c.Type == 3 && category != 4 {
		return ErrDisplay
	}
	if c.Type > 3 && category != 5 {
		return ErrDisplay
	}
	return nil
}

type DisplaySelection struct {
	AvatarTableID  int64 `json:"avatar_table_id"`
	AvatarCategory int64 `json:"avatar_category"`
	TitleID        int64 `json:"title_id"`
	TitleUniqueID  int64 `json:"title_unique_id"`
	BubbleID       int64 `json:"bubble_id"`
}

func (s DisplaySelection) Validate() error {
	if s.AvatarTableID < 0 || s.AvatarCategory < 0 || s.AvatarCategory > 5 || s.TitleID < 0 || s.TitleUniqueID < 0 || s.BubbleID < 0 || (s.AvatarTableID == 0) != (s.AvatarCategory == 0) {
		return ErrDisplay
	}
	return nil
}
