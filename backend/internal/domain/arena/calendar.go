package arena

import "time"

const (
	secondsPerDay = 86400
	zoneOffset    = 8 * 3600
	dayStart      = 5 * 3600
)

func floorDiv(a, b int64) int64 {
	q := a / b
	if a%b != 0 && (a < 0) != (b < 0) {
		q--
	}
	return q
}

// Day numbers the GMT+8 Arena day, which begins at 05:00 (daily coin limit).
func Day(at time.Time) int64 {
	return floorDiv(at.Unix()+zoneOffset-dayStart, secondsPerDay)
}

// Season is one 45-day Arena season: ranked play from OpensAt until ClosesAt;
// the remaining hours up to the next opening answer is_close.
type Season struct {
	Number   int64
	OpensAt  time.Time
	ClosesAt time.Time
}

func (s Season) Open(at time.Time) bool {
	return s.Number > 0 && !at.Before(s.OpensAt) && at.Before(s.ClosesAt)
}

// anchor is misc region_arena_star_time (season 1 at 05:00 GMT+8); C5D policy
// repeats the source season every SeasonDays (user decision 2026-10-20).
func (c Catalog) anchor() int64 {
	day, _ := time.Parse("2006-01-02", c.SeasonAnchor)
	return day.Unix() - zoneOffset + c.SeasonOpenSeconds
}

func (c Catalog) SeasonNumbered(n int64) Season {
	length := c.SeasonDays * secondsPerDay
	opens := c.anchor() + (n-1)*length
	closes := opens + length - c.SeasonOpenSeconds + c.SeasonCloseSeconds
	return Season{Number: n, OpensAt: time.Unix(opens, 0).UTC(), ClosesAt: time.Unix(closes, 0).UTC()}
}

func (c Catalog) SeasonAt(at time.Time) Season {
	n := floorDiv(at.Unix()-c.anchor(), c.SeasonDays*secondsPerDay) + 1
	return c.SeasonNumbered(max(n, 0))
}

// LatestClosed is the newest season whose ranked play ended at or before at.
func (c Catalog) LatestClosed(at time.Time) int64 {
	s := c.SeasonAt(at)
	if at.Before(s.ClosesAt) {
		return s.Number - 1
	}
	return s.Number
}
