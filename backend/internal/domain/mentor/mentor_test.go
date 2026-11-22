package mentor

import (
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
)

func testRules() Rules {
	return Rules{MentorMinimumLevel: 60, StudentLevelLimit: 90, LevelGap: 3, ApplicationTTL: 48 * time.Hour}
}

func minimumGapRulesForTest() Rules {
	rules := testRules()
	rules.LevelGapPolicy = MinimumLevelGapPolicy
	return rules
}

func state(id identity.PlayerID, level int64) PlayerState {
	return PlayerState{PlayerID: id, LogicalServerID: logicalserver.PlayerRegion(id), AcademyLevel: level}
}

func TestRoleAndSlotMappingIsSourceSettled(t *testing.T) {
	if role, err := RoleForSlot(SlotMentor); err != nil || role != RoleStudent {
		t.Fatalf("SlotMentor holder role = %v, %v; want student", role, err)
	}
	if role, err := RoleForSlot(SlotStudent); err != nil || role != RoleMentor {
		t.Fatalf("SlotStudent holder role = %v, %v; want mentor", role, err)
	}
	if slot, err := SlotForRole(RoleStudent); err != nil || slot != SlotMentor {
		t.Fatalf("student slot = %v, %v; want mentor slot", slot, err)
	}
	if slot, err := SlotForRole(RoleMentor); err != nil || slot != SlotStudent {
		t.Fatalf("mentor slot = %v, %v; want student slot", slot, err)
	}
	if _, err := RoleForSlot(0); !errors.Is(err, ErrRole) {
		t.Fatalf("invalid slot accepted: %v", err)
	}
	if _, err := SlotForRole(0); !errors.Is(err, ErrRole) {
		t.Fatalf("invalid role accepted: %v", err)
	}
	if _, err := RoleMentor.Opposite(); err != nil {
		t.Fatal(err)
	}
}

func TestPlayerStateValidation(t *testing.T) {
	valid := state(100001, 20)
	if err := valid.Validate(); err != nil {
		t.Fatal(err)
	}
	dual := valid
	dual.HasMentor, dual.MentorID = true, 100002
	dual.HasStudent, dual.StudentID = true, 100003
	if err := dual.Validate(); err != nil {
		t.Fatalf("a player may be both mentor and student with different people: %v", err)
	}
	cases := map[string]PlayerState{
		"invalid id":              {PlayerID: 0, LogicalServerID: 1, AcademyLevel: 20},
		"server mismatch":         {PlayerID: 200001, LogicalServerID: 1, AcademyLevel: 20},
		"level zero":              {PlayerID: 100001, LogicalServerID: 1, AcademyLevel: 0},
		"mentor flag without id":  {PlayerID: 100001, LogicalServerID: 1, AcademyLevel: 20, HasMentor: true},
		"mentor id without flag":  {PlayerID: 100001, LogicalServerID: 1, AcademyLevel: 20, MentorID: 100002},
		"student flag without id": {PlayerID: 100001, LogicalServerID: 1, AcademyLevel: 20, HasStudent: true},
		"student id without flag": {PlayerID: 100001, LogicalServerID: 1, AcademyLevel: 20, StudentID: 100002},
		"self mentor":             {PlayerID: 100001, LogicalServerID: 1, AcademyLevel: 20, HasMentor: true, MentorID: 100001},
		"self student":            {PlayerID: 100001, LogicalServerID: 1, AcademyLevel: 20, HasStudent: true, StudentID: 100001},
		"same person both roles":  {PlayerID: 100001, LogicalServerID: 1, AcademyLevel: 20, HasMentor: true, MentorID: 100002, HasStudent: true, StudentID: 100002},
	}
	for name, player := range cases {
		t.Run(name, func(t *testing.T) {
			err := player.Validate()
			if err == nil {
				t.Fatal("invalid player state accepted")
			}
			if name == "same person both roles" && !errors.Is(err, ErrSamePersonBothRoles) {
				t.Fatalf("wrong error: %v", err)
			}
		})
	}
}

func TestCandidateVerifiedLevelAndSlotChecks(t *testing.T) {
	rules := testRules()
	if err := (Candidate{State: state(100001, 59), Role: RoleMentor, GateOpen: true}).Validate(rules); !errors.Is(err, ErrLevel) {
		t.Fatalf("mentor below 60 accepted: %v", err)
	}
	if err := (Candidate{State: state(100001, 60), Role: RoleMentor, GateOpen: true}).Validate(rules); err != nil {
		t.Fatalf("mentor at 60 rejected: %v", err)
	}
	if err := (Candidate{State: state(100001, 90), Role: RoleStudent, GateOpen: true}).Validate(rules); !errors.Is(err, ErrLevel) {
		t.Fatalf("student at 90 accepted: %v", err)
	}
	if err := (Candidate{State: state(100001, 89), Role: RoleStudent, GateOpen: true}).Validate(rules); err != nil {
		t.Fatalf("student at 89 rejected: %v", err)
	}
	if err := (Candidate{State: state(100001, 1), Role: RoleStudent, GateOpen: true}).Validate(rules); err != nil {
		t.Fatalf("student lower boundary is UNKNOWN, must not invent a threshold: %v", err)
	}
	for _, role := range []Role{RoleMentor, RoleStudent} {
		if err := (Candidate{State: state(100001, 60), Role: role, GateOpen: false}).Validate(rules); !errors.Is(err, ErrGateUnqualified) {
			t.Fatalf("closed gate accepted for role %d: %v", role, err)
		}
	}
	filledMentor := state(100001, 60)
	filledMentor.HasStudent, filledMentor.StudentID = true, 100003
	if err := (Candidate{State: filledMentor, Role: RoleMentor, GateOpen: true}).Validate(rules); !errors.Is(err, ErrSlotFilled) {
		t.Fatalf("filled mentor slot accepted: %v", err)
	}
	filledStudent := state(100002, 20)
	filledStudent.HasMentor, filledStudent.MentorID = true, 100003
	if err := (Candidate{State: filledStudent, Role: RoleStudent, GateOpen: true}).Validate(rules); !errors.Is(err, ErrSlotFilled) {
		t.Fatalf("filled student slot accepted: %v", err)
	}
}

func TestValidatePairInvariants(t *testing.T) {
	admitted := minimumGapRulesForTest()
	rules := testRules()
	mentor, student := state(100001, 60), state(100002, 20)
	valid := Pair{Mentor: mentor, Student: student, MentorGateOpen: true, StudentGateOpen: true}
	if err := ValidatePair(valid, admitted); err != nil {
		t.Fatal(err)
	}
	if err := ValidatePair(valid, rules); !errors.Is(err, ErrLevelGapUnresolved) {
		t.Fatalf("unresolved gap admitted a valid pair: %v", err)
	}
	self := valid
	self.Student.PlayerID = self.Mentor.PlayerID
	if err := ValidatePair(self, rules); !errors.Is(err, ErrSelfPair) {
		t.Fatalf("self pair accepted: %v", err)
	}
	foreign := valid
	foreign.Student.PlayerID = 200002
	foreign.Student.LogicalServerID = 2
	if err := ValidatePair(foreign, rules); !errors.Is(err, ErrServerMismatch) {
		t.Fatalf("cross-server pair accepted: %v", err)
	}
	reverseMentor := valid
	reverseMentor.Mentor.HasMentor, reverseMentor.Mentor.MentorID = true, student.PlayerID
	if err := ValidatePair(reverseMentor, rules); !errors.Is(err, ErrSamePersonBothRoles) {
		t.Fatalf("reverse pair accepted (mentor already student of this person): %v", err)
	}
	reverseStudent := valid
	reverseStudent.Student.HasStudent, reverseStudent.Student.StudentID = true, mentor.PlayerID
	if err := ValidatePair(reverseStudent, rules); !errors.Is(err, ErrSamePersonBothRoles) {
		t.Fatalf("reverse pair accepted (student already mentor of this person): %v", err)
	}
	otherStudent := valid
	otherStudent.Mentor.HasStudent, otherStudent.Mentor.StudentID = true, 100003
	if err := ValidatePair(otherStudent, rules); !errors.Is(err, ErrSlotFilled) {
		t.Fatalf("mentor with another student accepted: %v", err)
	}
	otherMentor := valid
	otherMentor.Student.HasMentor, otherMentor.Student.MentorID = true, 100003
	if err := ValidatePair(otherMentor, rules); !errors.Is(err, ErrSlotFilled) {
		t.Fatalf("student with another mentor accepted: %v", err)
	}
}

func TestLevelGapFailsClosedUntilPolicySelected(t *testing.T) {
	rules := testRules()
	mentor, student := state(100001, 60), state(100002, 57)
	pair := Pair{Mentor: mentor, Student: student, MentorGateOpen: true, StudentGateOpen: true}
	if err := ValidatePair(pair, rules); !errors.Is(err, ErrLevelGapUnresolved) {
		t.Fatalf("unresolved gap must fail closed, got %v", err)
	}
	assessment, err := AssessLevelGap(mentor.AcademyLevel, student.AcademyLevel, rules)
	if err != nil || assessment.Qualified || assessment.Sufficient {
		t.Fatalf("unverified gap reported qualified: %+v %v", assessment, err)
	}

	resolved := minimumGapRulesForTest()
	if err := ValidatePair(Pair{Mentor: mentor, Student: state(100002, 58), MentorGateOpen: true, StudentGateOpen: true}, resolved); !errors.Is(err, ErrLevel) {
		t.Fatalf("known-invalid gap 2 accepted: %v", err)
	}
	if err := ValidatePair(Pair{Mentor: mentor, Student: state(100002, 56), MentorGateOpen: true, StudentGateOpen: true}, resolved); err != nil {
		t.Fatalf("known-valid gap 4 rejected: %v", err)
	}
	assessment, err = AssessLevelGap(60, 56, resolved)
	if err != nil || !assessment.Qualified || !assessment.Sufficient {
		t.Fatalf("resolved assessment for gap 4: %+v %v", assessment, err)
	}
	assessment, err = AssessLevelGap(60, 58, resolved)
	if err != nil || !assessment.Qualified || assessment.Sufficient {
		t.Fatalf("resolved assessment for gap 2: %+v %v", assessment, err)
	}
}

func TestApplicationWindowAndRecipientSlot(t *testing.T) {
	// teach_relation_send_broken=172800 seconds = 48 hours (misc.lua:3826);
	// the 72-hour/259200 reading is not the source policy.
	if ttl := testRules().ApplicationTTL; ttl != 48*time.Hour || int64(ttl/time.Second) != 172800 {
		t.Fatalf("application TTL = %v (%d s), want 48h/172800s", ttl, int64(ttl/time.Second))
	}
	created := time.Date(2026, 11, 5, 12, 0, 0, 0, time.UTC)
	application, err := NewApplication(100001, 100002, SlotMentor, created, 48*time.Hour)
	if err != nil {
		t.Fatal(err)
	}
	if application.RecipientSlot != SlotStudent || !application.ExpiresAt.Equal(created.Add(48*time.Hour)) {
		t.Fatalf("seeking a mentor must store the recipient's student slot: %+v", application)
	}
	reverse, err := NewApplication(100001, 100002, SlotStudent, created, 48*time.Hour)
	if err != nil || reverse.RecipientSlot != SlotMentor {
		t.Fatalf("seeking a student must store the recipient's mentor slot: %+v %v", reverse, err)
	}
	for name, build := range map[string]func() (Application, error){
		"self":         func() (Application, error) { return NewApplication(100001, 100001, SlotMentor, created, 48*time.Hour) },
		"cross server": func() (Application, error) { return NewApplication(100001, 200002, SlotMentor, created, 48*time.Hour) },
		"zero time": func() (Application, error) {
			return NewApplication(100001, 100002, SlotMentor, time.Time{}, 48*time.Hour)
		},
		"zero ttl": func() (Application, error) { return NewApplication(100001, 100002, SlotMentor, created, 0) },
		"bad slot": func() (Application, error) { return NewApplication(100001, 100002, 0, created, 48*time.Hour) },
	} {
		t.Run(name, func(t *testing.T) {
			if _, err := build(); err == nil {
				t.Fatal("invalid application accepted")
			}
		})
	}
	tampered := application
	tampered.RecipientSlot = SlotMentor
	if err := tampered.Validate(48 * time.Hour); !errors.Is(err, ErrRole) {
		t.Fatalf("tampered recipient slot accepted: %v", err)
	}
	wrongTTL := application
	wrongTTL.ExpiresAt = application.ExpiresAt.Add(time.Second)
	if err := wrongTTL.Validate(48 * time.Hour); !errors.Is(err, ErrDuration) {
		t.Fatalf("wrong request duration accepted: %v", err)
	}
	for _, cell := range []struct {
		name   string
		at     time.Time
		active bool
	}{
		{"before", created.Add(-time.Nanosecond), false},
		{"created", created, true},
		{"last instant", application.ExpiresAt.Add(-time.Nanosecond), true},
		{"expiry equality", application.ExpiresAt, false},
		{"after", application.ExpiresAt.Add(time.Second), false},
	} {
		t.Run(cell.name, func(t *testing.T) {
			active, err := application.ActiveAt(cell.at)
			if err != nil || active != cell.active {
				t.Fatalf("active=%v err=%v want %v", active, err, cell.active)
			}
		})
	}
	if _, err := application.ActiveAt(time.Time{}); !errors.Is(err, ErrTime) {
		t.Fatalf("zero observation accepted: %v", err)
	}
}

func TestPlanApplicationRoleMappingAndInvariants(t *testing.T) {
	resolved := minimumGapRulesForTest()
	rules := testRules()
	mentor, student := state(100001, 60), state(100002, 20)

	seekingMentor := ApplicationFacts{Applicant: student, Recipient: mentor, ApplicantGateOpen: true, RecipientGateOpen: true, Seeking: SlotMentor}
	plan, err := PlanApplication(seekingMentor, resolved)
	if err != nil {
		t.Fatal(err)
	}
	if plan.ApplicantRole != RoleStudent || plan.RecipientRole != RoleMentor || plan.RecipientSlot != SlotStudent || plan.Mentor != mentor.PlayerID || plan.Student != student.PlayerID {
		t.Fatalf("seeking-mentor plan: %+v", plan)
	}
	seekingStudent := ApplicationFacts{Applicant: mentor, Recipient: student, ApplicantGateOpen: true, RecipientGateOpen: true, Seeking: SlotStudent}
	plan, err = PlanApplication(seekingStudent, resolved)
	if err != nil {
		t.Fatal(err)
	}
	if plan.ApplicantRole != RoleMentor || plan.RecipientRole != RoleStudent || plan.RecipientSlot != SlotMentor || plan.Mentor != mentor.PlayerID || plan.Student != student.PlayerID {
		t.Fatalf("seeking-student plan: %+v", plan)
	}
	if _, err := PlanApplication(seekingMentor, rules); !errors.Is(err, ErrLevelGapUnresolved) {
		t.Fatalf("unresolved gap let PlanApplication admit: %v", err)
	}
	closed := seekingMentor
	closed.RecipientGateOpen = false
	if _, err := PlanApplication(closed, rules); !errors.Is(err, ErrGateUnqualified) {
		t.Fatalf("closed recipient gate accepted: %v", err)
	}
	filled := seekingMentor
	filled.Recipient.HasStudent, filled.Recipient.StudentID = true, 100003
	if _, err := PlanApplication(filled, rules); !errors.Is(err, ErrSlotFilled) {
		t.Fatalf("recipient with another student accepted: %v", err)
	}
	applicantFilled := seekingMentor
	applicantFilled.Applicant.HasMentor, applicantFilled.Applicant.MentorID = true, 100003
	if _, err := PlanApplication(applicantFilled, rules); !errors.Is(err, ErrSlotFilled) {
		t.Fatalf("applicant with another mentor accepted: %v", err)
	}
	badSlot := seekingMentor
	badSlot.Seeking = 0
	if _, err := PlanApplication(badSlot, rules); !errors.Is(err, ErrRole) {
		t.Fatalf("invalid seeking slot accepted: %v", err)
	}
}

func TestMinimumLevelGapPolicyIncludesExactBoundary(t *testing.T) {
	rules := testRules()
	rules.LevelGapPolicy = MinimumLevelGapPolicy
	for _, test := range []struct {
		student int64
		allowed bool
	}{{58, false}, {57, true}, {56, true}} {
		pair := Pair{Mentor: state(100001, 60), Student: state(100002, test.student), MentorGateOpen: true, StudentGateOpen: true}
		err := ValidatePair(pair, rules)
		if test.allowed && err != nil {
			t.Fatal("eligible minimum gap refused", test.student, err)
		}
		if !test.allowed && !errors.Is(err, ErrLevel) {
			t.Fatal("insufficient gap admitted", test.student, err)
		}
	}
	rules.LevelGapPolicy = "unsupported"
	if _, err := AssessLevelGap(60, 57, rules); !errors.Is(err, ErrInvalid) {
		t.Fatal("unsupported policy accepted", err)
	}
}
