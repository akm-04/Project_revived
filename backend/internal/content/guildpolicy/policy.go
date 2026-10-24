package guildpolicy

import (
	"crypto/sha256"
	_ "embed"
	"encoding/hex"
	"encoding/json"
	"errors"
	"unicode/utf8"
)

//go:embed generated/guild_core_policy.json
var builtinJSON []byte

type Policy struct {
	Profile                       string  `json:"profile"`
	SourceCurrentMiscSHA256       string  `json:"source_current_misc_sha256"`
	SourceHistoricalMiscSHA256    string  `json:"source_historical_misc_sha256"`
	SourceCurrentMessageSHA256    string  `json:"source_current_message_sha256"`
	SourceHistoricalMessageSHA256 string  `json:"source_historical_message_sha256"`
	CreateLevel                   int64   `json:"create_level"`
	CreateCrystalCost             int64   `json:"create_crystal_cost"`
	RenameCrystalCost             int64   `json:"rename_crystal_cost"`
	GuildApplicantCap             int64   `json:"guild_applicant_cap"`
	NameMinChars                  int     `json:"name_min_chars"`
	NameMaxChars                  int     `json:"name_max_chars"`
	JoinOtherAfterLeaveSeconds    int64   `json:"join_other_after_leave_seconds"`
	ReapplyPreviousGuildSeconds   int64   `json:"reapply_previous_guild_seconds"`
	JoinLevelMin                  int64   `json:"join_level_min"`
	JoinLevelMax                  int64   `json:"join_level_max"`
	JoinsLimit                    int64   `json:"joins_limit"`
	OutgoingApplicationCap        int64   `json:"outgoing_application_cap"`
	BulletinMinChars              int     `json:"bulletin_min_chars"`
	BulletinMaxChars              int     `json:"bulletin_max_chars"`
	MemberCap                     int64   `json:"member_cap"`
	DeputyLimit                   int64   `json:"deputy_limit"`
	LeaderOfflineSeconds          int64   `json:"leader_offline_seconds"`
	InitialVitality               int64   `json:"initial_vitality"`
	InviteSendLimit               int64   `json:"invite_send_limit"`
	InviteLifetimeSeconds         int64   `json:"invite_lifetime_seconds"`
	JoinLimitWindow               string  `json:"join_limit_window"`
	InviteSendWindow              string  `json:"invite_send_window"`
	IconFramePolicy               string  `json:"icon_frame_policy"`
	TextPolicy                    string  `json:"text_policy"`
	GuildIDAllocator              string  `json:"guild_id_allocator"`
	OfflineLeaderSuccession       string  `json:"offline_leader_succession"`
	GuildIcons                    []int64 `json:"guild_icons"`
}

type Builtin struct {
	Policy   Policy
	Revision string
}

func LoadBuiltin() (Builtin, error) {
	var p Policy
	decErr := json.Unmarshal(builtinJSON, &p)
	if decErr != nil {
		return Builtin{}, decErr
	}
	if err := p.Validate(); err != nil {
		return Builtin{}, err
	}
	sum := sha256.Sum256(builtinJSON)
	return Builtin{Policy: p, Revision: hex.EncodeToString(sum[:])}, nil
}

func (p Policy) Validate() error {
	if p.Profile == "" || p.SourceCurrentMiscSHA256 == "" || p.SourceHistoricalMiscSHA256 == "" || p.SourceCurrentMessageSHA256 == "" || p.SourceHistoricalMessageSHA256 == "" || p.CreateLevel <= 0 || p.CreateCrystalCost <= 0 || p.RenameCrystalCost <= 0 || p.MemberCap <= 0 || p.DeputyLimit <= 0 || p.JoinsLimit <= 0 || p.InviteSendLimit <= 0 || p.InviteLifetimeSeconds <= 0 || p.JoinLimitWindow == "" || p.InviteSendWindow == "" || p.GuildIDAllocator == "" || len(p.GuildIcons) == 0 {
		return errors.New("invalid guild core policy")
	}
	seen := map[int64]struct{}{}
	for _, id := range p.GuildIcons {
		if id <= 0 {
			return errors.New("invalid guild icon")
		}
		if _, ok := seen[id]; ok {
			return errors.New("duplicate guild icon")
		}
		seen[id] = struct{}{}
	}
	return nil
}
func (p Policy) AllowsIcon(id int64) bool {
	for _, v := range p.GuildIcons {
		if v == id {
			return true
		}
	}
	return false
}
func (p Policy) ValidName(s string) bool {
	return utf8.ValidString(s) && len([]rune(s)) >= p.NameMinChars && len([]rune(s)) <= p.NameMaxChars
}
func (p Policy) ValidBulletin(s string) bool {
	return utf8.ValidString(s) && len([]rune(s)) >= p.BulletinMinChars && len([]rune(s)) <= p.BulletinMaxChars
}
