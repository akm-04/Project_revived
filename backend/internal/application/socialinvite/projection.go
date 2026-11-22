package socialinvite

import (
	domain "gxb.local/backend/v2/internal/domain/socialinvite"
)

// MissionState is the client-shaped invitation mission row. The client indexes
// mission_id and can_award only (InviteFriendsWindow.lua:168-186).
type MissionState struct {
	MissionID int64
	CanAward  bool
}

// Projection is the finite MID 384/385 read value: durable mission states and
// invited-player facts plus the caller's own code and invitor.
type Projection struct {
	InviteCode  string
	InvitorID   int64
	InvitorName string
	Missions    []MissionState
	Invitees    []InviteeFacts
}

func BuildProjection(snapshot Snapshot, catalog MissionCatalog) (Projection, error) {
	out := Projection{InviteCode: snapshot.InviteCode, InvitorID: int64(snapshot.InvitorID), InvitorName: snapshot.InvitorName, Missions: []MissionState{}, Invitees: snapshot.Invitees}
	if catalog.Validate() != nil {
		return Projection{}, ErrFacts
	}
	claimed := make(map[int64]bool, len(snapshot.Claimed))
	for _, mission := range snapshot.Claimed {
		claimed[mission] = true
	}
	facts := make([]domain.InviteeFacts, 0, len(snapshot.Invitees))
	for _, invitee := range snapshot.Invitees {
		facts = append(facts, invitee.domainFacts())
	}
	for _, mission := range catalog {
		progress, err := domain.Progress(domain.Mission{ID: mission.ID, Type: mission.Type, Threshold: mission.Threshold}, facts)
		if err != nil {
			return Projection{}, ErrFacts
		}
		// PRIVATE_POLICY (D493 item 5): every source mission row is independently
		// evaluated; the undocumented pre/next task graph is not invented.
		out.Missions = append(out.Missions, MissionState{MissionID: mission.ID, CanAward: !claimed[mission.ID] && progress >= mission.RequiredCount})
	}
	return out, nil
}

// MissionList is the client-shaped missions array.
func (p Projection) MissionList() []any {
	rows := make([]any, 0, len(p.Missions))
	for _, mission := range p.Missions {
		rows = append(rows, map[string]any{"mission_id": mission.MissionID, "can_award": mission.CanAward})
	}
	return rows
}

// InvitePlayerList is the client-shaped invite_players array. PRIVATE_POLICY:
// lev carries the highest currently owned battle girl level (D493 item 5).
func (p Projection) InvitePlayerList() []any {
	rows := make([]any, 0, len(p.Invitees))
	for _, invitee := range p.Invitees {
		rows = append(rows, map[string]any{"player_name": invitee.Name, "region_name": invitee.RegionName, "lev": invitee.HighestOwnedHeroLevel, "partner_num": invitee.OwnedHeroCount, "charge": invitee.ChargeTotal, "avatar_id": invitee.AvatarID})
	}
	return rows
}

func (p Projection) ReadBody() map[string]any {
	return map[string]any{"missions": p.MissionList(), "invite_players": p.InvitePlayerList(), "invite_code": p.InviteCode, "invitor_id": p.InvitorID, "invitor_name": p.InvitorName}
}

// NewInfos is the MID 385 reload fragment the client indexes at
// InviteFriends.lua:72-79.
func (p Projection) NewInfos() map[string]any {
	return map[string]any{"missions": p.MissionList(), "invite_players": p.InvitePlayerList()}
}
