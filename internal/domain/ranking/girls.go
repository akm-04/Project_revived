package ranking

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"math"
	"sort"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

// These are private-server policies, not recovered original-server algorithms.
// New tuning requires a new policy identity; stored generations keep this one.
const GirlsPolicy = "C4C_PRIVATE_GIRLS_SERVER_RANKING_V1"
const GirlsCohort = "I4_SERVER_ALL_PLAYERS_V1"
const GirlsSourcePolicy = "C4C_PRIVATE_CURRENT_ROSTER_V1"
const GirlsSourceSemantics = "CURRENT_DISTINCT_ORIGIN_HERO_PET_STARS_BEFORE_AWAKEN_V1"
const GirlsTitleDuration int64 = 604800
const GirlsLockRank uint16 = 600

var ErrSnapshot = errors.New("ranking: invalid or unavailable canonical Girls snapshot")
var ErrStale = errors.New("ranking: bound observation precedes durable state")

func digest(v any) string {
	b, e := json.Marshal(v)
	if e != nil {
		return ""
	}
	h := sha256.Sum256(b)
	return hex.EncodeToString(h[:])
}
func revision(s string) bool {
	b, e := hex.DecodeString(s)
	return e == nil && len(b) == 32 && hex.EncodeToString(b) == s
}

type ScoreRun struct {
	Score    int64
	Since    time.Time
	Revision string
}
type GirlsRoot struct {
	Server                       identity.LogicalServerID
	Policy                       string
	NextGeneration, StateVersion int64
	CreatedAt, UpdatedAt         time.Time
	Runs                         map[identity.PlayerID]ScoreRun
}

func NewGirlsRoot(server identity.LogicalServerID, at time.Time) (GirlsRoot, error) {
	r := GirlsRoot{Server: server, Policy: GirlsPolicy, NextGeneration: 1, StateVersion: 1, CreatedAt: at.UTC(), UpdatedAt: at.UTC(), Runs: map[identity.PlayerID]ScoreRun{}}
	return r, r.Validate()
}
func (r GirlsRoot) Validate() error {
	if !r.Server.Valid() || r.Policy != GirlsPolicy || r.NextGeneration < 1 || r.StateVersion < 1 || r.CreatedAt.Unix() <= 0 || r.UpdatedAt.Before(r.CreatedAt) || r.Runs == nil {
		return ErrSnapshot
	}
	for id, v := range r.Runs {
		if !id.Valid() || v.Score < 0 || v.Score > 9007199254740991 || v.Since.Before(r.CreatedAt) || v.Since.After(r.UpdatedAt) || !revision(v.Revision) {
			return ErrSnapshot
		}
	}
	return nil
}

// GirlsMetric is retained canonical provenance, not a second count authority.
// The application obtains it only from the witnessed public-profile provider.
type GirlsMetric struct {
	Player                                               identity.PlayerID
	Owner, Policy, Semantics, Revision, PopulationDigest string
	FieldID, Value, SourceVersion, PopulationVersion     int64
	ObservedAt                                           time.Time
}

func (m GirlsMetric) valid(at time.Time, rev string) bool {
	return m.Player.Valid() && m.Owner == "CharacterHero" && m.Policy == GirlsSourcePolicy && m.Semantics == GirlsSourceSemantics && m.Revision == rev && m.FieldID == 1001 && m.Value >= 0 && m.Value <= 9007199254740991 && m.SourceVersion > 0 && m.PopulationVersion == m.SourceVersion && revision(m.PopulationDigest) && m.ObservedAt.Equal(at)
}

// Presentation is a snapshot of I4's derived directory; it never establishes a
// score, cohort membership, title eligibility or authoritative Conquer state.
type GirlsPresentation struct {
	Player                                                identity.PlayerID
	Name                                                  string
	Level, AvatarID, FrameID, ConquerLevel, ConquerLoopID int64
}

func (p GirlsPresentation) valid(id identity.PlayerID) bool {
	return p.Player == id && p.Level >= 1 && p.AvatarID >= 0 && p.FrameID >= 0 && p.ConquerLevel >= 0 && p.ConquerLoopID >= 0
}

type GirlsInput struct {
	Metric  GirlsMetric
	Display GirlsPresentation
}
type GirlsEntry struct {
	Metric     GirlsMetric
	Display    GirlsPresentation
	ScoreSince time.Time
}
type GirlsSnapshot struct {
	Server               identity.LogicalServerID
	Policy, Revision     string
	Generation           int64
	OperationID          ids.UUID
	ObservedAt           time.Time
	Entries              []GirlsEntry
	CohortDigest, Digest string
}

func (s GirlsSnapshot) scope() Scope {
	return Scope{Kind: "SERVER", ServerID: int64(s.Server), Cohort: GirlsCohort}
}
func (s GirlsSnapshot) ordering() Profile {
	return Profile{ID: CurrentObserved, PolicyVersion: s.Policy, Generation: strconv.FormatInt(s.Generation, 10), TieBreak: StableID, Scope: s.scope(), ObservedAt: s.ObservedAt}
}
func (s GirlsSnapshot) ordered() ([]Entry, error) {
	in := make([]Entry, 0, len(s.Entries))
	for _, v := range s.Entries {
		in = append(in, Entry{SubjectID: int64(v.Metric.Player), Score: v.Metric.Value, ScoreSince: v.ScoreSince, Basis: CurrentObserved, PolicyVersion: s.Policy, Generation: strconv.FormatInt(s.Generation, 10), Scope: s.scope()})
	}
	return Order(s.ordering(), in)
}
func (s GirlsSnapshot) cohortDigest() string {
	ids := make([]int64, 0, len(s.Entries))
	for _, v := range s.Entries {
		ids = append(ids, int64(v.Metric.Player))
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	return digest(ids)
}
func (s GirlsSnapshot) hash() string { s.Digest = ""; return digest(s) }
func (s GirlsSnapshot) Validate() error {
	if !s.Server.Valid() || s.Policy != GirlsPolicy || !revision(s.Revision) || s.Generation < 1 || s.OperationID.IsZero() || s.ObservedAt.Unix() <= 0 || s.Entries == nil || !revision(s.Digest) || s.CohortDigest != s.cohortDigest() || s.Digest != s.hash() {
		return ErrSnapshot
	}
	for _, v := range s.Entries {
		if !v.Metric.valid(s.ObservedAt, s.Revision) || !v.Display.valid(v.Metric.Player) {
			return ErrSnapshot
		}
	}
	ordered, e := s.ordered()
	if e != nil {
		return e
	}
	for i, v := range ordered {
		if v.SubjectID != int64(s.Entries[i].Metric.Player) {
			return ErrSnapshot
		}
	}
	return nil
}

// BuildGirlsSnapshot must receive the complete canonical I4 cohort. The caller
// checks cohort identity and obtains all metrics in one witnessed transaction.
// This function never manufactures historical first-reach timestamps.
func BuildGirlsSnapshot(r GirlsRoot, at time.Time, rev string, op ids.UUID, in []GirlsInput) (GirlsRoot, GirlsSnapshot, error) {
	var out GirlsSnapshot
	if r.Validate() != nil || !revision(rev) || op.IsZero() || at.Unix() <= 0 {
		return GirlsRoot{}, out, ErrSnapshot
	}
	if at.Before(r.UpdatedAt) {
		return GirlsRoot{}, out, ErrStale
	}
	if r.StateVersion == math.MaxInt64 || r.NextGeneration == math.MaxInt64 {
		return GirlsRoot{}, out, ErrSnapshot
	}
	out = GirlsSnapshot{Server: r.Server, Policy: r.Policy, Revision: rev, Generation: r.NextGeneration, OperationID: op, ObservedAt: at.UTC(), Entries: []GirlsEntry{}}
	next := r
	next.Runs = map[identity.PlayerID]ScoreRun{}
	byID := map[int64]GirlsEntry{}
	for _, v := range in {
		m := v.Metric
		if !m.valid(at, rev) || !v.Display.valid(m.Player) {
			return GirlsRoot{}, GirlsSnapshot{}, ErrSnapshot
		}
		if _, dup := byID[int64(m.Player)]; dup {
			return GirlsRoot{}, GirlsSnapshot{}, ErrSnapshot
		}
		run := ScoreRun{Score: m.Value, Since: at.UTC(), Revision: rev}
		if old, ok := r.Runs[m.Player]; ok && old.Score == m.Value && old.Revision == rev {
			run.Since = old.Since
		}
		next.Runs[m.Player] = run
		v := GirlsEntry{Metric: m, Display: v.Display, ScoreSince: run.Since}
		byID[int64(m.Player)] = v
		out.Entries = append(out.Entries, v)
	}
	ordered, e := out.ordered()
	if e != nil {
		return GirlsRoot{}, GirlsSnapshot{}, e
	}
	out.Entries = []GirlsEntry{}
	for _, v := range ordered {
		out.Entries = append(out.Entries, byID[v.SubjectID])
	}
	out.CohortDigest = out.cohortDigest()
	out.Digest = out.hash()
	next.NextGeneration++
	next.StateVersion++
	next.UpdatedAt = at.UTC()
	if next.Validate() != nil || out.Validate() != nil {
		return GirlsRoot{}, GirlsSnapshot{}, ErrSnapshot
	}
	return next, out, nil
}

// GirlsWeek is an explicit private UTC calendar. It does not reuse another
// mode's 05:00 reset or imply a recovered original leaderboard timetable.
func GirlsWeek(at time.Time) (time.Time, error) {
	if at.Unix() <= 0 {
		return time.Time{}, ErrSnapshot
	}
	u := at.UTC()
	day := time.Date(u.Year(), u.Month(), u.Day(), 0, 0, 0, 0, time.UTC)
	offset := (int(u.Weekday()) + 6) % 7
	return day.AddDate(0, 0, -offset), nil
}

type GirlsAward struct {
	Player        identity.PlayerID
	Rank, TitleID int64
	OriginKey     string
	StartsAt      time.Time
	EndTime       int64
}

func (s GirlsSnapshot) Awards() ([]GirlsAward, error) {
	if e := s.Validate(); e != nil {
		return nil, e
	}
	if s.ObservedAt.Unix() > 9007199254740991-GirlsTitleDuration {
		return nil, ErrSnapshot
	}
	week, e := GirlsWeek(s.ObservedAt)
	if e != nil {
		return nil, e
	}
	out := []GirlsAward{}
	for i, v := range s.Entries {
		rank := int64(i + 1)
		if rank > 20 || v.Metric.Value == 0 {
			continue
		}
		title := int64(100062)
		if rank <= 3 {
			title = 100058 + rank
		}
		key := "ranking:" + s.Policy + ":" + strconv.FormatInt(int64(s.Server), 10) + ":" + week.Format("2006-01-02") + ":" + strconv.FormatInt(int64(v.Metric.Player), 10)
		out = append(out, GirlsAward{Player: v.Metric.Player, Rank: rank, TitleID: title, OriginKey: key, StartsAt: s.ObservedAt, EndTime: s.ObservedAt.Unix() + GirlsTitleDuration})
	}
	return out, nil
}
