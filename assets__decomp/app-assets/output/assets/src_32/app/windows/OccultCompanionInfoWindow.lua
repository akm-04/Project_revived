local var_0_0 = class("OccultCompanionInfoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = 6

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.occult = xyd.ModelManager.get():loadModel(xyd.ModelType.OCCULT)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.heroInfos = arg_1_2
	arg_1_0.dispatchStatus = arg_1_0.heroInfos.dispatch_status
	arg_1_0.playerID = arg_1_2.player_id
	arg_1_0.playerInfo = arg_1_0.occult:getPlayerInfoByID(arg_1_0.playerID)

	arg_1_0:initialHeros()
end

function var_0_0.initialHeros(arg_2_0, ...)
	arg_2_0.dispatchHeros = {}
	arg_2_0.unDispatchHeros = {}

	for iter_2_0 = 1, #arg_2_0.heroInfos.dispatch_heroes do
		local var_2_0 = var_0_2.new()

		var_2_0:populate(arg_2_0.heroInfos.dispatch_heroes[iter_2_0])
		table.insert(arg_2_0.dispatchHeros, var_2_0)
	end

	for iter_2_1 = 1, #arg_2_0.heroInfos.undispatch_heroes do
		local var_2_1 = var_0_2.new()

		var_2_1:populate(arg_2_0.heroInfos.undispatch_heroes[iter_2_1])
		table.insert(arg_2_0.unDispatchHeros, var_2_1)
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)
	arg_3_0:layout()
	arg_3_0:addBlockLayer()
	arg_3_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("title_text"):setString(var_0_1:translation("HERO_WUJIANG"))

	arg_4_0.scroll = arg_4_0:nodeByName("scroll")

	local var_4_0 = arg_4_0.scroll:getContentSize()

	arg_4_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.scroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.scrollList:setDelegate(handler(arg_4_0, arg_4_0.scrollListDelegate))
	arg_4_0.scrollList:reload()
	arg_4_0:updatePlayerInfo()
end

function var_0_0.updatePlayerInfo(arg_5_0)
	xyd.setPlayerInfoContainer(arg_5_0:nodeByName("container"), arg_5_0.playerInfo)
end

function var_0_0.scrollListDelegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return math.ceil(#arg_6_0.dispatchHeros / var_0_3) + 2 + math.ceil(#arg_6_0.unDispatchHeros / var_0_3)
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_0
		local var_6_1 = arg_6_0.scrollList:dequeueItem()

		if not var_6_1 then
			var_6_1 = arg_6_0.scrollList:newItem()
		else
			var_6_1:removeAllChildren(true)
		end

		local var_6_2

		if arg_6_3 == 1 or arg_6_3 == math.ceil(#arg_6_0.dispatchHeros / var_0_3) + 2 then
			var_6_2 = arg_6_0:createTitleContent(arg_6_3)
		else
			var_6_2 = arg_6_0:createListContent(arg_6_3)
		end

		local var_6_3 = var_6_2:getWidth()
		local var_6_4 = var_6_2:getHeight()

		var_6_1:setItemSize(var_6_3, var_6_4 + 17)
		var_6_1:addContent(var_6_2)

		return var_6_1
	end
end

function var_0_0.createTitleContent(arg_7_0, arg_7_1)
	local var_7_0 = display.newNode()
	local var_7_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/occult/companion_info/title_item.csb")
	local var_7_2 = var_7_1:getChildByName("container")
	local var_7_3 = string.format(var_0_1:translation("OCCULT_DISPATCH_HERO_TEXT"), #arg_7_0.dispatchHeros, xyd.tables.misc.creatsDispatchHeroLimit)

	if arg_7_1 > 1 then
		var_7_3 = var_0_1:translation("OCCULT_UNDISPATCH_HERO_TEXT")
	end

	var_7_2:getChildByName("progress_txt"):setString(var_7_3)
	var_7_1:addTo(var_7_0)
	var_7_1:setAnchorPoint(cc.p(0, 0))
	var_7_0:setContentSize(var_7_2:getContentSize())
	var_7_1:setName("source")

	return var_7_0
end

function var_0_0.createListContent(arg_8_0, arg_8_1)
	local var_8_0 = display.newNode()
	local var_8_1 = 126
	local var_8_2 = 10
	local var_8_3 = 5

	var_8_0:setContentSize(760, 140)

	local var_8_4 = math.ceil(#arg_8_0.dispatchHeros / var_0_3) + 3

	for iter_8_0 = 1, var_0_3 do
		local var_8_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_new/hero_avatar_new.csb")

		var_8_5:getChildByName("yongbing_tubiao"):setVisible(false)

		local var_8_6 = var_8_5:getChildByName("background"):getContentSize()
		local var_8_7 = var_8_5:getChildByName("chosen")

		var_8_7:setLocalZOrder(100)
		var_8_7:setVisible(false)

		local var_8_8 = var_8_5:getChildByName("avatar_mask")

		var_8_8:setLocalZOrder(2)
		var_8_8:setVisible(false)
		var_8_5:getChildByName("is_can_rent"):setVisible(false)

		for iter_8_1 = 1, 3 do
			var_8_5:getChildByName("team" .. iter_8_1):setVisible(false)
		end

		local var_8_9 = var_8_5:getChildByName("hp_bar")
		local var_8_10 = var_8_5:getChildByName("mp_bar")
		local var_8_11 = var_8_5:getChildByName("dead_text")

		var_8_11:setString(var_0_1:translation("ALREADY_DEAD"))

		if var_8_11 then
			var_8_11:setVisible(false)
		end

		local var_8_12

		if (arg_8_1 - 2) * var_0_3 + iter_8_0 <= #arg_8_0.dispatchHeros then
			var_8_12 = arg_8_0.dispatchHeros[(arg_8_1 - 2) * var_0_3 + iter_8_0]

			local var_8_13 = arg_8_0.dispatchStatus[tostring(var_8_12:getHeroID())]
			local var_8_14 = var_8_13.hp * 100 / var_8_13.total_hp
			local var_8_15 = var_8_13.mp * 100 / xyd.ENERGY_DECIMAL_BASE

			var_8_9:setPercent(var_8_14)
			var_8_9:setVisible(true)
			var_8_10:setPercent(var_8_15)
			var_8_10:setVisible(true)

			if var_8_13.hp <= 0 then
				var_8_11:setVisible(true)
				var_8_8:setVisible(true)
			end
		elseif var_8_4 <= arg_8_1 and (arg_8_1 - var_8_4) * var_0_3 + iter_8_0 <= #arg_8_0.unDispatchHeros then
			var_8_12 = arg_8_0.unDispatchHeros[(arg_8_1 - var_8_4) * var_0_3 + iter_8_0]

			var_8_9:hide()
			var_8_10:hide()
			var_8_5:getChildByName("hp_di"):hide()
			var_8_5:getChildByName("mp_di"):hide()
		end

		if var_8_12 then
			xyd.setAvatarBorderNewUI(var_8_12, var_8_5:getChildByName("avatar"))

			local var_8_16 = var_8_5:getChildByName("lv_txt")
			local var_8_17 = var_8_5:getChildByName("name_text")

			var_8_16:setString(var_8_12:getLevel())
			var_8_16:enableOutline(cc.c4b(0, 0, 0, 255), 1)
			var_8_17:setString(var_8_12:getName())
			var_8_5:addTo(var_8_0)
			var_8_5:setAnchorPoint(cc.p(0, 0))
			var_8_5:setPosition(cc.p(var_8_2, var_8_3))

			var_8_2 = var_8_2 + var_8_1
		end
	end

	return var_8_0
end

function var_0_0.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.scrollViewMoved_ = false
		arg_9_0.prevY_ = arg_9_1.y
	elseif arg_9_1.name == "moved" and 5 <= math.abs(arg_9_1.y - arg_9_0.prevY_) then
		arg_9_0.scrollViewMoved_ = true
	end
end

return var_0_0
