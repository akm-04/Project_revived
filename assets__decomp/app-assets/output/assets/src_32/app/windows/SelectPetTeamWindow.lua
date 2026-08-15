local var_0_0 = class("SelectPetTeamWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Item")
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = xyd.tables.translation
local var_0_5 = "skeletons/ui_effect/cloudcity_select_effect/cloudcity_select_effect"
local var_0_6 = 5
local var_0_7 = 4
local var_0_8 = 10
local var_0_9 = 150
local var_0_10 = xyd.tables.hero
local var_0_11 = xyd.tables.battle
local var_0_12 = {
	RENT_PET = 2,
	SELF_PET = 1
}
local var_0_13 = {
	STEP_TWO = 2,
	STEP_ONE = 1,
	STEP_THREE = 3
}
local var_0_14 = 20010276

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.campaignID = arg_1_2.campaignID
	arg_1_0.campaignType = arg_1_2.campaignType
	arg_1_0.star = arg_1_2.star
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.allTeamPets = arg_1_2.allTeamPets
	arg_1_0.petTeam = {}
	arg_1_0.petSelect = {}
	arg_1_0.selectedIndex = 0
	arg_1_0.isSelectMerPet = false
	arg_1_0.selectMerPet = nil
	arg_1_0.addBuffHeros = {}
	arg_1_0.guideStatus = false
	arg_1_0.prePets = {}
	arg_1_0.task = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)
	arg_1_0.collectedPets = arg_1_0.player.collectedPets or {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:loadPreFormation()
	arg_2_0:layout()
	arg_2_0:initHero()
	arg_2_0:initAllTeamPets()
	arg_2_0:initPrePets()
	arg_2_0:initPets()
	arg_2_0:initBottomCell()
	arg_2_0:initGuidePos()
	arg_2_0:initListview()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0.petList:reload()
	arg_3_0:playGuide()
end

function var_0_0.initListview(arg_4_0)
	local var_4_0 = arg_4_0:nodeByName("pet_container")
	local var_4_1 = var_4_0:getContentSize().width
	local var_4_2 = var_4_0:getContentSize().height

	arg_4_0.petList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_1, var_4_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_4_0)
	arg_4_0.petCells = {}

	arg_4_0.petList:setDelegate(handler(arg_4_0, arg_4_0.delegate))
end

function var_0_0.loadPreFormation(arg_5_0)
	local var_5_0 = (xyd.db.formation:getFormationData(arg_5_0.campaignType) or {})[1] or {}
	local var_5_1 = {}

	if #var_5_0 > xyd.MAX_TEAM_MEMBER_NUM then
		return
	end

	for iter_5_0, iter_5_1 in pairs(var_5_0) do
		if iter_5_1 ~= 0 and not var_5_1[iter_5_1] then
			for iter_5_2, iter_5_3 in pairs(arg_5_0.collectedPets) do
				if iter_5_3:getTableID() == iter_5_1 then
					table.insert(arg_5_0.prePets, iter_5_3)

					var_5_1[iter_5_1] = true

					break
				end
			end
		else
			table.insert(arg_5_0.prePets, 0)
		end
	end
end

function var_0_0.initPrePets(arg_6_0)
	for iter_6_0, iter_6_1 in pairs(arg_6_0.prePets) do
		if iter_6_1 ~= 0 then
			local var_6_0 = arg_6_0:initPetBottomCell(iter_6_1)

			arg_6_0.selectedIndex = iter_6_0
			var_6_0.bottomIndex = arg_6_0.selectedIndex

			local var_6_1, var_6_2 = arg_6_0:nodeByName("pet_bg_" .. arg_6_0.selectedIndex):getPosition()

			var_6_0:pos(var_6_1, var_6_2)
			var_6_0:addTo(arg_6_0)
			var_6_0:setTouchEnabled(true)
			var_6_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
				if arg_7_0.name == "ended" then
					arg_6_0:clickPetBottomAvatar(var_6_0)
				end

				return true
			end)
			arg_6_0:getPetTeamNo(arg_6_0.selectedIndex, var_6_0)
			arg_6_0:updateTopHero(arg_6_0.selectedIndex, iter_6_1, var_0_12.SELF_PET)
		end
	end

	arg_6_0:updateScore()
end

function var_0_0.layout(arg_8_0)
	arg_8_0:nodeByName("text_tips"):setString(var_0_4:translation("CLOUD_TIPS_2"))
	arg_8_0:nodeByName("btn_pet"):setBrightStyle(ccui.BrightStyle.highlight)
	arg_8_0:nodeByName("btn_rent"):setBrightStyle(ccui.BrightStyle.normal)

	arg_8_0.leftMenuType = var_0_12.SELF_PET

	arg_8_0:nodeByName("btn_pet"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_8_0:nodeByName("btn_pet"):setBrightStyle(ccui.BrightStyle.highlight)
			arg_8_0:nodeByName("btn_rent"):setBrightStyle(ccui.BrightStyle.normal)

			arg_8_0.leftMenuType = var_0_12.SELF_PET

			arg_8_0.petList:reload()
		end
	end)
	arg_8_0:nodeByName("btn_rent"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_8_0:nodeByName("btn_pet"):setBrightStyle(ccui.BrightStyle.normal)
			arg_8_0:nodeByName("btn_rent"):setBrightStyle(ccui.BrightStyle.highlight)

			arg_8_0.leftMenuType = var_0_12.RENT_PET

			arg_8_0.petList:reload()
		end
	end)
	arg_8_0:nodeByName("btn_battle"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_8_0.selectMerPet and arg_8_0.selectMerPet.can_rent then
				local var_11_0 = {
					hero = arg_8_0.selectMerPet
				}

				var_11_0.window = "select_pet_team"
				var_11_0.type = xyd.ConfirmRent.PET

				xyd.WindowManager.get():openWindow("confirm_rent", var_11_0)
			elseif #arg_8_0.petTeam < xyd.MAX_TEAM_MEMBER_NUM then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_4:translation("CLOUD_TIPS_3"), function()
					arg_8_0:startBattle()
				end, nil, nil, arg_8_0.colorMode)
			elseif arg_8_0.isPetAwakeCampaign and not arg_8_0:isAwakenPetInTeam() then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_4:translation("NO_TARGET_PET"), function()
					arg_8_0:startBattle()
				end, nil, nil, arg_8_0.colorMode)
			else
				arg_8_0:startBattle()
			end
		end
	end)
	arg_8_0:nodeByName("btn_tips"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("cloud_pet_tips")
		end
	end)
	arg_8_0:petAwakeMissionInit()
end

function var_0_0.isAwakenPetInTeam(arg_15_0)
	for iter_15_0, iter_15_1 in ipairs(arg_15_0.petTeam) do
		if arg_15_0.awakePet and arg_15_0.awakePet == iter_15_1.data then
			return true
		end
	end

	return false
end

function var_0_0.initHero(arg_16_0)
	local var_16_0 = xyd.tables.campaign:selfTeams(arg_16_0.campaignID)

	arg_16_0.heros = {}

	for iter_16_0 = 1, #var_16_0 do
		local var_16_1 = var_0_1.new()

		var_16_1:populateWithTableID(var_16_0[iter_16_0])
		table.insert(arg_16_0.heros, var_16_1)
	end

	for iter_16_1, iter_16_2 in pairs(arg_16_0.heros) do
		arg_16_0:updateTopHero(iter_16_1)
	end
end

function var_0_0.initGuidePos(arg_17_0)
	arg_17_0.guideEndNode = display.newNode()

	local var_17_0 = arg_17_0:nodeByName("hero_1")
	local var_17_1 = var_17_0:getContentSize().width
	local var_17_2 = var_17_0:getContentSize().height

	arg_17_0.guideEndNode:setContentSize(var_17_1, var_17_2)

	local var_17_3 = var_17_0:getParent():convertToWorldSpace(cc.p(var_17_0:getPositionX(), var_17_0:getPositionY()))

	arg_17_0.guideEndNode:setPosition(cc.p(var_17_3))
	arg_17_0.guideEndNode:setTouchEnabled(true)
	arg_17_0.guideEndNode:addTo(arg_17_0)
	arg_17_0.guideEndNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_18_0)
		if arg_18_0.name == "began" then
			return true
		elseif arg_18_0.name == "ended" and xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_CLOUD_CITY_ONE and arg_17_0.nextGuideStep == var_0_13.STEP_THREE then
			arg_17_0:playGuide(var_0_13.STEP_THREE)
		end
	end)
end

function var_0_0.updateTopHero(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	local var_19_0 = arg_19_0.heros[arg_19_1]

	arg_19_0:nodeByName("hero_" .. arg_19_1):removeAllChildren()

	local var_19_1 = true
	local var_19_2 = var_19_0:getTableID()

	if arg_19_3 then
		var_19_0.cell_type = arg_19_3
	else
		var_19_0.cell_type = var_0_12.SELF_PET
	end

	if not arg_19_2 then
		if var_19_0:beforeAwakenID() > 0 then
			var_19_2 = var_19_0:beforeAwakenID()
		end

		var_19_0:populateWithTableID(var_19_2)
		xyd.justSetAvatar(var_19_0, arg_19_0:nodeByName("hero_" .. arg_19_1))
		var_19_0:setIsPet(false)
		var_19_0:setAttrMD5(nil)
		var_19_0:setTotalAttrs(nil)
	else
		if arg_19_2:isAwaken() and var_19_0:afterAwakenID() > 0 then
			var_19_0:populateWithTableID(var_19_0:afterAwakenID())
		end

		if arg_19_0.isPetAwakeCampaign and arg_19_2 == arg_19_0.awakePet then
			arg_19_0.awakePetHero = var_19_0
		end

		var_19_0:setStar(arg_19_2:getStar())

		var_19_0.color_ = arg_19_2:getColor()
		var_19_0.level_ = arg_19_2:getLevel()
		var_19_0.mark = true

		local var_19_3 = arg_19_2:getTableID()

		var_19_0.pet_table_id = var_19_3
		var_19_0.player_id = arg_19_2:getPlayerID()

		for iter_19_0, iter_19_1 in pairs(xyd.tables.hero:getHolyAttr(var_19_3)) do
			if arg_19_0.campaignType == xyd.tables.petHolyAttr:campaignType(iter_19_1) then
				var_19_1 = false
			end
		end

		var_19_0.skillLev_ = {}

		for iter_19_2 = xyd.SKILL_INDEX.Energy, xyd.SKILL_INDEX.TotalNum do
			local var_19_4 = arg_19_2:getSkillLevel(iter_19_2)

			if var_19_4 and var_19_4 > 0 then
				var_19_0.skillLev_[iter_19_2] = var_19_4
			else
				var_19_0.skillLev_[iter_19_2] = false
			end
		end

		arg_19_2:setupBattleAttrInfo()

		local var_19_5 = arg_19_2.totalAttrs_

		var_19_0:setupBattleAttrInfo()

		var_19_5[xyd.AttributeType.GETMP] = var_19_0.totalAttrs_[xyd.AttributeType.GETMP]

		local var_19_6 = {}

		for iter_19_3 = 1, xyd.AttributeType.TOTAL_ATTR_NUM do
			if isClient then
				var_19_6[iter_19_3] = crypto.md5(var_19_5[iter_19_3] .. xyd.tables.misc.encryptoKey)
			end
		end

		var_19_0:setIsPet(true)
		var_19_0:setAttrMD5(var_19_6)
		var_19_0:setTotalAttrs(var_19_5)
		arg_19_0:nodeByName("hero_" .. arg_19_1):removeAllChildren()
		xyd.setAvatarBorderWithLevelAndHp(var_19_0, arg_19_0:nodeByName("hero_" .. arg_19_1), var_19_0:getColor(), var_19_0:getStar(), var_19_0:getLevel())
	end

	arg_19_0.addBuffHeros[var_19_2] = var_19_1
end

function var_0_0.initAllTeamPets(arg_20_0)
	arg_20_0:sortPets(arg_20_0.allTeamPets)
end

function var_0_0.initPets(arg_21_0)
	arg_21_0.pets = {}

	for iter_21_0, iter_21_1 in ipairs(arg_21_0.collectedPets) do
		if iter_21_1.is_show_ == 1 then
			table.insert(arg_21_0.pets, iter_21_1)
		end
	end

	arg_21_0:sortPets(arg_21_0.pets)
end

function var_0_0.sortPets(arg_22_0, arg_22_1)
	table.sort(arg_22_1, function(arg_23_0, arg_23_1)
		return xyd.petNormalSort(arg_23_0, arg_23_1) or false
	end)
end

function var_0_0.initBottomCell(arg_24_0)
	for iter_24_0 = 1, 5 do
		arg_24_0:nodeByName("pet_bg_" .. iter_24_0):setTouchEnabled(true)
		arg_24_0:nodeByName("pet_bg_" .. iter_24_0):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_25_0)
			if arg_25_0.name == "began" then
				return true
			elseif arg_25_0.name == "ended" and not arg_24_0.isAnimated then
				arg_24_0.selectedIndex = iter_24_0

				arg_24_0:showBottomSelectEffect(arg_24_0:nodeByName("pet_bg_" .. iter_24_0))

				if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_CLOUD_CITY_ONE and arg_24_0.nextGuideStep == var_0_13.STEP_ONE then
					arg_24_0:playGuide(var_0_13.STEP_ONE)
				end
			end
		end)
	end

	arg_24_0:showBottomSelectEffect(arg_24_0:nodeByName("pet_bg_1"))

	arg_24_0.selectedIndex = 1
end

function var_0_0.updateBottomSelected(arg_26_0)
	for iter_26_0, iter_26_1 in pairs(arg_26_0.heros) do
		if not iter_26_1.mark then
			arg_26_0:showBottomSelectEffect(arg_26_0:nodeByName("pet_bg_" .. iter_26_0))

			arg_26_0.selectedIndex = iter_26_0

			break
		end
	end
end

function var_0_0.showBottomSelectEffect(arg_27_0, arg_27_1)
	if not arg_27_0.bottomSelectEffect then
		local var_27_0 = var_0_5 .. ".json"
		local var_27_1 = var_0_5 .. ".atlas"

		arg_27_0.bottomSelectEffect = var_0_3.new(var_27_0, var_27_1, 1)

		arg_27_0.bottomSelectEffect:addTo(arg_27_0)
		arg_27_0.bottomSelectEffect:play(nil, true)
		arg_27_0.bottomSelectEffect:setAnchorPoint(cc.p(0.5, 0.5))
	end

	local var_27_2, var_27_3 = arg_27_1:getPosition()

	arg_27_0.bottomSelectEffect:setPosition(cc.p(var_27_2, var_27_3))
end

function var_0_0.delegate(arg_28_0, ...)
	if arg_28_0.leftMenuType == var_0_12.RENT_PET then
		return arg_28_0:rentDelegate(...)
	end

	return arg_28_0:petDelegate(...)
end

function var_0_0.petDelegate(arg_29_0, arg_29_1, arg_29_2, arg_29_3)
	local var_29_0 = math.ceil(#arg_29_0.pets / var_0_6)

	if cc.ui.UIListView.COUNT_TAG == arg_29_2 then
		return var_29_0
	elseif cc.ui.UIListView.CELL_TAG == arg_29_2 then
		local var_29_1
		local var_29_2
		local var_29_3
		local var_29_4 = arg_29_0.petList:dequeueItem()

		if not var_29_4 then
			var_29_4 = arg_29_0.petList:newItem()
		else
			var_29_4:removeAllChildren()
		end

		local var_29_5 = display.newNode()

		var_29_5:setTouchSwallowEnabled(false)

		for iter_29_0 = 1, var_0_6 do
			local var_29_6 = (arg_29_3 - 1) * var_0_6 + iter_29_0

			if var_29_6 > #arg_29_0.pets then
				break
			end

			var_29_3 = display.newNode()

			arg_29_0:initPetCell(var_29_3, var_29_6)

			local var_29_7 = var_29_3:getContentSize().width
			local var_29_8 = var_29_3:getContentSize().height
			local var_29_9 = (arg_29_0.petList.viewRect_.width - var_29_7 * var_0_6) / (var_0_6 + 1)

			var_29_3:align(display.CENTER, var_29_9 * iter_29_0 + (iter_29_0 - 1) * var_29_7 + var_29_7 / 2, var_29_8 / 2)
			var_29_5:addChild(var_29_3)

			if var_29_6 == 1 then
				arg_29_0.firstCell = var_29_3
			end
		end

		var_29_5:setContentSize(cc.size(arg_29_0.petList.viewRect_.width, var_29_3:getContentSize().height))
		var_29_4:setItemSize(arg_29_0.petList.viewRect_.width, var_29_3:getContentSize().height)
		var_29_4:addContent(var_29_5)

		return var_29_4
	end
end

function var_0_0.rentDelegate(arg_30_0, arg_30_1, arg_30_2, arg_30_3)
	local var_30_0 = math.ceil(#arg_30_0.allTeamPets / var_0_7)

	if cc.ui.UIListView.COUNT_TAG == arg_30_2 then
		return var_30_0
	elseif cc.ui.UIListView.CELL_TAG == arg_30_2 then
		local var_30_1
		local var_30_2
		local var_30_3 = arg_30_0.petList:dequeueItem()

		if not var_30_3 then
			var_30_3 = arg_30_0.petList:newItem()
		else
			var_30_3:removeAllChildren()
		end

		local var_30_4 = display.newNode()

		var_30_4:setTouchSwallowEnabled(false)

		for iter_30_0 = 1, var_0_7 do
			local var_30_5 = (arg_30_3 - 1) * var_0_7 + iter_30_0

			if var_30_5 > #arg_30_0.allTeamPets then
				break
			end

			local var_30_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/cloud_city/rent_pet_avatar.csb")
			local var_30_7 = var_30_6:getChildByName("container")
			local var_30_8 = var_30_7:getChildByName("avatar")

			var_30_8.type = var_0_12.RENT_PET

			local var_30_9 = arg_30_0.allTeamPets[var_30_5]

			var_30_7:getChildByName("player_name"):setString(var_30_9.player_name)
			var_30_7:getChildByName("rent_cost"):setString(var_30_9.rent_need_mana)
			var_30_7:setAnchorPoint(cc.p(0.5, 0.5))
			xyd.setPetAvatar(var_30_8, var_30_9, 100)
			var_30_8:getChildByName("layout"):setPositionY(var_30_8:getChildByName("layout"):getPositionY() + 15)

			if not var_30_9.can_rent then
				var_30_7:getChildByName("can_not_rent"):setString(var_0_4:translation("CAN_NOT_BORROW"))
				var_30_8:getChildByName("layout"):getChildByName("chosen"):setVisible(false)
				var_30_8:getChildByName("layout"):getChildByName("avatar_mask"):setVisible(true)
			else
				var_30_7:getChildByName("can_not_rent"):setVisible(false)
			end

			var_30_8.data = arg_30_0.allTeamPets[var_30_5]

			var_30_6:setPosition(cc.p((iter_30_0 - 1) * 190 + 95, 107))
			var_30_4:addChild(var_30_6)
			var_30_6:setTouchEnabled(true)
			var_30_6:setTouchSwallowEnabled(false)
			var_30_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_31_0)
				arg_30_0:buttonHandler(nil, var_30_6, arg_31_0)

				if arg_31_0.name == "began" then
					arg_30_0.startClick_ = true
					arg_30_0.prevX_ = arg_31_0.x
					arg_30_0.prevY_ = arg_31_0.y
				elseif arg_31_0.name == "moved" then
					if math.abs(arg_31_0.y - arg_30_0.prevY_) > 5 or math.abs(arg_31_0.x - arg_30_0.prevX_) > 5 then
						arg_30_0.startClick_ = false
					end
				elseif arg_31_0.name == "ended" and arg_30_0.startClick_ and var_30_9.can_rent then
					local var_31_0 = var_30_9.rent_need_mana

					if var_31_0 and var_31_0 > arg_30_0.player.mana then
						local var_31_1 = var_0_4:translation("MERCENARY_ERROR_TIP4")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_31_1
						})

						return
					else
						arg_30_0:clickPetAvatar(var_30_8)
					end
				end

				return true
			end)

			for iter_30_1, iter_30_2 in ipairs(arg_30_0.petTeam) do
				if var_30_9 == iter_30_2.data then
					arg_30_0.petTeam[iter_30_1].iniCell_ = var_30_8
					var_30_6.teamNo_ = iter_30_1

					local var_30_10 = var_30_8:getChildByName("layout")
					local var_30_11 = var_30_10:getChildByName("avatar_mask")
					local var_30_12 = var_30_10:getChildByName("chosen")

					var_30_11:setVisible(true)
					var_30_12:setVisible(true)

					break
				end
			end
		end

		var_30_4:setContentSize(cc.size(arg_30_0.petList.viewRect_.width, 234))
		var_30_3:setItemSize(arg_30_0.petList.viewRect_.width, 234)
		var_30_3:addContent(var_30_4)

		return var_30_3
	end
end

function var_0_0.initPetCell(arg_32_0, arg_32_1, arg_32_2)
	local var_32_0 = arg_32_0.pets[arg_32_2]

	arg_32_1:align(display.CENTER):size(146, 146)
	xyd.setPetAvatar(arg_32_1, var_32_0, 100)

	arg_32_1.type = var_0_12.SELF_PET
	arg_32_1.data = var_32_0

	arg_32_1:setTouchEnabled(true)
	arg_32_1:setTouchSwallowEnabled(false)
	arg_32_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_33_0)
		arg_32_0:buttonHandler(nil, arg_32_1, arg_33_0)

		if arg_33_0.name == "began" then
			arg_32_0.startClick_ = true
			arg_32_0.prevX_ = arg_33_0.x
			arg_32_0.prevY_ = arg_33_0.y
		elseif arg_33_0.name == "moved" then
			if math.abs(arg_33_0.y - arg_32_0.prevY_) > 5 or math.abs(arg_33_0.x - arg_32_0.prevX_) > 5 then
				arg_32_0.startClick_ = false
			end
		elseif arg_33_0.name == "ended" and arg_32_0.startClick_ then
			arg_32_0:clickPetAvatar(arg_32_1)

			if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_CLOUD_CITY_ONE and arg_32_0.nextGuideStep == var_0_13.STEP_TWO then
				arg_32_0:playGuide(var_0_13.STEP_TWO)
			end
		end

		return true
	end)

	for iter_32_0, iter_32_1 in ipairs(arg_32_0.petTeam) do
		if var_32_0 == iter_32_1.data then
			arg_32_0.petTeam[iter_32_0].iniCell_ = arg_32_1
			arg_32_1.teamNo_ = iter_32_0
			arg_32_1.bottomIndex = arg_32_0.petTeam[iter_32_0].bottomIndex

			local var_32_1 = arg_32_1:getChildByName("layout")
			local var_32_2 = var_32_1:getChildByName("avatar_mask")
			local var_32_3 = var_32_1:getChildByName("chosen")

			var_32_2:setVisible(true)
			var_32_3:setVisible(true)

			break
		end
	end
end

function var_0_0.buttonHandler(arg_34_0, arg_34_1, arg_34_2, arg_34_3)
	if not arg_34_2 or not arg_34_2:getParent() then
		return
	end

	if arg_34_3.name == "ended" then
		transition.stopTarget(arg_34_2)
		arg_34_2:setScale(1)

		if arg_34_1 then
			arg_34_1(arg_34_2, eventType)
		end
	elseif arg_34_3.name == "began" then
		local var_34_0 = cc.ScaleTo:create(0.3, 0.95)

		arg_34_2:runAction(var_34_0)

		return true
	elseif arg_34_3.name == "cancled" then
		transition.stopTarget(arg_34_2)
		arg_34_2:setScale(1)
	end
end

function var_0_0.getPetTeamByIndex(arg_35_0, arg_35_1)
	for iter_35_0, iter_35_1 in pairs(arg_35_0.petTeam) do
		if iter_35_1.bottomIndex == arg_35_1 then
			return iter_35_1
		end
	end

	return false
end

function var_0_0.clickPetAvatar(arg_36_0, arg_36_1, arg_36_2)
	if arg_36_1.isAnimated_ or not arg_36_1.teamNo_ and #arg_36_0.petTeam >= xyd.MAX_TEAM_MEMBER_NUM or arg_36_0.isAnimated then
		return
	elseif arg_36_0.selectedIndex == 0 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_4:translation("CLOUD_TIPS_4")
		})

		return
	elseif not arg_36_1.teamNo_ and arg_36_0.selectedIndex > 0 and arg_36_0.heros[arg_36_0.selectedIndex].mark == true then
		local var_36_0 = arg_36_0:getPetTeamByIndex(arg_36_0.selectedIndex)

		arg_36_0:clickPetBottomAvatarWithoutAnimation(var_36_0, function()
			arg_36_0:clickPetAvatar(arg_36_1, arg_36_2)
		end)

		return
	end

	local var_36_1 = arg_36_1:getChildByName("layout")
	local var_36_2 = var_36_1:getChildByName("avatar_mask")
	local var_36_3 = var_36_1:getChildByName("chosen")
	local var_36_4 = arg_36_1:convertToWorldSpace(cc.p(0, 0))
	local var_36_5 = var_36_4.x + arg_36_1:getContentSize().width / 2
	local var_36_6 = var_36_4.y + arg_36_1:getContentSize().height / 2

	arg_36_1.isAnimated_ = true

	if arg_36_1.teamNo_ then
		local var_36_7 = arg_36_0.petTeam[arg_36_1.teamNo_]

		arg_36_0.isAnimated = true

		arg_36_0:moveFadeOutAction(var_36_5, var_36_6, var_36_7, function()
			arg_36_1.isAnimated_ = false
			arg_36_0.isAnimated = false
		end)
		var_36_2:setVisible(false)
		var_36_3:setVisible(false)

		for iter_36_0 = #arg_36_0.petTeam, arg_36_1.teamNo_ + 1, -1 do
			arg_36_0.petTeam[iter_36_0].iniCell_.teamNo_ = iter_36_0 - 1
		end

		if arg_36_1.type == var_0_12.RENT_PET then
			arg_36_0.isSelectMerPet = false
			arg_36_0.selectMerPet = nil
		end

		table.remove(arg_36_0.petTeam, arg_36_1.teamNo_)
		table.remove(arg_36_0.petSelect, arg_36_1.teamNo_)

		arg_36_0.heros[arg_36_1.bottomIndex].mark = false

		arg_36_0:updateTopHero(arg_36_1.bottomIndex)

		arg_36_1.teamNo_ = nil
		arg_36_1.bottomIndex = nil
	elseif not arg_36_1.teamNo_ and #arg_36_0.petTeam < xyd.MAX_TEAM_MEMBER_NUM then
		if arg_36_0.isSelectMerPet and arg_36_0.leftMenuType == var_0_12.RENT_PET then
			arg_36_1.isAnimated_ = false

			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_4:translation("RENT_PET_ONLY_ONE")
			})

			return
		end

		local var_36_8 = arg_36_1.data

		if not arg_36_2 and var_0_10:chosenSound(var_36_8:getTableID()) ~= "" then
			audio.playSound(var_0_10:chosenSound(var_36_8:getTableID()), false)
		end

		local var_36_9 = arg_36_0:initPetBottomCell(var_36_8)

		var_36_9.iniCell_ = arg_36_1
		var_36_9.bottomIndex = arg_36_0.selectedIndex

		var_36_9:pos(var_36_5, var_36_6)
		var_36_9:addTo(arg_36_0)
		var_36_9:setTouchEnabled(true)
		var_36_9:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_39_0)
			if arg_39_0.name == "ended" then
				arg_36_0:clickPetBottomAvatar(var_36_9)
			end

			return true
		end)

		arg_36_1.teamNo_ = arg_36_0:getPetTeamNo(arg_36_0.selectedIndex, var_36_9)
		arg_36_1.bottomIndex = arg_36_0.selectedIndex

		if arg_36_1.type == var_0_12.RENT_PET then
			arg_36_0.isSelectMerPet = true
			arg_36_0.selectMerPet = var_36_8
		end

		local var_36_10, var_36_11 = arg_36_0:nodeByName("pet_bg_" .. arg_36_0.selectedIndex):getPosition()
		local var_36_12 = arg_36_0.petTeam[arg_36_1.teamNo_]

		transition.stopTarget(var_36_12)

		var_36_9.isAnimated_ = true
		arg_36_0.isAnimated = true

		transition.moveTo(var_36_12, {
			time = 0.3,
			x = var_36_10,
			y = var_36_11,
			onComplete = function()
				arg_36_0:attrSpriteMove(var_36_8:getTableID(), arg_36_0.selectedIndex, function()
					arg_36_0:updateTopHero(arg_36_0.selectedIndex, var_36_8, arg_36_1.type)
					arg_36_0:updateBottomSelected()

					arg_36_1.isAnimated_ = false
					var_36_9.isAnimated_ = false
					arg_36_0.isAnimated = false
				end)
			end
		})
		var_36_2:setVisible(true)
		var_36_3:setVisible(true)
	end

	arg_36_0:updateScore()
end

function var_0_0.attrSpriteMove(arg_42_0, arg_42_1, arg_42_2, arg_42_3)
	local var_42_0 = xyd.tables.hero:getHolyAttr(arg_42_1)
	local var_42_1 = false
	local var_42_2 = 0

	for iter_42_0 = 1, #var_42_0 do
		if arg_42_0.campaignType == xyd.tables.petHolyAttr:campaignType(var_42_0[iter_42_0]) then
			var_42_1 = true
			var_42_2 = var_42_0[iter_42_0]

			break
		end
	end

	if var_42_1 then
		local var_42_3 = xyd.tables.petHolyAttr:icon(var_42_2)
		local var_42_4 = xyd.AssetLoader.get():loadSprite(var_42_3)
		local var_42_5, var_42_6 = arg_42_0:nodeByName("pet_bg_" .. arg_42_2):getPosition()

		var_42_4:setPosition(cc.p(var_42_5, var_42_6))
		var_42_4:addTo(arg_42_0)

		local var_42_7 = var_42_5
		local var_42_8 = var_42_6 + 50

		transition.moveTo(var_42_4, {
			time = 0.3,
			x = var_42_7,
			y = var_42_8,
			onComplete = function()
				if var_42_4 and not tolua.isnull(var_42_4) then
					var_42_4:removeSelf()
				end

				if arg_42_3 then
					arg_42_3()
				end
			end
		})
	elseif arg_42_3 then
		arg_42_3()
	end
end

function var_0_0.getPetTeamNo(arg_44_0, arg_44_1, arg_44_2)
	table.insert(arg_44_0.petTeam, arg_44_2)
	table.insert(arg_44_0.petSelect, arg_44_2.data)

	return #arg_44_0.petTeam
end

function var_0_0.updateScore(arg_45_0)
	local var_45_0 = 0
	local var_45_1 = 0

	for iter_45_0, iter_45_1 in ipairs(arg_45_0.petTeam) do
		var_45_0 = var_45_0 + iter_45_1.data:getZhandouli()
	end

	arg_45_0:nodeByName("text_zhandouli"):setString(var_45_0)
end

function var_0_0.widgetSet(arg_46_0, arg_46_1)
	for iter_46_0, iter_46_1 in ipairs(arg_46_1:getChildren()) do
		if iter_46_1 ~= nil then
			iter_46_1:setCascadeOpacityEnabled(true)
			arg_46_0:widgetSet(iter_46_1)
		end
	end
end

function var_0_0.moveFadeOutAction(arg_47_0, arg_47_1, arg_47_2, arg_47_3, arg_47_4)
	arg_47_0:widgetSet(arg_47_3)
	arg_47_3:setCascadeOpacityEnabled(true)

	local var_47_0 = cc.Spawn:create(cc.FadeOut:create(0.4), cc.MoveTo:create(0.5, cc.p(arg_47_1, arg_47_2)))

	arg_47_3:runActionOnce(var_47_0, true, arg_47_4)
end

function var_0_0.initPetBottomCell(arg_48_0, arg_48_1)
	local var_48_0 = display.newNode()

	var_48_0:size(146, 146)
	var_48_0:align(display.CENTER)

	var_48_0.data = arg_48_1

	xyd.setPetAvatar(var_48_0, arg_48_1, 100)

	if arg_48_0.leftMenuType == var_0_12.RENT_PET then
		local var_48_1 = xyd.AssetLoader.get():loadSprite("windows/cloud_city/yongbing_tubiao.png")

		var_48_1:setPosition(cc.p(120, 120))
		var_48_0:addChild(var_48_1)

		var_48_0.type = var_0_12.RENT_PET
	else
		var_48_0.type = var_0_12.SELF_PET
	end

	return var_48_0
end

function var_0_0.clickPetBottomAvatar(arg_49_0, arg_49_1)
	if arg_49_1.isAnimated_ or arg_49_0.isAnimated then
		return
	end

	local var_49_0, var_49_1 = arg_49_0:nodeByName("pet_container"):getPosition()
	local var_49_2 = arg_49_1.iniCell_
	local var_49_3
	local var_49_4 = arg_49_1.bottomIndex

	for iter_49_0, iter_49_1 in ipairs(arg_49_0.petSelect) do
		if iter_49_1:getTableID() == arg_49_1.data:getTableID() and iter_49_1.player_name == arg_49_1.data.player_name then
			var_49_3 = iter_49_0

			break
		end
	end

	if not var_49_3 then
		return
	end

	if var_49_2 and not tolua.isnull(var_49_2) then
		local var_49_5 = var_49_2:convertToWorldSpace(cc.p(0, 0))

		var_49_0, var_49_1 = var_49_5.x, var_49_5.y

		local var_49_6 = var_49_2:getChildByName("layout")
		local var_49_7 = var_49_6:getChildByName("avatar_mask")
		local var_49_8 = var_49_6:getChildByName("chosen")

		var_49_7:setVisible(false)
		var_49_8:setVisible(false)
	end

	arg_49_0.isAnimated = true

	arg_49_0:moveFadeOutAction(var_49_0, var_49_1, arg_49_1, function()
		arg_49_0.isAnimated = false
	end)

	for iter_49_2 = #arg_49_0.petTeam, var_49_3 + 1, -1 do
		if arg_49_0.petTeam[iter_49_2].iniCell_ then
			arg_49_0.petTeam[iter_49_2].iniCell_.teamNo_ = iter_49_2 - 1
		end
	end

	if arg_49_1.type == var_0_12.RENT_PET then
		arg_49_0.isSelectMerPet = false
		arg_49_0.selectMerPet = nil
	end

	table.remove(arg_49_0.petTeam, var_49_3)
	table.remove(arg_49_0.petSelect, var_49_3)

	if var_49_4 then
		arg_49_0.heros[var_49_4].mark = false

		arg_49_0:updateTopHero(var_49_4)
		arg_49_0:showBottomSelectEffect(arg_49_0:nodeByName("pet_bg_" .. var_49_4))

		arg_49_0.selectedIndex = var_49_4
	end

	if var_49_2 then
		var_49_2.teamNo_ = nil
	end

	arg_49_0:updateScore()
end

function var_0_0.clickPetBottomAvatarWithoutAnimation(arg_51_0, arg_51_1, arg_51_2)
	if arg_51_1.isAnimated_ then
		return
	end

	local var_51_0, var_51_1 = arg_51_0:nodeByName("pet_container"):getPosition()
	local var_51_2 = arg_51_1.iniCell_
	local var_51_3
	local var_51_4 = arg_51_1.bottomIndex

	for iter_51_0, iter_51_1 in ipairs(arg_51_0.petTeam) do
		if iter_51_1 == arg_51_1 then
			var_51_3 = iter_51_0

			break
		end
	end

	if not var_51_3 then
		return
	end

	if var_51_2 and not tolua.isnull(var_51_2) then
		local var_51_5 = var_51_2:convertToWorldSpace(cc.p(0, 0))
		local var_51_6 = var_51_2:getChildByName("layout")
		local var_51_7 = var_51_6:getChildByName("avatar_mask")
		local var_51_8 = var_51_6:getChildByName("chosen")

		var_51_7:setVisible(false)
		var_51_8:setVisible(false)
	end

	for iter_51_2 = #arg_51_0.petTeam, var_51_3 + 1, -1 do
		if arg_51_0.petTeam[iter_51_2].iniCell_ then
			arg_51_0.petTeam[iter_51_2].iniCell_.teamNo_ = iter_51_2 - 1
		end
	end

	if arg_51_1.type == var_0_12.RENT_PET then
		arg_51_0.isSelectMerPet = false
		arg_51_0.selectMerPet = nil
	end

	table.remove(arg_51_0.petTeam, var_51_3)
	table.remove(arg_51_0.petSelect, var_51_3)

	if var_51_4 then
		arg_51_0.heros[var_51_4].mark = false

		arg_51_0:updateTopHero(var_51_4)
	end

	if var_51_2 then
		var_51_2.teamNo_ = nil
	end

	if arg_51_1 and not tolua.isnull(arg_51_1) then
		arg_51_1:removeSelf()
	end

	if arg_51_2 then
		arg_51_2()
	end
end

function var_0_0.startBattle(arg_52_0)
	if #arg_52_0.petTeam <= xyd.MAX_TEAM_MEMBER_NUM then
		arg_52_0:recordFormation()
		arg_52_0:startCampaignBattle()
	end
end

function var_0_0.recordFormation(arg_53_0)
	local var_53_0 = arg_53_0.campaignType
	local var_53_1 = {}
	local var_53_2 = ""
	local var_53_3 = 0

	if arg_53_0.isSelectMerPet then
		var_53_3 = arg_53_0.selectMerPet.player_id
	end

	for iter_53_0, iter_53_1 in pairs(arg_53_0.heros) do
		if iter_53_1.mark and iter_53_1.cell_type == var_0_12.SELF_PET and iter_53_1.player_id ~= var_53_3 then
			var_53_2 = var_53_2 .. string.format("%d|", iter_53_1.pet_table_id)
		else
			var_53_2 = var_53_2 .. "0|"
		end
	end

	print(var_53_2)
	xyd.db.formation:setFormationData(var_53_0, var_53_2)
end

function var_0_0.startCampaignBattle(arg_54_0)
	local var_54_0 = false
	local var_54_1 = {
		herosA = {}
	}

	table.sort(arg_54_0.heros, function(arg_55_0, arg_55_1)
		if arg_55_0:getDistance() ~= arg_55_1:getDistance() then
			return arg_55_0:getDistance() < arg_55_1:getDistance()
		end
	end)

	for iter_54_0, iter_54_1 in ipairs(arg_54_0.heros) do
		table.insert(var_54_1.herosA, iter_54_1)
	end

	if arg_54_0.isSelectMerPet then
		var_54_0 = true
	end

	var_54_1.rentFlag = var_54_0
	var_54_1.campaignType = arg_54_0.campaignType
	var_54_1.campaignID = arg_54_0.campaignID
	var_54_1.itemComposeID = nil
	var_54_1.battleID = xyd.tables.campaign:fightID(arg_54_0.campaignID)

	local var_54_2 = {}

	if xyd.StoryData.get():getStoryID() <= var_54_1.battleID then
		local var_54_3 = var_0_11:storyHeroes(var_54_1.battleID)

		for iter_54_2, iter_54_3 in ipairs(var_54_3) do
			local var_54_4 = 0

			for iter_54_4, iter_54_5 in ipairs(var_54_1.herosA) do
				if iter_54_5:getTableID() == iter_54_3 then
					var_54_4 = iter_54_2

					break
				end
			end

			if var_54_4 > 0 then
				local var_54_5 = var_0_11:specialBefore(var_54_1.battleID)[var_54_4] or 0
				local var_54_6 = var_0_11:specialLose(var_54_1.battleID)[var_54_4] or 0
				local var_54_7 = var_0_11:specialVictory(var_54_1.battleID)[var_54_4] or 0

				var_54_2 = {
					var_54_5,
					var_54_6,
					var_54_7
				}

				break
			end
		end

		if next(var_54_2) == nil then
			local var_54_8 = var_0_11:storyBefore(var_54_1.battleID)
			local var_54_9 = var_0_11:storyLose(var_54_1.battleID)
			local var_54_10 = var_0_11:storyVictory(var_54_1.battleID)

			var_54_2 = {
				var_54_8,
				var_54_9,
				var_54_10
			}
		end

		if xyd.StoryData.get():getStoryID() == var_54_1.battleID then
			if xyd.StoryData.get():getStoryState() >= 1 then
				var_54_2[1] = 0
			end

			if xyd.StoryData.get():getStoryState() >= 2 then
				var_54_2[2] = 0
			end

			if xyd.StoryData.get():getStoryState() >= 3 then
				var_54_2[3] = 0
			end
		end

		var_54_1.stories = var_54_2
	end

	if arg_54_0.player.worldMaps_[arg_54_0.campaignID] then
		var_54_1.star = arg_54_0.player.worldMaps_[arg_54_0.campaignID].star or 0
	end

	local var_54_11 = var_0_11:monsters(var_54_1.battleID)

	var_54_1.herosB = {}

	for iter_54_6 = 1, #var_54_11 do
		local var_54_12 = {}

		for iter_54_7, iter_54_8 in ipairs(var_54_11[iter_54_6]) do
			local var_54_13 = var_0_1.new()

			var_54_13:populateWithTableID(iter_54_8)
			table.insert(var_54_12, var_54_13)
		end

		if next(var_54_12) then
			table.insert(var_54_1.herosB, var_54_12)
		end
	end

	local var_54_14 = clone(var_54_1.herosA)

	if arg_54_0:isAwakenPetInTeam() then
		var_54_1.isPetAwakeCampaign = true
		var_54_1.awakePet = arg_54_0.awakePetHero
		var_54_1.awakeStage = arg_54_0.awakeStage
		var_54_1.petAwakeMissionGoalType = arg_54_0.petAwakeMissionGoalType
		var_54_1.petAwakeMissionID = arg_54_0.petAwakeMission.table_id
	else
		var_54_1.isPetAwakeCampaign = false
	end

	local var_54_15 = arg_54_0:getFormationStr(arg_54_0.petTeam)

	var_54_1.pet_formation = var_54_15

	local var_54_16 = {
		campaign_id = var_54_1.campaignID,
		campaign_type = var_54_1.campaignType,
		pet_formation = var_54_15
	}

	var_54_16.formation = ""

	if arg_54_0.isSelectMerPet then
		var_54_16.rent_pet_player_id = arg_54_0.selectMerPet.player_id
		var_54_16.rent_pet_id = tostring(arg_54_0.selectMerPet:getPetID())
	end

	xyd.Backend.get():request(xyd.mid.FIGHT, var_54_16, function(arg_56_0, arg_56_1)
		if arg_56_0 == xyd.error.OK then
			if arg_56_1.items then
				local var_56_0 = {}

				for iter_56_0, iter_56_1 in ipairs(arg_56_1.items) do
					for iter_56_2 = 1, iter_56_1.item_num do
						local var_56_1 = var_0_2.new()

						var_56_1:populate({
							table_id = iter_56_1.item_id
						})
						var_56_1:initDrop(arg_54_0.campaignID)
						table.insert(var_56_0, var_56_1)
					end
				end

				var_54_1.drops = var_56_0
			end

			local var_56_2 = clone(var_54_11)

			if arg_54_0.selectMerPet then
				arg_54_0.guild:setUseRentPet(arg_54_0.selectMerPet)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "cloud_city",
					status = {
						chapter_type = arg_54_0.campaignType,
						chapter = xyd.tables.campaign:chapter(var_54_1.campaignID)
					}
				}
			})

			var_54_1.add_buff_ids = {}
			var_54_1.addBuffHeros = arg_54_0.addBuffHeros
			var_54_1.xixueBuff = {
				var_0_14
			}

			local var_56_3 = xyd.tables.petHolyAttr:ids()

			for iter_56_3, iter_56_4 in ipairs(var_56_3) do
				if xyd.tables.petHolyAttr:campaignType(iter_56_4) == arg_54_0.campaignType then
					var_54_1.add_buff_ids = xyd.tables.petHolyAttr:addBuff(iter_56_4)

					break
				end
			end

			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_54_1)
		else
			arg_54_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.getFormationStr(arg_57_0, arg_57_1)
	local var_57_0 = ""
	local var_57_1 = #arg_57_1

	if arg_57_0.isSelectMerPet then
		var_57_1 = var_57_1 - 1
	end

	for iter_57_0, iter_57_1 in ipairs(arg_57_1) do
		local var_57_2 = iter_57_1.data

		if var_57_2 ~= arg_57_0.selectMerPet then
			var_57_0 = var_57_0 .. string.format("%d", var_57_2:getPetID())

			if iter_57_0 < var_57_1 then
				var_57_0 = var_57_0 .. "|"
			end
		end
	end

	return var_57_0
end

function var_0_0.moveCell(arg_58_0, arg_58_1, arg_58_2, arg_58_3)
	if not arg_58_0.moveCellingStatus then
		local var_58_0 = arg_58_1:getChildByName("layout")
		local var_58_1 = var_58_0:getChildByName("avatar_mask")
		local var_58_2 = var_58_0:getChildByName("chosen")
		local var_58_3 = arg_58_1:convertToWorldSpace(cc.p(0, 0))
		local var_58_4 = var_58_3.x
		local var_58_5 = var_58_3.y

		arg_58_1.isAnimated_ = true

		local var_58_6 = arg_58_1.data

		arg_58_0.moveCelling = arg_58_0:initPetBottomCell(var_58_6)
		arg_58_0.moveCelling.iniCell_ = arg_58_1

		arg_58_0.moveCelling:pos(var_58_4, var_58_5)
		arg_58_0.moveCelling:addTo(arg_58_0)
		arg_58_0.moveCelling:setTouchEnabled(true)
		var_58_1:setVisible(true)
		var_58_2:setVisible(true)

		arg_58_0.moveCellingStatus = true
	end

	arg_58_0.moveCelling.isAnimated_ = true
	arg_58_0.isAnimated = true

	arg_58_0.moveCelling:setPosition(arg_58_2, arg_58_3)
end

function var_0_0.petAwakeMissionInit(arg_59_0)
	local var_59_0 = arg_59_0.task:isHasAwakeOpen(xyd.AwakeType.PET)

	if var_59_0 then
		local var_59_1 = xyd.tables.mission:stage(var_59_0)

		if var_59_1 == 2 and xyd.getMissionGoIDs(var_59_0) == arg_59_0.campaignID then
			arg_59_0.isPetAwakeCampaign = true
			arg_59_0.petAwakeMission = arg_59_0.task:getTaskByID(var_59_0, xyd.TaskType.AWAKE)
			arg_59_0.awakeStage = var_59_1
			arg_59_0.petAwakeMissionGoalType = xyd.tables.mission:trialChallenges(var_59_0)[1]
			arg_59_0.awakePet = arg_59_0.player:getPetByTableID(xyd.tables.mission:beforeAwakenID(var_59_0))
		end
	end

	if arg_59_0.isPetAwakeCampaign then
		local var_59_2 = ""
		local var_59_3 = arg_59_0.petAwakeMission.tableID

		if arg_59_0.awakeStage == 2 then
			if arg_59_0.petAwakeMissionGoalType == xyd.AwakeStage3MissionType.SELF_KILL then
				var_59_2 = string.format(var_0_4:translation("PET_AWAKE_SELECT_TEAM_TIP" .. arg_59_0.petAwakeMissionGoalType), arg_59_0.awakePet:getName())
			elseif arg_59_0.petAwakeMissionGoalType == xyd.AwakeStage3MissionType.DAMAGE_ACHIEVE then
				var_59_2 = string.format(var_0_4:translation("PET_AWAKE_SELECT_TEAM_TIP" .. arg_59_0.petAwakeMissionGoalType), xyd.tables.mission:challengeNums(var_59_3))
			elseif arg_59_0.petAwakeMissionGoalType == xyd.AwakeStage3MissionType.ALONE_KILL then
				var_59_2 = string.format(var_0_4:translation("PET_AWAKE_SELECT_TEAM_TIP" .. arg_59_0.petAwakeMissionGoalType), arg_59_0.awakePet:getName())
			elseif arg_59_0.petAwakeMissionGoalType == xyd.AwakeStage3MissionType.ALL_ALIVE then
				var_59_2 = var_0_4:translation("PET_AWAKE_SELECT_TEAM_TIP" .. arg_59_0.petAwakeMissionGoalType)
			end
		end

		arg_59_0:nodeByName("text_tips"):setVisible(true)
		arg_59_0:nodeByName("text_tips"):setString(var_59_2)

		arg_59_0.preSelect_ = {}
		arg_59_0.preHeros_ = {}

		table.insert(arg_59_0.preSelect_, arg_59_0.awakePet:getPetID())
		table.insert(arg_59_0.preHeros_, arg_59_0.awakePet)
	end
end

function var_0_0.playGuide(arg_60_0, arg_60_1)
	local var_60_0 = 0
	local var_60_1 = 40
	local var_60_2 = false

	local function var_60_3(arg_61_0, arg_61_1, arg_61_2, arg_61_3, arg_61_4, arg_61_5)
		if not arg_60_0.guideNode then
			arg_60_0.guideNode = display.newNode()

			local var_61_0 = import("app.windows.GuideHand").new()

			arg_60_0.guideNode:addChild(var_61_0)
			arg_60_0:addChild(arg_60_0.guideNode)
			var_61_0:setPosition(0, 0)

			local var_61_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/guide_window/guide_tip.csb")

			var_61_1:addTo(arg_60_0.guideNode)
			var_61_1:setName("tipWindow")

			local var_61_2 = 10001001
			local var_61_3 = xyd.tables.skinDynamic:path(var_61_2)
			local var_61_4 = xyd.tables.misc:getValue("guide_scailing")
			local var_61_5 = xyd.tables.misc:getValue("guide_location")

			xyd.EffectLoader.new(var_61_3, 3, var_61_4, {
				x = var_61_5[1],
				y = var_61_5[2]
			}):addTo(var_61_1:getChildByName("tip_bg"):getChildByName("card_pos"))
		end

		local var_61_6 = arg_60_0.guideNode:getChildByName("tipWindow")

		var_61_6:setPosition(arg_61_3, arg_61_4)
		var_61_6:getChildByName("tip_txt"):setString(arg_61_2)

		if arg_61_5 then
			var_61_6:getChildByName("tip_bg"):setFlippedX(true)
			var_61_6:getChildByName("tip_bg"):getChildByName("guide_tip"):setFlippedX(true)
		else
			var_61_6:getChildByName("tip_bg"):setFlippedX(false)
			var_61_6:getChildByName("tip_bg"):getChildByName("guide_tip"):setFlippedX(false)
		end

		arg_60_0.guideNode:setPosition(arg_61_0, arg_61_1)
		arg_60_0.guideNode:setLocalZOrder(10)
	end

	local var_60_4 = xyd.StoryData.get():getGuideID()

	if arg_60_1 == nil then
		if var_60_4 == xyd.GuideStoryType.GUIDE_CLOUD_CITY_START then
			xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CLOUD_CITY_ONE, true)

			arg_60_0.nextGuideStep = var_0_13.STEP_ONE

			local var_60_5 = arg_60_0:nodeByName("pet_bg_1")

			if not var_60_5 then
				return
			end

			local var_60_6 = arg_60_0:convertToNodeSpace(var_60_5:getParent():convertToWorldSpace(cc.p(var_60_5:getPosition())))
			local var_60_7 = var_0_4:translation("CLOUD_CITY_GUIDE_1")
			local var_60_8 = 300
			local var_60_9 = 0
			local var_60_10 = true

			var_60_3(var_60_6.x, var_60_6.y, var_60_7, var_60_8, var_60_9, var_60_10)
		end
	elseif arg_60_1 == var_0_13.STEP_ONE then
		arg_60_0.nextGuideStep = var_0_13.STEP_TWO

		if not arg_60_0.firstCell then
			return
		end

		local var_60_11 = 300
		local var_60_12 = 0
		local var_60_13 = true
		local var_60_14 = var_0_4:translation("CLOUD_CITY_GUIDE_2")
		local var_60_15 = arg_60_0:convertToNodeSpace(arg_60_0.firstCell:getParent():convertToWorldSpace(cc.p(arg_60_0.firstCell:getPosition())))

		var_60_3(var_60_15.x, var_60_15.y, var_60_14, var_60_11, var_60_12, var_60_13)
	elseif arg_60_1 == var_0_13.STEP_TWO then
		local var_60_16 = arg_60_0.guideEndNode

		if not var_60_16 then
			return
		end

		local var_60_17 = var_60_16:getContentSize().width
		local var_60_18 = var_60_16:getContentSize().height

		arg_60_0.nextGuideStep = var_0_13.STEP_THREE

		local var_60_19 = var_0_4:translation("CLOUD_CITY_GUIDE_3")
		local var_60_20 = 300
		local var_60_21 = -100
		local var_60_22 = true
		local var_60_23 = cc.p(var_60_16:getPositionX() + var_60_17 / 2, var_60_16:getPositionY() + var_60_18 / 2)

		var_60_3(var_60_23.x, var_60_23.y, var_60_19, var_60_20, var_60_21, var_60_22)
	elseif arg_60_1 == var_0_13.STEP_THREE then
		if arg_60_0.guideNode then
			arg_60_0.guideNode:setVisible(false)
		end

		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CLOUD_CITY_END, true)
		xyd.StoryData.get():persist()
	end
end

return var_0_0
