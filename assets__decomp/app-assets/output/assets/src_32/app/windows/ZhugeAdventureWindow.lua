local var_0_0 = class("ZhugeAdventureWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = require("framework.scheduler")
local var_0_4 = 5
local var_0_5 = xyd.tables.misc
local var_0_6 = xyd.tables.zhugeEvent
local var_0_7 = import("app.model.Hero")
local var_0_8 = import("app.model.Pet")
local var_0_9 = cc.p(624.94, 312.28)
local var_0_10 = cc.p(351.19, 312.28)
local var_0_11 = {
	width = 880,
	height = 322
}
local var_0_12 = {
	x = 195,
	y = 60
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.zhugeModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)
	arg_1_0.storyEventType = nil

	if arg_1_2 and next(arg_1_2) then
		arg_1_0.storyEventType = arg_1_2.storyEventType
	end

	arg_1_0.isFirstEvent = true
	arg_1_0.isAnimation = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:initHeros()
	arg_2_0:layout()
end

function var_0_0.initHeros(arg_3_0)
	arg_3_0.teams = {}
	arg_3_0.teams = arg_3_0.zhugeModel:getCurrentHeros()
	arg_3_0.pet = arg_3_0.zhugeModel:getCurrentPet()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text_mana"):enableShadow(cc.c4b(1, 1, 1, 200), cc.size(1, -1), 1)
	arg_4_0:nodeByName("text_crystal"):enableShadow(cc.c4b(1, 1, 1, 200), cc.size(1, -1), 1)
	arg_4_0:updateCoin()
	arg_4_0:updateBottomList()
	arg_4_0:initHerosModel()
	arg_4_0:showDialog(false)
	arg_4_0:showRightBtn(false)
	arg_4_0:showBtnAvoid(false)
	arg_4_0:updateBg()
	arg_4_0:createRightArrowAction()
	arg_4_0:nodeByName("close"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended and not arg_4_0.isAnimation then
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
	arg_4_0:nodeByName("btn_change"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended and not arg_4_0.isAnimation and not arg_4_0.isComplete then
			local var_6_0 = {
				teamType = xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM
			}

			xyd.WindowManager.get():openWindow("zhuge_select_team", var_6_0)
		end
	end)
	arg_4_0:nodeByName("img_backpack"):setTouchEnabled(true)
	arg_4_0:nodeByName("img_backpack"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			return true
		elseif arg_7_0.name == "ended" and not arg_4_0.isComplete then
			xyd.WindowManager.get():openWindow("zhuge_backpack")
		end
	end)
	arg_4_0:nodeByName("right"):setTouchEnabled(true)
	arg_4_0:nodeByName("right"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "began" then
			return true
		elseif arg_8_0.name == "ended" and not arg_4_0.isAnimation then
			arg_4_0.isAnimation = true

			if arg_4_0.zhugeModel:getEventID() ~= 0 and arg_4_0.isFirstEvent and arg_4_0:checkCanGoOn() then
				arg_4_0.isFirstEvent = false
				arg_4_0.storyEventType = arg_4_0:getEventType()

				arg_4_0:playEvent(arg_4_0.storyEventType)
			else
				local var_8_0 = arg_4_0.zhugeModel:getBaseInfo()

				if var_8_0.free_times == 0 and var_8_0.status == 0 then
					local var_8_1 = var_0_5.zhugeForestCost
					local var_8_2 = string.format(var_0_1:translation("ZHUGE_FOREST_TIPS_4"), var_8_1)

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_8_2, function()
						if var_8_1 > arg_4_0.selfPlayer.crystal then
							arg_4_0.isAnimation = false

							local var_9_0 = var_0_1:translation("ZHUGE_FOREST_TIPS_5")

							xyd.WindowManager.get():openWindow("toast", {
								message = var_9_0
							})

							return
						end

						arg_4_0:getEvent()
					end, {
						lcallback = function()
							arg_4_0.isAnimation = false
						end
					}, nil, arg_4_0.colorMode)
				elseif var_8_0.free_times > 0 and var_8_0.status == 0 then
					local var_8_3 = var_0_1:translation("ZHUGE_FOREST_TIPS_41")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_8_3, function()
						arg_4_0:getEvent()
					end, {
						lcallback = function()
							arg_4_0.isAnimation = false
						end
					}, nil, arg_4_0.colorMode)
				else
					arg_4_0:getEvent()
				end
			end
		end
	end)
	arg_4_0:nodeByName("btn_avoid"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended and arg_4_0.canClick then
			arg_4_0.avoidSuccess = true

			arg_4_0.zhugeModel:avoidDamage(true, function(arg_14_0, arg_14_1)
				if arg_14_0 == xyd.error.OK then
					arg_4_0:showBtnAvoid(false)
					arg_4_0:walkToAvoidStone(function()
						arg_4_0:showTrap()
					end)
				end
			end)
		end
	end)
end

function var_0_0.getEvent(arg_16_0)
	if not arg_16_0:checkCanGoOn() then
		return
	end

	arg_16_0.zhugeModel:getEvent(function(arg_17_0, arg_17_1)
		if arg_17_0 == xyd.error.OK then
			if not arg_16_0:checkCanGoOn() then
				return
			end

			arg_16_0.storyEventType = arg_16_0:getEventType()

			arg_16_0:playEvent(arg_16_0.storyEventType)
		end
	end)
end

function var_0_0.didOpen(arg_18_0, arg_18_1)
	var_0_0.super:didOpen(arg_18_1)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_18_0):addEventListener(xyd.event.ECONOMY, handler(arg_18_0, arg_18_0.updateCoin))
	arg_18_0:playEvent(arg_18_0.storyEventType)
end

function var_0_0.updateCoin(arg_19_0)
	arg_19_0:nodeByName("text_mana"):setString(xyd.num2ThousandsStr(arg_19_0.selfPlayer.mana))
	arg_19_0:nodeByName("text_crystal"):setString(xyd.num2ThousandsStr(arg_19_0.selfPlayer.crystal))
end

function var_0_0.getEventType(arg_20_0)
	local var_20_0 = arg_20_0.zhugeModel:getEventID()

	return (var_0_6:type(var_20_0))
end

function var_0_0.updateBottomList(arg_21_0)
	for iter_21_0 = 1, var_0_4 do
		local var_21_0 = arg_21_0:nodeByName("avatar" .. iter_21_0)

		var_21_0:removeAllChildren()

		local var_21_1 = arg_21_0.teams[iter_21_0]

		if var_21_1 then
			arg_21_0:initHeroAvatar(var_21_0, var_21_1)
		end
	end

	arg_21_0:initPetBottomCell(arg_21_0:nodeByName("pet_back2"), arg_21_0.pet)
end

function var_0_0.initHeroAvatar(arg_22_0, arg_22_1, arg_22_2)
	local var_22_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar.csb")

	var_22_0:getChildByName("yongbing_tubiao"):setVisible(false)

	local var_22_1 = var_22_0:getChildByName("background"):getContentSize()

	var_22_0:setContentSize(var_22_1)
	xyd.setAvatarBorder(arg_22_2, var_22_0:getChildByName("avatar"))

	local var_22_2 = var_22_0:getChildByName("chosen")

	var_22_2:setLocalZOrder(100)
	var_22_2:setVisible(false)

	local var_22_3 = var_22_0:getChildByName("avatar_mask")

	var_22_3:setLocalZOrder(2)
	var_22_3:setVisible(false)
	var_22_0:getChildByName("is_can_rent"):setVisible(false)

	if arg_22_2.partner_type == 1 or arg_22_2.partner_type == 5 then
		var_22_0:getChildByName("yongbing_tubiao"):setVisible(true)
	else
		var_22_0:getChildByName("yongbing_tubiao"):setVisible(false)
	end

	for iter_22_0 = 1, 3 do
		var_22_0:getChildByName("team" .. iter_22_0):setVisible(false)
	end

	var_22_0:getChildByName("lv_txt"):setString(arg_22_2:getLevel())

	local var_22_4 = var_22_0:getChildByName("name_text")

	var_22_4:setString(arg_22_2:getName())
	var_22_4:enableOutline(cc.c4b(0, 0, 0, 105), 1)

	if xyd.Color2Level[arg_22_2:getColor()] ~= "" then
		local var_22_5 = {
			size = 20,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = var_22_4:getX() + var_22_4:getWidth() / 2 - 10,
			y = var_22_4:getY(),
			color = xyd.color.HERO_QUALITY[arg_22_2:getColor()],
			text = xyd.Color2Level[arg_22_2:getColor()]
		}
		local var_22_6 = xyd.AssetLoader.get():loadLabel(var_22_5)

		var_22_6:addTo(var_22_0)
		var_22_6:align(display.CENTER_LEFT)
		var_22_6:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_22_4:x(var_22_4:getX() - 15)
	end

	local var_22_7 = var_22_0:getChildByName("hp_bar")
	local var_22_8 = var_22_0:getChildByName("mp_bar")
	local var_22_9 = var_22_0:getChildByName("dead_text")

	var_22_9:setString(var_0_1:translation("ALREADY_DEAD"))

	if var_22_9 then
		var_22_9:setVisible(false)
	end

	local var_22_10 = arg_22_0.zhugeModel:getHeroStatus(arg_22_2:getTableID())

	if var_22_10 and next(var_22_10) then
		arg_22_0:updateHeroAvatar(var_22_0, arg_22_1, arg_22_2, var_22_10)
	else
		var_22_7:hide()
		var_22_8:hide()
		var_22_0:getChildByName("hp_di"):hide()
		var_22_0:getChildByName("mp_di"):hide()

		arg_22_2.isDead = false
	end

	var_22_0:setName("layout")
	var_22_0:setPosition(cc.p(0, 0))
	arg_22_1:addChild(var_22_0)
end

function var_0_0.updateHeroAvatar(arg_23_0, arg_23_1, arg_23_2, arg_23_3, arg_23_4)
	if not arg_23_4 then
		return
	end

	local var_23_0 = arg_23_1:getChildByName("hp_bar")
	local var_23_1 = arg_23_1:getChildByName("mp_bar")
	local var_23_2 = arg_23_1:getChildByName("dead_text")

	var_23_2:setVisible(false)

	local var_23_3 = arg_23_1:getChildByName("avatar_mask")

	var_23_3:setVisible(false)

	local var_23_4 = false

	arg_23_3.healthStatus = arg_23_4

	if arg_23_4 and arg_23_4.health then
		local var_23_5 = 0
		local var_23_6 = 0

		if arg_23_4.health == 0 then
			var_23_5 = 100
			var_23_6 = arg_23_4.mp / 10
		elseif arg_23_4.health == 1 and arg_23_4.hp >= 1 then
			var_23_5 = arg_23_4.hp / arg_23_4.max_hp * 100
			var_23_6 = arg_23_4.mp / 10
		else
			var_23_5 = 0
			var_23_6 = 0

			var_23_3:setVisible(true)
			var_23_2:setLocalZOrder(3)
			var_23_2:setVisible(true)
			var_23_2:enableOutline(cc.c4b(0, 0, 0), 2)
			var_23_2:getVirtualRenderer():setAdditionalKerning(-2)

			var_23_4 = true
		end

		var_23_0:setPercent(var_23_5)
		var_23_0:setVisible(true)
		var_23_1:setPercent(var_23_6)
		var_23_1:setVisible(true)
	end

	arg_23_3.isDead = var_23_4
end

function var_0_0.initPetBottomCell(arg_24_0, arg_24_1, arg_24_2)
	if not arg_24_2 or not next(arg_24_2) then
		return
	end

	arg_24_1:removeAllChildren()

	local var_24_0 = display.newNode()

	var_24_0:size(146, 146)
	var_24_0:align(display.CENTER)

	var_24_0.data = arg_24_2

	xyd.setPetAvatar(var_24_0, arg_24_2, 100)

	if arg_24_2.partner_type == 3 then
		local var_24_1 = xyd.AssetLoader.get():loadSprite("windows/cloud_city/yongbing_tubiao.png")

		var_24_1:addTo(var_24_0)
		var_24_1:setAnchorPoint(cc.p(0.5, 0.5))
		var_24_1:setPosition(cc.p(110, 120))
	end

	arg_24_1:addChild(var_24_0)

	local var_24_2 = arg_24_1:getContentSize()

	var_24_0:pos(var_24_2.width / 2, var_24_2.height / 2)
end

function var_0_0.initModelNode(arg_25_0, arg_25_1)
	if arg_25_0.herosModelNode and not tolua.isnull(arg_25_0.herosModelNode) then
		arg_25_0.herosModelNode:removeAllChildren()
	else
		local var_25_0 = arg_25_1:getContentSize()

		arg_25_0.herosModelNode = display.newNode()

		arg_25_0.herosModelNode:addTo(arg_25_1)
		arg_25_0.herosModelNode:setAnchorPoint(cc.p(0.5, 0))
	end
end

function var_0_0.initHerosModel(arg_26_0, arg_26_1)
	local var_26_0 = arg_26_0:nodeByName("detail_container")
	local var_26_1 = var_26_0:getContentSize()

	arg_26_0:initModelNode(var_26_0)

	local var_26_2 = 0

	arg_26_0.petModel = nil

	if arg_26_0.pet and next(arg_26_0.pet) then
		local var_26_3 = arg_26_0.pet:getHeroModel()

		var_26_3:setScale(0.7)
		var_26_3:addTo(arg_26_0.herosModelNode)
		var_26_3:setPosition(var_26_2, 0)

		arg_26_0.petModel = var_26_3
		var_26_2 = var_26_2 + 120
	end

	arg_26_0.herosModel = {}

	local var_26_4 = {
		0,
		-20,
		70,
		-45,
		50
	}

	for iter_26_0 = #arg_26_0.teams, 1, -1 do
		local var_26_5 = arg_26_0.teams[iter_26_0]

		if arg_26_0.zhugeModel:getHeroStatus(var_26_5:getTableID()).health ~= 2 then
			local var_26_6 = var_26_5:getHeroModel()

			var_26_6:setScale(0.7)
			var_26_6:addTo(arg_26_0.herosModelNode)
			var_26_6:setPosition(var_26_2, var_26_4[iter_26_0])

			if var_26_4[iter_26_0] < 0 then
				var_26_6:setLocalZOrder(10)
			else
				var_26_6:setLocalZOrder(5)
			end

			arg_26_0.herosModel[iter_26_0] = var_26_6
			var_26_2 = var_26_2 + 120
		end
	end

	arg_26_0.herosModelNode:setContentSize(var_26_2 - 150, var_26_1.height)

	if not arg_26_1 then
		arg_26_0.herosModelNode:setPosition(cc.p(0, 0))
	end
end

function var_0_0.playHerosModelMove(arg_27_0, arg_27_1, arg_27_2, arg_27_3)
	local var_27_0 = cc.MoveTo:create(arg_27_2, cc.p(arg_27_1))

	for iter_27_0, iter_27_1 in pairs(arg_27_0.herosModel) do
		arg_27_0:resetModelState(iter_27_1, xyd.ModelState.Walk)
	end

	if arg_27_0.petModel and not tolua.isnull(arg_27_0.petModel) then
		arg_27_0:resetModelState(arg_27_0.petModel, xyd.ModelState.Walk)
	end

	arg_27_0.herosModelNode:runActionOnce(var_27_0, false, function()
		for iter_28_0, iter_28_1 in pairs(arg_27_0.herosModel) do
			arg_27_0:resetModelState(iter_28_1, xyd.ModelState.Idle)
		end

		if arg_27_0.petModel and not tolua.isnull(arg_27_0.petModel) then
			arg_27_0:resetModelState(arg_27_0.petModel, xyd.ModelState.Idle)
		end

		if arg_27_3 then
			arg_27_3()
		end
	end)
end

function var_0_0.resetModelState(arg_29_0, arg_29_1, arg_29_2)
	local var_29_0

	var_29_0 = arg_29_2 or xyd.ModelState.Idle

	if arg_29_2 == xyd.ModelState.Walk then
		arg_29_1:walk(true)
	else
		arg_29_1:idle()
	end
end

function var_0_0.checkNeedSelect(arg_30_0)
	return false
end

function var_0_0.createSelect(arg_31_0)
	arg_31_0:showRightBtn(false)

	local var_31_0 = arg_31_0:nodeByName("detail_container"):getContentSize()

	if arg_31_0.selectNode then
		arg_31_0.selectNode:removeAllChildren()
	else
		arg_31_0.selectNode = display.newNode()

		arg_31_0.selectNode:setContentSize(445, var_31_0.height)
		arg_31_0.selectNode:addTo(arg_31_0:nodeByName("detail_container"))
		arg_31_0.selectNode:setAnchorPoint(cc.p(0.5, 0.5))
		arg_31_0.selectNode:setPosition(cc.p(var_31_0.width / 2, var_31_0.height / 2))
	end

	arg_31_0.selectNode:setVisible(true)

	local var_31_1 = var_31_0.height
	local var_31_2 = arg_31_0.zhugeModel:getEventID()
	local var_31_3 = var_0_6:branch(var_31_2)
	local var_31_4 = {
		var_0_1:translation("ZHUGE_FOREST_TIPS_33"),
		var_0_1:translation("ZHUGE_FOREST_TIPS_35")
	}

	if #var_31_3 == 3 then
		table.insert(var_31_4, 2, var_0_1:translation("ZHUGE_FOREST_TIPS_34"))
	else
		var_31_1 = var_31_0.height - 120
	end

	for iter_31_0 = 1, #var_31_3 do
		local var_31_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/zhugeliang/adventure/select_item.csb")

		var_31_5:addTo(arg_31_0.selectNode)

		local var_31_6 = var_31_5:getChildByName("container")

		var_31_1 = var_31_1 - var_31_6:getContentSize().height

		var_31_5:setPositionY(var_31_1)

		local var_31_7 = var_31_6:getChildByName("btn_select")
		local var_31_8 = var_31_4[iter_31_0]

		var_31_6:getChildByName("text"):setString(var_31_8)
		var_31_7:addTouchEventListener(function(arg_32_0, arg_32_1)
			if arg_32_1 == ccui.TouchEventType.ended then
				arg_31_0.zhugeModel:selectBranch(function(arg_33_0, arg_33_1)
					if arg_33_0 == xyd.error.OK then
						arg_31_0.storyEventType = arg_31_0:getEventType()

						arg_31_0:playEvent(arg_31_0.storyEventType)
					end
				end)
			end
		end)
	end
end

function var_0_0.showDialog(arg_34_0, arg_34_1, arg_34_2, arg_34_3)
	if not arg_34_1 then
		arg_34_0:nodeByName("dialog_bg"):setVisible(false)

		return
	end

	arg_34_0:nodeByName("dialog_bg"):setVisible(true)
	arg_34_0:nodeByName("text_dialog"):setString(arg_34_2)

	if arg_34_3 then
		arg_34_0:nodeByName("dialog_bg"):setPosition(cc.p(arg_34_3))
	end
end

function var_0_0.showRightBtn(arg_35_0, arg_35_1)
	arg_35_0:nodeByName("right"):setVisible(arg_35_1)

	if arg_35_1 then
		arg_35_0.isAnimation = false
	end
end

function var_0_0.playEvent(arg_36_0, arg_36_1)
	arg_36_0.isAnimation = true

	if not arg_36_1 then
		arg_36_0:playStartEvent()
	elseif arg_36_1 == xyd.ZhugeEventType.BRANCH then
		arg_36_0.isAnimation = false

		arg_36_0:createSelect()
	elseif arg_36_1 == xyd.ZhugeEventType.TRAP then
		arg_36_0.zhugeModel:checkAvoidDamage(function(arg_37_0, arg_37_1)
			if arg_37_0 == xyd.error.OK then
				arg_36_0:walkToNextEvent()
			end
		end)
	elseif arg_36_1 == xyd.ZhugeEventType.ENEMY then
		arg_36_0:walkToNextEvent()
	elseif arg_36_1 == xyd.ZhugeEventType.ENEMY_END then
		arg_36_0:playEnemyEndEvent()
	else
		arg_36_0.zhugeModel:startAdventure(function(arg_38_0, arg_38_1)
			if arg_38_0 == xyd.error.OK then
				arg_36_0:walkToNextEvent()
			end
		end)
	end
end

function var_0_0.playEventDetail(arg_39_0, arg_39_1)
	if arg_39_1 == xyd.ZhugeEventType.NONE_EVENT then
		arg_39_0:playNoneEvent()
	elseif arg_39_1 == xyd.ZhugeEventType.ENEMY then
		arg_39_0:playEnemyEvent()
	elseif arg_39_1 == xyd.ZhugeEventType.TRAP then
		arg_39_0:playTrapEvent()
	elseif arg_39_1 == xyd.ZhugeEventType.TREASUER then
		arg_39_0:playTreasuerEvent()
	end
end

function var_0_0.playStartEvent(arg_40_0)
	arg_40_0.herosModelNode:setPosition(cc.p(0, 0))
	arg_40_0:playHerosModelMove(cc.p(640, 0), 3, function()
		local var_41_0 = var_0_1:translation("ZHUGE_FOREST_TIPS_23")

		arg_40_0:showDialog(true, var_41_0, var_0_9)
		arg_40_0:showRightBtn(true)
	end)
end

function var_0_0.playNoneEvent(arg_42_0)
	arg_42_0.herosModelNode:setPosition(cc.p(0, 0))
	arg_42_0:playHerosModelMove(cc.p(640, 0), 2, function()
		if arg_42_0:checkCanGoOn() then
			local var_43_0 = var_0_1:translation("ZHUGE_FOREST_TIPS_24")

			arg_42_0:showDialog(true, var_43_0, var_0_9)
			arg_42_0:showRightBtn(true)
		end
	end)
end

function var_0_0.walkToNextEvent(arg_44_0)
	local var_44_0 = arg_44_0.herosModelNode:getContentSize()
	local var_44_1 = arg_44_0:nodeByName("detail_container"):getContentSize()
	local var_44_2 = var_44_0.width + var_44_1.width + 100

	if arg_44_0.selectNode then
		arg_44_0.selectNode:setVisible(false)
	end

	arg_44_0:showDialog(false)
	arg_44_0:showRightBtn(false)
	arg_44_0:showEnemy(false)
	arg_44_0:playHerosModelMove(cc.p(var_44_2, 0), 3, function()
		arg_44_0:updateBg()
		arg_44_0:playEventDetail(arg_44_0.storyEventType)
	end)
end

function var_0_0.playEnemyEvent(arg_46_0)
	arg_46_0.herosModelNode:setPosition(cc.p(0, 0))
	arg_46_0:playHerosModelMove(cc.p(540, 0), 1, function()
		local var_47_0 = var_0_1:translation("ZHUGE_FOREST_TIPS_25")

		arg_46_0:showDialog(true, var_47_0, var_0_9)
		arg_46_0:showEnemy(true)
		arg_46_0:showRightBtn(false)
		arg_46_0.zhugeModel:startAdventure(function(arg_48_0, arg_48_1)
			if arg_48_0 == xyd.error.OK then
				arg_46_0:playReport(arg_48_1.battle_report)
			end
		end)
	end)
end

function var_0_0.showEnemy(arg_49_0, arg_49_1)
	if arg_49_1 then
		arg_49_0.enemyNode = display.newNode()

		arg_49_0.enemyNode:addTo(arg_49_0:nodeByName("detail_container"))
		arg_49_0.enemyNode:setAnchorPoint(cc.p(0, 0))
		arg_49_0.enemyNode:setPosition(cc.p(1029, 0))

		local var_49_0 = arg_49_0.zhugeModel:getEventID()
		local var_49_1 = var_0_6:model(var_49_0)
		local var_49_2 = math.random(1, #var_49_1)
		local var_49_3 = var_49_1[math.floor(var_49_2)]
		local var_49_4 = xyd.HeroAnimation.new(nil, var_49_3, xyd.tables.model:uiScale(var_49_3, {}))

		var_49_4:addTo(arg_49_0.enemyNode)
		var_49_4:setScale(0.7)
		var_49_4:flipX(true)
	elseif arg_49_0.enemyNode and not tolua.isnull(arg_49_0.enemyNode) then
		arg_49_0.enemyNode:removeSelf()

		arg_49_0.enemyNode = nil
	end
end

function var_0_0.showTrap(arg_50_0)
	arg_50_0:shake()

	if not arg_50_0.avoidSuccess then
		-- block empty
	else
		local var_50_0 = var_0_1:translation("ZHUGE_FOREST_TIPS_26")

		arg_50_0:showDialog(true, var_50_0, var_0_10)
	end

	arg_50_0:showStoneEffcet(function()
		if arg_50_0.stoneEffcet then
			arg_50_0.stoneEffcet:setVisible(false)
		end

		if arg_50_0:checkCanGoOn() then
			local var_51_0 = var_0_1:translation("ZHUGE_FOREST_TIPS_27")

			arg_50_0:showDialog(true, var_51_0)
			arg_50_0:showRightBtn(true)
		end
	end)
end

function var_0_0.playTrapEvent(arg_52_0)
	arg_52_0.avoidSuccess = false

	arg_52_0.herosModelNode:setPosition(cc.p(0, 0))
	arg_52_0:playHerosModelMove(cc.p(640, 0), 2, function()
		if arg_52_0.zhugeModel:isCanAvoid() then
			local var_53_0 = var_0_1:translation("ZHUGE_FOREST_TIPS_28")

			arg_52_0:showDialog(true, var_53_0, var_0_9)
			arg_52_0:showBtnAvoid(true, function()
				arg_52_0:showTrap()
				arg_52_0:updateBottomList()
				arg_52_0:initHerosModel(true)
			end)
		else
			local var_53_1 = var_0_1:translation("ZHUGE_FOREST_TIPS_29")

			arg_52_0:showDialog(true, var_53_1, var_0_9)
			arg_52_0:showTrap()
			arg_52_0:updateBottomList()
			arg_52_0:initHerosModel(true)
		end
	end)
end

function var_0_0.shake(arg_55_0)
	local var_55_0 = arg_55_0:nodeByName("bottom_di")
	local var_55_1 = var_0_5.storyShakeDuration
	local var_55_2 = var_0_5.shakeOffPos1
	local var_55_3 = xyd.Shake:create(var_55_1, 0, var_55_2)

	var_55_0:runActionOnce(var_55_3, nil, function()
		arg_55_0.shaking_ = false
	end)
end

function var_0_0.openBox(arg_57_0, arg_57_1, arg_57_2, arg_57_3, arg_57_4)
	if arg_57_0.openBoxEffcet then
		arg_57_0.openBoxEffcet:removeSelf()

		arg_57_0.openBoxEffcet = nil
	end

	if not arg_57_1 then
		return
	end

	local var_57_0 = "skeletons/ui_effect/zhugeliang/zhuge_effect03"
	local var_57_1 = arg_57_0:nodeByName("detail_container"):getContentSize()
	local var_57_2 = cc.p(840, 30)

	arg_57_0.openBoxEffcet = arg_57_0:createEffect(var_57_0, arg_57_0:nodeByName("detail_container"), var_57_2, 1)

	arg_57_0.openBoxEffcet:setVisible(true)

	if arg_57_3 then
		arg_57_0.openBoxEffcet:play(nil, true, nil, arg_57_2)
	else
		arg_57_0.openBoxEffcet:play(function()
			arg_57_0.openBoxEffcet:setVisible(false)

			if arg_57_4 then
				arg_57_4()
			end
		end, false, nil, arg_57_2)
	end
end

function var_0_0.openBox2(arg_59_0, arg_59_1, arg_59_2, arg_59_3, arg_59_4)
	if arg_59_0.openBox2Effcet then
		arg_59_0.openBox2Effcet:removeSelf()

		arg_59_0.openBox2Effcet = nil
	end

	if not arg_59_1 then
		return
	end

	local var_59_0 = "skeletons/ui_effect/zhugeliang/zhuge_effect03"
	local var_59_1 = arg_59_0:nodeByName("detail_container"):getContentSize()
	local var_59_2 = cc.p(840, 30)

	arg_59_0.openBox2Effcet = arg_59_0:createEffect(var_59_0, arg_59_0:nodeByName("detail_container"), var_59_2, 1)

	arg_59_0.openBox2Effcet:setVisible(true)
	arg_59_0.openBox2Effcet:play(nil, true, nil, arg_59_2)
end

function var_0_0.showStoneEffcet(arg_60_0, arg_60_1)
	if arg_60_0.stoneEffcet then
		arg_60_0.stoneEffcet:removeSelf()

		arg_60_0.stoneEffcet = nil
	end

	local var_60_0 = "skeletons/ui_effect/zhugeliang/zhuge_effect02"
	local var_60_1 = arg_60_0:nodeByName("detail_container"):getContentSize()
	local var_60_2 = cc.p(var_60_1.width / 2, 0)

	arg_60_0.stoneEffcet = arg_60_0:createEffect(var_60_0, arg_60_0:nodeByName("detail_container"), var_60_2, 1)

	arg_60_0.stoneEffcet:play(function()
		if arg_60_1 then
			arg_60_1()
		end
	end, false)
end

function var_0_0.createEffect(arg_62_0, arg_62_1, arg_62_2, arg_62_3, arg_62_4)
	local var_62_0 = arg_62_4 or 1
	local var_62_1 = var_0_2.new(arg_62_1 .. ".json", arg_62_1 .. ".atlas", var_62_0)

	var_62_1:addTo(arg_62_2)
	var_62_1:setPosition(arg_62_3)

	return var_62_1
end

function var_0_0.checkCanGoOn(arg_63_0)
	if arg_63_0:checkIsComplete() then
		arg_63_0:showComplete()

		return false
	end

	if not arg_63_0:checkHerosAlive() then
		local var_63_0 = var_0_1:translation("ZHUGE_FOREST_TIPS_36")

		arg_63_0:showDialog(true, var_63_0)

		arg_63_0.isAnimation = false

		return false
	end

	return true
end

function var_0_0.checkIsComplete(arg_64_0)
	if arg_64_0.zhugeModel:checkIsComplete() then
		return true
	end

	return false
end

function var_0_0.checkHerosAlive(arg_65_0)
	local var_65_0 = arg_65_0.zhugeModel:getCurrentHeros()
	local var_65_1 = false

	for iter_65_0 = 1, #var_65_0 do
		local var_65_2 = var_65_0[iter_65_0]
		local var_65_3 = arg_65_0.zhugeModel:getHeroStatus(var_65_2:getTableID())

		if var_65_3 and var_65_3.health ~= 2 then
			var_65_1 = true

			break
		end
	end

	return var_65_1
end

function var_0_0.getAvoidBtnPos(arg_66_0)
	local var_66_0
	local var_66_1 = math.random(0, var_0_11.width)
	local var_66_2 = math.random(0, var_0_11.height)

	return (cc.p(var_66_1 + var_0_12.x, var_66_2 + var_0_12.y))
end

function var_0_0.showBtnAvoid(arg_67_0, arg_67_1, arg_67_2)
	if not arg_67_1 then
		arg_67_0:nodeByName("btn_avoid"):setVisible(false)

		return
	end

	arg_67_0:nodeByName("btn_avoid"):setVisible(true)
	arg_67_0:nodeByName("btn_avoid"):setLocalZOrder(100)

	local var_67_0 = arg_67_0:getAvoidBtnPos()

	arg_67_0:nodeByName("btn_avoid"):setPosition(var_67_0)

	local var_67_1 = cc.ScaleTo:create(1, 0.5)

	arg_67_0:nodeByName("circle"):setScale(1)
	arg_67_0:nodeByName("circle"):runActionOnce(var_67_1, false, function()
		arg_67_0.canClick = false

		arg_67_0:showBtnAvoid(false)

		if not arg_67_0.avoidSuccess then
			arg_67_0.zhugeModel:avoidDamage(false, function(arg_69_0, arg_69_1)
				if arg_69_0 == xyd.error.OK and arg_67_2 then
					arg_67_2()
				end
			end)
		end
	end)

	arg_67_0.canClick = true
end

function var_0_0.walkToAvoidStone(arg_70_0, arg_70_1)
	for iter_70_0, iter_70_1 in pairs(arg_70_0.herosModel) do
		iter_70_1:flipX(true)
	end

	if arg_70_0.petModel and not tolua.isnull(arg_70_0.petModel) then
		arg_70_0.petModel:flipX(true)
	end

	local var_70_0 = arg_70_0.herosModelNode:getContentSize()

	arg_70_0:playHerosModelMove(cc.p(640 - var_70_0.width / 2 - 180, 0), 1, function()
		for iter_71_0, iter_71_1 in pairs(arg_70_0.herosModel) do
			iter_71_1:flipX(false)
		end

		if arg_70_0.petModel and not tolua.isnull(arg_70_0.petModel) then
			arg_70_0.petModel:flipX(false)
		end

		if arg_70_1 then
			arg_70_1()
		end
	end)
end

function var_0_0.playTreasuerEvent(arg_72_0)
	arg_72_0.herosModelNode:setPosition(cc.p(0, 0))
	arg_72_0:playHerosModelMove(cc.p(240, 0), 1, function()
		local var_73_0 = var_0_1:translation("ZHUGE_FOREST_TIPS_30")

		arg_72_0:showDialog(true, var_73_0, var_0_10)
		arg_72_0:showBox(true)
		var_0_3.performWithDelayGlobal(function()
			arg_72_0:playHerosModelMove(cc.p(440, 0), 0.5, function()
				arg_72_0:showBox(false)
				arg_72_0:openBox(true, "texiao1", false, function()
					arg_72_0:openBox2(true, "texiao2", true)

					local var_76_0 = arg_72_0.zhugeModel:getAwards()

					if var_76_0 and next(var_76_0) then
						arg_72_0.selfPlayer:handleRewards(var_76_0, function()
							arg_72_0:openBox2(false)

							if arg_72_0:checkCanGoOn() then
								local var_77_0 = var_0_1:translation("ZHUGE_FOREST_TIPS_27")

								arg_72_0:showDialog(true, var_77_0, var_0_9)
								arg_72_0:showRightBtn(true)
							end
						end)
					end
				end)
			end)
		end, 1)
	end)
end

function var_0_0.showBox(arg_78_0, arg_78_1)
	if arg_78_1 then
		if not arg_78_0.giftBox then
			arg_78_0.giftBox = xyd.AssetLoader.get():loadSprite("windows/zhugeliang/adventure/box_close.png")

			arg_78_0.giftBox:addTo(arg_78_0:nodeByName("detail_container"))
			arg_78_0.giftBox:setPosition(cc.p(840, 0))
			arg_78_0.giftBox:setAnchorPoint(cc.p(0.5, 0))
		end

		arg_78_0.giftBox:setVisible(true)
	elseif arg_78_0.giftBox then
		arg_78_0.giftBox:setVisible(false)
	end
end

function var_0_0.showComplete(arg_79_0)
	arg_79_0.isComplete = true
	arg_79_0.isAnimation = false

	arg_79_0:showRightBtn(false)
	arg_79_0:showEnemy(false)

	local var_79_0 = var_0_1:translation("ZHUGE_FOREST_TIPS_31")

	arg_79_0:showDialog(true, var_79_0)

	local var_79_1 = arg_79_0.zhugeModel:getBaseInfo()

	arg_79_0.zhugeModel:updateMemberInfo(nil)

	if var_79_1.is_first_complete == 1 then
		arg_79_0:playStory()
	end
end

function var_0_0.playReport(arg_80_0, arg_80_1)
	if arg_80_1 == nil then
		return
	end

	if not arg_80_0 or tolua.isnull(arg_80_0) then
		return
	end

	local var_80_0 = {}
	local var_80_1 = json.decode(arg_80_1)

	var_80_0.herosA = {}
	var_80_0.herosB = {}
	var_80_0.summonMonsters = {}
	var_80_0.campaignType = xyd.CampaignType.ZHUGE_ENEMY
	var_80_0.battleID = xyd.MapBattleID.ZHUGE_ENEMY
	var_80_0.battleType = xyd.BattleType.ReplayReport
	ngx.ctx.battle.reportData = var_80_1

	local var_80_2 = {}
	local var_80_3 = {}

	for iter_80_0, iter_80_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_80_4 = string.sub(iter_80_0, 1, 1)
		local var_80_5 = tonumber(string.sub(iter_80_0, 3, 3))

		if var_80_4 == "A" and tonumber(iter_80_1.summon_type) == xyd.summonMonsterType.None then
			local var_80_6 = var_0_7.new()

			var_80_6:populate(iter_80_1.hero)
			var_80_6:setReportData(iter_80_1)

			var_80_6.healthStatus = arg_80_0.zhugeModel:getOldHeroStatus(var_80_6:getTableID())

			if isOnlyData then
				var_80_6.harms = iter_80_1.harms
				var_80_6.willDie = (iter_80_1.die_count or 0) ~= -1
			end

			var_80_0.herosA[var_80_5] = var_80_6
		elseif var_80_4 == "A" and tonumber(iter_80_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_80_7 = var_0_8.new()

			var_80_7:populate(iter_80_1.hero)
			var_80_7:setReportData(iter_80_1)

			if isOnlyData then
				var_80_7.harms = iter_80_1.harms
				var_80_7.willDie = (iter_80_1.die_count or 0) ~= -1
				var_80_0.petA = {
					var_80_7
				}
			else
				var_80_0.petsA = {
					var_80_7
				}
			end
		elseif var_80_4 == "B" and tonumber(iter_80_1.summon_type) == xyd.summonMonsterType.None then
			local var_80_8 = var_0_7.new()

			var_80_8:populate(iter_80_1.hero)
			var_80_8:setReportData(iter_80_1)

			if isOnlyData then
				var_80_8.harms = iter_80_1.harms
				var_80_8.willDie = (iter_80_1.die_count or 0) ~= -1
				var_80_0.herosB[var_80_5] = var_80_8
			else
				var_80_2[var_80_5] = var_80_8
			end
		elseif var_80_4 == "B" and tonumber(iter_80_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_80_9 = var_0_8.new()

			var_80_9:populate(iter_80_1.hero)
			var_80_9:setReportData(iter_80_1)

			if isOnlyData then
				var_80_9.harms = iter_80_1.harms
				var_80_9.willDie = (iter_80_1.die_count or 0) ~= -1
				var_80_0.petB = {
					var_80_9
				}
			else
				var_80_0.petsB = {
					var_80_9
				}
			end
		elseif var_80_4 == "C" then
			local var_80_10 = var_0_7.new()

			var_80_10:populate(iter_80_1.hero)
			var_80_10:setReportData(iter_80_1)

			if not isOnlyData then
				sceneFighter = var_80_10
			end
		elseif tonumber(iter_80_1.summon_type) ~= xyd.summonMonsterType.None and tonumber(iter_80_1.summon_type) ~= xyd.summonMonsterType.Pet then
			local var_80_11 = var_0_7.new()

			var_80_11:populate(iter_80_1.hero)
			var_80_11:setReportData(iter_80_1)

			var_80_3[iter_80_0] = var_80_11
		end
	end

	var_80_0.herosB = {
		var_80_2
	}
	var_80_0.sceneFighter = sceneFighter
	var_80_0.summonMonsters = var_80_3
	var_80_0.reportStar = tonumber(var_80_1.star)

	arg_80_0.zhugeModel:updateEnemyStar(var_80_1.star)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "zhuge_adventure",
			status = {
				storyEventType = xyd.ZhugeEventType.ENEMY_END
			}
		}
	})
	xyd.WindowManager.get():retainHistory()
	xyd.pushBattleScene(var_80_0)
end

function var_0_0.showSelectTeam(arg_81_0)
	local var_81_0 = {
		teamType = xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM
	}

	xyd.WindowManager.get():openWindow("zhuge_select_team", var_81_0)
end

function var_0_0.playEnemyEndEvent(arg_82_0)
	arg_82_0.herosModelNode:setPosition(cc.p(640, 0))
	arg_82_0:showEnemy(false)
	arg_82_0.zhugeModel:updateEnemyStar(0)
	arg_82_0:showRightBtn(true)

	local var_82_0 = var_0_1:translation("ZHUGE_FOREST_TIPS_27")

	arg_82_0:showDialog(true, var_82_0, var_0_9)
end

function var_0_0.playStory(arg_83_0)
	local var_83_0 = {
		talk_id = "zhuge02",
		callback = function()
			xyd.WindowManager.get():openWindow("zhuge_small_house")
		end
	}

	xyd.WindowManager.get():openWindow("school_story_talk", var_83_0)
	xyd.WindowManager.get():closeWindow(arg_83_0.name)
end

function var_0_0.updateBg(arg_85_0)
	if not arg_85_0.bgIndex then
		arg_85_0.bgIndex = 0
	end

	arg_85_0.bgIndex = (arg_85_0.bgIndex + 1) % 3 + 1

	if arg_85_0.bgSprite then
		arg_85_0.bgSprite:removeSelf()

		arg_85_0.bgSprite = nil
	end

	arg_85_0.bgSprite = xyd.AssetLoader.get():loadSprite("windows/zhugeliang/adventure/map/map_" .. arg_85_0.bgIndex .. ".png")

	arg_85_0.bgSprite:addTo(arg_85_0:nodeByName("container"), -1)
	arg_85_0.bgSprite:setAnchorPoint(cc.p(0, 0))
	arg_85_0.bgSprite:setPosition(cc.p(0, 0))

	local var_85_0 = arg_85_0.bgSprite:getContentSize()

	arg_85_0.bgSprite:setScale(xyd.STAGE_WIDTH / var_85_0.width, xyd.STAGE_HEIGHT / var_85_0.height)
end

function var_0_0.createRightArrowAction(arg_86_0)
	local var_86_0, var_86_1 = arg_86_0:nodeByName("right"):getPosition()
	local var_86_2 = transition.sequence({
		cc.MoveTo:create(1, cc.p(var_86_0 - 10, var_86_1)),
		cc.MoveTo:create(1, cc.p(var_86_0, var_86_1))
	})
	local var_86_3 = cc.RepeatForever:create(var_86_2)

	arg_86_0:nodeByName("right"):runAction(var_86_3)
end

return var_0_0
