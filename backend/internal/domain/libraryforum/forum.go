// Package libraryforum owns the stock hero and pet forum boards: cross-player
// global comments and likes across logical servers.
package libraryforum

import (
	"errors"
	"time"
	"unicode/utf8"

	"gxb.local/backend/v2/internal/domain/identity"
)

const (
	HeroForum       int64 = 1
	PetForum        int64 = 2
	MaxCommentRunes       = 32
	MaxPageRows           = 50
	MaxLiveComments       = 200
)

var ErrInvalid = errors.New("library forum: invalid fact")

// Key identifies one global forum board.
type Key struct {
	ForumType int64
	TableID   int64
}

func (k Key) Validate() error {
	if (k.ForumType != HeroForum && k.ForumType != PetForum) || k.TableID <= 0 {
		return ErrInvalid
	}
	return nil
}

// Comment is the one comment an author may have on a board. A later post
// replaces the text and advances UpdatedAt.
type Comment struct {
	Key       Key
	Author    identity.PlayerID
	Text      string
	CreatedAt time.Time
	UpdatedAt time.Time
}

func (c Comment) Validate() error {
	if c.Key.Validate() != nil || !c.Author.Valid() || !ValidText(c.Text) || c.CreatedAt.IsZero() || c.UpdatedAt.Before(c.CreatedAt) {
		return ErrInvalid
	}
	return nil
}

// Reaction is one viewer's like on an author's comment.
type Reaction struct {
	Key       Key
	Author    identity.PlayerID
	Viewer    identity.PlayerID
	CreatedAt time.Time
}

func (r Reaction) Validate() error {
	if r.Key.Validate() != nil || !r.Author.Valid() || !r.Viewer.Valid() || r.CreatedAt.IsZero() {
		return ErrInvalid
	}
	return nil
}

// Listed is a stored comment with its derived like count and the viewer's own
// like bit.
type Listed struct {
	Author      identity.PlayerID
	Text        string
	CreatedAt   time.Time
	UpdatedAt   time.Time
	Likes       int64
	ViewerLiked bool
}

func ValidText(text string) bool {
	if !utf8.ValidString(text) {
		return false
	}
	n := utf8.RuneCountInString(text)
	return n >= 1 && n <= MaxCommentRunes
}
