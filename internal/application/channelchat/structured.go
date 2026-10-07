package channelchat

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	ar "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
	"unicode/utf8"
)

// Kind is semantic. Wire discriminators and serialization belong to adapters.
type Kind string

const (
	ArenaReference              Kind = "arena-reference"
	PeakReference               Kind = "peak-reference"
	ScratchShare                Kind = "scratch-share"
	IllusionInvitation          Kind = "illusion-invitation"
	OccultInvitation            Kind = "occult-invitation"
	AdventureIllusionInvitation Kind = "adventure-illusion-invitation"
	DefenseInvitation           Kind = "defense-invitation"
	CampMessage                 Kind = "camp-message"
	RagnarokInvitation          Kind = "ragnarok-invitation"
)

var ErrProviderUnavailable = errors.New("canonical structured owner unavailable")
var ErrInvalidStructured = errors.New("invalid structured selection or owner observation")

type RecordSelection struct{ PlayerID, RecordID int64 }
type ScratchSelection struct{}
type RoomSelection struct{ RoomID int64 }
type CampSelection struct {
	DisplayRoomID, ClaimedCamp int64
	Text                       string
	EmoticonID                 int64
	IsEmoticon                 bool
}
type Selector struct {
	Kind                                                   Kind
	Arena, Peak                                            *RecordSelection
	Scratch                                                *ScratchSelection
	Illusion, Occult, AdventureIllusion, Defense, Ragnarok *RoomSelection
	Camp                                                   *CampSelection
}

func (s Selector) Valid() bool {
	n := 0
	for _, present := range []bool{s.Arena != nil, s.Peak != nil, s.Scratch != nil, s.Illusion != nil, s.Occult != nil, s.AdventureIllusion != nil, s.Defense != nil, s.Camp != nil, s.Ragnarok != nil} {
		if present {
			n++
		}
	}
	if n != 1 {
		return false
	}
	switch s.Kind {
	case ArenaReference:
		return s.Arena != nil && s.Arena.PlayerID > 0 && s.Arena.RecordID > 0
	case PeakReference:
		return s.Peak != nil && s.Peak.PlayerID > 0 && s.Peak.RecordID > 0
	case ScratchShare:
		return s.Scratch != nil
	case IllusionInvitation:
		return s.Illusion != nil && s.Illusion.RoomID > 0
	case OccultInvitation:
		return s.Occult != nil && s.Occult.RoomID > 0
	case AdventureIllusionInvitation:
		return s.AdventureIllusion != nil && s.AdventureIllusion.RoomID > 0
	case DefenseInvitation:
		return s.Defense != nil && s.Defense.RoomID > 0
	case RagnarokInvitation:
		return s.Ragnarok != nil && s.Ragnarok.RoomID > 0
	case CampMessage:
		return s.Camp != nil && s.Camp.DisplayRoomID >= 0 && s.Camp.ClaimedCamp >= 0 && ((!s.Camp.IsEmoticon && s.Camp.Text != "" && utf8.ValidString(s.Camp.Text) && utf8.RuneCountInString(s.Camp.Text) <= 40 && s.Camp.EmoticonID == 0) || (s.Camp.IsEmoticon && s.Camp.Text == "" && s.Camp.EmoticonID > 0))
	}
	return false
}

type Profile struct {
	PlayerID                                                    int64
	Name                                                        string
	Level, AvatarID, AvatarFrameID, ConquerLevel, ConquerLoopID int64
}
type Arena struct {
	PlayerID              int64
	PlayerName, EnemyName string
	Time, RecordID        int64
	IsAttack              bool
}
type Peak struct {
	PlayerID              int64
	PlayerName, EnemyName string
	Time, RecordID        int64
	IsAttack, IsWin       bool
	Attack, Defense       Profile
}
type Scratch struct {
	PlayerID                          int64
	PlayerName                        string
	RandomCards, Cards, ScratchStatus []int64
}
type Invitation struct {
	RoomID   int64
	BossName string
	Level    int64
}
type Occult struct{ RoomID, ChapterID, Force int64 }
type Defense struct{ RoomID, Level int64 }
type Camp struct {
	DisplayRoomID, CampID int64
	Text                  string
	EmoticonID            int64
	IsEmoticon            bool
}

// EventID is owner identity; DisplayRoomID (including zero) is never authority.
type CampAudience struct{ EventID, CampID, DisplayRoomID int64 }
type Structured struct {
	Kind                                  Kind
	Arena                                 *Arena
	Peak                                  *Peak
	Scratch                               *Scratch
	Illusion, AdventureIllusion, Ragnarok *Invitation
	Occult                                *Occult
	Defense                               *Defense
	Camp                                  *Camp
}
type SourceObservation struct {
	Identity          string
	ContentRevisionID int64
}
type Owned[T any] struct {
	Value  T
	Source SourceObservation
}
type Observation struct {
	Sender playerpresentation.Minimal
	At     time.Time
}
type ObservationReader interface {
	ObserveTx(context.Context, tx.Tx, ar.Admission, bool) (Observation, error)
}
type PreparedStructured struct {
	Sender   playerpresentation.Minimal
	Message  Structured
	Source   SourceObservation
	Audience *CampAudience
}
type ArenaReader interface {
	ReadArenaTx(context.Context, tx.Tx, ar.Admission, time.Time, RecordSelection) (Owned[Arena], error)
}
type PeakReader interface {
	ReadPeakTx(context.Context, tx.Tx, ar.Admission, time.Time, RecordSelection) (Owned[Peak], error)
}
type ScratchReader interface {
	ReadScratchTx(context.Context, tx.Tx, ar.Admission, time.Time, ScratchSelection) (Owned[Scratch], error)
}
type IllusionReader interface {
	ReadIllusionTx(context.Context, tx.Tx, ar.Admission, time.Time, RoomSelection) (Owned[Invitation], error)
}
type OccultReader interface {
	ReadOccultTx(context.Context, tx.Tx, ar.Admission, time.Time, RoomSelection) (Owned[Occult], error)
}
type AdventureIllusionReader interface {
	ReadAdventureIllusionTx(context.Context, tx.Tx, ar.Admission, time.Time, RoomSelection) (Owned[Invitation], error)
}
type DefenseReader interface {
	ReadDefenseTx(context.Context, tx.Tx, ar.Admission, time.Time, RoomSelection) (Owned[Defense], error)
}
type RagnarokReader interface {
	ReadRagnarokTx(context.Context, tx.Tx, ar.Admission, time.Time, RoomSelection) (Owned[Invitation], error)
}
type CampReader interface {
	ReadCampTx(context.Context, tx.Tx, ar.Admission, time.Time, CampSelection) (Owned[Camp], CampAudience, error)
	AuthorizeCampRecipientTx(context.Context, tx.Tx, ar.Admission, time.Time, CampAudience) error
}

// Explicit owner seams, all nil in current production. This is not a dispatch registry.
type Owners struct {
	Arena             ArenaReader
	Peak              PeakReader
	Scratch           ScratchReader
	Illusion          IllusionReader
	Occult            OccultReader
	AdventureIllusion AdventureIllusionReader
	Defense           DefenseReader
	Ragnarok          RagnarokReader
	Camp              CampReader
}

func (o Owners) Available(k Kind) bool {
	switch k {
	case ArenaReference:
		return o.Arena != nil
	case PeakReference:
		return o.Peak != nil
	case ScratchShare:
		return o.Scratch != nil
	case IllusionInvitation:
		return o.Illusion != nil
	case OccultInvitation:
		return o.Occult != nil
	case AdventureIllusionInvitation:
		return o.AdventureIllusion != nil
	case DefenseInvitation:
		return o.Defense != nil
	case RagnarokInvitation:
		return o.Ragnarok != nil
	case CampMessage:
		return o.Camp != nil
	}
	return false
}
func (s Service) PrepareStructured(ctx context.Context, a ar.Admission, selector Selector) (PreparedStructured, error) {
	if !selector.Valid() {
		return PreparedStructured{}, ErrInvalidStructured
	}
	if !s.Owners.Available(selector.Kind) {
		return PreparedStructured{}, ErrProviderUnavailable
	}
	if selector.Arena != nil && selector.Arena.PlayerID != int64(a.Domain.Actor.PlayerID) || selector.Peak != nil && selector.Peak.PlayerID != int64(a.Domain.Actor.PlayerID) {
		return PreparedStructured{}, ErrInvalidStructured
	}
	reader, ok := s.Reader.(ObservationReader)
	if !ok {
		return PreparedStructured{}, ErrIncompleteRead
	}
	op, e := s.Operations.New(policy.Set{})
	if e != nil {
		return PreparedStructured{}, e
	}
	var private PreparedStructured
	result, e := s.Runner.Run(ctx, op, ReadProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, scope tx.Scope) error {
		observed, e := reader.ObserveTx(c, scope.Tx, a, true)
		if e != nil {
			return e
		}
		if observed.At.IsZero() {
			return ErrInvalidStructured
		}
		p := PreparedStructured{Sender: observed.Sender, Message: Structured{Kind: selector.Kind}}
		t := scope.Tx
		at := observed.At
		switch selector.Kind {
		case ArenaReference:
			v, e := s.Owners.Arena.ReadArenaTx(c, t, a, at, *selector.Arena)
			if e != nil {
				return e
			}
			p.Source = v.Source
			p.Message.Arena = &v.Value
			if v.Value.RecordID != selector.Arena.RecordID {
				return ErrInvalidStructured
			}
			p.Message.Arena.PlayerID = int64(a.Domain.Actor.PlayerID)
			p.Message.Arena.PlayerName = observed.Sender.Name
		case PeakReference:
			v, e := s.Owners.Peak.ReadPeakTx(c, t, a, at, *selector.Peak)
			if e != nil {
				return e
			}
			p.Source = v.Source
			p.Message.Peak = &v.Value
			if v.Value.RecordID != selector.Peak.RecordID {
				return ErrInvalidStructured
			}
			p.Message.Peak.PlayerID = int64(a.Domain.Actor.PlayerID)
			p.Message.Peak.PlayerName = observed.Sender.Name
		case ScratchShare:
			v, e := s.Owners.Scratch.ReadScratchTx(c, t, a, at, *selector.Scratch)
			if e != nil {
				return e
			}
			p.Source = v.Source
			p.Message.Scratch = &v.Value
			p.Message.Scratch.PlayerID = int64(a.Domain.Actor.PlayerID)
			p.Message.Scratch.PlayerName = observed.Sender.Name
			p.Message.Scratch.RandomCards = cloneStructuredArray(v.Value.RandomCards)
			p.Message.Scratch.Cards = cloneStructuredArray(v.Value.Cards)
			p.Message.Scratch.ScratchStatus = cloneStructuredArray(v.Value.ScratchStatus)
		case IllusionInvitation:
			v, e := s.Owners.Illusion.ReadIllusionTx(c, t, a, at, *selector.Illusion)
			if e != nil {
				return e
			}
			p.Source = v.Source
			p.Message.Illusion = &v.Value
			if v.Value.RoomID != selector.Illusion.RoomID {
				return ErrInvalidStructured
			}
		case OccultInvitation:
			v, e := s.Owners.Occult.ReadOccultTx(c, t, a, at, *selector.Occult)
			if e != nil {
				return e
			}
			p.Source = v.Source
			p.Message.Occult = &v.Value
			if v.Value.RoomID != selector.Occult.RoomID {
				return ErrInvalidStructured
			}
		case AdventureIllusionInvitation:
			v, e := s.Owners.AdventureIllusion.ReadAdventureIllusionTx(c, t, a, at, *selector.AdventureIllusion)
			if e != nil {
				return e
			}
			p.Source = v.Source
			p.Message.AdventureIllusion = &v.Value
			if v.Value.RoomID != selector.AdventureIllusion.RoomID {
				return ErrInvalidStructured
			}
		case DefenseInvitation:
			v, e := s.Owners.Defense.ReadDefenseTx(c, t, a, at, *selector.Defense)
			if e != nil {
				return e
			}
			p.Source = v.Source
			p.Message.Defense = &v.Value
			if v.Value.RoomID != selector.Defense.RoomID {
				return ErrInvalidStructured
			}
		case RagnarokInvitation:
			v, e := s.Owners.Ragnarok.ReadRagnarokTx(c, t, a, at, *selector.Ragnarok)
			if e != nil {
				return e
			}
			p.Source = v.Source
			p.Message.Ragnarok = &v.Value
			if v.Value.RoomID != selector.Ragnarok.RoomID {
				return ErrInvalidStructured
			}
		case CampMessage:
			v, audience, e := s.Owners.Camp.ReadCampTx(c, t, a, at, *selector.Camp)
			if e != nil {
				return e
			}
			if audience.EventID <= 0 || audience.CampID < 0 || audience.DisplayRoomID < 0 || v.Value.CampID != audience.CampID || v.Value.DisplayRoomID != audience.DisplayRoomID || audience.DisplayRoomID != selector.Camp.DisplayRoomID || audience.CampID != selector.Camp.ClaimedCamp || v.Value.Text != selector.Camp.Text || v.Value.EmoticonID != selector.Camp.EmoticonID || v.Value.IsEmoticon != selector.Camp.IsEmoticon {
				return ErrInvalidStructured
			}
			p.Source = v.Source
			p.Message.Camp = &v.Value
			p.Audience = &audience
		default:
			return ErrInvalidStructured
		}
		if p.Source.Identity == "" || len(p.Source.Identity) > 256 || p.Source.ContentRevisionID <= 0 {
			return ErrInvalidStructured
		}
		private = p
		return nil
	})
	if e != nil {
		return PreparedStructured{}, e
	}
	if result.Outcome != tx.DefiniteCommit {
		return PreparedStructured{}, ErrIncompleteRead
	}
	return private, nil
}
func (s Service) AuthorizeStructuredRecipient(ctx context.Context, a ar.Admission, p PreparedStructured) error {
	if p.Message.Kind != CampMessage {
		return s.AuthorizeRecipient(ctx, a)
	}
	if s.Owners.Camp == nil {
		return ErrProviderUnavailable
	}
	if p.Audience == nil || p.Audience.EventID <= 0 {
		return ErrInvalidStructured
	}
	reader, ok := s.Reader.(ObservationReader)
	if !ok {
		return ErrIncompleteRead
	}
	op, e := s.Operations.New(policy.Set{})
	if e != nil {
		return e
	}
	result, e := s.Runner.Run(ctx, op, ReadProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, scope tx.Scope) error {
		observed, e := reader.ObserveTx(c, scope.Tx, a, false)
		if e != nil {
			return e
		}
		if observed.At.IsZero() {
			return ErrInvalidStructured
		}
		return s.Owners.Camp.AuthorizeCampRecipientTx(c, scope.Tx, a, observed.At, *p.Audience)
	})
	if e != nil {
		return e
	}
	if result.Outcome != tx.DefiniteCommit {
		return ErrIncompleteRead
	}
	return nil
}

func cloneStructuredArray(a []int64) []int64 {
	if a == nil {
		return nil
	}
	return append([]int64{}, a...)
}
