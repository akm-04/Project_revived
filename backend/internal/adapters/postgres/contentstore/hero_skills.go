package contentstore

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (s Store) HeroRawSkillsActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, errors.New("Hero skill nil content queryer")
	}
	a, ok, e := s.ReadActiveSummary(ctx, s.Queryer)
	if e != nil || !ok {
		return "", false, e
	}
	good, e := manifestHasCapability(a.ManifestJSON, a.Activation.RevisionID, "HERO_RAW_SKILLS_I7C2A")
	return a.Activation.RevisionID, good, e
}
func (Store) HeroSkillCatalogTx(ctx context.Context, q tx.Queryer, revision string, tableID int64) (character.HeroSkillCatalog, error) {
	out := character.HeroSkillCatalog{TableID: tableID, ContentRevision: revision}
	if q == nil || len(revision) != 64 || tableID <= 0 {
		return out, errors.New("Hero skill invalid content request")
	}
	var raw string
	if e := q.QueryRow(ctx, contentqueries.ReadHeroSkillSlots, revision, tableID).Scan(&raw); e != nil {
		return out, e
	}
	var slots []builtin.HeroSkillSlot
	if e := json.Unmarshal([]byte(raw), &slots); e != nil {
		return out, e
	}
	if len(slots) != 6 {
		return out, errors.New("Hero skill incomplete content slots")
	}
	for i, s := range slots {
		if len(s.ChoiceIDs) == 0 || len(s.ChoiceIDs) != len(s.BookItemIDs) || s.DefaultID != s.ChoiceIDs[0] {
			return out, errors.New("Hero skill inconsistent catalog")
		}
		for j, id := range s.ChoiceIDs {
			out.Choices[i] = append(out.Choices[i], character.HeroSkillOption{ID: id, BookItemID: s.BookItemIDs[j]})
		}
	}
	return out, out.Validate()
}
