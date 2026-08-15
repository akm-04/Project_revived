local var_0_0 = class("PetCampaignWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 0.5
local var_0_3 = 605
local var_0_4 = 720
local var_0_5 = import("app.model.Hero")
local var_0_6 = 5
local var_0_7 = 6
local var_0_8 = require("framework.scheduler")
local var_0_9 = xyd.tables.petCampaign
local var_0_10 = xyd.tables.mission
local var_0_11 = 1
local var_0_12 = 2
local var_0_13 = 16
local var_0_14 = 7

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	collectgarbage("collect")
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.petCampaign = xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN)
	arg_1_0.arena = xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.task = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)
	arg_1_0.floorType = arg_1_0.petCampaign.state
end

function var_0_0.checkSweepOver(arg_2_0)
	if arg_2_0.petCampaign.has_red then
		arg_2_0.petCampaign.has_red = nil

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.CHECK_MIDDLE_RED_MARK,
			params = xyd.CheckMiddleRed.SKY
		})

		local var_2_0 = {
			finish_time = tonumber(xyd.ServerTime.get():getServerTime())
		}

		arg_2_0.petCampaign:finishSweep(function(arg_3_0, arg_3_1)
			if arg_3_0 == xyd.error.OK then
				var_2_0.isFinishAward = true
				var_2_0.awards = arg_3_1.awards
				var_2_0.floorType = xyd.PetCampaignFloorType.NORMAL

				xyd.WindowManager.get():openWindow("pet_campaign_award", var_2_0)

				if arg_2_0.petCampaign.state == xyd.PetCampaignFloorType.NORMAL then
					arg_2_0.currentIndex = arg_2_0.petCampaign.now_floor
					arg_2_0.minSearchIndex = arg_2_0.petCampaign.now_floor

					arg_2_0:layout()
				end
			end
		end, var_2_0)
	end
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	var_0_0.super.willOpen(arg_4_0, arg_4_1)

	arg_4_0.is_after_win = false

	if arg_4_1 and arg_4_1.now_floor then
		arg_4_0.currentIndex = arg_4_1.now_floor
		arg_4_0.minSearchIndex = arg_4_1.now_floor

		if arg_4_0.floorType == xyd.PetCampaignFloorType.SUPER and arg_4_0.petCampaign.lastSuperMaxFloor and arg_4_0.petCampaign.lastSuperMaxFloor ~= arg_4_0.petCampaign.max_floor and arg_4_0.petCampaign.max_floor <= var_0_9:getMaxLimitFloor(arg_4_0.floorType) then
			arg_4_0.currentIndex = arg_4_0.currentIndex + 1
			arg_4_0.is_after_win = true
		end
	else
		arg_4_0.currentIndex = arg_4_0.petCampaign.now_floor
		arg_4_0.minSearchIndex = arg_4_0.petCampaign.now_floor
	end

	if arg_4_0.petCampaign.has_red then
		arg_4_0.petCampaign.has_red = nil

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.CHECK_MIDDLE_RED_MARK,
			params = xyd.CheckMiddleRed.SKY
		})

		if arg_4_0.petCampaign.awards then
			local var_4_0 = {}

			var_4_0.isFinishAward = true
			var_4_0.awards = arg_4_0.petCampaign.awards
			var_4_0.floorType = xyd.PetCampaignFloorType.NORMAL

			xyd.WindowManager.get():openWindow("pet_campaign_award", var_4_0)

			if arg_4_0.petCampaign.state == xyd.PetCampaignFloorType.NORMAL then
				arg_4_0.currentIndex = arg_4_0.petCampaign.now_floor
				arg_4_0.minSearchIndex = arg_4_0.petCampaign.now_floor
			end
		else
			local var_4_1 = {
				finish_time = tonumber(xyd.ServerTime.get():getServerTime())
			}

			arg_4_0.petCampaign:finishSweep(function(arg_5_0, arg_5_1)
				if arg_5_0 == xyd.error.OK then
					var_4_1.isFinishAward = true
					var_4_1.awards = arg_5_1.awards
					var_4_1.floorType = xyd.PetCampaignFloorType.NORMAL

					xyd.WindowManager.get():openWindow("pet_campaign_award", var_4_1)

					if arg_4_0.petCampaign.state == xyd.PetCampaignFloorType.NORMAL then
						arg_4_0.currentIndex = arg_4_0.petCampaign.now_floor
						arg_4_0.minSearchIndex = arg_4_0.petCampaign.now_floor

						arg_4_0:layout()
					end
				end
			end, var_4_1)
		end
	end

	arg_4_0.floorCells = {}
	arg_4_0.delayIndex = {}

	arg_4_0:scheduleUpdate()
	arg_4_0:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function(...)
		arg_4_0:update_(...)
	end)

	if arg_4_0.floorType == xyd.PetCampaignFloorType.SUPER then
		arg_4_0.minSearchIndex = 0
		arg_4_0.hasInSuper = true
	end

	arg_4_0.canDisplay_ = true
	arg_4_0.co = coroutine.create(function()
		while true do
			if not arg_4_0.delayIndex or not arg_4_0.delayIndex[1] then
				coroutine.yield()
			end

			local var_7_0 = arg_4_0.delayIndex[1]
			local var_7_1 = arg_4_0:nodeByName("list")

			if var_7_0 < arg_4_0.minSearchIndex then
				if arg_4_0.minSearchIndex == arg_4_0.petCampaign.max_floor then
					arg_4_0:initCell(var_7_0, var_7_1, {
						x = 0,
						y = (var_0_4 - var_0_3) / 2 - var_0_3
					})
				else
					arg_4_0:initHasDoneCell(var_7_0, var_7_1, {
						x = 0,
						y = (var_0_4 - var_0_3) / 2 - var_0_3
					})
				end
			elseif var_7_0 < arg_4_0.currentIndex and var_7_0 >= arg_4_0.minSearchIndex then
				arg_4_0:initCell(var_7_0, var_7_1, {
					x = 0,
					y = (var_0_4 - var_0_3) / 2 - var_0_3
				})
			elseif var_7_0 > arg_4_0.currentIndex then
				arg_4_0:initCell(var_7_0, var_7_1, {
					x = 0,
					y = (var_0_4 - var_0_3) / 2 + var_0_3
				})
			end

			table.remove(arg_4_0.delayIndex, 1)
			coroutine.yield()
		end
	end)

	arg_4_0:layout()

	if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_PET_ONE then
		local var_4_2 = arg_4_0.floorCells[arg_4_0.currentIndex]:getChildByName("container"):getChildByName("bottom"):getChildByName("fight_btn")

		if var_4_2 and var_4_2.can_click then
			arg_4_0:playGuide(var_0_11)
		else
			xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_PET_THREE)
			xyd.StoryData.get():persist()

			arg_4_0.selfPlayer.petGuideId = 0
		end
	elseif xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_PET_TWO then
		arg_4_0:playGuide(var_0_12)
	end
end

function var_0_0.playGuide(arg_8_0, arg_8_1)
	if arg_8_1 == var_0_11 then
		local var_8_0 = arg_8_0.floorCells[arg_8_0.currentIndex]:getChildByName("container"):getChildByName("bottom"):getChildByName("fight_btn")
		local var_8_1 = var_8_0:getPositionX()
		local var_8_2 = var_8_0:getPositionY()

		if xyd.WindowManager.get():getWindow("guide") then
			xyd.WindowManager.get():closeWindow("guide")
		end

		xyd.WindowManager.get():openWindow("guide")

		local var_8_3 = xyd.WindowManager.get():getWindow("guide")
		local var_8_4 = arg_8_0:convertToNodeSpace(var_8_0:getParent():convertToWorldSpace(cc.p(var_8_1, var_8_2)))

		var_8_3:addNode()
		var_8_3:setStencil(var_8_0:getContentSize().width, var_8_0:getContentSize().height, var_8_4.x, var_8_4.y, 1)
	elseif arg_8_1 == var_0_12 then
		local var_8_5 = arg_8_0:nodeByName("close")
		local var_8_6 = var_8_5:getPositionX()
		local var_8_7 = var_8_5:getPositionY()

		if xyd.WindowManager.get():getWindow("guide") then
			xyd.WindowManager.get():closeWindow("guide")
		end

		xyd.WindowManager.get():openWindow("guide")

		local var_8_8 = xyd.WindowManager.get():getWindow("guide")
		local var_8_9 = arg_8_0:convertToNodeSpace(var_8_5:getParent():convertToWorldSpace(cc.p(var_8_6, var_8_7)))

		var_8_8:addNode()
		var_8_8:setStencil(var_8_5:getContentSize().width, var_8_5:getContentSize().height, var_8_9.x, var_8_9.y, 1)
	end
end

function var_0_0.layout(arg_9_0)
	arg_9_0:setTouchSwallowEnabled(false)

	if arg_9_0.is_after_win then
		arg_9_0.can_move = false
		arg_9_0.is_after_win = false
		arg_9_0.currentIndex = arg_9_0.currentIndex - 1

		arg_9_0:setCurrentItem(arg_9_0.currentIndex)
		arg_9_0:playDead(arg_9_0.currentIndex)

		arg_9_0.playDeadHandle = var_0_8.performWithDelayGlobal(function()
			if arg_9_0.moveList then
				arg_9_0:moveList(true)

				if arg_9_0.floorType == xyd.PetCampaignFloorType.SUPER then
					arg_9_0.playDeadHandle = var_0_8.performWithDelayGlobal(function()
						arg_9_0:playLive(arg_9_0.currentIndex - 1)

						arg_9_0.can_move = true
					end, 1)
				else
					arg_9_0.can_move = true
				end
			else
				arg_9_0.can_move = true
			end
		end, 1.4)
	else
		arg_9_0.can_move = true

		arg_9_0:setCurrentItem(arg_9_0.currentIndex)
	end

	local var_9_0 = xyd.WindowManager.get():getWindow("pet_sweeping")

	if arg_9_0.floorType == xyd.PetCampaignFloorType.SUPER then
		if var_9_0 then
			xyd.WindowManager.get():closeWindow("pet_sweeping")
		end
	elseif tonumber(xyd.ServerTime.get():getServerTime()) <= arg_9_0.petCampaign.begin_sweep_time + var_0_9:getSweepTime(arg_9_0.minSearchIndex, arg_9_0.petCampaign.max_floor) then
		xyd.WindowManager.get():openWindow("pet_sweeping", {
			currentLayer = arg_9_0.minSearchIndex
		})
	end

	if arg_9_0.petCampaign.super.awards then
		arg_9_0.petCampaign.super.awards = nil

		arg_9_0:playFunctionGuide()
	end
end

function var_0_0.playDead(arg_12_0, arg_12_1)
	for iter_12_0 = 1, 6 do
		local var_12_0 = arg_12_0.floorCells[arg_12_1]:getChildByName("container"):getChildByName("model_" .. iter_12_0)

		var_12_0:getChildByName("model"):die()

		local var_12_1 = xyd.tables.model:deathSound(var_12_0.modelID)

		if var_12_1 and var_12_1 ~= "" then
			audio.playSound(var_12_1, false)
		end
	end
end

function var_0_0.playLive(arg_13_0, arg_13_1)
	for iter_13_0 = 1, 6 do
		arg_13_0.floorCells[arg_13_1]:getChildByName("container"):getChildByName("model_" .. iter_13_0):getChildByName("model"):idle()
	end
end

function var_0_0.setCurrentItem(arg_14_0, arg_14_1)
	arg_14_0:nodeByName("list"):removeAllChildren()

	local var_14_0 = arg_14_0:nodeByName("list")

	arg_14_0:initCell(arg_14_1, var_14_0, {
		x = 0,
		y = (var_0_4 - var_0_3) / 2
	})

	if arg_14_1 + 1 <= var_0_9:getMaxLimitFloor(arg_14_0.floorType) then
		table.insert(arg_14_0.delayIndex, arg_14_1 + 1)
	end

	if arg_14_1 - 1 > 0 then
		table.insert(arg_14_0.delayIndex, arg_14_1 - 1)
	end

	arg_14_0.currentIndex = arg_14_1

	if arg_14_0.floorType == xyd.PetCampaignFloorType.SUPER then
		arg_14_0.petCampaign.superFloor = arg_14_1 - 1
	end

	if arg_14_0.floorCells[arg_14_1] then
		arg_14_0.floorCells[arg_14_1]:setLocalZOrder(1)
		arg_14_0.floorCells[arg_14_1]:getChildByName("container"):getChildByName("bottom"):setVisible(true)
		arg_14_0.floorCells[arg_14_1]:getChildByName("container"):getChildByName("avatar_container"):setVisible(true)

		if arg_14_0.floorType == xyd.PetCampaignFloorType.NORMAL then
			arg_14_0.floorCells[arg_14_1]:getChildByName("container"):getChildByName("title_container"):setVisible(true)
		else
			arg_14_0.floorCells[arg_14_1]:getChildByName("container"):getChildByName("super_title_container"):setVisible(true)
		end
	end

	arg_14_0:updateSuperPaper(arg_14_1)
end

function var_0_0.initExchangeBtn(arg_15_0, arg_15_1, arg_15_2)
	arg_15_1:getChildByName("normal_btn"):setVisible(false)
	arg_15_1:getChildByName("super_btn"):setVisible(false)

	if arg_15_0.petCampaign.openSuper then
		if arg_15_0.floorType == xyd.PetCampaignFloorType.SUPER then
			arg_15_1:getChildByName("normal_btn"):setVisible(true)
		else
			arg_15_1:getChildByName("super_btn"):setVisible(true)
		end
	end

	arg_15_1:getChildByName("normal_btn"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.ended and arg_15_0.can_move == true then
			arg_15_0.petCampaign.state = xyd.PetCampaignFloorType.NORMAL
			arg_15_0.floorType = xyd.PetCampaignFloorType.NORMAL

			arg_15_0.petCampaign:initData()

			arg_15_0.currentIndex = arg_15_0.petCampaign.now_floor
			arg_15_0.minSearchIndex = arg_15_0.petCampaign.now_floor
			arg_15_0.floorCells = {}
			arg_15_0.delayIndex = {}

			collectgarbage("collect")
			arg_15_0:checkSweepOver()
			arg_15_0:layout()
		end
	end)
	arg_15_1:getChildByName("super_btn"):addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.ended and arg_15_0.can_move == true then
			arg_15_0.petCampaign.state = xyd.PetCampaignFloorType.SUPER
			arg_15_0.floorType = xyd.PetCampaignFloorType.SUPER
			arg_15_0.hasClickSuper = true

			if arg_15_0.GuideHands then
				arg_15_0.GuideHands:setVisible(false)
			end

			arg_15_0.petCampaign:initData()

			if arg_15_0.petCampaign.superFloor then
				arg_15_0.currentIndex = arg_15_0.petCampaign.superFloor + 1
			else
				arg_15_0.currentIndex = arg_15_0.petCampaign.now_floor
			end

			arg_15_0.minSearchIndex = 0
			arg_15_0.floorCells = {}
			arg_15_0.delayIndex = {}

			collectgarbage("collect")

			arg_15_0.hasInSuper = true

			arg_15_0:checkSweepOver()
			arg_15_0:layout()
		end
	end)

	if arg_15_0.floorType == xyd.PetCampaignFloorType.SUPER then
		arg_15_0.titleContainer = "super_title_container"
		arg_15_0.midBg = "super_border_mid"
		arg_15_0.topBg = "super_border_top"

		arg_15_1:getChildByName("bottom"):getChildByName("restart_words"):setVisible(false)
		arg_15_1:getChildByName("bottom"):getChildByName("restart_btn"):setVisible(false)
		arg_15_1:getChildByName("bottom"):getChildByName("super_bottom_container"):setVisible(true)
		arg_15_1:getChildByName("bottom"):getChildByName("sweep_words"):setVisible(false)

		local var_15_0 = arg_15_1:getChildByName("bottom"):getChildByName("super_bottom_container")

		var_15_0:getChildByName("left_times_words"):setString(var_0_1:translation("PET_CAMPAIGN_SWEEP_TIMES") .. var_0_1:translation("COLON"))
		var_15_0:getChildByName("challenge_coin_text"):setString(string.format(var_0_1:translation("CHALLENGE_PAPAER_NUM"), arg_15_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.skyCitySuperPaper)))

		local var_15_1 = 0

		if arg_15_0.petCampaign.superSweepInfo then
			var_15_1 = arg_15_0.petCampaign.superSweepInfo[arg_15_2]
		end

		local var_15_2 = xyd.tables.misc.skyCitySuperTimesBuy

		var_15_0:getChildByName("left_times_text"):setString(var_15_1 .. " / " .. var_15_2)

		if var_15_1 ~= 0 then
			var_15_0:getChildByName("add_times_btn"):setVisible(false)
		else
			var_15_0:getChildByName("add_times_btn"):setVisible(true)
		end

		arg_15_1:getChildByName("bottom"):getChildByName("awake_sweep_btn"):setVisible(false)
		arg_15_1:getChildByName("bottom"):getChildByName("awake_sweep_words"):setVisible(false)
		arg_15_1:getChildByName("bottom"):getChildByName("practice_words"):setVisible(true)
		arg_15_1:getChildByName("bottom"):getChildByName("rank_words"):setVisible(false)
	else
		arg_15_0.midBg = "border"
		arg_15_0.topBg = "top_border"
		arg_15_0.titleContainer = "title_container"

		arg_15_1:getChildByName("bottom"):getChildByName("restart_words"):setVisible(true)
		arg_15_1:getChildByName("bottom"):getChildByName("restart_btn"):setVisible(true)
		arg_15_1:getChildByName("bottom"):getChildByName("super_bottom_container"):setVisible(false)
		arg_15_1:getChildByName("select_btn"):setVisible(false)
		arg_15_1:getChildByName("bottom"):getChildByName("sweep_this"):setVisible(false)

		local var_15_3 = arg_15_0.task:isHasAwakeOpen(xyd.AwakeType.PET)

		if var_15_3 and var_0_10:stage(var_15_3) == 1 and arg_15_0.petCampaign.can_sweep_times <= 0 then
			arg_15_1:getChildByName("bottom"):getChildByName("awake_sweep_btn"):setVisible(true)
			arg_15_1:getChildByName("bottom"):getChildByName("awake_sweep_words"):setVisible(true)
		end

		arg_15_1:getChildByName("bottom"):getChildByName("practice_words"):setVisible(false)
		arg_15_1:getChildByName("bottom"):getChildByName("rank_words"):setVisible(true)
	end
end

function var_0_0.initCell(arg_18_0, arg_18_1, arg_18_2, arg_18_3)
	if not arg_18_0.floorCells[arg_18_1] or tolua.isnull(arg_18_0.floorCells[arg_18_1]) then
		arg_18_0.canDisplay_ = false

		local var_18_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petCampaign/CampaignItem.csb")
		local var_18_1 = var_18_0:getChildByName("container")
		local var_18_2 = var_18_1:getChildByName("award_bg")
		local var_18_3 = var_18_1:getContentSize()
		local var_18_4 = xyd.SpriteLoader.new(var_0_9:getMap(arg_18_0.floorType, arg_18_1), nil, nil, xyd.DefaultImageType.MAP)
		local var_18_5 = xyd.AssetLoader:get():loadSprite("windows/pet/petCampaign/border_1.png")
		local var_18_6 = cc.ClippingNode:create()

		var_18_6:setStencil(var_18_5)
		var_18_6:setInverted(false)
		var_18_6:setAlphaThreshold(0)
		var_18_6:addChild(var_18_4)
		var_18_4:align(display.CENTER, var_18_3.width / 2, var_18_3.height / 2)
		var_18_4:scale(var_18_3.width / var_18_4:getWidth())
		var_18_5:addTo(var_18_1, -1)
		var_18_5:align(display.CENTER, var_18_3.width / 2, var_18_3.height / 2)
		var_18_5:scale((var_18_3.width - 3) / var_18_5:getWidth())
		var_18_1:addChild(var_18_6)
		var_18_6:setLocalZOrder(-1)
		arg_18_0:initExchangeBtn(var_18_1, arg_18_1)

		arg_18_0.floorCells[arg_18_1] = var_18_0

		local var_18_7 = 0
		local var_18_8 = var_0_9:getItem(arg_18_0.floorType, arg_18_1)
		local var_18_9 = var_0_9:getItemNum(arg_18_0.floorType, arg_18_1, arg_18_0.selfPlayer.vip >= var_0_7)
		local var_18_10 = arg_18_0.task:isHasAwakeOpen(xyd.AwakeType.PET)

		if var_18_10 and var_0_10:stage(var_18_10) == 1 and var_0_10:pet_campaign_id(var_18_10) == arg_18_1 then
			local var_18_11 = var_0_10:awaken_piece(var_18_10)
			local var_18_12 = 1

			table.insert(var_18_8, var_18_11)
			table.insert(var_18_9, var_18_12)
		end

		if arg_18_1 >= arg_18_0.petCampaign.max_floor then
			var_18_8 = var_0_9:getFirstDrop(arg_18_0.floorType, arg_18_1)
			var_18_9 = var_0_9:getFirstDropNum(arg_18_0.floorType, arg_18_1, arg_18_0.selfPlayer.vip >= var_0_7)
		end

		for iter_18_0, iter_18_1 in ipairs(var_18_8) do
			local var_18_13 = cc.Node:create()

			var_18_13:setContentSize(50, 50)
			xyd.setItemBorder(var_18_13, iter_18_1, nil, nil, var_18_9[iter_18_0])
			var_18_2:getChildByName("icons"):addChild(var_18_13)
			var_18_13:setPosition(var_18_7, 0)

			var_18_7 = var_18_7 + 60

			local var_18_14 = {
				id = iter_18_1
			}

			arg_18_0:addTips(var_18_13, var_18_14)
		end

		var_18_1:getChildByName("super_border_top"):setVisible(false)
		var_18_1:getChildByName("super_border_mid"):setVisible(false)
		var_18_1:getChildByName("top_border"):setVisible(false)
		var_18_1:getChildByName("border"):setVisible(false)

		if arg_18_1 == var_0_9:getMaxLimitFloor(arg_18_0.floorType) then
			var_18_1:getChildByName(arg_18_0.topBg):setVisible(true)
			var_18_1:getChildByName(arg_18_0.topBg):setScale(1)
		else
			var_18_1:getChildByName(arg_18_0.midBg):setVisible(true)
		end

		local var_18_15 = xyd.AssetLoader.get():loadLabel(nil, "petBattle")

		if arg_18_0.petCampaign.state == xyd.PetCampaignFloorType.SUPER then
			var_18_15 = xyd.AssetLoader.get():loadLabel(nil, "super_sky")
		end

		var_18_15:setString(arg_18_1)
		var_18_15:addTo(var_18_1:getChildByName(arg_18_0.titleContainer):getChildByName("num_node"))
		var_18_15:setAnchorPoint(cc.p(0.5, 0.5))

		local var_18_16 = var_18_1:getContentSize()

		var_18_0:setContentSize(var_18_16)
		var_18_0:setTouchSwallowEnabled(false)
		var_18_1:getChildByName("title_container"):setVisible(false)
		var_18_1:getChildByName("super_title_container"):setVisible(false)
		var_18_1:getChildByName("bottom"):setVisible(false)
		var_18_1:getChildByName("avatar_container"):setVisible(false)

		local var_18_17 = var_0_9:getMonster(arg_18_0.floorType, arg_18_1)

		arg_18_0.monsterTips = {}

		for iter_18_2 = 1, #var_18_17 do
			local var_18_18 = {}
			local var_18_19 = cc.Node:create()

			var_18_18.isBoss = false

			var_18_19:setContentSize(90, 90)
			xyd.setAvatarBorderWithLevelAndHp(var_18_17[iter_18_2], var_18_19, var_0_9:monsterQuality(arg_18_0.floorType, arg_18_1)[iter_18_2], var_0_9:monsterStar(arg_18_0.floorType, arg_18_1)[iter_18_2], var_0_9:monsterLevel(arg_18_0.floorType, arg_18_1)[iter_18_2])
			var_18_1:getChildByName("avatar_container"):addChild(var_18_19)
			var_18_19:setPosition(iter_18_2 * 95 - 95, 0)

			var_18_18.id = var_18_17[iter_18_2]
			var_18_18.lev = var_0_9:monsterLevel(arg_18_0.floorType, arg_18_1)[iter_18_2]
			var_18_18.quality = var_0_9:monsterQuality(arg_18_0.floorType, arg_18_1)[iter_18_2]
			var_18_18.name = xyd.tables.hero:name(var_18_17[iter_18_2])
			var_18_18.desc = xyd.tables.hero:getDes(var_18_17[iter_18_2])
			var_18_18.isHero = true

			local var_18_20, var_18_21 = var_18_19:getPosition()

			var_18_19:setTouchEnabled(true)
			var_18_19:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_19_0)
				if arg_19_0.name == "began" then
					local var_19_0 = xyd.WindowManager.get():getWindow("new_item_tips")
					local var_19_1 = arg_18_0:convertToWorldSpace(cc.p(0, 0))

					if not var_19_0 then
						local var_19_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_18_18)

						xyd.adaptToWorldPosition(var_18_19, var_19_2)
					end

					return true
				elseif arg_19_0.name == "ended" then
					xyd.WindowManager.get():closeWindow("new_item_tips")
				end
			end)
		end

		if arg_18_1 == arg_18_0.currentIndex then
			arg_18_0:layoutMonsterModels(arg_18_1)

			var_18_0.modelStatus = 1
		else
			var_18_0.modelStatus = 0
		end

		var_18_0:addTo(arg_18_2)
		var_18_0:setPosition(arg_18_3.x, arg_18_3.y)

		arg_18_0.canDisplay_ = true

		arg_18_0:addButtonEvent(var_18_1, arg_18_1)
	end

	return arg_18_0.floorCells[arg_18_1]
end

function var_0_0.initHasDoneCell(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	if not arg_20_0.floorCells[arg_20_1] or tolua.isnull(arg_20_0.floorCells[arg_20_1]) then
		arg_20_0.canDisplay_ = false

		local var_20_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petCampaign/CampaignItem.csb")
		local var_20_1 = var_20_0:getChildByName("container")
		local var_20_2 = var_20_1:getContentSize()
		local var_20_3 = xyd.SpriteLoader.new(var_0_9:getMap(arg_20_0.floorType, arg_20_1), nil, nil, xyd.DefaultImageType.MAP)
		local var_20_4 = xyd.AssetLoader:get():loadSprite("windows/pet/petCampaign/border_1.png")
		local var_20_5 = cc.ClippingNode:create()

		var_20_5:setStencil(var_20_4)
		var_20_5:setInverted(false)
		var_20_5:setAlphaThreshold(0)
		var_20_5:addChild(var_20_3)
		var_20_3:align(display.CENTER, var_20_2.width / 2, var_20_2.height / 2)
		var_20_3:scale(var_20_2.width / var_20_3:getWidth())
		var_20_4:addTo(var_20_1, -1)
		var_20_4:align(display.CENTER, var_20_2.width / 2, var_20_2.height / 2)
		var_20_4:scale((var_20_2.width - 3) / var_20_4:getWidth())
		var_20_1:addChild(var_20_5)
		var_20_5:setLocalZOrder(-1)

		local var_20_6 = var_20_1:getContentSize()

		var_20_0:setContentSize(var_20_6)
		var_20_0:setTouchSwallowEnabled(false)
		arg_20_0:initExchangeBtn(var_20_1, arg_20_1)
		var_20_1:getChildByName("title_container"):setVisible(false)
		var_20_1:getChildByName("super_title_container"):setVisible(false)
		var_20_1:getChildByName("bottom"):setVisible(false)
		var_20_1:getChildByName("avatar_container"):setVisible(false)

		arg_20_0.floorCells[arg_20_1] = var_20_0

		var_20_0:addTo(arg_20_2)
		var_20_0:setPosition(arg_20_3.x, arg_20_3.y)

		arg_20_0.canDisplay_ = true

		var_20_1:getChildByName("super_border_top"):setVisible(false)
		var_20_1:getChildByName("super_border_mid"):setVisible(false)
		var_20_1:getChildByName("top_border"):setVisible(false)
		var_20_1:getChildByName("border"):setVisible(false)

		if arg_20_1 == var_0_9:getMaxLimitFloor(arg_20_0.floorType) then
			var_20_1:getChildByName(arg_20_0.topBg):setVisible(true)
			var_20_1:getChildByName(arg_20_0.topBg):setScale(1)
		else
			var_20_1:getChildByName(arg_20_0.midBg):setVisible(true)
		end
	end

	return arg_20_0.floorCells[arg_20_1]
end

function var_0_0.layoutMonsterModels(arg_21_0, arg_21_1)
	local var_21_0 = var_0_9:getMonster(arg_21_0.floorType, arg_21_1)
	local var_21_1 = arg_21_0.floorCells[arg_21_1]:getChildByName("container")

	if var_21_1 and not tolua.isnull(var_21_1) then
		for iter_21_0 = 1, #var_21_0 do
			if xyd.tables.hero:name(var_21_0[iter_21_0]) ~= "" then
				local var_21_2 = var_0_5.new()

				var_21_2:populateWithTableID(var_21_0[iter_21_0])
				arg_21_0:updateHeroModel(var_21_2, var_21_1:getChildByName("model_" .. iter_21_0))
			end
		end
	end
end

function var_0_0.addButtonEvent(arg_22_0, arg_22_1, arg_22_2)
	local var_22_0 = arg_22_1:getChildByName("bottom")

	if arg_22_0.floorType == xyd.PetCampaignFloorType.SUPER then
		arg_22_1:getChildByName("bar"):setPercent(arg_22_0.petCampaign.super.max_floor / var_0_9:getMaxLimitFloor(arg_22_0.floorType) * 100)
	else
		arg_22_1:getChildByName("bar"):setPercent(arg_22_0.minSearchIndex / var_0_9:getMaxLimitFloor(arg_22_0.floorType) * 100)
	end

	arg_22_1:getChildByName("up_btn"):addTouchEventListener(function(arg_23_0, arg_23_1)
		if arg_23_1 == ccui.TouchEventType.ended and arg_22_0.can_move == true then
			if arg_22_0.currentIndex < var_0_9:getMaxLimitFloor(arg_22_0.floorType) then
				if arg_22_0.currentIndex < arg_22_0.minSearchIndex + var_0_6 or arg_22_0.floorType == xyd.PetCampaignFloorType.SUPER then
					arg_22_0.can_move = false

					var_0_8.performWithDelayGlobal(function()
						arg_22_0.can_move = true
					end, var_0_2 + 0.1)
					arg_22_0:moveList(true)
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("SKY_UP_TIP")
					})
				end
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("SKY_UP_TIP")
				})
			end
		end
	end)
	arg_22_1:getChildByName("down_btn"):addTouchEventListener(function(arg_25_0, arg_25_1)
		if arg_25_1 == ccui.TouchEventType.ended and arg_22_0.can_move == true then
			if arg_22_0.currentIndex > 1 then
				if arg_22_0.currentIndex > arg_22_0.minSearchIndex or arg_22_0.floorType == xyd.PetCampaignFloorType.SUPER then
					arg_22_0.can_move = false

					var_0_8.performWithDelayGlobal(function()
						arg_22_0.can_move = true
					end, var_0_2 + 0.1)
					arg_22_0:moveList(false)
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("SKY_DOWN_TIP")
					})
				end
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("SKY_DOWN_TIP")
				})
			end
		end
	end)
	var_22_0:getChildByName("rule_btn"):addTouchEventListener(function(arg_27_0, arg_27_1)
		if arg_27_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_27_0 = {
				floorType = arg_22_0.floorType
			}

			xyd.WindowManager.get():openWindow("pet_campaign_rule", var_27_0)
		end
	end)
	var_22_0:getChildByName("rank_btn"):addTouchEventListener(function(arg_28_0, arg_28_1)
		if arg_28_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_22_0.floorType == xyd.PetCampaignFloorType.SUPER then
				local var_28_0 = false

				if arg_22_0.selfPlayer.mana < xyd.tables.misc.skyCityTestCost then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, xyd.tables.translation:translation("JINBI_ABSENCE"), function()
						local var_29_0 = xyd.FunctionID.ID_GOLD_HAND

						if arg_22_0.selfPlayer:isFuncOpen(var_29_0) == true then
							xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
						else
							local var_29_1 = xyd.tables.functionOpen:level(var_29_0)
							local var_29_2 = string.format(xyd.tables.translation:translation("FUNCTION_OPEN_TIP_LEVEL"), var_29_1)

							xyd.WindowManager.get():openWindow("toast", {
								message = var_29_2
							})
						end
					end, nil, nil, arg_22_0.colorMode)
				else
					var_28_0 = true
				end

				if not var_28_0 then
					return
				end

				xyd.WindowManager.get():closeWindow("new_item_tips")

				local var_28_1 = {
					campaign_type = xyd.CampaignType.PET
				}

				arg_22_0.guild:loadAllTeamHeros(var_28_1, function(arg_30_0)
					local var_30_0 = false
					local var_30_1 = {}

					if arg_30_0 == xyd.error.OK then
						var_30_0 = true

						for iter_30_0, iter_30_1 in ipairs(arg_22_0.guild:getAllTeamHeros()) do
							local var_30_2 = var_0_5.new()

							var_30_2:populate(iter_30_1)

							var_30_2.player_name = iter_30_1.player_name
							var_30_2.rent_need_mana = iter_30_1.rent_need_mana
							var_30_2.can_rent = iter_30_1.can_rent
							var_30_2.player_id = iter_30_1.player_id

							table.insert(var_30_1, var_30_2)
						end
					end

					local var_30_3 = arg_22_0.petCampaign.testFormation[arg_22_2] or {}
					local var_30_4 = var_30_3.heros or {}
					local var_30_5 = {}
					local var_30_6 = {}

					if var_30_3.pet then
						table.insert(var_30_6, arg_22_0.selfPlayer:getPetByID(var_30_3.pet))
					end

					for iter_30_2, iter_30_3 in pairs(var_30_4) do
						table.insert(var_30_5, arg_22_0.selfPlayer:getHeroByID(iter_30_3))
					end

					local var_30_7 = {
						isPet = true,
						type = xyd.SelectTeamType.PET_PRACTICE,
						isMercenary = var_30_0,
						allTeamHeros = var_30_1,
						campaignID = var_0_9:getCampaignId(arg_22_0.floorType, arg_22_2),
						petFloor = arg_22_2,
						petFloorType = arg_22_0.floorType,
						campaignType = xyd.CampaignType.PET,
						selected = var_30_4,
						preHeros = var_30_5,
						prePet = var_30_6
					}

					xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_30_7)
				end)
			else
				local var_28_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.RANK_LIST)

				var_28_2:loadRankList({
					xyd.SubRankType.SKYCITY_SUB_RANK
				}, true, function(arg_31_0, arg_31_1)
					if arg_31_0 == xyd.error.OK then
						local var_31_0 = {
							rank_type = xyd.RankType.PetCampaign,
							sub_type = xyd.SubRankType.SKYCITY_SUB_RANK,
							rankData = var_28_2:getRankList()
						}

						xyd.WindowManager.get():openWindow("new_rank_list", var_31_0)
					end
				end)
			end
		end
	end)
	var_22_0:getChildByName("restart_btn"):addTouchEventListener(function(arg_32_0, arg_32_1)
		if arg_32_1 == ccui.TouchEventType.ended and xyd.WindowManager.get():getWindow("pet_sweeping") == nil then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("PET_CAMPAIGN_RESTART"), function()
				if arg_22_0.petCampaign.challenge_times >= 1 then
					arg_22_0.petCampaign:restart(function(arg_34_0, arg_34_1)
						if arg_34_0 == xyd.error.OK then
							arg_22_0.currentIndex = 1
							arg_22_0.minSearchIndex = 1
							arg_22_0.floorCells = {}

							arg_22_0:setCurrentItem(1)
						end
					end)
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("MARCH_RESET_ALL_USED")
					})
				end
			end, nil, nil, arg_22_0.colorMode)
		end
	end)

	local var_22_1 = arg_22_0.task:isHasAwakeOpen(xyd.AwakeType.PET)

	if var_22_1 and var_0_10:stage(var_22_1) == 1 and arg_22_0.petCampaign.can_sweep_times <= 0 then
		var_22_0:getChildByName("awake_sweep_btn"):addTouchEventListener(function(arg_35_0, arg_35_1)
			if arg_35_1 == ccui.TouchEventType.ended then
				if xyd.WindowManager.get():getWindow("pet_sweeping") then
					return
				end

				local var_35_0 = arg_22_0.petCampaign.mission_sweep_times

				if var_0_10:pet_campaign_id(var_22_1) > arg_22_0.petCampaign.max_floor then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("PET_CAMPAIGN_NOT_REACHABLE_FLOOR")
					})
				elseif var_35_0 < var_0_13 then
					local var_35_1 = xyd.tables.misc.petAwakenSweepCost[var_35_0 + 1]

					if var_35_1 > arg_22_0.selfPlayer.crystal then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
							local var_36_0 = {}

							var_36_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_36_0)
						end, nil, nil, arg_22_0.colorMode)
					else
						local var_35_2 = {
							txt = string.format(var_0_1:translation("PET_CAMPAIGN_AWAKE_SWEEP_ALERT"), var_35_0, var_35_1),
							rcallback = function(arg_37_0)
								if arg_37_0.name == "ended" then
									local var_37_0 = xyd.WindowManager.get():getWindow("pet_sweeping")
									local var_37_1 = {
										floor = var_0_10:pet_campaign_id(var_22_1)
									}

									if var_37_0 == nil then
										arg_22_0.petCampaign:awakeSweep(function(arg_38_0, arg_38_1)
											if arg_38_0 == xyd.error.OK then
												local var_38_0 = arg_38_1.awards

												xyd.WindowManager.get():openWindow("pet_campaign_award", {
													isFinishAward = true,
													currentLayer = arg_22_0.minSearchIndex,
													awards = var_38_0
												})
											end
										end, var_37_1)
									end
								end
							end
						}

						xyd.WindowManager.get():openWindow("common_alert", var_35_2)
					end
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = string.format(var_0_1:translation("PET_CAMPAIGN_AWAKE_SWEEP_OUT_OF_TIMES"), var_0_13)
					})
				end
			end
		end)
	end

	local var_22_2 = var_22_0:getChildByName("super_bottom_container")

	var_22_0:getChildByName("sweep_btn"):addTouchEventListener(function(arg_39_0, arg_39_1)
		if arg_39_1 == ccui.TouchEventType.ended then
			local var_39_0 = xyd.WindowManager.get():getWindow("pet_sweeping")

			if arg_22_0.floorType == xyd.PetCampaignFloorType.SUPER then
				local var_39_1 = {
					campaign_id = var_0_9:getCampaignId(arg_22_0.floorType, arg_22_2)
				}

				if arg_22_0.petCampaign.superSweepInfo[arg_22_2] > 0 and arg_22_2 < arg_22_0.petCampaign.max_floor then
					if arg_22_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.skyCitySuperPaper) > 0 and not arg_22_0.canNotClickSweep then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("SKY_SUPER_SWEEP_CONFIRM"), function()
							arg_22_0.canNotClickSweep = true

							arg_22_0.petCampaign:sweepSuper(var_39_1, function(arg_41_0, arg_41_1)
								if arg_41_0 == xyd.error.OK then
									arg_22_0.canNotClickSweep = false

									var_22_2:getChildByName("challenge_coin_text"):setString(string.format(var_0_1:translation("CHALLENGE_PAPAER_NUM"), arg_22_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.skyCitySuperPaper)))

									local var_41_0 = arg_22_0.petCampaign.superSweepInfo[arg_22_2]
									local var_41_1 = xyd.tables.misc.skyCitySuperTimesBuy

									var_22_2:getChildByName("left_times_text"):setString(var_41_0 .. " / " .. var_41_1)

									if var_41_0 ~= 0 then
										var_22_2:getChildByName("add_times_btn"):setVisible(false)
									else
										var_22_2:getChildByName("add_times_btn"):setVisible(true)
									end

									xyd.WindowManager.get():openWindow("pet_campaign_award", {
										isFinishAward = true,
										currentLayer = arg_22_2,
										awards = arg_41_1.awards
									})
								end
							end)
						end, nil, nil, arg_22_0.colorMode)
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("SKYCITY_HARD_BUY_TIP3")
						})
					end
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("SKYCITY_HARD_BUY_TIP2")
					})
				end
			elseif var_39_0 == nil then
				if arg_22_0.petCampaign.real_now_floor >= arg_22_0.petCampaign.max_floor or arg_22_0.petCampaign.can_sweep_times <= 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("MAP_NO_SWEEP")
					})
				else
					xyd.WindowManager.get():openWindow("pet_campaign_award", {
						currentLayer = arg_22_0.minSearchIndex
					})
				end
			end
		end
	end)
	var_22_0:getChildByName("super_bottom_container"):getChildByName("add_times_btn"):addTouchEventListener(function(arg_42_0, arg_42_1)
		if arg_42_1 == ccui.TouchEventType.ended and arg_22_0.can_move == true then
			if arg_22_0.petCampaign.superSweepInfo[arg_22_2] and arg_22_0.petCampaign.superSweepInfo[arg_22_2] >= xyd.tables.misc.skyCitySuperTimesBuy then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("SKY_SUPER_CANT_BUY")
				})
			else
				local var_42_0 = xyd.tables.refreshCost:skycityHardCost(arg_22_0.petCampaign.superBuyInfo[arg_22_2] + 1)
				local var_42_1 = string.format(var_0_1:translation("SKY_SUPER_BUY_TIMES"), var_42_0)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_42_1, function()
					if var_42_0 > arg_22_0.selfPlayer.crystal then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
							local var_44_0 = {}

							var_44_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_44_0)
						end, nil, nil, arg_22_0.colorMode)
					else
						local var_43_0 = {
							floor = arg_22_2
						}

						arg_22_0.petCampaign:buySuper(var_43_0, function(arg_45_0, arg_45_1)
							if arg_45_0 == xyd.error.OK then
								local var_45_0 = arg_22_0.petCampaign.superSweepInfo[arg_22_2]
								local var_45_1 = xyd.tables.misc.skyCitySuperTimesBuy

								var_22_2:getChildByName("left_times_text"):setString(var_45_0 .. " / " .. var_45_1)

								if var_45_0 ~= 0 then
									var_22_2:getChildByName("add_times_btn"):setVisible(false)
								else
									var_22_2:getChildByName("add_times_btn"):setVisible(true)
								end

								local var_45_2 = var_0_1:translation("BUY_SUCCESS")

								xyd.WindowManager.get():openWindow("toast", {
									message = var_45_2
								})
							end
						end)
					end
				end, nil, 0, arg_22_0.colorMode)
			end
		end
	end)
	arg_22_1:getChildByName("select_btn"):addTouchEventListener(function(arg_46_0, arg_46_1)
		if arg_46_1 == ccui.TouchEventType.ended and arg_22_0.can_move == true then
			xyd.WindowManager.get():openWindow("super_select_level")
		end
	end)

	local var_22_3 = display.newFilteredSprite("windows/button/battle_btn1.png", "GRAY", {
		0.2,
		0.3,
		0.5,
		0.1
	})
	local var_22_4
	local var_22_5

	if arg_22_0.floorType == xyd.PetCampaignFloorType.NORMAL then
		if arg_22_2 ~= arg_22_0.minSearchIndex or arg_22_0.minSearchIndex == var_0_9:getMaxLimitFloor(arg_22_0.floorType) and arg_22_0.petCampaign.max_floor > var_0_9:getMaxLimitFloor(arg_22_0.floorType) and arg_22_0.petCampaign.max_floor <= arg_22_0.petCampaign.real_now_floor then
			var_22_5 = false
		else
			var_22_5 = true
		end
	elseif arg_22_2 <= arg_22_0.petCampaign.max_floor then
		var_22_5 = true
	else
		var_22_5 = false
	end

	var_22_0:getChildByName("fight_btn").can_click = var_22_5

	if var_22_5 == false then
		var_22_3:setAnchorPoint(0, 0)
		var_22_3:addTo(var_22_0:getChildByName("fight_btn"))
	else
		var_22_0:getChildByName("fight_btn"):addTouchEventListener(function(arg_47_0, arg_47_1)
			if arg_47_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				if arg_22_0.floorType == xyd.PetCampaignFloorType.SUPER and arg_22_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.skyCitySuperPaper) == 0 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("SKYCITY_HARD_BUY_TIP3")
					})

					return
				end

				if xyd.WindowManager.get():getWindow("pet_sweeping") == nil or arg_22_0.floorType == xyd.PetCampaignFloorType.SUPER then
					xyd.WindowManager.get():closeWindow("new_item_tips")

					arg_22_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

					local var_47_0 = {
						campaign_type = xyd.CampaignType.PET
					}

					arg_22_0.guild:loadAllTeamHeros(var_47_0, function(arg_48_0)
						local var_48_0 = false
						local var_48_1 = {}

						if arg_48_0 == xyd.error.OK then
							var_48_0 = true

							for iter_48_0, iter_48_1 in ipairs(arg_22_0.guild:getAllTeamHeros()) do
								local var_48_2 = var_0_5.new()

								var_48_2:populate(iter_48_1)

								var_48_2.player_name = iter_48_1.player_name
								var_48_2.rent_need_mana = iter_48_1.rent_need_mana
								var_48_2.can_rent = iter_48_1.can_rent
								var_48_2.player_id = iter_48_1.player_id

								table.insert(var_48_1, var_48_2)
							end
						end

						local var_48_3 = {
							isPet = true,
							type = xyd.SelectTeamType.PET,
							isMercenary = var_48_0,
							allTeamHeros = var_48_1,
							campaignID = var_0_9:getCampaignId(arg_22_0.floorType, arg_22_2),
							campaignType = xyd.CampaignType.PET,
							petFloor = arg_22_2,
							petFloorType = arg_22_0.floorType
						}

						xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_48_3)
					end)
				end
			end
		end)
	end
end

function var_0_0.updateHeroModel(arg_49_0, arg_49_1, arg_49_2)
	if arg_49_2 and not tolua.isnull(arg_49_2) then
		local var_49_0 = arg_49_1:getHeroModel()

		var_49_0:setFlipX(true)
		var_49_0:setTouchSwallowEnabled(false)

		local var_49_1 = arg_49_2:getContentSize().width / 2

		var_49_0:setPosition(cc.p(var_49_1, 0))
		arg_49_2:removeAllChildren()
		var_49_0:setScale(0.7)
		var_49_0:setName("model")
		var_49_0:addTo(arg_49_2)
	end
end

function var_0_0.moveList(arg_50_0, arg_50_1)
	local var_50_0 = arg_50_0:nodeByName("list")
	local var_50_1 = 0

	if arg_50_0.floorType == xyd.PetCampaignFloorType.SUPER then
		for iter_50_0, iter_50_1 in pairs(arg_50_0.floorCells) do
			var_50_1 = var_50_1 + 1
		end
	end

	if arg_50_1 == true then
		if arg_50_0.floorCells[arg_50_0.currentIndex + 1] and arg_50_0.floorCells[arg_50_0.currentIndex + 1].modelStatus == 0 then
			arg_50_0:layoutMonsterModels(arg_50_0.currentIndex + 1)

			arg_50_0.floorCells[arg_50_0.currentIndex + 1].modelStatus = 1
		end

		if arg_50_0.currentIndex + 2 <= var_0_9:getMaxLimitFloor(arg_50_0.floorType) and not arg_50_0.floorCells[arg_50_0.currentIndex + 2] then
			arg_50_0:initCell(arg_50_0.currentIndex + 2, var_50_0, {
				x = 0,
				y = var_0_3 * 2 + (var_0_4 - var_0_3) / 2
			})
		end

		if not tolua.isnull(arg_50_0.floorCells[arg_50_0.currentIndex]) then
			transition.moveTo(arg_50_0.floorCells[arg_50_0.currentIndex], {
				y = arg_50_0.floorCells[arg_50_0.currentIndex]:getPositionY() - var_0_3,
				time = var_0_2
			})
		end

		if arg_50_0.currentIndex - 1 >= 1 and not tolua.isnull(arg_50_0.floorCells[arg_50_0.currentIndex - 1]) then
			transition.moveTo(arg_50_0.floorCells[arg_50_0.currentIndex - 1], {
				y = arg_50_0.floorCells[arg_50_0.currentIndex - 1]:getPositionY() - var_0_3,
				time = var_0_2
			})
		end

		if arg_50_0.currentIndex + 1 <= var_0_9:getMaxLimitFloor(arg_50_0.floorType) and not tolua.isnull(arg_50_0.floorCells[arg_50_0.currentIndex + 1]) then
			transition.moveTo(arg_50_0.floorCells[arg_50_0.currentIndex + 1], {
				y = arg_50_0.floorCells[arg_50_0.currentIndex + 1]:getPositionY() - var_0_3,
				time = var_0_2
			})
		end

		if arg_50_0.currentIndex + 2 <= var_0_9:getMaxLimitFloor(arg_50_0.floorType) and not tolua.isnull(arg_50_0.floorCells[arg_50_0.currentIndex + 2]) then
			transition.moveTo(arg_50_0.floorCells[arg_50_0.currentIndex + 2], {
				y = arg_50_0.floorCells[arg_50_0.currentIndex + 2]:getPositionY() - var_0_3,
				time = var_0_2
			})
		end

		if not tolua.isnull(arg_50_0.floorCells[arg_50_0.currentIndex + 1]) then
			arg_50_0.floorCells[arg_50_0.currentIndex + 1]:setLocalZOrder(var_0_9:getMaxLimitFloor(arg_50_0.floorType))
			arg_50_0.floorCells[arg_50_0.currentIndex + 1]:getChildByName("container"):getChildByName(arg_50_0.titleContainer):setVisible(true)
			arg_50_0.floorCells[arg_50_0.currentIndex + 1]:getChildByName("container"):getChildByName("bottom"):setVisible(true)
			arg_50_0.floorCells[arg_50_0.currentIndex + 1]:getChildByName("container"):getChildByName("avatar_container"):setVisible(true)
		end

		if not tolua.isnull(arg_50_0.floorCells[arg_50_0.currentIndex]) then
			arg_50_0.floorCells[arg_50_0.currentIndex]:getChildByName("container"):getChildByName("bottom"):setVisible(false)
			arg_50_0.floorCells[arg_50_0.currentIndex]:getChildByName("container"):getChildByName(arg_50_0.titleContainer):setVisible(false)
			arg_50_0.floorCells[arg_50_0.currentIndex]:setLocalZOrder(0)
			arg_50_0.floorCells[arg_50_0.currentIndex]:getChildByName("container"):getChildByName("avatar_container"):setVisible(false)
		end

		arg_50_0.currentIndex = arg_50_0.currentIndex + 1

		if arg_50_0.floorType == xyd.PetCampaignFloorType.SUPER then
			arg_50_0.petCampaign.super.now_floor = arg_50_0.currentIndex - 1
			arg_50_0.petCampaign.superFloor = arg_50_0.currentIndex - 1

			if var_50_1 > var_0_14 then
				for iter_50_2 = 1, var_0_9:getMaxLimitFloor(arg_50_0.floorType) do
					if arg_50_0.floorCells[iter_50_2] then
						arg_50_0:nodeByName("list"):removeChild(arg_50_0.floorCells[iter_50_2])

						arg_50_0.floorCells[iter_50_2] = nil

						collectgarbage("collect")

						break
					end
				end
			end
		end
	else
		if arg_50_0.floorCells[arg_50_0.currentIndex - 1] and arg_50_0.floorCells[arg_50_0.currentIndex - 1].modelStatus == 0 then
			arg_50_0:layoutMonsterModels(arg_50_0.currentIndex - 1)

			arg_50_0.floorCells[arg_50_0.currentIndex - 1].modelStatus = 1
		end

		if arg_50_0.currentIndex - 2 >= 1 then
			arg_50_0:initCell(arg_50_0.currentIndex - 2, var_50_0, {
				x = 0,
				y = -var_0_3 * 2 + (var_0_4 - var_0_3) / 2
			})
		end

		if not tolua.isnull(arg_50_0.floorCells[arg_50_0.currentIndex]) then
			transition.moveTo(arg_50_0.floorCells[arg_50_0.currentIndex], {
				y = arg_50_0.floorCells[arg_50_0.currentIndex]:getPositionY() + var_0_3,
				time = var_0_2
			})
		end

		if arg_50_0.currentIndex + 1 <= var_0_9:getMaxLimitFloor(arg_50_0.floorType) and not tolua.isnull(arg_50_0.floorCells[arg_50_0.currentIndex + 1]) then
			transition.moveTo(arg_50_0.floorCells[arg_50_0.currentIndex + 1], {
				y = arg_50_0.floorCells[arg_50_0.currentIndex + 1]:getPositionY() + var_0_3,
				time = var_0_2
			})
		end

		if arg_50_0.currentIndex - 1 >= 1 and not tolua.isnull(arg_50_0.floorCells[arg_50_0.currentIndex - 1]) then
			transition.moveTo(arg_50_0.floorCells[arg_50_0.currentIndex - 1], {
				y = arg_50_0.floorCells[arg_50_0.currentIndex - 1]:getPositionY() + var_0_3,
				time = var_0_2
			})
		end

		if arg_50_0.currentIndex - 2 >= 1 and not tolua.isnull(arg_50_0.floorCells[arg_50_0.currentIndex - 2]) then
			transition.moveTo(arg_50_0.floorCells[arg_50_0.currentIndex - 2], {
				y = arg_50_0.floorCells[arg_50_0.currentIndex - 2]:getPositionY() + var_0_3,
				time = var_0_2
			})
		end

		if not tolua.isnull(arg_50_0.floorCells[arg_50_0.currentIndex - 1]) then
			arg_50_0.floorCells[arg_50_0.currentIndex - 1]:setLocalZOrder(var_0_9:getMaxLimitFloor(arg_50_0.floorType))
			arg_50_0.floorCells[arg_50_0.currentIndex - 1]:getChildByName("container"):getChildByName(arg_50_0.titleContainer):setVisible(true)
			arg_50_0.floorCells[arg_50_0.currentIndex - 1]:getChildByName("container"):getChildByName("bottom"):setVisible(true)
			arg_50_0.floorCells[arg_50_0.currentIndex - 1]:getChildByName("container"):getChildByName("avatar_container"):setVisible(true)
		end

		if not tolua.isnull(arg_50_0.floorCells[arg_50_0.currentIndex]) then
			arg_50_0.floorCells[arg_50_0.currentIndex]:setLocalZOrder(0)
			arg_50_0.floorCells[arg_50_0.currentIndex]:getChildByName("container"):getChildByName(arg_50_0.titleContainer):setVisible(false)
			arg_50_0.floorCells[arg_50_0.currentIndex]:getChildByName("container"):getChildByName("bottom"):setVisible(false)
			arg_50_0.floorCells[arg_50_0.currentIndex]:getChildByName("container"):getChildByName("avatar_container"):setVisible(false)
		end

		arg_50_0.currentIndex = arg_50_0.currentIndex - 1

		if arg_50_0.floorType == xyd.PetCampaignFloorType.SUPER then
			arg_50_0.petCampaign.super.now_floor = arg_50_0.currentIndex - 1
			arg_50_0.petCampaign.superFloor = arg_50_0.currentIndex - 1

			if var_50_1 > var_0_14 then
				for iter_50_3 = var_0_9:getMaxLimitFloor(arg_50_0.floorType), 1, -1 do
					if arg_50_0.floorCells[iter_50_3] then
						arg_50_0:nodeByName("list"):removeChild(arg_50_0.floorCells[iter_50_3])

						arg_50_0.floorCells[iter_50_3] = nil

						collectgarbage("collect")

						break
					end
				end
			end
		end
	end

	arg_50_0:updateSuperPaper()
end

function var_0_0.updateSuperPaper(arg_51_0, arg_51_1)
	local var_51_0 = arg_51_1 or arg_51_0.currentIndex

	if arg_51_0.floorCells[var_51_0] then
		arg_51_0.floorCells[arg_51_0.currentIndex]:getChildByName("container"):getChildByName("bottom"):getChildByName("super_bottom_container"):getChildByName("challenge_coin_text"):setString(string.format(var_0_1:translation("CHALLENGE_PAPAER_NUM"), arg_51_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.skyCitySuperPaper)))
	end
end

function var_0_0.didOpen(arg_52_0, arg_52_1)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_52_0):addEventListener(xyd.event.SKY_CHANGE_FLOOR, function(arg_53_0)
		arg_52_0.currentIndex = arg_53_0.params
		arg_52_0.minSearchIndex = 0
		arg_52_0.floorCells = {}

		arg_52_0:setCurrentItem(arg_53_0.params)
	end)
end

function var_0_0.willClose(arg_54_0)
	if arg_54_0.petCampaign.superFloor and arg_54_0.floorType and arg_54_0.petCampaign.openSuper then
		local var_54_0 = {
			floor = arg_54_0.petCampaign.superFloor,
			state = arg_54_0.floorType
		}

		arg_54_0.petCampaign:saveSuperFloor(var_54_0)
	end

	if arg_54_0.playDeadHandle then
		var_0_8.unscheduleGlobal(arg_54_0.playDeadHandle)
	end
end

function var_0_0.didClose(arg_55_0)
	var_0_0.super.didClose(arg_55_0, params)

	if xyd.WindowManager.get():getWindow("pet_sweeping") then
		xyd.WindowManager.get():closeWindow("pet_sweeping")
	end
end

function var_0_0.update_(arg_56_0, arg_56_1)
	if arg_56_0.delayIndex and next(arg_56_0.delayIndex) then
		coroutine.resume(arg_56_0.co)
	end
end

function var_0_0.playFunctionGuide(arg_57_0)
	local var_57_0 = -100
	local var_57_1 = 0
	local var_57_2 = 40
	local var_57_3 = 0
	local var_57_4 = xyd.tables.translation:translation("FUNCTION_OPEN_TIP_SKY")
	local var_57_5

	if arg_57_0.floorCells[100] then
		var_57_5 = arg_57_0.floorCells[100]:getChildByName("container"):getChildByName("super_btn")
	else
		return
	end

	local function var_57_6(arg_58_0, arg_58_1, arg_58_2, arg_58_3, arg_58_4)
		if var_57_5 then
			local var_58_0 = var_57_5:getPositionX()
			local var_58_1 = var_57_5:getPositionY() + 60
			local var_58_2 = display.newNode()

			var_58_2:setPosition(var_58_0, var_58_1)

			local var_58_3 = import("app.windows.GuideHand").new()

			var_58_2:addChild(var_58_3)
			var_58_3:setPosition(0, 0)

			local var_58_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/function/function_open.csb")

			var_58_2:addChild(var_58_4)
			var_58_4:setPosition(arg_58_0, arg_58_1)
			var_58_4:getChildByName("tip_container"):getChildByName("text_open"):setString(arg_58_3)

			local var_58_5 = var_58_4:getChildByName("tip_container"):getChildByName("tip_arrow")

			if arg_58_2 ~= 0 then
				local var_58_6 = cc.p(var_58_5:getPosition())

				var_58_5:setPosition(cc.p(var_58_6.x + arg_58_2, var_58_6.y))
			end

			if arg_58_4 ~= 0 then
				var_58_5:setSkewY(arg_58_4)
			end

			if arg_57_0.GuideHands == nil then
				arg_57_0:addChild(var_58_2)

				arg_57_0.GuideHands = var_58_2
			else
				arg_57_0.GuideHands = var_58_2
			end
		end
	end

	;(function(arg_59_0, arg_59_1, arg_59_2, arg_59_3, arg_59_4)
		if var_57_5 and var_57_5:isVisible() and not arg_57_0.hasClickSuper then
			var_57_6(arg_59_0, arg_59_1, arg_59_2, arg_59_3, arg_59_4)

			return true
		end
	end)(var_57_0, var_57_1, var_57_3, var_57_4, var_57_2)
end

return var_0_0
