package socialinvite

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

var inviteBoundAt = time.Unix(2_000_000, 0).UTC()

func account(t *testing.T) identity.AccountID {
	t.Helper()
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	account, err := identity.AccountIDFrom(id)
	if err != nil {
		t.Fatal(err)
	}
	return account
}

func validCandidate(t *testing.T) Candidate {
	t.Helper()
	return Candidate{
		Inviter:             100001,
		Invitee:             100002,
		LogicalServerID:     1,
		InviterAccount:      account(t),
		InviteeAccount:      account(t),
		InviteeAcademyLevel: 49,
	}
}

func TestBindEligibilityAndIdentityRules(t *testing.T) {
	const limit = 50
	candidate := validCandidate(t)
	binding, err := Bind(nil, candidate, limit, inviteBoundAt)
	if err != nil {
		t.Fatal(err)
	}
	if err := binding.Validate(); err != nil {
		t.Fatal(err)
	}
	if binding.InviteeAcademyLevel != 49 || !binding.BoundAt.Equal(inviteBoundAt) {
		t.Fatalf("binding lost supplied facts: %+v", binding)
	}

	atLimit := candidate
	atLimit.InviteeAcademyLevel = limit
	if _, err := Bind(nil, atLimit, limit, inviteBoundAt); err != ErrIneligible {
		t.Fatalf("academy level at limit accepted: %v", err)
	}
	negativeLevel := candidate
	negativeLevel.InviteeAcademyLevel = -1
	if _, err := Bind(nil, negativeLevel, limit, inviteBoundAt); err == nil {
		t.Fatal("negative academy level accepted")
	}

	self := candidate
	self.Invitee = self.Inviter
	if _, err := Bind(nil, self, limit, inviteBoundAt); err != ErrSelfInvite {
		t.Fatalf("self invite accepted: %v", err)
	}
	sameAccount := candidate
	sameAccount.InviteeAccount = sameAccount.InviterAccount
	if _, err := Bind(nil, sameAccount, limit, inviteBoundAt); err != ErrSameAccount {
		t.Fatalf("same account accepted: %v", err)
	}
	foreign := candidate
	foreign.Invitee = 200002
	if _, err := Bind(nil, foreign, limit, inviteBoundAt); err != ErrServerMismatch {
		t.Fatalf("foreign server accepted: %v", err)
	}
	if _, err := Bind(nil, candidate, 0, inviteBoundAt); err == nil {
		t.Fatal("zero academy limit accepted")
	}
	if _, err := Bind(nil, candidate, limit, time.Time{}); err == nil {
		t.Fatal("zero binding time accepted")
	}
}

func TestBindingIsImmutableAndOnce(t *testing.T) {
	candidate := validCandidate(t)
	first, err := Bind(nil, candidate, 50, inviteBoundAt)
	if err != nil {
		t.Fatal(err)
	}
	second, err := Bind(&first, candidate, 50, inviteBoundAt.Add(time.Hour))
	if err != ErrAlreadyBound || second != (Binding{}) {
		t.Fatalf("second binding accepted: %+v %v", second, err)
	}
	if first.Invitee != candidate.Invitee || !first.BoundAt.Equal(inviteBoundAt) {
		t.Fatalf("existing binding mutated: %+v", first)
	}
}

func TestMissionProgressTypesAndUniqueInvitees(t *testing.T) {
	invitees := []InviteeFacts{
		{Player: 100002, AcademyLevel: 49, OwnedHeroCount: 6, HighestOwnedHeroLevel: 30, ChargeTotal: 1000},
		{Player: 100003, AcademyLevel: 99, OwnedHeroCount: 4, HighestOwnedHeroLevel: 20, ChargeTotal: 500},
		{Player: 100004, AcademyLevel: 20, OwnedHeroCount: 6, HighestOwnedHeroLevel: 10, ChargeTotal: 2000},
	}
	cases := []struct {
		name     string
		mission  Mission
		expected int64
	}{
		{"invited count", Mission{ID: 1, Type: MissionInvitedCount, Threshold: 2}, 3},
		{"owned hero count", Mission{ID: 2, Type: MissionOwnedHeroCount, Threshold: 6}, 2},
		{"highest hero level", Mission{ID: 3, Type: MissionHighestOwnedHeroLevel, Threshold: 25}, 1},
		{"charge total", Mission{ID: 4, Type: MissionCharge, Threshold: 1000}, 2},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			progress, err := Progress(testCase.mission, invitees)
			if err != nil || progress != testCase.expected {
				t.Fatalf("progress = %d, %v; want %d", progress, err, testCase.expected)
			}
		})
	}

	academyHighHeroLow := []InviteeFacts{{Player: 100002, AcademyLevel: 99, HighestOwnedHeroLevel: 10}}
	progress, err := Progress(Mission{ID: 3, Type: MissionHighestOwnedHeroLevel, Threshold: 25}, academyHighHeroLow)
	if err != nil || progress != 0 {
		t.Fatalf("academy level leaked into hero metric: %d %v", progress, err)
	}
	heroHighAcademyLow := []InviteeFacts{{Player: 100002, AcademyLevel: 1, HighestOwnedHeroLevel: 40}}
	progress, err = Progress(Mission{ID: 3, Type: MissionHighestOwnedHeroLevel, Threshold: 25}, heroHighAcademyLow)
	if err != nil || progress != 1 {
		t.Fatalf("hero level not used for type 3: %d %v", progress, err)
	}

	duplicates := []InviteeFacts{{Player: 100002}, {Player: 100002, OwnedHeroCount: 9}}
	if _, err := Progress(Mission{ID: 1, Type: MissionInvitedCount}, duplicates); err != ErrDuplicate {
		t.Fatalf("duplicate invitee accepted: %v", err)
	}

	for _, malformed := range []Mission{
		{ID: 0, Type: MissionInvitedCount},
		{ID: 1, Type: 5},
		{ID: 1, Type: MissionOwnedHeroCount, Threshold: -1},
	} {
		if _, err := Progress(malformed, invitees); err == nil {
			t.Fatalf("malformed mission accepted: %+v", malformed)
		}
	}
	for _, invalid := range []InviteeFacts{
		{Player: 0},
		{Player: 100002, AcademyLevel: -1},
		{Player: 100002, OwnedHeroCount: -1},
		{Player: 100002, HighestOwnedHeroLevel: -1},
		{Player: 100002, ChargeTotal: -1},
	} {
		if _, err := Progress(Mission{ID: 1, Type: MissionInvitedCount}, []InviteeFacts{invalid}); err == nil {
			t.Fatalf("invalid facts accepted: %+v", invalid)
		}
	}
}
