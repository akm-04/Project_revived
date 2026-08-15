local var_0_0 = class("WarCampSelectTeamWindow", import("app.windows.BaseSelectTeamWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Pet")
local var_0_3 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.warCamp_ = xyd.ModelManager.get():loadModel(xyd.ModelType.WAR_CAMP)
	arg_1_0.selectType = arg_1_2.select_type
	arg_1_0.cityId = arg_1_2.city_id
	arg_1_0.teamID = arg_1_2.team_id
	arg_1_0.preHeroIDs_ = arg_1_2.pre_heros or {}
	arg_1_0.prePetID = arg_1_2.pre_pet_id
end

function var_0_0.startBattle(arg_2_0)
	if next(arg_2_0.team_) == nil then
		return
	end

	if arg_2_0.selectType == xyd.WarCampSelectTeamType.NEW_TEAM then
		arg_2_0:saveNewTeam()
	elseif arg_2_0.selectType == xyd.WarCampSelectTeamType.CHANGE then
		arg_2_0:changeTeam()
	end
end

function var_0_0.saveNewTeam(arg_3_0)
	local var_3_0, var_3_1 = arg_3_0:getFormationStr(arg_3_0.select_)

	if not var_3_1 then
		local var_3_2 = var_0_3:translation("WAR_CAMP_SELECT_TIPS3")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_3_2
		})

		return
	end

	local var_3_3 = 0

	if arg_3_0.petSelect_[1] then
		var_3_3 = arg_3_0.petSelect_[1]:getPetID()
	end

	local var_3_4 = {
		map_id = arg_3_0.cityId,
		team_str = var_3_0,
		pet_id = var_3_3
	}

	arg_3_0.warCamp_:createNewTeam(var_3_4, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			local var_4_0 = xyd.WindowManager.get():getWindow("war_camp_team")

			if var_4_0 then
				var_4_0:refreshTeam()
			end

			arg_3_0.warCamp_.baseInfo.defense_wins[arg_3_0.cityId] = 0

			xyd.WindowManager.get():closeWindow(arg_3_0)
		end

		arg_3_0.battleBegan = false
	end)
end

function var_0_0.changeTeam(arg_5_0)
	local var_5_0, var_5_1 = arg_5_0:getFormationStr(arg_5_0.select_)

	if not var_5_1 then
		local var_5_2 = var_0_3:translation("WAR_CAMP_SELECT_TIPS3")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_5_2
		})

		return
	end

	local var_5_3 = 0

	if arg_5_0.petSelect_[1] then
		var_5_3 = arg_5_0.petSelect_[1]:getPetID()
	end

	local var_5_4 = {
		team_id = arg_5_0.teamID,
		team_str = var_5_0,
		pet_id = var_5_3
	}

	arg_5_0.warCamp_:modifyTeam(var_5_4, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			local var_6_0 = xyd.WindowManager.get():getWindow("war_camp_team")

			if var_6_0 then
				var_6_0:refreshTeam()
			end

			arg_5_0.warCamp_.baseInfo.defense_wins[arg_5_0.cityId] = 0

			xyd.WindowManager.get():closeWindow(arg_5_0)
		end

		arg_5_0.battleBegan = false
	end)
end

function var_0_0.canHeroJoinBattle(arg_7_0, arg_7_1)
	return true
end

function var_0_0.loadPreFormation(arg_8_0)
	if arg_8_0.preHeroIDs_ and next(arg_8_0.preHeroIDs_) then
		for iter_8_0 = 1, #arg_8_0.preHeroIDs_ do
			local var_8_0 = arg_8_0.selfPlayer:getHeroByID(arg_8_0.preHeroIDs_[iter_8_0])

			table.insert(arg_8_0.preHeros_, var_8_0)
		end
	end

	if arg_8_0.prePetID and arg_8_0.prePetID > 0 then
		local var_8_1 = arg_8_0.selfPlayer:getPetByID(arg_8_0.prePetID)

		table.insert(arg_8_0.prePet_, var_8_1)
	end
end

function var_0_0.getHeros(arg_9_0)
	local var_9_0 = {}

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.selfPlayer.heros_) do
		local var_9_1 = var_0_1.new()

		var_9_1:populate(iter_9_1:toParams())
		table.insert(var_9_0, var_9_1)
	end

	local var_9_2 = {}

	for iter_9_2, iter_9_3 in ipairs(arg_9_0.preHeros_) do
		local var_9_3 = var_0_1.new()

		var_9_3:populate(iter_9_3:toParams())
		table.insert(var_9_2, var_9_3)
	end

	arg_9_0.warCamp_:updateHeros(var_9_0)
	arg_9_0.warCamp_:updateHeros(var_9_2)

	arg_9_0.preHeros_ = var_9_2

	return var_9_0
end

function var_0_0.checkCanLoadPreFormation(arg_10_0)
	return true
end

function var_0_0.getPets(arg_11_0)
	local var_11_0 = {}

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.selfPlayer.collectedPets) do
		local var_11_1 = var_0_2.new()

		var_11_1:populate(iter_11_1:toParams())
		table.insert(var_11_0, var_11_1)
	end

	local var_11_2 = {}

	for iter_11_2, iter_11_3 in ipairs(arg_11_0.prePet_) do
		local var_11_3 = var_0_2.new()

		var_11_3:populate(iter_11_3:toParams())
		table.insert(var_11_2, var_11_3)
	end

	arg_11_0.warCamp_:updatePets(var_11_0)
	arg_11_0.warCamp_:updatePets(var_11_2)

	arg_11_0.prePet_ = var_11_2

	return var_11_0
end

function var_0_0.beforeClickAvatar(arg_12_0, arg_12_1)
	if arg_12_0.warCamp_:checkHeroIsSelect(arg_12_1.data, arg_12_0.teamID) then
		local var_12_0 = string.format(var_0_3:translation("WAR_CAMP_SELECT_TIPS1"), arg_12_1.data:getName())

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_12_0, function()
			var_0_0.super.beforeClickAvatar(arg_12_0, arg_12_1)
		end, nil, nil, arg_12_0.colorMode)
	else
		var_0_0.super.beforeClickAvatar(arg_12_0, arg_12_1)
	end
end

function var_0_0.beforeClickPetAvatar(arg_14_0, arg_14_1, arg_14_2)
	if arg_14_0.warCamp_:checkPetIsSelect(arg_14_2, arg_14_0.teamID) then
		local var_14_0 = string.format(var_0_3:translation("WAR_CAMP_SELECT_TIPS1"), arg_14_2:getName())

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_14_0, function()
			var_0_0.super.beforeClickPetAvatar(arg_14_0, arg_14_1, arg_14_2)
		end, nil, nil, arg_14_0.colorMode)
	else
		var_0_0.super.beforeClickPetAvatar(arg_14_0, arg_14_1, arg_14_2)
	end
end

function var_0_0.getListStatus(arg_16_0, arg_16_1, arg_16_2)
	return (arg_16_0.warCamp_:getHeroStatusByID(arg_16_2:getHeroID()))
end

function var_0_0.showHpBarIgnoreHealth(arg_17_0)
	return true
end

function var_0_0.updatePresetTeams(arg_18_0, arg_18_1)
	for iter_18_0 = 1, #arg_18_1 do
		local var_18_0 = arg_18_1[iter_18_0].team

		arg_18_0.warCamp_:updateHeros(var_18_0)
	end

	return arg_18_1
end

function var_0_0.updateHeroMask(arg_19_0, arg_19_1, arg_19_2, arg_19_3, arg_19_4)
	var_0_0.super.updateHeroMask(arg_19_0, arg_19_1, arg_19_2, arg_19_3, arg_19_4)

	local var_19_0 = arg_19_2:getChildByName("chosen")
	local var_19_1 = arg_19_2:getChildByName("avatar_mask")

	if arg_19_0.warCamp_:checkHeroIsSelect(arg_19_3) then
		var_19_0:setVisible(true)
		var_19_1:setVisible(true)
	end
end

function var_0_0.updatePetCellMask(arg_20_0, arg_20_1, arg_20_2)
	var_0_0.super.updatePetCellMask(arg_20_0, arg_20_1, arg_20_2)

	local var_20_0

	if arg_20_0.rentMenuType == xyd.RentMenuType.RENT_PET then
		var_20_0 = arg_20_1:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
	else
		var_20_0 = arg_20_1:getChildByName("layout")
	end

	local var_20_1 = var_20_0:getChildByName("avatar_mask")
	local var_20_2 = var_20_0:getChildByName("chosen")

	if arg_20_0.warCamp_:checkPetIsSelect(arg_20_2) then
		var_20_1:setVisible(true)
		var_20_2:setVisible(true)
	end
end

function var_0_0.getBattleBtn(arg_21_0)
	if not arg_21_0.battleBtn_ then
		arg_21_0.battleBtn_ = arg_21_0:nodeByName("button_ok")

		arg_21_0.battleBtn_:addTouchEventListener(function(arg_22_0, arg_22_1)
			if not arg_21_0:checkCanStartBattle() then
				return
			end

			if arg_22_1 == ccui.TouchEventType.ended and not arg_21_0.battleBegan then
				xyd.playButtonSound()

				if xyd.WindowManager.get():isWindowOpen("guide") then
					xyd.WindowManager.get():closeWindow("guide")
				end

				arg_21_0:beforeStartBattle()
			end
		end)
		arg_21_0.battleBtn_:setVisible(true)
		arg_21_0:nodeByName("button_battle"):setVisible(false)
	end

	return arg_21_0.battleBtn_
end

function var_0_0.checkCanPresetTeam(arg_23_0)
	return false
end

function var_0_0.getFormationStr(arg_24_0, arg_24_1)
	local var_24_0 = ""
	local var_24_1 = {}
	local var_24_2 = true

	if #arg_24_1 > xyd.MAX_TEAM_MEMBER_NUM then
		var_24_2 = false

		return var_24_0, var_24_2
	end

	for iter_24_0, iter_24_1 in ipairs(arg_24_1) do
		if var_24_1[iter_24_1:getHeroID()] then
			var_24_2 = false

			break
		end

		var_24_1[iter_24_1:getHeroID()] = true
		var_24_0 = var_24_0 .. string.format("%d", iter_24_1:getHeroID())

		if iter_24_0 < #arg_24_1 then
			var_24_0 = var_24_0 .. "|"
		end
	end

	return var_24_0, var_24_2
end

return var_0_0
