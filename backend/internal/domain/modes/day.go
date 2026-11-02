package modes

import "time"

const (
	secondsPerDay = 86400
	zoneOffset    = 8 * 3600
	dayStart      = 5 * 3600
	// Day 4 is Monday 1970-01-05; the epoch day was a Thursday.
	firstMonday = 4
)

func floorDiv(a, b int64) int64 {
	q := a / b
	if a%b != 0 && (a < 0) != (b < 0) {
		q--
	}
	return q
}

// Day numbers the game day, which begins at 05:00 GMT+8 (F7).
func Day(at time.Time) int64 {
	return floorDiv(at.Unix()+zoneOffset-dayStart, secondsPerDay)
}

// WeekStart is the Day of the Monday 05:00 GMT+8 that starts at's game week (D84).
func WeekStart(at time.Time) int64 {
	return firstMonday + 7*floorDiv(Day(at)-firstMonday, 7)
}

// DayBegins is the instant game day day begins.
func DayBegins(day int64) time.Time {
	return time.Unix(day*secondsPerDay-zoneOffset+dayStart, 0).UTC()
}
