// Package guildbroadcast owns immutable Guild broadcast source facts.
package guildbroadcast

import (
	"errors"
	"strings"
	"unicode/utf8"
)

const (
	StoragePolicyID   = "PG_UTF8_TEXT_NO_NUL_V1"
	PolicyID          = "GUILD_BROADCAST_STOCK_TEXTLEN_V1"
	TextSourceSHA256  = "6e56c7342e889d7ae8d41fe47cb06f66832227efe702f3863f693ee7ba84ffad"
	MaxTitleHalfUnits = 20
	MaxBodyHalfUnits  = 200
	MaxTitleBytes     = 80
	MaxBodyBytes      = 800
	MaxRecipients     = 50
)

var ErrText = errors.New("invalid Guild broadcast text")

// TextHalfUnits reproduces current src_64 utils.lua:xyd.getTextLen (105-136).
// Deliberately walk bytes: E0/E1 and F0 are not normal rune boundaries in that
// function. Valid UTF8 is required before applying the source's literal walk.
func TextHalfUnits(s string) (int, error) {
	if !utf8.ValidString(s) {
		return 0, ErrText
	}
	units := 0
	for i := 0; i < len(s); {
		b := s[i]
		stride := 1
		switch {
		case b > 240:
			stride = 4
		case b > 225:
			stride = 3
		case b > 192:
			stride = 2
		}
		i += stride
		if b > 225 && b <= 240 {
			units += 2
		} else {
			units++
		}
	}
	return units, nil
}

// Request is the complete stock588 input. No operation nonce or inferred
// server profanity/normalization rule is added.
type Request struct {
	Title   string `json:"title"`
	Content string `json:"content"`
}

func (r Request) Validate() error {
	if strings.IndexByte(r.Title, 0) >= 0 || strings.IndexByte(r.Content, 0) >= 0 || r.Title == "" || r.Content == "" || len(r.Title) > MaxTitleBytes || len(r.Content) > MaxBodyBytes {
		return ErrText
	}
	t, e := TextHalfUnits(r.Title)
	if e != nil || t > MaxTitleHalfUnits {
		return ErrText
	}
	b, e := TextHalfUnits(r.Content)
	if e != nil || b > MaxBodyHalfUnits {
		return ErrText
	}
	return nil
}
