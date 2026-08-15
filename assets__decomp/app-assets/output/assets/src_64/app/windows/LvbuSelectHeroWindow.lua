local var_0_0 = class("LvbuSelectHero", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.attr
local var_0_4 = 28
local var_0_5 = 10
local var_0_6 = 260
local var_0_7 = 392
local var_0_8 = 1
local var_0_9 = 3
local var_0_10 = 5

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.lvbuFestival = xyd.ModelManager.get():loadModel(xyd.ModelType.LVBU_FESTIVAL)
	arg_1_0.startIndex = 1
	arg_1_0.heros = {}
	arg_1_0.selectedHeros = {}
	arg_1_0.currentGroup = {}
	arg_1_0.selectIds = arg_1_2.ids
	arg_1_0.currentSelectedIds = arg_1_2.cur_select

	if arg_1_0.currentSelectedIds then
		arg_1_0:initialSelectedHeros()

		arg_1_0.startIndex = #arg_1_0.currentSelectedIds * var_0_9 + 1

		if #arg_1_0.currentSelectedIds == var_0_10 then
			arg_1_0.startIndex = (var_0_10 - 1) * var_0_9 + 1
		end
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.initialSelectedHeros(arg_3_0)
	for iter_3_0 = 1, #arg_3_0.currentSelectedIds do
		local var_3_0 = var_0_1.new()

		var_3_0:initUnCollected(arg_3_0.currentSelectedIds[iter_3_0])
		table.insert(arg_3_0.selectedHeros, var_3_0)
	end

	arg_3_0.lvbuFestival:formatLvbuCampusHeros(arg_3_0.selectedHeros)
end

function var_0_0.updateAvatars(arg_4_0)
	arg_4_0:nodeByName("select_bg"):setVisible(true)

	local var_4_0 = arg_4_0:nodeByName("avatar" .. 1):getContentSize()

	for iter_4_0 = 1, #arg_4_0.selectedHeros do
		local var_4_1 = display.newNode()

		var_4_1:setContentSize(var_4_0.width, var_4_0.height)
		var_4_1:setAnchorPoint(cc.p(0, 0))
		arg_4_0:nodeByName("avatar" .. iter_4_0):removeAllChildren(true)
		xyd.setAvatarBorder(arg_4_0.selectedHeros[iter_4_0], var_4_1)
		var_4_1:addTo(arg_4_0:nodeByName("avatar" .. iter_4_0))

		local var_4_2 = {}
		local var_4_3 = arg_4_0.selectedHeros[iter_4_0]:getTableID()

		var_4_2.id = var_4_3
		var_4_2.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_4_3)

		arg_4_0:addHeroTips(var_4_1, arg_4_0.selectedHeros[iter_4_0])
	end
end

function var_0_0.addHeroTips(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = {
		id = arg_5_2:getTableID(),
		lev = arg_5_2:getLevel(),
		quality = arg_5_2:getColor(),
		name = arg_5_2:getName(),
		desc = xyd.tables.hero:getDes(arg_5_2:getTableID()),
		hero = arg_5_2
	}

	var_5_0.isHero = true

	local var_5_1, var_5_2 = arg_5_1:getPosition()

	arg_5_1:setTouchEnabled(true)
	arg_5_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			local var_6_0 = xyd.WindowManager.get():getWindow("new_item_tips")
			local var_6_1 = arg_5_0:convertToWorldSpace(cc.p(0, 0))

			if not var_6_0 then
				local var_6_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_5_0)

				xyd.adaptToWorldPosition(arg_5_1, var_6_2)
			end

			return true
		elseif arg_6_0.name == "ended" and xyd.WindowManager.get():getWindow("new_item_tips") then
			local var_6_3 = xyd.WindowManager.get():closeWindow("new_item_tips")
		end
	end)
end

function var_0_0.layout(arg_7_0)
	arg_7_0:nodeByName("select_bg"):setVisible(false)
	arg_7_0:nodeByName("text_mid"):setString(string.format(var_0_2:translation("SELECT_NTH_HERO"), 1))

	arg_7_0.itemList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_7_0:nodeByName("list"):getWidth(), arg_7_0:nodeByName("list"):getHeight()),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_7_0:nodeByName("list")):onScroll(handler(arg_7_0, arg_7_0.scrollListener))

	if arg_7_0.itemList.touchNode_ then
		arg_7_0.itemList.touchNode_:setTouchEnabled(false)
	end

	arg_7_0.itemList:setDelegate(handler(arg_7_0, arg_7_0.listDelegate))

	arg_7_0.scrollx = 0

	arg_7_0.itemList:setBounceable(false)
	arg_7_0:changeGroup()
	arg_7_0:updateAvatars()
	arg_7_0:updateSelectBtnState()
	arg_7_0:nodeByName("select_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			arg_7_0:nodeByName("select_btn"):setScale(1)
			xyd.playButtonSound()
			arg_7_0:buyGroup()
		elseif arg_8_1 == ccui.TouchEventType.began then
			arg_7_0:nodeByName("select_btn"):setScale(0.9)
		elseif arg_8_1 == ccui.TouchEventType.moved then
			arg_7_0:nodeByName("select_btn"):setScale(0.9)
		end
	end)
	xyd.nodeEventSample(arg_7_0:nodeByName("close_btn"), nil, function()
		local var_9_0 = string.format(var_0_2:translation("SURE_GIVE_UP_GROUP"), xyd.tables.misc.lvbuTeamChange)

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
			var_9_0
		}, function()
			arg_7_0.lvbuFestival:giveUp({}, function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK then
					xyd.WindowManager.get():closeWindow(arg_7_0)
				end
			end)
		end)
	end)
	arg_7_0:nodeByName("title"):setString(var_0_2:translation("LVBU_NEW_TXT7"))
	arg_7_0:nodeByName("close_txt"):setString(var_0_2:translation("LVBU_NEW_TXT8"))
	arg_7_0:nodeByName("save_txt"):setString(var_0_2:translation("LVBU_NEW_TXT9"))
	arg_7_0:nodeByName("save_gray_txt"):setString(var_0_2:translation("LVBU_NEW_TXT9"))
end

function var_0_0.listDelegate(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	if cc.ui.UIListView.COUNT_TAG == arg_12_2 then
		return #arg_12_0.currentGroup
	elseif cc.ui.UIListView.CELL_TAG == arg_12_2 then
		local var_12_0 = arg_12_0.itemList:dequeueItem()

		if not var_12_0 then
			var_12_0 = arg_12_0.itemList:newItem()
		else
			var_12_0:removeAllChildren(true)
		end

		local var_12_1 = arg_12_0:createItemContent(arg_12_0.currentGroup[arg_12_3])
		local var_12_2 = var_12_1:getWidth()
		local var_12_3 = var_12_1:getHeight()

		var_12_0:setItemSize(var_12_2 + 12, var_12_3)
		var_12_0:addContent(var_12_1)

		return var_12_0
	end
end

function var_0_0.createItemContent(arg_13_0, arg_13_1)
	local var_13_0 = var_0_1.new()

	var_13_0:initUnCollected(arg_13_1)

	local var_13_1 = display.newNode()
	local var_13_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/lvbu/select/hero_item.csb")
	local var_13_3 = var_13_2:getChildByName("container")
	local var_13_4 = var_13_0:getName()
	local var_13_5 = var_13_0:getDes()
	local var_13_6 = cc.p(var_13_3:getChildByName("text_pos"):getPosition())
	local var_13_7 = {
		size = 20,
		color = cc.c3b(106, 105, 119),
		text = var_13_5,
		dimensions = cc.size(215, 0),
		x = var_13_6.x,
		y = var_13_6.y,
		align = cc.ui.TEXT_ALIGN_CENTER
	}
	local var_13_8 = xyd.AssetLoader.get():loadLabel(var_13_7)

	var_13_8:addTo(var_13_3)
	var_13_8:setAnchorPoint(cc.p(0.5, 1))
	var_13_3:getChildByName("text_name"):setString(var_13_4)
	var_13_3:getChildByName("text_name"):enableOutline(cc.c4b(193, 109, 64, 255), 2)

	local var_13_9 = var_13_3:getChildByName("hero_container")
	local var_13_10 = var_13_0:getHeroModel()

	var_13_10:setScale(0.8)
	var_13_9:addChild(var_13_10)
	var_13_10:setPositionX(var_13_9:getContentSize().width / 2)

	local var_13_11 = display.newNode()

	var_13_11:setContentSize(var_0_6, var_0_7)
	var_13_11:setAnchorPoint(cc.p(0, 0))
	var_13_11:setPosition(2, var_13_3:getContentSize().height - var_0_7 - 20)
	var_13_11:setTouchEnabled(true)
	var_13_11:setTouchSwallowEnabled(false)
	var_13_11:addTo(var_13_3)
	var_13_11:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
		if arg_14_0.name == "began" then
			return true
		elseif arg_14_0.name == "ended" then
			arg_13_0:selectHero(var_13_0)
		end
	end)
	var_13_2:addTo(var_13_1)
	var_13_2:setAnchorPoint(cc.p(0, 0))
	var_13_1:setContentSize(var_13_3:getContentSize())
	var_13_2:setName("source")

	return var_13_1
end

function var_0_0.selectHero(arg_15_0, arg_15_1)
	if arg_15_0.onSelecting then
		return
	end

	if #arg_15_0.selectedHeros >= var_0_10 then
		local var_15_0 = var_0_2:translation("LVBU_GROUP_FULL_TIPS")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_15_0
		})

		return
	end

	arg_15_0.lvbuFestival:formatLvbuCampusHeros({
		arg_15_1
	})
	table.insert(arg_15_0.selectedHeros, arg_15_1)

	if #arg_15_0.selectedHeros <= var_0_10 then
		arg_15_0.onSelecting = true

		local var_15_1 = {
			team_str = arg_15_0:getFormationStr(arg_15_0.selectedHeros)
		}

		arg_15_0.lvbuFestival:setCurrentHero(var_15_1, function(arg_16_0, arg_16_1)
			if arg_16_0 == xyd.error.OK then
				arg_15_0.onSelecting = false

				arg_15_0:updateAvatars()
				arg_15_0:updateSelectBtnState()

				if #arg_15_0.selectedHeros < var_0_10 then
					arg_15_0:changeGroup()
				end
			else
				table.remove(arg_15_0.selectedHeros, #arg_15_0.selectedHeros)

				arg_15_0.onSelecting = false
			end
		end)
	end
end

function var_0_0.updateSelectBtnState(arg_17_0)
	if #arg_17_0.selectedHeros >= var_0_10 then
		arg_17_0:nodeByName("select_btn"):setBright(true)
		arg_17_0:nodeByName("select_btn"):setTouchEnabled(true)
		arg_17_0:nodeByName("save_txt"):setVisible(true)
		arg_17_0:nodeByName("save_gray_txt"):setVisible(false)
	else
		arg_17_0:nodeByName("select_btn"):setBright(false)
		arg_17_0:nodeByName("select_btn"):setTouchEnabled(false)
		arg_17_0:nodeByName("save_txt"):setVisible(false)
		arg_17_0:nodeByName("save_gray_txt"):setVisible(true)
	end
end

function var_0_0.changeGroup(arg_18_0)
	arg_18_0.currentGroup = {}

	for iter_18_0 = 1, var_0_9 do
		table.insert(arg_18_0.currentGroup, arg_18_0.selectIds[arg_18_0.startIndex])

		arg_18_0.startIndex = arg_18_0.startIndex + 1
	end

	arg_18_0:nodeByName("text_mid"):setString(string.format(var_0_2:translation("SELECT_NTH_HERO"), #arg_18_0.selectedHeros + 1))
	arg_18_0.itemList:reload()
end

function var_0_0.buyGroup(arg_19_0)
	local var_19_0 = {
		team_str = arg_19_0:getFormationStr(arg_19_0.selectedHeros)
	}

	arg_19_0.lvbuFestival:setTeam(var_19_0, function(arg_20_0, arg_20_1)
		if arg_20_0 == xyd.error.OK then
			xyd.WindowManager.get():closeWindow(arg_19_0)
		end
	end)
end

function var_0_0.getFormationStr(arg_21_0, arg_21_1)
	local var_21_0 = ""

	for iter_21_0, iter_21_1 in ipairs(arg_21_1) do
		var_21_0 = var_21_0 .. string.format("%d", iter_21_1:getTableID())

		if iter_21_0 < #arg_21_1 then
			var_21_0 = var_21_0 .. "|"
		end
	end

	return var_21_0
end

function var_0_0.scrollListener(arg_22_0, arg_22_1)
	if arg_22_1.name == "began" then
		arg_22_0.scrollViewMoved_ = false
		arg_22_0.prevX_ = arg_22_1.x
	elseif arg_22_1.name == "moved" then
		arg_22_0.scrollx = arg_22_0.itemList:getScrollNode():getPositionX()

		if 20 <= math.abs(arg_22_1.x - arg_22_0.prevX_) then
			arg_22_0.scrollViewMoved_ = true
		end
	elseif arg_22_1.name == "scrollEnd" then
		arg_22_0.scrollx = arg_22_0.itemList:getScrollNode():getPositionX()
	end
end

function var_0_0.didOpen(arg_23_0, arg_23_1)
	var_0_0.super.didOpen(arg_23_1)
	arg_23_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
