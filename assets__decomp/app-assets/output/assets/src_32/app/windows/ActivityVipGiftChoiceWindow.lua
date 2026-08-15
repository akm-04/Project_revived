local var_0_0 = class("ActivityVipGiftChoiceWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.callback = arg_1_2.callback
	arg_1_0.count = arg_1_2.count
	arg_1_0.tableId = arg_1_2.table_id
	arg_1_0.heroItems = {}
	arg_1_0.choosenGift1 = nil
	arg_1_0.choosenGift2 = nil
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
	arg_4_0:nodeByName("desc_txt"):setString(var_0_1:translation("VIPGIFT_CHOICE_DESC"))

	local var_4_0 = xyd.tables.ActivityVipGift:giftChoice(arg_4_0.count)
	local var_4_1 = #var_4_0
	local var_4_2 = 2
	local var_4_3 = math.floor(var_4_1 / var_4_2)

	for iter_4_0 = 1, var_4_2 do
		for iter_4_1 = 1, var_4_3 do
			local var_4_4 = (iter_4_0 - 1) * var_4_3 + iter_4_1
			local var_4_5 = var_4_0[var_4_4]
			local var_4_6 = xyd.tables.gift:items(var_4_5)[1]
			local var_4_7 = xyd.tables.gift:itemNum(var_4_5)[1]
			local var_4_8 = arg_4_0:checkHeroChoosen(var_4_5)
			local var_4_9 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1040/avatar_item.csb")
			local var_4_10 = var_4_9:getChildByName("container")
			local var_4_11 = display.newNode()

			var_4_11:setContentSize(113, 113)
			var_4_11:addTo(var_4_10)
			var_4_11:setLocalZOrder(-1)

			local var_4_12 = var_4_10:getChildByName("zhezhao")
			local var_4_13 = var_4_10:getChildByName("gou")

			var_4_12:setVisible(false)
			var_4_13:setVisible(false)
			table.insert(arg_4_0.heroItems, var_4_10)

			if var_4_8 then
				var_4_10:setTouchEnabled(false)
				xyd.setItemBorder(var_4_11, var_4_6, nil, nil, var_4_7)
			else
				xyd.setItemBorder(var_4_11, var_4_6, nil, nil, var_4_7)
				var_4_11:setTouchEnabled(true)

				local var_4_14 = {
					id = var_4_6
				}
				local var_4_15

				var_4_11:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
					if arg_5_0.name == "began" then
						var_4_15 = arg_5_0.y

						if not xyd.WindowManager.get():getWindow("new_item_tips") and not xyd.WindowManager.get():getWindow("new_item_tips") then
							local var_5_0 = xyd.WindowManager.get():openWindow("new_item_tips", var_4_14)

							xyd.adaptToWorldPosition(var_4_11, var_5_0)
						end

						return true
					elseif arg_5_0.name == "moved" then
						local var_5_1 = arg_5_0.y

						if math.abs(var_5_1 - var_4_15) > 30 then
							xyd.WindowManager.get():closeWindow("new_item_tips")
						end
					elseif arg_5_0.name == "ended" then
						wnd = xyd.WindowManager.get():closeWindow("new_item_tips")

						local var_5_2 = var_4_11:convertToWorldSpace(cc.p(0, 0))

						if arg_5_0.y - var_5_2.y < 0 or arg_5_0.y - var_5_2.y > 113 or arg_5_0.x - var_5_2.x < 0 or arg_5_0.x - var_5_2.x > 113 then
							return
						end

						var_4_12:setVisible(true)
						var_4_13:setVisible(true)

						if var_4_4 == arg_4_0.choosenGift2 then
							arg_4_0.choosenGift2 = nil
						elseif var_4_4 == arg_4_0.choosenGift1 then
							arg_4_0.choosenGift1 = nil
						elseif arg_4_0.choosenGift2 == nil and arg_4_0.choosenGift1 ~= nil then
							arg_4_0.choosenGift2 = var_4_4
						else
							arg_4_0.choosenGift1 = arg_4_0.choosenGift2
							arg_4_0.choosenGift2 = var_4_4
						end

						for iter_5_0 = 1, var_4_1 do
							if iter_5_0 ~= arg_4_0.choosenGift1 and iter_5_0 ~= arg_4_0.choosenGift2 then
								arg_4_0.heroItems[iter_5_0]:getChildByName("zhezhao"):setVisible(false)
								arg_4_0.heroItems[iter_5_0]:getChildByName("gou"):setVisible(false)
							end
						end
					end

					return true
				end)
			end

			var_4_9:addTo(arg_4_0:nodeByName("container"))
			var_4_9:setPosition((iter_4_1 - 1) * 160, (2 - iter_4_0) * 115)
		end
	end

	arg_4_0:nodeByName("ok_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if not arg_4_0.choosenGift1 or not arg_4_0.choosenGift2 or arg_4_0.choosenGift1 == arg_4_0.choosenGift2 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("PLEASE_CHOOSE_ITEMS")
				})

				return
			end

			local var_6_0 = {
				activity_id = arg_4_0.tableId,
				award_id = arg_4_0.count,
				choice_ids = {}
			}

			table.insert(var_6_0.choice_ids, arg_4_0.choosenGift1)
			table.insert(var_6_0.choice_ids, arg_4_0.choosenGift2)
			xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_REWARD, var_6_0, function(arg_7_0, arg_7_1)
				if arg_7_0 == xyd.error.OK then
					arg_4_0.selfPlayer:handleRewards(arg_7_1.awards)

					if arg_4_0.callback then
						arg_4_0.callback()
					end

					xyd.WindowManager.get():closeWindow(arg_4_0.name)
				end
			end)
		end
	end)
end

function var_0_0.checkHeroChoosen(arg_8_0, arg_8_1)
	if not arg_8_0.choosenHeros or not next(arg_8_0.choosenHeros) then
		return false
	end

	for iter_8_0, iter_8_1 in pairs(arg_8_0.choosenHeros) do
		if arg_8_1 == iter_8_1 then
			return true
		end
	end

	return false
end

function var_0_0.getHeros(arg_9_0, arg_9_1)
	local var_9_0 = {}

	for iter_9_0, iter_9_1 in pairs(arg_9_1) do
		local var_9_1 = xyd.tables.gift:items(iter_9_1)

		table.insert(var_9_0, var_9_1[1])
	end

	return var_9_0
end

function var_0_0.setItemAndAddTips(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local var_10_0 = arg_10_1:getContentSize().height
	local var_10_1 = display.newNode()

	var_10_1:setContentSize(var_10_0, var_10_0)

	local var_10_2 = xyd.tables.item:type(arg_10_2)

	xyd.setItemBorder(var_10_1, arg_10_2, nil, nil, arg_10_3)
	var_10_1:addTo(arg_10_1)
	var_10_1:setAnchorPoint(cc.p(0, 0))

	local var_10_3 = {
		id = arg_10_2,
		hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(arg_10_2)
	}

	arg_10_0:addTips(var_10_1, var_10_3)
end

function var_0_0.willClose(arg_11_0, arg_11_1)
	var_0_0.super:willClose(arg_11_1)
end

return var_0_0
