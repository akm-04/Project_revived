local var_0_0 = class("WarCamp", import(".BaseModel"))
local var_0_1 = 10

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.loaded_ = false
	arg_1_0.activity = {}
	arg_1_0.oldHeroStatus = {}
	arg_1_0.records_ = {}
	arg_1_0.reports_ = {}
	arg_1_0.oldBossMapInfo = {}
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.loadSingleActivity(arg_3_0, arg_3_1)
	local var_3_0 = {
		activity_id = xyd.Activities.WarCamp
	}

	arg_3_0.activities:loadSingleActivity(var_3_0, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_0:updateInfo(arg_4_1)

			if arg_3_1 then
				arg_3_1(arg_4_0, arg_4_1)
			end
		end
	end)
end

function var_0_0.updateInfo(arg_5_0, arg_5_1)
	arg_5_0.activity = arg_5_1
	arg_5_0.baseInfo = arg_5_1.details.base_info or {}
end

function var_0_0.updateDetailInfo(arg_6_0, arg_6_1)
	arg_6_0.partnerInfos = arg_6_1.partner_infos or {}
	arg_6_0.oldHeroStatus = clone(arg_6_0.partnerInfos)
	arg_6_0.teamInfos = arg_6_1.team_infos or {}
	arg_6_0.mapInfos = arg_6_1.map_infos or {}
	arg_6_0.petInfos = arg_6_1.pet_infos or {}
end

function var_0_0.updateMapInfos(arg_7_0, arg_7_1)
	local var_7_0, var_7_1 = arg_7_0:getMapInfoByMapID(arg_7_1.map_id)

	if var_7_1 ~= 0 then
		arg_7_0.oldBossMapInfo = clone(arg_7_0.mapInfos[var_7_1])
		arg_7_0.mapInfos[var_7_1] = arg_7_1
	end
end

function var_0_0.getOldBossMapInfo(arg_8_0)
	return arg_8_0.oldBossMapInfo or {}
end

function var_0_0.getDieHeros(arg_9_0)
	local var_9_0 = {}

	for iter_9_0 = 1, #arg_9_0.partnerInfos do
		if arg_9_0.partnerInfos[iter_9_0].health and arg_9_0.partnerInfos[iter_9_0].health == 2 then
			table.insert(var_9_0, arg_9_0.partnerInfos[iter_9_0].partner_id)
		end
	end

	return var_9_0
end

function var_0_0.getDayCount(arg_10_0)
	return arg_10_0.baseInfo.day_count or 1
end

function var_0_0.getDefenseWins(arg_11_0)
	return arg_11_0.baseInfo.defense_wins or {}
end

function var_0_0.getScore(arg_12_0)
	return arg_12_0.baseInfo.score or 0
end

function var_0_0.getWins(arg_13_0)
	return arg_13_0.baseInfo.wins or 0
end

function var_0_0.getFightTimes(arg_14_0)
	return arg_14_0.baseInfo.fight_times or 0
end

function var_0_0.getMissionInfo(arg_15_0)
	return arg_15_0.baseInfo.missions or {}
end

function var_0_0.updateTeamMapID(arg_16_0, arg_16_1)
	local var_16_0 = arg_16_0:getTeamById(arg_16_1.team_id)

	if var_16_0 ~= 0 then
		arg_16_0.teamInfos[var_16_0].map_id = arg_16_1.map_id
	end
end

function var_0_0.removeTeamById(arg_17_0, arg_17_1)
	for iter_17_0, iter_17_1 in ipairs(arg_17_0.teamInfos) do
		if iter_17_1.team_id == arg_17_1 then
			arg_17_0:updatePartnerInfoByIDs(arg_17_0.teamInfos[iter_17_0].partner_ids)
			arg_17_0:updatePetInfoByID(arg_17_0.teamInfos[iter_17_0].pet_id)
			table.remove(arg_17_0.teamInfos, iter_17_0)

			break
		end
	end
end

function var_0_0.getTeamsByMapId(arg_18_0, arg_18_1)
	local var_18_0 = {}

	for iter_18_0 = 1, #arg_18_0.teamInfos do
		if arg_18_0.teamInfos[iter_18_0].map_id == arg_18_1 then
			table.insert(var_18_0, arg_18_0.teamInfos[iter_18_0])
		end
	end

	return var_18_0
end

function var_0_0.getTeamById(arg_19_0, arg_19_1)
	for iter_19_0 = 1, #arg_19_0.teamInfos do
		if arg_19_0.teamInfos[iter_19_0].team_id == arg_19_1 then
			return iter_19_0
		end
	end

	return 0
end

function var_0_0.isMyCampCity(arg_20_0, arg_20_1)
	local var_20_0 = arg_20_0:getCampType()

	for iter_20_0 = 1, #arg_20_0.mapInfos do
		if arg_20_1 == arg_20_0.mapInfos[iter_20_0].map_id and var_20_0 == arg_20_0.mapInfos[iter_20_0].camp then
			return true
		end
	end

	return false
end

function var_0_0.updateTeamInfo(arg_21_0, arg_21_1)
	for iter_21_0 = 1, #arg_21_1 do
		local var_21_0 = arg_21_0:getTeamById(arg_21_1[iter_21_0].team_id)

		if var_21_0 ~= 0 then
			if not arg_21_1[iter_21_0].map_id then
				table.remove(arg_21_0.teamInfos, var_21_0)
			else
				arg_21_0.teamInfos[var_21_0] = arg_21_1[iter_21_0]
			end
		else
			table.insert(arg_21_0.teamInfos, arg_21_1[iter_21_0])
		end
	end
end

function var_0_0.getPartnerByID(arg_22_0, arg_22_1)
	for iter_22_0 = 1, #arg_22_0.partnerInfos do
		if arg_22_0.partnerInfos[iter_22_0].partner_id == arg_22_1 then
			return iter_22_0
		end
	end

	return 0
end

function var_0_0.updatePartnerInfos(arg_23_0, arg_23_1)
	arg_23_0.oldHeroStatus = clone(arg_23_0.partnerInfos)

	for iter_23_0 = 1, #arg_23_1 do
		local var_23_0 = arg_23_0:getPartnerByID(arg_23_1[iter_23_0].partner_id)

		if var_23_0 ~= 0 then
			arg_23_0.partnerInfos[var_23_0] = arg_23_1[iter_23_0]
		else
			table.insert(arg_23_0.partnerInfos, arg_23_1[iter_23_0])
			table.insert(arg_23_0.oldHeroStatus, arg_23_1[iter_23_0])
		end
	end
end

function var_0_0.getPetByID(arg_24_0, arg_24_1)
	for iter_24_0 = 1, #arg_24_0.petInfos do
		if arg_24_0.petInfos[iter_24_0].pet_id == arg_24_1 then
			return iter_24_0
		end
	end

	return 0
end

function var_0_0.updatePetInfos(arg_25_0, arg_25_1)
	for iter_25_0 = 1, #arg_25_1 do
		local var_25_0 = arg_25_0:getPetByID(arg_25_1[iter_25_0].pet_id)

		if var_25_0 ~= 0 then
			arg_25_0.petInfos[var_25_0] = arg_25_1[iter_25_0]
		else
			table.insert(arg_25_0.petInfos, arg_25_1[iter_25_0])
		end
	end
end

function var_0_0.updatePartnerInfoByIDs(arg_26_0, arg_26_1)
	for iter_26_0 = 1, #arg_26_1 do
		local var_26_0 = arg_26_0:getPartnerByID(arg_26_1[iter_26_0])

		if var_26_0 > 0 then
			arg_26_0.partnerInfos[var_26_0].team_id = 0
			arg_26_0.oldHeroStatus[var_26_0].team_id = 0
		end
	end
end

function var_0_0.updatePetInfoByID(arg_27_0, arg_27_1)
	local var_27_0 = arg_27_0:getPetByID(arg_27_1)

	if var_27_0 ~= 0 then
		arg_27_0.petInfos[var_27_0].team_id = 0
	end
end

function var_0_0.checkHeroIsSelect(arg_28_0, arg_28_1, arg_28_2)
	local var_28_0 = false

	for iter_28_0 = 1, #arg_28_0.partnerInfos do
		if arg_28_0.partnerInfos[iter_28_0].partner_id == arg_28_1:getHeroID() and arg_28_0.partnerInfos[iter_28_0].team_id ~= 0 and arg_28_0.partnerInfos[iter_28_0].team_id ~= arg_28_2 then
			var_28_0 = true

			break
		end
	end

	return var_28_0
end

function var_0_0.checkPetIsSelect(arg_29_0, arg_29_1, arg_29_2)
	local var_29_0 = false

	for iter_29_0 = 1, #arg_29_0.petInfos do
		if arg_29_0.petInfos[iter_29_0].pet_id == arg_29_1:getPetID() and arg_29_0.petInfos[iter_29_0].team_id ~= 0 and arg_29_0.petInfos[iter_29_0].team_id ~= arg_29_2 then
			var_29_0 = true

			break
		end
	end

	return var_29_0
end

function var_0_0.updateHeros(arg_30_0, arg_30_1)
	xyd.formatRegionArenaHeros(arg_30_1)
end

function var_0_0.updatePets(arg_31_0, arg_31_1)
	xyd.formatRegionArenaPets(arg_31_1)
end

function var_0_0.getHeroStatusByID(arg_32_0, arg_32_1)
	if arg_32_0.partnerInfos and next(arg_32_0.partnerInfos) then
		for iter_32_0 = 1, #arg_32_0.partnerInfos do
			if arg_32_0.partnerInfos[iter_32_0].partner_id == arg_32_1 then
				return arg_32_0.partnerInfos[iter_32_0]
			end
		end
	end

	return {}
end

function var_0_0.getCampType(arg_33_0)
	return arg_33_0.baseInfo.group_id
end

function var_0_0.updateBaseInfo(arg_34_0, arg_34_1)
	arg_34_0.activity.details.base_info = arg_34_1
	arg_34_0.baseInfo = arg_34_1
end

function var_0_0.getSelfCitys(arg_35_0)
	local var_35_0 = {}
	local var_35_1 = arg_35_0:getCampType()

	for iter_35_0 = 1, #arg_35_0.mapInfos do
		local var_35_2 = arg_35_0.mapInfos[iter_35_0]

		if var_35_2.camp == var_35_1 then
			table.insert(var_35_0, var_35_2)
		end
	end

	return var_35_0
end

function var_0_0.getMaxCityNum(arg_36_0)
	return var_0_1
end

function var_0_0.apply(arg_37_0, arg_37_1, arg_37_2)
	local var_37_0 = {
		group_id = arg_37_1
	}

	xyd.Backend.get():request(xyd.mid.WAR_CAMP_APPLY, var_37_0, function(arg_38_0, arg_38_1)
		if arg_38_0 == xyd.error.OK then
			arg_37_0:updateBaseInfo(arg_38_1.base_info)
		end

		if arg_37_2 then
			arg_37_2(arg_38_0, arg_38_1)
		end
	end)
end

function var_0_0.createNewTeam(arg_39_0, arg_39_1, arg_39_2)
	local var_39_0 = arg_39_1 or {}

	xyd.Backend.get():request(xyd.mid.WAR_CAMP_NEW_TEAM, var_39_0, function(arg_40_0, arg_40_1)
		if arg_40_0 == xyd.error.OK then
			if arg_40_1 and arg_40_1.team_infos then
				arg_39_0:updateTeamInfo(arg_40_1.team_infos, true)
			end

			if arg_40_1 and arg_40_1.partner_infos then
				arg_39_0:updatePartnerInfos(arg_40_1.partner_infos)
			end

			if arg_40_1 and arg_40_1.pet_infos then
				arg_39_0:updatePetInfos(arg_40_1.pet_infos)
			end
		end

		if arg_39_2 then
			arg_39_2(arg_40_0, arg_40_1)
		end
	end)
end

function var_0_0.modifyTeam(arg_41_0, arg_41_1, arg_41_2)
	local var_41_0 = arg_41_1 or {}

	xyd.Backend.get():request(xyd.mid.WAR_CAMP_MODIFY_TEAM, var_41_0, function(arg_42_0, arg_42_1)
		if arg_42_0 == xyd.error.OK then
			if arg_42_1 and arg_42_1.team_infos then
				arg_41_0:updateTeamInfo(arg_42_1.team_infos, true)
			end

			if arg_42_1 and arg_42_1.partner_infos then
				arg_41_0:updatePartnerInfos(arg_42_1.partner_infos)
			end

			if arg_42_1 and arg_42_1.pet_infos then
				arg_41_0:updatePetInfos(arg_42_1.pet_infos)
			end
		end

		if arg_41_2 then
			arg_41_2(arg_42_0, arg_42_1)
		end
	end)
end

function var_0_0.getInfos(arg_43_0, arg_43_1)
	local var_43_0 = {}

	xyd.Backend.get():request(xyd.mid.WAR_CAMP_GET_INFOS, var_43_0, function(arg_44_0, arg_44_1)
		if arg_44_0 == xyd.error.OK then
			arg_43_0:updateDetailInfo(arg_44_1)
		end

		if arg_43_1 then
			arg_43_1(arg_44_0, arg_44_1)
		end
	end)
end

function var_0_0.fightBoss(arg_45_0, arg_45_1, arg_45_2)
	local var_45_0 = arg_45_1 or {}

	xyd.Backend.get():request(xyd.mid.WAR_CAMP_FIGHT_BOSS, var_45_0, function(arg_46_0, arg_46_1)
		if arg_46_0 == xyd.error.OK then
			if arg_46_1 and arg_46_1.partner_infos then
				arg_45_0:updatePartnerInfos(arg_46_1.partner_infos)
			end

			if arg_46_1 and arg_46_1.map_info then
				arg_45_0:updateMapInfos(arg_46_1.map_info)
			end

			if arg_46_1 and arg_46_1.team_info then
				arg_45_0:updateTeamInfo({
					arg_46_1.team_info
				}, true)
			end

			if arg_46_1 and arg_46_1.base_info then
				arg_45_0:updateBaseInfo(arg_46_1.base_info)
			end
		end

		if arg_45_2 then
			arg_45_2(arg_46_0, arg_46_1)
		end
	end)
end

function var_0_0.delTeam(arg_47_0, arg_47_1, arg_47_2)
	local var_47_0 = arg_47_1 or {}

	xyd.Backend.get():request(xyd.mid.WAR_CAMP_DEL_TEAM, var_47_0, function(arg_48_0, arg_48_1)
		if arg_48_0 == xyd.error.OK then
			arg_47_0:removeTeamById(var_47_0.team_id)
		end

		if arg_47_2 then
			arg_47_2(arg_48_0, arg_48_1)
		end
	end)
end

function var_0_0.moveTeam(arg_49_0, arg_49_1, arg_49_2)
	local var_49_0 = arg_49_1 or {}

	xyd.Backend.get():request(xyd.mid.WAR_CAMP_MOVE_TEAM, var_49_0, function(arg_50_0, arg_50_1)
		if arg_50_0 == xyd.error.OK then
			arg_49_0:updateTeamMapID(var_49_0)
		end

		if arg_49_2 then
			arg_49_2(arg_50_0, arg_50_1)
		end
	end)
end

function var_0_0.rebornHero(arg_51_0, arg_51_1, arg_51_2)
	local var_51_0 = arg_51_1 or {}

	xyd.Backend.get():request(xyd.mid.WAR_CAMP_REBORN_HERO, var_51_0, function(arg_52_0, arg_52_1)
		if arg_52_0 == xyd.error.OK then
			arg_51_0:updatePartnerInfos(arg_52_1.partner_infos)
		end

		if arg_51_2 then
			arg_51_2(arg_52_0, arg_52_1)
		end
	end)
end

function var_0_0.rebornTeam(arg_53_0, arg_53_1, arg_53_2)
	local var_53_0 = arg_53_1 or {}

	xyd.Backend.get():request(xyd.mid.WAR_CAMP_REBORN_TEAM, var_53_0, function(arg_54_0, arg_54_1)
		if arg_54_0 == xyd.error.OK then
			arg_53_0:updatePartnerInfos(arg_54_1.partner_infos)
		end

		if arg_53_2 then
			arg_53_2(arg_54_0, arg_54_1)
		end
	end)
end

function var_0_0.buyItem(arg_55_0, arg_55_1, arg_55_2)
	local var_55_0 = arg_55_1 or {}

	xyd.Backend.get():request(xyd.mid.WAR_CAMP_BUY_ITEM, var_55_0, function(arg_56_0, arg_56_1)
		if arg_56_0 == xyd.error.OK then
			arg_55_0:updateBaseInfo(arg_56_1)
		end

		if arg_55_2 then
			arg_55_2(arg_56_0, arg_56_1)
		end
	end)
end

function var_0_0.getHurtRank(arg_57_0, arg_57_1, arg_57_2)
	local var_57_0 = arg_57_1 or {}

	xyd.Backend.get():request(xyd.mid.WAR_CAMP_GET_HURT_RANK, var_57_0, function(arg_58_0, arg_58_1)
		if arg_57_2 then
			arg_57_2(arg_58_0, arg_58_1)
		end
	end)
end

function var_0_0.getScoreRank(arg_59_0, arg_59_1)
	xyd.Backend.get():request(xyd.mid.WAR_CAMP_GET_SCORE_RANK, {}, function(arg_60_0, arg_60_1)
		if arg_59_1 then
			arg_59_1(arg_60_0, arg_60_1)
		end
	end)
end

function var_0_0.fightEnemy(arg_61_0, arg_61_1, arg_61_2)
	local var_61_0 = arg_61_1 or {}

	xyd.Backend.get():request(xyd.mid.WAR_CAMP_FIGHT_ENEMY, var_61_0, function(arg_62_0, arg_62_1)
		if arg_62_0 == xyd.error.OK then
			if arg_62_1 and arg_62_1.map_info then
				arg_61_0:updateMapInfos(arg_62_1.map_info)
			end

			if arg_62_1 and arg_62_1.partner_infos then
				arg_61_0:updatePartnerInfos(arg_62_1.partner_infos)
			end

			if arg_62_1 and arg_62_1.team_info then
				arg_61_0:updateTeamInfo({
					arg_62_1.team_info
				}, true)
			end

			if arg_62_1 and arg_62_1.base_info then
				arg_61_0:updateBaseInfo(arg_62_1.base_info)
			end
		end

		if arg_61_2 then
			arg_61_2(arg_62_0, arg_62_1)
		end
	end)
end

function var_0_0.getMapInfoByMapID(arg_63_0, arg_63_1)
	local var_63_0 = {}
	local var_63_1 = 0

	for iter_63_0 = 1, #arg_63_0.mapInfos do
		if arg_63_0.mapInfos[iter_63_0].map_id == arg_63_1 then
			var_63_0 = arg_63_0.mapInfos[iter_63_0]
			var_63_1 = iter_63_0
		end
	end

	return var_63_0, var_63_1
end

function var_0_0.getDamageResult(arg_64_0)
	return arg_64_0.damageResult or {}
end

function var_0_0.getOldHeroStatus(arg_65_0, arg_65_1)
	for iter_65_0 = 1, #arg_65_0.oldHeroStatus do
		if arg_65_0.oldHeroStatus[iter_65_0].partner_id == arg_65_1 then
			return arg_65_0.oldHeroStatus[iter_65_0]
		end
	end

	return {}
end

function var_0_0.getRecordsList(arg_66_0)
	return arg_66_0.records_ or {}
end

function var_0_0.getRecords(arg_67_0, arg_67_1)
	xyd.Backend.get():request(xyd.mid.WAR_CAMP_FIGHT_RECORDS, {}, function(arg_68_0, arg_68_1)
		if arg_68_0 == xyd.error.OK then
			arg_67_0.records_ = arg_68_1
		end

		if arg_67_1 then
			arg_67_1(arg_68_0, arg_68_1)
		end
	end)
end

function var_0_0.getReport(arg_69_0, arg_69_1, arg_69_2)
	if arg_69_0.reports_[arg_69_1.id] then
		if arg_69_2 then
			arg_69_2(xyd.error.OK, arg_69_0.reports_[arg_69_1.id])
		end

		return
	end

	local var_69_0 = arg_69_1 or {}

	xyd.Backend.get():request(xyd.mid.WAR_CAMP_FIGHT_REPORT, var_69_0, function(arg_70_0, arg_70_1)
		if arg_70_0 == xyd.error.OK then
			arg_69_0.reports_[var_69_0.id] = arg_70_1
		end

		if arg_69_2 then
			arg_69_2(arg_70_0, arg_70_1)
		end
	end)
end

function var_0_0.getMapTeams(arg_71_0, arg_71_1, arg_71_2)
	local var_71_0 = arg_71_1 or {}

	xyd.Backend.get():request(xyd.mid.WAR_CAMP_MAP_TEAMS, var_71_0, function(arg_72_0, arg_72_1)
		if arg_71_2 then
			arg_71_2(arg_72_0, arg_72_1)
		end
	end)
end

function var_0_0.buyReviveItem(arg_73_0, arg_73_1)
	local var_73_0 = {}

	xyd.Backend.get():request(xyd.mid.WAR_CAMP_BUY_REVIVE_ITEM, var_73_0, function(arg_74_0, arg_74_1)
		if arg_73_1 then
			arg_73_1(arg_74_0, arg_74_1)
		end
	end)
end

return var_0_0
