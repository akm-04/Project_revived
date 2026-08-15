local var_0_0 = class("OpenActItemWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.misc
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.activities

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.itemId = arg_1_2.itemId
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("label_title"):setString(var_0_2:translation("ACTIVITY_OPEN_SELECT"))
	arg_2_0:nodeByName("confirm"):addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			if not arg_2_0.choose then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("ACTIVITY_OPEN_CHOOSE")
				})

				return
			end

			xyd.AlertWindow.open(xyd.AlertType.YES_NO, {
				var_0_2:translation("ACTIVITY_OPEN_CONFIRM")
			}, function(arg_4_0)
				if arg_4_0 then
					arg_2_0.player:openActItem({
						item_id = arg_2_0.itemId,
						act_id = arg_2_0.choose
					}, function(arg_5_0)
						local var_5_0 = arg_5_0 == xyd.error.OK and "ACTIVITY_OPEN_SUCCESS" or "ACTIVITY_OPEN_FAIL"

						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_2:translation(var_5_0)
						})

						local var_5_1 = xyd.WindowManager.get():getWindow("backpack")

						if var_5_1 then
							var_5_1:updateItems()
						end
					end)
				end
			end)
		end
	end)
	arg_2_0:initList()
end

function var_0_0.initList(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_0:nodeByName("list_container")
	local var_6_1 = var_6_0:getContentSize()

	arg_6_0.width = var_6_1.width
	arg_6_0.List = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_6_1.width, var_6_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(var_6_0)

	local var_6_2 = var_0_1.activity_open_id
	local var_6_3 = math.ceil(#var_6_2 / 2)

	for iter_6_0 = 2, 2 * var_6_3, 2 do
		arg_6_0:createItem(var_6_2[iter_6_0 - 1], var_6_2[iter_6_0])
	end

	arg_6_0.List:reload()
end

function var_0_0.createItem(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_0.List:newItem()
	local var_7_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/backpack_window/open_activity_item/list_item.csb")
	local var_7_2 = var_7_1:getChildByName("container")
	local var_7_3 = var_7_2:getContentSize()

	arg_7_0:createClickNode(var_7_2:getChildByName("act1"), arg_7_1)
	arg_7_0:createClickNode(var_7_2:getChildByName("act2"), arg_7_2)
	var_7_0:addContent(var_7_1)
	var_7_1:setContentSize(var_7_3.width, var_7_3.height)
	var_7_0:setItemSize(var_7_3.width, var_7_3.height)
	arg_7_0.List:addItem(var_7_0)
end

function var_0_0.createClickNode(arg_8_0, arg_8_1, arg_8_2)
	if not arg_8_2 then
		arg_8_1:setVisible(false)

		return
	end

	arg_8_1:loadTexture(var_0_3:icon(arg_8_2))

	local var_8_0 = arg_8_1:getContentSize()
	local var_8_1 = display.newNode()

	var_8_1:setContentSize(var_8_0.width, var_8_0.height)
	var_8_1:addTo(arg_8_1)
	var_8_1:setTouchEnabled(true)
	var_8_1:setTouchSwallowEnabled(false)
	var_8_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
		if arg_9_0.name == "began" then
			return true
		elseif arg_9_0.name == "ended" then
			if arg_8_0.chooseFrame then
				arg_8_0.chooseFrame:removeSelf()
			end

			arg_8_0.choose = arg_8_2
			arg_8_0.chooseFrame = xyd.AssetLoader.get():loadSprite("windows/backpack_window/open_activity_item/choose_frame.png")

			arg_8_0.chooseFrame:scale(1.25, 1.05)
			arg_8_0.chooseFrame:setPosition(200, 68)
			arg_8_0.chooseFrame:addTo(arg_8_1)
		end
	end)
end

function var_0_0.didOpen(arg_10_0, arg_10_1)
	arg_10_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
