local var_0_0 = class("DragonBoatSelectTeamWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = xyd.tables.activityDragonBoat
local var_0_3 = xyd.tables.translation
local var_0_4 = 1
local var_0_5 = 4
local var_0_6 = 30
local var_0_7 = 4
local var_0_8 = 3
local var_0_9 = {
	10001003,
	10001009,
	10001010,
	10001018,
	10001025,
	10001028,
	10001039,
	10001040,
	10001046,
	10001048,
	10001053,
	10001071,
	10001075,
	11001003,
	11001009,
	11001040
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.dragonBoatModel = xyd.ModelManager.get():loadModel(xyd.ModelType.DRAGON_BOAT)
	arg_1_0.team_ = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:layout()
	arg_3_0:getBoatingBtn()
end

function var_0_0.willClose(arg_4_0)
	return
end

function var_0_0.didClose(arg_5_0)
	return
end

function var_0_0.layout(arg_6_0)
	arg_6_0:setupText()
	arg_6_0:initData()
	arg_6_0:playActions()
	arg_6_0:setupList()
end

function var_0_0.initData(arg_7_0)
	arg_7_0.boatID_ = arg_7_0.dragonBoatModel:getLastBoatID() or var_0_4

	arg_7_0:nodeByName("boat_container"):scale(0.7)
	arg_7_0:nodeByName("hero_container"):scale(0.7)
	arg_7_0:updateWindow()
end

function var_0_0.updateWindow(arg_8_0)
	arg_8_0:updateText()
	arg_8_0:updateBoatImage()
end

function var_0_0.setupText(arg_9_0)
	arg_9_0:nodeByName("text_top_tip"):setString(var_0_3:translation("DRAGONBOAT_SELECT_TOP_TIP"))
	arg_9_0:nodeByName("text_tip_tittle"):setString(var_0_3:translation("DRAGONBOAT_SELECT_TEXT_TIP_TITTLE"))
	arg_9_0:nodeByName("text_price_label"):setString(var_0_3:translation("DRAGONBOAT_SELECT_PRICE_LABEL"))
end

function var_0_0.updateText(arg_10_0)
	arg_10_0:nodeByName("text_boat_name"):setString(var_0_2:name(arg_10_0.boatID_))
	arg_10_0:nodeByName("text_content"):setString(var_0_2:des(arg_10_0.boatID_))
	arg_10_0:nodeByName("text_price_value"):setString(var_0_2:crystal(arg_10_0.boatID_))
end

function var_0_0.playActions(arg_11_0)
	if not arg_11_0.actions_ then
		arg_11_0.actions_ = {}

		local var_11_0 = cc.Sequence:create(cc.FadeOut:create(1), cc.FadeIn:create(1))
		local var_11_1 = cc.Sequence:create(cc.FadeOut:create(1), cc.FadeIn:create(1))

		arg_11_0.actions_[1] = cc.RepeatForever:create(var_11_0)
		arg_11_0.actions_[2] = cc.RepeatForever:create(var_11_1)

		arg_11_0:getLastBoatArrow():runAction(arg_11_0.actions_[1])
		arg_11_0:getNextBoatArrow():runAction(arg_11_0.actions_[2])
	end
end

function var_0_0.getLastBoatArrow(arg_12_0)
	if not arg_12_0.lastArrow_ then
		local var_12_0 = arg_12_0:nodeByName("button_switch_1")

		var_12_0:setTouchEnabled(true)
		var_12_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
			if arg_13_0.name == "ended" then
				arg_12_0.boatID_ = arg_12_0.boatID_ - 1
				arg_12_0.boatID_ = arg_12_0.boatID_ < 1 and var_0_5 or arg_12_0.boatID_

				arg_12_0:updateWindow()
				audio.playSound(xyd.tables.sound:getSound("ui_switch_page"))
			end

			return true
		end)
		var_12_0:setCascadeOpacityEnabled(true)

		arg_12_0.lastArrow_ = var_12_0
	end

	return arg_12_0.lastArrow_
end

function var_0_0.getNextBoatArrow(arg_14_0)
	if not arg_14_0.nextArrow_ then
		local var_14_0 = arg_14_0:nodeByName("button_switch_2")

		var_14_0:setTouchEnabled(true)
		var_14_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
			if arg_15_0.name == "ended" then
				arg_14_0.boatID_ = arg_14_0.boatID_ + 1
				arg_14_0.boatID_ = arg_14_0.boatID_ > var_0_5 and 1 or arg_14_0.boatID_

				arg_14_0:updateWindow()
				audio.playSound(xyd.tables.sound:getSound("ui_switch_page"))
			end

			return true
		end)

		arg_14_0.nextArrow_ = var_14_0

		var_14_0:setCascadeOpacityEnabled(true)
	end

	return arg_14_0.nextArrow_
end

function var_0_0.updateBoatImage(arg_16_0)
	local var_16_0 = arg_16_0:nodeByName("boat_container")

	var_16_0:removeAllChildren()

	local var_16_1 = xyd.AssetLoader.get():loadSprite("windows/activities/1060/boat" .. arg_16_0.boatID_ .. ".png")
	local var_16_2 = var_16_0:getWidth()
	local var_16_3 = var_16_0:getHeight()

	var_16_1:addTo(var_16_0):align(display.CENTER_BOTTOM, var_16_2 / 2, 0)
end

function var_0_0.setupList(arg_17_0)
	arg_17_0.heros_ = {}

	for iter_17_0, iter_17_1 in ipairs(arg_17_0.selfPlayer.heros_) do
		if not table.keyof(var_0_9, iter_17_1:getTableID()) then
			table.insert(arg_17_0.heros_, iter_17_1)
		end
	end

	arg_17_0:sortTables(arg_17_0.heros_)

	local var_17_0 = arg_17_0:nodeByName("list")
	local var_17_1 = var_17_0:getWidth()
	local var_17_2 = var_17_0:getHeight()

	arg_17_0.list_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_17_1, var_17_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_17_0)

	arg_17_0.list_:setDelegate(handler(arg_17_0, arg_17_0.delegate))
	arg_17_0.list_:reload()
end

function var_0_0.sortTables(arg_18_0, arg_18_1)
	for iter_18_0 = 1, #arg_18_1 do
		table.sort(arg_18_1[iter_18_0], function(arg_19_0, arg_19_1)
			return xyd.heroNormalSort(arg_19_0, arg_19_1) or false
		end)
	end
end

function var_0_0.delegate(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	local var_20_0 = math.ceil(#arg_20_0.heros_ / var_0_7)

	if cc.ui.UIListView.COUNT_TAG == arg_20_2 then
		return var_20_0
	elseif cc.ui.UIListView.CELL_TAG == arg_20_2 then
		local var_20_1 = arg_20_0.list_:dequeueItem()

		if not var_20_1 then
			var_20_1 = arg_20_0.list_:newItem()
		else
			var_20_1:removeAllChildren()
		end

		local var_20_2 = display.newNode()
		local var_20_3

		var_20_2:setTouchSwallowEnabled(false)

		for iter_20_0 = 1, var_0_7 do
			local var_20_4 = (arg_20_3 - 1) * var_0_7 + iter_20_0

			if var_20_4 > #arg_20_0.heros_ then
				break
			end

			var_20_3 = display.newNode()

			arg_20_0:initHeroCell(var_20_3, var_20_4)

			local var_20_5 = var_20_3:getWidth()
			local var_20_6 = var_20_3:getHeight()
			local var_20_7 = (arg_20_0:nodeByName("list"):getWidth() - var_20_5 * var_0_7) / (var_0_7 + 1)

			var_20_3:align(display.CENTER, var_20_7 * iter_20_0 + (iter_20_0 - 1) * var_20_5 + var_20_5 / 2, var_0_6 + var_20_6 / 2)
			var_20_2:addChild(var_20_3)
		end

		var_20_2:size(arg_20_0:nodeByName("list"):getWidth(), var_20_3:getHeight() + var_0_6)
		var_20_1:setItemSize(arg_20_0:nodeByName("list"):getWidth(), var_20_2:getHeight())
		var_20_1:addContent(var_20_2)

		return var_20_1
	end
end

function var_0_0.initHeroCell(arg_21_0, arg_21_1, arg_21_2)
	local var_21_0 = arg_21_0.heros_[arg_21_2]
	local var_21_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar.csb")
	local var_21_2 = {
		"background",
		"mp_di",
		"hp_di",
		"mp_bar",
		"hp_bar",
		"dead_text",
		"avatar_mask",
		"chosen",
		"team1",
		"team2",
		"team3",
		"yongbing_tubiao",
		"is_can_rent"
	}

	for iter_21_0, iter_21_1 in ipairs(var_21_2) do
		var_21_1:getChildByName(iter_21_1):hide()
	end

	var_21_1:addTo(arg_21_1)
	xyd.setAvatarBorder(var_21_0, var_21_1:getChildByName("avatar"))
	var_21_1:getChildByName("name_text"):setString(var_21_0:getName())
	var_21_1:getChildByName("lv_txt"):setString(var_21_0:getLevel())
	var_21_1:setName("layout")
	var_21_1:size(var_21_1:getChildByName("background"):getWidth(), var_21_1:getChildByName("background"):getHeight())
	arg_21_1:size(var_21_1:getChildByName("background"):getWidth(), var_21_1:getChildByName("background"):getHeight())
	arg_21_1:setTouchEnabled(true)
	arg_21_1:setTouchSwallowEnabled(false)
	arg_21_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_22_0)
		arg_21_0:buttonHandler(arg_21_1, arg_22_0)

		if arg_22_0.name == "began" then
			arg_21_0.startClick_ = true
			arg_21_0.prevX_ = arg_22_0.x
			arg_21_0.prevY_ = arg_22_0.y
		elseif arg_22_0.name == "moved" then
			if math.abs(arg_22_0.y - arg_21_0.prevY_) > 5 or math.abs(arg_22_0.x - arg_21_0.prevX_) > 5 then
				arg_21_0.startClick_ = false
			end
		elseif arg_22_0.name == "ended" and arg_21_0.startClick_ then
			arg_21_0:clickAvatar(arg_21_1)
		end

		return true
	end)

	arg_21_1.hero = var_21_0

	if table.keyof(arg_21_0.team_, var_21_0) then
		var_21_1:getChildByName("chosen"):show()
		var_21_1:getChildByName("avatar_mask"):show()
	end
end

function var_0_0.buttonHandler(arg_23_0, arg_23_1, arg_23_2)
	if not arg_23_1 or not arg_23_1:getParent() then
		return
	end

	if arg_23_2.name == "ended" then
		transition.stopTarget(arg_23_1)
		arg_23_1:setScale(1)
	elseif arg_23_2.name == "began" then
		local var_23_0 = cc.ScaleTo:create(0.3, 0.95)

		arg_23_1:runAction(var_23_0)

		return true
	elseif arg_23_2.name == "cancled" then
		transition.stopTarget(arg_23_1)
		arg_23_1:setScale(1)
	end
end

function var_0_0.clickAvatar(arg_24_0, arg_24_1)
	local var_24_0 = arg_24_1.hero
	local var_24_1 = table.keyof(arg_24_0.team_, var_24_0)
	local var_24_2 = arg_24_1:getChildByName("layout")

	if var_24_1 then
		var_24_2:getChildByName("chosen"):hide()
		var_24_2:getChildByName("avatar_mask"):hide()
		var_24_0.dragonModel_:removeSelf()
		table.remove(arg_24_0.team_, var_24_1)

		for iter_24_0 = var_24_1, #arg_24_0.team_ do
			arg_24_0.team_[iter_24_0].dragonModel_:x(arg_24_0:nodeByName("node_" .. iter_24_0):getX())
		end

		return
	end

	if #arg_24_0.team_ >= var_0_8 then
		return
	end

	var_24_2:getChildByName("chosen"):show()
	var_24_2:getChildByName("avatar_mask"):show()
	table.insert(arg_24_0.team_, var_24_0)

	if var_24_0.dragonModel_ and not tolua.isnull(var_24_0.dragonModel_) then
		var_24_0.dragonModel_:addTo(arg_24_0:nodeByName("hero_container"))
	else
		var_24_0.dragonModel_ = var_24_0:getHeroModel()

		var_24_0.dragonModel_:retain()
		var_24_0.dragonModel_:addTo(arg_24_0:nodeByName("hero_container"))
	end

	var_24_0.dragonModel_:pos(arg_24_0:nodeByName("node_" .. #arg_24_0.team_):getX(), arg_24_0:nodeByName("node_" .. #arg_24_0.team_):getY())
end

function var_0_0.getBoatingBtn(arg_25_0)
	if not arg_25_0.boatingBtn_ then
		arg_25_0.boatingBtn_ = arg_25_0:nodeByName("button_boating")

		arg_25_0.boatingBtn_:addTouchEventListener(function(arg_26_0, arg_26_1)
			if arg_26_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				if next(arg_25_0.team_) == nil then
					local var_26_0 = var_0_3:translation("DRAGONBOAT_SELECT_PARTNER_TIP")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_26_0
					})

					return
				end

				if var_0_2:crystal(arg_25_0.boatID_) > 0 then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_3:translation("DRAGONBOAT_BUY_BOAT_COST"), var_0_2:crystal(arg_25_0.boatID_)), function()
						if arg_25_0.selfPlayer.crystal < var_0_2:crystal(arg_25_0.boatID_) then
							local var_27_0 = var_0_3:translation("CRYSTAL_TIP")

							xyd.WindowManager.get():openWindow("toast", {
								message = var_27_0
							})
						else
							arg_25_0.dragonBoatModel:startBoating({
								boat_id = arg_25_0.boatID_
							}, function()
								local var_28_0 = {
									team = arg_25_0.team_,
									boatID = arg_25_0.boatID_
								}

								xyd.WindowManager.get():openWindow("dragon_boat_boating", var_28_0)
								xyd.WindowManager.get():closeWindow(arg_25_0)
							end)
						end
					end, nil, nil, arg_25_0.colorMode)
				else
					arg_25_0.dragonBoatModel:startBoating({
						boat_id = arg_25_0.boatID_
					}, function()
						local var_29_0 = {
							team = arg_25_0.team_,
							boatID = arg_25_0.boatID_
						}

						xyd.WindowManager.get():openWindow("dragon_boat_boating", var_29_0)
						xyd.WindowManager.get():closeWindow(arg_25_0)
					end)
				end
			end
		end)
	end

	return arg_25_0.boatingBtn_
end

return var_0_0
