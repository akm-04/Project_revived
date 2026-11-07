package gmquestion

import (
	"errors"
	"strings"
	"time"
	"unicode/utf8"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/ids"
)

const MaxMessageBytes = 4096
const HistoryLimit = 100

var ErrQuestion = errors.New("gm question: invalid inquiry")

type Question struct {
	Operation ids.UUID
	Player    identity.PlayerID
	Server    identity.LogicalServerID
	Message   string
	AskedAt   time.Time
}

func (question Question) Validate() error {
	if question.Operation.IsZero() || !question.Player.Valid() || !question.Server.Valid() || logicalserver.PlayerRegion(question.Player) != question.Server || question.AskedAt.IsZero() || question.AskedAt.Unix() < 0 {
		return ErrQuestion
	}
	if len(question.Message) > MaxMessageBytes || !utf8.ValidString(question.Message) || strings.TrimSpace(question.Message) == "" || strings.ContainsRune(question.Message, 0) {
		return ErrQuestion
	}
	return nil
}
