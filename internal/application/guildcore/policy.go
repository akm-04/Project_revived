package guildcore

import (
	"errors"
	"unicode/utf8"
)

// Policy is the immutable Guild-core policy value consumed by the application
// layer. Source compilation/provenance belongs to the content owner; this type
// deliberately contains only the qualified values required to authorize Guild
// operations.
type Policy struct {
	CreateLevel                 int64
	CreateCrystalCost           int64
	RenameCrystalCost           int64
	GuildApplicantCap           int64
	NameMinChars                int
	NameMaxChars                int
	JoinOtherAfterLeaveSeconds  int64
	ReapplyPreviousGuildSeconds int64
	JoinLevelMin                int64
	JoinLevelMax                int64
	JoinsLimit                  int64
	OutgoingApplicationCap      int64
	BulletinMinChars            int
	BulletinMaxChars            int
	MemberCap                   int64
	DeputyLimit                 int64
	InitialVitality             int64
	InviteSendLimit             int64
	InviteLifetimeSeconds       int64
	GuildIcons                  []int64
}

// PolicyBinding binds an immutable application policy value to the exact
// source/content revision that produced it. The revision is persisted in Guild
// facts/receipts; application code does not import the content compiler.
type PolicyBinding struct {
	Policy   Policy
	Revision string
}

func (b PolicyBinding) Validate() error {
	if b.Revision == "" {
		return errors.New("guild policy revision missing")
	}
	return b.Policy.Validate()
}

func (p Policy) Validate() error {
	if p.CreateLevel <= 0 || p.CreateCrystalCost <= 0 || p.RenameCrystalCost <= 0 || p.GuildApplicantCap <= 0 || p.NameMinChars < 0 || p.NameMaxChars < p.NameMinChars || p.JoinOtherAfterLeaveSeconds < 0 || p.ReapplyPreviousGuildSeconds < 0 || p.JoinLevelMin <= 0 || p.JoinLevelMax < p.JoinLevelMin || p.JoinsLimit <= 0 || p.OutgoingApplicationCap <= 0 || p.BulletinMinChars < 0 || p.BulletinMaxChars < p.BulletinMinChars || p.MemberCap <= 0 || p.DeputyLimit <= 0 || p.InitialVitality < 0 || p.InviteSendLimit <= 0 || p.InviteLifetimeSeconds <= 0 || len(p.GuildIcons) == 0 {
		return errors.New("invalid guild core policy binding")
	}
	seen := make(map[int64]struct{}, len(p.GuildIcons))
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
	if !utf8.ValidString(s) {
		return false
	}
	n := len([]rune(s))
	return n >= p.NameMinChars && n <= p.NameMaxChars
}

func (p Policy) ValidBulletin(s string) bool {
	if !utf8.ValidString(s) {
		return false
	}
	n := len([]rune(s))
	return n >= p.BulletinMinChars && n <= p.BulletinMaxChars
}
