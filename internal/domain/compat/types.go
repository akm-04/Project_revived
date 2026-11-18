// Package compat owns the player compatibility preferences: the stock
// message-push notification toggles and the first-main-touch marker. Both are
// presentation preferences; no currency, item, fact or mail belongs here.
package compat

import (
	"errors"
	"slices"
)

// LockRank is the player compat row rank (LEAD_SEAMS_I9-11_V2 section 2),
// taken after the I4 player root and before every mode owner.
const LockRank uint16 = 470

var (
	ErrUnavailable        = errors.New("compat preferences unavailable")
	ErrInvalidMessageType = errors.New("compat message type is not a stock notification")
)

// Preferences is one player's compat row.
type Preferences struct {
	FirstMainTouch int64
	MessagePushIDs []int64
	StateVersion   int64
}

// Catalog is the compiled stock notification id set for one content revision.
type Catalog struct {
	Revision       string
	MessagePushIDs map[int64]struct{}
}

func (c Catalog) ValidMessagePush(id int64) bool {
	_, ok := c.MessagePushIDs[id]
	return ok
}

// Enabled returns a copy of the enabled ids in ascending order; the stock
// Redmark and MessagePush readers iterate the MID 1 array with ipairs.
func (p Preferences) Enabled() []int64 {
	out := make([]int64, len(p.MessagePushIDs))
	copy(out, p.MessagePushIDs)
	slices.Sort(out)
	return out
}

func (p *Preferences) AddMessagePush(id int64) bool {
	if slices.Contains(p.MessagePushIDs, id) {
		return false
	}
	p.MessagePushIDs = append(p.MessagePushIDs, id)
	slices.Sort(p.MessagePushIDs)
	return true
}

func (p *Preferences) RemoveMessagePush(id int64) bool {
	for index, existing := range p.MessagePushIDs {
		if existing != id {
			continue
		}
		p.MessagePushIDs = append(p.MessagePushIDs[:index], p.MessagePushIDs[index+1:]...)
		return true
	}
	return false
}

func (p *Preferences) MarkFirstMainTouch() bool {
	if p.FirstMainTouch == 1 {
		return false
	}
	p.FirstMainTouch = 1
	return true
}

// Validate rejects a row or payload that the wire readers could not consume.
func (p Preferences) Validate() error {
	if p.FirstMainTouch != 0 && p.FirstMainTouch != 1 {
		return ErrUnavailable
	}
	if p.StateVersion < 1 {
		return ErrUnavailable
	}
	for index, id := range p.MessagePushIDs {
		if id <= 0 {
			return ErrUnavailable
		}
		if index > 0 && p.MessagePushIDs[index-1] >= id {
			return ErrUnavailable
		}
	}
	return nil
}
