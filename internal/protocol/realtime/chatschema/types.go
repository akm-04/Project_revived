package chatschema

import "unicode/utf8"

// Finite wire values only. The adapter bridges these to application-owned semantic types.
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
