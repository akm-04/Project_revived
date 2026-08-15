local var_0_0 = class("BattlePassRewardViewWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.battlePassReward
local var_0_3 = xyd.tables.gift
local var_0_4 = xyd.tables.misc
local var_0_5 = xyd.tables.item
local var_0_6 = xyd.tables.asset
local var_0_7 = var_0_4:getValue("battle_pass_award_loop_range")
local var_0_8 = var_0_4:getValue("battle_pass_award_max_level") - var_0_7
local var_0_9 = {
	NORMAL = 1,
	SENIOR = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.battlePass = xyd.ModelManager.get():loadModel(xyd.ModelType.BATTLE_PASS)
	arg_1_0.type_ = var_0_9.NORMAL
	arg_1_0.normalLevel = arg_1_0.battlePass:getNormalLevel()
	arg_1_0.seniorLevel = arg_1_0.battlePass:getSeniorLevel()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	local var_3_0 = arg_3_0:convertToWorldSpace(cc.p(0, 0))

	arg_3_0.blockLayer_ = display.newColorLayer(cc.c4b(0, 0, 0, 180))

	arg_3_0.blockLayer_:pos(-var_3_0.x, -var_3_0.y):addTo(arg_3_0:background(), -1)
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_title"):setString(var_0_1:translation("BATTLE_PASS_TEXT_10"))
	arg_4_0:nodeByName("txt_normal_pass"):setString(var_0_1:translation("BATTLE_PASS_TEXT_11"))
	arg_4_0:nodeByName("txt_senior_pass"):setString(var_0_1:translation("BATTLE_PASS_TEXT_12"))
	arg_4_0:nodeByName("txt_level_up"):setString(var_0_1:translation("BATTLE_PASS_TEXT_7"))

	local var_4_0 = arg_4_0:nodeByName("list"):getContentSize()

	arg_4_0.list = cc.ui.UITableView.new({
		async = true,
		itemGap = 14,
		size = var_4_0,
		direction = cc.ui.UITableView.DIRECTION_VERTICAL,
		itemSize = cc.size(var_4_0.width, 142)
	}):addTo(arg_4_0:nodeByName("list"))

	arg_4_0.list:setDelegate(handler(arg_4_0, arg_4_0.delegate))
	arg_4_0.list:reload()
	arg_4_0:initBtns()
end

function var_0_0.initBtns(arg_5_0)
	arg_5_0:nodeByName("btn_normal"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			if arg_5_0.type_ == var_0_9.NORMAL then
				return
			end

			arg_5_0:nodeByName("normal_pass"):setVisible(true)
			arg_5_0:nodeByName("senior_pass"):setVisible(false)
			arg_5_0:nodeByName("btn_normal"):getChildByName("icon_gray"):setVisible(false)
			arg_5_0:nodeByName("btn_normal"):getChildByName("icon"):setVisible(true)
			arg_5_0:nodeByName("btn_senior"):getChildByName("icon_gray"):setVisible(true)
			arg_5_0:nodeByName("btn_senior"):getChildByName("icon"):setVisible(false)
			arg_5_0:nodeByName("arrow"):setPositionX(362)

			arg_5_0.type_ = var_0_9.NORMAL

			arg_5_0.list:reload()
		end
	end)
	arg_5_0:nodeByName("btn_senior"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			if arg_5_0.type_ == var_0_9.SENIOR then
				return
			end

			arg_5_0:nodeByName("normal_pass"):setVisible(false)
			arg_5_0:nodeByName("senior_pass"):setVisible(true)
			arg_5_0:nodeByName("btn_normal"):getChildByName("icon_gray"):setVisible(true)
			arg_5_0:nodeByName("btn_normal"):getChildByName("icon"):setVisible(false)
			arg_5_0:nodeByName("btn_senior"):getChildByName("icon_gray"):setVisible(false)
			arg_5_0:nodeByName("btn_senior"):getChildByName("icon"):setVisible(true)
			arg_5_0:nodeByName("arrow"):setPositionX(918)

			arg_5_0.type_ = var_0_9.SENIOR

			arg_5_0.list:reload()
		end
	end)
	xyd.nodeEventSample(arg_5_0:nodeByName("btn_level_up"), nil, function()
		xyd.WindowManager.get():openWindow("battle_pass_buy_senior")
	end)
end

function var_0_0.getDataByType(arg_9_0, arg_9_1)
	if arg_9_1 == var_0_9.NORMAL then
		if arg_9_0.normalData then
			return arg_9_0.normalData
		else
			arg_9_0.normalData = {}

			local var_9_0 = {}
			local var_9_1 = {}

			for iter_9_0 = 1, var_0_8 do
				local var_9_2, var_9_3 = var_0_2:getItem(iter_9_0)

				if var_9_2 and var_9_2 ~= 0 then
					if var_9_0[var_9_2] then
						var_9_0[var_9_2] = var_9_0[var_9_2] + var_9_3
					else
						var_9_0[var_9_2] = var_9_3
					end

					if iter_9_0 <= arg_9_0.normalLevel then
						if var_9_1[var_9_2] then
							var_9_1[var_9_2] = var_9_1[var_9_2] + var_9_3
						else
							var_9_1[var_9_2] = var_9_3
						end
					end
				end
			end

			for iter_9_1, iter_9_2 in pairs(var_9_0) do
				local var_9_4 = {
					item_id = iter_9_1,
					total_num = iter_9_2,
					get_num = var_9_1[iter_9_1] or 0
				}

				table.insert(arg_9_0.normalData, var_9_4)
			end

			return arg_9_0.normalData
		end
	elseif arg_9_1 == var_0_9.SENIOR then
		if arg_9_0.seniorData then
			return arg_9_0.seniorData
		else
			arg_9_0.seniorData = {}

			local var_9_5 = {}
			local var_9_6 = {}

			for iter_9_3 = 1, var_0_8 do
				local var_9_7, var_9_8 = var_0_2:getItem(iter_9_3, true)

				if var_9_7 and var_9_7 ~= 0 then
					if var_9_5[var_9_7] then
						var_9_5[var_9_7] = var_9_5[var_9_7] + var_9_8
					else
						var_9_5[var_9_7] = var_9_8
					end

					if iter_9_3 <= arg_9_0.seniorLevel then
						if var_9_6[var_9_7] then
							var_9_6[var_9_7] = var_9_6[var_9_7] + var_9_8
						else
							var_9_6[var_9_7] = var_9_8
						end
					end
				end
			end

			for iter_9_4, iter_9_5 in pairs(var_9_5) do
				local var_9_9 = {
					item_id = iter_9_4,
					total_num = iter_9_5,
					get_num = var_9_6[iter_9_4] or 0
				}

				table.insert(arg_9_0.seniorData, var_9_9)
			end

			return arg_9_0.seniorData
		end
	end
end

function var_0_0.delegate(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	if arg_10_2 == cc.ui.UITableView.COUNT_TAG then
		return math.ceil(#arg_10_0:getDataByType(arg_10_0.type_) / 2)
	elseif arg_10_2 == cc.ui.UITableView.CELL_TAG then
		local var_10_0 = arg_10_0.list:getItem()
		local var_10_1 = arg_10_0:createContent(arg_10_3)

		var_10_0:addContent(var_10_1)

		return var_10_0
	end
end

function var_0_0.createContent(arg_11_0, arg_11_1)
	local var_11_0 = arg_11_0:getDataByType(arg_11_0.type_)
	local var_11_1 = display.newNode()

	for iter_11_0 = 1, 2 do
		local var_11_2 = (arg_11_1 - 1) * 2 + iter_11_0

		if not var_11_0[var_11_2] then
			break
		end

		local var_11_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/battle_pass/view_item.csb")
		local var_11_4 = var_11_3:getChildByName("bg")

		xyd.setItemAndAddTips(var_11_4:getChildByName("item"), var_11_0[var_11_2].item_id)

		if var_11_0[var_11_2].item_id < 0 then
			var_11_4:getChildByName("txt_name"):setString(var_0_6:name(var_11_0[var_11_2].item_id))
		else
			var_11_4:getChildByName("txt_name"):setString(var_0_5:name(var_11_0[var_11_2].item_id))
		end

		var_11_4:getChildByName("txt_num"):setString(var_11_0[var_11_2].get_num .. "/" .. var_11_0[var_11_2].total_num)
		var_11_4:getChildByName("bg_bar"):getChildByName("bar"):setPercent(100 * var_11_0[var_11_2].get_num / var_11_0[var_11_2].total_num)
		var_11_4:getChildByName("txt_get"):setString(var_0_1:translation("BATTLE_PASS_TEXT_13"))
		var_11_3:setPosition((iter_11_0 - 1) * 458, 0)
		var_11_1:addChild(var_11_3)
	end

	return var_11_1
end

return var_0_0
