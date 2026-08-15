local var_0_0 = class("PopularityRaceWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.model
local var_0_3 = xyd.tables.hero
local var_0_4 = xyd.tables.activityVotePartner
local var_0_5 = xyd.tables.activityVoteTicket
local var_0_6 = xyd.tables.activityVoteTimeline
local var_0_7 = require("framework.scheduler")
local var_0_8 = 6

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.popularContest = xyd.ModelManager.get():loadModel(xyd.ModelType.POPULARITY_CONTEST)
	arg_1_0.preChampionNum = 0
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	local var_2_0 = arg_2_0:nodeByName("btn_restore"):getContentSize()

	arg_2_0.restoreInitPosX = arg_2_0:nodeByName("btn_restore"):getPositionX() - var_2_0.width / 2

	arg_2_0:initList()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:refreshHeroList()
end

function var_0_0.refreshHeroList(arg_4_0)
	arg_4_0:selectHeros()
	arg_4_0.heroList_:reload()

	if arg_4_0.preChampionNum > 0 then
		arg_4_0.heroList_:getScrollNode():setPositionX(-arg_4_0.preChampionNum * 190)
	end
end

function var_0_0.selectHeros(arg_5_0)
	arg_5_0.preChampionNum = 0

	if arg_5_0.isSearch and arg_5_0.searchHero and next(arg_5_0.searchHero) then
		local var_5_0 = clone(arg_5_0.searchHero)

		if var_0_4:isPreChampion(arg_5_0.searchHero.table_id) then
			var_5_0.is_champion = true
		end

		arg_5_0.datas_ = {
			var_5_0
		}
	else
		arg_5_0.datas_ = arg_5_0:getPollInfo()

		local var_5_1 = arg_5_0.popularContest:getStartPos()
		local var_5_2 = arg_5_0.popularContest:getOrder()

		if var_5_1 == 1 and var_5_2 == xyd.PopularityShowOrder.DOWN then
			local var_5_3 = var_0_4:getAllPreChampion()

			arg_5_0.preChampionNum = #var_5_3

			for iter_5_0 = 1, #var_5_3 do
				local var_5_4 = {
					is_champion = true,
					table_id = var_5_3[iter_5_0]
				}

				table.insert(arg_5_0.datas_, 1, var_5_4)
			end
		end
	end
end

function var_0_0.getPollInfo(arg_6_0)
	local var_6_0 = clone(arg_6_0.popularContest:getPollInfo() or {})

	for iter_6_0 = #var_6_0, 1, -1 do
		if var_0_4:isPreChampion(var_6_0[iter_6_0].table_id) then
			table.remove(var_6_0, iter_6_0)
		end
	end

	return var_6_0
end

function var_0_0.layout(arg_7_0)
	arg_7_0:setupButton()
	arg_7_0:nodeByName("load_tip_left"):setVisible(false)
	arg_7_0:nodeByName("load_tip_right"):setVisible(false)

	local var_7_0 = arg_7_0.popularContest:getStage()

	arg_7_0.isShowSuper = var_0_6:isShowSuper(var_7_0)
	arg_7_0.isChooseFav = var_0_6:isChooseFav(var_7_0)

	local var_7_1 = cc.p(arg_7_0:nodeByName("pos_title"):getPosition())

	if var_7_0 and var_7_0 > 0 and var_7_0 <= 3 then
		local var_7_2 = xyd.AssetLoader.get():loadSprite("windows/popularity_contest/race_wnd/title_" .. var_7_0 .. ".png")

		var_7_2:addTo(arg_7_0:nodeByName("container"))
		var_7_2:setPosition(cc.p(var_7_1.x, var_7_1.y))
	end

	if var_7_0 < 4 then
		arg_7_0:updateTimeCount(var_7_0)
	end
end

function var_0_0.setupButton(arg_8_0)
	arg_8_0:nodeByName("btn_timeline"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.began then
			arg_9_0:setScale(0.9)
		elseif arg_9_1 == ccui.TouchEventType.ended then
			arg_9_0:setScale(1)
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("popularity_schedule")
		end
	end)

	local function var_8_0()
		if arg_8_0.popularContest:getOrder() == xyd.PopularityShowOrder.DOWN then
			arg_8_0:nodeByName("icon_sort_down"):setVisible(true)
			arg_8_0:nodeByName("icon_sort_up"):setVisible(false)
		else
			arg_8_0:nodeByName("icon_sort_up"):setVisible(true)
			arg_8_0:nodeByName("icon_sort_down"):setVisible(false)
		end
	end

	var_8_0()
	arg_8_0:nodeByName("btn_sort"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.began then
			arg_11_0:setScale(0.9)
		elseif arg_11_1 == ccui.TouchEventType.ended then
			arg_11_0:setScale(1)
			xyd.playButtonSound()
			arg_8_0.popularContest:setOrder()
			arg_8_0.popularContest:getPollList(xyd.PopularityLoadDataType.NONE, function(arg_12_0, arg_12_1)
				if arg_12_0 == xyd.error.OK then
					arg_8_0:refreshHeroList()
				else
					arg_8_0.popularContest:setOrder()
				end

				var_8_0()
			end)
		end
	end)
	arg_8_0:nodeByName("close"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_8_0.popularContest:setOrder(xyd.PopularityShowOrder.DOWN)

			arg_8_0.isLoadData = xyd.PopularityLoadDataType.NONE

			arg_8_0:getNewRankList(function(arg_14_0, arg_14_1)
				if arg_14_0 == xyd.error.OK then
					local var_14_0 = xyd.WindowManager.get():getWindow("popularity_contest")

					if var_14_0 and not tolua.isnull(var_14_0) then
						var_14_0:initList()
					end
				end

				xyd.WindowManager.get():closeWindow(arg_8_0)
			end)
		end
	end)
	arg_8_0:nodeByName("btn_search"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.began then
			arg_15_0:setScale(0.9)
		elseif arg_15_1 == ccui.TouchEventType.ended then
			arg_15_0:setScale(1)
			xyd.playButtonSound()
			arg_8_0:showSearchWnd(true)
		end
	end)
	arg_8_0:updateBtnRestore()
end

function var_0_0.updateBtnRestore(arg_16_0)
	if arg_16_0.isSearch then
		arg_16_0:nodeByName("btn_restore"):setVisible(true)
	else
		arg_16_0:nodeByName("btn_restore"):setVisible(false)
		arg_16_0:nodeByName("panel_function"):setPositionX(903)

		return
	end

	local var_16_0 = var_0_3:name(arg_16_0.searchHero.table_id)

	arg_16_0:nodeByName("text_hero_name"):setString(var_16_0)
	arg_16_0:nodeByName("text_hero_name"):enableOutline(cc.c4b(85, 137, 243, 255), 2)

	local var_16_1 = arg_16_0:nodeByName("text_hero_name"):getContentSize()

	arg_16_0:nodeByName("btn_restore"):setContentSize(var_16_1.width + 50, 61)
	arg_16_0:nodeByName("img_close"):setPositionX(var_16_1.width + 5)
	arg_16_0:nodeByName("btn_restore"):setPositionX(arg_16_0.restoreInitPosX + (var_16_1.width + 50) / 2)
	arg_16_0:nodeByName("btn_restore"):addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.began then
			arg_17_0:setScale(0.9)
		elseif arg_17_1 == ccui.TouchEventType.ended then
			arg_17_0:setScale(1)
			xyd.playButtonSound()
			arg_16_0:getNewRankList(function(arg_18_0, arg_18_1)
				if arg_18_0 == xyd.error.OK and arg_16_0 and not tolua.isnull(arg_16_0) then
					arg_16_0.isSearch = false

					arg_16_0:updateBtnRestore()
					arg_16_0:refreshHeroList()
				end
			end)
		end
	end)

	local var_16_2 = arg_16_0:nodeByName("panel_function"):getPositionX()

	arg_16_0:nodeByName("panel_function"):setPositionX(903.47 - var_16_1.width - 50)
end

function var_0_0.updateTimeCount(arg_19_0, arg_19_1)
	if arg_19_0.handle_ then
		var_0_7.unscheduleGlobal(arg_19_0.handle_)
	end

	local function var_19_0(arg_20_0)
		if arg_20_0 > 86400 then
			return xyd.secondsToString1(arg_20_0, 2)
		end

		return xyd.secondsToString(arg_20_0)
	end

	local var_19_1 = var_0_6:des(arg_19_1)
	local var_19_2 = arg_19_0.popularContest:getStageEndtime() - xyd.ServerTime.get():getServerTime()

	arg_19_0:nodeByName("text_time"):setString(string.format(var_19_1, var_19_0(var_19_2)))

	arg_19_0.handle_ = var_0_7.scheduleGlobal(function()
		if arg_19_0 and not tolua.isnull(arg_19_0) then
			var_19_2 = var_19_2 - 1

			arg_19_0:nodeByName("text_time"):setString(string.format(var_19_1, var_19_0(var_19_2)))

			if var_19_2 == 0 then
				arg_19_0:updateBtnType()

				if arg_19_0.handle_ then
					var_0_7.unscheduleGlobal(arg_19_0.handle_)

					arg_19_0.handle_ = nil
				end
			end
		elseif arg_19_0.handle_ then
			var_0_7.unscheduleGlobal(arg_19_0.handle_)

			arg_19_0.handle_ = nil
		end
	end, 1)
end

function var_0_0.willClose(arg_22_0)
	if arg_22_0.handle_ then
		var_0_7.unscheduleGlobal(arg_22_0.handle_)

		arg_22_0.handle_ = nil
	end
end

function var_0_0.initList(arg_23_0)
	local var_23_0 = arg_23_0:nodeByName("list")
	local var_23_1 = var_23_0:getContentSize().width
	local var_23_2 = var_23_0:getContentSize().height

	arg_23_0.heroList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_23_1, var_23_2),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_23_0):onScroll(handler(arg_23_0, arg_23_0.scrollListener))

	arg_23_0.heroList_:setDelegate(handler(arg_23_0, arg_23_0.delegate))
end

function var_0_0.scrollListener(arg_24_0, arg_24_1)
	if arg_24_1.name == "began" then
		arg_24_0:nodeByName("load_tip_left"):setVisible(false)
		arg_24_0:nodeByName("load_tip_right"):setVisible(false)

		arg_24_0.isLoadData = xyd.PopularityLoadDataType.NONE
		arg_24_0.scrollViewMoved_ = false
		arg_24_0.prevX_ = arg_24_1.x
	elseif arg_24_1.name == "moved" then
		if 10 <= math.abs(arg_24_1.x - arg_24_0.prevX_) then
			arg_24_0.scrollViewMoved_ = true
		end

		local var_24_0 = arg_24_0.heroList_:getScrollNode()

		if arg_24_1.x - arg_24_0.prevX_ > 0 then
			if var_24_0:getPositionX() > 25 then
				arg_24_0:nodeByName("load_tip_left"):setVisible(true)

				arg_24_0.isLoadData = xyd.PopularityLoadDataType.FRONT
			else
				arg_24_0:nodeByName("load_tip_left"):setVisible(false)

				arg_24_0.isLoadData = xyd.PopularityLoadDataType.NONE
			end
		elseif arg_24_1.x - arg_24_0.prevX_ < 0 then
			if -var_24_0:getPositionX() > (#arg_24_0.datas_ - var_0_8) * 190 + 25 then
				arg_24_0:nodeByName("load_tip_right"):setVisible(true)

				arg_24_0.isLoadData = xyd.PopularityLoadDataType.BACK
			else
				arg_24_0:nodeByName("load_tip_right"):setVisible(false)

				arg_24_0.isLoadData = xyd.PopularityLoadDataType.NONE
			end
		end
	elseif arg_24_1.name == "scrollEnd" and arg_24_0.isLoadData ~= xyd.PopularityLoadDataType.NONE then
		arg_24_0:nodeByName("load_tip_left"):setVisible(false)
		arg_24_0:nodeByName("load_tip_right"):setVisible(false)
		arg_24_0:getNewRankList()
	end
end

function var_0_0.getNewRankList(arg_25_0, arg_25_1)
	local var_25_0 = arg_25_0.isLoadData
	local var_25_1 = arg_25_0.popularContest:getStartPos()
	local var_25_2 = false

	if var_25_1 == 1 then
		var_25_2 = true
	end

	arg_25_0.popularContest:getPollList(var_25_0, function(arg_26_0, arg_26_1)
		if arg_26_0 == xyd.error.OK and arg_25_0 and not tolua.isnull(arg_25_0) and not arg_25_1 then
			arg_25_0:refreshHeroList()

			if var_25_0 == xyd.PopularityLoadDataType.FRONT and not var_25_2 then
				arg_25_0.heroList_:getScrollNode():setPositionX(-(#arg_25_0.datas_ - 6) * 190)
			end
		end

		if arg_25_1 then
			arg_25_1(arg_26_0, arg_26_1)
		end
	end)

	arg_25_0.isLoadData = xyd.PopularityLoadDataType.NONE
end

function var_0_0.delegate(arg_27_0, arg_27_1, arg_27_2, arg_27_3)
	local var_27_0 = #arg_27_0.datas_

	if cc.ui.UIListView.COUNT_TAG == arg_27_2 then
		return var_27_0
	elseif cc.ui.UIListView.CELL_TAG == arg_27_2 then
		local var_27_1
		local var_27_2
		local var_27_3
		local var_27_4 = arg_27_0.heroList_:dequeueItem()

		if not var_27_4 then
			var_27_4 = arg_27_0.heroList_:newItem()
		else
			var_27_4:removeAllChildren()
		end

		local var_27_5 = display.newNode()

		var_27_5:setTouchSwallowEnabled(false)

		local var_27_6 = display.newNode()

		arg_27_0:initHeroCell(var_27_6, arg_27_3)

		local var_27_7 = var_27_6:getContentSize().width
		local var_27_8 = var_27_6:getContentSize().height

		var_27_5:addChild(var_27_6)
		var_27_5:setContentSize(cc.size(var_27_6:getContentSize().width + 10, arg_27_0.heroList_.viewRect_.height))
		var_27_4:setItemSize(var_27_6:getContentSize().width + 10, arg_27_0.heroList_.viewRect_.height)
		var_27_4:addContent(var_27_5)

		return var_27_4
	end
end

function var_0_0.initHeroCell(arg_28_0, arg_28_1, arg_28_2)
	local var_28_0 = arg_28_0.datas_[arg_28_2]
	local var_28_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/popularity_contest/race_item.csb")

	var_28_1:addTo(arg_28_1)

	local var_28_2 = var_28_1:getChildByName("container")
	local var_28_3 = var_28_2:getContentSize()

	arg_28_1:setContentSize(var_28_3)

	if var_28_0.is_champion then
		arg_28_0:initChampionCell(var_28_2, var_28_0)

		return
	end

	local var_28_4, var_28_5, var_28_6 = arg_28_0.popularContest:getShowModel(arg_28_0.isShowSuper, var_28_0)
	local var_28_7 = var_0_4:models(var_28_0.table_id)
	local var_28_8 = var_0_4:modelName(var_28_0.table_id)
	local var_28_9 = var_0_4:canVote(var_28_0.table_id)

	var_28_2:getChildByName("text_name"):setString(var_0_3:name(var_28_0.table_id))
	var_28_2:getChildByName("text_type"):setString(var_28_8[var_28_6])
	var_28_2:getChildByName("text_ticket_num"):setString(var_28_0.vote_num)
	arg_28_0:updateItemRank(var_28_2, var_28_0.display_rank)
	arg_28_0:updateHeroCard(var_28_2, var_28_4, var_28_0.table_id)

	local var_28_10 = var_28_2:getChildByName("gift_icon")

	if var_28_0.gift_pool > 0 then
		var_28_10:getChildByName("text_gift_num"):setString(var_28_0.gift_pool)
	else
		var_28_10:setVisible(false)
	end

	var_28_2:getChildByName("btn_vote"):addTouchEventListener(function(arg_29_0, arg_29_1)
		if arg_29_1 == ccui.TouchEventType.began then
			arg_29_0:setScale(0.9)
		elseif arg_29_1 == ccui.TouchEventType.moved or arg_29_1 == ccui.TouchEventType.canceled then
			arg_29_0:setScale(1)
		elseif arg_29_1 == ccui.TouchEventType.ended then
			arg_29_0:setScale(1)
			xyd.playButtonSound()

			if not var_28_9 then
				local var_29_0 = var_0_1:translation("VOTE_HERO_TIPS_18")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_29_0
				})
			else
				local var_29_1 = {
					data = var_28_0
				}

				xyd.WindowManager.get():openWindow("popularity_vote", var_29_1)
			end
		end
	end)
	var_28_2:getChildByName("img_love"):setTouchEnabled(true)
	var_28_2:getChildByName("img_love"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_30_0)
		if arg_30_0.name == "began" then
			arg_28_0.nodePreX_ = arg_30_0.x
			arg_28_0.nodePreY_ = arg_30_0.y
			arg_28_0.isMove_ = false

			var_28_2:getChildByName("img_love"):setScale(0.9)
		elseif arg_30_0.name == "moved" then
			local var_30_0 = 10

			if var_30_0 < math.abs(arg_28_0.nodePreY_ - arg_30_0.y) or var_30_0 < math.abs(arg_28_0.nodePreX_ - arg_30_0.x) then
				arg_28_0.isMove_ = true

				var_28_2:getChildByName("img_love"):setScale(1)
			end
		elseif arg_30_0.name == "ended" and not arg_28_0.isMove_ then
			var_28_2:getChildByName("img_love"):setScale(1)

			if not var_28_9 then
				local var_30_1 = var_0_1:translation("VOTE_HERO_TIPS_18")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_30_1
				})

				return
			end

			if arg_28_0.isChooseFav == 1 then
				local var_30_2 = arg_28_0.popularContest:getPredictHero()
				local var_30_3 = var_0_3:name(var_28_0.table_id)
				local var_30_4 = var_28_0.table_id
				local var_30_5 = ""

				if var_30_2 == 0 then
					var_30_5 = string.format(var_0_1:translation("VOTE_PREDICT_HERO_1"), var_30_3)
				elseif var_30_2 == var_28_0.table_id then
					var_30_5 = string.format(var_0_1:translation("VOTE_PREDICT_HERO_3"), var_30_3)
				else
					local var_30_6 = var_0_3:name(var_30_2)

					var_30_5 = string.format(var_0_1:translation("VOTE_PREDICT_HERO_2"), var_30_6, var_30_3)
				end

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_30_5, function()
					arg_28_0.popularContest:predict(var_30_4, function(arg_32_0, arg_32_1)
						if arg_32_0 == xyd.error.OK then
							arg_28_0:updatePredictHero(var_28_2:getChildByName("img_love"))
						else
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("VOTE_PREDICT_HERO_4")
							})
						end
					end)
				end, nil, nil, arg_28_0.colorMode)
			end
		end

		return true
	end)

	if arg_28_0.popularContest:getPredictHero() == var_28_0.table_id then
		arg_28_0.predictItem = var_28_2:getChildByName("img_love")

		var_28_2:getChildByName("img_love"):getChildByName("img_love_2"):setVisible(true)
		var_28_2:getChildByName("img_love"):getChildByName("img_love_gray_2"):setVisible(true)
	else
		var_28_2:getChildByName("img_love"):getChildByName("img_love_2"):setVisible(false)
		var_28_2:getChildByName("img_love"):getChildByName("img_love_gray_2"):setVisible(false)
	end

	if arg_28_0.isChooseFav == 0 then
		var_28_2:getChildByName("img_love"):setTouchEnabled(false)
		var_28_2:getChildByName("img_love"):getChildByName("img_love_gray"):setVisible(true)
	else
		var_28_2:getChildByName("img_love"):getChildByName("img_love_gray"):setVisible(false)
		var_28_2:getChildByName("img_love"):getChildByName("img_love_gray_2"):setVisible(false)
	end
end

function var_0_0.initChampionCell(arg_33_0, arg_33_1, arg_33_2)
	local var_33_0 = var_0_4:models(arg_33_2.table_id)
	local var_33_1 = var_0_4:modelName(arg_33_2.table_id)

	arg_33_0:updateHeroCard(arg_33_1, var_33_0[1], arg_33_2.table_id, true)
	arg_33_1:getChildByName("text_name"):setString(var_0_3:name(arg_33_2.table_id))
	arg_33_1:getChildByName("text_type"):setString(var_33_1[1])
	arg_33_1:getChildByName("gift_icon"):setVisible(false)
	arg_33_1:getChildByName("text_ticket_num"):setVisible(false)

	local var_33_2 = cc.p(arg_33_1:getChildByName("rank_node"):getPosition())
	local var_33_3 = xyd.AssetLoader.get():loadSprite("windows/popularity_contest/img_champion.png")

	var_33_3:addTo(arg_33_1)
	var_33_3:setPosition(cc.p(arg_33_1:getContentSize().width / 2, var_33_2.y))
	arg_33_1:getChildByName("img_love"):setVisible(false)
	arg_33_1:getChildByName("btn_vote"):setVisible(false)
end

function var_0_0.updatePredictHero(arg_34_0, arg_34_1)
	if arg_34_0.predictItem and not tolua.isnull(arg_34_0.predictItem) then
		arg_34_0.predictItem:getChildByName("img_love_2"):setVisible(false)
	end

	if arg_34_0.popularContest:getPredictHero() == 0 then
		arg_34_0.predictItem = nil
	else
		arg_34_1:getChildByName("img_love_2"):setVisible(true)

		arg_34_0.predictItem = arg_34_1
	end
end

function var_0_0.updateItemRank(arg_35_0, arg_35_1, arg_35_2)
	local var_35_0 = cc.p(arg_35_1:getChildByName("rank_node"):getPosition())

	if arg_35_2 > 0 and arg_35_2 <= 3 then
		local var_35_1 = "windows/popularity_contest/rank0" .. arg_35_2 .. ".png"
		local var_35_2 = xyd.AssetLoader:get():loadSprite(var_35_1)

		var_35_2:setScale(0.8)
		var_35_2:setAnchorPoint(cc.p(0, 0))
		var_35_2:addTo(arg_35_1)
		var_35_2:setPosition(cc.p(var_35_0.x - 5, var_35_0.y - 20))
	elseif arg_35_2 > 3 then
		local var_35_3 = xyd.AssetLoader.get():loadLabel(nil, "bonus")

		var_35_3:setString(arg_35_2)
		var_35_3:setAnchorPoint(cc.p(0, 0))
		var_35_3:setScale(1.2)
		var_35_3:addTo(arg_35_1)
		var_35_3:setPosition(cc.p(var_35_0.x - 5, var_35_0.y - 10))
	end
end

function var_0_0.updateHeroCard(arg_36_0, arg_36_1, arg_36_2, arg_36_3, arg_36_4)
	local var_36_0 = arg_36_1:getChildByName("hero")
	local var_36_1 = var_0_2:smallCard(arg_36_2)
	local var_36_2 = xyd.SpriteLoader.new(var_36_1, nil, nil, xyd.DefaultImageType.SMALL_CARD)

	var_36_2:addTo(var_36_0)
	var_36_2:setAnchorPoint(cc.p(0, 0))
	var_36_2:setPosition(cc.p(5, 0))

	if not arg_36_4 then
		var_36_2:setTouchEnabled(true)
		var_36_2:setTouchSwallowEnabled(false)
		var_36_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_37_0)
			if arg_37_0.name == "began" then
				arg_36_1:setScale(0.9)

				return true
			elseif arg_37_0.name == "moved" and arg_36_0.scrollViewMoved_ then
				arg_36_1:setScale(1)
			elseif arg_37_0.name == "ended" and not arg_36_0.scrollViewMoved_ then
				arg_36_1:setScale(1)
				arg_36_0.popularContest:getPollPlayerRankList(arg_36_3, function(arg_38_0, arg_38_1)
					if arg_38_0 == xyd.error.OK then
						local var_38_0 = {
							table_id = arg_36_3
						}

						if arg_38_1 and next(arg_38_1) then
							var_38_0.my_rank_info = arg_38_1.my_rank_info or {}
							var_38_0.rank_list = arg_38_1.rank_list or {}
						end

						xyd.WindowManager.get():openWindow("popularity_vote_rank", var_38_0)
					end
				end)
			end
		end)
	end
end

function var_0_0.showSearchWnd(arg_39_0, arg_39_1)
	if not arg_39_1 then
		if arg_39_0.searchWnd and not tolua.isnull(arg_39_0.searchWnd) then
			arg_39_0.searchWnd:setVisible(false)
		end

		return
	end

	if not arg_39_0.searchWnd or tolua.isnull(arg_39_0.searchWnd) then
		local var_39_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/popularity_contest/input_hero_name.csb")

		var_39_0:addTo(arg_39_0:nodeByName("container"))

		arg_39_0.searchWnd = var_39_0
	else
		arg_39_0.searchWnd:setVisible(true)

		return
	end

	local var_39_1 = arg_39_0.searchWnd:getChildByName("container")
	local var_39_2 = display.newColorLayer(cc.c4b(0, 0, 0, 200))
	local var_39_3 = var_39_1:convertToWorldSpace(cc.p(0, 0))

	var_39_2:pos(-var_39_3.x, -var_39_3.y):addTo(var_39_1, -1)
	arg_39_0:initInputbox(var_39_1)
	var_39_1:getChildByName("btn_cancel"):getChildByName("text_cancel_2"):setVisible(false)
	var_39_1:getChildByName("btn_cancel"):addTouchEventListener(function(arg_40_0, arg_40_1)
		if arg_40_1 == ccui.TouchEventType.began then
			arg_40_0:getChildByName("txt_cancel"):setVisible(false)
			arg_40_0:getChildByName("text_cancel_2"):setVisible(true)
		elseif arg_40_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_40_0:getChildByName("txt_cancel"):setVisible(true)
			arg_40_0:getChildByName("text_cancel_2"):setVisible(false)
			arg_39_0:showSearchWnd(false)
		end
	end)
	var_39_1:getChildByName("btn_search"):getChildByName("text_search_2"):setVisible(false)
	var_39_1:getChildByName("btn_search"):addTouchEventListener(function(arg_41_0, arg_41_1)
		if arg_41_1 == ccui.TouchEventType.began then
			arg_41_0:getChildByName("txt_search"):setVisible(false)
			arg_41_0:getChildByName("text_search_2"):setVisible(true)
		elseif arg_41_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_41_0:getChildByName("txt_search"):setVisible(true)
			arg_41_0:getChildByName("text_search_2"):setVisible(false)

			local var_41_0 = arg_39_0:checkInputIsExist()

			if var_41_0 and var_41_0 > 0 then
				arg_39_0.popularContest:getSingleRankById(var_41_0, function(arg_42_0, arg_42_1)
					if arg_42_0 == xyd.error.OK then
						arg_39_0:updateSearchHero()
					else
						local var_42_0 = var_0_1:translation("VOTE_SEARCH_HERO_2")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_42_0
						})
					end
				end)
			else
				local var_41_1 = string.format(var_0_1:translation("VOTE_SEARCH_HERO_1"), arg_39_0.searchName)

				xyd.WindowManager.get():openWindow("toast", {
					message = var_41_1
				})
			end
		end
	end)
end

function var_0_0.updateSearchHero(arg_43_0)
	arg_43_0.searchHero = arg_43_0.popularContest:getSearchInfo()
	arg_43_0.isSearch = true

	arg_43_0:refreshHeroList()
	arg_43_0:showSearchWnd(false)
	arg_43_0:updateBtnRestore()
end

function var_0_0.initInputbox(arg_44_0, arg_44_1)
	arg_44_0.textInput = arg_44_1:getChildByName("text_input")

	arg_44_0.textInput:setString("")

	local var_44_0 = arg_44_1:getChildByName("edit"):getContentSize()
	local var_44_1 = "windows/login/transparent.png"

	arg_44_0.editBox = ccui.EditBox:create(var_44_0, var_44_1)

	arg_44_1:getChildByName("edit"):addChild(arg_44_0.editBox)
	arg_44_0.editBox:setAnchorPoint(cc.p(0, 0))
	arg_44_0.editBox:setPosition(0, 0)
	arg_44_0.editBox:registerScriptEditBoxHandler(handler(arg_44_0, arg_44_0.inputContentbox))
	arg_44_0.editBox:setInputFlag(3)
	arg_44_0.editBox:setInputMode(cc.EDITBOX_INPUT_MODE_ANY)
	arg_44_0.editBox:setMaxLength(20)
end

function var_0_0.inputContentbox(arg_45_0, arg_45_1)
	if arg_45_1 == "began" then
		if not arg_45_0.searchName or arg_45_0.searchName == "" then
			arg_45_0.textInput:setString("")
		else
			arg_45_0.editBox:setText(arg_45_0.textInput:getString())
		end
	elseif arg_45_1 == "return" then
		local var_45_0 = arg_45_0.editBox:getText()

		if var_45_0 == "" then
			arg_45_0.searchName = ""
		else
			if xyd.utf8len(var_45_0) > 20 then
				var_45_0 = xyd.getTextstr(var_45_0, 1, 20)
			end

			arg_45_0.searchName = var_45_0

			arg_45_0.textInput:setString(var_45_0)
			arg_45_0.textInput:setColor(cc.c3b(0, 0, 0))
		end

		arg_45_0.editBox:setText("")
		arg_45_0.editBox:setVisible(true)
	end
end

function var_0_0.checkInputIsExist(arg_46_0)
	if not arg_46_0.searchName or arg_46_0.searchName == "" then
		return false
	end

	local var_46_0 = var_0_4:getTableIdByName(arg_46_0.searchName)

	if var_46_0 == 0 then
		return false
	else
		return var_46_0
	end
end

return var_0_0
