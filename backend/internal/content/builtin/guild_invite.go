package builtin

import "errors"

type GuildInvitePolicy struct {
	GuildModelSHA       string `json:"guild_model_source_sha256"`
	SocialModelSHA      string `json:"social_model_source_sha256"`
	SchemaVersion       int    `json:"schema_version"`
	PolicyID            string `json:"policy_id"`
	GuildCoreRevision   string `json:"guild_core_revision"`
	NoticeType          int    `json:"notice_type"`
	SourceIdentity      string `json:"source_identity"`
	ExpiryPolicy        string `json:"expiry_policy"`
	GenerationPolicy    string `json:"generation_policy"`
	JoinPolicy          string `json:"join_policy"`
	NamePolicy          string `json:"name_policy"`
	ObservationPolicy   string `json:"observation_policy"`
	InviteMID           int    `json:"stock_invite_mid"`
	AcceptMID           int    `json:"stock_accept_mid"`
	DismissMID          int    `json:"stock_dismiss_mid"`
	BaseMID             int    `json:"stock_base_mid"`
	ListMID             int    `json:"stock_list_mid"`
	FirstPurpose        int    `json:"reload_first_materialized_purpose"`
	InvalidationPurpose int    `json:"reload_invalidation_purpose"`
	WindowLimit         int    `json:"window_limit"`
	ScanLimit           int    `json:"scan_limit"`
	ScanPage            int    `json:"scan_page"`
	CleanupDefault      int    `json:"cleanup_default"`
	CleanupMax          int    `json:"cleanup_max"`
	EnumsSHA            string `json:"enums_source_sha256"`
	MIDSHA              string `json:"mid_source_sha256"`
	WindowSHA           string `json:"window_source_sha256"`
	DismissJoins        bool   `json:"dismiss_joins_guild"`
	DismissCancels      bool   `json:"dismiss_cancels_invite"`
	HistoricalBackfill  bool   `json:"historical_backfill"`
}

func (p GuildInvitePolicy) Validate() error {
	if p.GuildModelSHA != "c744e6f256a796a98613911372c1821b3e02f21d38480184df9c095373bd64f9" || p.SocialModelSHA != "ec5bea26bbdcbb67ca2ea80ab5ad7e9fb53ee613a3ffcbb13ae5dfef9ddf0502" || p.SchemaVersion != 1 || p.PolicyID != "GUILD_INVITE_PRESENTATION_V1" || p.GuildCoreRevision != GuildCoreBroadcastRevision || p.NoticeType != 10 || p.SourceIdentity != "guild_id:recipient_player_id:invite_generation" || p.ExpiryPolicy != "GUILD_INVITE_STRICT_EXPIRY_V1" || p.GenerationPolicy != "GUILD_INVITE_RETAINED_PAIR_CURSOR_V1" || p.JoinPolicy != "GUILD_INVITE_JOIN_BOUNDARY_V1" || p.NamePolicy != "GUILD_INVITE_NAME_SNAPSHOT_V1" || p.ObservationPolicy != "GUILD_INVITE_SHARED_OBSERVATION_V1" || p.InviteMID != 2563 || p.AcceptMID != 2564 || p.DismissMID != 184 || p.BaseMID != 176 || p.ListMID != 189 || p.FirstPurpose != 7 || p.InvalidationPurpose != 8 || p.WindowLimit != 50 || p.ScanLimit != 4096 || p.ScanPage != 128 || p.CleanupDefault != 32 || p.CleanupMax != 1000 || p.EnumsSHA != "15340bd89fe7c6f150ccfd4a5cd2a2f0e8e73c89dfae9ac3388376a4799901f3" || p.MIDSHA != "026a20b29d97624979777a68c64c749254031604057ff42aa8f8254c3e35b5af" || p.WindowSHA != "5d0c3e1e20d69b7009ff52bf94ad438c6a133c8b099301d951bd1e413b90f112" || p.DismissJoins || p.DismissCancels || p.HistoricalBackfill {
		return errors.New("unqualified Guild Invite content policy")
	}
	return nil
}
