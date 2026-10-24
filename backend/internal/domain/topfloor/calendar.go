package topfloor

import "time"

const (
	secondsPerDay = 86400
	zoneOffset    = 8 * 3600
	ticketReset   = 5 * 3600
)

func floorDiv(a, b int64) int64 {
	q := a / b
	if a%b != 0 && (a < 0) != (b < 0) {
		q--
	}
	return q
}

// TicketDay numbers the GMT+8 ticket day, which begins at 05:00.
func TicketDay(at time.Time) int64 {
	return floorDiv(at.Unix()+zoneOffset-ticketReset, secondsPerDay)
}

// LatestCutoffDay numbers the GMT+8 date of the most recent daily 21:00 cutoff at or before at.
func (c Catalog) LatestCutoffDay(at time.Time) int64 {
	return floorDiv(at.Unix()+zoneOffset-c.CutoffSeconds, secondsPerDay)
}

func (c Catalog) CutoffInstant(day int64) time.Time {
	return time.Unix(day*secondsPerDay-zoneOffset+c.CutoffSeconds, 0).UTC()
}

// Frozen is the 21:00-21:30 GMT+8 settlement window in which no START is admitted.
func (c Catalog) Frozen(at time.Time) bool {
	second := at.Unix() + zoneOffset - floorDiv(at.Unix()+zoneOffset, secondsPerDay)*secondsPerDay
	return second >= c.CutoffSeconds && second < c.FreezeEndSeconds
}

// DayDate renders a day number as its GMT+8 calendar date.
func DayDate(day int64) string {
	return time.Unix(day*secondsPerDay, 0).UTC().Format("2006-01-02")
}
