package combat

import (
	"fmt"

	d "gxb.local/backend/v2/internal/domain/combat"
)

// AssistCapability is the TRIAL provenance of a battle table assist partner (D23c).
const AssistCapability = "BATTLE_ASSIST_PARTNER_V1"

// MonsterWaves is the shared PvE enemy lineup: each non-empty wave of the
// fight's battle row as table-shaped TEMPLATE Heroes, the stock
// populateWithTableID(monsterID) herosB (D23b).
func MonsterWaves(rules Rules, fightID int64) ([][]Participant, error) {
	waves, _, err := rules.BattleLineup(fightID)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", d.ErrInvalid, err)
	}
	out := make([][]Participant, 0, len(waves))
	for _, wave := range waves {
		participants := make([]Participant, 0, len(wave))
		for _, id := range wave {
			participants = append(participants, tableShaped(d.Template, id, nil))
		}
		out = append(out, participants)
	}
	return out, nil
}

// AssistTrial is the fight's assist partner in the 1-based slot of
// assist_partner as a TRIAL Hero for side A: the player fights with it and
// never owns it (SelectTeamWindow.checkIsAssistBattle).
func AssistTrial(rules Rules, fightID int64, slot int) (Participant, error) {
	_, partners, err := rules.BattleLineup(fightID)
	if err != nil {
		return Participant{}, fmt.Errorf("%w: %v", d.ErrInvalid, err)
	}
	if slot < 1 || slot > len(partners) {
		return Participant{}, fmt.Errorf("%w: fight %d has no assist slot %d", d.ErrInvalid, fightID, slot)
	}
	provenance := &d.Provenance{Capability: AssistCapability, Reference: fmt.Sprintf("battle/%d/%d", fightID, slot)}
	return tableShaped(d.Trial, partners[slot-1], provenance), nil
}

func tableShaped(origin d.Origin, tableID int64, provenance *d.Provenance) Participant {
	return Participant{Origin: origin, Kind: d.HeroActor, Identity: tableID, TemplateParams: map[string]any{"table_id": tableID}, Provenance: provenance}
}
