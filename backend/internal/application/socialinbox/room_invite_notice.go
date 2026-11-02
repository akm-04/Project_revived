package socialinbox

import (
	"fmt"
	"strconv"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

const RoomInviteSourceKind = "social-room-invite.v1"

// PRIVATE_POLICY retention: a room invite is readable for one day after the
// room last invited the player.
const RoomInviteRetention = 24 * time.Hour

const (
	RoomInviteIllusionNoticeType int16 = 6
	RoomInviteOccultNoticeType   int16 = 7
	RoomInviteCoopNoticeType     int16 = 8
	RoomInviteDefenseNoticeType  int16 = 9
)

// RoomInvite is the canonical tuple a room family materializes for one target.
type RoomInvite struct {
	Recipient  identity.PlayerID
	NoticeType int16
	RoomID     int64
	ParadiseID int64
	ChapterID  int64
	Force      int64
}

func (r RoomInvite) Validate() error {
	if !r.Recipient.Valid() || r.NoticeType < RoomInviteIllusionNoticeType || r.NoticeType > RoomInviteDefenseNoticeType {
		return ErrInvalidNotice
	}
	if r.RoomID < 1 || r.ParadiseID < 0 || r.ChapterID < 0 || r.Force < 0 {
		return ErrInvalidNotice
	}
	return nil
}

// SourceKey is the unique typed source identity; values are never client JSON.
func (r RoomInvite) SourceKey() (SourceKey, error) {
	if r.Validate() != nil {
		return SourceKey{}, ErrInvalidNotice
	}
	return SourceKey{Kind: RoomInviteSourceKind, Key: fmt.Sprintf("%d:%d:%d:%d:%d", r.NoticeType, r.RoomID, r.ParadiseID, r.ChapterID, r.Force)}, nil
}

func RoomInviteFamily(s SourceKey) bool { return s.Kind == RoomInviteSourceKind }

// ParseRoomInviteSource accepts only the canonical integer form it re-encodes.
func ParseRoomInviteSource(recipient identity.PlayerID, noticeType int16, key string) (RoomInvite, error) {
	var invite RoomInvite
	parts := strings.Split(key, ":")
	if len(parts) != 5 {
		return invite, ErrInvalidNotice
	}
	values := make([]int64, 5)
	for index, raw := range parts {
		value, err := strconv.ParseInt(raw, 10, 64)
		if err != nil || strconv.FormatInt(value, 10) != raw {
			return invite, ErrInvalidNotice
		}
		values[index] = value
	}
	invite = RoomInvite{Recipient: recipient, NoticeType: noticeType, RoomID: values[1], ParadiseID: values[2], ChapterID: values[3], Force: values[4]}
	if values[0] != int64(noticeType) || invite.Validate() != nil {
		return invite, ErrInvalidNotice
	}
	canonical, err := invite.SourceKey()
	if err != nil || canonical.Key != key {
		return invite, ErrInvalidNotice
	}
	return invite, nil
}

func RoomInviteTuple(n Notice) (RoomInvite, error) {
	if !RoomInviteFamily(n.Source) {
		return RoomInvite{}, ErrInvalidNotice
	}
	invite, err := ParseRoomInviteSource(n.RecipientPlayerID, n.NoticeType, n.Source.Key)
	if err != nil {
		return RoomInvite{}, err
	}
	return invite, nil
}

func ValidateRoomInviteLifecycle(n Notice) error {
	if n.Validate() != nil || !n.NoticeID.WireSafe() {
		return ErrInvalidNotice
	}
	if _, err := RoomInviteTuple(n); err != nil {
		return err
	}
	if !n.RelatedPlayerID.Valid() && !n.RelatedPlayerDeleted {
		return ErrInvalidNotice
	}
	return nil
}
