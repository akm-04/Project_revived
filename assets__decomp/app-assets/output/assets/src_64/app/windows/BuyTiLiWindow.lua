local var_0_0 = class("BuyTiLiWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.item
local var_0_3 = require("framework.scheduler")
local var_0_4 = import("app.common.ui.SpineEffect")
local var_0_5 = 120

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.listInfo = {}
	arg_1_0.callback = arg_1_2.callback

	if arg_1_2.buytype then
		arg_1_0.buytype = arg_1_2.buytype
	end

	arg_1_0.buyTimes = arg_1_0.selfPlayer.buySkillTimes
	arg_1_0.buyCost = xyd.tables.refreshCost:buySkillCost(arg_1_0.buyTimes + 1)
	arg_1_0.handler = {}
	arg_1_0.buyEnergyTimes = arg_1_0.selfPlayer.buyEnergyTimes
	arg_1_0.buyEnergyCost = xyd.tables.refreshCost:buyEnergyCost(arg_1_0.buyEnergyTimes + 1)
	arg_1_0.maxBuyTimes = xyd.tables.vip:numEnergy(arg_1_0.selfPlayer.vip)

	if arg_1_0.selfPlayer.privilegeLeftCardDay > 0 then
		local var_1_0 = xyd.tables.monthlyPrivilege:numEnergy(1)

		arg_1_0.maxBuyTimes = arg_1_0.maxBuyTimes + var_1_0
	end

	arg_1_0.text = string.format(var_0_1:translation("BUY_TILI_TIP_TEXTS"), arg_1_0.buyEnergyCost, var_0_5, arg_1_0.buyEnergyTimes)

	if arg_1_0.buytype == 1 then
		local var_1_1 = arg_1_0.selfPlayer.buySkillTimes
		local var_1_2 = xyd.tables.refreshCost:buySkillCost(var_1_1 + 1)

		arg_1_0.skillPoints = arg_1_0.selfPlayer:getSkillPoint()

		if arg_1_0.skillPoints < 0 then
			arg_1_0.skillPoints = 0
		end

		arg_1_0.text = string.format(var_0_1:translation("BUY_SKILL_POINTS_TIP1"), var_1_2, arg_1_0.skillPoints, var_1_1)
	elseif arg_1_0.buytype == 2 then
		local var_1_3 = arg_1_0.selfPlayer.buySkillTimes
		local var_1_4 = xyd.tables.refreshCost:buySkillCost(var_1_3 + 1)

		arg_1_0.text = string.format(var_0_1:translation("SKILL_POINT_BUY"), var_1_4, var_1_3)
	end

	if arg_1_0.buyEnergyTimes == arg_1_0.maxBuyTimes then
		xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH):setSceneCondition(37)
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addBlockLayer()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:playGuide()
end

function var_0_0.didClose(arg_4_0, arg_4_1)
	var_0_0.super:didClose(arg_4_1)

	if arg_4_0.handler then
		if arg_4_0.handler[1] then
			var_0_3.unscheduleGlobal(arg_4_0.handler[1])
		end

		if arg_4_0.handler[2] then
			var_0_3.unscheduleGlobal(arg_4_0.handler[2])
		end
	end
end

function var_0_0.playGuide(arg_5_0)
	local var_5_0 = xyd.StoryData.get():getGuideID()

	if #arg_5_0.list.items_ > 0 and var_5_0 == xyd.GuideStoryType.GUIDE_SKILL_END then
		local var_5_1 = arg_5_0.list.items_[1]
		local var_5_2 = {
			600,
			300
		}
		local var_5_3 = var_5_1:getPositionX() + var_5_1:getContentSize().width / 2
		local var_5_4 = var_5_1:getPositionY() + var_5_1:getContentSize().height / 2

		xyd.WindowManager.get():closeWindow("guide")
		xyd.WindowManager.get():openWindow("guide")

		local var_5_5 = xyd.WindowManager.get():getWindow("guide")
		local var_5_6 = var_5_5:convertToNodeSpace(var_5_1:getParent():convertToWorldSpace(cc.p(var_5_3, var_5_4)))

		var_5_5:addNode()
		var_5_5:setStencil(100, 50, var_5_6.x, var_5_6.y, 2, {
			right = true,
			position = var_5_2
		})
	end
end

function var_0_0.layout(arg_6_0)
	if arg_6_0.buytype == 1 then
		arg_6_0:nodeByName("text_buy"):setString(var_0_1:translation("CHECK_PRIVILEGE"))
	end

	if arg_6_0.buytype then
		arg_6_0:nodeByName("text_tips"):setString(var_0_1:translation("BUY_SKILL_POINTS_TIP2"))
		arg_6_0:nodeByName("text_title"):setString(var_0_1:translation("BUY_SKILL_POINT_TEXT"))
	else
		arg_6_0:nodeByName("text_tips"):setString(var_0_1:translation("BUY_TILI_TEXT1"))
		arg_6_0:nodeByName("text_title"):setString(var_0_1:translation("BUY_TILI_TEXT"))
	end

	if arg_6_0.buytype == 1 or arg_6_0.buytype == 2 then
		arg_6_0:nodeByName("text_tips1"):setPositionY(165)
	end

	local var_6_0 = xyd.split(arg_6_0.text, ":")

	for iter_6_0 = 1, 6 do
		arg_6_0:nodeByName("text_tips" .. iter_6_0):setString(var_6_0[iter_6_0] or "")
	end

	local var_6_1 = arg_6_0:nodeByName("list")
	local var_6_2 = var_6_1:getContentSize()

	arg_6_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_6_2.width, var_6_2.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(var_6_1):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	arg_6_0.list:setDelegate(handler(arg_6_0, arg_6_0.delegate))
	arg_6_0:updateListInfo()
	arg_6_0.list:reload()
	arg_6_0:nodeByName("btn_cancel"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.began then
			arg_7_0:setScale(0.9)
		elseif arg_7_1 == ccui.TouchEventType.moved then
			arg_7_0:setScale(1)
		elseif arg_7_1 == ccui.TouchEventType.ended then
			arg_7_0:setScale(1)
			xyd.WindowManager.get():closeWindow(arg_6_0)
		end
	end)
	arg_6_0:nodeByName("btn_buy"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			arg_8_0:setScale(0.9)
		elseif arg_8_1 == ccui.TouchEventType.moved then
			arg_8_0:setScale(1)
		elseif arg_8_1 == ccui.TouchEventType.ended then
			arg_8_0:setScale(1)
			arg_6_0.callback()
		end
	end)
end

function var_0_0.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.scrollViewMoved_ = false
		arg_9_0.prevX_ = arg_9_1.x
		arg_9_0.prevY_ = arg_9_1.y
	elseif arg_9_1.name == "moved" then
		local var_9_0 = 5

		if var_9_0 <= math.abs(arg_9_1.y - arg_9_0.prevY_) or var_9_0 <= math.abs(arg_9_1.x - arg_9_0.prevX_) then
			arg_9_0.scrollViewMoved_ = true

			if arg_9_0.handler[1] ~= nil then
				var_0_3.unscheduleGlobal(arg_9_0.handler[1])
			end

			if arg_9_0.handler[2] ~= nil then
				var_0_3.unscheduleGlobal(arg_9_0.handler[2])
			end
		end
	end
end

function var_0_0.updateListInfo(arg_10_0)
	arg_10_0.listInfo = {}

	local var_10_0 = arg_10_0.selfPlayer:getBackpack():getItems()

	if arg_10_0.buytype then
		for iter_10_0, iter_10_1 in pairs(var_10_0) do
			if xyd.tables.item:subType(iter_10_1.itemID) == xyd.ConsumeItemType.SKILL_POINT then
				table.insert(arg_10_0.listInfo, iter_10_1.itemID)
			end
		end
	else
		for iter_10_2, iter_10_3 in pairs(var_10_0) do
			if xyd.tables.item:subType(iter_10_3.itemID) == xyd.ConsumeItemType.ENERGY_ITEM then
				table.insert(arg_10_0.listInfo, iter_10_3.itemID)
			end
		end
	end
end

function var_0_0.delegate(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	if cc.ui.UIListView.COUNT_TAG == arg_11_2 then
		return #arg_11_0.listInfo
	elseif cc.ui.UIListView.CELL_TAG == arg_11_2 then
		local var_11_0 = arg_11_0.list:dequeueItem()

		if not var_11_0 then
			var_11_0 = arg_11_0.list:newItem()
		else
			var_11_0:removeAllChildren(true)
		end

		local var_11_1 = 160
		local var_11_2 = 144

		var_11_0:setItemSize(var_11_1, var_11_2)

		local var_11_3 = display.newNode()

		var_11_3:setContentSize(var_11_1, 144)
		arg_11_0:initCell(var_11_3, arg_11_3)
		var_11_0:addContent(var_11_3)

		return var_11_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_11_2 then
		-- block empty
	end
end

function var_0_0.initCell(arg_12_0, arg_12_1, arg_12_2)
	if arg_12_2 > #arg_12_0.listInfo then
		return
	end

	local var_12_0 = display.newNode()

	var_12_0:setContentSize(108, 108)
	var_12_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_12_0:setPosition(80, 89)
	var_12_0:addTo(arg_12_1)

	local var_12_1 = arg_12_0.listInfo[arg_12_2]

	xyd.setItemBorder(var_12_0, var_12_1)

	local var_12_2 = {
		size = 24,
		color = cc.c3b(17, 17, 17)
	}
	local var_12_3 = xyd.AssetLoader:get():loadLabel(var_12_2)

	var_12_3:setString("x" .. arg_12_0.selfPlayer:getBackpack():getItemNumByID(var_12_1))
	var_12_3:setAnchorPoint(cc.p(0, 0))
	var_12_3:setPosition(57, 0)
	var_12_3:addTo(arg_12_1)

	local var_12_4 = "skeletons/ui_effect/common_effect_exp_click/common_effect_exp_click"
	local var_12_5 = var_12_4 .. ".json"
	local var_12_6 = var_12_4 .. ".atlas"
	local var_12_7 = var_0_4.new(var_12_5, var_12_6, 1)

	var_12_7:setAnchorPoint(cc.p(0.5, 0.5))
	var_12_7:setScale(0.85)
	var_12_7:setPosition(81, 89)
	arg_12_1:addChild(var_12_7)
	var_12_0:setTouchEnabled(true)
	var_12_0:setTouchSwallowEnabled(false)

	local var_12_8 = false
	local var_12_9 = xyd.tables.misc.energyMaxLimit

	local function var_12_10(arg_13_0, arg_13_1, arg_13_2)
		if arg_12_0.selfPlayer.energy >= var_12_9 and not arg_12_0.buytype then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("TILI_LIMIT_INFO")
			})

			if arg_12_0.handler[1] ~= nil then
				var_0_3.unscheduleGlobal(arg_12_0.handler[1])
			end

			if arg_12_0.handler[2] ~= nil then
				var_0_3.unscheduleGlobal(arg_12_0.handler[2])
			end

			return
		end

		local var_13_0 = {
			item_id = arg_13_0,
			item_num = arg_13_1
		}

		if arg_12_0.buytype then
			arg_12_0.selfPlayer:useSkillPointItem(var_13_0, function(arg_14_0)
				if arg_14_0 == xyd.error.OK then
					if arg_13_2 then
						arg_13_2()
					else
						var_12_3:setString("x" .. arg_12_0.selfPlayer:getBackpack():getItemNumByID(arg_13_0))
					end
				end
			end)
		else
			arg_12_0.selfPlayer:useEnergyItem(var_13_0, function(arg_15_0)
				if arg_15_0 == xyd.error.OK then
					if arg_13_2 then
						arg_13_2()
					else
						var_12_3:setString("x" .. arg_12_0.selfPlayer:getBackpack():getItemNumByID(arg_13_0))
					end
				end
			end)
		end
	end

	local var_12_11 = 0
	local var_12_12 = arg_12_0.selfPlayer.energy
	local var_12_13 = false
	local var_12_14 = var_12_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
		if arg_16_0.name == "began" then
			arg_12_0.prevTiLiX_ = arg_16_0.x
			arg_12_0.prevTiLiY_ = arg_16_0.y
			var_12_13 = false

			local var_16_0 = 0

			if arg_12_0.handler[1] ~= nil then
				var_0_3.unscheduleGlobal(arg_12_0.handler[1])
			end

			if arg_12_0.handler[2] ~= nil then
				var_0_3.unscheduleGlobal(arg_12_0.handler[2])
			end

			local function var_16_1()
				var_16_0 = var_16_0 + 0.03

				if arg_12_0.selfPlayer:getBackpack():getItemNumByID(var_12_1) - var_12_11 > 0 and var_12_12 <= var_12_9 then
					var_12_11 = var_12_11 + 1

					var_12_7:play(nil, false)

					var_12_12 = var_12_12 + var_0_2:energy(var_12_1)

					var_12_3:setString("x" .. arg_12_0.selfPlayer:getBackpack():getItemNumByID(var_12_1) - var_12_11)
				else
					var_0_3.unscheduleGlobal(arg_12_0.handler[2])
					var_12_10(var_12_1, var_12_11, function()
						var_12_11 = 0
						var_12_12 = arg_12_0.selfPlayer.energy

						arg_12_0:updateListInfo()
						arg_12_0.list:refreshList(0)
					end)
				end
			end

			local function var_16_2()
				var_16_0 = var_16_0 + 0.1

				if var_16_0 > 0.5 and var_16_0 <= 4 then
					var_12_8 = true

					if arg_12_0.selfPlayer:getBackpack():getItemNumByID(var_12_1) - var_12_11 > 0 and var_12_12 <= var_12_9 then
						var_12_11 = var_12_11 + 1

						var_12_7:play(nil, false)

						var_12_12 = var_12_12 + var_0_2:energy(var_12_1)

						var_12_3:setString("x" .. arg_12_0.selfPlayer:getBackpack():getItemNumByID(var_12_1) - var_12_11)
					else
						var_0_3.unscheduleGlobal(arg_12_0.handler[1])
						var_12_10(var_12_1, var_12_11, function()
							var_12_11 = 0
							var_12_12 = arg_12_0.selfPlayer.energy

							arg_12_0:updateListInfo()
							arg_12_0.list:refreshList(0)
						end)
						arg_12_0:updateListInfo()
						arg_12_0.list:refreshList(0)
					end
				elseif var_16_0 > 4 then
					arg_12_0.handler[2] = var_0_3.scheduleGlobal(var_16_1, 0.03)

					var_0_3.unscheduleGlobal(arg_12_0.handler[1])
				else
					var_12_8 = false
				end
			end

			var_12_8 = false
			arg_12_0.handler[1] = var_0_3.scheduleGlobal(var_16_2, 0.1)

			return true
		elseif arg_16_0.name == "moved" then
			local var_16_3 = 5

			if var_16_3 <= math.abs(arg_16_0.y - arg_12_0.prevTiLiY_) or var_16_3 <= math.abs(arg_16_0.x - arg_12_0.prevTiLiX_) then
				var_12_13 = true

				if arg_12_0.handler[1] ~= nil then
					var_0_3.unscheduleGlobal(arg_12_0.handler[1])
				end

				if arg_12_0.handler[2] ~= nil then
					var_0_3.unscheduleGlobal(arg_12_0.handler[2])
				end

				if var_12_11 > 0 then
					var_12_10(var_12_1, var_12_11, function()
						var_12_11 = 0
						var_12_12 = arg_12_0.selfPlayer.energy

						arg_12_0:updateListInfo()
						arg_12_0.list:refreshList(0)
					end)

					var_12_11 = 0
					var_12_12 = arg_12_0.selfPlayer.energy
				end
			end
		elseif arg_16_0.name == "ended" then
			if arg_12_0.handler[1] ~= nil then
				var_0_3.unscheduleGlobal(arg_12_0.handler[1])
			end

			if arg_12_0.handler[2] ~= nil then
				var_0_3.unscheduleGlobal(arg_12_0.handler[2])
			end

			if var_12_8 == false then
				if not var_12_13 then
					if arg_12_0.selfPlayer:getBackpack():getItemNumByID(var_12_1) - var_12_11 > 0 then
						var_12_7:play(nil, false)
						var_12_10(var_12_1, 1, function()
							var_12_11 = 0
							var_12_12 = arg_12_0.selfPlayer.energy

							arg_12_0:updateListInfo()
							arg_12_0.list:refreshList(0)
						end)
					else
						arg_12_0:updateListInfo()
						arg_12_0.list:refreshList(0)
					end
				end
			else
				var_12_10(var_12_1, var_12_11, function()
					var_12_11 = 0
					var_12_12 = arg_12_0.selfPlayer.energy

					arg_12_0:updateListInfo()
					arg_12_0.list:refreshList(0)
				end)
			end
		end
	end)
end

return var_0_0
