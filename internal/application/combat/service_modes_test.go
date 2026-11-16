package combat

import (
	"errors"
	"testing"

	d "gxb.local/backend/v2/internal/domain/combat"
)

func modeRequest(key d.ModeKey, family string) StartRequest {
	return StartRequest{Mode: key, Locator: d.Locator{DomainKind: family, AuthorityScope: "server:1", DomainLocator: "player:1"}}
}

func TestStartModeRegistrationRefusals(t *testing.T) {
	trustMismatch := modeRequest(d.ModeCampaign, "CAMPAIGN")
	trustMismatch.TrustProfile = d.ServerReport
	replayMismatch := modeRequest(d.ModeCampaign, "CAMPAIGN")
	replayMismatch.TrustProfile = d.ClientSummaryAttested
	replayMismatch.Replay = d.ReplaySpec{Response: d.ReplayFightExist, ErrorCode: d.FightExistCode}
	foreignTransform := modeRequest(d.ModeArena, "ARENA")
	foreignTransform.Battle = BattleRequest{Context: &d.BattleContext{Transform: "NO_SUCH_TRANSFORM_V1"}}
	challengeProducer := modeRequest(d.ModeCampaign, "CAMPAIGN")
	challengeProducer.TrustProfile = d.ClientSummaryAttested
	challengeProducer.Replay = d.ReplaySpec{Response: d.ReplayOK}
	challengeProducer.Challenge = &d.Challenge{}
	battleProducer := modeRequest(d.ModeDodgeball, "dodgeball")
	battleProducer.TrustProfile = d.ServerEntropyClientDerived
	battleProducer.Replay = d.ReplaySpec{Response: d.ReplayFightExist, ErrorCode: d.FightExistCode}
	battleProducer.Battle = BattleRequest{CampaignType: 1}
	cases := []struct {
		name    string
		request StartRequest
	}{
		{"empty mode", modeRequest("", "ACADEMY_LEAGUE")},
		{"unknown mode", modeRequest("NO_SUCH_MODE", "ACADEMY_LEAGUE")},
		{"family mismatch", modeRequest(d.ModeChampionsLeague, "ARENA")},
		{"trust mismatch", trustMismatch},
		{"replay mismatch", replayMismatch},
		{"foreign transform", foreignTransform},
		{"challenge producer", challengeProducer},
		{"battle producer", battleProducer},
	}
	for _, testCase := range cases {
		if err := validateStartMode(testCase.request); !errors.Is(err, d.ErrInvalid) {
			t.Fatalf("%s: got %v", testCase.name, err)
		}
	}
}

func TestStartModeRegistrationAllowsTodayTuple(t *testing.T) {
	request := modeRequest(d.ModeChampionsLeague, "ACADEMY_LEAGUE")
	request.Battle = BattleRequest{CampaignType: 1}
	if err := validateStartMode(request); err != nil {
		t.Fatal(err)
	}
	carry := modeRequest(d.ModeMemoirBattle, "MEMOIR")
	carry.TrustProfile = d.ClientFullReportAttested
	carry.Replay = d.ReplaySpec{Response: d.ReplayFightExist, ErrorCode: d.FightExistCode}
	carry.Battle = BattleRequest{Context: &d.BattleContext{Transform: "MEMOIR_CARRY_V1"}}
	if err := validateStartMode(carry); err != nil {
		t.Fatal(err)
	}
}
