package guildstore

import (
	"encoding/json"
	"errors"
	"io"
	"strings"
)

// AuditDetails is the guild_audit_log.details object. Role is a pointer because
// 0 (Member) is a meaningful stored role and must stay distinct from an absent key.
type AuditDetails struct {
	Role *int64 `json:"role,omitempty"`
}

func parseAuditDetails(details string) (AuditDetails, error) {
	if details == "" {
		return AuditDetails{}, nil
	}
	decoder := json.NewDecoder(strings.NewReader(details))
	decoder.DisallowUnknownFields()
	var parsed AuditDetails
	if err := decoder.Decode(&parsed); err != nil {
		return AuditDetails{}, err
	}
	if _, err := decoder.Token(); !errors.Is(err, io.EOF) {
		return AuditDetails{}, errors.New("trailing data after guild audit details")
	}
	return parsed, nil
}
