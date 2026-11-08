package gmquestion

import (
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

func TestQuestionPreservesTextAndRejectsInvalidFacts(t *testing.T) {
	operation, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	original := Question{Operation: operation, Player: 125001, Server: 1, Message: "  Need help 世界  ", AskedAt: time.Unix(100, 0).UTC()}
	if err := original.Validate(); err != nil {
		t.Fatal(err)
	}
	for _, name := range []string{"empty", "space", "nul", "bad-utf8", "too-long", "foreign-server", "zero-id", "zero-time"} {
		t.Run(name, func(t *testing.T) {
			question := original
			switch name {
			case "empty":
				question.Message = ""
			case "space":
				question.Message = " \n\t"
			case "nul":
				question.Message = "a\x00b"
			case "bad-utf8":
				question.Message = string([]byte{255})
			case "too-long":
				question.Message = strings.Repeat("a", MaxMessageBytes+1)
			case "foreign-server":
				question.Server = identity.LogicalServerID(2)
			case "zero-id":
				question.Operation = ids.UUID{}
			case "zero-time":
				question.AskedAt = time.Time{}
			}
			if question.Validate() == nil {
				t.Fatal("invalid question accepted", name)
			}
		})
	}
	original.Message = strings.Repeat("a", MaxMessageBytes)
	if err := original.Validate(); err != nil {
		t.Fatal("maximum valid message refused", err)
	}
}
