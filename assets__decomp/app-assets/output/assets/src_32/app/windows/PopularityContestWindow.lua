local var_0_0 = class("PopularityContestWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.model
local var_0_3 = xyd.tables.activityVotePartner
local var_0_4 = xyd.tables.activityVoteTicket
local var_0_5 = xyd.tables.activityVoteTimeline
local var_0_6 = import("app.common.ui.SpineEffect")
local var_0_7 = require("framework.scheduler")
local var_0_8 = 3

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.popularContest = xyd.ModelManager.get():loadModel(xyd.ModelType.POPULARITY_CONTEST)
	arg_1_0.rankItems_ = {}
	arg_1_0.rankItemModels_ = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	local var_2_0 = arg_2_0.popularContest:getStage()

	arg_2_0.isShowSuper = var_0_5:isShowSuper(var_2_0)

	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
end

function var_0_0.layout(arg_4_0)
	arg_4_0.rankItemsPos_ = {}

	for iter_4_0 = 1, var_0_8 do
		table.insert(arg_4_0.rankItemsPos_, cc.p(arg_4_0:nodeByName("pos_" .. iter_4_0):getPosition()))
	end

	arg_4_0:setupButton()
	arg_4_0:initList()
	arg_4_0:updateTimeCount()
	arg_4_0:playLightEffect()
	arg_4_0:nodeByName("text_time"):enableOutline(cc.c4b(85, 137, 243, 255), 2)
end

function var_0_0.playWinnerAction(arg_5_0)
	if arg_5_0.winnerModel and not tolua.isnull(arg_5_0.winnerModel) then
		arg_5_0.winnerModel:win(false, function()
			arg_5_0.winnerModel:idle()
		end)
	end
end

function var_0_0.setupButton(arg_7_0)
	arg_7_0:nodeByName("btn_race"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			local var_8_0 = arg_7_0.popularContest:getStage()
			local var_8_1 = ""

			if var_8_0 == 0 then
				local var_8_2 = var_0_1:translation("VOTE_RACE_TIPS_1")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_8_2
				})

				return
			elseif var_8_0 >= 4 then
				local var_8_3 = var_0_1:translation("VOTE_RACE_TIPS_2")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_8_3
				})

				return
			end

			local var_8_4 = {}

			xyd.WindowManager.get():openWindow("popularity_race_wnd", var_8_4)
		end
	end)
	arg_7_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			local var_9_0 = {
				title_name = "VOTE_RULE_TITLE",
				rule = "VOTE_RULE_TEXT",
				hasOtherItem = true,
				otherItemType = xyd.TextRuleItemType.Popularity
			}

			xyd.WindowManager.get():openWindow("text_rule", var_9_0)
		end
	end)
end

function var_0_0.updateTimeCount(arg_10_0)
	if arg_10_0.handle_ then
		var_0_7.unscheduleGlobal(arg_10_0.handle_)
	end

	local var_10_0 = xyd.ServerTime.get():getServerTime()
	local var_10_1 = ""
	local var_10_2 = 0

	if var_10_0 < arg_10_0.popularContest.startTime then
		var_10_2 = arg_10_0.popularContest.startTime - var_10_0
		var_10_1 = var_0_1:translation("VOTE_RACE_TIPS_3")
	else
		var_10_2 = arg_10_0.popularContest.endTime - var_10_0
		var_10_1 = var_0_1:translation("ACTIVITY_END_TIME")
	end

	if var_10_2 <= 0 then
		arg_10_0:nodeByName("text_time"):setString(var_10_1 .. "00:00:00")

		return
	end

	local function var_10_3(arg_11_0)
		if arg_11_0 > 86400 then
			return xyd.secondsToString1(arg_11_0, 3)
		end

		return xyd.secondsToString(arg_11_0)
	end

	arg_10_0:nodeByName("text_time"):setString(var_10_1 .. var_10_3(var_10_2))

	arg_10_0.handle_ = var_0_7.scheduleGlobal(function()
		if arg_10_0 and not tolua.isnull(arg_10_0) then
			var_10_2 = var_10_2 - 1

			arg_10_0:nodeByName("text_time"):setString(var_10_1 .. var_10_3(var_10_2))

			if var_10_2 == 0 then
				if arg_10_0.handle_ then
					var_0_7.unscheduleGlobal(arg_10_0.handle_)

					arg_10_0.handle_ = nil
				end

				arg_10_0.popularContest:loadInfo(function(arg_13_0, arg_13_1)
					if arg_13_0 == xyd.error.OK then
						arg_10_0:updateTimeCount()
					end
				end)
			end
		elseif arg_10_0.handle_ then
			var_0_7.unscheduleGlobal(arg_10_0.handle_)

			arg_10_0.handle_ = nil
		end
	end, 1)
end

function var_0_0.willClose(arg_14_0)
	if arg_14_0.handle_ then
		var_0_7.unscheduleGlobal(arg_14_0.handle_)

		arg_14_0.handle_ = nil
	end
end

function var_0_0.initList(arg_15_0)
	local var_15_0 = arg_15_0:nodeByName("list")

	var_15_0:removeAllChildren()

	arg_15_0.rankItems_ = {}

	local var_15_1 = arg_15_0.popularContest:getPollInfo()

	for iter_15_0 = 1, var_0_8 do
		local var_15_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/popularity_contest/rank_item_1.csb")

		var_15_2:addTo(var_15_0)

		local var_15_3 = arg_15_0.rankItemsPos_[iter_15_0]
		local var_15_4 = var_15_2:getChildByName("container"):getContentSize()

		var_15_2:setPosition(cc.p(var_15_3.x - var_15_4.width / 2, var_15_3.y - var_15_4.height / 2 + 20))

		arg_15_0.rankItems_[iter_15_0] = var_15_2

		arg_15_0:updateRankItem(iter_15_0, var_15_1[iter_15_0])
	end

	arg_15_0:playWinnerAction()
end

function var_0_0.updateRankItem(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = arg_16_0.rankItems_[arg_16_1]

	if not var_16_0 or tolua.isnull(var_16_0) then
		return
	end

	local var_16_1 = var_16_0:getChildByName("container")
	local var_16_2 = var_16_1:getChildByName("top")
	local var_16_3 = var_16_1:getChildByName("btn_detail")

	var_16_1:getChildByName("hero"):removeAllChildren()
	var_16_2:getChildByName("text_ticket"):enableOutline(cc.c4b(124, 71, 230, 255), 2)

	local var_16_4 = cc.p(var_16_2:getChildByName("ticket_num_node"):getPosition())
	local var_16_5 = xyd.AssetLoader.get():loadLabel(nil, "popular_font")

	var_16_5:setString(arg_16_2.vote_num)
	var_16_5:setAnchorPoint(cc.p(0.5, 0.5))
	var_16_5:setScale(1)
	var_16_5:addTo(var_16_2)
	var_16_5:setPosition(cc.p(var_16_4.x, var_16_4.y - 2))

	local var_16_6 = var_16_5:getContentSize()

	var_16_2:getChildByName("text_ticket"):setPositionX(var_16_4.x + 20 + var_16_6.width / 2)

	local var_16_7 = cc.p(var_16_2:getChildByName("rank_pos"):getPosition())
	local var_16_8 = xyd.AssetLoader.get():loadSprite("windows/popularity_contest/main_wnd/rank_" .. arg_16_1 .. ".png")

	var_16_8:addTo(var_16_2)
	var_16_8:setAnchorPoint(cc.p(0.5, 0.5))
	var_16_8:setPosition(cc.p(var_16_7))

	if arg_16_1 == 1 then
		local var_16_9 = var_16_2:getPositionY()

		var_16_2:setPositionY(var_16_9 + 20)
		var_16_2:getChildByName("rank_bg_2"):setVisible(false)
	else
		var_16_2:getChildByName("rank_bg_1"):setVisible(false)
	end

	local var_16_10, var_16_11, var_16_12 = arg_16_0.popularContest:getShowModel(arg_16_0.isShowSuper, arg_16_2)
	local var_16_13 = var_0_3:modelName(arg_16_2.table_id)
	local var_16_14 = xyd.HeroAnimation.new(nil, var_16_10, var_0_2:uiScale(var_16_10), {})

	if var_16_14 then
		var_16_14:idle()
	end

	var_16_14:addTo(var_16_1:getChildByName("hero"))

	local var_16_15 = var_16_1:getChildByName("hero"):getContentSize()

	var_16_14:setPosition(cc.p(var_16_15.width / 2, 0))
	var_16_14:setScale(0.9)

	if arg_16_1 == 1 then
		arg_16_0.winnerModel = var_16_14
	end

	arg_16_0.rankItemModels_[arg_16_1] = var_16_14

	var_16_3:getChildByName("text_name"):setString(xyd.tables.hero:name(arg_16_2.table_id))
	var_16_3:getChildByName("text_name"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_16_3:getChildByName("text_type"):setString(var_16_13[var_16_12])
	var_16_3:addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.began then
			arg_17_0:setScale(0.9)
		elseif arg_17_1 == ccui.TouchEventType.ended then
			arg_17_0:setScale(1)
			arg_16_0.popularContest:getPollPlayerRankList(arg_16_2.table_id, function(arg_18_0, arg_18_1)
				if arg_18_0 == xyd.error.OK then
					local var_18_0 = {
						table_id = arg_16_2.table_id
					}

					if arg_18_1 and next(arg_18_1) then
						var_18_0.my_rank_info = arg_18_1.my_rank_info or {}
						var_18_0.rank_list = arg_18_1.rank_list or {}
					end

					xyd.WindowManager.get():openWindow("popularity_vote_rank", var_18_0)
				end
			end)
		end
	end)
end

function var_0_0.playLightEffect(arg_19_0, arg_19_1)
	local var_19_0 = "skeletons/ui_effect/activity_vote_box/activity_vote_light"
	local var_19_1 = arg_19_0:nodeByName("light"):getContentSize()
	local var_19_2 = cc.p(var_19_1.width / 2, var_19_1.height / 2 + 80)

	arg_19_0.lightEffcet = arg_19_0:createEffect(var_19_0, arg_19_0:nodeByName("light"), var_19_2, 1)

	arg_19_0.lightEffcet:play(arg_19_1, true)
end

function var_0_0.createEffect(arg_20_0, arg_20_1, arg_20_2, arg_20_3, arg_20_4)
	local var_20_0 = arg_20_4 or 1
	local var_20_1 = var_0_6.new(arg_20_1 .. ".json", arg_20_1 .. ".atlas", var_20_0)

	var_20_1:addTo(arg_20_2)
	var_20_1:setPosition(arg_20_3)

	return var_20_1
end

return var_0_0
