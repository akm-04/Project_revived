package builtin_test

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"os"
	"reflect"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/domain/mentor"
)

// mentorGoldenCatalog is the verified compiled catalog shared by production
// (builtin.MentorCatalog) and this test.
// from the exact c7e archive (sha256 c7e98789...) and the pinned
// teacher_mission.lua member (sha256 212ad92d...). It is a test fixture, not a
// generated deployment artifact.
const mentorGoldenCatalog = builtin.MentorCatalogJSON

func decodeMentorGolden(t *testing.T) builtin.MentorInputCatalog {
	t.Helper()
	catalog, err := builtin.DecodeMentorInputCatalog([]byte(mentorGoldenCatalog))
	if err != nil {
		t.Fatal(err)
	}
	return catalog
}

// mentorGoldenCatalogSHA256 is shared with tools/mentor_content.py's
// MENTOR_CATALOG_SHA256: the pinned source archive must compile to exactly this
// golden fixture, and neither side may drift alone.
const mentorGoldenCatalogSHA256 = "fe6c878703af4efcdcd575ffac292b31806238c9d8ad7134f088a572a1057519"

func TestDecodeMentorInputCatalogGoldenSource(t *testing.T) {
	sum := sha256.Sum256([]byte(mentorGoldenCatalog))
	if hex.EncodeToString(sum[:]) != mentorGoldenCatalogSHA256 {
		t.Fatalf("golden fixture digest drift: %s", hex.EncodeToString(sum[:]))
	}
	catalog := decodeMentorGolden(t)
	if catalog.SchemaVersion != builtin.MentorInputSchemaVersion {
		t.Fatalf("schema %d", catalog.SchemaVersion)
	}
	if len(catalog.Missions) != 25 {
		t.Fatalf("missions %d", len(catalog.Missions))
	}
	typeCounts, categoryCounts := map[int64]int{}, map[int64]int{}
	var hidden []int64
	for index, mission := range catalog.Missions {
		if mission.ID != int64(100001+index) || mission.GiftID != int64(90008004+index) {
			t.Fatalf("mission %d identity/gift drift: %+v", index, mission)
		}
		typeCounts[mission.Type]++
		categoryCounts[mission.Category]++
		if mission.IsHide == 1 {
			hidden = append(hidden, mission.ID)
		}
	}
	if !reflect.DeepEqual(typeCounts, map[int64]int{1: 21, 2: 4}) || !reflect.DeepEqual(categoryCounts, map[int64]int{1: 4, 2: 8, 3: 6, 4: 3, 5: 1, 6: 2, 7: 1}) {
		t.Fatalf("type/category counts: %v %v", typeCounts, categoryCounts)
	}
	if !reflect.DeepEqual(hidden, []int64{100005, 100006}) {
		t.Fatalf("hidden missions: %v", hidden)
	}
	finish := catalog.Missions[24]
	if finish.ID != 100025 || finish.Type != 2 || finish.Category != 7 || finish.Level != 90 || finish.ExtraInfo != 22608 || finish.IsHide != 0 {
		t.Fatalf("finish mission: %+v", finish)
	}
	if catalog.Rules.RelationDaily != 100 || catalog.Rules.RelationMax != 3000 || catalog.Rules.TeacherLevel != 60 || catalog.Rules.RelationBrokenSeconds != 86400 || catalog.Rules.RelationSendTimes != 3 || catalog.Rules.RelationSendBrokenSeconds != 172800 || catalog.Rules.TerminateTimeLimitSeconds != 86400 || catalog.Rules.FindingNum != 20 || catalog.Rules.StudentLevelLimit != 90 || catalog.Rules.FindingRange != 100 || catalog.Rules.LevelRelation != 3 || catalog.Rules.GiftIntimacy != 100 || catalog.Rules.PlayerOpenLevel != 10 || catalog.Rules.FinishMissionID != 100025 || catalog.Rules.TeacherMinLevel != 60 {
		t.Fatalf("rules: %+v", catalog.Rules)
	}
	if catalog.Function.ID != 50 || catalog.Function.Name != "My Class" || catalog.Function.Level != "8|10" || catalog.Function.Condition != "60" || catalog.Function.Tip != "Unlock when Academy level reaches 10" {
		t.Fatalf("function 50: %+v", catalog.Function)
	}
	if catalog.Help.MentorName != "Mentor" || catalog.Help.StudentName != "Student" || catalog.Help.OpenTips != "Unlock when lv10 and there is a player in server over lv 60" {
		t.Fatalf("help identity: %+v", catalog.Help)
	}
	if catalog.Help.Digest() != "2817d9051f3c72850935095fe003d08651796a11f1d8e431b23a31dea8f88371" {
		t.Fatalf("help digest drift: %s", catalog.Help.Digest())
	}
	for _, marker := range []string{"cross server", "1 mentor can only have 1 student", "3 levels higher", "48 hours", "lv90"} {
		if !strings.Contains(catalog.Help.Rule, marker) {
			t.Fatalf("rule text lost source marker %q", marker)
		}
	}
	visible := catalog.VisibleMissions()
	if len(visible) != 23 {
		t.Fatalf("visible missions %d", len(visible))
	}
	for _, mission := range visible {
		if mission.IsHide != 0 {
			t.Fatalf("hidden mission %d leaked as grantable", mission.ID)
		}
	}
}

func TestMentorInputCatalogRejectsMalformedPayload(t *testing.T) {
	cases := map[string]string{
		"empty object":         `{}`,
		"trailing data":        mentorGoldenCatalog + ` {}`,
		"unknown field":        strings.Replace(mentorGoldenCatalog, `{"exam":`, `{"unexpected":true,"exam":`, 1),
		"duplicate top key":    strings.Replace(mentorGoldenCatalog, `{"exam":`, `{"schema_version":2,"exam":`, 1),
		"duplicate nested key": strings.Replace(mentorGoldenCatalog, `"id":100001`, `"id":100001,"id":100001`, 1),
		"integer overflow":     strings.Replace(mentorGoldenCatalog, `"schema_version":2`, `"schema_version":9223372036854775808`, 1),
		"fractional integer":   strings.Replace(mentorGoldenCatalog, `"schema_version":2`, `"schema_version":2.5`, 1),
	}
	for name, raw := range cases {
		t.Run(name, func(t *testing.T) {
			if _, err := builtin.DecodeMentorInputCatalog([]byte(raw)); !errors.Is(err, builtin.ErrMentorUnqualified) {
				t.Fatalf("malformed payload accepted: %v", err)
			}
		})
	}
}

func TestMentorInputCatalogValidationRefusesDrift(t *testing.T) {
	cases := map[string]func(*builtin.MentorInputCatalog){
		"schema version":   func(c *builtin.MentorInputCatalog) { c.SchemaVersion = 3 },
		"mission count":    func(c *builtin.MentorInputCatalog) { c.Missions = c.Missions[:24] },
		"mission identity": func(c *builtin.MentorInputCatalog) { c.Missions[0].ID = 100002 },
		"mission gift":     func(c *builtin.MentorInputCatalog) { c.Missions[0].GiftID = 1 },
		"mission category": func(c *builtin.MentorInputCatalog) { c.Missions[0].Category = 5 },
		"mission type":     func(c *builtin.MentorInputCatalog) { c.Missions[24].Type = 1 },
		"mission desc":     func(c *builtin.MentorInputCatalog) { c.Missions[0].Description = "" },
		"mission flag":     func(c *builtin.MentorInputCatalog) { c.Missions[0].Refresh = 2 },
		"hidden drift": func(c *builtin.MentorInputCatalog) {
			for index := range c.Missions {
				if c.Missions[index].ID == 100005 {
					c.Missions[index].IsHide = 0
				}
			}
		},
		"finish drift": func(c *builtin.MentorInputCatalog) {
			c.Missions[24].Level = 89
		},
		"rules drift":    func(c *builtin.MentorInputCatalog) { c.Rules.TeacherLevel = 61 },
		"function drift": func(c *builtin.MentorInputCatalog) { c.Function.Tip = "different" },
		"help drift":     func(c *builtin.MentorInputCatalog) { c.Help.OpenTips = "different" },
	}
	for name, mutate := range cases {
		t.Run(name, func(t *testing.T) {
			catalog := decodeMentorGolden(t)
			mutate(&catalog)
			if err := catalog.Validate(); !errors.Is(err, builtin.ErrMentorUnqualified) {
				t.Fatalf("drifted catalog accepted: %v", err)
			}
		})
	}
}

func TestCompiledMentorCatalogMatchesGoldenFixture(t *testing.T) {
	path := os.Getenv("GXB_MENTOR_CATALOG_PATH")
	if path == "" {
		t.Skip("compiled Mentor catalog not supplied")
	}
	compiled, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	var got, want any
	if err := json.Unmarshal(compiled, &got); err != nil {
		t.Fatal(err)
	}
	if err := json.Unmarshal([]byte(mentorGoldenCatalog), &want); err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatal("Python compiler output differs from the embedded golden fixture")
	}
	if _, err := builtin.DecodeMentorInputCatalog(compiled); err != nil {
		t.Fatalf("compiled catalog does not validate: %v", err)
	}
}

// Source facts do not select a reconstruction policy implicitly.
func TestMentorContentFeedsDomainRules(t *testing.T) {
	catalog := decodeMentorGolden(t)
	rules := mentor.Rules{
		MentorMinimumLevel: catalog.Rules.TeacherLevel,
		StudentLevelLimit:  catalog.Rules.StudentLevelLimit,
		LevelGap:           catalog.Rules.LevelRelation,
		ApplicationTTL:     time.Duration(catalog.Rules.RelationSendBrokenSeconds) * time.Second,
	}
	if err := rules.Validate(); err != nil {
		t.Fatal(err)
	}
	if rules.ApplicationTTL != 48*time.Hour || int64(rules.ApplicationTTL/time.Second) != 172800 {
		t.Fatalf("application TTL %v (%d s), want 48h/172800s, not 72h", rules.ApplicationTTL, int64(rules.ApplicationTTL/time.Second))
	}
	assessment, err := mentor.AssessLevelGap(60, 57, rules)
	if err != nil || assessment.Qualified {
		t.Fatalf("unverified level gap must stay UNKNOWN: %+v %v", assessment, err)
	}
	server := logicalserver.PlayerRegion(100001)
	mentorState := mentor.PlayerState{PlayerID: 100001, LogicalServerID: server, AcademyLevel: 60}
	studentState := mentor.PlayerState{PlayerID: 100002, LogicalServerID: server, AcademyLevel: 20}
	pair := mentor.Pair{Mentor: mentorState, Student: studentState, MentorGateOpen: true, StudentGateOpen: true}
	if err := mentor.ValidatePair(pair, rules); !errors.Is(err, mentor.ErrLevelGapUnresolved) {
		t.Fatalf("mapped content rules admitted a pair with an unresolved gap: %v", err)
	}
	facts := mentor.ApplicationFacts{Applicant: studentState, Recipient: mentorState, ApplicantGateOpen: true, RecipientGateOpen: true, Seeking: mentor.SlotMentor}
	if _, err := mentor.PlanApplication(facts, rules); !errors.Is(err, mentor.ErrLevelGapUnresolved) {
		t.Fatalf("mapped content rules admitted an application with an unresolved gap: %v", err)
	}
	rules.LevelGapPolicy = mentor.MinimumLevelGapPolicy
	if err := mentor.ValidatePair(pair, rules); err != nil {
		t.Fatal("explicit reconstruction policy refused", err)
	}
	if _, err := mentor.PlanApplication(facts, rules); err != nil {
		t.Fatal("explicit policy application refused", err)
	}

}

func FuzzDecodeMentorInputCatalog(f *testing.F) {
	f.Add([]byte(mentorGoldenCatalog))
	f.Add([]byte(`{}`))
	f.Add([]byte(`{"schema_version":2,"schema_version":2}`))
	f.Add([]byte(`{"missions":[{"id":100001}]}`))
	f.Add([]byte(`{"schema_version":9223372036854775808}`))
	f.Fuzz(func(t *testing.T, raw []byte) {
		catalog, err := builtin.DecodeMentorInputCatalog(raw)
		if err != nil {
			return
		}
		if err := catalog.Validate(); err != nil {
			t.Fatalf("accepted catalog failed validation: %v", err)
		}
	})
}
