package channelchatread

import (
	"context"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/arenastore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/leaguestore"
	"gxb.local/backend/v2/internal/adapters/postgres/topfloorstore"
	"gxb.local/backend/v2/internal/adapters/publicpresentation"
	"gxb.local/backend/v2/internal/application/channelchat"
	ar "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ArenaReportReader reads the canonical fight record and its stored enemy
// display behind a structured arena-reference chat.
type ArenaReportReader struct {
	TopFloor topfloorstore.Store
	Arena    arenastore.Store
	League   leaguestore.Store
	Content  contentstore.Store
}

func (r ArenaReportReader) ReadArenaTx(c context.Context, t tx.Tx, a ar.Admission, at time.Time, selection channelchat.RecordSelection) (channelchat.Owned[channelchat.Arena], error) {
	if t == nil || selection.PlayerID <= 0 || selection.RecordID <= 0 || selection.PlayerID != int64(a.Domain.Actor.PlayerID) {
		return channelchat.Owned[channelchat.Arena]{}, channelchat.ErrInvalidStructured
	}
	sender := identity.PlayerID(selection.PlayerID)
	if value, ok, err := r.topFloorRecord(c, t, at, sender, selection.RecordID); err != nil || ok {
		return value, err
	}
	if value, ok, err := r.arenaRecord(c, t, at, sender, selection.RecordID); err != nil || ok {
		return value, err
	}
	return r.leagueRecord(c, t, sender, selection.RecordID)
}

func (r ArenaReportReader) topFloorRecord(c context.Context, t tx.Tx, at time.Time, sender identity.PlayerID, recordID int64) (channelchat.Owned[channelchat.Arena], bool, error) {
	record, found, err := r.TopFloor.RecordTx(c, t, recordID)
	if err != nil || !found || record.Owner != sender {
		return channelchat.Owned[channelchat.Arena]{}, false, err
	}
	name, err := r.topFloorName(c, t, at, record.Opponent)
	if err != nil {
		return channelchat.Owned[channelchat.Arena]{}, false, err
	}
	return channelchat.Owned[channelchat.Arena]{
		Value:  channelchat.Arena{PlayerID: int64(sender), EnemyName: name, Time: record.At.Unix(), RecordID: record.ID, IsAttack: record.Attack},
		Source: channelchat.SourceObservation{Identity: fmt.Sprintf("top-floor-record:%d", record.ID), ContentRevisionID: record.At.Unix()},
	}, true, nil
}

func (r ArenaReportReader) arenaRecord(c context.Context, t tx.Tx, at time.Time, sender identity.PlayerID, recordID int64) (channelchat.Owned[channelchat.Arena], bool, error) {
	records, err := r.Arena.RecordsTx(c, t, sender)
	if err != nil {
		return channelchat.Owned[channelchat.Arena]{}, false, err
	}
	for _, record := range records {
		if record.ID != recordID || record.Owner != sender {
			continue
		}
		match, found, err := r.Arena.ReadMatchTx(c, t, record.MatchID, false)
		if err != nil {
			return channelchat.Owned[channelchat.Arena]{}, false, err
		}
		if !found {
			return channelchat.Owned[channelchat.Arena]{}, false, channelchat.ErrInvalidStructured
		}
		enemy := match.Defender
		if !record.Attack {
			enemy = match.Attacker
		}
		name, err := r.playerName(c, t, at, enemy)
		if err != nil {
			return channelchat.Owned[channelchat.Arena]{}, false, err
		}
		return channelchat.Owned[channelchat.Arena]{
			Value:  channelchat.Arena{PlayerID: int64(sender), EnemyName: name, Time: record.At.Unix(), RecordID: record.ID, IsAttack: record.Attack},
			Source: channelchat.SourceObservation{Identity: fmt.Sprintf("region-arena-record:%d", record.ID), ContentRevisionID: record.At.Unix()},
		}, true, nil
	}
	return channelchat.Owned[channelchat.Arena]{}, false, nil
}

func (r ArenaReportReader) leagueRecord(c context.Context, t tx.Tx, sender identity.PlayerID, recordID int64) (channelchat.Owned[channelchat.Arena], error) {
	matches, err := r.League.RecordsTx(c, t, sender)
	if err != nil {
		return channelchat.Owned[channelchat.Arena]{}, err
	}
	for _, match := range matches {
		if match.WireID != recordID || match.SettledAt == nil || match.Attacker != sender && match.Defender != sender {
			continue
		}
		attack := match.Attacker == sender
		enemy := match.SelfFace
		if attack {
			enemy = match.EnemyFace
		}
		return channelchat.Owned[channelchat.Arena]{
			Value:  channelchat.Arena{PlayerID: int64(sender), EnemyName: enemy.Name, Time: match.SettledAt.Unix(), RecordID: match.WireID, IsAttack: attack},
			Source: channelchat.SourceObservation{Identity: fmt.Sprintf("league-match:%d", match.WireID), ContentRevisionID: match.SettledAt.Unix()},
		}, nil
	}
	return channelchat.Owned[channelchat.Arena]{}, channelchat.ErrInvalidStructured
}

func (r ArenaReportReader) topFloorName(c context.Context, t tx.Tx, at time.Time, opponent d.Occupant) (string, error) {
	if !opponent.IsRobot() {
		return r.playerName(c, t, at, opponent.Player)
	}
	revision, err := r.Content.ActiveRevision(c, t)
	if err != nil {
		return "", err
	}
	catalog, err := r.Content.TopFloorCatalogTx(c, t, revision)
	if err != nil {
		return "", err
	}
	if _, found := catalog.Team(opponent.Robot); !found {
		return "", channelchat.ErrInvalidStructured
	}
	return catalog.RobotName(opponent.Robot), nil
}

func (r ArenaReportReader) playerName(c context.Context, t tx.Tx, at time.Time, player identity.PlayerID) (string, error) {
	revision, err := r.Content.ActiveRevision(c, t)
	if err != nil {
		return "", err
	}
	presentation, found, err := (publicpresentation.Reader{Queryer: t, Revision: revision, ObservedAt: at}).Minimal(c, player)
	if err != nil {
		return "", err
	}
	if !found {
		return "", channelchat.ErrInvalidStructured
	}
	return presentation.Name, nil
}

var _ channelchat.ArenaReader = ArenaReportReader{}
