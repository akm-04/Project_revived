// Package mentor owns the pure My Class (mentor/student) role and application
// invariants. Every fact - the qualified function-50 gate, academy levels and
// current slot occupancy - is supplied by the caller. This package performs no
// I/O and creates no relationship, friendship, counter, reward or route.
//
// Source-backed level comparators:
//   - mentor role: TeacherWindow.lua:163,288 rejects selfPlayer.lev < teacherLev
//     (misc teacher_lev=60), so the verified predicate is level >= 60.
//   - student role: TeacherWindow.lua:354 rejects studentLevLimit and above
//     (misc student_lev_limit=90), so the verified predicate is level < 90.
//
// UNKNOWN and deliberately not enforced here:
//   - the student lower bound ("more than 10" in TEACHER_RULE vs the level-10
//     function-50 open tip) has no client comparator; the qualified gate fact
//     subsumes opening, not the exact boundary;
//   - "mentor must be 3 levels higher" has no recovered client comparator;
//     MinimumLevelGapPolicy explicitly selects the reconstruction >= rule.
//     A missing policy still refuses; it is not original-server proof.
package mentor

import (
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
)

var (
	ErrInvalid             = errors.New("mentor: invalid facts")
	ErrSelfPair            = errors.New("mentor: applicant and recipient must be distinct players")
	ErrServerMismatch      = errors.New("mentor: pair must be on one logical server")
	ErrGateUnqualified     = errors.New("mentor: qualified function-50 gate is required")
	ErrLevel               = errors.New("mentor: academy level is not eligible")
	ErrLevelGapUnresolved  = errors.New("mentor: level gap comparator is unverified")
	ErrSlotFilled          = errors.New("mentor: role slot is already filled")
	ErrSamePersonBothRoles = errors.New("mentor: one person cannot be both mentor and student")
	ErrRole                = errors.New("mentor: invalid role or slot")
	ErrTime                = errors.New("mentor: invalid application timestamp")
	ErrDuration            = errors.New("mentor: invalid application duration")
	ErrApplication         = errors.New("mentor: invalid application facts")
)

// Role is the person's role in the pair.
type Role uint8

const (
	RoleMentor  Role = 1
	RoleStudent Role = 2
)

func (role Role) Valid() bool { return role == RoleMentor || role == RoleStudent }

func (role Role) Opposite() (Role, error) {
	switch role {
	case RoleMentor:
		return RoleStudent, nil
	case RoleStudent:
		return RoleMentor, nil
	default:
		return 0, ErrRole
	}
}

// Slot is the client relation_type. SlotMentor (1) means "my mentor", so the
// slot holder is the student; SlotStudent (2) means "my student", so the slot
// holder is the mentor. This flip is source-settled by base_info.relations[1]
// being teacherInfo and relations[2] being studentInfo (SocialSystem.lua:1366,
// TeacherWindow.lua:738).
type Slot uint8

const (
	SlotMentor  Slot = 1
	SlotStudent Slot = 2
)

func (slot Slot) Valid() bool { return slot == SlotMentor || slot == SlotStudent }

func RoleForSlot(slot Slot) (Role, error) {
	switch slot {
	case SlotMentor:
		return RoleStudent, nil
	case SlotStudent:
		return RoleMentor, nil
	default:
		return 0, ErrRole
	}
}

func SlotForRole(role Role) (Slot, error) {
	switch role {
	case RoleStudent:
		return SlotMentor, nil
	case RoleMentor:
		return SlotStudent, nil
	default:
		return 0, ErrRole
	}
}

// PlayerState is the caller-supplied mentor/student slot occupancy. A player
// may be both mentor and student at the same time, but not with the same other
// person.
type PlayerState struct {
	PlayerID        identity.PlayerID
	LogicalServerID identity.LogicalServerID
	AcademyLevel    int64
	HasMentor       bool
	MentorID        identity.PlayerID
	HasStudent      bool
	StudentID       identity.PlayerID
}

func (state PlayerState) Validate() error {
	if !state.PlayerID.Valid() || !state.LogicalServerID.Valid() || logicalserver.PlayerRegion(state.PlayerID) != state.LogicalServerID || state.AcademyLevel < 1 {
		return ErrInvalid
	}
	if state.HasMentor != state.MentorID.Valid() || state.HasStudent != state.StudentID.Valid() {
		return ErrInvalid
	}
	if state.HasMentor && state.MentorID == state.PlayerID || state.HasStudent && state.StudentID == state.PlayerID {
		return ErrInvalid
	}
	if state.HasMentor && state.HasStudent && state.MentorID == state.StudentID {
		return ErrSamePersonBothRoles
	}
	return nil
}

const MinimumLevelGapPolicy = "I9_MENTOR_LEVEL_GAP_AT_LEAST_V1"

type Rules struct {
	MentorMinimumLevel  int64
	StudentMinimumLevel int64
	StudentLevelLimit   int64
	LevelGap            int64
	ApplicationTTL      time.Duration
	ApplicationDaily    int64
	BreakCooldown       time.Duration
	MinimumRelationAge  time.Duration
	IntimacyDaily       int64
	IntimacyCap         int64
	FunctionOpenLevel   int64
	ServerMentorLevel   int64

	LevelGapPolicy string
}

func (rules Rules) Validate() error {
	if rules.LevelGapPolicy != "" && rules.LevelGapPolicy != MinimumLevelGapPolicy {
		return ErrInvalid
	}
	if rules.MentorMinimumLevel < 1 || rules.StudentLevelLimit < 1 || rules.LevelGap < 0 || rules.ApplicationTTL <= 0 {
		return ErrInvalid
	}
	if rules.StudentMinimumLevel < 0 || rules.ApplicationDaily < 0 || rules.BreakCooldown < 0 || rules.MinimumRelationAge < 0 || rules.IntimacyDaily < 0 || rules.IntimacyCap < 0 || rules.FunctionOpenLevel < 0 || rules.ServerMentorLevel < 0 {
		return ErrInvalid
	}
	if rules.IntimacyCap > 0 && rules.IntimacyDaily > rules.IntimacyCap {
		return ErrInvalid
	}
	return nil
}

// Candidate is one player considered for one role. GateOpen is the qualified
// function-50 fact; it is never forced open by this package.
type Candidate struct {
	State    PlayerState
	Role     Role
	GateOpen bool
}

func (candidate Candidate) Validate(rules Rules) error {
	if rules.Validate() != nil || !candidate.Role.Valid() || candidate.State.Validate() != nil {
		return ErrInvalid
	}
	if !candidate.GateOpen {
		return ErrGateUnqualified
	}
	switch candidate.Role {
	case RoleMentor:
		if candidate.State.AcademyLevel < rules.MentorMinimumLevel {
			return ErrLevel
		}
		if candidate.State.HasStudent {
			return ErrSlotFilled
		}
	case RoleStudent:
		if candidate.State.AcademyLevel <= rules.StudentMinimumLevel || candidate.State.AcademyLevel >= rules.StudentLevelLimit {
			return ErrLevel
		}
		if candidate.State.HasMentor {
			return ErrSlotFilled
		}
	}
	return nil
}

type Pair struct {
	Mentor          PlayerState
	Student         PlayerState
	MentorGateOpen  bool
	StudentGateOpen bool
}

func ValidatePair(pair Pair, rules Rules) error {
	if rules.Validate() != nil {
		return ErrInvalid
	}
	if pair.Mentor.PlayerID == pair.Student.PlayerID {
		return ErrSelfPair
	}
	if pair.Mentor.LogicalServerID != pair.Student.LogicalServerID {
		return ErrServerMismatch
	}
	mentor := Candidate{State: pair.Mentor, Role: RoleMentor, GateOpen: pair.MentorGateOpen}
	student := Candidate{State: pair.Student, Role: RoleStudent, GateOpen: pair.StudentGateOpen}
	if err := mentor.Validate(rules); err != nil {
		return err
	}
	if err := student.Validate(rules); err != nil {
		return err
	}
	if pair.Mentor.HasMentor && pair.Mentor.MentorID == pair.Student.PlayerID {
		return ErrSamePersonBothRoles
	}
	if pair.Student.HasStudent && pair.Student.StudentID == pair.Mentor.PlayerID {
		return ErrSamePersonBothRoles
	}
	if rules.LevelGapPolicy == "" {
		return ErrLevelGapUnresolved
	}
	if pair.Mentor.AcademyLevel-pair.Student.AcademyLevel < rules.LevelGap {
		return ErrLevel
	}
	return nil
}

// Qualified identifies an explicit reconstruction policy, not original-server proof.
type LevelGapAssessment struct {
	Qualified  bool
	Sufficient bool
}

func AssessLevelGap(mentorLevel, studentLevel int64, rules Rules) (LevelGapAssessment, error) {
	if mentorLevel < 1 || studentLevel < 1 || rules.Validate() != nil {
		return LevelGapAssessment{}, ErrInvalid
	}
	if rules.LevelGapPolicy == "" {
		return LevelGapAssessment{Qualified: false, Sufficient: false}, nil
	}
	return LevelGapAssessment{Qualified: true, Sufficient: mentorLevel-studentLevel >= rules.LevelGap}, nil
}

// Application is the pure source-backed request window. The stored relation_type
// is the recipient's new slot, which is the opposite of the slot the applicant
// sought (client-settled by checkHasTeacherApplyRed and accept).
type Application struct {
	Applicant     identity.PlayerID
	Recipient     identity.PlayerID
	Seeking       Slot
	RecipientSlot Slot
	CreatedAt     time.Time
	ExpiresAt     time.Time
}

func NewApplication(applicant, recipient identity.PlayerID, seeking Slot, createdAt time.Time, ttl time.Duration) (Application, error) {
	if !applicant.Valid() || !recipient.Valid() || applicant == recipient || !seeking.Valid() || createdAt.IsZero() || ttl <= 0 {
		return Application{}, ErrApplication
	}
	if logicalserver.PlayerRegion(applicant) != logicalserver.PlayerRegion(recipient) {
		return Application{}, ErrServerMismatch
	}
	created := createdAt.UTC()
	expires := created.Add(ttl)
	if !expires.After(created) || expires.Sub(created) != ttl {
		return Application{}, ErrDuration
	}
	applicantRole, _ := RoleForSlot(seeking)
	recipientRole, _ := applicantRole.Opposite()
	recipientSlot, _ := SlotForRole(recipientRole)
	application := Application{
		Applicant: applicant, Recipient: recipient, Seeking: seeking,
		RecipientSlot: recipientSlot, CreatedAt: created, ExpiresAt: expires,
	}
	if err := application.Validate(ttl); err != nil {
		return Application{}, err
	}
	return application, nil
}

func (application Application) Validate(ttl time.Duration) error {
	if !application.Applicant.Valid() || !application.Recipient.Valid() || application.Applicant == application.Recipient || !application.Seeking.Valid() || application.CreatedAt.IsZero() || application.ExpiresAt.IsZero() || ttl <= 0 {
		return ErrApplication
	}
	if logicalserver.PlayerRegion(application.Applicant) != logicalserver.PlayerRegion(application.Recipient) {
		return ErrServerMismatch
	}
	applicantRole, err := RoleForSlot(application.Seeking)
	if err != nil {
		return ErrRole
	}
	recipientRole, err := applicantRole.Opposite()
	if err != nil {
		return ErrRole
	}
	expectedSlot, err := SlotForRole(recipientRole)
	if err != nil || application.RecipientSlot != expectedSlot {
		return ErrRole
	}
	if application.CreatedAt.Location() != time.UTC || application.ExpiresAt.Location() != time.UTC {
		return ErrTime
	}
	if application.ExpiresAt.Sub(application.CreatedAt) != ttl || !application.ExpiresAt.After(application.CreatedAt) {
		return ErrDuration
	}
	return nil
}

// ActiveAt reports membership in the half-open request window
// [CreatedAt, ExpiresAt). A future instant and the exact expiry instant are not
// active.
func (application Application) ActiveAt(at time.Time) (bool, error) {
	if at.IsZero() || application.CreatedAt.IsZero() || application.ExpiresAt.IsZero() {
		return false, ErrTime
	}
	if err := application.Validate(application.ExpiresAt.Sub(application.CreatedAt)); err != nil {
		return false, err
	}
	instant := at.UTC()
	if instant.Before(application.CreatedAt) || !instant.Before(application.ExpiresAt) {
		return false, nil
	}
	return true, nil
}

type ApplicationFacts struct {
	Applicant         PlayerState
	Recipient         PlayerState
	ApplicantGateOpen bool
	RecipientGateOpen bool
	Seeking           Slot
}

type ApplicationPlan struct {
	ApplicantRole Role
	RecipientRole Role
	RecipientSlot Slot
	Mentor        identity.PlayerID
	Student       identity.PlayerID
}

// PlanApplication derives both person roles from the slot the applicant seeks,
// maps the recipient's stored slot, and validates the pair invariants.
func PlanApplication(facts ApplicationFacts, rules Rules) (ApplicationPlan, error) {
	if !facts.Seeking.Valid() {
		return ApplicationPlan{}, ErrRole
	}
	applicantRole, err := RoleForSlot(facts.Seeking)
	if err != nil {
		return ApplicationPlan{}, ErrRole
	}
	recipientRole, err := applicantRole.Opposite()
	if err != nil {
		return ApplicationPlan{}, ErrRole
	}
	pair := Pair{MentorGateOpen: facts.ApplicantGateOpen, StudentGateOpen: facts.RecipientGateOpen}
	if applicantRole == RoleMentor {
		pair.Mentor, pair.Student = facts.Applicant, facts.Recipient
	} else {
		pair.Mentor, pair.Student = facts.Recipient, facts.Applicant
		pair.MentorGateOpen, pair.StudentGateOpen = facts.RecipientGateOpen, facts.ApplicantGateOpen
	}
	if err := ValidatePair(pair, rules); err != nil {
		return ApplicationPlan{}, err
	}
	recipientSlot, err := SlotForRole(recipientRole)
	if err != nil {
		return ApplicationPlan{}, ErrRole
	}
	return ApplicationPlan{
		ApplicantRole: applicantRole,
		RecipientRole: recipientRole,
		RecipientSlot: recipientSlot,
		Mentor:        pair.Mentor.PlayerID,
		Student:       pair.Student.PlayerID,
	}, nil
}
