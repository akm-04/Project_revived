local var_0_0 = class("ZhugeFestival", import(".BaseModel"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Pet")
local var_0_3 = 6

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.infos = {}
	arg_1_0.allHeros = {}
	arg_1_0.allPets = {}
	arg_1_0.currentHeros = {}
	arg_1_0.currentPet = {}
	arg_1_0.canOpenShop = false
	arg_1_0.oldMemberInfo = {}
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.loadInfo(arg_3_0, arg_3_1)
	local var_3_0 = {
		activity_id = xyd.Activities.ZhugeFestival
	}

	arg_3_0.activities:loadSingleActivity(var_3_0, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK and arg_4_1 and arg_4_1.details then
			arg_3_0:updateInfo(arg_4_1.details)
		end

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.REFRESH_ZHUGE_SHOW
		})

		if arg_3_1 then
			arg_3_1(arg_4_0, arg_4_1)
		end
	end)
end

function var_0_0.updateInfo(arg_5_0, arg_5_1)
	arg_5_0.infos = arg_5_1 or {}
	arg_5_0.baseInfo = arg_5_0.infos.base_info or {}

	if arg_5_0.memberInfos and next(arg_5_0.memberInfos) then
		arg_5_0.oldMemberInfo = arg_5_0.memberInfos
	else
		arg_5_0.oldMemberInfo = arg_5_0.infos.member_infos or {}
	end

	arg_5_0.memberInfos = arg_5_0.infos.member_infos or {}
	arg_5_0.awards = arg_5_0.infos.awards or {}
	arg_5_0.mapInfo = arg_5_0.infos.map_info or {}

	if arg_5_1.boss_info then
		arg_5_0:updateBossInfo(arg_5_1.boss_info)
	end

	arg_5_0:updateIsComplete(nil, nil)
end

function var_0_0.updateNoteInfo(arg_6_0, arg_6_1)
	arg_6_0.noteInfo = arg_6_1
end

function var_0_0.updateBaseInfo(arg_7_0, arg_7_1)
	arg_7_0.infos.base_info = arg_7_1
	arg_7_0.baseInfo = arg_7_1
end

function var_0_0.getBaseInfo(arg_8_0)
	return arg_8_0.baseInfo or {}
end

function var_0_0.getMapInfo(arg_9_0)
	return arg_9_0.mapInfo or {}
end

function var_0_0.getMapPointByIndex(arg_10_0, arg_10_1)
	local var_10_0 = arg_10_0.mapInfo.points

	if var_10_0 then
		return var_10_0[arg_10_1] or {}
	end
end

function var_0_0.updateMapInfo(arg_11_0, arg_11_1)
	arg_11_0.mapInfo = arg_11_1
	arg_11_0.infos.map_info = arg_11_1
end

function var_0_0.updateSkillEffect(arg_12_0, arg_12_1)
	arg_12_0.skillEffect = arg_12_1
end

function var_0_0.getSkillEffect(arg_13_0)
	return arg_13_0.skillEffect or 0
end

function var_0_0.updateMemberInfo(arg_14_0, arg_14_1)
	if arg_14_0.memberInfos and next(arg_14_0.memberInfos) then
		arg_14_0.oldMemberInfo = arg_14_0.memberInfos
	else
		arg_14_0.oldMemberInfo = arg_14_1 or {}
	end

	arg_14_0.infos.member_infos = arg_14_1
	arg_14_0.memberInfos = arg_14_1
end

function var_0_0.checkTeamHasAlive(arg_15_0)
	for iter_15_0 = 1, #arg_15_0.memberInfos do
		local var_15_0 = arg_15_0.memberInfos[iter_15_0]

		if var_15_0.partner_type ~= 2 and var_15_0.partner_type ~= 3 and var_15_0.hp > 0 then
			return true
		end
	end

	return false
end

function var_0_0.updateBossInfo(arg_16_0, arg_16_1)
	arg_16_0.bossInfo = arg_16_1 or {}
end

function var_0_0.getLocalBossInfo(arg_17_0, arg_17_1)
	return arg_17_0.bossInfo or {}
end

function var_0_0.updateCurrentTeam(arg_18_0, arg_18_1)
	arg_18_0.currentHeros = arg_18_1.heros
	arg_18_0.currentPet = arg_18_1.pet
end

function var_0_0.getAwards(arg_19_0)
	return arg_19_0.awards or {}
end

function var_0_0.getMemberInfos(arg_20_0)
	return arg_20_0.memberInfos or {}
end

function var_0_0.getTotalHp(arg_21_0)
	local var_21_0 = arg_21_0:getMemberInfos()
	local var_21_1 = 0
	local var_21_2 = 0

	for iter_21_0 = 1, #var_21_0 do
		var_21_1 = var_21_1 + var_21_0[iter_21_0].max_hp
		var_21_2 = var_21_2 + var_21_0[iter_21_0].hp
	end

	return var_21_1, var_21_2
end

function var_0_0.setMemberHeros(arg_22_0, arg_22_1)
	arg_22_0.memberHeros = arg_22_1
end

function var_0_0.getMemberHeros(arg_23_0)
	if not arg_23_0.memberHeros or not next(arg_23_0.memberHeros) then
		local var_23_0 = arg_23_0:getMemberInfos()
		local var_23_1 = {}

		for iter_23_0, iter_23_1 in ipairs(var_23_0) do
			if iter_23_1.partner_type ~= 2 and iter_23_1.partner_type ~= 3 then
				local var_23_2 = var_0_1.new()
				local var_23_3 = arg_23_0.selfPlayer:getHeroIgnoreAwaken(iter_23_1.table_id)

				if var_23_3 then
					var_23_2:populate(var_23_3:toParams())

					var_23_2.type = xyd.LeftMenuType.SELF_HERO
				else
					var_23_2:initUnCollected(iter_23_1.table_id)

					var_23_2.type = xyd.LeftMenuType.RENT_HERO

					var_23_2:setStar(5)
				end

				var_23_2.partner_type = iter_23_1.partner_type

				table.insert(var_23_1, var_23_2)
			end
		end

		arg_23_0:formatNewHeros(var_23_1)

		arg_23_0.memberHeros = var_23_1
	end

	return arg_23_0.memberHeros or {}
end

function var_0_0.initEnemyInfo(arg_24_0, arg_24_1)
	local var_24_0 = xyd.tables.battle:fight1(arg_24_1)
	local var_24_1 = {}

	for iter_24_0 = 1, #var_24_0 - 1 do
		local var_24_2 = var_0_1.new()

		var_24_2:populateWithTableID(var_24_0[iter_24_0])

		var_24_2.star_ = xyd.tables.hero:star(var_24_0[iter_24_0])

		table.insert(var_24_1, var_24_2)
	end

	local var_24_3 = var_0_1.new()

	var_24_3:populateWithTableID(var_24_0[#var_24_0])

	var_24_3.star_ = xyd.tables.hero:star(var_24_0[#var_24_0])

	return var_24_1, var_24_3
end

function var_0_0.updateShopType(arg_25_0, arg_25_1)
	arg_25_0.canOpenShop = arg_25_1
end

function var_0_0.getShopType(arg_26_0)
	return arg_26_0.canOpenShop
end

function var_0_0.getExtraPatnerNum(arg_27_0)
	return arg_27_0.baseInfo.extra_partner_num or 0
end

function var_0_0.getCurrentHeros(arg_28_0)
	return arg_28_0.currentHeros or {}
end

function var_0_0.getCurrentPet(arg_29_0)
	return arg_29_0.currentPet or {}
end

function var_0_0.checkFightFail(arg_30_0)
	local var_30_0 = arg_30_0:getBaseInfo()

	if var_30_0 and var_30_0.fight_fail == 1 then
		return true
	end

	return false
end

function var_0_0.getEventID(arg_31_0)
	return arg_31_0.baseInfo.event_id or 0
end

function var_0_0.updateEventID(arg_32_0, arg_32_1)
	arg_32_0.baseInfo.event_id = arg_32_1
	arg_32_0.infos.base_info.event_id = arg_32_1
end

function var_0_0.isCanAvoid(arg_33_0)
	return arg_33_0.baseInfo.is_avoid == 1 and true or false
end

function var_0_0.checkIsPass(arg_34_0)
	return arg_34_0.baseInfo.is_passed == 1 and true or false
end

function var_0_0.updateIsComplete(arg_35_0, arg_35_1, arg_35_2)
	arg_35_0.isComplete_ = arg_35_1 or 0
	arg_35_0.isFirstComplete_ = arg_35_2 or 0
end

function var_0_0.checkIsComplete(arg_36_0)
	if arg_36_0.isComplete_ and arg_36_0.isComplete_ == 1 then
		return true
	end

	return false
end

function var_0_0.checkIsFirstComplete(arg_37_0)
	if arg_37_0.isFirstComplete_ and arg_37_0.isFirstComplete_ == 1 then
		return true
	end

	return false
end

function var_0_0.getLocalNoteInfo(arg_38_0)
	return arg_38_0.noteInfo or {}
end

function var_0_0.deleteBossItem(arg_39_0)
	return arg_39_0.isDelectBossItem or false
end

function var_0_0.setDeleteBossItem(arg_40_0, arg_40_1)
	arg_40_0.isDelectBossItem = arg_40_1 or false
end

function var_0_0.updateEnemyStar(arg_41_0, arg_41_1)
	arg_41_0.enemyStar = arg_41_1
end

function var_0_0.getEnemyStar(arg_42_0)
	return arg_42_0.enemyStar or 0
end

function var_0_0.getHeroStatus(arg_43_0, arg_43_1)
	local var_43_0 = arg_43_0:getMemberInfos()

	for iter_43_0 = 1, #var_43_0 do
		if var_43_0[iter_43_0].table_id == arg_43_1 or var_43_0[iter_43_0].table_id == xyd.tables.hero:beforeAwaken(arg_43_1) then
			return var_43_0[iter_43_0]
		end
	end

	return {}
end

function var_0_0.getOldHeroStatus(arg_44_0, arg_44_1)
	local var_44_0 = arg_44_0.oldMemberInfo or {}

	for iter_44_0 = 1, #var_44_0 do
		if var_44_0[iter_44_0].table_id == arg_44_1 or var_44_0[iter_44_0].table_id == xyd.tables.hero:beforeAwaken(arg_44_1) then
			return var_44_0[iter_44_0]
		end
	end

	return {}
end

function var_0_0.setSelectTeam(arg_45_0, arg_45_1, arg_45_2)
	local var_45_0 = arg_45_1 or {}

	xyd.Backend.get():request(xyd.mid.ZHUGE_SELECT_TEAM, var_45_0, function(arg_46_0, arg_46_1)
		if arg_46_0 == xyd.error.OK then
			arg_45_0.memberHeros = nil

			arg_45_0:updateInfo(arg_46_1)
		end

		if arg_45_2 then
			arg_45_2(arg_46_0, arg_46_1)
		end
	end, nil, nil, false)
end

function var_0_0.setExtraPartner(arg_47_0, arg_47_1, arg_47_2)
	local var_47_0 = {
		partner_ids = arg_47_1.partner_ids,
		rent_partner_ids = arg_47_1.rent_partner_ids
	}

	xyd.Backend.get():request(xyd.mid.ZHUGE_SET_EXTRA_PARTNER, var_47_0, function(arg_48_0, arg_48_1)
		if arg_48_0 == xyd.error.OK then
			arg_47_0:updateInfo(arg_48_1)
		end

		if arg_47_2 then
			arg_47_2(arg_48_0, arg_48_1)
		end
	end, nil, nil, false)
end

function var_0_0.sweep(arg_49_0, arg_49_1)
	xyd.Backend.get():request(xyd.mid.ZHUGE_SWEEP, {}, function(arg_50_0, arg_50_1)
		if arg_50_0 == xyd.error.OK and arg_50_1 and arg_50_1.base_info then
			arg_49_0:updateBaseInfo(arg_50_1.base_info)
		end

		if arg_49_1 then
			arg_49_1(arg_50_0, arg_50_1)
		end
	end, nil, nil, false)
end

function var_0_0.getEvent(arg_51_0, arg_51_1)
	xyd.Backend.get():request(xyd.mid.ZHUGE_GET_EVENT, {}, function(arg_52_0, arg_52_1)
		if arg_52_0 == xyd.error.OK then
			arg_51_0:updateBaseInfo(arg_52_1)
		end

		if arg_51_1 then
			arg_51_1(arg_52_0, arg_52_1)
		end
	end, nil, nil, false)
end

function var_0_0.selectBranch(arg_53_0, arg_53_1)
	xyd.Backend.get():request(xyd.mid.ZHUGE_SELECT_BRANCH, {}, function(arg_54_0, arg_54_1)
		if arg_54_0 == xyd.error.OK then
			arg_53_0:updateEventID(arg_54_1.event_id)
		end

		if arg_53_1 then
			arg_53_1(arg_54_0, arg_54_1)
		end
	end, nil, nil, false)
end

function var_0_0.startAdventure(arg_55_0, arg_55_1, arg_55_2)
	local var_55_0 = arg_55_1 or {}

	xyd.Backend.get():request(xyd.mid.ZHUGE_START_ADVENTURE, var_55_0, function(arg_56_0, arg_56_1)
		if arg_56_0 == xyd.error.OK then
			if arg_56_1 and arg_56_1.base_info then
				arg_55_0:updateBaseInfo(arg_56_1.base_info)
			end

			if arg_56_1 and arg_56_1.map_info then
				arg_55_0:updateMapInfo(arg_56_1.map_info)
			end

			if arg_56_1 and arg_56_1.skill_effect then
				arg_55_0:updateSkillEffect(arg_56_1.skill_effect)
			end

			arg_55_0:updateIsComplete(arg_56_1.is_complete, arg_56_1.is_first_complete)
		end

		if arg_55_2 then
			arg_55_2(arg_56_0, arg_56_1)
		end
	end, nil, nil, false)
end

function var_0_0.resetAdventure(arg_57_0, arg_57_1)
	xyd.Backend.get():request(xyd.mid.ZHUGE_RESET_ADVENTURE, {}, function(arg_58_0, arg_58_1)
		if arg_58_0 == xyd.error.OK then
			arg_57_0:updateInfo(arg_58_1)
		end

		if arg_57_1 then
			arg_57_1(arg_58_0, arg_58_1)
		end
	end, nil, nil, false)
end

function var_0_0.resetBackpack(arg_59_0)
	local var_59_0 = xyd.tables.zhugeShop:ids()
	local var_59_1 = arg_59_0.selfPlayer:getBackpack()

	for iter_59_0 = 1, #var_59_0 do
		local var_59_2 = var_59_0[iter_59_0]
		local var_59_3 = var_59_1:getItemNumByID(var_59_2)

		if var_59_3 > 0 then
			local var_59_4 = {
				itemID = var_59_2,
				itemNum = var_59_3
			}

			var_59_1:removeItem(var_59_4)
		end
	end
end

function var_0_0.getFormation(arg_60_0)
	local var_60_0 = arg_60_0:getCurrentHeros()
	local var_60_1 = ""

	for iter_60_0 = 1, #var_60_0 do
		local var_60_2 = var_60_0[iter_60_0]
		local var_60_3 = arg_60_0:getHeroStatus(var_60_2:getTableID())

		if var_60_3.health ~= 2 then
			var_60_1 = var_60_1 .. var_60_3.init_id

			if iter_60_0 ~= #var_60_0 then
				var_60_1 = var_60_1 .. "|"
			end
		end
	end

	local var_60_4 = arg_60_0:getCurrentPet()
	local var_60_5 = 0

	if var_60_4 and next(var_60_4) then
		var_60_5 = arg_60_0:getHeroStatus(var_60_4:getTableID()).init_id
	end

	return {
		partner_ids = var_60_1,
		pet_id = var_60_5
	}
end

function var_0_0.checkAvoidDamage(arg_61_0, arg_61_1)
	local var_61_0 = arg_61_0:getFormation()

	xyd.Backend.get():request(xyd.mid.ZHUGE_CHECK_AVOID_DAMAGE, var_61_0, function(arg_62_0, arg_62_1)
		if arg_62_0 == xyd.error.OK then
			arg_61_0:updateInfo(arg_62_1)
		end

		if arg_61_1 then
			arg_61_1(arg_62_0, arg_62_1)
		end
	end, nil, nil, false)
end

function var_0_0.avoidDamage(arg_63_0, arg_63_1, arg_63_2)
	local var_63_0 = arg_63_0:getFormation()

	var_63_0.is_avoid = arg_63_1 and 1 or 0

	xyd.Backend.get():request(xyd.mid.ZHUGE_AVOID_DAMAGE, var_63_0, function(arg_64_0, arg_64_1)
		if arg_64_0 == xyd.error.OK then
			arg_63_0:updateInfo(arg_64_1)
		end

		if arg_63_2 then
			arg_63_2(arg_64_0, arg_64_1)
		end
	end, nil, nil, false)
end

function var_0_0.buyShopItems(arg_65_0, arg_65_1, arg_65_2)
	local var_65_0 = {
		item_ids = "" .. arg_65_1
	}

	xyd.Backend.get():request(xyd.mid.ZHUGE_BUY_SHOP_ITEMS, var_65_0, function(arg_66_0, arg_66_1)
		if arg_66_0 == xyd.error.OK then
			arg_65_0:updateBaseInfo(arg_66_1)
		end

		if arg_65_2 then
			arg_65_2(arg_66_0, arg_66_1)
		end
	end, nil, nil, false)
end

function var_0_0.useItem(arg_67_0, arg_67_1, arg_67_2)
	xyd.Backend.get():request(xyd.mid.ZHUGE_USE_ITEM, arg_67_1, function(arg_68_0, arg_68_1)
		if arg_68_0 == xyd.error.OK then
			arg_67_0:updateMemberInfo(arg_68_1.member_infos)
		end

		if arg_67_2 then
			arg_67_2(arg_68_0, arg_68_1)
		end
	end, nil, nil, false)
end

function var_0_0.getNoteInfo(arg_69_0, arg_69_1)
	xyd.Backend.get():request(xyd.mid.ZHUGE_GET_NOTE_INFO, {}, function(arg_70_0, arg_70_1)
		if arg_70_0 == xyd.error.OK then
			arg_69_0:updateNoteInfo(arg_70_1)
		end

		if arg_69_1 then
			arg_69_1(arg_70_0, arg_70_1)
		end
	end, nil, nil, false)
end

function var_0_0.ramdomTask(arg_71_0, arg_71_1)
	xyd.Backend.get():request(xyd.mid.ZHUGE_RAMDOM_TASK, {}, function(arg_72_0, arg_72_1)
		if arg_72_0 == xyd.error.OK then
			arg_71_0:updateNoteInfo(arg_72_1)
		end

		if arg_71_1 then
			arg_71_1(arg_72_0, arg_72_1)
		end
	end, nil, nil, false)
end

function var_0_0.selectTask(arg_73_0, arg_73_1, arg_73_2)
	local var_73_0 = {
		cur_select = arg_73_1
	}

	xyd.Backend.get():request(xyd.mid.ZHUGE_SELECT_TASK, var_73_0, function(arg_74_0, arg_74_1)
		if arg_74_0 == xyd.error.OK then
			arg_73_0:updateNoteInfo(arg_74_1)
		end

		if arg_73_2 then
			arg_73_2(arg_74_0, arg_74_1)
		end
	end, nil, nil, false)
end

function var_0_0.completeTask(arg_75_0, arg_75_1, arg_75_2)
	local var_75_0 = arg_75_1 and 1 or 0
	local var_75_1 = {
		is_win = var_75_0
	}

	xyd.Backend.get():request(xyd.mid.ZHUGE_COMPLETE_TASK, var_75_1, function(arg_76_0, arg_76_1)
		if arg_76_0 == xyd.error.OK then
			arg_75_0:updateNoteInfo(arg_76_1.note_info)
		end

		if arg_75_2 then
			arg_75_2(arg_76_0, arg_76_1)
		end
	end, nil, nil, false)
end

function var_0_0.getRankList(arg_77_0, arg_77_1)
	xyd.Backend.get():request(xyd.mid.ZHUGE_GET_RANK_LIST, {}, function(arg_78_0, arg_78_1)
		if arg_78_0 == xyd.error.OK then
			-- block empty
		end

		if arg_77_1 then
			arg_77_1(arg_78_0, arg_78_1)
		end
	end, nil, nil, false)
end

function var_0_0.summon(arg_79_0, arg_79_1, arg_79_2, arg_79_3)
	local var_79_0 = {
		summon_type = arg_79_1,
		summon_index = arg_79_2
	}

	xyd.Backend.get():request(xyd.mid.ZHUGE_SUMMOM, var_79_0, function(arg_80_0, arg_80_1)
		if arg_80_0 == xyd.error.OK then
			-- block empty
		end

		if arg_79_3 then
			arg_79_3(arg_80_0, arg_80_1)
		end
	end, nil, nil, false)
end

function var_0_0.showBossAwards(arg_81_0, arg_81_1)
	if arg_81_0.isShowBossAward and arg_81_0.bossAward and next(arg_81_0.bossAward) then
		arg_81_0.selfPlayer:handleRewards(arg_81_0.bossAward, arg_81_1)

		arg_81_0.bossAward = nil
		arg_81_0.isShowBossAward = false
	end
end

function var_0_0.checkShowBossAward(arg_82_0)
	if arg_82_0.isShowBossAward and arg_82_0.bossAward and next(arg_82_0.bossAward) then
		return true
	end

	return false
end

function var_0_0.fightBoss(arg_83_0, arg_83_1, arg_83_2)
	xyd.Backend.get():request(xyd.mid.ZHUGE_FIGHT_BOSS, arg_83_1, function(arg_84_0, arg_84_1)
		if arg_84_0 == xyd.error.OK then
			arg_83_0:updateBossInfo(arg_84_1.boss_info)

			if arg_84_1.awards and next(arg_84_1.awards) then
				arg_83_0.bossAward = arg_84_1.awards
				arg_83_0.isShowBossAward = true
			end

			if arg_83_0:deleteBossItem() then
				local var_84_0 = arg_83_0.selfPlayer:getBackpack()
				local var_84_1 = {
					itemNum = 1,
					itemID = xyd.tables.misc.zhugeTeleportItem
				}

				var_84_0:removeItem(var_84_1)
			end
		end

		if arg_83_2 then
			arg_83_2(arg_84_0, arg_84_1)
		end
	end, nil, nil, false)
end

function var_0_0.getBossInfo(arg_85_0, arg_85_1)
	xyd.Backend.get():request(xyd.mid.ZHUGE_GET_BOSS_INFO, {}, function(arg_86_0, arg_86_1)
		if arg_86_0 == xyd.error.OK then
			arg_85_0:updateBossInfo(arg_86_1)
		end

		if arg_85_1 then
			arg_85_1(arg_86_0, arg_86_1)
		end
	end, nil, nil, false)
end

function var_0_0.selectVip(arg_87_0, arg_87_1, arg_87_2)
	local var_87_0 = {
		is_vip = arg_87_1
	}

	xyd.Backend.get():request(xyd.mid.ZHUGE_SELECT_VIP, var_87_0, function(arg_88_0, arg_88_1)
		if arg_88_0 == xyd.error.OK then
			arg_87_0:updateBaseInfo(arg_88_1)
		end

		if arg_87_2 then
			arg_87_2(arg_88_0, arg_88_1)
		end
	end, nil, nil, false)
end

function var_0_0.recoverEnergy(arg_89_0, arg_89_1, arg_89_2, arg_89_3)
	local var_89_0 = {
		recover_type = arg_89_1,
		num = arg_89_2
	}

	xyd.Backend.get():request(xyd.mid.ZHUGE_RECOVER_ENERGY, var_89_0, function(arg_90_0, arg_90_1)
		if arg_90_0 == xyd.error.OK then
			arg_89_0:updateBaseInfo(arg_90_1.base_info)
		end

		if arg_89_3 then
			arg_89_3(arg_90_0, arg_90_1)
		end
	end, nil, nil, false)
end

function var_0_0.selectDialog(arg_91_0, arg_91_1, arg_91_2)
	local var_91_0 = arg_91_1 or {}

	xyd.Backend.get():request(xyd.mid.ZHUGE_SELECT_DIALOG, var_91_0, function(arg_92_0, arg_92_1)
		if arg_92_0 == xyd.error.OK then
			if arg_92_1 and arg_92_1.map_info then
				arg_91_0:updateMapInfo(arg_92_1.map_info)
			end

			if arg_92_1 and arg_92_1.base_info then
				arg_91_0:updateBaseInfo(arg_92_1.base_info)
			end
		end

		if arg_91_2 then
			arg_91_2(arg_92_0, arg_92_1)
		end
	end, nil, nil, false)
end

function var_0_0.endCurDialog(arg_93_0, arg_93_1, arg_93_2, arg_93_3, arg_93_4, arg_93_5)
	local var_93_0 = {
		event_id = arg_93_1,
		dialog_id = arg_93_2,
		index = arg_93_3
	}

	if arg_93_4 and next(arg_93_4) then
		var_93_0.params = arg_93_4
	end

	arg_93_0:endDialog(var_93_0, function(arg_94_0, arg_94_1)
		if arg_93_5 then
			arg_93_5(arg_94_0, arg_94_1)
		end
	end)
end

function var_0_0.exchangeSkillBook(arg_95_0, arg_95_1, arg_95_2)
	local var_95_0 = {
		id = arg_95_1
	}

	xyd.Backend.get():request(xyd.mid.ZHUGE_EXCHANGE_SKILL_BOOK, var_95_0, function(arg_96_0, arg_96_1)
		if arg_96_0 == xyd.error.OK and arg_96_1 and arg_96_1.base_info then
			arg_95_0:updateBaseInfo(arg_96_1.base_info)
		end

		if arg_95_2 then
			arg_95_2(arg_96_0, arg_96_1)
		end
	end, nil, nil, false)
end

function var_0_0.endDialog(arg_97_0, arg_97_1, arg_97_2)
	local var_97_0 = arg_97_1 or {}

	xyd.Backend.get():request(xyd.mid.ZHUGE_END_DIALOG, var_97_0, function(arg_98_0, arg_98_1)
		if arg_98_0 == xyd.error.OK then
			if arg_98_1 and arg_98_1.map_info then
				arg_97_0:updateMapInfo(arg_98_1.map_info)
			end

			if arg_98_1 and arg_98_1.base_info then
				arg_97_0:updateBaseInfo(arg_98_1.base_info)
			end

			if arg_98_1 and arg_98_1.member_infos then
				arg_97_0:updateMemberInfo(arg_98_1.member_infos)
			end

			if arg_98_1 and arg_98_1.skill_effect then
				arg_97_0:updateSkillEffect(arg_98_1.skill_effect)
			end

			arg_97_0:updateIsComplete(arg_98_1.is_complete, arg_98_1.is_first_complete)
		end

		if arg_97_2 then
			arg_97_2(arg_98_0, arg_98_1)
		end
	end, nil, nil, false)
end

function var_0_0.getAdventureLog(arg_99_0, arg_99_1)
	xyd.Backend.get():request(xyd.mid.ZHUGE_ADVENTURE_LOG, {}, function(arg_100_0, arg_100_1)
		if arg_99_1 then
			arg_99_1(arg_100_0, arg_100_1)
		end
	end, nil, nil, false)
end

function var_0_0.formatNewHeros(arg_101_0, arg_101_1)
	local var_101_0 = {
		100,
		100,
		80,
		60,
		0,
		0
	}
	local var_101_1 = {
		0,
		0,
		0,
		0,
		0,
		0
	}
	local var_101_2 = {
		0,
		0,
		0,
		0,
		0,
		0
	}
	local var_101_3 = {
		0,
		0,
		0,
		0,
		0,
		0
	}

	for iter_101_0, iter_101_1 in pairs(arg_101_1) do
		if iter_101_1:isHaveAwakenItem() and not iter_101_1:isAwaken() then
			local var_101_4 = {
				100,
				100,
				80,
				60,
				0,
				0
			}
			local var_101_5 = {
				1,
				1,
				1,
				1,
				1,
				1
			}

			arg_101_0:renewHeroInfo(iter_101_1, var_101_4, var_101_1, var_101_5, var_101_2)
		elseif iter_101_1:isAwaken() and not iter_101_1:isAwakeTwice() then
			local var_101_6 = {
				100,
				100,
				80,
				60,
				40,
				0
			}
			local var_101_7 = {
				1,
				1,
				1,
				1,
				1,
				1
			}

			arg_101_0:renewHeroInfo(iter_101_1, var_101_6, var_101_1, var_101_7, var_101_2)
		elseif iter_101_1:isAwakeTwice() then
			local var_101_8 = {
				100,
				100,
				80,
				60,
				40,
				40
			}
			local var_101_9 = {
				1,
				1,
				1,
				1,
				1,
				1
			}

			arg_101_0:renewHeroInfo(iter_101_1, var_101_8, var_101_1, var_101_9, var_101_2)
		else
			local var_101_10 = {
				100,
				100,
				80,
				60,
				0,
				0
			}
			local var_101_11 = {
				0,
				1,
				1,
				1,
				1,
				1
			}

			arg_101_0:renewHeroInfo(iter_101_1, var_101_10, var_101_1, var_101_11, var_101_2)
		end

		iter_101_1:updatePracticeAwardAttr()
	end
end

function var_0_0.renewHeroInfo(arg_102_0, arg_102_1, arg_102_2, arg_102_3, arg_102_4, arg_102_5)
	arg_102_1.color_ = 16
	arg_102_1.level_ = 100
	arg_102_1.skillLev_ = {}
	arg_102_1.skillLev_[xyd.SKILL_INDEX.Energy] = tonumber(arg_102_2[xyd.SKILL_INDEX.Energy]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Energy]

	if arg_102_1.color_ >= xyd.EquipQuality.GREEN then
		arg_102_1.skillLev_[xyd.SKILL_INDEX.Green] = tonumber(arg_102_2[xyd.SKILL_INDEX.Green]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Green]
	else
		arg_102_1.skillLev_[xyd.SKILL_INDEX.Green] = false
	end

	if arg_102_1.color_ >= xyd.EquipQuality.BLUE then
		arg_102_1.skillLev_[xyd.SKILL_INDEX.Blue] = tonumber(arg_102_2[xyd.SKILL_INDEX.Blue]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Blue]
	else
		arg_102_1.skillLev_[xyd.SKILL_INDEX.Blue] = false
	end

	if arg_102_1.color_ >= xyd.EquipQuality.PURPLE then
		arg_102_1.skillLev_[xyd.SKILL_INDEX.Purple] = tonumber(arg_102_2[xyd.SKILL_INDEX.Purple]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Purple]
	else
		arg_102_1.skillLev_[xyd.SKILL_INDEX.Purple] = false
	end

	if arg_102_1:isAwaken() then
		arg_102_1.skillLev_[xyd.SKILL_INDEX.Awake] = tonumber(arg_102_2[xyd.SKILL_INDEX.Awake]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Awake]
	else
		arg_102_1.skillLev_[xyd.SKILL_INDEX.Awake] = false
	end

	if arg_102_1:isAwakeTwice() then
		arg_102_1.skillLev_[xyd.SKILL_INDEX.AwakeTwice] = tonumber(arg_102_2[xyd.SKILL_INDEX.AwakeTwice]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.AwakeTwice]
	else
		arg_102_1.skillLev_[xyd.SKILL_INDEX.AwakeTwice] = false
	end

	arg_102_1.equips_ = {}

	for iter_102_0 = 1, var_0_3 do
		table.insert(arg_102_1.equips_, tonumber(arg_102_4[iter_102_0]))
	end

	arg_102_1.fumo_ = {}

	for iter_102_1 = 1, var_0_3 do
		table.insert(arg_102_1.fumo_, tonumber(arg_102_3[iter_102_1]))
	end

	arg_102_1.fumoLev_ = {}

	for iter_102_2 = 1, var_0_3 do
		table.insert(arg_102_1.fumoLev_, tonumber(arg_102_5[iter_102_2]))
	end

	dump(arg_102_1.fumo_)
	dump(arg_102_1.fumoLev_)
end

function var_0_0.formatNewPets(arg_103_0, arg_103_1)
	local var_103_0 = {
		100,
		100,
		80,
		60,
		0
	}

	for iter_103_0, iter_103_1 in pairs(arg_103_1) do
		if iter_103_1:isHaveAwakenItem() and not iter_103_1:isAwaken() then
			local var_103_1 = {
				100,
				100,
				80,
				60,
				0
			}
			local var_103_2 = {
				1,
				1,
				1
			}

			arg_103_0:renewPetInfo(iter_103_1, var_103_1, var_103_2)
		elseif iter_103_1:isAwaken() then
			local var_103_3 = {
				100,
				100,
				80,
				60,
				40
			}
			local var_103_4 = {
				1,
				1,
				1
			}

			arg_103_0:renewPetInfo(iter_103_1, var_103_3, var_103_4)
		else
			local var_103_5 = {
				100,
				100,
				80,
				60,
				0
			}
			local var_103_6 = {
				0,
				1,
				1
			}

			arg_103_0:renewPetInfo(iter_103_1, var_103_5, var_103_6)
		end

		iter_103_1:updatePracticeAwardAttr()
	end
end

function var_0_0.renewPetInfo(arg_104_0, arg_104_1, arg_104_2, arg_104_3)
	local var_104_0 = 16

	arg_104_1.level_, arg_104_1.color_ = 100, var_104_0
	arg_104_1.skillLev_ = {}
	arg_104_1.skillLev_[xyd.SKILL_INDEX.Energy] = tonumber(arg_104_2[xyd.SKILL_INDEX.Energy]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Energy]

	if arg_104_1.color_ >= xyd.EquipQuality.GREEN then
		arg_104_1.skillLev_[xyd.SKILL_INDEX.Green] = tonumber(arg_104_2[xyd.SKILL_INDEX.Green]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Green]
	else
		arg_104_1.skillLev_[xyd.SKILL_INDEX.Green] = false
	end

	if arg_104_1.color_ >= xyd.EquipQuality.BLUE then
		arg_104_1.skillLev_[xyd.SKILL_INDEX.Blue] = tonumber(arg_104_2[xyd.SKILL_INDEX.Blue]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Blue]
	else
		arg_104_1.skillLev_[xyd.SKILL_INDEX.Blue] = false
	end

	if arg_104_1.color_ >= xyd.EquipQuality.PURPLE then
		arg_104_1.skillLev_[xyd.SKILL_INDEX.Purple] = tonumber(arg_104_2[xyd.SKILL_INDEX.Purple]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Purple]
	else
		arg_104_1.skillLev_[xyd.SKILL_INDEX.Purple] = false
	end

	if arg_104_1:isAwaken() then
		arg_104_1.skillLev_[xyd.SKILL_INDEX.Awake] = tonumber(arg_104_2[xyd.SKILL_INDEX.Awake]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Awake]
	else
		arg_104_1.skillLev_[xyd.SKILL_INDEX.Awake] = false
	end

	arg_104_1.equips_ = {}

	for iter_104_0 = 1, var_0_3 do
		table.insert(arg_104_1.equips_, tonumber(arg_104_3[iter_104_0]))
	end
end

function var_0_0.spy(arg_105_0, arg_105_1, arg_105_2)
	xyd.Backend.get():request(xyd.mid.ZHUGE_ADVENTURE_SPY, arg_105_1, function(arg_106_0, arg_106_1)
		if arg_106_0 == xyd.error.OK then
			arg_105_0:updateBaseInfo(arg_106_1.base_info)
		end

		if arg_105_2 then
			arg_105_2(arg_106_0, arg_106_1)
		end
	end, nil, nil, false)
end

function var_0_0.changeSummonType(arg_107_0, arg_107_1, arg_107_2)
	xyd.Backend.get():request(xyd.mid.ZHUGE_CHANGE_SUMMON_TYPE, arg_107_1, function(arg_108_0, arg_108_1)
		if arg_108_0 == xyd.error.OK and arg_108_1.base_info then
			-- block empty
		end

		if arg_107_2 then
			arg_107_2(arg_108_0, arg_108_1)
		end
	end, nil, nil, false)
end

function var_0_0.skipAdventure(arg_109_0, arg_109_1)
	xyd.Backend.get():request(xyd.mid.ZHUGE_SKIP_ADVENTURE, nil, function(arg_110_0, arg_110_1)
		if arg_110_0 == xyd.error.OK then
			if arg_110_1 and arg_110_1.map_info then
				arg_109_0:updateMapInfo(arg_110_1.map_info)
			end

			if arg_110_1 and arg_110_1.base_info then
				arg_109_0:updateBaseInfo(arg_110_1.base_info)
			end

			if arg_110_1 and arg_110_1.member_infos then
				arg_109_0:updateMemberInfo(arg_110_1.member_infos)
			end

			if arg_110_1 and arg_110_1.skill_effect then
				arg_109_0:updateSkillEffect(arg_110_1.skill_effect)
			end

			arg_109_0:updateIsComplete(arg_110_1.is_complete, arg_110_1.is_first_complete)

			if arg_109_1 then
				arg_109_1(arg_110_0, arg_110_1)
			end
		end
	end)
end

return var_0_0
