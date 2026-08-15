local var_0_0 = class("MagicSummonSwitchHeroWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.hero
local var_0_3 = 100
local var_0_4 = require("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.herolist = xyd.tables.magicSummonList:getHeroId(1)
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.scrollListener(arg_2_0, arg_2_1)
	if arg_2_1.name == "began" then
		arg_2_0.scrollViewMoved_ = false
		arg_2_0.prevY_ = arg_2_1.y
	elseif arg_2_1.name == "moved" and 20 <= math.abs(arg_2_1.y - arg_2_0.prevY_) then
		arg_2_0.scrollViewMoved_ = true
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_0:nodeByName("list")
	local var_3_1 = var_3_0:getContentSize()

	arg_3_0.width = var_3_1.width
	arg_3_0.listView_ = cc.ui.UIListView.new({
		async = true,
		touchOnContent = true,
		viewRect = cc.rect(0, 0, arg_3_0.width, var_3_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_3_0):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.listView_:setDelegate(handler(arg_3_0, arg_3_0.sourceDelegate))
	arg_3_0.listView_:setBounceable(true)
	arg_3_0.listView_:reload()
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
	arg_4_0:addBlockLayer()
end

function var_0_0.sourceDelegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return math.ceil(#arg_5_0.herolist / 5)
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_0
		local var_5_1 = arg_5_0.listView_:dequeueItem()

		if not var_5_1 then
			var_5_1 = arg_5_0.listView_:newItem()
		else
			var_5_1:removeAllChildren(true)
		end

		local var_5_2 = cc.Node:create()

		for iter_5_0 = 1, 5 do
			local var_5_3 = (arg_5_3 - 1) * 5 + iter_5_0

			if var_5_3 > #arg_5_0.herolist then
				break
			end

			local var_5_4 = cc.Node:create()

			var_5_4:setAnchorPoint(cc.p(0.5, 0.5))
			var_5_4:setContentSize(var_0_3, var_0_3)
			var_5_4:setPosition((iter_5_0 - 3) * 112, 0)
			var_5_2:addChild(var_5_4)
			arg_5_0:setBorder(arg_5_0.herolist[var_5_3], var_5_4)
		end

		var_5_1:setItemSize(arg_5_0.width, var_0_3 + 30)
		var_5_1:addContent(var_5_2)

		return var_5_1
	end
end

function var_0_0.setBorder(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = false
	local var_6_1 = arg_6_0.player:getHeros()
	local var_6_2 = arg_6_0.player:getHeroIgnoreAwaken(arg_6_1)

	if var_6_2 then
		xyd.setAvatarBorderNewUI(arg_6_1, arg_6_2, var_6_2:getColor(), var_6_2:getStar())
	elseif arg_6_1 ~= 0 then
		xyd.setAvatarBorder(arg_6_1, arg_6_2, 1, var_0_2:initialStar(arg_6_1), nil, true)

		var_6_0 = true
	end

	local var_6_3 = {}

	var_6_3.quality = 1
	var_6_3.isBoss = false
	var_6_3.id = arg_6_1
	var_6_3.name = xyd.tables.hero:name(arg_6_1)
	var_6_3.desc = xyd.tables.hero:getDes(arg_6_1)
	var_6_3.isHero = true

	local var_6_4
	local var_6_5 = false

	arg_6_2:setTouchEnabled(true)
	arg_6_2:setTouchSwallowEnabled(false)
	arg_6_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			local var_7_0 = 0

			local function var_7_1()
				var_7_0 = var_7_0 + 0.1

				if var_7_0 > 0.5 then
					var_6_5 = true

					if tolua.isnull(arg_6_2) then
						return
					end

					local var_8_0 = arg_6_2:getParent():convertToWorldSpace(cc.p(arg_6_2:getPosition()))

					if not xyd.WindowManager.get():getWindow("new_item_tips") then
						local var_8_1 = xyd.WindowManager.get():openWindow("new_item_tips", var_6_3)

						xyd.adaptToWorldPosition(arg_6_2, var_8_1)
					end
				else
					var_6_5 = false
				end
			end

			var_6_5 = false
			var_6_4 = var_0_4.scheduleGlobal(var_7_1, 0.1)

			return true
		elseif arg_7_0.name == "ended" then
			if var_6_4 then
				var_0_4.unscheduleGlobal(var_6_4)

				var_6_4 = nil
			end

			xyd.WindowManager.get():closeWindow("new_item_tips")

			if not var_6_5 and not arg_6_0.scrollViewMoved_ then
				if var_6_0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = xyd.tables.translation:translation("MAGIC_SUMMON_NO_HERO_TIP")
					})

					return
				end

				if arg_6_1 and arg_6_1 > 0 then
					arg_6_0.callback(arg_6_1)
				end

				xyd.WindowManager.get():closeWindow(arg_6_0)
			end
		end
	end)
end

function var_0_0.willClose(arg_9_0, arg_9_1)
	xyd.WindowManager.get():closeWindow("new_item_tips")
end

return var_0_0
