package contentstore

import (
	mentor "gxb.local/backend/v2/internal/application/mentor"
	"gxb.local/backend/v2/internal/content/builtin"
)

// MentorCatalog maps the compiled source catalog into the application view.
// Mentor rules are immutable source facts, not a revision-scoped deployment
// artifact.
func (Store) MentorCatalog() (mentor.Catalog, error) {
	source, err := builtin.MentorCatalog()
	if err != nil {
		return mentor.Catalog{}, err
	}
	return mentorCatalog(source), nil
}

func mentorCatalog(source builtin.MentorInputCatalog) mentor.Catalog {
	out := mentor.Catalog{
		Missions: make([]mentor.CatalogMission, 0, len(source.Missions)),
		Rules: mentor.CatalogRules{
			TeacherLevel: source.Rules.TeacherLevel, TeacherMinLevel: source.Rules.TeacherMinLevel,
			PlayerOpenLevel: source.Rules.PlayerOpenLevel, StudentLevelLimit: source.Rules.StudentLevelLimit,
			RelationSendBrokenSeconds: source.Rules.RelationSendBrokenSeconds, RelationBrokenSeconds: source.Rules.RelationBrokenSeconds,
			TerminateTimeLimitSeconds: source.Rules.TerminateTimeLimitSeconds, RelationSendTimes: source.Rules.RelationSendTimes,
			GiftIntimacy: source.Rules.GiftIntimacy, RelationMax: source.Rules.RelationMax,
			LevelRelation: source.Rules.LevelRelation, FinishMissionID: source.Rules.FinishMissionID,
		},
		Gifts: make([]mentor.CatalogGift, 0, len(source.Gifts)),
		Exam:  mentor.CatalogExam{CampaignID: source.Exam.CampaignID, MissionID: source.Exam.MissionID, Items: catalogItems(source.Exam.Items)},
	}
	for _, mission := range source.Missions {
		out.Missions = append(out.Missions, mentor.CatalogMission{ID: mission.ID, GiftID: mission.GiftID, Type: mission.Type, Category: mission.Category, Condition: mission.Condition, Level: mission.Level, IsHide: mission.IsHide})
	}
	for _, gift := range source.Gifts {
		out.Gifts = append(out.Gifts, mentor.CatalogGift{ID: gift.ID, Crystal: gift.Crystal, Exp: gift.Exp, Items: catalogItems(gift.Items)})
	}
	return out
}

func catalogItems(items []builtin.MentorGiftItem) []mentor.CatalogGiftItem {
	out := make([]mentor.CatalogGiftItem, 0, len(items))
	for _, item := range items {
		out = append(out, mentor.CatalogGiftItem{ItemID: item.ItemID, Quantity: item.Quantity})
	}
	return out
}
