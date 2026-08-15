local var_0_0 = class("TreasureWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = require("framework.scheduler")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.treasureLocation
local var_0_5 = xyd.tables.treasureType
local var_0_6 = xyd.tables.hero
local var_0_7 = xyd.tables.treasureSkill
local var_0_8 = 40
local var_0_9 = 65
local var_0_10 = {}

var_0_10.ING = 1
var_0_10.NONE = 2
var_0_10.OVER = 3

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.handle_ = {}
	arg_1_0.isRecover = false
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.treasureModel = xyd.ModelManager.get():loadModel(xyd.ModelType.TREASURE)
	arg_1_0.treasureModel.isDisabelAll = false
	arg_1_0.cellsByID = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:playWindowAction()
	arg_2_0:getItemData()
	arg_2_0:layout()
	arg_2_0:updateAtTime()
	arg_2_0:setHandler()
	arg_2_0:playGuide()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.TREASURE_UPDATE_WINDOW, function(arg_3_0)
		if arg_2_0 and not tolua.isnull(arg_2_0) then
			arg_2_0:update()
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.TREASURE_SAVE_HEROS, function(arg_4_0)
		if arg_2_0 and not tolua.isnull(arg_2_0) then
			arg_2_0:update()
		end
	end)
end

function var_0_0.playWindowAction(arg_5_0)
	local var_5_0, var_5_1 = arg_5_0:nodeByName("bg_top"):getPosition()

	arg_5_0:nodeByName("bg_top"):setPosition(var_5_0, var_5_1 + 52)
	transition.moveTo(arg_5_0:nodeByName("bg_top"), {
		time = 0.3,
		y = var_5_1
	})
end

function var_0_0.getItemData(arg_6_0)
	arg_6_0.openType = {}

	local var_6_0 = var_0_4:getAll()

	for iter_6_0, iter_6_1 in pairs(var_6_0) do
		local var_6_1 = {}
		local var_6_2 = var_0_4:treasureType(iter_6_1)

		for iter_6_2, iter_6_3 in pairs(var_6_2) do
			local var_6_3 = var_0_5:reqType(iter_6_3)
			local var_6_4 = var_0_5:req(iter_6_3)

			if var_6_3 == xyd.TreasureOpenType.CHAPTER then
				if arg_6_0.selfPlayer.worldMaps_[var_6_4] and arg_6_0.selfPlayer.worldMaps_[var_6_4].star and arg_6_0.selfPlayer.worldMaps_[var_6_4].star > 0 then
					table.insert(var_6_1, iter_6_3)
				end
			elseif var_6_4 <= arg_6_0.selfPlayer.lev then
				table.insert(var_6_1, iter_6_3)
			end
		end

		if #var_6_1 > 0 then
			local var_6_5 = #arg_6_0.openType + 1

			arg_6_0.openType[var_6_5] = {}
			arg_6_0.openType[var_6_5].types = var_6_1
			arg_6_0.openType[var_6_5].id = iter_6_1
			arg_6_0.openType[var_6_5].name = var_0_4:name(iter_6_1)
		end
	end
end

function var_0_0.layout(arg_7_0)
	arg_7_0:initSPNode()
	arg_7_0:nodeByName("txt_title"):setString(var_0_3:translation("TREASURE_TXT"))
	arg_7_0:nodeByName("close"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			local var_8_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_8_0, false)
			xyd.WindowManager.get():closeWindow(arg_7_0)
		end
	end)
	arg_7_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_7_0.treasureModel.isDisabelAll then
			return
		end

		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_9_0 = {}

			var_9_0.title_name = "TREASURE_RULE_TITLE"
			var_9_0.rule = "TREASURE_RULE_TEXT"
			var_9_0.style = xyd.RuleStyle.BLUE

			xyd.WindowManager.get():openWindow("new_text_rule", var_9_0)
		end
	end)
	arg_7_0:nodeByName("txt_record"):setString(var_0_3:translation("TREASURE_DIARY"))
	arg_7_0:nodeByName("btn_record"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_7_0:nodeByName("btn_record"), arg_10_1)

		if arg_7_0.treasureModel.isDisabelAll then
			return
		end

		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_7_0.treasureModel:getTreasureDiary(function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK then
					local var_11_0 = arg_11_1 or {}

					xyd.WindowManager.get():openWindow("treasure_diary", var_11_0)
				end
			end)
		end
	end)

	arg_7_0.listView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_7_0:nodeByName("list"):getWidth(), arg_7_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL
	}):addTo(arg_7_0:nodeByName("list")):onScroll(handler(arg_7_0, arg_7_0.scrollListener))

	arg_7_0.listView_:setBounceable(true)
	arg_7_0.listView_:setDelegate(handler(arg_7_0, arg_7_0.delegate))
	arg_7_0.listView_:reload()
	arg_7_0:updateTime()

	arg_7_0.txt_spNum = arg_7_0:nodeByName("sp_num_txt")

	arg_7_0:updateSPNumTxt()
end

function var_0_0.update(arg_12_0)
	arg_12_0:getItemData()
	arg_12_0.listView_:refreshList()
	arg_12_0:updateTime()
	arg_12_0:updateSPNumTxt()
end

function var_0_0.initSPNode(arg_13_0)
	arg_13_0.node_sp = cc.Node:create()

	arg_13_0.node_sp:setContentSize(arg_13_0:nodeByName("node_sp"):getWidth(), arg_13_0:nodeByName("node_sp"):getHeight() + 50)
	arg_13_0.node_sp:addTo(arg_13_0:nodeByName("bg_top"))
	arg_13_0.node_sp:setAnchorPoint(cc.p(0, 0))
	arg_13_0.node_sp:setPosition(arg_13_0:nodeByName("node_sp"):getX(), arg_13_0:nodeByName("node_sp"):getY() - 50)
	arg_13_0.node_sp:setTouchEnabled(true)
	arg_13_0.node_sp:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
		if arg_13_0.treasureModel.isDisabelAll then
			return
		end

		if arg_14_0.name == "began" then
			arg_13_0.SPTips = xyd.WindowManager.get():openWindow("treasure_sp_tips")

			arg_13_0.SPTips:setPosition(615, 432)

			return true
		elseif arg_14_0.name == "ended" then
			xyd.WindowManager.get():closeWindow("treasure_sp_tips")
		end
	end)
end

function var_0_0.delegate(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	data = arg_15_0.openType

	if cc.ui.UIListView.COUNT_TAG == arg_15_2 then
		return #data
	elseif cc.ui.UIListView.CELL_TAG == arg_15_2 then
		if arg_15_3 > #data then
			return nil
		end

		local var_15_0 = arg_15_0.listView_:dequeueItem()

		if not var_15_0 then
			var_15_0 = arg_15_0.listView_:newItem()
		else
			var_15_0:removeAllChildren(true)
		end

		local var_15_1 = data[arg_15_3]
		local var_15_2 = display.newNode()

		arg_15_0:initCell(var_15_2, var_15_1, arg_15_3)

		local var_15_3 = display.newNode()

		var_15_3:addChild(var_15_2)

		arg_15_0.cellsByID[var_15_2.itemId] = var_15_3

		var_15_2:setPosition(23, 0)
		var_15_3:setContentSize(var_15_2:getContentSize())
		var_15_0:setItemSize(var_15_2:getContentSize().width, var_15_2:getContentSize().height)
		var_15_0:addContent(var_15_3)

		return var_15_0
	end
end

function var_0_0.updateTime(arg_16_0)
	local var_16_0 = xyd.ServerTime.get():getServerTime()

	for iter_16_0, iter_16_1 in pairs(arg_16_0.treasureModel.teams) do
		local var_16_1 = arg_16_0.cellsByID[iter_16_1.team_id]

		if iter_16_1.need_time ~= 0 and var_16_0 <= iter_16_1.need_time + iter_16_1.start_time then
			if var_16_1 ~= nil and not tolua.isnull(var_16_1) then
				local var_16_2 = iter_16_1.need_time + iter_16_1.start_time - var_16_0
				local var_16_3 = var_16_1:getChildByName("cell"):getChildByName("layout"):getChildByName("container"):getChildByName("item_bg1")
				local var_16_4 = var_16_3:getChildByName("left_time")
				local var_16_5 = var_16_3:getChildByName("bar")
				local var_16_6 = math.floor(var_16_2 / 3600)
				local var_16_7 = math.floor(var_16_2 / 60) % 60
				local var_16_8 = var_16_2 % 60

				var_16_4:setString(string.format("%02d:%02d:%02d", var_16_6, var_16_7, var_16_8))

				local var_16_9 = (iter_16_1.need_time - var_16_2) / iter_16_1.need_time * 100

				if var_16_9 > 100 then
					var_16_9 = 100
				elseif var_16_9 < 0 then
					var_16_9 = 0
				end

				var_16_5:setPercent(var_16_9)
			end
		elseif var_16_0 > iter_16_1.need_time + iter_16_1.start_time and var_16_1 ~= nil and not tolua.isnull(var_16_1) and var_16_1.is_load then
			local var_16_10 = var_16_1:getChildByName("cell")

			if var_16_10.isShowTime then
				var_16_10.isShowTime = false

				arg_16_0.listView_:reload()

				break
			end
		end
	end
end

function var_0_0.scrollListener(arg_17_0, arg_17_1)
	if arg_17_1.name == "began" then
		arg_17_0.startClick_ = true
		arg_17_0.prevX_ = arg_17_1.x
	elseif arg_17_1.name == "moved" and 20 <= math.abs(arg_17_1.x - arg_17_0.prevX_) then
		arg_17_0.startClick_ = false
	end
end

function var_0_0.initCell(arg_18_0, arg_18_1, arg_18_2, arg_18_3)
	if arg_18_3 == 1 then
		arg_18_0.firstTreasureCell = arg_18_1
	end

	arg_18_1.itemId = arg_18_2.id

	local var_18_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/treasure/main/treasure_item.csb")
	local var_18_1 = var_18_0:getChildByName("container")
	local var_18_2 = var_18_1:getContentSize()
	local var_18_3 = {
		var_18_1:getChildByName("item_bg1"),
		var_18_1:getChildByName("item_bg2"),
		(var_18_1:getChildByName("item_bg3"))
	}

	var_18_3[1]:setVisible(false)
	var_18_3[2]:setVisible(false)
	var_18_3[3]:setVisible(false)
	var_18_1:getChildByName("left_top"):setVisible(false)
	var_18_0:setContentSize(var_18_2)
	arg_18_1:setContentSize(var_18_2.width + 28, var_18_2.height)
	var_18_3[1]:getChildByName("txt_doing"):setString(var_0_3:translation("TREASURE_WORKING"))
	var_18_3[1]:getChildByName("txt_left_time"):setString(var_0_3:translation("TEAM_DRINK_LEFT_TIME"))
	var_18_3[2]:getChildByName("txt_desc_1"):setString(var_0_3:translation("TREASURE_START_DES_1"))
	var_18_3[2]:getChildByName("txt_desc_2"):setString(var_0_3:translation("TREASURE_START_DES_3"))
	var_18_3[2]:getChildByName("txt_desc_3"):setString(var_0_3:translation("TREASURE_START_DES_2"))
	var_18_3[2]:getChildByName("txt_desc_4"):setString(var_0_3:translation("TREASURE_START_DES_3"))
	var_18_3[2]:getChildByName("txt_time"):setString(var_0_3:translation("COST_TIME"))
	var_18_3[2]:getChildByName("txt_need"):setString(var_0_3:translation("NEED"))
	var_18_3[3]:getChildByName("txt_reward"):setString(var_0_3:translation("ALERT_AWARD_NAME"))
	var_18_3[1]:getChildByName("txt_doing"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_18_3[2]:getChildByName("txt_desc_1"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_18_3[2]:getChildByName("txt_desc_2"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_18_3[2]:getChildByName("txt_desc_3"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_18_3[2]:getChildByName("txt_desc_4"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_18_3[3]:getChildByName("txt_reward"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_18_0:setName("layout")
	arg_18_1:setName("cell")
	var_18_0:setPosition(cc.p(0, 0))
	arg_18_1:addChild(var_18_0)
	arg_18_1:setTouchSwallowEnabled(false)
	arg_18_1:setTouchEnabled(true)
	var_18_1:getChildByName("txt_title"):setString(arg_18_2.name)

	local var_18_4 = display.newNode()

	var_18_4:setContentSize(var_18_2)
	var_18_4:setTouchEnabled(true)
	var_18_4:setTouchSwallowEnabled(false)
	var_18_4:setAnchorPoint(cc.p(0, 0))
	var_18_4:setPosition(0, 0)

	local var_18_5 = arg_18_0.treasureModel.teams[arg_18_2.id]
	local var_18_6 = var_0_4:icon(arg_18_2.id)

	if var_18_6 ~= "" then
		arg_18_0:setIcon(var_18_1:getChildByName("icon"), var_18_6)
	end

	if var_18_5.with_external_award == 1 then
		var_18_1:getChildByName("left_top"):setVisible(true)
	end

	local var_18_7 = var_0_10.NONE
	local var_18_8 = xyd.ServerTime.get():getServerTime()
	local var_18_9 = var_0_4:maxMember(arg_18_2.id)
	local var_18_10 = var_0_4:tableID(arg_18_2.id)
	local var_18_11 = xyd.HeroAnimation.new(var_0_4:model(arg_18_2.id), var_0_4:model(arg_18_2.id), xyd.tables.model:uiScale(var_0_4:model(arg_18_2.id)), {})

	var_18_1:getChildByName("model"):removeAllChildren()

	if var_18_5.need_time == 0 then
		var_18_7 = var_0_10.NONE

		local var_18_12 = #arg_18_0.treasureModel.MemeoryTeams[arg_18_2.id]
		local var_18_13 = 0
		local var_18_14 = 0
		local var_18_15 = var_0_4:baseIce(arg_18_2.id)

		for iter_18_0, iter_18_1 in pairs(arg_18_0.treasureModel.MemeoryTeams[arg_18_2.id]) do
			local var_18_16 = arg_18_0.selfPlayer:getHeroByID(iter_18_1)

			if var_0_6:treasureSkill(var_18_16:getTableID()) == xyd.TreasureSkillType.ICE_CREAM then
				var_18_13 = var_18_13 + var_0_7:num(xyd.TreasureSkillType.ICE_CREAM)
			end

			if var_0_6:treasureSkill(var_18_16:getTableID()) == xyd.TreasureSkillType.TIME then
				var_18_14 = var_18_14 + var_0_7:num(xyd.TreasureSkillType.TIME)
			end
		end

		local var_18_17 = 0

		for iter_18_2, iter_18_3 in pairs(var_0_6:getTreasureHeros(arg_18_2.id)) do
			if arg_18_0.selfPlayer:getHeroIgnoreAwaken(iter_18_3) then
				var_18_17 = var_18_17 + 1
			end
		end

		local var_18_18 = var_18_15 - var_18_13
		local var_18_19 = var_18_3[2]:getChildByName("txt_num_1")
		local var_18_20 = var_18_3[2]:getChildByName("txt_num_2")

		var_18_19:setString(var_18_12)
		var_18_20:setString(var_18_17 - var_18_12)
		var_18_3[2]:getChildByName("txt_desc_2"):setPositionX(var_18_19:getPositionX() + var_18_19:getWidth() + 10)
		var_18_3[2]:getChildByName("txt_desc_4"):setPositionX(var_18_20:getPositionX() + var_18_20:getWidth() + 10)

		local var_18_21 = var_0_4:baseTime(arg_18_2.id) - var_18_14
		local var_18_22 = math.floor(var_18_21 / 3600)
		local var_18_23 = math.floor(var_18_21 / 60) % 60
		local var_18_24 = var_18_21 % 60

		var_18_3[2]:getChildByName("time_text"):setString(string.format("%02d:%02d:%02d", var_18_22, var_18_23, var_18_24))
		var_18_3[2]:getChildByName("num_text"):setString(var_18_18)

		if var_18_18 > arg_18_0.selfPlayer.treasureSP then
			var_18_3[2]:getChildByName("num_text"):setColor(xyd.color.RED)
		end

		if var_18_11 then
			var_18_11:idle(true)
			var_18_11:setContentSize(1, 1)
			var_18_11:setScale(var_0_4:scale(arg_18_2.id))
			var_18_11:setPosition(cc.p(0, 0))
			var_18_1:getChildByName("model"):removeAllChildren()
			var_18_11:addTo(var_18_1:getChildByName("model"))
		end
	elseif var_18_8 > var_18_5.need_time + var_18_5.start_time then
		var_18_7 = var_0_10.OVER

		for iter_18_4 = 1, 4 do
			var_18_3[3]:getChildByName("reward_" .. iter_18_4):removeAllChildren()
		end

		local var_18_25 = arg_18_0:getRewards(var_18_5.award)
		local var_18_26 = 0

		for iter_18_5, iter_18_6 in pairs(var_18_25) do
			local var_18_27

			if iter_18_6.item_id < 0 then
				local var_18_28 = xyd.setItemWithTextNode(iter_18_6.item_id, iter_18_6.item_num, cc.c4b(27, 151, 46, 255), var_0_8, true, 22)

				var_18_3[3]:getChildByName("reward_" .. iter_18_5):addChild(var_18_28)
			else
				local var_18_29 = display.newNode()

				var_18_29:setContentSize(var_0_9, var_0_9)
				var_18_29:setPosition(var_18_26, 0)
				xyd.setItemAndAddTips(var_18_29, iter_18_6.item_id, iter_18_6.item_num)
				var_18_3[3]:getChildByName("reward_3"):addChild(var_18_29)

				var_18_26 = var_18_26 + var_0_9 + 10
			end
		end

		if var_18_11 then
			var_18_11:win(true)
			var_18_11:setContentSize(1, 1)
			var_18_11:setScale(var_0_4:scale(arg_18_2.id))
			var_18_11:setPosition(cc.p(0, 0))
			var_18_1:getChildByName("model"):removeAllChildren()
			var_18_11:addTo(var_18_1:getChildByName("model"))
		end
	else
		var_18_7 = var_0_10.ING
		arg_18_1.isShowTime = true

		local var_18_30 = var_18_5.start_time + var_18_5.need_time - var_18_8
		local var_18_31 = math.floor(var_18_30 / 3600)
		local var_18_32 = math.floor(var_18_30 / 60) % 60
		local var_18_33 = var_18_30 % 60

		var_18_3[1]:getChildByName("left_time"):setString(string.format("%02d:%02d:%02d", var_18_31, var_18_32, var_18_33))

		local var_18_34 = (var_18_5.need_time - var_18_30) / var_18_5.need_time * 100

		if var_18_34 > 100 then
			var_18_34 = 100
		elseif var_18_34 < 0 then
			var_18_34 = 0
		end

		var_18_3[1]:getChildByName("bar"):setPercent(var_18_34)

		if var_0_4:model(arg_18_2.id) == 10001108 then
			local var_18_35 = "skeletons/zhugejin/zhugejintreasure.json"
			local var_18_36 = "skeletons/zhugejin/zhugejintreasure.atlas"
			local var_18_37 = var_0_1.new(var_18_35, var_18_36, 1)

			var_18_37:setPosition(var_0_4:offset(arg_18_2.id), 0)
			var_18_37:setContentSize(1, 1)
			var_18_37:setScale(var_0_4:scale(arg_18_2.id))
			var_18_37:addTo(var_18_1:getChildByName("model"))
			var_18_37:play(nil, true)
		end

		if var_18_11 then
			var_18_11:treasure(true)
			var_18_11:setContentSize(1, 1)
			var_18_11:setScale(var_0_4:scale(arg_18_2.id))
			var_18_11:setPosition(var_0_4:offset(arg_18_2.id), 0)
			var_18_11:addTo(var_18_1:getChildByName("model"))
		end
	end

	var_18_1:getChildByName("item_bg" .. var_18_7):setVisible(true)
	var_18_1:getChildByName("img_can_get"):setVisible(var_18_7 == 3)
	var_18_1:addChild(var_18_4)
	var_18_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_19_0)
		if arg_19_0.name == "began" then
			var_18_1:setScale(0.9)

			return true
		elseif arg_19_0.name == "moved" then
			if arg_18_0.startClick_ == false then
				var_18_1:setScale(1)
			end

			return true
		elseif arg_19_0.name == "ended" then
			var_18_1:setScale(1)

			if arg_18_0.startClick_ == true then
				xyd.playButtonSound()

				if arg_18_0.guideHand and not tolua.isnull(arg_18_0.guideHand) then
					arg_18_0.guideHand:removeSelf()

					arg_18_0.guideHand = nil
				end

				if var_18_7 == var_0_10.ING then
					({}).teamId = arg_18_2.id

					local var_19_0 = {
						locationId = arg_18_2.id,
						types = arg_18_2.types
					}

					xyd.WindowManager.get():openWindow("treasure_show_team", var_19_0)
				elseif var_18_7 == var_0_10.NONE then
					local var_19_1 = {
						locationId = arg_18_2.id,
						types = arg_18_2.types,
						titleName = arg_18_2.name,
						typeName = var_18_5.treasure_type
					}

					xyd.WindowManager.get():openWindow("treasure_prepare", var_19_1)
				else
					local var_19_2 = {
						teamId = arg_18_2.id
					}

					arg_18_0.treasureModel:finishOneTeam(function(arg_20_0, arg_20_1)
						if arg_20_0 == xyd.error.OK then
							local var_20_0 = {
								locationId = arg_18_2.id,
								typeName = var_18_5.treasure_type,
								locationName = arg_18_2.name,
								reward = arg_20_1.award
							}

							xyd.WindowManager.get():openWindow("treasure_reward", var_20_0)
						end
					end, var_19_2)
				end
			end

			return true
		end
	end)
end

function var_0_0.getRewards(arg_21_0, arg_21_1)
	local var_21_0 = {}

	if arg_21_1.normal_award and (arg_21_1.normal_award.item_num or arg_21_1.normal_award.items) then
		local var_21_1 = arg_21_1.normal_award
		local var_21_2 = {}

		if var_21_1.award_type == xyd.TreasureProductType.MANA then
			var_21_2.item_id = -2
			var_21_2.item_num = var_21_1.item_num
		elseif var_21_1.award_type == xyd.TreasureProductType.DRINK then
			var_21_2 = var_21_1
		elseif var_21_1.award_type == xyd.TreasureProductType.STONE then
			var_21_2.item_id = -4
			var_21_2.item_num = 0

			for iter_21_0, iter_21_1 in pairs(var_21_1.items) do
				var_21_2.item_num = var_21_2.item_num + iter_21_1.item_num
			end
		elseif var_21_1.award_type == xyd.TreasureProductType.DUST then
			var_21_2.item_id = -11
			var_21_2.item_num = var_21_1.item_num
		elseif var_21_1.award_type == xyd.TreasureProductType.LIQUID then
			var_21_2.item_id = -12
			var_21_2.item_num = var_21_1.item_num
		else
			var_21_2 = var_21_1
		end

		table.insert(var_21_0, var_21_2)
	end

	if arg_21_1.externa_crystal_award ~= 0 then
		local var_21_3 = {
			item_id = -1,
			item_num = arg_21_1.externa_crystal_award
		}

		table.insert(var_21_0, var_21_3)
	end

	if arg_21_1.battle_award and arg_21_1.battle_award.item_num and arg_21_1.battle_award.item_num > 0 then
		table.insert(var_21_0, arg_21_1.battle_award)
	end

	if arg_21_1.chest_award and arg_21_1.chest_award.item_num then
		table.insert(var_21_0, arg_21_1.chest_award)
	end

	return var_21_0
end

function var_0_0.setIcon(arg_22_0, arg_22_1, arg_22_2)
	local var_22_0 = arg_22_1:getContentSize().width
	local var_22_1 = arg_22_1:getContentSize().height
	local var_22_2 = xyd.AssetLoader:get():loadSprite(arg_22_2)

	arg_22_1:addChild(var_22_2)
	var_22_2:setPosition(var_22_0 / 2, var_22_1 / 2)
	var_22_2:setAnchorPoint(cc.p(0.5, 0.5))

	local var_22_3 = 0.8

	var_22_2:setScale(var_22_3)
end

function var_0_0.updateSPNumTxt(arg_23_0)
	arg_23_0.txt_spNum:setString(arg_23_0.selfPlayer.treasureSP .. "/" .. xyd.tables.misc.treasureSPLimit)
end

function var_0_0.updateAtTime(arg_24_0)
	arg_24_0.updateAtTimeHandler = var_0_2.scheduleGlobal(function(arg_25_0)
		arg_24_0:updateTime()
	end, 1)
end

function var_0_0.setHandler(arg_26_0)
	if arg_26_0.selfPlayer.treasureSP >= xyd.tables.misc.treasureSPLimit then
		if arg_26_0.isRecover then
			var_0_2.unscheduleGlobal(arg_26_0.handle_)

			arg_26_0.isRecover = false
		end
	elseif not arg_26_0.isRecover then
		arg_26_0.handle_ = var_0_2.scheduleGlobal(function()
			arg_26_0.selfPlayer:getNextTreasureSPCoolTime()
			arg_26_0:updateSPNumTxt()
		end, 1)
		arg_26_0.isRecover = true
	end
end

function var_0_0.willClose(arg_28_0)
	if arg_28_0.updateAtTimeHandler then
		var_0_2.unscheduleGlobal(arg_28_0.updateAtTimeHandler)

		arg_28_0.updateAtTimeHandler = nil
	end

	if arg_28_0.handle_ and arg_28_0.isRecover then
		var_0_2.unscheduleGlobal(arg_28_0.handle_)

		arg_28_0.handle_ = nil
	end
end

function var_0_0.playGuide(arg_29_0)
	local var_29_0 = xyd.StoryData.get():getGuideID()

	if var_29_0 == xyd.GuideStoryType.GUIDE_TREASURE_START then
		local var_29_1 = arg_29_0.firstTreasureCell:getChildByName("layout")

		if not var_29_1 then
			return
		end

		local var_29_2 = var_29_1:getPositionX()
		local var_29_3 = var_29_1:getPositionY()
		local var_29_4 = var_29_1:getContentSize().width
		local var_29_5 = var_29_1:getContentSize().height
		local var_29_6 = display.newNode()
		local var_29_7 = cc.p(var_29_4 / 2, var_29_5 / 2)

		var_29_6:setPosition(var_29_7)
		var_29_6:addTo(var_29_1)

		local var_29_8 = {
			rect = true,
			width = var_29_4,
			height = var_29_5
		}
		local var_29_9 = import("app.windows.GuideHand").new(var_29_8)

		var_29_6:addChild(var_29_9)
		var_29_9:setPosition(0, 0)

		local var_29_10 = xyd.tables.guide:desc(var_29_0)

		var_29_9:setText(var_29_10, cc.p(0, 0))

		arg_29_0.guideHand = var_29_6

		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_TREASURE_ONE, true)
		xyd.StoryData.get():persist()
	end
end

return var_0_0
