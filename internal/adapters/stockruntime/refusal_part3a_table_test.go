package stockruntime

import (
	"errors"
	"net/http"
	"testing"

	"gxb.local/backend/v2/internal/application/characterpet"
	"gxb.local/backend/v2/internal/application/guildcampaign"
	"gxb.local/backend/v2/internal/application/guildcore"
	"gxb.local/backend/v2/internal/application/guildrental"
	"gxb.local/backend/v2/internal/application/guildtea"
	"gxb.local/backend/v2/internal/application/guildview"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/socialgift"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/economy"
	god "gxb.local/backend/v2/internal/domain/godstrial"
	guilddomain "gxb.local/backend/v2/internal/domain/guildcampaign"
	"gxb.local/backend/v2/internal/domain/objective"
	pc "gxb.local/backend/v2/internal/domain/petcampaign"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

func TestPart3AGuildFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"not found", failGuild(guildcore.ErrGuildNotFound), http.StatusConflict, guildNotFoundCode, ""},
		{"application not found", failGuild(guildcore.ErrApplicationNotFound), http.StatusConflict, unprovenRefusalCode, ""},
		{"invite not found", failGuild(guildcore.ErrInviteNotFound), http.StatusConflict, unprovenRefusalCode, ""},
		{"forbidden", failGuild(guildcore.ErrGuildPermission), http.StatusConflict, unprovenRefusalCode, ""},
		{"not member", failGuild(guildcore.ErrNotGuildMember), http.StatusConflict, unprovenRefusalCode, ""},
		{"view forbidden", failGuild(guildview.ErrForbidden), http.StatusConflict, unprovenRefusalCode, ""},
		{"closed", failGuild(guildcore.ErrGuildClosed), http.StatusConflict, 30014, ""},
		{"full", failGuild(guildcore.ErrGuildFull), http.StatusConflict, 30020, ""},
		{"application full", failGuild(guildcore.ErrGuildApplicationFull), http.StatusConflict, 30016, ""},
		{"name taken", failGuild(guildcore.ErrGuildNameTaken), http.StatusConflict, 30019, ""},
		{"application limit", failGuild(guildcore.ErrApplicationLimit), http.StatusConflict, 30013, ""},
		{"join limit", failGuild(guildcore.ErrJoinLimit), http.StatusConflict, 30012, ""},
		{"dissolve solo", failGuild(guildcore.ErrDissolveRequiresSolo), http.StatusConflict, 30017, ""},
		{"deputy limit", failGuild(guildcore.ErrDeputyLimit), http.StatusConflict, 30018, ""},
		{"already in guild", failGuild(guildcore.ErrAlreadyInGuild), http.StatusConflict, unprovenRefusalCode, ""},
		{"retired", failGuild(guildcore.ErrGuildRetired), http.StatusConflict, unprovenRefusalCode, ""},
		{"level low", failGuild(guildcore.ErrLevelTooLow), http.StatusConflict, unprovenRefusalCode, ""},
		{"applicant limit", failGuild(guildcore.ErrApplicantLimit), http.StatusConflict, unprovenRefusalCode, ""},
		{"invite expired", failGuild(guildcore.ErrInviteExpired), http.StatusConflict, unprovenRefusalCode, ""},
		{"invite limit", failGuild(guildcore.ErrInviteLimit), http.StatusConflict, unprovenRefusalCode, ""},
		{"target member", failGuild(guildcore.ErrTargetAlreadyMember), http.StatusConflict, unprovenRefusalCode, ""},
		{"target not member", failGuild(guildcore.ErrTargetNotMember), http.StatusConflict, unprovenRefusalCode, ""},
		{"leader leave", failGuild(guildcore.ErrCannotLeaveLeader), http.StatusConflict, unprovenRefusalCode, ""},
		{"invalid role", failGuild(guildcore.ErrInvalidRoleChange), http.StatusBadRequest, 0, "guild_invalid_parameter"},
		{"invalid description", failGuild(guildcore.ErrInvalidDescription), http.StatusBadRequest, 0, "guild_invalid_parameter"},
		{"invalid settings", failGuild(guildcore.ErrInvalidSettings), http.StatusBadRequest, 0, "guild_invalid_parameter"},
		{"invalid policy input", failGuild(guildcore.ErrInvalidGuildPolicyInput), http.StatusBadRequest, 0, "guild_invalid_parameter"},
		{"balance diamonds", failGuild(economy.InsufficientBalance("crystal")), http.StatusConflict, insufficientDiamondCode, ""},
		{"balance coins", failGuild(economy.InsufficientBalance("mana")), http.StatusConflict, insufficientCoinCode, ""},
		{"balance other", failGuild(economy.InsufficientBalance("guild_coin")), http.StatusConflict, unprovenRefusalCode, ""},
		{"untyped balance", failGuild(economy.ErrInsufficientBalance), http.StatusConflict, unprovenRefusalCode, ""},
		{"database", failGuild(errors.New("database unavailable")), http.StatusInternalServerError, unprovenRefusalCode, ""},
	})
	cooldown := sourceGuildProtocolResponse(t, &guildcore.CantJoinError{Kind: guildcore.JoinCooldownOtherGuild, RemainingSeconds: 7}, 30010)
	if cooldown.Body["time"] != int64(7) {
		t.Fatalf("guild join cooldown lost time: %#v", cooldown.Body)
	}
	assertPart2FailureCases(t, []part2FailureCase{
		{"same guild cooldown", sourceGuildProtocolResponse(t, &guildcore.CantJoinError{Kind: guildcore.JoinCooldownSameGuild}, 30011), http.StatusConflict, 30011, ""},
	})
}

func sourceGuildProtocolResponse(t *testing.T, err error, wantCode int64) httpedge.Response {
	t.Helper()
	response, ok := sourceGuildProtocolError(err)
	if !ok || response.HTTPStatus != http.StatusConflict || response.Body["error_code"] != wantCode || response.Body["error_msg"] != "" {
		t.Fatalf("source guild protocol error %v -> %#v", err, response)
	}
	return response
}

func TestPart3AGuildCampaignFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"refused", campaignFailure(errors.New("refused")), http.StatusInternalServerError, unprovenRefusalCode, ""},
		{"holder", campaignFailure(guildcampaign.ErrHolder), http.StatusConflict, unprovenRefusalCode, ""},
		{"domain refusal", campaignFailure(guilddomain.ErrRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"late", campaignSettleFailure(guildcampaign.ErrLate), http.StatusConflict, 30021, ""},
		{"unavailable", campaignFailure(guildcampaign.ErrUnavailable), http.StatusInternalServerError, unprovenRefusalCode, ""},
		{"invalid parameter", campaignBad(), http.StatusBadRequest, 0, "guild_campaign_invalid_parameter"},
	})
}

func TestPart3AGuildRentalFailureRows(t *testing.T) {
	rows := []error{
		guildrental.ErrNotInGuild, guildrental.ErrUnitUnavailable, guildrental.ErrAlreadyOffered,
		guildrental.ErrCapReached, guildrental.ErrNoOffer, guildrental.ErrRecallTooEarly,
	}
	cases := make([]part2FailureCase, 0, len(rows)+2)
	for i, row := range rows {
		cases = append(cases, part2FailureCase{name: "refusal " + string(rune('a'+i)), got: rentalFailure(row), want: http.StatusConflict, code: unprovenRefusalCode})
	}
	cases = append(cases,
		part2FailureCase{"unavailable", rentalFailure(guildrental.ErrUnavailable), http.StatusServiceUnavailable, serverBusyCode, ""},
		part2FailureCase{"invalid parameter", rentalBad(), http.StatusBadRequest, 0, "guild_rental_invalid_parameter"},
	)
	assertPart2FailureCases(t, cases)
}

func TestPart3AGuildTeaFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"not in guild", teaFailure(guildtea.ErrNotInGuild), http.StatusConflict, unprovenRefusalCode, ""},
		{"already wished", teaFailure(guildtea.ErrAlreadyWished), http.StatusConflict, unprovenRefusalCode, ""},
		{"no wish", teaFailure(guildtea.ErrNoWish), http.StatusConflict, unprovenRefusalCode, ""},
		{"wish full", teaFailure(guildtea.ErrWishFull), http.StatusConflict, unprovenRefusalCode, ""},
		{"already donated", teaFailure(guildtea.ErrAlreadyDonated), http.StatusConflict, unprovenRefusalCode, ""},
		{"self donation", teaFailure(guildtea.ErrSelfDonation), http.StatusConflict, unprovenRefusalCode, ""},
		{"not owner", teaFailure(guildtea.ErrNotOwner), http.StatusConflict, unprovenRefusalCode, ""},
		{"unknown scroll", teaFailure(guildtea.ErrUnknownScroll), http.StatusConflict, unprovenRefusalCode, ""},
		{"balance diamonds", teaFailure(economy.InsufficientBalance("crystal")), http.StatusConflict, insufficientDiamondCode, ""},
		{"balance other", teaFailure(economy.InsufficientBalance("guild_coin")), http.StatusConflict, unprovenRefusalCode, ""},
		{"invalid parameter", teaFailure(guildtea.ErrInvalid), http.StatusBadRequest, 0, "guild_tea_invalid_parameter"},
		{"unavailable", teaFailure(guildtea.ErrUnavailable), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}

func TestPart3ASocialFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"stock code", socialFailure(&sr.StockError{Code: 20004}), http.StatusConflict, 20004, ""},
		{"dependency", socialFailure(errors.New("database unavailable")), http.StatusInternalServerError, unprovenRefusalCode, ""},
		{"gift quota", giftFailure(socialgift.ErrQuota), http.StatusConflict, unprovenRefusalCode, ""},
		{"gift duplicate", giftFailure(socialgift.ErrDuplicate), http.StatusConflict, unprovenRefusalCode, ""},
		{"gift ineligible", giftFailure(socialgift.ErrNotEligible), http.StatusConflict, unprovenRefusalCode, ""},
		{"gift content", giftFailure(socialgift.ErrContent), http.StatusConflict, unprovenRefusalCode, ""},
		{"gift conflict", giftFailure(socialgift.ErrConflict), http.StatusConflict, staleConflictCode, ""},
		{"gift clock defect", giftFailure(socialgift.ErrClock), http.StatusInternalServerError, unprovenRefusalCode, ""},
		{"gift invalid", giftFailure(socialgift.ErrInvalid), http.StatusBadRequest, 0, "invalid_social_request"},
		{"gift dependency", giftFailure(errors.New("database unavailable")), http.StatusInternalServerError, unprovenRefusalCode, ""},
	})
	assertPart2FailureCases(t, []part2FailureCase{{"gift nil dependency", giftFailure(nil), http.StatusInternalServerError, unprovenRefusalCode, ""}})
}

func TestPart3AI5FailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"sign refused", failI5(objective.ErrSignRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"awakening refused", failI5(objective.ErrAwakeningRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"mission refused", failI5(appi5.ErrMissionRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"mail not claimable", failI5(appi5.ErrMailNotClaimable), http.StatusConflict, unprovenRefusalCode, ""},
		{"mail stack full", failI5(appi5.ErrMailStackFull), http.StatusConflict, unprovenRefusalCode, ""},
		{"redeem invalid", failI5(appi5.ErrRedeemInvalid), http.StatusBadRequest, 0, "invalid_redeem"},
		{"mail not found", failI5(appi5.ErrMailNotFound), http.StatusBadRequest, 0, "not_found"},
		{"objective not found", failI5(appi5.ErrObjectiveNotFound), http.StatusBadRequest, 0, "not_found"},
		{"dependency", failI5(errors.New("database unavailable")), http.StatusInternalServerError, unprovenRefusalCode, ""},
	})
}

func TestPart3APetFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"acquisition inactive", petFail(characterpet.ErrPetAcquisitionContentInactive), http.StatusConflict, unprovenRefusalCode, ""},
		{"progression inactive", petFail(characterpet.ErrPetProgressionContentInactive), http.StatusConflict, unprovenRefusalCode, ""},
		{"equipment inactive", petFail(characterpet.ErrPetEquipmentContentInactive), http.StatusConflict, unprovenRefusalCode, ""},
		{"promotion inactive", petFail(characterpet.ErrPetPromotionContentInactive), http.StatusConflict, unprovenRefusalCode, ""},
		{"appearance inactive", petFail(characterpet.ErrPetAppearanceContentInactive), http.StatusConflict, unprovenRefusalCode, ""},
		{"provider unavailable", petFail(characterpet.ErrPetAwakeningProviderUnavailable), http.StatusServiceUnavailable, serverBusyCode, ""},
		{"not found", petFail(characterpet.ErrPetNotFound), http.StatusConflict, unprovenRefusalCode, ""},
		{"incubating", petFail(characterpet.ErrPetStillIncubating), http.StatusConflict, unprovenRefusalCode, ""},
		{"not shown", petFail(characterpet.ErrPetNotShown), http.StatusConflict, unprovenRefusalCode, ""},
		{"style switch", petFail(characterpet.ErrPetStyleSwitchConflict), http.StatusConflict, unprovenRefusalCode, ""},
		{"time discontinuity", petFail(characterpet.ErrPetTimeDiscontinuity), http.StatusInternalServerError, unprovenRefusalCode, ""},
		{"balance diamonds", petFail(economy.InsufficientBalance("crystal")), http.StatusConflict, insufficientDiamondCode, ""},
		{"appearance unavailable", petFail(characterpet.ErrPetAppearanceUnavailable), http.StatusConflict, unprovenRefusalCode, ""},
		{"exp max", petFail(characterpet.ErrPetExpMax), http.StatusConflict, unprovenRefusalCode, ""},
		{"evolution unavailable", petFail(characterpet.ErrPetEvolutionUnavailable), http.StatusConflict, unprovenRefusalCode, ""},
		{"skill unavailable", petFail(characterpet.ErrPetSkillUnavailable), http.StatusConflict, unprovenRefusalCode, ""},
		{"equipment unavailable", petFail(characterpet.ErrPetEquipmentUnavailable), http.StatusConflict, unprovenRefusalCode, ""},
		{"promotion unavailable", petFail(characterpet.ErrPetPromotionUnavailable), http.StatusConflict, unprovenRefusalCode, ""},
		{"promotion prerequisites", petFail(characterpet.ErrPetPromotionPrerequisites), http.StatusConflict, unprovenRefusalCode, ""},
		{"promotion corrupt", petFail(characterpet.ErrPetPromotionCorruptState), http.StatusInternalServerError, unprovenRefusalCode, ""},
		{"promotion q1 unsupported", petFail(characterpet.ErrPetPromotionQ1Unsupported), http.StatusConflict, unprovenRefusalCode, ""},
		{"dependency", petFail(errors.New("database unavailable")), http.StatusInternalServerError, unprovenRefusalCode, ""},
	})
}

func TestPart3APetCampaignFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"invalid", petCampaignFailure(pc.ErrInvalid), http.StatusBadRequest, 0, "pet_campaign_invalid_parameter"},
		{"conflict", petCampaignFailure(&receipt.ConflictError{}), http.StatusConflict, staleConflictCode, ""},
		{"refused", petCampaignFailure(pc.ErrRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"balance coins", petCampaignFailure(economy.InsufficientBalance("mana")), http.StatusConflict, insufficientCoinCode, ""},
		{"unavailable", petCampaignFailure(pc.ErrUnavailable), http.StatusConflict, unprovenRefusalCode, ""},
		{"dependency", petCampaignFailure(errors.New("database unavailable")), http.StatusInternalServerError, unprovenRefusalCode, ""},
	})
}

func TestPart3AGodsTrialFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"invalid", godsTrialFailure(god.ErrInvalid), http.StatusBadRequest, 0, "gods_trial_invalid_parameter"},
		{"conflict", godsTrialFailure(&receipt.ConflictError{}), http.StatusConflict, staleConflictCode, ""},
		{"loan refused", godsTrialFailure(combat.ErrLoanRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"refused", godsTrialFailure(god.ErrRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"pet not found", godsTrialFailure(characterpet.ErrPetNotFound), http.StatusConflict, unprovenRefusalCode, ""},
		{"balance stamina", godsTrialFailure(economy.InsufficientBalance("energy")), http.StatusConflict, insufficientStaminaCode, ""},
		{"unavailable", godsTrialFailure(god.ErrUnavailable), http.StatusConflict, unprovenRefusalCode, ""},
		{"dependency", godsTrialFailure(errors.New("database unavailable")), http.StatusInternalServerError, unprovenRefusalCode, ""},
	})
}

func TestPart3ARefusalCodesHaveClientMessageRows(t *testing.T) {
	rowSets := [][]failureRow{guildFailureRows, campaignFailureRows, rentalFailureRows, teaFailureRows, socialGiftFailureRows, i5FailureRows, petFailureRows, petCampaignFailureRows, godsTrialFailureRows}
	for _, rows := range rowSets {
		for _, row := range rows {
			if row.class != failureRefusal || row.code == unprovenRefusalCode || row.code == 0 || row.balance {
				continue
			}
			if !clientMessageIDs[row.code] {
				t.Errorf("refusal code %d has no client message row", row.code)
			}
		}
	}
}
