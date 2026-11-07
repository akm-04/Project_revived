package mentor

// Catalog is the application-facing view of the compiled source catalog. The
// content adapter maps builtin.MentorInputCatalog into these types so the
// application layer does not depend on the content layer.
type Catalog struct {
	Missions []CatalogMission
	Rules    CatalogRules
	Gifts    []CatalogGift
	Exam     CatalogExam
}

type CatalogMission struct {
	ID        int64
	GiftID    int64
	Type      int64
	Category  int64
	Condition int64
	Level     int64
	IsHide    int64
}

type CatalogRules struct {
	TeacherLevel              int64
	TeacherMinLevel           int64
	PlayerOpenLevel           int64
	StudentLevelLimit         int64
	RelationSendBrokenSeconds int64
	RelationBrokenSeconds     int64
	TerminateTimeLimitSeconds int64
	RelationSendTimes         int64
	GiftIntimacy              int64
	RelationMax               int64
	LevelRelation             int64
	FinishMissionID           int64
}

type CatalogGift struct {
	ID      int64
	Crystal int64
	Exp     int64
	Items   []CatalogGiftItem
}

type CatalogGiftItem struct {
	ItemID   int64
	Quantity int64
}

type CatalogExam struct {
	CampaignID int64
	MissionID  int64
	Items      []CatalogGiftItem
}
