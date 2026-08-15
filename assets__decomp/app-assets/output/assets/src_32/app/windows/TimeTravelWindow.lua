local var_0_0 = class("TimeTravelItem", function()
	return cc.Node:create()
end)
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.timeTravel

function var_0_0.ctor(arg_2_0)
	arg_2_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_2_0:contentView()
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()
		arg_3_0.contentView_ = xyd.AssetLoader.get():loadNodeFromJson("windows/time_travel/time_travel_item.csb")

		arg_3_0.contentView_:addTo(arg_3_0):setAnchorPoint(0.5, 0.5)
		arg_3_0.contentView_:setContentSize(325, 520)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_0.contentView_:getChildByName("container")

	arg_4_0.contentView_:getChildByName("label_name"):setVisible(false)
	arg_4_0.contentView_:getChildByName("pic_icon_lock"):setVisible(false)

	local var_4_1 = arg_4_0.contentView_:getChildByName("bar"):getContentSize()
	local var_4_2 = var_0_1.new({
		size = var_4_1.width
	})

	var_4_2:addTo(arg_4_0.contentView_)
	var_4_2:setAnchorPoint(0.5, 0.5)
	var_4_2:setPosition(arg_4_0.contentView_:getChildByName("bar"):getPosition())

	local var_4_3
	local var_4_4
	local var_4_5
	local var_4_6

	if arg_4_1.id >= 11 and arg_4_1.id <= 15 then
		var_4_5 = xyd.tables.trialConfig:trials(arg_4_1.id)
		var_4_6 = var_0_3:trialTime(arg_4_1.id)
	else
		var_4_5 = xyd.tables.challenge:challenges(arg_4_1.id)
		var_4_6 = nil
	end

	local var_4_7 = xyd.tables.campaign:openLv(var_4_5[1])
	local var_4_8 = display.newNode()

	var_4_8:setContentSize(var_4_0:getWidth(), var_4_0:getHeight())
	var_4_8:setTouchEnabled(true)
	var_4_8:setTouchSwallowEnabled(false)
	var_4_8:setAnchorPoint(cc.p(0, 0))
	var_4_8:setPosition(0, 0)
	var_4_8:addTo(var_4_0)

	local var_4_9
	local var_4_10 = xyd.AssetLoader.get():loadSprite(arg_4_1.trialIcon)

	xyd.displaySpriteOnContainer(var_4_10, var_4_0, false, "bottom_left")
	var_4_0:setLocalZOrder(-100)

	local var_4_11 = var_4_7 <= arg_4_0.player.lev and ((arg_4_1.isOpen or arg_4_1.canBuy) and 1 or 2) or 3

	if var_4_11 == 1 then
		local var_4_12 = xyd.HeroAnimation.new(arg_4_1.model, arg_4_1.model, xyd.tables.model:uiScale(arg_4_1.model), {})

		if var_4_12 then
			var_4_12:idle()
			var_4_12:setScale(arg_4_1.modelScale)

			local var_4_13 = arg_4_0.contentView_:getChildByName("model_container"):getContentSize()

			if arg_4_1.id == 16 then
				var_4_12:setPosition(cc.p(var_4_13.width / 2 + 40, 0))
			else
				var_4_12:setPosition(cc.p(var_4_13.width / 2, 0))
			end

			arg_4_0.contentView_:getChildByName("model_container"):removeAllChildren()
			var_4_12:addTo(arg_4_0.contentView_:getChildByName("model_container"))
			var_4_12:setContentSize(320, 280)
		end

		var_4_4 = cc.c4b(99, 152, 196, 255)

		arg_4_0.contentView_:getChildByName("label_time"):setColor(cc.c3b(25, 142, 163))
		arg_4_0.contentView_:getChildByName("label_time"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
		arg_4_0.contentView_:getChildByName("label_time"):getVirtualRenderer():setAdditionalKerning(2)
		arg_4_0.contentView_:getChildByName("label_time"):setString(var_4_6)
		var_4_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
			if arg_5_0.name == "moved" and 20 <= math.abs(arg_5_0.x - arg_4_0.prevX_) then
				arg_4_0.moved = true
			end

			if arg_5_0.name == "began" then
				arg_4_0.moved = false
				arg_4_0.prevX_ = arg_5_0.x

				arg_4_0.contentView_:setScale(0.9)
			end

			if arg_5_0.name == "ended" then
				arg_4_0.contentView_:setScale(1)

				if arg_4_0.moved then
					arg_4_0.moved = false

					return false
				end

				if arg_4_1.isOpen or arg_4_1.canBuy then
					if arg_4_1.id >= 11 and arg_4_1.id <= 15 then
						xyd.WindowManager.get():openWindow("select_trial", arg_4_1.trial)
					else
						xyd.WindowManager.get():openWindow("difficultchoice")
					end
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_3:cannotChallenge(arg_4_1.id)
					})
				end
			end

			return true
		end)
	elseif var_4_11 == 2 then
		local var_4_14 = display.newSprite(arg_4_1.trialModelNo)

		var_4_14:setScale(arg_4_1.modelScale)
		xyd.displaySpriteOnContainer(var_4_14, arg_4_0.contentView_:getChildByName("model_container"), false)

		if arg_4_1.id >= 11 and arg_4_1.id <= 15 then
			var_4_14:setPositionX(172)
			var_4_14:setPositionY(100)
		end

		if arg_4_1.id == 16 then
			var_4_14:setPositionX(150)
			var_4_14:setPositionY(100)
		end

		xyd.GrayNode(arg_4_0.contentView_)

		var_4_4 = cc.c4b(111, 131, 148, 255)

		arg_4_0.contentView_:getChildByName("label_time"):setColor(cc.c3b(64, 64, 64))
		arg_4_0.contentView_:getChildByName("label_time"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
		arg_4_0.contentView_:getChildByName("label_time"):getVirtualRenderer():setAdditionalKerning(2)
		arg_4_0.contentView_:getChildByName("label_time"):setString(var_0_3:cannotChallenge(arg_4_1.id))
	else
		local var_4_15 = display.newSprite(arg_4_1.trialModelNo)

		var_4_15:setScale(arg_4_1.modelScale)
		xyd.displaySpriteOnContainer(var_4_15, arg_4_0.contentView_:getChildByName("model_container"), false)

		if arg_4_1.id >= 11 and arg_4_1.id <= 15 then
			var_4_15:setPositionX(172)
			var_4_15:setPositionY(100)
		end

		xyd.GrayNode(arg_4_0.contentView_)
		arg_4_0.contentView_:getChildByName("pic_icon_lock"):setVisible(true)
		arg_4_0.contentView_:getChildByName("label_time"):setVisible(false)

		local var_4_16 = string.format(var_0_2:translation("LEV_OPEN_TIPS"), var_4_7)

		var_4_2:setVisible(false)
		arg_4_0.contentView_:getChildByName("txt_tips"):setColor(cc.c3b(64, 64, 64))
		arg_4_0.contentView_:getChildByName("txt_tips"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
		arg_4_0.contentView_:getChildByName("txt_tips"):getVirtualRenderer():setAdditionalKerning(2)
		arg_4_0.contentView_:getChildByName("txt_tips"):setString(var_4_16)

		var_4_4 = cc.c4b(111, 131, 148, 255)
	end

	if not arg_4_1.isOpen and arg_4_1.canBuy then
		arg_4_0.contentView_:getChildByName("bg_canbuy"):setVisible(true)
		arg_4_0.contentView_:getChildByName("bg_canbuy"):getChildByName("label_canbuy"):setVisible(true)
	else
		arg_4_0.contentView_:getChildByName("bg_canbuy"):setVisible(false)
		arg_4_0.contentView_:getChildByName("bg_canbuy"):getChildByName("label_canbuy"):setVisible(false)
	end

	local var_4_17 = {
		size = 24,
		text = arg_4_1.trialName,
		color = cc.c3b(255, 255, 255),
		align = cc.ui.TEXT_ALIGN_CENTER
	}

	arg_4_0.textLabel = xyd.AssetLoader.get():loadLabel(var_4_17)

	arg_4_0.textLabel:enableOutline(var_4_4, 3)
	arg_4_0.textLabel:setPosition(arg_4_0.contentView_:getChildByName("label_name"):getPosition())
	arg_4_0.textLabel:setAnchorPoint(cc.p(0.5, 0.5))
	arg_4_0.textLabel:addTo(arg_4_0.contentView_)

	local var_4_18

	if arg_4_1.id <= 15 then
		var_4_18 = xyd.tables.trialConfig:showItems(arg_4_1.id)
	else
		var_4_18 = xyd.tables.challenge:itemDisplay(arg_4_1.id)
	end

	local var_4_19 = arg_4_0.contentView_:getChildByName("item_list")

	var_4_19:setTouchEnabled(true)
	var_4_19:setTouchSwallowEnabled(true)

	for iter_4_0 = 1, 4 do
		local var_4_20 = cc.Node:create()

		var_4_20:setContentSize(70, 70)
		xyd.setItemBorder(var_4_20, var_4_18[iter_4_0])
		var_4_19:addChild(var_4_20)
		var_4_20:setPosition(iter_4_0 * 75 - 80, 0)

		local var_4_21 = {}

		arg_4_0:tipsFormat(var_4_20, var_4_18[iter_4_0], var_4_21)
		arg_4_0:addTips(var_4_20, var_4_21)
	end
end

function var_0_0.tipsFormat(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	arg_6_3.id = arg_6_2
	arg_6_3.lev = xyd.tables.item:level(arg_6_2)

	if xyd.tables.item:type(arg_6_2) == -1 then
		arg_6_3.tipsType = 0
		arg_6_3.desc1 = xyd.tables.hero:getDes(arg_6_2)
	elseif specialItem then
		arg_6_3.tipsType = 1
		arg_6_3.id = -3
	else
		arg_6_3.tipsType = 1
		arg_6_3.desc1 = xyd.tables.item:desc1(arg_6_2)
		arg_6_3.desc2 = xyd.tables.item:desc2(arg_6_2)
	end

	arg_6_3.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(arg_6_2)
	arg_6_3.name = xyd.tables.item:name(arg_6_2)
end

function var_0_0.addTips(arg_7_0, arg_7_1, arg_7_2)
	arg_7_1:setTouchEnabled(true)
	arg_7_1:setTouchSwallowEnabled(false)

	local var_7_0

	arg_7_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "began" then
			var_7_0 = arg_8_0.y

			if not xyd.WindowManager.get():getWindow("new_item_tips") then
				local var_8_0 = xyd.WindowManager.get():openWindow("new_item_tips", arg_7_2)

				xyd.adaptToWorldPosition(arg_7_1, var_8_0)
			end

			return true
		elseif arg_8_0.name == "moved" then
			local var_8_1 = arg_8_0.y

			if math.abs(var_8_1 - var_7_0) > 30 then
				xyd.WindowManager.get():closeWindow("new_item_tips")
			end
		elseif arg_8_0.name == "ended" then
			xyd.WindowManager.get():closeWindow("new_item_tips")
		end
	end)
end

function var_0_0.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.scrollViewMoved_ = false
		arg_9_0.prevX_ = arg_9_1.x
	elseif arg_9_1.name == "moved" and 20 <= math.abs(arg_9_1.x - arg_9_0.prevX_) then
		arg_9_0.scrollViewMoved_ = true
	end
end

local var_0_4 = class("TimeTravelWindow", import("app.common.ui.BaseWindow"))
local var_0_5 = xyd.tables.translation
local var_0_6 = xyd.tables.timeTravel
local var_0_7 = {
	[xyd.TrialType.XIAOYAO] = xyd.DailyConsumeType.XiaoYao,
	[xyd.TrialType.YILING] = xyd.DailyConsumeType.YiLing,
	[xyd.TrialType.CHIBI] = xyd.DailyConsumeType.ChiBi,
	[xyd.TrialType.WULI] = xyd.DailyConsumeType.PhysicsTest,
	[xyd.TrialType.MOFA] = xyd.DailyConsumeType.MagicTest,
	[xyd.TrialType.JIUWEI] = 0,
	[xyd.TrialType.NIAN] = 0,
	[xyd.TrialType.QIUBITE] = 0,
	[xyd.TrialType.YUANXIAO] = 0,
	[xyd.TrialType.DANSHEN] = 0,
	[xyd.TrialType.SONGZHONGJI] = 0
}

function var_0_4.ctor(arg_10_0, arg_10_1, arg_10_2)
	var_0_4.super.ctor(arg_10_0, arg_10_1, arg_10_2)

	arg_10_0.trial = arg_10_2
	arg_10_0.offset_ = 40
end

function var_0_4.willOpen(arg_11_0, arg_11_1)
	var_0_4.super.willOpen(arg_11_0, arg_11_1)
	arg_11_0:addTopSidebar()

	arg_11_0.listView_ = cc.ui.UIListView.new({
		touchOnContent = true,
		viewRect = cc.rect(0, 0, 1180, 538),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_11_0:nodeByName("item_list")):onScroll(handler(arg_11_0, arg_11_0.scrollListener))

	arg_11_0.listView_:setTouchSwallowEnabled(true)

	arg_11_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_4.loadChallengeInfo(arg_12_0)
	arg_12_0.selfPlayer:loadTrialInfos(function()
		if xyd.WindowManager.get():getWindow("time_travel") then
			arg_12_0:layout()
		end
	end)
end

function var_0_4.onAppear(arg_14_0)
	arg_14_0:loadChallengeInfo()
end

function var_0_4.didOpen(arg_15_0, arg_15_1)
	var_0_4.super.didOpen(arg_15_0, arg_15_1)
	arg_15_0:loadChallengeInfo()
end

function var_0_4.sortCampaigns(arg_16_0)
	table.sort(arg_16_0.campaigns, function(arg_17_0, arg_17_1)
		if arg_17_0.isOpen and not arg_17_1.isOpen then
			return true
		elseif not arg_17_0.isOpen and arg_17_1.isOpen then
			return false
		end

		if arg_17_0.canBuy and not arg_17_1.canBuy then
			return true
		elseif not arg_17_0.canBuy and arg_17_1.canBuy then
			return false
		end

		if arg_17_0.id > arg_17_1.id then
			return true
		elseif arg_17_0.id < arg_17_1.id then
			return false
		end
	end)
end

function var_0_4.updateItems(arg_18_0)
	arg_18_0.campaigns = {}

	for iter_18_0 = 1, #var_0_6.ids_ do
		arg_18_0.campaigns[iter_18_0] = {}
		arg_18_0.campaigns[iter_18_0].isOpen = false
		arg_18_0.campaigns[iter_18_0].id = var_0_6.ids_[iter_18_0]
		arg_18_0.campaigns[iter_18_0].trialName = var_0_6:trialName(var_0_6.ids_[iter_18_0])
		arg_18_0.campaigns[iter_18_0].trialIcon = var_0_6:trialIcon(var_0_6.ids_[iter_18_0])
		arg_18_0.campaigns[iter_18_0].trialIconNo = var_0_6:trialIconNo(var_0_6.ids_[iter_18_0])
		arg_18_0.campaigns[iter_18_0].model = var_0_6:model(var_0_6.ids_[iter_18_0])
		arg_18_0.campaigns[iter_18_0].trialType = var_0_6:trialType(var_0_6.ids_[iter_18_0])
		arg_18_0.campaigns[iter_18_0].challengeNum = var_0_6:challengeNum(var_0_6.ids_[iter_18_0])
		arg_18_0.campaigns[iter_18_0].challengeStatus = var_0_6:challengeStatus(var_0_6.ids_[iter_18_0])
		arg_18_0.campaigns[iter_18_0].cannotChallenge = var_0_6:cannotChallenge(var_0_6.ids_[iter_18_0])
		arg_18_0.campaigns[iter_18_0].trialModelNo = var_0_6:trialModelNo(var_0_6.ids_[iter_18_0])
		arg_18_0.campaigns[iter_18_0].modelScale = var_0_6:modelScale(var_0_6.ids_[iter_18_0])
		arg_18_0.campaigns[iter_18_0].tableID = var_0_6:tableID(var_0_6.ids_[iter_18_0])
	end

	arg_18_0.trials = arg_18_0.selfPlayer.trialInfos_
	arg_18_0.challenges = arg_18_0.selfPlayer.challengeInfos_
	arg_18_0.openIds = {}

	for iter_18_1 = #arg_18_0.campaigns, 1, -1 do
		local var_18_0 = arg_18_0.campaigns[iter_18_1]

		if arg_18_0.trials[var_18_0.id] ~= nil then
			var_18_0.isOpen = tonumber(arg_18_0.trials[var_18_0.id].isOpen) == 1 and tonumber(arg_18_0.trials[var_18_0.id].leftTimes) ~= 0
			var_18_0.trial = arg_18_0.trials[var_18_0.id]
			arg_18_0.openIds[var_18_0.id] = true
		end

		if arg_18_0.challenges[var_18_0.id] ~= nil then
			var_18_0.isOpen = tonumber(arg_18_0.challenges[var_18_0.id].isOpen) == 1 and tonumber(arg_18_0.challenges[var_18_0.id].leftTimes) ~= 0
			var_18_0.trial = arg_18_0.trials[var_18_0.id]
			arg_18_0.openIds[var_18_0.id] = true
		end

		if not arg_18_0.challenges[var_18_0.id] and not arg_18_0.trials[var_18_0.id] or arg_18_0.challenges[var_18_0.id] and tonumber(arg_18_0.challenges[var_18_0.id].isOpen) == 0 or arg_18_0.trials[var_18_0.id] and tonumber(arg_18_0.trials[var_18_0.id].isOpen) == 0 then
			table.remove(arg_18_0.campaigns, iter_18_1)
		end
	end

	xyd.Backend.get():request(xyd.mid.DAILY_CONSUNME_LOAD, {}, function(arg_19_0, arg_19_1)
		local var_19_0 = arg_19_1.buy_times
		local var_19_1 = xyd.WindowManager.get():getWindow("time_travel")

		if var_19_1 and not tolua.isnull(var_19_1) then
			if not var_19_1.campaigns or not next(var_19_1.campaigns) then
				return
			end

			for iter_19_0 = 1, #var_19_1.campaigns do
				if var_0_7[var_19_1.campaigns[iter_19_0].id] ~= 0 then
					var_19_1.campaigns[iter_19_0].buyTimes = xyd.splitToNumber(var_19_0, "|")[var_0_7[var_19_1.campaigns[iter_19_0].id]] or 0
					var_19_1.campaigns[iter_19_0].maxBuyTime = xyd.tables.dailyConsume:getNum(var_0_7[var_19_1.campaigns[iter_19_0].id]) or 0

					if var_19_1.campaigns[iter_19_0].buyTimes < var_19_1.campaigns[iter_19_0].maxBuyTime then
						var_19_1.campaigns[iter_19_0].canBuy = true
					else
						var_19_1.campaigns[iter_19_0].canBuy = false
					end
				end
			end

			var_19_1:sortCampaigns()

			if var_19_1.listView_ and not tolua.isnull(var_19_1.listView_) then
				var_19_1.listView_:removeAllItems()
			else
				return
			end

			local var_19_2 = 0

			for iter_19_1 = 1, #var_19_1.campaigns do
				local var_19_3 = var_19_1.listView_:newItem()
				local var_19_4 = display.newNode()
				local var_19_5 = var_0_0.new()

				var_19_5:setParams(var_19_1.campaigns[iter_19_1])
				var_19_5:setPosition(165, 269)
				var_19_5:setAnchorPoint(cc.p(0.5, 0.5))
				var_19_4:addChild(var_19_5)
				var_19_3:addContent(var_19_4)
				var_19_4:setContentSize(355, 538)
				var_19_3:setItemSize(365, 538)
				var_19_1.listView_:addItem(var_19_3)
			end

			if #var_19_1.campaigns <= 3 then
				var_19_1.listView_:setPositionX(var_19_1.listView_:getPositionX() + var_19_1.offset_)
				var_19_1.listView_:setViewRect(cc.rect(0, 0, 1120 - var_19_1.offset_, 538))

				var_19_1.offset_ = 0
			elseif var_19_1.offset_ == 0 then
				var_19_1.offset_ = 40

				var_19_1.listView_:setPositionX(var_19_1.listView_:getPositionX() - var_19_1.offset_)
				var_19_1.listView_:setViewRect(cc.rect(0, 0, 1120 + var_19_1.offset_, 538))
			end

			var_19_1.listView_:reload()
		end
	end, {}, false, true)
end

function var_0_4.scrollListener(arg_20_0, arg_20_1)
	if arg_20_1.name == "began" then
		arg_20_0.scrollViewMoved_ = false
		arg_20_0.prevX_ = arg_20_1.x
	elseif arg_20_1.name == "moved" and 20 <= math.abs(arg_20_1.x - arg_20_0.prevX_) then
		arg_20_0.scrollViewMoved_ = true
	end
end

function var_0_4.willClose(arg_21_0)
	return
end

function var_0_4.layout(arg_22_0)
	arg_22_0:updateItems()
	arg_22_0:nodeByName("btn_leitai"):addTouchEventListener(function(arg_23_0, arg_23_1)
		if arg_23_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_23_0 = {
				openIds = arg_22_0.openIds
			}

			xyd.WindowManager.get():openWindow("futrueprophecy", var_23_0)
		end
	end)
end

return var_0_4
