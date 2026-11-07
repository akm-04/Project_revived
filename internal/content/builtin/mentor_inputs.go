package builtin

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"sort"
	"strings"
)

// Mentor (My Class) content is pure source data. The future I9-10F application
// owner is the only consumer: it maps MentorRules into domain/mentor rules and
// supplies qualified facts; nothing here creates relationships, counters,
// rewards, routes or function-50 activation.
const MentorInputSchemaVersion = 2

var ErrMentorUnqualified = errors.New("mentor content: unqualified payload")

type MentorInputCatalog struct {
	SchemaVersion int             `json:"schema_version"`
	Missions      []MentorMission `json:"missions"`
	Rules         MentorRules     `json:"rules"`
	Function      MentorFunction  `json:"function_50"`
	Help          MentorHelp      `json:"help"`
	Gifts         []MentorGift    `json:"gifts"`
	Exam          MentorExam      `json:"exam"`
}

// MentorGift is one teacher_mission reward from gift.lua. Crystal and Exp are
// the source scalars; Items are exact stack quantities.
type MentorGift struct {
	ID      int64            `json:"id"`
	Crystal int64            `json:"crystal"`
	Exp     int64            `json:"exp"`
	Items   []MentorGiftItem `json:"items"`
}

type MentorGiftItem struct {
	ItemID   int64 `json:"item_id"`
	Quantity int64 `json:"quantity"`
}

// MentorExam is the graduation battle drop (campaign 22608, dropbox 9700001).
type MentorExam struct {
	CampaignID int64            `json:"campaign_id"`
	MissionID  int64            `json:"mission_id"`
	Items      []MentorGiftItem `json:"items"`
}

type MentorMission struct {
	ID          int64  `json:"id"`
	Description string `json:"desc"`
	Type        int64  `json:"type"`
	GiftID      int64  `json:"gift_id"`
	Category    int64  `json:"category"`
	Level       int64  `json:"level"`
	Condition   int64  `json:"condition"`
	ExtraInfo   int64  `json:"extra_info"`
	Refresh     int64  `json:"refresh"`
	IsHide      int64  `json:"is_hide"`
}

type MentorRules struct {
	RelationDaily             int64 `json:"relation_daily"`
	RelationMax               int64 `json:"relation_max"`
	TeacherLevel              int64 `json:"teacher_level"`
	RelationBrokenSeconds     int64 `json:"relation_broken_seconds"`
	RelationSendTimes         int64 `json:"relation_send_times"`
	RelationSendBrokenSeconds int64 `json:"relation_send_broken_seconds"`
	TerminateTimeLimitSeconds int64 `json:"terminate_time_limit_seconds"`
	FindingNum                int64 `json:"finding_num"`
	StudentLevelLimit         int64 `json:"student_level_limit"`
	FindingRange              int64 `json:"finding_range"`
	LevelRelation             int64 `json:"level_relation"`
	GiftIntimacy              int64 `json:"gift_intimacy"`
	PlayerOpenLevel           int64 `json:"player_open_level"`
	FinishMissionID           int64 `json:"finish_mission_id"`
	TeacherMinLevel           int64 `json:"teacher_min_level"`
}

type MentorFunction struct {
	ID             int64  `json:"id"`
	Name           string `json:"name"`
	Level          string `json:"level"`
	Condition      string `json:"condition"`
	Icon           string `json:"icon"`
	LevelTips      string `json:"level_tips"`
	IsOnLevelupWnd string `json:"is_on_levelup_wnd"`
	OpenControl    string `json:"open_control"`
	Tip            string `json:"tip"`
	IsFunctionShow string `json:"is_function_show"`
	FxNum          string `json:"fx_num"`
	FunctionPic    string `json:"function_pic"`
	FunctionDesc   string `json:"function_desc"`
}

type MentorHelp struct {
	Rule               string `json:"rule"`
	RuleTitle          string `json:"rule_title"`
	OpenTips           string `json:"open_tips"`
	MentorName         string `json:"mentor_name"`
	StudentName        string `json:"student_name"`
	MainTip1           string `json:"main_tip1"`
	MainTip2           string `json:"main_tip2"`
	SendTip1           string `json:"send_tip1"`
	SendTip2           string `json:"send_tip2"`
	SendTip3           string `json:"send_tip3"`
	SendTip4           string `json:"send_tip4"`
	SendTip5           string `json:"send_tip5"`
	SendTip6           string `json:"send_tip6"`
	SendTip7           string `json:"send_tip7"`
	FriendTip          string `json:"friend_tip"`
	RelationBrokenTip1 string `json:"relation_broken_tip1"`
	RelationBrokenTip2 string `json:"relation_broken_tip2"`
	Relation           string `json:"relation"`
}

func DecodeMentorInputCatalog(raw []byte) (MentorInputCatalog, error) {
	if err := rejectDuplicateObjectKeys(raw); err != nil {
		return MentorInputCatalog{}, fmt.Errorf("%w: %v", ErrMentorUnqualified, err)
	}
	var catalog MentorInputCatalog
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&catalog); err != nil {
		return MentorInputCatalog{}, fmt.Errorf("%w: %v", ErrMentorUnqualified, err)
	}
	if err := decoder.Decode(&struct{}{}); err != io.EOF {
		return MentorInputCatalog{}, fmt.Errorf("%w: trailing data", ErrMentorUnqualified)
	}
	if err := catalog.Validate(); err != nil {
		return MentorInputCatalog{}, err
	}
	return catalog, nil
}

// rejectDuplicateObjectKeys refuses a repeated member at any depth. The typed
// decoder keeps the last value silently, which could hide source drift.
func rejectDuplicateObjectKeys(raw []byte) error {
	decoder := json.NewDecoder(bytes.NewReader(raw))
	var scan func() error
	scan = func() error {
		token, err := decoder.Token()
		if err != nil {
			return err
		}
		delim, ok := token.(json.Delim)
		if !ok {
			return nil
		}
		switch delim {
		case '{':
			seen := map[string]bool{}
			for decoder.More() {
				keyToken, err := decoder.Token()
				if err != nil {
					return err
				}
				key, ok := keyToken.(string)
				if !ok {
					return errors.New("object member is not a string")
				}
				if seen[key] {
					return fmt.Errorf("duplicate object key %q", key)
				}
				seen[key] = true
				if err := scan(); err != nil {
					return err
				}
			}
			_, err = decoder.Token()
			return err
		case '[':
			for decoder.More() {
				if err := scan(); err != nil {
					return err
				}
			}
			_, err = decoder.Token()
			return err
		}
		return nil
	}
	if err := scan(); err != nil {
		return err
	}
	if _, err := decoder.Token(); !errors.Is(err, io.EOF) {
		return errors.New("trailing data")
	}
	return nil
}

const mentorHelpDigest = "2817d9051f3c72850935095fe003d08651796a11f1d8e431b23a31dea8f88371"

func (help MentorHelp) Digest() string {
	values := map[string]string{
		"rule": help.Rule, "rule_title": help.RuleTitle, "open_tips": help.OpenTips,
		"mentor_name": help.MentorName, "student_name": help.StudentName,
		"main_tip1": help.MainTip1, "main_tip2": help.MainTip2,
		"send_tip1": help.SendTip1, "send_tip2": help.SendTip2,
		"send_tip3": help.SendTip3, "send_tip4": help.SendTip4,
		"send_tip5": help.SendTip5, "send_tip6": help.SendTip6, "send_tip7": help.SendTip7,
		"friend_tip": help.FriendTip, "relation_broken_tip1": help.RelationBrokenTip1,
		"relation_broken_tip2": help.RelationBrokenTip2, "relation": help.Relation,
	}
	keys := make([]string, 0, len(values))
	for key := range values {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	var builder strings.Builder
	for _, key := range keys {
		builder.WriteString(key)
		builder.WriteByte('=')
		builder.WriteString(values[key])
		builder.WriteByte('\n')
	}
	sum := sha256.Sum256([]byte(builder.String()))
	return hex.EncodeToString(sum[:])
}

var mentorExpectedRules = MentorRules{
	RelationDaily: 100, RelationMax: 3000, TeacherLevel: 60, RelationBrokenSeconds: 86400,
	RelationSendTimes: 3, RelationSendBrokenSeconds: 172800, TerminateTimeLimitSeconds: 86400,
	FindingNum: 20, StudentLevelLimit: 90, FindingRange: 100, LevelRelation: 3,
	GiftIntimacy: 100, PlayerOpenLevel: 10, FinishMissionID: 100025, TeacherMinLevel: 60,
}

var mentorExpectedFunction = MentorFunction{
	ID: 50, Name: "My Class", Level: "8|10", Condition: "60", Icon: "1", LevelTips: "0",
	IsOnLevelupWnd: "1", OpenControl: "1", Tip: "Unlock when Academy level reaches 10",
}

func (catalog MentorInputCatalog) Validate() error {
	if catalog.SchemaVersion != MentorInputSchemaVersion {
		return mentorError("schema version %d", catalog.SchemaVersion)
	}
	if catalog.Rules != mentorExpectedRules {
		return mentorError("misc rules drift")
	}
	if catalog.Function != mentorExpectedFunction {
		return mentorError("function 50 definition drift")
	}
	if catalog.Help.Digest() != mentorHelpDigest {
		return mentorError("help string drift")
	}
	if len(catalog.Missions) != 25 {
		return mentorError("mission count %d", len(catalog.Missions))
	}
	typeCounts, categoryCounts := map[int64]int{}, map[int64]int{}
	identifiers := map[int64]bool{}
	giftIdentifiers := map[int64]bool{}
	var hidden []int64
	for index, mission := range catalog.Missions {
		if mission.ID != int64(100001+index) {
			return mentorError("mission identity %d at position %d", mission.ID, index)
		}
		if identifiers[mission.ID] {
			return mentorError("duplicate mission %d", mission.ID)
		}
		identifiers[mission.ID] = true
		if mission.Description == "" || mission.GiftID <= 0 || mission.Level < 0 || mission.Condition < 0 || mission.ExtraInfo < 0 {
			return mentorError("mission %d fields", mission.ID)
		}
		if mission.Type != 1 && mission.Type != 2 {
			return mentorError("mission %d type %d", mission.ID, mission.Type)
		}
		if mission.Refresh != 0 && mission.Refresh != 1 || mission.IsHide != 0 && mission.IsHide != 1 {
			return mentorError("mission %d flags", mission.ID)
		}
		if mission.GiftID < 90008004 || mission.GiftID > 90008028 || giftIdentifiers[mission.GiftID] {
			return mentorError("mission %d gift reference %d", mission.ID, mission.GiftID)
		}
		giftIdentifiers[mission.GiftID] = true
		validCategory := mission.Type == 1 && mission.Category >= 1 && mission.Category <= 4 || mission.Type == 2 && mission.Category >= 5 && mission.Category <= 7
		if !validCategory {
			return mentorError("mission %d category %d", mission.ID, mission.Category)
		}
		typeCounts[mission.Type]++
		categoryCounts[mission.Category]++
		if mission.IsHide == 1 {
			hidden = append(hidden, mission.ID)
		}
	}
	expectedTypes := map[int64]int{1: 21, 2: 4}
	expectedCategories := map[int64]int{1: 4, 2: 8, 3: 6, 4: 3, 5: 1, 6: 2, 7: 1}
	if !sameCounts(typeCounts, expectedTypes) || !sameCounts(categoryCounts, expectedCategories) {
		return mentorError("mission type/category counts")
	}
	if len(hidden) != 2 || hidden[0] != 100005 || hidden[1] != 100006 {
		return mentorError("hidden mission identities")
	}
	finish := catalog.Missions[catalog.Rules.FinishMissionID-100001]
	if finish.Type != 2 || finish.Category != 7 || finish.IsHide != 0 || finish.Level != 90 {
		return mentorError("finish mission definition")
	}
	if len(catalog.Gifts) != len(catalog.Missions) {
		return mentorError("gift count %d", len(catalog.Gifts))
	}
	for index, gift := range catalog.Gifts {
		mission := catalog.Missions[index]
		if gift.ID != mission.GiftID || gift.Crystal < 0 || gift.Exp < 0 || len(gift.Items) == 0 {
			return mentorError("gift %d fields", gift.ID)
		}
		seen := map[int64]bool{}
		for _, item := range gift.Items {
			if item.ItemID <= 0 || item.Quantity <= 0 || seen[item.ItemID] {
				return mentorError("gift %d item %d", gift.ID, item.ItemID)
			}
			seen[item.ItemID] = true
		}
	}
	if catalog.Exam.CampaignID != 22608 || catalog.Exam.MissionID != catalog.Rules.FinishMissionID || len(catalog.Exam.Items) != 3 {
		return mentorError("graduation exam definition")
	}
	for _, item := range catalog.Exam.Items {
		if item.ItemID <= 0 || item.Quantity != 1 {
			return mentorError("graduation exam item %d", item.ItemID)
		}
	}
	return nil
}

// VisibleMissions drops source rows that the client itself filters out
// (teacher_mission is_hide=1, SocialSystem.lua:1268). Hidden rows remain in the
// catalog as SOURCE and are never grantable.
func (catalog MentorInputCatalog) VisibleMissions() []MentorMission {
	visible := make([]MentorMission, 0, len(catalog.Missions))
	for _, mission := range catalog.Missions {
		if mission.IsHide == 0 {
			visible = append(visible, mission)
		}
	}
	return visible
}

func sameCounts(actual, expected map[int64]int) bool {
	if len(actual) != len(expected) {
		return false
	}
	for key, value := range expected {
		if actual[key] != value {
			return false
		}
	}
	return true
}

func mentorError(format string, arguments ...any) error {
	return fmt.Errorf("%w: "+format, append([]any{ErrMentorUnqualified}, arguments...)...)
}
