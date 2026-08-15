local var_0_0 = class("GiftChooseWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.item
local var_0_3 = xyd.tables.gift
local var_0_4 = xyd.tables.hero

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.callback = arg_1_2.callback
	arg_1_0.count = arg_1_2.count
	arg_1_0.tableId = arg_1_2.table_id
	arg_1_0.heroItems = {}
	arg_1_0.choosenGift = nil
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 225), true)
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("desc_txt"):setString(var_0_1:translation("HERO_SELLING_DESC"))

	local var_4_0

	if arg_4_0.tableId == 1073 then
		var_4_0 = xyd.tables.activityNewCharge:gift(arg_4_0.count)
	elseif arg_4_0.tableId == 1072 then
		var_4_0 = xyd.tables.activityNewDayCharge:gift(arg_4_0.count)
	end

	local var_4_1 = #var_4_0
	local var_4_2 = 2
	local var_4_3 = math.floor(var_4_1 / var_4_2)

	for iter_4_0 = 1, var_4_2 do
		for iter_4_1 = 1, var_4_3 do
			local var_4_4 = (iter_4_0 - 1) * var_4_3 + iter_4_1
			local var_4_5 = var_4_0[var_4_4]
			local var_4_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1040/avatar_item.csb")
			local var_4_7 = var_4_6:getChildByName("container")
			local var_4_8 = display.newNode()

			var_4_8:setContentSize(113, 113)
			var_4_8:addTo(var_4_7)
			var_4_8:setLocalZOrder(-1)

			local var_4_9 = var_4_7:getChildByName("zhezhao")
			local var_4_10 = var_4_7:getChildByName("gou")

			var_4_9:setVisible(false)
			var_4_10:setVisible(false)
			table.insert(arg_4_0.heroItems, var_4_7)

			local var_4_11 = "new_item_tips"
			local var_4_12 = {}
			local var_4_13 = var_0_3:items(var_4_5)[1]

			var_4_12.id = var_4_13

			if var_0_2:type(var_4_13) == -1 then
				var_4_12.name = var_0_4:name(var_4_13)
				var_4_12.desc = var_0_4:getDes(var_4_13)

				xyd.setAvatarBorder(var_4_13, var_4_8, nil, 0)
			else
				var_4_11 = "new_item_tips"
				var_4_12.hasNum = var_0_3:itemNum(var_4_5)[1]

				xyd.setItemBorder(var_4_8, var_4_13, false, false, var_4_12.hasNum)
			end

			var_4_8:setTouchEnabled(true)

			local var_4_14, var_4_15 = var_4_8:getPosition()

			var_4_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
				if arg_5_0.name == "began" then
					local var_5_0 = xyd.WindowManager.get():getWindow(var_4_11)
					local var_5_1 = arg_4_0:convertToWorldSpace(cc.p(0, 0))

					if not var_5_0 then
						local var_5_2 = xyd.WindowManager.get():openWindow(var_4_11, var_4_12)
						local var_5_3 = var_4_8:getHeight()
						local var_5_4 = var_5_2:getTipHeight()
						local var_5_5 = var_4_8:getParent():convertToWorldSpace(cc.p(var_4_14 + 180, var_4_15 + var_5_4 / 2 + 160))

						var_5_2:setPosition(var_5_5.x - var_5_1.x, var_5_5.y - var_5_1.y)
					end

					return true
				elseif arg_5_0.name == "ended" then
					wnd = xyd.WindowManager.get():closeWindow(var_4_11)

					var_4_9:setVisible(true)
					var_4_10:setVisible(true)

					arg_4_0.choosenGift = var_4_4

					for iter_5_0 = 1, var_4_1 do
						if iter_5_0 ~= var_4_4 then
							arg_4_0.heroItems[iter_5_0]:getChildByName("zhezhao"):setVisible(false)
							arg_4_0.heroItems[iter_5_0]:getChildByName("gou"):setVisible(false)
						end
					end
				end

				return true
			end)
			var_4_6:addTo(arg_4_0:nodeByName("container"))
			var_4_6:setPosition((iter_4_1 - 1) * 115, (2 - iter_4_0) * 115)
		end
	end

	arg_4_0:nodeByName("ok_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if not arg_4_0.choosenGift then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("PLEASE_CHOOSE_HERO")
				})

				return
			end

			arg_4_0.activitiesModel:getActivityReward2(arg_4_0.tableId, arg_4_0.count, arg_4_0.choosenGift, function(arg_7_0, arg_7_1)
				if arg_7_0 == xyd.error.OK then
					arg_4_0.selfPlayer:handleRewards(arg_7_1.awards)
					arg_4_0.callback()
					xyd.WindowManager.get():closeWindow(arg_4_0.name)
				end
			end)
		end
	end)
end

function var_0_0.getHeros(arg_8_0, arg_8_1)
	local var_8_0 = {}

	for iter_8_0, iter_8_1 in pairs(arg_8_1) do
		local var_8_1 = var_0_3:items(iter_8_1)

		table.insert(var_8_0, var_8_1[1])
	end

	return var_8_0
end

function var_0_0.willClose(arg_9_0, arg_9_1)
	var_0_0.super:willClose(arg_9_1)
end

return var_0_0
