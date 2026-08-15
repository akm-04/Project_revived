local var_0_0 = class("ActivitySqTurntableShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.activitySqRaffleCGift

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.activity = arg_1_2.activity
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:initData()
	arg_2_0:initListview()
	arg_2_0:updateScore()
end

function var_0_0.initData(arg_3_0)
	local var_3_0 = var_0_3:ids()
	local var_3_1 = {}

	for iter_3_0 = 1, #var_3_0 do
		if arg_3_0.selfPlayer.vip >= var_0_3:vip(var_3_0[iter_3_0]) then
			table.insert(var_3_1, var_3_0[iter_3_0])
		end
	end

	arg_3_0.items = var_3_1
end

function var_0_0.initListview(arg_4_0)
	local var_4_0 = arg_4_0:nodeByName("item_details")
	local var_4_1 = var_4_0:getContentSize()

	arg_4_0.list_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_1.width, var_4_1.height),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_4_0)

	arg_4_0.list_:setDelegate(handler(arg_4_0, arg_4_0.delegate))
end

function var_0_0.delegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = #arg_5_0.items

	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return var_5_0
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_1
		local var_5_2
		local var_5_3
		local var_5_4 = arg_5_0.list_:dequeueItem()

		if not var_5_4 then
			var_5_4 = arg_5_0.list_:newItem()
		else
			var_5_4:removeAllChildren()
		end

		local var_5_5 = display.newNode()

		var_5_5:setTouchSwallowEnabled(false)

		local var_5_6 = display.newNode()

		arg_5_0:initItemCell(var_5_6, arg_5_3)
		var_5_5:addChild(var_5_6)

		local var_5_7 = var_5_6:getContentSize()

		var_5_5:setContentSize(cc.size(var_5_7.width + 25, arg_5_0.list_.viewRect_.height))
		var_5_4:setItemSize(var_5_7.width + 25, arg_5_0.list_.viewRect_.height)
		var_5_4:addContent(var_5_5)

		return var_5_4
	end
end

function var_0_0.updateScore(arg_6_0)
	arg_6_0:nodeByName("point_txt"):setString(var_0_2:translation("JIFEN_TIP") .. "：")
	arg_6_0:nodeByName("point_num"):setString(arg_6_0.activity.details.score)
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	arg_7_0:addBlockLayer()
	arg_7_0.list_:reload()
end

function var_0_0.initItemCell(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = arg_8_0.items[arg_8_2]
	local var_8_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1100/shop/shop_item.csb")
	local var_8_2 = var_8_1:getChildByName("container")
	local var_8_3 = var_8_2:getContentSize()

	arg_8_1:setContentSize(var_8_3)
	var_8_1:addTo(arg_8_1)
	var_8_2:getChildByName("pic"):loadTexture(var_0_3:icon(var_8_0))

	local var_8_4 = var_0_3:cost(var_8_0)

	var_8_2:getChildByName("cost"):setString(var_8_4 .. " " .. var_0_2:translation("JIFEN_TIP"))
	var_8_2:getChildByName("button"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			if var_8_4 > arg_8_0.activity.details.score then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("SQUARE_TURNTABLE2_POINT_TIP")
				})

				return
			end

			arg_8_0.activitiesModel:getActivityReward(arg_8_0.activity.table_id, var_8_0, function(arg_10_0, arg_10_1)
				if arg_10_0 == xyd.error.OK then
					arg_8_0.activity.details.score = arg_8_0.activity.details.score - var_8_4

					arg_8_0:updateScore()
					arg_8_0.callback()
					arg_8_0.selfPlayer:handleRewards(arg_10_1.awards)
				end
			end)
		end
	end)
end

return var_0_0
