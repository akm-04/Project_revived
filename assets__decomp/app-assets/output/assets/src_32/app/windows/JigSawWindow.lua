local var_0_0 = class("JigsawWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.translation
local var_0_4 = 20
local var_0_5 = 30
local var_0_6 = "skeletons/ui_effect/activity_anniversary/anniversary_jigsaw"
local var_0_7 = "skeletons/ui_effect/summon_hero/common_effect_summon12_02"
local var_0_8 = "skeletons/ui_effect/effect_card/effect_card7"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.jigsaw = xyd.ModelManager.get():loadModel(xyd.ModelType.JIGSAW)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
end

function var_0_0.initialJigInfos(arg_2_0)
	arg_2_0.jigInfosList = {}

	for iter_2_0, iter_2_1 in pairs(arg_2_0.jigInfos) do
		arg_2_0.jigInfosList[iter_2_1.jigsaw_id] = iter_2_1
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_0:nodeByName("close_btn")

	var_3_0:addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(var_3_0, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)

	local var_3_1 = arg_3_0:nodeByName("award_scroll"):getContentSize()

	arg_3_0.awardList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		padding_ = {
			0,
			0,
			var_3_1.width,
			var_3_1.height
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("award_scroll")):setBounceable(false)
	arg_3_0.progressBar = {}
	arg_3_0.progressTxt = {}
	arg_3_0.movePieces = {}
	arg_3_0.stablePieces = {}
	arg_3_0.activity = arg_3_0.jigsaw.activity
	arg_3_0.details = arg_3_0.activity.details
	arg_3_0.jigInfos = arg_3_0.details.jig_infos

	arg_3_0:initialJigInfos()

	local var_3_2 = arg_3_0:nodeByName("rule_btn")

	var_3_2:getChildByName("txt"):setString(var_0_3:translation("ACTIVITY_RULE"))
	var_3_2:addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(var_3_2, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("new_text_rule", {
				title_name = "ANNIVERSARY_JIGSAW_RULE_TITLE",
				rule = "ANNIVERSARY_JIGSAW_RULE_TEXT"
			})
		end
	end)
	arg_3_0:layout()
end

function var_0_0.layout(arg_6_0)
	arg_6_0:nodeByName("end_time_text"):setString(var_0_3:translation("ACTIVITY_END_TIME"))
	arg_6_0:nodeByName("end_time_text"):enableOutline(cc.c4b(141, 69, 154, 255), 2)
	arg_6_0:updateDownTimeScheduler()
	arg_6_0:updateMovePieces()
	arg_6_0:updateAwardList()

	for iter_6_0 = 1, var_0_4 do
		local var_6_0 = display.newNode()

		var_6_0:setContentSize(arg_6_0:nodeByName(tostring(iter_6_0)):getContentSize().width * 2 / 3, arg_6_0:nodeByName(tostring(iter_6_0)):getContentSize().height * 2 / 3)
		var_6_0:addTo(arg_6_0:nodeByName(tostring(iter_6_0)))
		var_6_0:setAnchorPoint(cc.p(0.5, 0.5))
		var_6_0:setName("touchNode" .. iter_6_0)
		var_6_0:setPosition(cc.p(arg_6_0:nodeByName(tostring(iter_6_0)):getContentSize().width / 2, arg_6_0:nodeByName(tostring(iter_6_0)):getContentSize().height / 2))
		arg_6_0:nodeByName(tostring(iter_6_0)):setTouchEnabled(true)
		var_6_0:setTouchEnabled(true)
		var_6_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
			if arg_7_0.name == "began" then
				return true
			elseif arg_7_0.name == "ended" then
				local var_7_0 = {
					jigInfo = arg_6_0.jigInfosList[iter_6_0]
				}

				xyd.WindowManager.get():openWindow("jigsaw_detail", var_7_0)
			end
		end)

		arg_6_0.progressBar[iter_6_0] = cc.ProgressTimer:create(cc.Sprite:create("windows/jigsaw/progress_bg.png"))

		arg_6_0.progressBar[iter_6_0]:setAnchorPoint(cc.p(0.5, 0.5))
		arg_6_0.progressBar[iter_6_0]:addTo(arg_6_0:nodeByName("container"))
		arg_6_0.progressBar[iter_6_0]:setPosition(arg_6_0:nodeByName("Node_" .. iter_6_0):getPosition())
		arg_6_0.progressBar[iter_6_0]:setLocalZOrder(10)
		arg_6_0.progressBar[iter_6_0]:setMidpoint(cc.p(0.5, 0.5))
		arg_6_0.progressBar[iter_6_0]:setBarChangeRate(cc.p(1, 0))

		arg_6_0.progressTxt[iter_6_0] = arg_6_0:createProgressLabel()

		arg_6_0.progressTxt[iter_6_0]:setAnchorPoint(cc.p(0.5, 0.5))
		arg_6_0.progressTxt[iter_6_0]:addTo(arg_6_0:nodeByName("container"))
		arg_6_0.progressTxt[iter_6_0]:setPosition(arg_6_0:nodeByName("Node_" .. iter_6_0):getPosition())
		arg_6_0.progressTxt[iter_6_0]:setLocalZOrder(11)
		arg_6_0:nodeByName("pos_" .. iter_6_0):setVisible(false)
	end

	arg_6_0:updateStableJigsaw(arg_6_0:isComplete())
end

function var_0_0.updateDownTimeScheduler(arg_8_0)
	if arg_8_0.handler then
		var_0_2.unscheduleGlobal(arg_8_0.handler)

		arg_8_0.handler = nil
	end

	arg_8_0.currentTime = xyd.ServerTime.get():getServerTime()
	arg_8_0.downTime = arg_8_0.activity.end_time - arg_8_0.currentTime

	arg_8_0:updateDownTime()

	arg_8_0.handler = var_0_2.scheduleGlobal(function()
		arg_8_0.downTime = arg_8_0.downTime - 1

		arg_8_0:updateDownTime()
	end, 1)
end

function var_0_0.updateDownTime(arg_10_0)
	if arg_10_0.downTime < 0 then
		arg_10_0.downTime = 0
	end

	local var_10_0 = xyd.timeFormatAsHMS(arg_10_0.downTime)

	if not tolua.isnull(arg_10_0:nodeByName("end_time_txt")) then
		arg_10_0:nodeByName("end_time_txt"):setString(var_10_0)
	end
end

function var_0_0.updateMovePieces(arg_11_0)
	for iter_11_0 = 1, var_0_4 do
		if arg_11_0.jigInfosList[iter_11_0].is_put ~= 1 and arg_11_0.jigInfosList[iter_11_0].count >= xyd.tables.ActivityJigsaw:amount(iter_11_0) then
			arg_11_0:createMovePieceByID(iter_11_0)
		end
	end
end

function var_0_0.createMovePieceByID(arg_12_0, arg_12_1)
	local var_12_0 = "windows/jigsaw/" .. "big_" .. arg_12_1 .. ".png"
	local var_12_1 = xyd.AssetLoader.get():loadSprite(var_12_0)

	var_12_1:addTo(arg_12_0:nodeByName("container"))
	var_12_1:setTouchEnabled(true)
	var_12_1:setScale(0.62)
	var_12_1:setLocalZOrder(20)

	if arg_12_0.movePieces[arg_12_1] then
		var_12_1:setPosition(arg_12_0.movePieces[arg_12_1]:getPosition())
		arg_12_0.movePieces[arg_12_1]:removeFromParent()
	else
		var_12_1:setPosition(arg_12_0:generateRandomPosition())
	end

	arg_12_0.movePieces[arg_12_1] = var_12_1

	var_12_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		if arg_13_0.name == "began" then
			var_12_1:setLocalZOrder(100)

			return true
		elseif arg_13_0.name == "moved" then
			if not tolua.isnull(var_12_1) then
				local var_13_0 = arg_12_0:nodeByName("container"):convertToNodeSpace(cc.p(arg_13_0.x, arg_13_0.y))
				local var_13_1 = var_12_1:getContentSize()

				var_13_1.width, var_13_1.height = var_13_1.width * 0.62, var_13_1.height * 0.62

				local var_13_2 = var_13_0.x
				local var_13_3 = var_13_0.y

				if var_13_2 < 70 + var_13_1.width / 2 then
					var_13_2 = 70 + var_13_1.width / 2
				end

				if var_13_2 > 620 - var_13_1.width / 2 then
					var_13_2 = 620 - var_13_1.width / 2
				end

				if var_13_3 < 30 + var_13_1.height / 2 then
					var_13_3 = 30 + var_13_1.height / 2
				end

				if var_13_3 > 640 - var_13_1.height / 2 then
					var_13_3 = 640 - var_13_1.height / 2
				end

				var_12_1:setPosition(cc.p(var_13_2, var_13_3))
			end
		elseif arg_13_0.name == "ended" then
			var_12_1:setLocalZOrder(20)

			local var_13_4 = cc.p(arg_12_0:nodeByName(tostring(arg_12_1)):getPosition())
			local var_13_5 = cc.p(var_12_1:getPosition())

			if (var_13_5.x - var_13_4.x) * (var_13_5.x - var_13_4.x) + (var_13_5.y - var_13_4.y) * (var_13_5.y - var_13_4.y) < var_0_5 * var_0_5 then
				var_12_1:setTouchEnabled(false)
				var_12_1:setPosition(arg_12_0:nodeByName(tostring(arg_12_1)):getPosition())
				arg_12_0:putPiece(arg_12_1, var_12_1)
			end
		end
	end)
end

function var_0_0.generateRandomPosition(arg_14_0)
	local var_14_0 = 140
	local var_14_1 = math.random(127, 580)

	return cc.p(var_14_0, var_14_1)
end

function var_0_0.putPiece(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = {
		jigsaw_id = arg_15_1
	}

	arg_15_0.jigsaw:put(var_15_0, function(arg_16_0, arg_16_1)
		if arg_16_0 == xyd.error.OK then
			arg_15_0.jigInfosList[arg_15_1].is_put = 1
			arg_15_0.details.can_award = arg_16_1.can_award

			arg_15_0.jigsaw:updateRedMark()
			arg_15_2:removeFromParent()

			arg_15_0.movePieces[arg_15_1] = nil

			arg_15_0:updateStableJigsaw()
			arg_15_0:updateAwardList()
			arg_15_0:updateMovePieces()
			arg_15_0:createJigsawEffect(arg_15_1, arg_15_0:nodeByName(tostring(arg_15_1)))

			if arg_15_0:isComplete() then
				arg_15_0.awards = arg_16_1.awards

				arg_15_0:doComplete()
			else
				arg_15_0:handleRewards(arg_16_1.awards)
			end
		end
	end)
end

function var_0_0.createJigsawEffect(arg_17_0, arg_17_1, arg_17_2)
	if not tolua.isnull(arg_17_0.jigsawEffect) and arg_17_0.jigsawEffect then
		arg_17_0.jigsawEffect:removeSelf()

		arg_17_0.jigsawEffect = nil
	end

	local var_17_0 = var_0_6 .. ".json"
	local var_17_1 = var_0_6 .. ".atlas"

	arg_17_0.jigsawEffect = var_0_1.new(var_17_0, var_17_1, 1)

	arg_17_0.jigsawEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_17_0.jigsawEffect:setLocalZOrder(19)
	arg_17_2:setLocalZOrder(20)
	arg_17_0.jigsawEffect:addTo(arg_17_0:nodeByName("container"))

	if not tolua.isnull(arg_17_2) then
		arg_17_0.jigsawEffect:setPosition(arg_17_2:getPosition())
	end

	arg_17_0.jigsawEffect:play(function()
		if not tolua.isnull(arg_17_2) then
			arg_17_2:setLocalZOrder(0)
		end
	end, false)
end

function var_0_0.isComplete(arg_19_0)
	for iter_19_0 = 1, #arg_19_0.details.is_awards do
		if arg_19_0.details.is_awards[iter_19_0] ~= 1 and arg_19_0.details.can_award[iter_19_0] ~= 1 then
			return false
		end
	end

	return true
end

function var_0_0.doComplete(arg_20_0)
	arg_20_0:nodeByName("jigsaw"):setVisible(true)

	local var_20_0 = arg_20_0:nodeByName("jigsaw"):getHeight()
	local var_20_1 = 0.1
	local var_20_2 = 50
	local var_20_3 = {
		x = arg_20_0:nodeByName("jigsaw"):getPositionX(),
		y = arg_20_0:nodeByName("jigsaw"):getPositionY() - arg_20_0:nodeByName("jigsaw"):getHeight() / 2 - 500
	}
	local var_20_4 = {
		x = arg_20_0:nodeByName("jigsaw"):getPositionX(),
		y = arg_20_0:nodeByName("jigsaw"):getPositionY() - arg_20_0:nodeByName("jigsaw"):getHeight() / 2 - 100
	}
	local var_20_5 = {
		x = var_20_4.x,
		y = arg_20_0:nodeByName("jigsaw"):getPositionY() + arg_20_0:nodeByName("jigsaw"):getHeight() / 2 + 100
	}
	local var_20_6 = 1

	arg_20_0:playComplete(var_20_0, var_20_1, var_20_2, var_20_3, var_20_4, var_20_5, var_20_6)
end

function var_0_0.playComplete(arg_21_0, arg_21_1, arg_21_2, arg_21_3, arg_21_4, arg_21_5, arg_21_6, arg_21_7)
	local var_21_0 = cc.Director:getInstance():getWinSize()
	local var_21_1 = arg_21_0:nodeByName("jigsaw"):getContentSize().width

	erase = cc.DrawNode:create()

	erase:drawDot(cc.p(0, 0), var_21_1, cc.c4f(0, 0, 0, 0))
	erase:retain()

	renderTex = cc.RenderTexture:create(var_21_0.width, var_21_0.height)

	renderTex:setAnchorPoint(cc.p(0.5, 0.5))
	renderTex:addTo(arg_21_0:nodeByName("container"), 1000)
	renderTex:setPosition(var_21_0.width / 2, var_21_0.height / 2)
	renderTex:retain()
	renderTex:setTouchSwallowEnabled(false)
	renderTex:begin()

	for iter_21_0 = 1, var_0_4 do
		arg_21_0:nodeByName(tostring(iter_21_0)):visit()
		arg_21_0:nodeByName(tostring(iter_21_0)):setVisible(false)
	end

	renderTex:endToLua()

	local var_21_2 = arg_21_0:convertToWorldSpace(cc.p(0, 0))
	local var_21_3 = arg_21_1
	local var_21_4 = arg_21_4.y + var_21_2.y
	local var_21_5 = arg_21_5.y
	local var_21_6 = arg_21_3

	arg_21_0.delayHandle = var_0_2.performWithDelayGlobal(function()
		arg_21_0:createCardEffect(cc.p(arg_21_5.x, var_21_5))

		arg_21_0.completeHandle = var_0_2.scheduleGlobal(function()
			arg_21_0.cardEffect:setPosition(arg_21_5.x, var_21_5)
			erase:setPosition(arg_21_4.x, var_21_4)
			erase:setBlendFunc(gl.ONE, gl.ZERO)
			renderTex:begin()
			erase:visit()
			renderTex:endToLua()

			var_21_3 = var_21_3 - var_21_6
			var_21_4 = var_21_4 + var_21_6
			var_21_5 = var_21_5 + var_21_6

			if var_21_5 >= arg_21_6.y then
				if arg_21_0.completeHandle then
					var_0_2.unscheduleGlobal(arg_21_0.completeHandle)
				end

				arg_21_0.cardEffect:runActionOnce(cc.FadeOut:create(0.3), false, nil)
				arg_21_0:createSummonEffect()
			end
		end, arg_21_2)
	end, arg_21_7)
end

function var_0_0.createCardEffect(arg_24_0, arg_24_1)
	if not tolua.isnull(arg_24_0.cardEffect) and arg_24_0.cardEffect then
		arg_24_0.cardEffect:removeSelf()

		arg_24_0.cardEffect = nil
	end

	local var_24_0 = var_0_8 .. ".json"
	local var_24_1 = var_0_8 .. ".atlas"

	arg_24_0.cardEffect = var_0_1.new(var_24_0, var_24_1, 1)

	arg_24_0.cardEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_24_0.cardEffect:setLocalZOrder(1001)
	arg_24_0.cardEffect:addTo(arg_24_0:nodeByName("container"))
	arg_24_0.cardEffect:setScale(1.5)

	if arg_24_1 then
		arg_24_0.cardEffect:setPosition(arg_24_1)
	end

	arg_24_0.cardEffect:play(nil, true)
end

function var_0_0.createSummonEffect(arg_25_0)
	if not tolua.isnull(arg_25_0.summonEffect) and arg_25_0.summonEffect then
		arg_25_0.summonEffect:removeSelf()

		arg_25_0.summonEffect = nil
	end

	local var_25_0 = var_0_7 .. ".json"
	local var_25_1 = var_0_7 .. ".atlas"

	arg_25_0.summonEffect = var_0_1.new(var_25_0, var_25_1, 1)

	arg_25_0.summonEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_25_0.summonEffect:setLocalZOrder(19)
	arg_25_0.summonEffect:addTo(arg_25_0:nodeByName("container"))
	arg_25_0.summonEffect:setPosition(arg_25_0:nodeByName("jigsaw"):getPosition())
	arg_25_0.summonEffect:setScale(1, 0.9)
	arg_25_0.summonEffect:play(function()
		if arg_25_0 and arg_25_0.awards then
			arg_25_0:handleRewards(arg_25_0.awards)

			arg_25_0.awards = nil
		end
	end, false)
end

function var_0_0.handleRewards(arg_27_0, arg_27_1)
	var_0_2.performWithDelayGlobal(function()
		if arg_27_1 then
			arg_27_0.selfPlayer:handleRewards(arg_27_1)
		end
	end, 0.5)
end

function var_0_0.updateAwardList(arg_29_0)
	arg_29_0.awardList:removeAllItems()

	arg_29_0.awardListItems = {}

	for iter_29_0 = 1, xyd.tables.ActivityJigsawReward:counts() do
		local var_29_0 = display.newNode()
		local var_29_1 = arg_29_0.awardList:newItem()
		local var_29_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/jigsaw/item/activity_item.csb")
		local var_29_3 = var_29_2:getChildByName("container")

		arg_29_0:rewardItemLayout(var_29_3, iter_29_0, index)
		var_29_2:addTo(var_29_0)
		var_29_2:setAnchorPoint(cc.p(0, 0))
		var_29_0:setContentSize(var_29_3:getContentSize())
		var_29_1:addContent(var_29_0)
		var_29_1:setItemSize(var_29_3:getWidth(), var_29_3:getHeight() + 10)
		arg_29_0.awardList:addItem(var_29_1)
	end

	arg_29_0.awardList:reload()
end

function var_0_0.rewardItemLayout(arg_30_0, arg_30_1, arg_30_2)
	local var_30_0 = arg_30_1:getChildByName("btn")
	local var_30_1 = arg_30_1:getChildByName("yilingqu")
	local var_30_2 = arg_30_1:getChildByName("lingqu")
	local var_30_3 = arg_30_1:getChildByName("get_gray")
	local var_30_4 = arg_30_1:getChildByName("expired")
	local var_30_5 = arg_30_1:getChildByName("not_begin")
	local var_30_6 = {
		btn = var_30_0,
		alreadyObtain = var_30_1,
		obtain_bright = var_30_2,
		obtain_gray = var_30_3,
		expired = var_30_4,
		notBegin = var_30_5
	}
	local var_30_7 = arg_30_1:getChildByName("reward_container")
	local var_30_8 = xyd.ServerTime.get():getServerTime()
	local var_30_9 = arg_30_0.details.is_awards
	local var_30_10 = arg_30_0.details.can_award

	arg_30_1:getChildByName("desc"):setString(xyd.tables.ActivityJigsawReward:desc(arg_30_2))
	arg_30_1:getChildByName("progress_txt"):setString(arg_30_0:getPutPiecesCount(arg_30_2) .. "/" .. #xyd.tables.ActivityJigsawReward:pieceIds(arg_30_2))
	arg_30_0:rewardFormat(var_30_7, xyd.tables.ActivityJigsawReward:gift(arg_30_2))

	if var_30_8 < arg_30_0.activity.start_time then
		arg_30_0:setBtnGetState(-2, var_30_6)

		return
	elseif var_30_8 > arg_30_0.activity.end_time then
		arg_30_0:setBtnGetState(2, var_30_6)

		return
	end

	if not var_30_9 or not var_30_10 then
		arg_30_0:setBtnGetState(-1, var_30_6)

		return
	end

	if var_30_9[arg_30_2] == 1 then
		arg_30_0:setBtnGetState(0, var_30_6)
	elseif var_30_10[arg_30_2] == 0 then
		arg_30_0:setBtnGetState(-1, var_30_6)
	else
		arg_30_0:setBtnGetState(1, var_30_6)
	end

	var_30_0:addTouchEventListener(function(arg_31_0, arg_31_1)
		if arg_31_1 == ccui.TouchEventType.ended then
			arg_30_0:getReward(arg_30_2, var_30_6)
		end
	end)
end

function var_0_0.getPutPiecesCount(arg_32_0, arg_32_1, arg_32_2)
	local var_32_0 = xyd.tables.ActivityJigsawReward:pieceIds(arg_32_1)
	local var_32_1 = 0

	for iter_32_0 = 1, #var_32_0 do
		if arg_32_0.jigInfosList[var_32_0[iter_32_0]].is_put == 1 then
			var_32_1 = var_32_1 + 1
		end
	end

	return var_32_1
end

function var_0_0.rewardFormat(arg_33_0, arg_33_1, arg_33_2)
	local var_33_0 = arg_33_1:getContentSize().height
	local var_33_1 = var_33_0 / 4
	local var_33_2 = xyd.tables.gift:items(arg_33_2)

	if #var_33_2 == 1 and var_33_2[1] == 0 then
		var_33_2 = {}
	end

	local var_33_3 = xyd.tables.gift:itemNum(arg_33_2)
	local var_33_4 = #var_33_2

	for iter_33_0 = 1, #var_33_2 do
		local var_33_5 = display.newNode()

		var_33_5:setContentSize(var_33_0, var_33_0)

		if xyd.tables.item:type(var_33_2[iter_33_0]) == -1 then
			xyd.setAvatarBorder(var_33_2[iter_33_0], var_33_5, 1, xyd.tables.hero:initialStar(var_33_2[iter_33_0]))
		else
			xyd.setItemBorder(var_33_5, var_33_2[iter_33_0], false, false, var_33_3[iter_33_0])
		end

		var_33_5:addTo(arg_33_1)
		var_33_5:setAnchorPoint(cc.p(0, 0))
		var_33_5:setPosition((iter_33_0 - 1) * (var_33_0 + var_33_1), 0)

		local var_33_6 = {
			id = var_33_2[iter_33_0],
			hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(itemID)
		}

		arg_33_0:addTips(var_33_5, var_33_6)
	end

	local var_33_7 = xyd.tables.gift:crystal(arg_33_2)

	if var_33_7 and var_33_7 > 0 then
		local var_33_8 = display.newNode()

		var_33_8:setContentSize(var_33_0, var_33_0)
		xyd.setItemBorder(var_33_8, -1, false, false, var_33_7)
		var_33_8:addTo(arg_33_1)
		var_33_8:setAnchorPoint(cc.p(0, 0))
		var_33_8:setPosition(var_33_4 * (var_33_0 + var_33_1), 0)

		local var_33_9 = {}

		var_33_9.id = -1
		var_33_9.hasNum = arg_33_0.selfPlayer.crystal

		arg_33_0:addTips(var_33_8, var_33_9)

		var_33_4 = var_33_4 + 1
	end

	local var_33_10 = xyd.tables.gift:mana(arg_33_2)

	if var_33_10 and var_33_10 > 0 then
		local var_33_11 = display.newNode()

		var_33_11:setContentSize(var_33_0, var_33_0)
		xyd.setItemBorder(var_33_11, -2, false, false, var_33_10)
		var_33_11:addTo(arg_33_1)
		var_33_11:setAnchorPoint(cc.p(0, 0))
		var_33_11:setPosition(var_33_4 * (var_33_0 + var_33_1), 0)

		local var_33_12 = {}

		var_33_12.id = -2
		var_33_12.hasNum = arg_33_0.selfPlayer.mana

		arg_33_0:addTips(var_33_11, var_33_12)

		local var_33_13 = var_33_4 + 1
	end

	return arg_33_1
end

function var_0_0.setBtnGetState(arg_34_0, arg_34_1, arg_34_2)
	if arg_34_1 == 1 then
		arg_34_2.btn:setVisible(true)
		arg_34_2.btn:setTouchEnabled(true)
		arg_34_2.btn:setBright(true)
		arg_34_2.alreadyObtain:setVisible(false)
		arg_34_2.obtain_bright:setVisible(true)
		arg_34_2.obtain_gray:setVisible(false)
		arg_34_2.expired:setVisible(false)
		arg_34_2.notBegin:setVisible(false)
	elseif arg_34_1 == -1 then
		arg_34_2.btn:setVisible(true)
		arg_34_2.btn:setTouchEnabled(false)
		arg_34_2.btn:setBright(false)
		arg_34_2.alreadyObtain:setVisible(false)
		arg_34_2.obtain_bright:setVisible(false)
		arg_34_2.obtain_gray:setVisible(true)
		arg_34_2.expired:setVisible(false)
		arg_34_2.notBegin:setVisible(false)
	elseif arg_34_1 == 0 then
		arg_34_2.btn:setVisible(false)
		arg_34_2.alreadyObtain:setVisible(true)
		arg_34_2.obtain_bright:setVisible(false)
		arg_34_2.obtain_gray:setVisible(false)
		arg_34_2.expired:setVisible(false)
		arg_34_2.notBegin:setVisible(false)
	elseif arg_34_1 == -2 then
		arg_34_2.btn:setVisible(true)
		arg_34_2.btn:setTouchEnabled(false)
		arg_34_2.btn:setBright(false)
		arg_34_2.alreadyObtain:setVisible(false)
		arg_34_2.obtain_bright:setVisible(false)
		arg_34_2.obtain_gray:setVisible(false)
		arg_34_2.expired:setVisible(false)
		arg_34_2.notBegin:setVisible(true)
	elseif arg_34_1 == 2 then
		arg_34_2.btn:setVisible(false)
		arg_34_2.alreadyObtain:setVisible(false)
		arg_34_2.obtain_bright:setVisible(false)
		arg_34_2.obtain_gray:setVisible(false)
		arg_34_2.expired:setVisible(true)
		arg_34_2.notBegin:setVisible(false)
	end
end

function var_0_0.getReward(arg_35_0, arg_35_1, arg_35_2)
	arg_35_0.activitiesModel:getActivityReward(arg_35_0.activity.table_id, arg_35_1, function(arg_36_0, arg_36_1)
		if arg_36_0 == xyd.error.OK then
			arg_35_0.selfPlayer:handleRewards(arg_36_1.awards)

			arg_35_0.details.can_award[arg_35_1] = 0
			arg_35_0.details.is_awards[arg_35_1] = 1

			arg_35_0.jigsaw:updateRedMark()
			arg_35_0:setBtnGetState(0, arg_35_2)
		end
	end)
end

function var_0_0.createProgressLabel(arg_37_0)
	local var_37_0 = {
		font = "fonts/main_font.ttf",
		size = 20,
		color = cc.c3b(253, 226, 5)
	}
	local var_37_1 = xyd.AssetLoader.get():loadLabel(var_37_0)

	var_37_1:setMaxLineWidth(100)

	return var_37_1
end

function var_0_0.updateStableJigsaw(arg_38_0, arg_38_1)
	for iter_38_0 = 1, var_0_4 do
		if arg_38_0.jigInfosList[iter_38_0].is_put ~= 1 then
			arg_38_0:nodeByName(tostring(iter_38_0)):setOpacity(0)

			if arg_38_0.jigInfosList[iter_38_0].count >= xyd.tables.ActivityJigsaw:amount(iter_38_0) or arg_38_0.jigInfosList[iter_38_0].count == 0 then
				arg_38_0.progressBar[iter_38_0]:setVisible(false)
				arg_38_0.progressTxt[iter_38_0]:setVisible(false)
			else
				local var_38_0 = 100 * arg_38_0.jigInfosList[iter_38_0].count / xyd.tables.ActivityJigsaw:amount(iter_38_0)

				if var_38_0 < 1 then
					var_38_0 = 1
				end

				arg_38_0.progressBar[iter_38_0]:setVisible(true)
				arg_38_0.progressTxt[iter_38_0]:setVisible(true)

				local var_38_1 = cc.ProgressTo:create(0, var_38_0)

				arg_38_0.progressBar[iter_38_0]:runAction(cc.Repeat:create(var_38_1, 1))
				arg_38_0.progressTxt[iter_38_0]:setString(math.floor(var_38_0) .. "%")
			end
		else
			arg_38_0.progressBar[iter_38_0]:setVisible(false)
			arg_38_0.progressTxt[iter_38_0]:setVisible(false)
			arg_38_0:nodeByName(tostring(iter_38_0)):setOpacity(255)
		end

		if arg_38_1 == true then
			arg_38_0:nodeByName(tostring(iter_38_0)):setVisible(false)
		end
	end

	if arg_38_1 == true then
		arg_38_0:nodeByName("jigsaw_bg"):setVisible(false)
		arg_38_0:nodeByName("jigsaw"):setVisible(true)
	end
end

function var_0_0.didOpen(arg_39_0, arg_39_1)
	var_0_0.super:didOpen(arg_39_1)
	arg_39_0:addBlockLayer(cc.c4b(0, 0, 0, 220), true)
end

function var_0_0.didClose(arg_40_0)
	if arg_40_0.handler then
		var_0_2.unscheduleGlobal(arg_40_0.handler)

		arg_40_0.handler = nil
	end

	if arg_40_0.completeHandle then
		var_0_2.unscheduleGlobal(arg_40_0.completeHandle)
	end
end

return var_0_0
