package clock

import "time"

// Clock is the only source of authoritative application time. Domain code must
// not call time.Now directly when the result affects canonical gameplay state.
type Clock interface{ Now() time.Time }

type System struct{}

func (System) Now() time.Time { return time.Now().UTC() }

// Fixed is deterministic test/replay time.
type Fixed struct{ T time.Time }

func (f Fixed) Now() time.Time { return f.T.UTC() }

func UTC(t time.Time) time.Time { return t.UTC() }
