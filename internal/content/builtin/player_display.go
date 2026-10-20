package builtin

import "errors"

// Immutable compiler data transfer shape. Player semantic validity is checked
// by the owning domain when the exact hash-bound payload is read at runtime.
// Content does not depend on gameplay domain layers.
type PlayerDisplayCatalog struct {
	SchemaVersion int    `json:"schema_version"`
	PolicyID      string `json:"policy_id"`
	RenameCost    int64  `json:"rename_cost"`
	DefaultAvatar int64  `json:"default_avatar"`
	DefaultFrame  int64  `json:"default_frame"`
	DefaultBubble int64  `json:"default_bubble"`
	HeroTemplates []struct {
		TableID      int64  `json:"table_id"`
		BeforeAwaken int64  `json:"before_awaken"`
		Kind         string `json:"kind"`
	} `json:"hero_templates"`
	Cosmetics []struct {
		Family    string `json:"family"`
		ID        int64  `json:"id"`
		Icon      int64  `json:"icon"`
		Type      int64  `json:"type"`
		PartnerID int64  `json:"partner_id"`
		Days      int64  `json:"days"`
		VIP       int64  `json:"vip"`
		Price     int64   `json:"price"`
		Condition []int64 `json:"condition,omitempty"`
	} `json:"cosmetics"`
	Names      []string `json:"names"`
	Words      []string `json:"words"`
	Collection []int64  `json:"collection"`
}

func (p PlayerDisplayCatalog) Validate() error {
	if p.SchemaVersion != 1 || p.PolicyID != "PLAYER_DISPLAY_V1" || p.RenameCost != 100 || p.DefaultAvatar <= 0 || p.DefaultFrame <= 0 || p.DefaultBubble <= 0 || len(p.HeroTemplates) == 0 || len(p.Cosmetics) == 0 || len(p.Names) != 12 || len(p.Words) == 0 || len(p.Collection) != 4 {
		return errors.New("builtin content: invalid display catalog metadata")
	}
	return nil
}
