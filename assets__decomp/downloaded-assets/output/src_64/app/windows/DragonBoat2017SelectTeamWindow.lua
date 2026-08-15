local var_0_0 = class("DragonBoat2017SelectTeamWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.activityDragonship2
local var_0_4 = var_0_3:getBoatNums()
local var_0_5 = 20
local var_0_6 = 5
local var_0_7 = 1
local var_0_8 = 7
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
	arg_1_0.dragonBoatModel = xyd.ModelManager.get():loadModel(xyd.ModelType.DRAGON_BOAT2017)
	arg_1_0.team_ = clone(arg_1_0.dragonBoatModel:getTeams()) or {}
end

function var_0_0.didOpen(arg_2_0, arg_2_1)
	var_0_0.super:didOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:setButtonClick()
	arg_3_0:setupText()
	arg_3_0:initData()
	arg_3_0:playActions()
	arg_3_0:setupList()
	arg_3_0:initialTeam()
end

function var_0_0.setButtonClick(arg_4_0)
	arg_4_0:nodeByName("button_boating"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if next(arg_4_0.team_) == nil then
				local var_5_0 = var_0_2:translation("DRAGONBOAT_SELECT_PARTNER_TIP")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_5_0
				})

				return
			end

			local var_5_1 = {
				formation = xyd.getFormationStr(arg_4_0.team_)
			}

			arg_4_0.dragonBoatModel:saveBoatFormation(var_5_1, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					arg_4_0.dragonBoatModel:setBoatID(arg_4_0.boatID_)
					xyd.WindowManager.get():closeWindow(arg_4_0)
				end
			end)
		end
	end)
end

function var_0_0.initData(arg_7_0)
	arg_7_0.boatID_ = arg_7_0.dragonBoatModel:getBoatID() or var_0_7

	arg_7_0:nodeByName("boat_container"):scale(0.7)
	arg_7_0:nodeByName("hero_container"):scale(0.5)
	arg_7_0:updateWindow()
end

function var_0_0.updateWindow(arg_8_0)
	arg_8_0:updateText()
	arg_8_0:updateBoatImage()
end

function var_0_0.setupText(arg_9_0)
	arg_9_0:nodeByName("text_top_tip"):setString(var_0_2:translation("DRAGONBOAT_SELECT_TOP_TIP"))
	arg_9_0:nodeByName("text_tip_tittle"):setString(var_0_2:translation("DRAGONBOAT2017_SELECT_TEXT_TIP_TITTLE"))
	arg_9_0:nodeByName("text_price_label"):setString(var_0_2:translation("DRAGONBOAT_SELECT_PRICE_LABEL"))
	arg_9_0:nodeByName("txt_title"):setString(var_0_2:translation("DRAGON_BOAT2017_SELECT_TEAM_TITLE"))
	arg_9_0:nodeByName("txt_boating"):setString(var_0_2:translation("DRAGON_BOAT2017_SELECT_TEAM_GO"))
end

function var_0_0.updateText(arg_10_0)
	arg_10_0:nodeByName("text_boat_name"):setString(var_0_3:name(arg_10_0.boatID_))
	arg_10_0:nodeByName("text_content"):setString(var_0_3:des(arg_10_0.boatID_))
	arg_10_0:nodeByName("text_price_value"):setString(var_0_3:crystal(arg_10_0.boatID_))
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
				arg_12_0.boatID_ = arg_12_0.boatID_ < 1 and var_0_4 or arg_12_0.boatID_

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
				arg_14_0.boatID_ = arg_14_0.boatID_ > var_0_4 and 1 or arg_14_0.boatID_

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

	local var_16_1 = xyd.AssetLoader.get():loadSprite("windows/activities/1104/boat" .. arg_16_0.boatID_ .. ".png")
	local var_16_2 = var_16_0:getWidth()
	local var_16_3 = var_16_0:getHeight()

	var_16_1:addTo(var_16_0):align(display.CENTER_BOTTOM, var_16_2 / 2, 0)
end

function var_0_0.setupList(arg_17_0)
	arg_17_0.heros_ = {}

	for iter_17_0, iter_17_1 in ipairs(arg_17_0.selfPlayer.heros_) do
		if not table.keyof(var_0_9, iter_17_1:getFirstTableID()) then
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

function var_0_0.initialTeam(arg_18_0)
	arg_18_0:nodeByName("hero_container"):removeAllChildren()

	for iter_18_0 = 1, #arg_18_0.team_ do
		local var_18_0 = arg_18_0.team_[iter_18_0]

		var_18_0.dragonModel_ = var_18_0:getHeroModel()

		var_18_0.dragonModel_:retain()
		var_18_0.dragonModel_:addTo(arg_18_0:nodeByName("hero_container"))
		var_18_0.dragonModel_:pos(504 - (iter_18_0 - 1) * 120, 0)
	end
end

function var_0_0.sortTables(arg_19_0, arg_19_1)
	table.sort(arg_19_1, function(arg_20_0, arg_20_1)
		if arg_20_0:getFirstTableID() == 10001215 or arg_20_1:getFirstTableID() == 10001215 then
			return arg_20_0:getTableID() == 10001215
		end

		return xyd.heroNormalSort(arg_20_0, arg_20_1) or false
	end)
end

function var_0_0.delegate(arg_21_0, arg_21_1, arg_21_2, arg_21_3)
	local var_21_0 = math.ceil(#arg_21_0.heros_ / var_0_8)

	if cc.ui.UIListView.COUNT_TAG == arg_21_2 then
		return var_21_0
	elseif cc.ui.UIListView.CELL_TAG == arg_21_2 then
		local var_21_1 = arg_21_0.list_:dequeueItem()

		if not var_21_1 then
			var_21_1 = arg_21_0.list_:newItem()
		else
			var_21_1:removeAllChildren()
		end

		local var_21_2 = display.newNode()
		local var_21_3

		var_21_2:setTouchSwallowEnabled(false)

		for iter_21_0 = 1, var_0_8 do
			local var_21_4 = (arg_21_3 - 1) * var_0_8 + iter_21_0

			if var_21_4 > #arg_21_0.heros_ then
				break
			end

			var_21_3 = display.newNode()

			arg_21_0:initHeroCell(var_21_3, var_21_4)

			local var_21_5 = var_21_3:getWidth()
			local var_21_6 = var_21_3:getHeight()
			local var_21_7 = (arg_21_0:nodeByName("list"):getWidth() - var_21_5 * var_0_8) / (var_0_8 + 1)

			var_21_3:align(display.CENTER, var_21_7 * iter_21_0 + (iter_21_0 - 1) * var_21_5 + var_21_5 / 2, var_0_5 + var_21_6 / 2)
			var_21_2:addChild(var_21_3)
		end

		var_21_2:size(arg_21_0:nodeByName("list"):getWidth(), var_21_3:getHeight() + var_0_5)
		var_21_1:setItemSize(arg_21_0:nodeByName("list"):getWidth(), var_21_2:getHeight())
		var_21_1:addContent(var_21_2)

		return var_21_1
	end
end

function var_0_0.initHeroCell(arg_22_0, arg_22_1, arg_22_2)
	local var_22_0 = arg_22_0.heros_[arg_22_2]
	local var_22_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_new/hero_avatar_list.csb")

	var_22_1:getChildByName("avatar_mask"):setVisible(false)
	var_22_1:addTo(arg_22_1)
	xyd.setAvatarBorderNewUI(var_22_0, var_22_1:getChildByName("avatar"))
	var_22_1:getChildByName("name_text"):setString(var_22_0:getName())
	var_22_1:getChildByName("lv_txt"):setString(var_22_0:getLevel())
	var_22_1:setName("layout")
	var_22_1:size(var_22_1:getChildByName("background"):getWidth(), var_22_1:getChildByName("background"):getHeight())
	arg_22_1:size(var_22_1:getChildByName("background"):getWidth(), var_22_1:getChildByName("background"):getHeight())

	if var_22_0:getFirstTableID() == 10001215 then
		local var_22_2 = var_22_0:getStar()
		local var_22_3 = {
			size = 18,
			text = var_0_2:translation("DRAGONBOAT2017_GET_ZONGZI_" .. var_22_2),
			color = cc.c3b(210, 84, 16),
			align = cc.ui.TEXT_ALIGN_CENTER,
			valign = cc.ui.TEXT_VALIGN_TOP
		}
		local var_22_4 = xyd.AssetLoader.get():loadLabel(var_22_3)

		var_22_4:setAnchorPoint(cc.p(0.5, 0.5))
		var_22_4:addTo(var_22_1)
		var_22_4:setPosition(cc.p(var_22_1:getChildByName("background"):getWidth() / 2, -(var_0_5 / 2)))
	end

	arg_22_1:setTouchEnabled(true)
	arg_22_1:setTouchSwallowEnabled(false)
	arg_22_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_23_0)
		arg_22_0:buttonHandler(arg_22_1, arg_23_0)

		if arg_23_0.name == "began" then
			arg_22_0.startClick_ = true
			arg_22_0.prevX_ = arg_23_0.x
			arg_22_0.prevY_ = arg_23_0.y
		elseif arg_23_0.name == "moved" then
			if math.abs(arg_23_0.y - arg_22_0.prevY_) > 5 or math.abs(arg_23_0.x - arg_22_0.prevX_) > 5 then
				arg_22_0.startClick_ = false
			end
		elseif arg_23_0.name == "ended" and arg_22_0.startClick_ then
			arg_22_0:clickAvatar(arg_22_1)
		end

		return true
	end)

	arg_22_1.hero = var_22_0

	if arg_22_0:getHeroIndexInTeam(var_22_0) then
		var_22_1:getChildByName("chosen"):show()
		var_22_1:getChildByName("avatar_mask"):show()
	end
end

function var_0_0.buttonHandler(arg_24_0, arg_24_1, arg_24_2)
	if not arg_24_1 or not arg_24_1:getParent() then
		return
	end

	if arg_24_2.name == "ended" then
		transition.stopTarget(arg_24_1)
		arg_24_1:setScale(1)
	elseif arg_24_2.name == "began" then
		local var_24_0 = cc.ScaleTo:create(0.3, 0.95)

		arg_24_1:runAction(var_24_0)

		return true
	elseif arg_24_2.name == "cancled" then
		transition.stopTarget(arg_24_1)
		arg_24_1:setScale(1)
	end
end

function var_0_0.clickAvatar(arg_25_0, arg_25_1)
	local var_25_0 = arg_25_1.hero
	local var_25_1 = arg_25_0:getHeroIndexInTeam(var_25_0)
	local var_25_2 = arg_25_1:getChildByName("layout")

	if var_25_1 then
		var_25_2:getChildByName("chosen"):hide()
		var_25_2:getChildByName("avatar_mask"):hide()
		var_25_0.dragonModel_:removeSelf()
		table.remove(arg_25_0.team_, var_25_1)
		arg_25_0:initialTeam()

		return
	end

	if #arg_25_0.team_ >= var_0_6 then
		return
	end

	var_25_2:getChildByName("chosen"):show()
	var_25_2:getChildByName("avatar_mask"):show()
	table.insert(arg_25_0.team_, var_25_0)
	arg_25_0:initialTeam()
end

function var_0_0.getHeroIndexInTeam(arg_26_0, arg_26_1)
	for iter_26_0, iter_26_1 in pairs(arg_26_0.team_) do
		if iter_26_1:getFirstTableID() == arg_26_1:getFirstTableID() then
			return iter_26_0
		end
	end
end

return var_0_0
