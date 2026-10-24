package oneonone

import "time"

const (
	secondsPerDay = 86400
	zoneOffset    = 8 * 3600
	triesReset    = 5 * 3600
)

func floorDiv(a, b int64) int64 {
	q := a / b
	if a%b != 0 && (a < 0) != (b < 0) {
		q--
	}
	return q
}

// LocalDay numbers the GMT+8 calendar date.
func LocalDay(at time.Time) int64 {
	return floorDiv(at.Unix()+zoneOffset, secondsPerDay)
}

// Weekday is ISO (Monday 1 .. Sunday 7); day 0 (1970-01-01) was a Thursday.
func Weekday(day int64) int64 {
	return (day+3)%7 + 1
}

func Instant(day, seconds int64) time.Time {
	return time.Unix(day*secondsPerDay-zoneOffset+seconds, 0).UTC()
}

// TriesDay numbers the GMT+8 tries day, which begins at 05:00.
func TriesDay(at time.Time) int64 {
	return floorDiv(at.Unix()+zoneOffset-triesReset, secondsPerDay)
}

// Open is the daily START window 08:00-22:00 (source message 30002).
func (c Catalog) Open(at time.Time) bool {
	second := at.Unix() + zoneOffset - LocalDay(at)*secondsPerDay
	return second >= c.OpenSeconds && second < c.CloseSeconds
}

func (c Catalog) settlementDay(day int64) bool {
	for _, w := range c.SettlementWeekdays {
		if Weekday(day) == w {
			return true
		}
	}
	return false
}

// LatestSettlement is the most recent Wednesday/Sunday 22:00 at or before at.
func (c Catalog) LatestSettlement(at time.Time) int64 {
	day := LocalDay(at)
	for !c.settlementDay(day) || Instant(day, c.SettlementSeconds).After(at) {
		day--
	}
	return day
}

// LatestPromotion is the GMT+8 date of the most recent promotion opening at or before at.
func (c Catalog) LatestPromotion(at time.Time) int64 {
	day := LocalDay(at)
	for Weekday(day) != c.PromotionStart.Weekday || Instant(day, c.PromotionStart.Seconds).After(at) {
		day--
	}
	return day
}

func (c Catalog) PromotionOpensAt(week int64) time.Time {
	return Instant(week, c.PromotionStart.Seconds)
}

func (c Catalog) PromotionClosesAt(week int64) time.Time {
	return Instant(week+c.PromotionEnd.Weekday-c.PromotionStart.Weekday, c.PromotionEnd.Seconds)
}

const (
	TransitionSettle = "SETTLE"
	TransitionOpen   = "PROMOTION_OPEN"
	TransitionClose  = "PROMOTION_CLOSE"
)

// Transition is one scheduled competition change keyed by its GMT+8 date.
type Transition struct {
	Kind string
	Key  int64
	At   time.Time
}

// NextDue is the earliest owed transition at or before at; the competition
// applies each in its own transaction, oldest first (settle-before-mutate).
func (c Catalog) NextDue(r Competition, at time.Time) (Transition, bool) {
	options := []Transition{}
	settle := r.SettledThrough + 1
	for !c.settlementDay(settle) {
		settle++
	}
	options = append(options, Transition{TransitionSettle, settle, Instant(settle, c.SettlementSeconds)})
	open := r.OpenedThrough + 1
	for Weekday(open) != c.PromotionStart.Weekday {
		open++
	}
	options = append(options, Transition{TransitionOpen, open, c.PromotionOpensAt(open)})
	if r.ClosedThrough < r.OpenedThrough {
		options = append(options, Transition{TransitionClose, r.OpenedThrough, c.PromotionClosesAt(r.OpenedThrough)})
	}
	best, found := Transition{}, false
	for _, t := range options {
		if !t.At.After(at) && (!found || t.At.Before(best.At)) {
			best, found = t, true
		}
	}
	return best, found
}

// InPromotion reports whether the competition's latest opened week is still running.
func (c Catalog) InPromotion(r Competition, at time.Time) bool {
	return r.ClosedThrough < r.OpenedThrough && at.Before(c.PromotionClosesAt(r.OpenedThrough))
}
