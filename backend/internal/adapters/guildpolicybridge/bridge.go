package guildpolicybridge

import (
	"gxb.local/backend/v2/internal/application/guildcore"
	"gxb.local/backend/v2/internal/content/guildpolicy"
)

// FromBuiltin converts the source/provenance-owning content artifact into the
// immutable application policy value consumed by Guild core. The copy keeps
// the content and application dependency directions separate.
func FromBuiltin(b guildpolicy.Builtin) (guildcore.PolicyBinding, error) {
	p := b.Policy
	out := guildcore.PolicyBinding{
		Revision: b.Revision,
		Policy: guildcore.Policy{
			CreateLevel:                 p.CreateLevel,
			CreateCrystalCost:           p.CreateCrystalCost,
			RenameCrystalCost:           p.RenameCrystalCost,
			GuildApplicantCap:           p.GuildApplicantCap,
			NameMinChars:                p.NameMinChars,
			NameMaxChars:                p.NameMaxChars,
			JoinOtherAfterLeaveSeconds:  p.JoinOtherAfterLeaveSeconds,
			ReapplyPreviousGuildSeconds: p.ReapplyPreviousGuildSeconds,
			JoinLevelMin:                p.JoinLevelMin,
			JoinLevelMax:                p.JoinLevelMax,
			JoinsLimit:                  p.JoinsLimit,
			OutgoingApplicationCap:      p.OutgoingApplicationCap,
			BulletinMinChars:            p.BulletinMinChars,
			BulletinMaxChars:            p.BulletinMaxChars,
			MemberCap:                   p.MemberCap,
			DeputyLimit:                 p.DeputyLimit,
			InitialVitality:             p.InitialVitality,
			InviteSendLimit:             p.InviteSendLimit,
			InviteLifetimeSeconds:       p.InviteLifetimeSeconds,
			GuildIcons:                  append([]int64(nil), p.GuildIcons...),
		},
	}
	if err := out.Validate(); err != nil {
		return guildcore.PolicyBinding{}, err
	}
	return out, nil
}
