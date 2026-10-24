// Package publication owns immutable published revisions, separate family payloads and picture read identity.
package publication

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/foundation/ids"
	"math"
	"strings"
	"time"
)

const (
	Announcement          = "announcement"
	Board                 = "board"
	Picture               = "picture"
	MaxWireID      int64  = 1<<53 - 1
	MarkerLockRank uint16 = 390
)

var (
	ErrInvalid          = errors.New("invalid published revision")
	ErrRevisionConflict = errors.New("published revision identity conflict")
)

type Section struct {
	Title    string   `json:"title"`
	Contents []string `json:"contents"`
	URL      string   `json:"url,omitempty"`
}
type BoardItem struct {
	ID        int64  `json:"id"`
	Title     string `json:"title"`
	StartDate string `json:"start_date"`
	Content   string `json:"content"`
	ImageURL  string `json:"img_url,omitempty"`
}
type PictureItem struct {
	Weight   float64 `json:"weight"`
	Pic      string  `json:"pic"`
	SmallPic string  `json:"small_pic"`
}
type Item struct {
	Announcement *Section     `json:"announcement,omitempty"`
	Board        *BoardItem   `json:"board,omitempty"`
	Picture      *PictureItem `json:"picture,omitempty"`
}
type Set struct {
	ID       ids.UUID   `json:"id"`
	Family   string     `json:"family"`
	ServerID int32      `json:"server_id"`
	StartsAt time.Time  `json:"starts_at"`
	EndsAt   *time.Time `json:"ends_at,omitempty"`
	Items    []Item     `json:"items"`
}
type Catalog struct {
	Sets []Set `json:"sets"`
}

// Empty image values use packaged stock defaults. Nonempty values must use the
// prefix understood by OnlineImageSprite; media hosting/versioned basenames remain publisher responsibility.
func image(v string) bool { return v == "" || (strings.HasPrefix(v, "http://") && len(v) > 7) }
func (s Set) Validate() error {
	if s.ID.IsZero() || s.ServerID < 0 || s.StartsAt.IsZero() || (s.EndsAt != nil && !s.EndsAt.After(s.StartsAt)) {
		return ErrInvalid
	}
	if s.Family != Announcement && s.Family != Board && s.Family != Picture {
		return ErrInvalid
	}
	if s.Family == Announcement && s.ServerID != 0 {
		return ErrInvalid
	}
	seen := map[int64]bool{}
	for _, i := range s.Items {
		switch s.Family {
		case Announcement:
			if i.Announcement == nil || i.Board != nil || i.Picture != nil || !image(i.Announcement.URL) {
				return ErrInvalid
			}
		case Board:
			if i.Board == nil || i.Announcement != nil || i.Picture != nil || i.Board.ID <= 0 || i.Board.ID > MaxWireID || seen[i.Board.ID] || !image(i.Board.ImageURL) {
				return ErrInvalid
			}
			seen[i.Board.ID] = true
		case Picture:
			if i.Picture == nil || i.Announcement != nil || i.Board != nil || math.IsNaN(i.Picture.Weight) || math.IsInf(i.Picture.Weight, 0) || !image(i.Picture.Pic) || !image(i.Picture.SmallPic) {
				return ErrInvalid
			}
		}
	}
	return nil
}

// Canonical copies caller input and uses PostgreSQL's durable microsecond time precision.
func (s Set) Canonical() (Set, string, error) {
	b, e := json.Marshal(s)
	if e != nil {
		return Set{}, "", e
	}
	var out Set
	if e = json.Unmarshal(b, &out); e != nil {
		return Set{}, "", e
	}
	out.StartsAt = out.StartsAt.UTC().Truncate(time.Microsecond)
	if out.EndsAt != nil {
		t := out.EndsAt.UTC().Truncate(time.Microsecond)
		out.EndsAt = &t
	}
	if out.Items == nil {
		out.Items = []Item{}
	}
	for _, i := range out.Items {
		if i.Announcement != nil && i.Announcement.Contents == nil {
			i.Announcement.Contents = []string{}
		}
	}
	if e = out.Validate(); e != nil {
		return Set{}, "", e
	}
	b, e = json.Marshal(out)
	if e != nil {
		return Set{}, "", e
	}
	h := sha256.Sum256(b)
	return out, hex.EncodeToString(h[:]), nil
}

// View is a Publication-owned read snapshot; projections do not import application orchestration.
type View struct {
	Set     Set
	Visible bool
	HasRead bool
}
