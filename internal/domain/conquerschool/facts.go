// Package conquerschool owns CONQUER_SCHOOL facts, distinct from CONQUEST.
package conquerschool

import (
	"encoding/hex"
	"errors"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"math"
	"strconv"
	"strings"
	"time"
)

const Policy = "C2J_INITIAL_NO_PROGRESS_V1"
const Initial = "INITIAL_NO_PROGRESS"
const Unknown = "UNKNOWN_LEGACY"
const Retained = "RETAINED_CALLER_FACT"

var ErrUnavailable = errors.New("conquer: canonical fact unavailable")
var ErrUnqualified = errors.New("conquer: unqualified fact/content")
var ErrConflict = errors.New("conquer: version conflict")
var ErrStale = errors.New("conquer: stale observation")

type Campaign struct{ ID, Level, Region, NextID, Open int64 }
type Catalog struct {
	campaigns map[int64]Campaign
	levels    map[int64]int64
	last      map[int64]int64
	attrs     map[int64]map[int64]int64
	maxLoop   int64
}

func num(s string) (int64, error) {
	n, e := strconv.ParseInt(s, 10, 64)
	if e != nil || n < 0 || strconv.FormatInt(n, 10) != s {
		return 0, ErrUnqualified
	}
	return n, nil
}
func list(s string) ([]int64, error) {
	var out []int64
	for _, x := range strings.Split(s, "|") {
		n, e := num(x)
		if e != nil {
			return nil, e
		}
		out = append(out, n)
	}
	return out, nil
}
func NewCatalog(schema int, policy string, rows map[string][]map[string]string) (Catalog, error) {
	c := Catalog{campaigns: map[int64]Campaign{}, levels: map[int64]int64{}, last: map[int64]int64{}, attrs: map[int64]map[int64]int64{}}
	if schema != 1 || policy != "C2J_CONQUER_SOURCE_V1" || len(rows["regions"]) != 5 || len(rows["campaigns"]) != 56 || len(rows["loops"]) != 8 {
		return c, ErrUnqualified
	}
	for _, r := range rows["regions"] {
		id, e := num(r["region_id"])
		if e != nil || id < 1 || id > 5 || c.attrs[id] != nil {
			return Catalog{}, ErrUnqualified
		}
		a, e := list(r["attr_type"])
		if e != nil {
			return Catalog{}, e
		}
		v, e := list(r["attr_num"])
		if e != nil || len(a) != len(v) {
			return Catalog{}, ErrUnqualified
		}
		c.attrs[id] = map[int64]int64{}
		for i, k := range a {
			if k < 1 || v[i] < 1 || c.attrs[id][k] != 0 {
				return Catalog{}, ErrUnqualified
			}
			c.attrs[id][k] = v[i]
		}
	}
	for _, r := range rows["campaigns"] {
		var x Campaign
		for key, dst := range map[string]*int64{"id": &x.ID, "lev": &x.Level, "region": &x.Region, "next_id": &x.NextID, "is_open": &x.Open} {
			v, e := num(r[key])
			if e != nil {
				return Catalog{}, e
			}
			*dst = v
		}
		if x.ID < 1 || x.Level < 1 || c.attrs[x.Region] == nil || x.Open > 1 || c.campaigns[x.ID].ID != 0 || c.levels[x.Level] != 0 {
			return Catalog{}, ErrUnqualified
		}
		c.campaigns[x.ID] = x
		c.levels[x.Level] = x.Region
		c.last[x.Region] = x.Level
	}
	for _, x := range c.campaigns {
		if x.NextID != 0 && c.campaigns[x.NextID].ID == 0 {
			return Catalog{}, ErrUnqualified
		}
	}
	for i, r := range rows["loops"] {
		n, e := num(r["loop_id"])
		if e != nil || n != int64(i+1) {
			return Catalog{}, ErrUnqualified
		}
		c.maxLoop = n
	}
	return c, nil
}

type Progress struct {
	Level int64 `json:"conquer_lev"`
	Loop  int64 `json:"conquer_loop_id"`
}
type Run struct {
	Loop       int64  `json:"conquer_loop_id"`
	CurrentID  int64  `json:"current_id"`
	PassedID   int64  `json:"passed_id"`
	Generation string `json:"generation"`
}

func (c Catalog) ValidateProgress(p Progress) error {
	if len(c.campaigns) != 56 || len(c.attrs) != 5 || c.maxLoop != 8 {
		return ErrUnqualified
	}
	if p.Level < 0 || (p.Level > 0 && c.levels[p.Level] == 0) || p.Loop < 1 || p.Loop > c.maxLoop+1 {
		return ErrUnqualified
	}
	return nil
}
func (c Catalog) ValidateRun(r Run) error {
	if len(c.campaigns) != 56 || c.maxLoop != 8 {
		return ErrUnqualified
	}
	if r.Loop < 1 || r.Loop > c.maxLoop+1 || r.Generation == "" || len(r.Generation) > 128 || r.CurrentID < 0 || r.PassedID < 0 {
		return ErrUnqualified
	}
	for _, id := range []int64{r.CurrentID, r.PassedID} {
		if id != 0 && c.campaigns[id].ID == 0 {
			return ErrUnqualified
		}
	}
	return nil
}

// Run completion never invents global stat progress or a missing run.
func (c Catalog) Complete(r Run) (bool, error) {
	if e := c.ValidateRun(r); e != nil {
		return false, e
	}
	return r.CurrentID == r.PassedID || c.campaigns[r.CurrentID].Open == 0 || r.Loop > c.maxLoop, nil
}

// openRegions are the regions whose attributes a validated progress opens:
// every region after loop 1, else the regions whose last mission is cleared.
func (c Catalog) openRegions(p Progress) []int64 {
	if p.Level == 0 {
		return nil
	}
	max := c.levels[p.Level]
	if p.Loop > 1 {
		max = 5
	}
	var out []int64
	for region := int64(1); region <= max; region++ {
		if p.Loop == 1 && region == max && p.Level != c.last[region] {
			continue
		}
		out = append(out, region)
	}
	return out
}

// Region is MID1 conquer_region: the number of attribute-open regions.
func (c Catalog) Region(p Progress) (int64, error) {
	if e := c.ValidateProgress(p); e != nil {
		return 0, e
	}
	return int64(len(c.openRegions(p))), nil
}
func (c Catalog) Evaluate(p Progress) (map[int64]int64, error) {
	if e := c.ValidateProgress(p); e != nil {
		return nil, e
	}
	out := map[int64]int64{}
	for _, region := range c.openRegions(p) {
		for k, v := range c.attrs[region] {
			if out[k] > math.MaxInt64-v {
				return nil, ErrUnqualified
			}
			out[k] += v
		}
	}
	return out, nil
}

type Payload struct {
	Kind            string    `json:"kind"`
	Policy          string    `json:"policy"`
	OriginOperation ids.UUID  `json:"origin_operation"`
	OriginRef       string    `json:"origin_ref"`
	Progress        *Progress `json:"progress"`
	Run             *Run      `json:"run"`
}

func (p Payload) Clone() Payload {
	if p.Progress != nil {
		v := *p.Progress
		p.Progress = &v
	}
	if p.Run != nil {
		v := *p.Run
		p.Run = &v
	}
	return p
}

type Facts struct {
	Player               identity.PlayerID
	Version              int64
	ContentRevision      string
	Payload              Payload
	CreatedAt, UpdatedAt time.Time
}

func (f Facts) Validate(c Catalog) error {
	p := f.Payload
	if len(c.campaigns) != 56 || len(c.attrs) != 5 || c.maxLoop != 8 {
		return ErrUnqualified
	}
	if b, e := hex.DecodeString(f.ContentRevision); e != nil || len(b) != 32 {
		return ErrUnqualified
	}
	if !f.Player.Valid() || f.Version < 1 || len(f.ContentRevision) != 64 || f.CreatedAt.IsZero() || f.UpdatedAt.Before(f.CreatedAt) || p.Policy != Policy || p.OriginOperation.IsZero() || strings.TrimSpace(p.OriginRef) == "" || len(p.OriginRef) > 512 {
		return ErrUnqualified
	}
	switch p.Kind {
	case Unknown:
		if p.Progress != nil || p.Run != nil {
			return ErrUnqualified
		}
	case Initial:
		if p.Progress == nil || *p.Progress != (Progress{Level: 0, Loop: 1}) || p.Run != nil {
			return ErrUnqualified
		}
	case Retained:
		if p.Progress == nil {
			return ErrUnqualified
		}
	default:
		return ErrUnqualified
	}
	if p.Progress != nil {
		if e := c.ValidateProgress(*p.Progress); e != nil {
			return e
		}
	}
	if p.Run != nil {
		return c.ValidateRun(*p.Run)
	}
	return nil
}
func (f Facts) Known() bool { return f.Payload.Kind != Unknown && f.Payload.Progress != nil }

// Observation is one coherent read of a player's Conquer facts with the
// content revision it was observed under.
type Observation struct {
	Facts           Facts
	ContentRevision string
	ObservedAt      time.Time
	Contributions   map[int64]int64
	Regions         int64
	RunAvailable    bool
	RunComplete     bool
}

// HeroInputs is one hero with the population version and Conquer facts it was
// read under.
type HeroInputs struct {
	Hero              character.Hero
	PopulationVersion int64
	Observation       Observation
}
