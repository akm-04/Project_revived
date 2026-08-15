local var_0_0 = class("SummerQuizResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = "skeletons/ui_effect/summer/zhiparticle_texture"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.summer = xyd.ModelManager.get():loadModel(xyd.ModelType.SUMMER)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backPack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.bigPassInfo = arg_1_0.summer.details.big_pass_info
	arg_1_0.fightResponse = arg_1_0.summer.fightResponse
	arg_1_0.awards = arg_1_0.fightResponse.awards
	arg_1_0.rank = arg_1_0.fightResponse.rank
	arg_1_0.summer.fightResponse = nil
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("cost_time_text"):setString(var_0_1:translation("QUIZ_COST_TIME_TEXT"))

	local var_3_0 = math.floor(arg_3_0.bigPassInfo.finish_time)
	local var_3_1 = math.floor((arg_3_0.bigPassInfo.finish_time - var_3_0) * 100)

	if var_3_1 < 10 then
		var_3_1 = "0" .. var_3_1
	end

	arg_3_0:nodeByName("cost_time_txt"):setString(os.date("%M'%S''", var_3_0) .. tostring(var_3_1))
	arg_3_0:nodeByName("reward_text"):setString(var_0_1:translation("QUIZ_AWARD_TEXT"))
	arg_3_0:nodeByName("end_rank_text"):setString(var_0_1:translation("QUIZ_END_RANK_TEXT"))

	local var_3_2 = cc.ParticleSystemQuad:create(var_0_2 .. ".plist")

	var_3_2:addTo(arg_3_0:nodeByName("container"))
	var_3_2:setPosition(cc.p(300, 587))
	arg_3_0:nodeByName("rank_text"):setString(arg_3_0.rank)

	arg_3_0.scroll = arg_3_0:nodeByName("reward_scroll")

	local var_3_3 = arg_3_0.scroll:getContentSize()

	arg_3_0.scrollList = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_3_3.width, var_3_3.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_3_0.scroll):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.scrollList:setBounceable(true)
	arg_3_0:updateAwardScroll()
	arg_3_0:setButtonClick()
end

function var_0_0.updateAwardScroll(arg_4_0)
	for iter_4_0 = 1, #arg_4_0.awards do
		local var_4_0
		local var_4_1 = arg_4_0.scrollList:dequeueItem()

		if not var_4_1 then
			var_4_1 = arg_4_0.scrollList:newItem()
		else
			var_4_1:removeAllChildren(true)
		end

		local var_4_2 = arg_4_0:createListContent(iter_4_0)
		local var_4_3 = var_4_2:getWidth()
		local var_4_4 = var_4_2:getHeight()

		var_4_1:setItemSize(var_4_3, var_4_4)
		var_4_1:addContent(var_4_2)
		arg_4_0.scrollList:addItem(var_4_1)
		arg_4_0.scrollList:reload()
	end
end

function var_0_0.createListContent(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_0.awards[arg_5_1]
	local var_5_1 = display.newNode()

	var_5_1:setContentSize(100, 100)
	xyd.setItemBorder(var_5_1, var_5_0.table_id, nil, nil, var_5_0.item_num)

	if var_5_0.table_id > 0 then
		local var_5_2 = {
			itemID = var_5_0.table_id,
			itemNum = var_5_0.item_num
		}

		arg_5_0.backPack:addItem(var_5_2)
	end

	return var_5_1
end

function var_0_0.setButtonClick(arg_6_0)
	arg_6_0:nodeByName("rank_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_7_0, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_7_0 = {}

			arg_6_0.summer:getQuizRankList(var_7_0, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("summer_quiz_rank")
				end
			end)
		end
	end)
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
