local var_0_0 = class("PetCampaignAwardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.petCampaign
local var_0_3 = 6

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.petCampaign = xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN)
	arg_1_0.currentLayer = arg_1_2.currentLayer
	arg_1_0.floorType = arg_1_2.floorType or arg_1_0.petCampaign.state
	arg_1_0.isFinishAward = arg_1_2.isFinishAward
	arg_1_0.awards = arg_1_2.awards
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	if arg_3_0.isFinishAward then
		arg_3_0:nodeByName("ok_btn"):setPosition(arg_3_0:nodeByName("ok_btn"):getX() - 100, arg_3_0:nodeByName("ok_btn"):getY())
		arg_3_0:nodeByName("txt_sure"):setPosition(arg_3_0:nodeByName("txt_sure"):getX() - 100, arg_3_0:nodeByName("txt_sure"):getY())
		arg_3_0:nodeByName("txt_cancel"):setVisible(false)
		arg_3_0:nodeByName("cancel_btn"):setVisible(false)

		for iter_3_0, iter_3_1 in ipairs(arg_3_0.awards) do
			if iter_3_1.table_id ~= -1 then
				arg_3_0.selfPlayer:getBackpack():addItemsByID(tonumber(iter_3_1.table_id), tonumber(iter_3_1.item_num))
			end
		end
	end

	arg_3_0:nodeByName("cancel_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
	arg_3_0:nodeByName("ok_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_3_0.isFinishAward then
				xyd.WindowManager.get():closeWindow(arg_3_0)
			else
				arg_3_0.petCampaign:beginSweep(function(arg_6_0, arg_6_1)
					if arg_6_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("pet_sweeping", {
							currentLayer = arg_3_0.currentLayer
						})
						xyd.WindowManager.get():closeWindow(arg_3_0)
					end
				end)
			end
		end
	end)

	local var_3_0
	local var_3_1
	local var_3_2 = ""
	local var_3_3 = arg_3_0.floorType == xyd.PetCampaignFloorType.NORMAL and "normal" or "super"
	local var_3_4 = arg_3_0.petCampaign[var_3_3]

	if var_3_4.now_floor < var_0_2:getMaxLimitFloor(arg_3_0.floorType) then
		var_3_1 = var_3_4.now_floor + 1
	else
		var_3_1 = var_3_4.now_floor
	end

	local var_3_5 = var_3_4.max_floor + 1

	arg_3_0.floor_item = {}

	local var_3_6 = 0

	for iter_3_2 = var_3_1, var_3_5 - 1 do
		for iter_3_3, iter_3_4 in pairs(var_0_2.item_display_[arg_3_0.floorType][iter_3_2]) do
			local var_3_7 = true

			for iter_3_5, iter_3_6 in ipairs(arg_3_0.floor_item) do
				if iter_3_6.table_id == iter_3_4 then
					var_3_7 = false
					iter_3_6.item_num = iter_3_6.item_num + var_0_2:getItemNum(arg_3_0.floorType, iter_3_2, arg_3_0.selfPlayer.vip >= var_0_3)[iter_3_3]

					break
				end
			end

			if var_3_7 == true then
				local var_3_8 = {
					table_id = iter_3_4,
					item_num = var_0_2:getItemNum(arg_3_0.floorType, iter_3_2, arg_3_0.selfPlayer.vip >= var_0_3)[iter_3_3]
				}

				table.insert(arg_3_0.floor_item, var_3_8)
			end
		end

		var_3_6 = var_0_2:getManaGain(arg_3_0.floorType, iter_3_2) + var_3_6
	end

	local var_3_9 = {}

	var_3_9.table_id = -1
	var_3_9.item_num = var_3_6
	var_3_9.mana = var_3_6

	table.insert(arg_3_0.floor_item, var_3_9)
	table.sort(arg_3_0.floor_item, function(arg_7_0, arg_7_1)
		return arg_7_0.item_num > arg_7_1.item_num
	end)

	if arg_3_0.isFinishAward then
		arg_3_0:nodeByName("des_words"):setString(var_0_1:translation("GET_AWARD_IS"))
	else
		arg_3_0:nodeByName("des_words"):setString(string.format(var_0_1:translation("PET_SWEEP_AWARD"), var_3_5 - 1))
	end

	arg_3_0.listView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 10, arg_3_0:nodeByName("award_container"):getWidth(), arg_3_0:nodeByName("award_container"):getHeight() - 20),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("award_container"))

	arg_3_0.listView_:setBounceable(true)
	arg_3_0.listView_:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0.listView_:reload()
end

function var_0_0.delegate(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0 = arg_8_0.floor_item

	if arg_8_0.isFinishAward then
		var_8_0 = arg_8_0.awards
	end

	if cc.ui.UIListView.COUNT_TAG == arg_8_2 then
		return #var_8_0
	elseif cc.ui.UIListView.CELL_TAG == arg_8_2 then
		if arg_8_3 > #var_8_0 then
			return nil
		end

		local var_8_1 = arg_8_0.listView_:dequeueItem()

		if not var_8_1 then
			var_8_1 = arg_8_0.listView_:newItem()
		else
			var_8_1:removeAllChildren(true)
		end

		local var_8_2 = var_8_0[arg_8_3]
		local var_8_3 = display.newNode()

		arg_8_0:initCell(var_8_3, var_8_2, arg_8_3)

		local var_8_4 = display.newNode()

		var_8_4:addChild(var_8_3)
		var_8_3:setPosition(0, 0)
		var_8_4:setContentSize(340, 85)
		var_8_1:setItemSize(340, 85)
		var_8_1:addContent(var_8_4)

		return var_8_1
	end
end

function var_0_0.initCell(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petCampaign/longAwardItem.csb")
	local var_9_1 = var_9_0:getChildByName("container")
	local var_9_2 = var_9_1:getContentSize()
	local var_9_3 = cc.Node:create()
	local var_9_4 = ""

	var_9_3:setContentSize(70, 70)

	if arg_9_2.table_id == -1 or arg_9_2.table_id == -2 then
		if arg_9_2.mana then
			arg_9_2.table_id = -2
			var_9_4 = var_0_1:translation("COIN")
		end
	else
		var_9_4 = xyd.tables.item:name(arg_9_2.table_id)
	end

	xyd.setItemBorder(var_9_3, arg_9_2.table_id)
	var_9_1:getChildByName("icon"):addChild(var_9_3)
	var_9_1:getChildByName("num_text"):setString(arg_9_2.item_num)
	var_9_1:getChildByName("name_text"):setString(var_9_4)
	arg_9_1:addChild(var_9_0)

	local var_9_5 = {
		id = arg_9_2.table_id,
		hasNum = arg_9_0.selfPlayer:getBackpack():getItemNumByID(arg_9_2.table_id)
	}
	local var_9_6, var_9_7 = var_9_3:getPosition()

	var_9_3:setTouchEnabled(true)
	var_9_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
		if arg_10_0.name == "began" then
			local var_10_0 = xyd.WindowManager.get():getWindow("new_item_tips")
			local var_10_1 = arg_9_0:convertToWorldSpace(cc.p(0, 0))

			if not var_10_0 then
				local var_10_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_9_5)

				xyd.adaptToWorldPosition(var_9_3, var_10_2)
			end

			return true
		elseif arg_10_0.name == "ended" then
			wnd = xyd.WindowManager.get():closeWindow("new_item_tips")
		end
	end)
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	var_0_0.super.didOpen(arg_11_0, arg_11_1)
	arg_11_0:addBlockLayer()
end

function var_0_0.willClose(arg_12_0)
	arg_12_0.petCampaign.has_red = nil
end

function var_0_0.didClose(arg_13_0)
	return
end

return var_0_0
