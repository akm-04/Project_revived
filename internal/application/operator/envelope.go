// Package operator is the I11A operator command bus (I11A_OPERATOR_COMMANDS_V1):
// envelope validation, idempotency and the audit row. It owns no domain rule;
// each command's owner validates and applies its payload inside the bus
// transaction.
package operator

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"regexp"
	"strings"
	"unicode/utf8"
)

const (
	RoleRoot = "root"

	StateAccepted = "ACCEPTED"
	StateApplied  = "APPLIED"
	StateRefused  = "REFUSED"
	StateFailed   = "FAILED"

	CodeEnvelopeInvalid = "OPERATOR_ENVELOPE_INVALID"
	CodeKeyReused       = "OPERATOR_KEY_REUSED"
	CodeRevisionStale   = "OPERATOR_REVISION_STALE"
	CodeUnknownCommand  = "OPERATOR_UNKNOWN_COMMAND"
	CodePayloadInvalid  = "OPERATOR_PAYLOAD_INVALID"

	// MaxCommandBodyBytes bounds a command body on the operator listener; the
	// agent sizes its own cap below this because it re-marshals the envelope.
	MaxCommandBodyBytes = 32 << 20
)

var (
	moduleCommandPattern = regexp.MustCompile(`^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$`)
	scopePattern         = regexp.MustCompile(`^server:[1-9][0-9]{0,9}$`)
)

// Envelope is the O2 command envelope every operator command carries.
type Envelope struct {
	Principal        string `json:"principal"`
	Role             string `json:"role"`
	Scope            string `json:"scope"`
	Reason           string `json:"reason"`
	SemanticKey      string `json:"semantic_key"`
	ExpectedRevision *int64 `json:"expected_revision,omitempty"`
}

func lengthWithin(value string, low, high int) bool {
	count := utf8.RuneCountInString(value)
	return utf8.ValidString(value) && count >= low && count <= high
}

func (envelope Envelope) Validate() error {
	principalValid := lengthWithin(envelope.Principal, 1, 64) && strings.TrimSpace(envelope.Principal) == envelope.Principal
	scopeValid := envelope.Scope == "global" || scopePattern.MatchString(envelope.Scope)
	reasonValid := lengthWithin(envelope.Reason, 1, 500) && strings.TrimSpace(envelope.Reason) != ""
	keyValid := lengthWithin(envelope.SemanticKey, 1, 128) && strings.TrimSpace(envelope.SemanticKey) == envelope.SemanticKey
	revisionValid := envelope.ExpectedRevision == nil || *envelope.ExpectedRevision >= 0
	if principalValid && envelope.Role == RoleRoot && scopeValid && reasonValid && keyValid && revisionValid {
		return nil
	}
	return Refuse(CodeEnvelopeInvalid, "the command envelope is missing a field or a field is invalid", nil)
}

// Command is one validated submission, as the owner's handler sees it.
type Command struct {
	ModuleCommand string
	Envelope      Envelope
	Payload       json.RawMessage
	PayloadSHA256 string
}

// NewCommand validates the envelope and the command name and fixes the payload
// hash over a canonical form, so whitespace and key order do not change it.
func NewCommand(moduleCommand string, envelope Envelope, payload json.RawMessage) (Command, error) {
	if !moduleCommandPattern.MatchString(moduleCommand) {
		return Command{}, Refuse(CodeUnknownCommand, "unknown command", nil)
	}
	if err := envelope.Validate(); err != nil {
		return Command{}, err
	}
	canonical, err := canonicalJSON(payload)
	if err != nil {
		return Command{}, Refuse(CodePayloadInvalid, "the payload is not one JSON value", nil)
	}
	digest := sha256.Sum256(canonical)
	return Command{ModuleCommand: moduleCommand, Envelope: envelope, Payload: canonical, PayloadSHA256: hex.EncodeToString(digest[:])}, nil
}

func canonicalJSON(payload json.RawMessage) ([]byte, error) {
	if len(bytes.TrimSpace(payload)) == 0 {
		payload = json.RawMessage("{}")
	}
	decoder := json.NewDecoder(bytes.NewReader(payload))
	decoder.UseNumber()
	var value any
	if err := decoder.Decode(&value); err != nil {
		return nil, err
	}
	if decoder.More() {
		return nil, errors.New("trailing data after the payload")
	}
	return json.Marshal(value)
}

// Refusal is a permanent, typed refusal: the HTTP edge answers 409 with Code.
// A handler returns it to record the command as REFUSED with no other effect.
type Refusal struct {
	Code    string `json:"error_code"`
	Message string `json:"message"`
	Detail  any    `json:"detail,omitempty"`
}

func (refusal *Refusal) Error() string { return fmt.Sprintf("%s: %s", refusal.Code, refusal.Message) }

func Refuse(code, message string, detail any) *Refusal {
	return &Refusal{Code: code, Message: message, Detail: detail}
}

// StaleRevision is the refusal a handler returns when Envelope.ExpectedRevision
// does not match the owner's current revision.
func StaleRevision(current int64) *Refusal {
	return Refuse(CodeRevisionStale, "the state changed since it was read", map[string]int64{"current_revision": current})
}
