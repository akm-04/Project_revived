local var_0_0 = class("OccultBattleResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.occult = xyd.ModelManager.get():loadModel(xyd.ModelType.OCCULT)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.awards = arg_1_2.awards or {}
	arg_1_0.awardDetail = arg_1_2.award_detail
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer(cc.c4b(0, 0, 0, 255), true)
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("award_text"):setString(var_0_1:translation("MISSION_TEXT"))
	arg_3_0:nodeByName("remain_time_text"):setString(var_0_1:translation("TEAM_DRINK_LEFT_TIME"))
	arg_3_0:nodeByName("score_text"):setString(var_0_1:translation("OCCULT_SCORE_TEXT"))
	arg_3_0:nodeByName("extra_text"):setString(var_0_1:translation("EXTRA_MARK_ON_TEXT"))
	arg_3_0:nodeByName("battle_progress_text"):setString(var_0_1:translation("BATTLE_WIN_JINDU"))
	arg_3_0:nodeByName("jinbi"):setVisible(false)
	arg_3_0:nodeByName("mana_num_txt"):setVisible(false)
	arg_3_0:nodeByName("extra_txt"):setString(arg_3_0.awardDetail.extra_point)
	arg_3_0:nodeByName("score_txt"):setString(arg_3_0.awardDetail.point)

	if arg_3_0.awardDetail.is_close == 0 then
		arg_3_0:nodeByName("remain_time_txt"):setString("0:0")
	elseif arg_3_0.awardDetail.is_close == 1 and arg_3_0.awardDetail.close_time then
		local var_3_0 = xyd.tables.misc.creatsCampaignDuration - (arg_3_0.awardDetail.close_time - arg_3_0.awardDetail.start_time)

		if var_3_0 < 0 then
			var_3_0 = 0
		end

		arg_3_0:nodeByName("remain_time_txt"):setString(xyd.secondsToString(var_3_0))
	end

	if not arg_3_0.awardDetail.progress then
		arg_3_0.awardDetail.progress = 0
	end

	arg_3_0:nodeByName("progress_txt"):setString(tostring(math.floor(arg_3_0.awardDetail.progress * 100)) .. "%")
	arg_3_0:nodeByName("progress_bar"):setPercent(math.floor(arg_3_0.awardDetail.progress * 100))

	arg_3_0.scroll = arg_3_0:nodeByName("item_scroll")

	local var_3_1 = arg_3_0.scroll:getContentSize()

	arg_3_0.itemList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_3_0.scroll):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.itemList:setBounceable(false)
	arg_3_0.itemList:setDelegate(handler(arg_3_0, arg_3_0.itemListDelegate))
	arg_3_0.itemList:setTouchType(false)
	arg_3_0.itemList:reload()
	arg_3_0:setButtonClick()

	local var_3_2 = xyd.createEffect("skeletons/ui_effect/battle_end/win_light")

	var_3_2:addTo(arg_3_0:nodeByName("effect_pos"))
	var_3_2:play(nil, true, nil, "texiao02")

	local var_3_3 = xyd.createEffect("skeletons/ui_effect/battle_end/win_star")

	var_3_3:addTo(arg_3_0:nodeByName("effect_pos"))
	var_3_3:play(nil, true, nil, "texiao05")
end

function var_0_0.setButtonClick(arg_4_0)
	arg_4_0:nodeByName("button_return"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
end

function var_0_0.itemListDelegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return #arg_6_0.awards
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_0
		local var_6_1 = arg_6_0.itemList:dequeueItem()

		if not var_6_1 then
			var_6_1 = arg_6_0.itemList:newItem()
		else
			var_6_1:removeAllChildren(true)
		end

		local var_6_2 = arg_6_0:createListContent(arg_6_0.awards[arg_6_3])
		local var_6_3 = var_6_2:getWidth()
		local var_6_4 = var_6_2:getHeight()

		var_6_1:setItemSize(var_6_3 + 28, var_6_4)
		var_6_1:addContent(var_6_2)

		return var_6_1
	end
end

function var_0_0.createListContent(arg_7_0, arg_7_1)
	local var_7_0 = display.newNode()

	var_7_0:setContentSize(90, 90)
	xyd.setItemAndAddTips(var_7_0, arg_7_1.table_id, arg_7_1.item_num)

	return var_7_0
end

function var_0_0.scrollListener(arg_8_0, arg_8_1)
	if arg_8_1.name == "began" then
		arg_8_0.scrollViewMoved_ = false
		arg_8_0.prevY_ = arg_8_1.y
	elseif arg_8_1.name == "moved" and 5 <= math.abs(arg_8_1.y - arg_8_0.prevY_) then
		arg_8_0.scrollViewMoved_ = true
	end
end

return var_0_0
