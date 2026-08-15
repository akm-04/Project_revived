local var_0_0 = class("NewTermMakePresentWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.newTermMake
local var_0_4 = import("framework.scheduler")
local var_0_5 = 3
local var_0_6 = 60
local var_0_7 = xyd.tables.misc.newTermMaterials

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.newTermModel = xyd.ModelManager.get():loadModel(xyd.ModelType.NEW_TERMS)
	arg_1_0.materials = {
		0,
		0,
		0
	}
	arg_1_0.makeNum = 0
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("make_num"):setString(tostring(arg_4_0.makeNum))
	arg_4_0:nodeByName("rest_txt"):setString(var_0_2:translation("LIANYI_TEXT2"))
	arg_4_0:nodeByName("speaking_txt"):setString(var_0_2:translation("LIANYI_TEXT4"))
	arg_4_0:nodeByName("make_num_label"):setString(var_0_2:translation("LIANYI_TEXT3"))

	for iter_4_0 = 1, var_0_5 do
		local var_4_0 = var_0_7[iter_4_0]

		arg_4_0:nodeByName("rest_item_" .. iter_4_0):setAnchorPoint(0.5, 0.5)
		arg_4_0:nodeByName("rest_item_" .. iter_4_0):setContentSize(var_0_6, var_0_6)
		xyd.setItemBorder(arg_4_0:nodeByName("rest_item_" .. iter_4_0), var_4_0)

		local var_4_1 = arg_4_0.selfPlayer:getBackpack():getItemNumByID(var_4_0)

		arg_4_0:nodeByName("rest_num_" .. iter_4_0):setString("x" .. var_4_1)
	end

	arg_4_0:registerListeners()
end

function var_0_0.updateRightPanel(arg_5_0)
	for iter_5_0 = 1, var_0_5 do
		local var_5_0 = var_0_7[iter_5_0]
		local var_5_1 = arg_5_0.selfPlayer:getBackpack():getItemNumByID(var_5_0)

		arg_5_0:nodeByName("rest_num_" .. iter_5_0):setString("x" .. var_5_1)
	end
end

function var_0_0.registerListeners(arg_6_0)
	for iter_6_0 = 1, var_0_5 do
		arg_6_0:nodeByName("item_" .. iter_6_0):setTouchEnabled(true)
		arg_6_0:nodeByName("item_" .. iter_6_0):setTouchSwallowEnabled(false)
		arg_6_0:nodeByName("item_" .. iter_6_0):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
			if arg_7_0.name == "ended" then
				local var_7_0 = {
					index = iter_6_0
				}

				xyd.WindowManager.get():openWindow("new_term_make_choose_alert", var_7_0)
			end

			return true
		end)
	end

	arg_6_0:nodeByName("make_records_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_6_0:nodeByName("make_records_btn"), arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			arg_6_0.newTermModel:getMakeLogs({}, function(arg_9_0, arg_9_1)
				xyd.WindowManager.get():openWindow("new_term_make_alert", arg_9_1)
			end)
		end
	end)
	arg_6_0:nodeByName("random_material_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_6_0:nodeByName("random_material_btn"), arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			arg_6_0:updateRandomMaterials()
		end
	end)
	arg_6_0:nodeByName("make_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(arg_6_0:nodeByName("make_btn"), arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			local var_11_0 = var_0_3:getIDByItems(arg_6_0.materials)
			local var_11_1 = arg_6_0.makeNum
			local var_11_2 = {
				id = var_11_0,
				num = var_11_1
			}

			if var_11_1 <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("LIANYI_TEXT22")
				})
			elseif var_11_1 > arg_6_0:maxNum() then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("LIANYI_TEXT25")
				})
			else
				arg_6_0.newTermModel:makePresent(var_11_2, function(arg_12_0, arg_12_1)
					dump(arg_12_1)

					arg_6_0.awards = arg_12_1.awards

					arg_6_0:createMakeAnimation(var_11_0)
				end)
			end
		end
	end)
	arg_6_0:nodeByName("plus_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		xyd.buttonScaleAnim(arg_6_0:nodeByName("plus_btn"), arg_13_1)

		if arg_13_1 == ccui.TouchEventType.ended then
			arg_6_0.makeNum = arg_6_0.makeNum + 1

			local var_13_0 = arg_6_0:maxNum()

			if var_13_0 < arg_6_0.makeNum then
				arg_6_0.makeNum = var_13_0
			end

			arg_6_0:nodeByName("make_num"):setString(tostring(arg_6_0.makeNum))
		end
	end)
	arg_6_0:nodeByName("max_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
		xyd.buttonScaleAnim(arg_6_0:nodeByName("max_btn"), arg_14_1)

		if arg_14_1 == ccui.TouchEventType.ended then
			arg_6_0.makeNum = arg_6_0:maxNum()

			arg_6_0:nodeByName("make_num"):setString(tostring(arg_6_0.makeNum))
		end
	end)
	arg_6_0:nodeByName("minus_btn"):addTouchEventListener(function(arg_15_0, arg_15_1)
		xyd.buttonScaleAnim(arg_6_0:nodeByName("minus_btn"), arg_15_1)

		if arg_15_1 == ccui.TouchEventType.ended then
			arg_6_0.makeNum = arg_6_0.makeNum - 1

			if arg_6_0.makeNum < 0 then
				arg_6_0.makeNum = 0
			end

			arg_6_0:nodeByName("make_num"):setString(tostring(arg_6_0.makeNum))
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_6_0):addEventListener(xyd.event.NEW_TERM_CHOOSE_MATERIALS, function(arg_16_0)
		if arg_6_0 and not tolua.isnull(arg_6_0) then
			local var_16_0 = arg_16_0.params.index
			local var_16_1 = arg_16_0.params.itemID

			arg_6_0:updateItemByIndexAndID(var_16_0, var_16_1)
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_6_0):addEventListener(xyd.event.NEW_TERM_USE_MATERIAL_RATIO, function(arg_17_0)
		if arg_6_0 and not tolua.isnull(arg_6_0) then
			local var_17_0 = arg_17_0.params.id
			local var_17_1 = var_0_3:combination(var_17_0)

			for iter_17_0, iter_17_1 in pairs(var_17_1) do
				arg_6_0:updateItemByIndexAndID(iter_17_0, iter_17_1)
			end
		end
	end)
end

function var_0_0.updateRandomMaterials(arg_18_0)
	for iter_18_0 = 1, var_0_5 do
		local var_18_0 = math.random(1, var_0_5)

		arg_18_0:updateItemByIndexAndID(iter_18_0, var_0_7[var_18_0])
	end
end

function var_0_0.updateItemByIndexAndID(arg_19_0, arg_19_1, arg_19_2)
	arg_19_0:nodeByName("item_" .. arg_19_1):removeAllChildren()

	local var_19_0 = display.newNode()

	var_19_0:addTo(arg_19_0:nodeByName("item_" .. arg_19_1))
	var_19_0:setName("node" .. arg_19_1)
	var_19_0:setContentSize(arg_19_0:nodeByName("item_" .. arg_19_1):getContentSize())
	xyd.setItemBorder(var_19_0, arg_19_2)

	arg_19_0.materials[arg_19_1] = arg_19_2

	arg_19_0:clearAndUpdateMakeNum()
end

function var_0_0.clearAndUpdateMakeNum(arg_20_0)
	arg_20_0.makeNum = 1

	if arg_20_0.makeNum > arg_20_0:maxNum() then
		arg_20_0.makeNum = 0
	end

	arg_20_0:nodeByName("make_num"):setString(tostring(arg_20_0.makeNum))
end

function var_0_0.maxNum(arg_21_0)
	local var_21_0 = 999
	local var_21_1 = {}

	for iter_21_0, iter_21_1 in pairs(arg_21_0.materials) do
		if iter_21_1 == 0 then
			return 0
		end

		if #var_21_1 == 0 then
			local var_21_2 = {
				id = iter_21_1
			}

			var_21_2.num = 1

			table.insert(var_21_1, var_21_2)
		else
			for iter_21_2, iter_21_3 in pairs(var_21_1) do
				if iter_21_3 and iter_21_3.id == iter_21_1 then
					iter_21_3.num = iter_21_3.num + 1
				else
					local var_21_3 = {
						id = iter_21_1
					}

					var_21_3.num = 1

					table.insert(var_21_1, var_21_3)

					break
				end
			end
		end
	end

	for iter_21_4, iter_21_5 in pairs(var_21_1) do
		local var_21_4 = math.floor(arg_21_0.selfPlayer:getBackpack():getItemNumByID(iter_21_5.id) / iter_21_5.num)

		if var_21_4 < var_21_0 then
			var_21_0 = var_21_4
		end
	end

	return var_21_0
end

function var_0_0.handleRewards(arg_22_0, arg_22_1, arg_22_2)
	local var_22_0 = {}

	for iter_22_0, iter_22_1 in pairs(arg_22_1) do
		local var_22_1 = false

		for iter_22_2, iter_22_3 in pairs(var_22_0) do
			if iter_22_3.table_id == iter_22_1.table_id then
				var_22_1 = iter_22_3

				break
			end
		end

		if var_22_1 then
			var_22_1.item_num = var_22_1.item_num + iter_22_1.item_num
		else
			table.insert(var_22_0, iter_22_1)
		end
	end

	arg_22_0.selfPlayer:handleRewards(var_22_0)
end

function var_0_0.updateActivityDetails(arg_23_0, arg_23_1)
	for iter_23_0, iter_23_1 in pairs(arg_23_1) do
		if not xyd.isInTable(arg_23_0.newTermModel.collectionItems, tostring(iter_23_1.table_id)) then
			table.insert(arg_23_0.newTermModel.collectionItems, tostring(iter_23_1.table_id))
		end

		local var_23_0 = xyd.tables.newTermGift:connection(iter_23_1.table_id) * tonumber(iter_23_1.item_num)

		arg_23_0.newTermModel.connection = arg_23_0.newTermModel.connection + var_23_0
	end
end

function var_0_0.createMakeAnimation(arg_24_0, arg_24_1)
	for iter_24_0 = 1, var_0_5 do
		local var_24_0 = arg_24_0:nodeByName("animation_end_node")
		local var_24_1 = arg_24_0:nodeByName("item_" .. iter_24_0):getChildByName("node" .. iter_24_0)

		if var_24_1 and not tolua.isnull(var_24_1) then
			local var_24_2 = cc.MoveTo:create(0.5, var_24_1:convertToNodeSpace(cc.p(var_24_0:getPosition())))
			local var_24_3 = cc.FadeOut:create(0.5)
			local var_24_4 = cc.Spawn:create(var_24_2, var_24_3)

			if var_24_1 and not tolua.isnull(var_24_1) then
				var_24_1:runActionOnce(var_24_4, false, function()
					var_24_1:removeFromParent()

					if arg_24_0.awards then
						arg_24_0:handleRewards(arg_24_0.awards)

						arg_24_0.awards = nil

						arg_24_0:updateRightPanel()

						if arg_24_1 then
							local var_25_0 = var_0_3:combination(arg_24_1)

							for iter_25_0 = 1, #var_25_0 do
								arg_24_0:updateItemByIndexAndID(iter_25_0, var_25_0[iter_25_0])
							end
						end

						arg_24_0:clearAndUpdateMakeNum()
					end
				end)
			end
		end
	end
end

function var_0_0.willClose(arg_26_0)
	if arg_26_0.handle then
		var_0_4.unscheduleGlobal(arg_26_0.handle)

		arg_26_0.handle = nil
	end
end

return var_0_0
