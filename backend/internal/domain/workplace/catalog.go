package workplace

import "errors"

var ErrUnavailable = errors.New("workplace unavailable")
var ErrRefused = errors.New("workplace refused")

type Crew struct {
	BaseID   int64 `json:"base_id"`
	Location int64 `json:"location"`
	Trait    int64 `json:"trait"`
}
type Policy struct {
	InitialSP       int64 `json:"initial_sp"`
	Drink           int64 `json:"drink_item_id"`
	DiaryLimit      int   `json:"diary_limit"`
	MaxCombatCrew   int   `json:"max_combat_crew"`
	BonusLevel      int64 `json:"bonus_level"`
	BonusMin        int64 `json:"bonus_min"`
	BonusMax        int64 `json:"bonus_max"`
	BonusPerDay     int64 `json:"bonus_per_day"`
	CampaignType    int64 `json:"rival_campaign_type"`
	BattleID        int64 `json:"rival_battle_id"`
	AttemptLifetime int64 `json:"attempt_lifetime_seconds"`
	ExcludeSX       bool  `json:"exclude_sx_scrolls"`
}
type Catalog struct {
	Schema       int64             `json:"schema_version"`
	Contract     string            `json:"contract_id"`
	PolicyID     string            `json:"policy_id"`
	PolicySHA    string            `json:"policy_sha256"`
	Sources      map[string]string `json:"source_sha256"`
	Locations    []Location        `json:"locations"`
	Jobs         []Job             `json:"jobs"`
	Crew         []Crew            `json:"crew"`
	Scrolls      []int64           `json:"scrolls"`
	ItemProducts map[int64]int64   `json:"item_products"`
	Formula      Formula           `json:"formula"`
	VIP          []Rate            `json:"vip"`
	Policy       Policy            `json:"policy"`
}

func (c Catalog) Validate() error {
	if c.Schema != 1 || c.Contract != "I9_WORKPLACE_V1" || c.PolicyID != "I9_WORKPLACE_PRIVATE_POLICY_V1" || len(c.PolicySHA) != 64 || len(c.Locations) != 6 || len(c.Jobs) != 35 || len(c.Crew) != 114 || len(c.Scrolls) != 109 || len(c.VIP) != 16 || len(c.Sources) != 7 {
		return ErrInvalid
	}
	p := c.Policy
	if p.InitialSP != 50 || p.Drink != 50001002 || p.DiaryLimit < 1 || p.DiaryLimit > 100 || p.MaxCombatCrew != 5 || p.BonusLevel != 42 || p.BonusMin < 0 || p.BonusMax < p.BonusMin || p.BonusMax > 1000 || p.BonusPerDay != 1 || p.CampaignType != 6 || p.BattleID != 113001 || p.AttemptLifetime < 36000 || p.AttemptLifetime > 315360000 || !p.ExcludeSX {
		return ErrInvalid
	}
	seen := map[int64]bool{}
	for _, l := range c.Locations {
		if seen[l.ID] || l.ID < 1 || l.ID > 6 || l.BaseTime != 36000 || l.BaseIce != 10 || l.MaxMembers < 1 || l.MaxMembers > 30 {
			return ErrInvalid
		}
		seen[l.ID] = true
	}
	jobs := map[int64]bool{}
	for _, j := range c.Jobs {
		if jobs[j.ID] || j.ID <= 0 || j.Product < 1 || j.Product > 9 || j.RequireType < 1 || j.RequireType > 2 || j.Require <= 0 {
			return ErrInvalid
		}
		jobs[j.ID] = true
		for _, r := range j.Chests {
			if r[0] <= 0 || r[1] <= 0 {
				return ErrInvalid
			}
		}
	}
	bases := map[int64]bool{}
	for _, h := range c.Crew {
		if h.BaseID <= 0 || bases[h.BaseID] || !seen[h.Location] || h.Trait < 0 || h.Trait > 4 {
			return ErrInvalid
		}
		bases[h.BaseID] = true
	}
	for _, l := range c.Locations {
		n := 0
		for _, h := range c.Crew {
			if h.Location == l.ID {
				n++
			}
		}
		if int64(n) != l.MaxMembers {
			return ErrInvalid
		}
		for _, id := range l.Jobs {
			if !jobs[id] {
				return ErrInvalid
			}
		}
	}
	for _, r := range c.VIP {
		if r.Numerator <= 0 || r.Denominator <= 0 {
			return ErrInvalid
		}
	}
	for _, id := range c.Scrolls {
		if id <= 0 {
			return ErrInvalid
		}
	}
	return nil
}
func (c Catalog) Location(id int64) (Location, bool) {
	for _, r := range c.Locations {
		if r.ID == id {
			return r, true
		}
	}
	return Location{}, false
}
func (c Catalog) Job(id int64) (Job, bool) {
	for _, r := range c.Jobs {
		if r.ID == id {
			return r, true
		}
	}
	return Job{}, false
}
func (c Catalog) Girl(id int64) (Crew, bool) {
	for _, r := range c.Crew {
		if r.BaseID == id {
			return r, true
		}
	}
	return Crew{}, false
}
