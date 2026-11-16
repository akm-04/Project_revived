package guildstore

// auditDetails is the guild_audit_log.details object. Role is a pointer because
// 0 (Member) is a meaningful stored role and must stay distinct from an absent key.
type auditDetails struct {
	Role *int64 `json:"role,omitempty"`
}
