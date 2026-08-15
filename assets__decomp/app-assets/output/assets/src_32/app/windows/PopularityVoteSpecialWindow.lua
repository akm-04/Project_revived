local var_0_0 = class("PopularityVoteSpecialWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityVoteTimeline
local var_0_3 = xyd.tables.activityVoteTicket
local var_0_4 = xyd.tables.activityVotePartner
local var_0_5 = xyd.tables.model

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.popularContest = xyd.ModelManager.get():loadModel(xyd.ModelType.POPULARITY_CONTEST)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.data = arg_1_2.data
	arg_1_0.tableID = arg_1_2.table_id
	arg_1_0.pollType = arg_1_2.poll_type
	arg_1_0.pollNum = arg_1_2.poll_num
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:initData()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.initData(arg_4_0)
	arg_4_0.models = var_0_4:models(arg_4_0.tableID)
	arg_4_0.stage = arg_4_0.popularContest:getStage()
	arg_4_0.isShowSuper = var_0_2:isShowSuper(arg_4_0.stage)
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("text_tips"):setString(var_0_1:translation("VOTE_HERO_TIPS_12"))

	if #arg_5_0.models > 3 then
		arg_5_0:initListview()
	else
		arg_5_0:initList()
	end
end

function var_0_0.initListview(arg_6_0)
	local var_6_0 = arg_6_0:nodeByName("list")
	local var_6_1 = var_6_0:getContentSize().width
	local var_6_2 = var_6_0:getContentSize().height

	arg_6_0.heroList_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_6_1, var_6_2),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_6_0)

	local var_6_3 = {}
	local var_6_4 = {}

	for iter_6_0 = 1, #arg_6_0.models do
		local var_6_5 = arg_6_0.heroList_:newItem()
		local var_6_6 = arg_6_0:initVoteItem(iter_6_0, var_6_3, var_6_4)

		var_6_6:setTouchSwallowEnabled(false)
		var_6_5:setItemSize(var_6_6:getContentSize().width, arg_6_0.heroList_.viewRect_.height)
		var_6_5:addContent(var_6_6)
		arg_6_0.heroList_:addItem(var_6_5)
	end

	local var_6_7 = 0
	local var_6_8 = 1

	for iter_6_1 = 1, #var_6_3 do
		if var_6_7 < var_6_3[iter_6_1] then
			var_6_7 = var_6_3[iter_6_1]
			var_6_8 = iter_6_1
		end
	end

	for iter_6_2 = 1, #var_6_4 do
		if iter_6_2 == var_6_8 then
			var_6_4[iter_6_2]:setVisible(true)
		else
			var_6_4[iter_6_2]:setVisible(false)
		end
	end

	arg_6_0.heroList_:reload()
end

function var_0_0.initVoteItem(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = var_0_4:modelName(arg_7_0.tableID)
	local var_7_1 = arg_7_0.models[arg_7_1]
	local var_7_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/popularity_contest/vote_special_item.csb")
	local var_7_3 = var_7_2:getChildByName("container")
	local var_7_4 = var_7_3:getContentSize()

	arg_7_0:updateHeroCard(var_7_3:getChildByName("hero"), var_7_1)
	var_7_3:getChildByName("text_name"):setString(var_7_0[arg_7_1])
	table.insert(arg_7_3, var_7_3:getChildByName("text_cur_show"))

	local var_7_5 = 0
	local var_7_6 = 0

	if arg_7_0.isShowSuper == 1 then
		var_7_5 = var_0_3:weight(xyd.PopularityHeroPollType.SUPER) / var_0_3:weight(xyd.PopularityHeroPollType.NORMAL)
	end

	local var_7_7 = arg_7_0.data[tostring(var_7_1)]
	local var_7_8 = var_7_7[xyd.PopularityHeroPollType.NORMAL] + var_7_7[xyd.PopularityHeroPollType.SUPER] * var_7_5

	table.insert(arg_7_2, var_7_8)
	var_7_3:getChildByName("text_ticket_num"):setString(var_7_8)
	var_7_2:setTouchEnabled(true)
	var_7_2:setTouchSwallowEnabled(false)
	var_7_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "began" then
			var_7_3:setScale(0.9)

			arg_7_0.preX_ = arg_8_0.x
			arg_7_0.preY_ = arg_8_0.y
			arg_7_0.isMove_ = false
		elseif arg_8_0.name == "moved" then
			if math.abs(arg_8_0.x - arg_7_0.preX_) > 10 or math.abs(arg_8_0.y - arg_7_0.preY_) > 10 then
				arg_7_0.isMove_ = true

				var_7_3:setScale(1)
			end
		elseif arg_8_0.name == "ended" and not arg_7_0.isMove_ then
			var_7_3:setScale(1)

			local var_8_0 = string.format(var_0_1:translation("VOTE_HERO_TIPS_17"), var_7_0[arg_7_1])

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_8_0, function()
				if arg_7_0 and not tolua.isnull(arg_7_0) then
					arg_7_0:voteTicket(var_7_1)

					arg_7_0.isSelect = true
				end
			end, nil, nil, arg_7_0.colorMode)
		end

		return true
	end)

	local var_7_9 = display.newNode()

	var_7_9:setContentSize(var_7_4.width + 10, arg_7_0.heroList_.viewRect_.height)
	var_7_9:addChild(var_7_2)

	return var_7_9
end

function var_0_0.initList(arg_10_0)
	if #arg_10_0.models <= 0 then
		return
	end

	local var_10_0 = arg_10_0:nodeByName("list"):getContentSize()
	local var_10_1 = var_0_4:modelName(arg_10_0.tableID)
	local var_10_2 = 15
	local var_10_3 = 0
	local var_10_4 = 0

	if #arg_10_0.models == 2 then
		var_10_3 = 80
		var_10_2 = 45
	end

	local var_10_5 = {}
	local var_10_6 = {}

	for iter_10_0 = 1, #arg_10_0.models do
		local var_10_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/popularity_contest/vote_special_item.csb")

		var_10_7:addTo(arg_10_0:nodeByName("list"))

		local var_10_8 = var_10_7:getChildByName("container")
		local var_10_9 = var_10_8:getContentSize()
		local var_10_10 = arg_10_0.models[iter_10_0]

		arg_10_0:updateHeroCard(var_10_8:getChildByName("hero"), var_10_10)
		var_10_8:getChildByName("text_name"):setString(var_10_1[iter_10_0])
		table.insert(var_10_6, var_10_8:getChildByName("text_cur_show"))

		local var_10_11 = 0
		local var_10_12 = 0

		if arg_10_0.isShowSuper == 1 then
			var_10_11 = var_0_3:weight(xyd.PopularityHeroPollType.SUPER) / var_0_3:weight(xyd.PopularityHeroPollType.NORMAL)
		end

		local var_10_13 = arg_10_0.data[tostring(var_10_10)]
		local var_10_14 = var_10_13[xyd.PopularityHeroPollType.NORMAL] + var_10_13[xyd.PopularityHeroPollType.SUPER] * var_10_11

		table.insert(var_10_5, var_10_14)
		var_10_8:getChildByName("text_ticket_num"):setString(var_10_14)
		var_10_7:setPosition(cc.p(var_10_3, var_10_4))

		var_10_3 = var_10_9.width + var_10_3 + var_10_2

		var_10_7:setTouchEnabled(true)
		var_10_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
			if arg_11_0.name == "began" then
				var_10_8:setScale(0.9)

				return true
			elseif arg_11_0.name == "ended" then
				var_10_8:setScale(1)

				local var_11_0 = string.format(var_0_1:translation("VOTE_HERO_TIPS_17"), var_10_1[iter_10_0])

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_11_0, function()
					if arg_10_0 and not tolua.isnull(arg_10_0) then
						arg_10_0:voteTicket(var_10_10)

						arg_10_0.isSelect = true
					end
				end, nil, nil, arg_10_0.colorMode)
			end
		end)
	end

	local var_10_15 = 0
	local var_10_16 = 1

	for iter_10_1 = 1, #var_10_5 do
		if var_10_15 < var_10_5[iter_10_1] then
			var_10_15 = var_10_5[iter_10_1]
			var_10_16 = iter_10_1
		end
	end

	for iter_10_2 = 1, #var_10_6 do
		if iter_10_2 == var_10_16 then
			var_10_6[iter_10_2]:setVisible(true)
		else
			var_10_6[iter_10_2]:setVisible(false)
		end
	end
end

function var_0_0.updateHeroCard(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = var_0_5:smallCard(arg_13_2)
	local var_13_1 = xyd.SpriteLoader.new(var_13_0, nil, nil, xyd.DefaultImageType.SMALL_CARD)
	local var_13_2 = arg_13_1:getContentSize().height
	local var_13_3 = arg_13_1:getContentSize().width

	if not var_13_1 then
		return
	end

	local var_13_4 = "windows/popularity_contest/race_wnd/img_clip.png"
	local var_13_5 = xyd.AssetLoader.get():loadSprite(var_13_4)

	var_13_5:setPosition(var_13_3 / 2, var_13_2 / 2)
	var_13_5:setAnchorPoint(cc.p(0.5, 0.5))
	var_13_5:setScale(var_13_3 / var_13_5:getWidth(), var_13_2 / var_13_5:getHeight())

	local var_13_6 = cc.ClippingNode:create()

	var_13_6:setStencil(var_13_5)
	var_13_6:setInverted(true)
	var_13_6:setAlphaThreshold(0.5)
	arg_13_1:addChild(var_13_6)
	var_13_6:addChild(var_13_1)
	var_13_1:setPosition(var_13_3 / 2, var_13_2 / 2)
	var_13_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_13_1:setScale(var_13_3 / var_13_1:getWidth(), var_13_2 / var_13_1:getHeight())
	var_13_6:setLocalZOrder(-1)
end

function var_0_0.voteTicket(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = {
		table_id = arg_14_0.tableID,
		model_id = arg_14_1,
		poll_num = arg_14_0.pollNum,
		poll_type = arg_14_0.pollType
	}

	arg_14_0.popularContest:poll(var_14_0, function(arg_15_0, arg_15_1)
		if arg_15_0 == xyd.error.OK then
			local var_15_0 = xyd.WindowManager.get():getWindow("popularity_race_wnd")

			if var_15_0 and not tolua.isnull(var_15_0) then
				var_15_0:updateSearchHero()
			end

			if not arg_14_2 then
				xyd.WindowManager.get():closeWindow(arg_14_0)
			end
		end
	end)
end

function var_0_0.willClose(arg_16_0)
	if not arg_16_0.isSelect then
		arg_16_0:voteTicket(arg_16_0.models[1], true)
	end
end

return var_0_0
