package builtin

import "testing"

func TestGuildBroadcastPolicyRejectsUnqualifiedBehavior(t *testing.T) {
	c, e := Load()
	if e != nil {
		t.Fatal(e)
	}
	for _, mutate := range []func(*GuildBroadcastPolicy){func(p *GuildBroadcastPolicy) { p.TitleHalfUnits = 21 }, func(p *GuildBroadcastPolicy) { p.TextSourceSHA256 = "unknown" }, func(p *GuildBroadcastPolicy) { p.GuildCoreRevision = "unknown" }, func(p *GuildBroadcastPolicy) { p.MailNamespace = "REGION" }, func(p *GuildBroadcastPolicy) { p.MailCategory = 1 }, func(p *GuildBroadcastPolicy) { p.Attachments = true }, func(p *GuildBroadcastPolicy) { p.Expiry = true }, func(p *GuildBroadcastPolicy) { p.MemberCap = 51 }} {
		p := c.GuildBroadcast
		mutate(&p)
		if p.Validate() == nil {
			t.Fatal("unqualified policy accepted")
		}
	}
}
