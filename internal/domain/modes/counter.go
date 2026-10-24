package modes

import "errors"

var ErrCounterExhausted = errors.New("mode counter exhausted")

// Counter is a lazily reset use count: Period is the Day or WeekStart it was last used in.
type Counter struct {
	Period int64
	Used   int64
}

// In is the counter as seen in period: a counter from an earlier period starts again at zero.
func (c Counter) In(period int64) Counter {
	if c.Period != period {
		return Counter{Period: period}
	}
	return c
}

// Use spends n uses in period when the total stays within limit.
func (c Counter) Use(period, n, limit int64) (Counter, error) {
	current := c.In(period)
	if n < 1 || current.Used+n > limit {
		return c, ErrCounterExhausted
	}
	current.Used += n
	return current, nil
}
