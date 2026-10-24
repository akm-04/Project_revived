package stockruntime

import (
	cc "gxb.local/backend/v2/internal/application/channelchat"
	wire "gxb.local/backend/v2/internal/protocol/realtime/chatschema"
)

// Explicit composition-edge bridge; I0 layer matrix remains unchanged.
func semanticStructuredSelector(v wire.Selector) cc.Selector {
	s := cc.Selector{Kind: cc.Kind(v.Kind)}
	if v.Arena != nil {
		x := cc.RecordSelection(*v.Arena)
		s.Arena = &x
	}
	if v.Peak != nil {
		x := cc.RecordSelection(*v.Peak)
		s.Peak = &x
	}
	if v.Illusion != nil {
		x := cc.RoomSelection(*v.Illusion)
		s.Illusion = &x
	}
	if v.Occult != nil {
		x := cc.RoomSelection(*v.Occult)
		s.Occult = &x
	}
	if v.AdventureIllusion != nil {
		x := cc.RoomSelection(*v.AdventureIllusion)
		s.AdventureIllusion = &x
	}
	if v.Defense != nil {
		x := cc.RoomSelection(*v.Defense)
		s.Defense = &x
	}
	if v.Ragnarok != nil {
		x := cc.RoomSelection(*v.Ragnarok)
		s.Ragnarok = &x
	}
	if v.Scratch != nil {
		s.Scratch = &cc.ScratchSelection{}
	}
	if v.Camp != nil {
		x := cc.CampSelection(*v.Camp)
		s.Camp = &x
	}
	return s
}
func wireStructuredValue(v cc.Structured) wire.Structured {
	s := wire.Structured{Kind: wire.Kind(v.Kind)}
	if v.Arena != nil {
		x := wire.Arena(*v.Arena)
		s.Arena = &x
	}
	if v.Scratch != nil {
		x := wire.Scratch(*v.Scratch)
		s.Scratch = &x
	}
	if v.Illusion != nil {
		x := wire.Invitation(*v.Illusion)
		s.Illusion = &x
	}
	if v.Occult != nil {
		x := wire.Occult(*v.Occult)
		s.Occult = &x
	}
	if v.AdventureIllusion != nil {
		x := wire.Invitation(*v.AdventureIllusion)
		s.AdventureIllusion = &x
	}
	if v.Defense != nil {
		x := wire.Defense(*v.Defense)
		s.Defense = &x
	}
	if v.Ragnarok != nil {
		x := wire.Invitation(*v.Ragnarok)
		s.Ragnarok = &x
	}
	if v.Camp != nil {
		x := wire.Camp(*v.Camp)
		s.Camp = &x
	}
	if v.Peak != nil {
		p := v.Peak
		s.Peak = &wire.Peak{PlayerID: p.PlayerID, PlayerName: p.PlayerName, EnemyName: p.EnemyName, Time: p.Time, RecordID: p.RecordID, IsAttack: p.IsAttack, IsWin: p.IsWin, Attack: wire.Profile(p.Attack), Defense: wire.Profile(p.Defense)}
	}
	return s
}
