package builtin

import (
	"errors"
)

const GuildCoreBroadcastRevision = "0c74f31996a5cc3290a63541814495f5e830cbd5a56a1554e99cf66071a2b963"

// GuildBroadcastPolicy is one immutable finite policy row. It records the
// selected reconstruction policy, without claiming original-server behavior.
type GuildBroadcastPolicy struct {
	StoragePolicyID   string `json:"storage_policy_id"`
	SchemaVersion     int    `json:"schema_version"`
	PolicyID          string `json:"policy_id"`
	TextSourceSHA256  string `json:"text_source_sha256"`
	TitleHalfUnits    int    `json:"title_half_units"`
	BodyHalfUnits     int    `json:"body_half_units"`
	TitleBytes        int    `json:"title_bytes"`
	BodyBytes         int    `json:"body_bytes"`
	MemberCap         int    `json:"member_cap"`
	GuildCoreRevision string `json:"guild_core_revision"`
	MailNamespace     string `json:"mail_namespace"`
	MailCategory      int    `json:"mail_category"`
	MailPlatform      string `json:"mail_platform"`
	MailShown         bool   `json:"mail_shown"`
	Attachments       bool   `json:"attachments"`
	Expiry            bool   `json:"expiry"`
}

func (p GuildBroadcastPolicy) Validate() error {
	if p.StoragePolicyID != "PG_UTF8_TEXT_NO_NUL_V1" || p.SchemaVersion != 1 || p.PolicyID != "GUILD_BROADCAST_STOCK_TEXTLEN_V1" || p.TextSourceSHA256 != "6e56c7342e889d7ae8d41fe47cb06f66832227efe702f3863f693ee7ba84ffad" || p.TitleHalfUnits != 20 || p.BodyHalfUnits != 200 || p.TitleBytes != 80 || p.BodyBytes != 800 || p.MemberCap != 50 || p.GuildCoreRevision != GuildCoreBroadcastRevision || p.MailNamespace != "NORMAL" || p.MailCategory != 0 || p.MailPlatform != "ANY" || !p.MailShown || p.Attachments || p.Expiry {
		return errors.New("unqualified Guild broadcast content policy")
	}
	return nil
}
