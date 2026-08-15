local var_0_0 = class("PetRoomSelectPetWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 6

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.heros = arg_1_0.selfPlayer.collectedPets
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.scroll = arg_3_0:nodeByName("scroll")

	local var_3_0 = arg_3_0.scroll:getContentSize()

	arg_3_0.petsList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 10, var_3_0.width, var_3_0.height - 10),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0.scroll):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.petsList:setDelegate(handler(arg_3_0, arg_3_0.petsListDelegate))
	arg_3_0.petsList:setBounceable(false)
	arg_3_0.petsList:reload()
	arg_3_0:nodeByName("decrease_time_txt"):setString(var_0_1:translation("PET_CHOOSE_TIP_1"))
	arg_3_0:nodeByName("txt_title"):setString(var_0_1:translation("EVENT_CENTRE_TIP5"))
end

function var_0_0.petsListDelegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return math.ceil(#arg_4_0.heros / var_0_2)
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		local var_4_0
		local var_4_1 = arg_4_0.petsList:dequeueItem()

		if not var_4_1 then
			var_4_1 = arg_4_0.petsList:newItem()
		else
			var_4_1:removeAllChildren(true)
		end

		local var_4_2 = arg_4_0:createListLineContent(arg_4_3)
		local var_4_3 = var_4_2:getWidth()
		local var_4_4 = var_4_2:getHeight()

		var_4_1:setItemSize(var_4_3, var_4_4)
		var_4_1:addContent(var_4_2)

		return var_4_1
	end
end

function var_0_0.createListLineContent(arg_5_0, arg_5_1)
	local var_5_0 = display.newNode()
	local var_5_1 = 126
	local var_5_2 = 63
	local var_5_3 = 80

	var_5_0:setContentSize(760, 160)

	for iter_5_0 = 1, var_0_2 do
		if (arg_5_1 - 1) * var_0_2 + iter_5_0 <= #arg_5_0.heros then
			local var_5_4 = arg_5_0.heros[(arg_5_1 - 1) * var_0_2 + iter_5_0]
			local var_5_5 = arg_5_0:creatPetContent(var_5_4)

			var_5_5:addTo(var_5_0)
			var_5_5:setAnchorPoint(0.5, 0.5)
			var_5_5:setPosition(cc.p(var_5_2, var_5_3))

			var_5_2 = var_5_2 + var_5_1

			var_5_5:setTouchEnabled(true)
			var_5_5:setTouchSwallowEnabled(false)
			var_5_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
				if arg_6_0.name == "began" then
					var_5_5:setScale(0.9)

					return true
				elseif arg_6_0.name == "ended" then
					var_5_5:setScale(1)

					if arg_5_0.scrollViewMoved_ then
						return
					end

					if arg_5_0.callback then
						arg_5_0.callback(var_5_4)
						xyd.WindowManager.get():closeWindow(arg_5_0)
					end
				end
			end)
		end
	end

	return var_5_0
end

function var_0_0.creatPetContent(arg_7_0, arg_7_1)
	local var_7_0 = display.newNode()

	var_7_0:setContentSize(126, 160)

	local var_7_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/event_centre/pet_room/select_pet_item.csb")
	local var_7_2 = var_7_1:getChildByName("container")

	xyd.setPetAvatar(var_7_2:getChildByName("pet"), arg_7_1, nil, true)
	var_7_2:getChildByName("txt_name"):setString(arg_7_1:getName())
	var_7_1:addTo(var_7_0)
	var_7_1:setPosition(63, 80)

	return var_7_0
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	var_0_0.super:didOpen(arg_8_1)
	arg_8_0:addBlockLayer()
end

function var_0_0.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.scrollViewMoved_ = false
		arg_9_0.prevY_ = arg_9_1.y
	elseif arg_9_1.name == "moved" and 5 <= math.abs(arg_9_1.y - arg_9_0.prevY_) then
		arg_9_0.scrollViewMoved_ = true
	end
end

return var_0_0
