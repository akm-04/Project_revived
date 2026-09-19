package activity

import (
	"errors"
	"math"
)

var ErrInvalidProjection = errors.New("activity: invalid common projection")

// Projection is the source-observed common Activity envelope. Details remains
// child-owner data; I6B does not interpret its mechanics.
type Projection struct {
	TableID   int64
	IsOpen    int64
	StartTime int64
	EndTime   int64
	Days      int64
	Details   any
}

func (p Projection) Validate() error {
	if p.TableID <= 0 || p.TableID > math.MaxInt32 {
		return ErrInvalidProjection
	}
	if p.IsOpen != 0 && p.IsOpen != 1 {
		return ErrInvalidProjection
	}
	if p.StartTime < 0 || p.EndTime < 0 || p.Days < math.MinInt32 || p.Days > math.MaxInt32 {
		return ErrInvalidProjection
	}
	return nil
}
