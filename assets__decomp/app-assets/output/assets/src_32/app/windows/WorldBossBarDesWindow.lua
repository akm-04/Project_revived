local var_0_0 = class("WorldBossBarDesWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = 10011

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.WorldBoss = xyd.ModelManager.get():loadModel(xyd.ModelType.WORLD_BOSS)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.listView_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, arg_2_0:nodeByName("reward_list"):getWidth(), arg_2_0:nodeByName("reward_list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_2_0:nodeByName("reward_list"))

	arg_2_0.listView_:setBounceable(true)
	arg_2_0:init()
end

function var_0_0.init(arg_3_0)
	local var_3_0 = string.formatnumberthousands(arg_3_0.WorldBoss.boss_brave)

	arg_3_0:nodeByName("now_value_text"):setString(var_3_0)
	arg_3_0:nodeByName("des_words"):setString(var_0_2:translation("WORLD_BOSS_BRAVE_STATE_DES"))
	arg_3_0:nodeByName("second_title_words"):setString(var_0_2:translation("BRAVE_VALUE_REWARD"))
	arg_3_0:nodeByName("now_value_words"):setString(var_0_2:translation("CURRENT_BRAVE") .. var_0_2:translation("COLON"))
	arg_3_0:nodeByName("title_words"):setString(var_0_2:translation("BRAVE_STATE"))
	arg_3_0.listView_:removeAllItems()

	for iter_3_0 = var_0_3 + 4, var_0_3, -1 do
		if iter_3_0 <= arg_3_0.WorldBoss.boss_id then
			local var_3_1 = cc.c4b(200, 200, 200, 255)

			if iter_3_0 ~= arg_3_0.WorldBoss.boss_id then
				var_3_1 = xyd.color.GREEN
			end

			local var_3_2 = display.newNode()
			local var_3_3 = arg_3_0.listView_:newItem()

			arg_3_0:initCell(var_3_2, xyd.tables.worldBoss.open_explain[iter_3_0], var_3_1)
			var_3_2:setContentSize(675, 80)
			var_3_3:setItemSize(675, 80)
			var_3_3:addContent(var_3_2)
			arg_3_0.listView_:addItem(var_3_3)
		end
	end

	arg_3_0.listView_:reload()
end

function var_0_0.initCell(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/worldBoss/rewardAlert/rewardAlertItem.csb")
	local var_4_1 = var_4_0:getChildByName("container")
	local var_4_2 = var_4_1:getContentSize()

	var_4_1:getChildByName("reward_des_words"):setTextColor(arg_4_3)
	var_4_1:getChildByName("need_value_words"):setTextColor(arg_4_3)
	var_4_1:getChildByName("point"):setTextColor(arg_4_3)

	local var_4_3 = xyd.luaStringSplit(arg_4_2, "@")

	var_4_1:getChildByName("reward_des_words"):setString(var_4_3[1])
	var_4_1:getChildByName("need_value_words"):setString(var_4_3[2])
	arg_4_1:addChild(var_4_0)
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super:didOpen(arg_5_1)
	arg_5_0:addBlockLayer()
	arg_5_0:nodeByName("close_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			local var_6_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_6_0, false)
			xyd.WindowManager.get():closeWindow(arg_5_0.name)
		end
	end)
end

return var_0_0
