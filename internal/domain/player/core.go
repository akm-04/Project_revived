package player

import (
	"errors"
	"math"
	"sort"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
)

// GUIDE_END is source-visible in current src_64 enums.lua and StoryData.lua.
// It is a presentation/onboarding completion marker, not gameplay reward proof.
const GuideEndID int64 = 100197

type Profile struct {
	PlayerID      identity.PlayerID
	DisplayName   string
	AvatarID      int64
	AvatarFrameID int64
	PlayerType    int64
	StateVersion  int64
	CreatedAt     time.Time
	UpdatedAt     time.Time
}

type Progression struct {
	PlayerID     identity.PlayerID
	Level        int64
	Exp          int64
	StateVersion int64
	UpdatedAt    time.Time
}

func (p Progression) CreditExp(amount int64, now time.Time) (Progression, error) {
	if err := p.Validate(); err != nil {
		return Progression{}, err
	}
	if amount <= 0 || now.IsZero() {
		return Progression{}, errors.New("player exp credit must be positive")
	}
	if amount > math.MaxInt64-p.Exp {
		return Progression{}, errors.New("player exp overflow")
	}
	p.Exp += amount
	p.StateVersion++
	p.UpdatedAt = now.UTC()
	return p, nil
}

type StoryCursor struct {
	PlayerID     identity.PlayerID
	StoryID      int64
	StoryState   int64
	GuideID      int64
	StateVersion int64
	UpdatedAt    time.Time
}

type GuideReturnState struct {
	PlayerID         identity.PlayerID
	GuideReturnID    int64
	GuideFunctionIDs []int64
	StateVersion     int64
	UpdatedAt        time.Time
}

type FunctionUnlock struct {
	PlayerID      identity.PlayerID
	FunctionID    int64
	OpenedAt      time.Time
	SourceFactKey string
	StateVersion  int64
}

type Core struct {
	Profile     Profile
	Progression Progression
	Story       StoryCursor
	GuideReturn GuideReturnState
	Functions   []FunctionUnlock
}

func (p Profile) Validate() error {
	if !p.PlayerID.Valid() || p.AvatarID <= 0 || p.AvatarFrameID < 0 || p.StateVersion <= 0 || p.CreatedAt.IsZero() || p.UpdatedAt.IsZero() {
		return errors.New("invalid player profile")
	}
	return nil
}
func (p Progression) Validate() error {
	if !p.PlayerID.Valid() || p.Level < 1 || p.Exp < 0 || p.StateVersion <= 0 || p.UpdatedAt.IsZero() {
		return errors.New("invalid player progression")
	}
	return nil
}
func (s StoryCursor) Validate() error {
	if !s.PlayerID.Valid() || s.StoryID < 0 || s.StoryState < 0 || s.GuideID < 0 || s.StateVersion <= 0 || s.UpdatedAt.IsZero() {
		return errors.New("invalid player story cursor")
	}
	return nil
}
func (g GuideReturnState) Validate() error {
	if !g.PlayerID.Valid() || g.GuideReturnID < 0 || g.StateVersion <= 0 || g.UpdatedAt.IsZero() {
		return errors.New("invalid guide return state")
	}
	seen := map[int64]struct{}{}
	for _, id := range g.GuideFunctionIDs {
		if id <= 0 {
			return errors.New("guide function ids must be positive")
		}
		if _, ok := seen[id]; ok {
			return errors.New("duplicate guide function id")
		}
		seen[id] = struct{}{}
	}
	return nil
}
func (u FunctionUnlock) Validate() error {
	if !u.PlayerID.Valid() || u.FunctionID <= 0 || u.OpenedAt.IsZero() || u.SourceFactKey == "" || u.StateVersion <= 0 {
		return errors.New("invalid function unlock")
	}
	return nil
}
func (c Core) Validate() error {
	if err := c.Profile.Validate(); err != nil {
		return err
	}
	if err := c.Progression.Validate(); err != nil {
		return err
	}
	if err := c.Story.Validate(); err != nil {
		return err
	}
	if err := c.GuideReturn.Validate(); err != nil {
		return err
	}
	pid := c.Profile.PlayerID
	if c.Progression.PlayerID != pid || c.Story.PlayerID != pid || c.GuideReturn.PlayerID != pid {
		return errors.New("player core owner mismatch")
	}
	for _, u := range c.Functions {
		if err := u.Validate(); err != nil {
			return err
		}
		if u.PlayerID != pid {
			return errors.New("function unlock owner mismatch")
		}
	}
	return nil
}

// CompatibilityBootstrap is deliberately narrow: it carries exactly the I4
// source-shaped defaults already frozen for a newly-created player. It does not
// invent starter heroes, gacha outcomes, non-zero currencies or temporal policy.
func CompatibilityBootstrap(playerID identity.PlayerID, now time.Time) Core {
	now = now.UTC()
	return Core{
		Profile:     Profile{PlayerID: playerID, DisplayName: "", AvatarID: logicalserver.BootstrapDirectoryAvatarID, AvatarFrameID: 0, PlayerType: 0, StateVersion: 1, CreatedAt: now, UpdatedAt: now},
		Progression: Progression{PlayerID: playerID, Level: 1, Exp: 0, StateVersion: 1, UpdatedAt: now},
		Story:       StoryCursor{PlayerID: playerID, StoryID: 0, StoryState: 0, GuideID: 0, StateVersion: 1, UpdatedAt: now},
		GuideReturn: GuideReturnState{PlayerID: playerID, GuideReturnID: 0, GuideFunctionIDs: []int64{}, StateVersion: 1, UpdatedAt: now},
	}
}

func (c Core) FunctionIDs() []int64 {
	out := make([]int64, 0, len(c.Functions))
	for _, f := range c.Functions {
		out = append(out, f.FunctionID)
	}
	sort.Slice(out, func(i, j int) bool { return out[i] < out[j] })
	return out
}

// MID17OwnedFields projects only Player Core-owned stock fields. Economy,
// Social, Commerce and later-domain fields are intentionally absent.
func (c Core) MID17OwnedFields() (map[string]any, error) {
	if err := c.Validate(); err != nil {
		return nil, err
	}
	guide := append([]int64(nil), c.GuideReturn.GuideFunctionIDs...)
	sort.Slice(guide, func(i, j int) bool { return guide[i] < guide[j] })
	return map[string]any{
		"player_name":        c.Profile.DisplayName,
		"player_type":        c.Profile.PlayerType,
		"avatar_id":          c.Profile.AvatarID,
		"avatar_frame_id":    c.Profile.AvatarFrameID,
		"lev":                c.Progression.Level,
		"exp":                c.Progression.Exp,
		"story_id":           c.Story.StoryID,
		"story_state":        c.Story.StoryState,
		"guide_id":           c.Story.GuideID,
		"func_ids":           c.FunctionIDs(),
		"guide_function_ids": guide,
		"guide_return_id":    c.GuideReturn.GuideReturnID,
	}, nil
}

func SaveStory(cur StoryCursor, storyID, storyState, guideID int64, now time.Time) (StoryCursor, bool, error) {
	if err := cur.Validate(); err != nil {
		return StoryCursor{}, false, err
	}
	if storyID < 0 || storyState < 0 || guideID < 0 || now.IsZero() {
		return StoryCursor{}, false, errors.New("invalid SAVE_STORY values")
	}
	if cur.StoryID == storyID && cur.StoryState == storyState && cur.GuideID == guideID {
		return cur, guideID == GuideEndID, nil
	}
	cur.StoryID, cur.StoryState, cur.GuideID = storyID, storyState, guideID
	cur.StateVersion++
	cur.UpdatedAt = now.UTC()
	return cur, guideID == GuideEndID, nil
}

// ProgressionRow is the immutable source-derived progression policy for one
// player level. TotalExp is cumulative and AwardEnergy belongs to the departed
// level when the next threshold is crossed.
type ProgressionRow struct {
	Level       int64
	MaxEnergy   int64
	AwardEnergy int64
	TotalExp    int64
}

type ProgressionPolicy struct {
	Revision string
	Rows     []ProgressionRow
}

func (p ProgressionPolicy) Validate() error {
	if p.Revision == "" || len(p.Rows) == 0 {
		return errors.New("invalid progression policy")
	}
	var prevTotal int64
	for i, row := range p.Rows {
		want := int64(i + 1)
		if row.Level != want || row.MaxEnergy <= 0 || row.AwardEnergy < 0 || row.TotalExp <= prevTotal {
			return errors.New("invalid progression policy row")
		}
		prevTotal = row.TotalExp
	}
	return nil
}

func (p ProgressionPolicy) MaxLevel() int64 { return int64(len(p.Rows)) }

func (p ProgressionPolicy) MaxCanonicalExp() (int64, error) {
	if err := p.Validate(); err != nil {
		return 0, err
	}
	last := p.Rows[len(p.Rows)-1].TotalExp
	if last <= 0 {
		return 0, errors.New("invalid terminal progression threshold")
	}
	return last - 1, nil
}

func (p ProgressionPolicy) row(level int64) (ProgressionRow, error) {
	if err := p.Validate(); err != nil {
		return ProgressionRow{}, err
	}
	if level < 1 || level > int64(len(p.Rows)) {
		return ProgressionRow{}, errors.New("progression level outside policy")
	}
	return p.Rows[level-1], nil
}

func (p ProgressionPolicy) EnergyCap(level int64) (int64, error) {
	r, err := p.row(level)
	if err != nil {
		return 0, err
	}
	return r.MaxEnergy, nil
}

// ValidateState rejects imported contradictory level/EXP pairs rather than
// silently normalizing historical state.
func (p ProgressionPolicy) ValidateState(s Progression) error {
	if err := s.Validate(); err != nil {
		return err
	}
	if err := p.Validate(); err != nil {
		return err
	}
	maxExp, err := p.MaxCanonicalExp()
	if err != nil {
		return err
	}
	if s.Level > p.MaxLevel() || s.Exp > maxExp {
		return errors.New("progression state outside immutable policy")
	}
	var minExp int64
	if s.Level > 1 {
		minExp = p.Rows[s.Level-2].TotalExp
	}
	if s.Exp < minExp {
		return errors.New("progression level ahead of cumulative exp")
	}
	if s.Level < p.MaxLevel() {
		upper := p.Rows[s.Level-1].TotalExp
		if s.Exp >= upper {
			return errors.New("progression cumulative exp implies higher level")
		}
	}
	return nil
}

type ProgressionTransition struct {
	Before              Progression
	After               Progression
	RequestedExp        int64
	EffectiveExp        int64
	DiscardedExp        int64
	DepartedLevels      []int64
	AwardEnergy         int64
	OldEnergyCap        int64
	NewEnergyCap        int64
	ContentRevision     string
	CompatibilityPolicy string
}

func (p ProgressionPolicy) PlanCreditExp(s Progression, amount int64, now time.Time) (ProgressionTransition, error) {
	if err := p.ValidateState(s); err != nil {
		return ProgressionTransition{}, err
	}
	if amount <= 0 || now.IsZero() {
		return ProgressionTransition{}, errors.New("player exp credit must be positive with authoritative time")
	}
	maxExp, err := p.MaxCanonicalExp()
	if err != nil {
		return ProgressionTransition{}, err
	}
	room := maxExp - s.Exp
	effective := amount
	if effective > room {
		effective = room
	}
	if effective < 0 {
		effective = 0
	}
	discarded := amount - effective
	before := s
	after := s
	if effective > 0 {
		if effective > math.MaxInt64-after.Exp {
			return ProgressionTransition{}, errors.New("player exp overflow")
		}
		after.Exp += effective
	}
	oldCap, err := p.EnergyCap(before.Level)
	if err != nil {
		return ProgressionTransition{}, err
	}
	departed := make([]int64, 0, 4)
	var energyAward int64
	for after.Level < p.MaxLevel() {
		row := p.Rows[after.Level-1]
		if after.Exp < row.TotalExp {
			break
		}
		if row.AwardEnergy > math.MaxInt64-energyAward {
			return ProgressionTransition{}, errors.New("level energy award overflow")
		}
		energyAward += row.AwardEnergy
		departed = append(departed, after.Level)
		after.Level++
	}
	newCap, err := p.EnergyCap(after.Level)
	if err != nil {
		return ProgressionTransition{}, err
	}
	if after.Exp != before.Exp || after.Level != before.Level {
		if before.StateVersion == math.MaxInt64 {
			return ProgressionTransition{}, errors.New("progression version overflow")
		}
		after.StateVersion = before.StateVersion + 1
		after.UpdatedAt = now.UTC()
	}
	return ProgressionTransition{
		Before: before, After: after, RequestedExp: amount, EffectiveExp: effective,
		DiscardedExp: discarded, DepartedLevels: departed, AwardEnergy: energyAward,
		OldEnergyCap: oldCap, NewEnergyCap: newCap, ContentRevision: p.Revision,
		CompatibilityPolicy: "r5.progression.v1",
	}, nil
}

type FunctionEligibility struct {
	PlayerID        identity.PlayerID
	FunctionID      int64
	ContentRevision string
	SourceFactKey   string
	EligibleAt      time.Time
}

func (e FunctionEligibility) Validate() error {
	if !e.PlayerID.Valid() || e.FunctionID <= 0 || e.ContentRevision == "" || e.SourceFactKey == "" || e.EligibleAt.IsZero() {
		return errors.New("invalid function eligibility")
	}
	return nil
}
