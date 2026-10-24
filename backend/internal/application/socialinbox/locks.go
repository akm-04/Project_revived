package socialinbox

import (
	"errors"
	"fmt"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
)

const LockRankNotice uint16 = 370
const NoticeSourceUniqueConstraint = "social_notices_recipient_player_id_source_kind_source_key_key"

var ErrInvalidLockKey = errors.New("invalid social inbox lock key")

func NoticeLockKey(recipient identity.PlayerID, id NoticeID) (lockkey.Key, error) {
	if !recipient.Valid() || !id.Valid() {
		return lockkey.Key{}, ErrInvalidLockKey
	}
	return lockkey.New(LockRankNotice, "social-inbox.notice", lockkey.String(fmt.Sprintf("%d:%d", recipient, id)))
}

// NoticeSourceLockKey is available before a numeric notice identity exists and
// orders typed-source materialization at the same owner rank. The database
// unique source key remains the authoritative creation fence.
func NoticeSourceLockKey(recipient identity.PlayerID, source SourceKey) (lockkey.Key, error) {
	if !recipient.Valid() || source.Validate() != nil {
		return lockkey.Key{}, ErrInvalidLockKey
	}
	return lockkey.New(LockRankNotice, "social-inbox.notice-source", lockkey.String(fmt.Sprintf("%d:%s:%s", recipient, source.Kind, source.Key)))
}
