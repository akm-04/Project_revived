local var_0_0 = class("BattlePassMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.battlePassReward
local var_0_3 = xyd.tables.gift
local var_0_4 = xyd.tables.misc
local var_0_5 = var_0_4:getValue("battle_pass_award_loop_range")
local var_0_6 = var_0_4:getValue("battle_pass_award_max_level")
local var_0_7 = var_0_4:getValue("battle_pass_point_per_level")
local var_0_8 = var_0_6 - var_0_5

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.battlePass = xyd.ModelManager.get():loadModel(xyd.ModelType.BATTLE_PASS)
	arg_1_0.task = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar({
		show_rule = true
	})
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.BATTLE_PASS_POINT_CHANGE, handler(arg_3_0, arg_3_0.updatePoint))
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_buy_point"):setString(var_0_1:translation("BATTLE_PASS_TEXT_4"))
	arg_4_0:nodeByName("txt_normal_pass"):setString(var_0_1:translation("BATTLE_PASS_TEXT_5"))
	arg_4_0:nodeByName("txt_senior_pass"):setString(var_0_1:translation("BATTLE_PASS_TEXT_6"))
	arg_4_0:nodeByName("txt_level_up"):setString(var_0_1:translation("BATTLE_PASS_TEXT_7"))

	local var_4_0 = arg_4_0:nodeByName("list"):getContentSize()

	arg_4_0.list = cc.ui.UITableView.new({
		async = true,
		size = var_4_0,
		direction = cc.ui.UITableView.DIRECTION_HORIZONTAL,
		itemSize = cc.size(141, 330)
	}):addTo(arg_4_0:nodeByName("list")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.list:setSideResisVal(100)
	arg_4_0.list:setDelegate(handler(arg_4_0, arg_4_0.delegate))

	local var_4_1

	if arg_4_0.battlePass:isBuySenior() then
		var_4_1 = math.min(arg_4_0.battlePass:getNormalLevel(), arg_4_0.battlePass:getSeniorLevel())
	else
		var_4_1 = arg_4_0.battlePass:getNormalLevel()
	end

	arg_4_0.list:reloadAtIndex(arg_4_0:levelToIndex(var_4_1), true)

	if arg_4_0.battlePass:isBuySenior() then
		arg_4_0:nodeByName("lock"):setVisible(false)
	end

	local var_4_2 = var_0_4:getValue("battle_pass_season_start_time")
	local var_4_3 = var_0_4:getValue("battle_pass_season_end_time")
	local var_4_4 = os.date(var_0_1:translation("BATTLE_PASS_TEXT_3"), var_4_2)
	local var_4_5 = os.date(var_0_1:translation("BATTLE_PASS_TEXT_3"), var_4_3)
	local var_4_6 = string.format(var_0_1:translation("BATTLE_PASS_TEXT_1"), var_4_4, var_4_5)

	arg_4_0:nodeByName("txt_time"):setString(var_4_6)
	arg_4_0:nodeByName("txt_time"):enableOutline(cc.c4b(125, 66, 66, 255), 2)

	local var_4_7 = arg_4_0.battlePass:getPoint()
	local var_4_8 = string.format(var_0_1:translation("BATTLE_PASS_TEXT_2"), var_4_7, var_0_7)

	arg_4_0:nodeByName("txt_lv"):setString(arg_4_0.battlePass:getLevel())
	arg_4_0:nodeByName("txt_point"):setString(var_4_8)
	arg_4_0:nodeByName("bar"):setPercent(100 * var_4_7 / var_0_7)
	arg_4_0:updateImportantItem(arg_4_0:getNextImportantItem(arg_4_0:indexToLevel(arg_4_0.list:getEndIndex())))
	arg_4_0:initBtns()
end

function var_0_0.initBtns(arg_5_0)
	xyd.nodeEventSample(arg_5_0:nodeByName("btn_shop"), nil, function()
		xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadShopList({}, function()
			xyd.WindowManager.get():openWindow("battle_pass_shop", {
				shop_type = xyd.ShopType.BATTLE_PASS_SHOP
			})
		end)
	end)
	xyd.nodeEventSample(arg_5_0:nodeByName("btn_reward_view"), nil, function()
		xyd.WindowManager.get():openWindow("battle_pass_reward_view")
	end)
	xyd.nodeEventSample(arg_5_0:nodeByName("btn_add"), nil, function()
		arg_5_0.task:loadTaskByType(xyd.TaskType.CHALLENGE, function(arg_10_0)
			if arg_10_0 == xyd.error.OK then
				arg_5_0.task:setCurTaskType(xyd.TaskType.CHALLENGE)
				xyd.WindowManager.get():openWindow("task")
				arg_5_0:close()
			end
		end)
	end)
	xyd.nodeEventSample(arg_5_0:nodeByName("btn_buy_point"), nil, function()
		xyd.WindowManager.get():openWindow("battle_pass_buy_point")
	end)
	xyd.nodeEventSample(arg_5_0:nodeByName("btn_level_up"), nil, function()
		xyd.WindowManager.get():openWindow("battle_pass_buy_senior")
	end)
	xyd.nodeEventSample(arg_5_0:nodeByName("top_sidebar"):nodeByName("rule"), nil, function()
		local var_13_0 = {
			title_name = "BATTLE_PASS_RULE_TITLE",
			rule = "BATTLE_PASS_RULE_TEXT",
			style = xyd.RuleStyle.BLUE
		}

		xyd.WindowManager.get():openWindow("new_text_rule", var_13_0)
	end)
end

function var_0_0.updatePoint(arg_14_0)
	local var_14_0 = arg_14_0.battlePass:getPoint()
	local var_14_1 = string.format(var_0_1:translation("BATTLE_PASS_TEXT_2"), var_14_0, var_0_7)

	arg_14_0:nodeByName("txt_lv"):setString(arg_14_0.battlePass:getLevel())
	arg_14_0:nodeByName("txt_point"):setString(var_14_1)
	arg_14_0:nodeByName("bar"):setPercent(100 * var_14_0 / var_0_7)
	arg_14_0.list:refreshList()
end

function var_0_0.updateSenior(arg_15_0)
	if arg_15_0.battlePass:isBuySenior() then
		arg_15_0:nodeByName("lock"):setVisible(false)
	end

	arg_15_0.list:refreshList()
end

function var_0_0.getListShowNum(arg_16_0)
	if arg_16_0.battlePass:getLevel() < var_0_8 then
		return var_0_8
	else
		return var_0_8 + math.floor((arg_16_0.battlePass:getLevel() - var_0_8 + var_0_5) / var_0_5)
	end
end

function var_0_0.delegate(arg_17_0, arg_17_1, arg_17_2, arg_17_3)
	if arg_17_2 == cc.ui.UITableView.COUNT_TAG then
		return arg_17_0:getListShowNum()
	elseif arg_17_2 == cc.ui.UITableView.CELL_TAG then
		local var_17_0 = arg_17_0:indexToLevel(arg_17_3)

		if var_0_2:isImportant(var_17_0) == 1 and arg_17_0.list:getEndIndex() and arg_17_3 == arg_17_0.list:getEndIndex() + 1 then
			arg_17_0:updateImportantItem(arg_17_0:getNextImportantItem(var_17_0))
		end

		local var_17_1 = arg_17_0.list:getItem()
		local var_17_2 = arg_17_0:createContent(var_17_0)

		var_17_1:addContent(var_17_2)

		return var_17_1
	elseif arg_17_2 == cc.ui.UITableView.UNLOAD_CELL_TAG then
		local var_17_3 = arg_17_0:indexToLevel(arg_17_3)

		if var_0_2:isImportant(var_17_3) == 1 and arg_17_0.list:getEndIndex() and arg_17_3 == arg_17_0.list:getEndIndex() then
			arg_17_0:updateImportantItem(var_17_3)
		end
	end
end

function var_0_0.createContent(arg_18_0, arg_18_1)
	local var_18_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/battle_pass/reward_item.csb")
	local var_18_1 = var_18_0:getChildByName("bg")
	local var_18_2, var_18_3 = var_0_2:getItem(arg_18_1)
	local var_18_4, var_18_5 = var_0_2:getItem(arg_18_1, true)
	local var_18_6 = var_18_1:getChildByName("normal_container")

	if var_18_2 and var_18_2 ~= 0 then
		var_18_6:getChildByName("txt_lv"):setString("LV." .. arg_18_1)
		xyd.setItemAndAddTips(var_18_6:getChildByName("item"), var_18_2, var_18_3)

		if arg_18_1 <= arg_18_0.battlePass:getNormalLevel() then
			var_18_6:getChildByName("mask"):setVisible(true)
		elseif arg_18_1 <= arg_18_0.battlePass:getLevel() then
			local var_18_7 = var_18_6:getChildByName("btn")

			var_18_6:getChildByName("txt_lv"):setVisible(false)
			var_18_7:getChildByName("txt"):setString(var_0_1:translation("BATTLE_PASS_TEXT_8"))
			var_18_7:setVisible(true)
			var_18_7:addTouchEventListener(function(arg_19_0, arg_19_1)
				xyd.buttonScaleAnim(arg_19_0, arg_19_1)

				if arg_19_1 == ccui.TouchEventType.ended then
					arg_18_0.battlePass:getAward(nil, function(arg_20_0, arg_20_1)
						if arg_20_0 == xyd.error.OK then
							arg_18_0:handleRewards(arg_20_1.awards)
							arg_18_0.list:refreshList()
						end
					end)
				end
			end)
		end
	else
		var_18_6:setVisible(false)
	end

	local var_18_8 = var_18_1:getChildByName("senior_container")

	if var_18_4 and var_18_4 ~= 0 then
		var_18_8:getChildByName("txt_lv"):setString("LV." .. arg_18_1)
		xyd.setItemAndAddTips(var_18_8:getChildByName("item"), var_18_4, var_18_5)

		if not arg_18_0.battlePass:isBuySenior() then
			-- block empty
		elseif arg_18_1 <= arg_18_0.battlePass:getSeniorLevel() then
			var_18_8:getChildByName("mask"):setVisible(true)
		elseif arg_18_1 <= arg_18_0.battlePass:getLevel() then
			local var_18_9 = var_18_8:getChildByName("btn")

			var_18_8:getChildByName("txt_lv"):setVisible(false)
			var_18_9:getChildByName("txt"):setString(var_0_1:translation("BATTLE_PASS_TEXT_8"))
			var_18_9:setVisible(true)
			var_18_9:addTouchEventListener(function(arg_21_0, arg_21_1)
				xyd.buttonScaleAnim(arg_21_0, arg_21_1)

				if arg_21_1 == ccui.TouchEventType.ended then
					arg_18_0.battlePass:getAward(nil, function(arg_22_0, arg_22_1)
						if arg_22_0 == xyd.error.OK then
							arg_18_0:handleRewards(arg_22_1.awards)
							arg_18_0.list:refreshList()
						end
					end)
				end
			end)
		end
	else
		var_18_8:setVisible(false)
	end

	return var_18_0
end

function var_0_0.indexToLevel(arg_23_0, arg_23_1)
	if arg_23_1 > var_0_8 then
		return var_0_8 + (arg_23_1 - var_0_8) * var_0_5
	end

	return arg_23_1
end

function var_0_0.levelToIndex(arg_24_0, arg_24_1)
	if arg_24_1 > var_0_8 then
		return var_0_8 + math.floor((arg_24_1 - var_0_8) / var_0_5)
	end

	return arg_24_1
end

function var_0_0.getNextImportantItem(arg_25_0, arg_25_1)
	if arg_25_1 < var_0_6 then
		for iter_25_0 = arg_25_1 + 1, var_0_6 do
			if var_0_2:isImportant(iter_25_0) == 1 then
				return iter_25_0
			end
		end
	elseif var_0_2:isImportant(var_0_6) == 1 and arg_25_1 <= arg_25_0.battlePass:getLevel() then
		return var_0_6 + math.floor((arg_25_1 - var_0_6 + var_0_5) / var_0_5) * var_0_5
	end
end

function var_0_0.updateImportantItem(arg_26_0, arg_26_1)
	arg_26_0:nodeByName("normal_core_icon"):removeAllChildren()
	arg_26_0:nodeByName("senior_core_icon"):removeAllChildren()

	if not arg_26_1 then
		arg_26_0:nodeByName("txt_normal_core_lv"):setString("")
		arg_26_0:nodeByName("txt_senior_core_lv"):setString("")

		return
	end

	local var_26_0, var_26_1 = var_0_2:getItem(arg_26_1)
	local var_26_2, var_26_3 = var_0_2:getItem(arg_26_1, true)

	if var_26_0 and var_26_0 ~= 0 then
		arg_26_0:nodeByName("txt_normal_core_lv"):setString("LV." .. arg_26_1)
		xyd.setItemAndAddTips(arg_26_0:nodeByName("normal_core_icon"), var_26_0, var_26_1)
	else
		arg_26_0:nodeByName("txt_normal_core_lv"):setString("")
	end

	if var_26_2 and var_26_2 ~= 0 then
		arg_26_0:nodeByName("txt_senior_core_lv"):setString("LV." .. arg_26_1)
		xyd.setItemAndAddTips(arg_26_0:nodeByName("senior_core_icon"), var_26_2, var_26_3)
	else
		arg_26_0:nodeByName("txt_senior_core_lv"):setString("")
	end
end

function var_0_0.scrollListener(arg_27_0, arg_27_1)
	if arg_27_1.name == "began" then
		arg_27_0.scrollViewMoved_ = false
		arg_27_0.prevX_ = arg_27_1.x
	elseif arg_27_1.name == "moved" and 5 <= math.abs(arg_27_1.x - arg_27_0.prevX_) then
		arg_27_0.scrollViewMoved_ = true
	end
end

function var_0_0.handleRewards(arg_28_0, arg_28_1)
	local var_28_0 = arg_28_0.selfPlayer:handleRewardsWithoutShow(arg_28_1)

	if var_28_0 and next(var_28_0) then
		local var_28_1 = var_28_0[1]

		if var_28_1.is_partner then
			local var_28_2 = {
				toStone = false,
				partnerID = var_28_1.table_id
			}
			local var_28_3 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_28_2)

			cc.EventProxy.new(var_28_3, var_28_3):addEventListener(xyd.event.SUMMON_HERO_CLOSE, function()
				xyd.WindowManager.get():openWindow("battle_pass_get_reward", arg_28_1)
			end)
		elseif var_28_1.to_stone then
			local var_28_4 = {
				partnerID = xyd.tables.item:heroID(var_28_1.table_id),
				toStone = tonumber(var_28_1.item_num)
			}
			local var_28_5 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_28_4)

			cc.EventProxy.new(var_28_5, var_28_5):addEventListener(xyd.event.SUMMON_HERO_CLOSE, function()
				xyd.WindowManager.get():openWindow("battle_pass_get_reward", arg_28_1)
			end)
		end
	else
		xyd.WindowManager.get():openWindow("battle_pass_get_reward", arg_28_1)
	end
end

return var_0_0
