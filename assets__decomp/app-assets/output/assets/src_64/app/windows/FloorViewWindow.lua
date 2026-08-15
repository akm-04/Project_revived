local var_0_0 = class("FloorViewWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.hero
local var_0_5 = xyd.tables.item
local var_0_6 = 6
local var_0_7 = "skeletons/ui_effect/dorm/kuojian_name"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.dorm = xyd.ModelManager.get():loadModel(xyd.ModelType.DORM)
	arg_1_0.floorState = arg_1_2.floorType
	arg_1_0.unlockFloor = false
	arg_1_0.lockRoomCanTouch = true
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:setButtonClick()
	arg_2_0:layout()
end

function var_0_0.setButtonClick(arg_3_0, arg_3_1)
	arg_3_0:nodeByName("btn_lounge"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended and arg_3_0.lockRoomCanTouch then
			arg_3_0.dorm:toLoungeHouse()
		end
	end)
	arg_3_0:nodeByName("btn_normal"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended and arg_3_0.lockRoomCanTouch then
			if not arg_3_0.dorm:checkDormOpen(xyd.FunctionID.ID_DORM_NORMAL) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("DORM_LIMIT_1")
				})

				return
			end

			arg_3_0.floorState = xyd.DormType.NORMAL

			arg_3_0:changeFloorState()
			arg_3_0:updateListInfo()
			arg_3_0.list:reload()

			if not arg_3_0.dorm:isSelfDorm() then
				local var_5_0 = cc.p(0, #arg_3_0.listInfo * 720)

				arg_3_0.list:scrollTo(var_5_0.x, var_5_0.y)
			end
		end
	end)
	arg_3_0:nodeByName("btn_foreign"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended and arg_3_0.lockRoomCanTouch then
			if not arg_3_0.dorm:checkDormOpen(xyd.FunctionID.ID_DORM_FOREIGN) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("DORM_LIMIT_1")
				})

				return
			end

			arg_3_0.floorState = xyd.DormType.FOREIGN

			arg_3_0:changeFloorState()
			arg_3_0:updateListInfo()
			arg_3_0.list:reload()

			if not arg_3_0.dorm:isSelfDorm() then
				local var_6_0 = cc.p(0, #arg_3_0.listInfo * 720)

				arg_3_0.list:scrollTo(var_6_0.x, var_6_0.y)
			end
		end
	end)
	arg_3_0:nodeByName("btn_villa"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended and arg_3_0.lockRoomCanTouch then
			if not arg_3_0.dorm:checkDormOpen(xyd.FunctionID.ID_DORM_VILLA) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("DORM_LIMIT_1")
				})

				return
			end

			arg_3_0.floorState = xyd.DormType.VILLA

			arg_3_0:changeFloorState()
			arg_3_0:updateListInfo()
			arg_3_0.list:reload()

			if not arg_3_0.dorm:isSelfDorm() then
				local var_7_0 = cc.p(0, #arg_3_0.listInfo * 720)

				arg_3_0.list:scrollTo(var_7_0.x, var_7_0.y)
			end
		end
	end)
	arg_3_0:nodeByName("close"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended and arg_3_0.lockRoomCanTouch then
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	return
end

function var_0_0.didClose(arg_10_0, arg_10_1)
	var_0_0.super:didClose(arg_10_1)
end

function var_0_0.layout(arg_11_0)
	local var_11_0 = arg_11_0:nodeByName("foreign_effect")
	local var_11_1 = "skeletons/ui_effect/dorm/dorm_guidepost"
	local var_11_2 = var_0_2.new(var_11_1 .. ".json", var_11_1 .. ".atlas", 1)

	var_11_0:removeAllChildren()
	var_11_2:setScale(-1)
	var_11_2:addTo(var_11_0)
	var_11_2:play(nil, true)

	local var_11_3 = arg_11_0:nodeByName("villa_effect")
	local var_11_4 = "skeletons/ui_effect/dorm/dorm_guidepost"
	local var_11_5 = var_0_2.new(var_11_4 .. ".json", var_11_4 .. ".atlas", 1)

	var_11_3:removeAllChildren()
	var_11_5:addTo(var_11_3)
	var_11_5:play(nil, true)

	local var_11_6 = arg_11_0:nodeByName("normal_effect")
	local var_11_7 = "skeletons/ui_effect/dorm/dorm_guidepost"
	local var_11_8 = var_0_2.new(var_11_7 .. ".json", var_11_7 .. ".atlas", 1)

	var_11_6:removeAllChildren()
	var_11_8:addTo(var_11_6)
	var_11_8:play(nil, true)

	local var_11_9 = arg_11_0:nodeByName("floor_list")
	local var_11_10 = var_11_9:getContentSize()

	arg_11_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_11_10.width, var_11_10.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_11_9):onScroll(handler(arg_11_0, arg_11_0.scrollListener))

	arg_11_0.list:setBounceable(false)
	arg_11_0.list:setDelegate(handler(arg_11_0, arg_11_0.delegate))
	arg_11_0:changeFloorState()
	arg_11_0:updateListInfo()
	arg_11_0.list:reload()

	if not arg_11_0.dorm:isSelfDorm() then
		local var_11_11 = cc.p(0, #arg_11_0.listInfo * 720)

		arg_11_0.list:scrollTo(var_11_11.x, var_11_11.y)
	end
end

function var_0_0.scrollListener(arg_12_0, arg_12_1)
	if arg_12_1.name == "began" then
		arg_12_0.scrollViewMoved_ = false
		arg_12_0.prevX_ = arg_12_1.x
		arg_12_0.prevY_ = arg_12_1.y
	elseif arg_12_1.name == "moved" then
		local var_12_0 = 3

		if var_12_0 <= math.abs(arg_12_1.y - arg_12_0.prevY_) or var_12_0 <= math.abs(arg_12_1.x - arg_12_0.prevX_) then
			arg_12_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.changeFloorState(arg_13_0)
	if arg_13_0.floorState == xyd.DormType.NORMAL then
		arg_13_0:nodeByName("btn_normal"):setTouchEnabled(false)
		arg_13_0:nodeByName("btn_foreign"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_villa"):setTouchEnabled(true)
		arg_13_0:nodeByName("villa_effect"):setVisible(false)
		arg_13_0:nodeByName("normal_effect"):setVisible(true)
		arg_13_0:nodeByName("foreign_effect"):setVisible(false)
		arg_13_0:nodeByName("btn_normal"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_13_0:nodeByName("btn_foreign"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("btn_villa"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_13_0.floorState == xyd.DormType.FOREIGN then
		arg_13_0:nodeByName("btn_normal"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_foreign"):setTouchEnabled(false)
		arg_13_0:nodeByName("btn_villa"):setTouchEnabled(true)
		arg_13_0:nodeByName("villa_effect"):setVisible(false)
		arg_13_0:nodeByName("normal_effect"):setVisible(false)
		arg_13_0:nodeByName("foreign_effect"):setVisible(true)
		arg_13_0:nodeByName("btn_normal"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("btn_foreign"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_13_0:nodeByName("btn_villa"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_13_0.floorState == xyd.DormType.VILLA then
		arg_13_0:nodeByName("btn_normal"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_foreign"):setTouchEnabled(true)
		arg_13_0:nodeByName("btn_villa"):setTouchEnabled(false)
		arg_13_0:nodeByName("foreign_effect"):setVisible(false)
		arg_13_0:nodeByName("normal_effect"):setVisible(false)
		arg_13_0:nodeByName("villa_effect"):setVisible(true)
		arg_13_0:nodeByName("btn_normal"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("btn_foreign"):setBrightStyle(ccui.BrightStyle.normal)
		arg_13_0:nodeByName("btn_villa"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_0.updateListInfo(arg_14_0, arg_14_1)
	arg_14_0.listInfo = {}

	local var_14_0 = arg_14_1 or false
	local var_14_1 = {}

	for iter_14_0, iter_14_1 in pairs(arg_14_0.dorm.dormBaseInfo) do
		if iter_14_0 == arg_14_0.floorState then
			var_14_1 = iter_14_1
		end
	end

	for iter_14_2 = 1, math.ceil((#var_14_1 + 1) / 6) do
		arg_14_0.listInfo[iter_14_2] = {}
	end

	for iter_14_3, iter_14_4 in pairs(var_14_1) do
		arg_14_0.listInfo[iter_14_4.floor][iter_14_4.pos] = iter_14_4
	end

	if arg_14_0:checkTopFloorisFull() then
		if var_14_0 then
			arg_14_0.unlockFloor = true

			arg_14_0:showUnlockEffect()
		end

		arg_14_0.listInfo[#arg_14_0.listInfo + 1] = {}
	end
end

function var_0_0.showUnlockEffect(arg_15_0)
	local var_15_0 = arg_15_0:nodeByName("floor_effect")
	local var_15_1 = "skeletons/ui_effect/dorm/dorm_floor"
	local var_15_2 = var_0_2.new(var_15_1 .. ".json", var_15_1 .. ".atlas", 1)

	var_15_0:removeAllChildren()
	var_15_2:addTo(var_15_0)
	var_15_2:play(nil, false, 1, nil)

	arg_15_0.schedulerHandler = var_0_1.performWithDelayGlobal(function()
		var_15_0:removeAllChildren()
	end, 2.5)
end

function var_0_0.delegate(arg_17_0, arg_17_1, arg_17_2, arg_17_3)
	if cc.ui.UIListView.COUNT_TAG == arg_17_2 then
		return #arg_17_0.listInfo
	elseif cc.ui.UIListView.CELL_TAG == arg_17_2 then
		local var_17_0 = arg_17_0.list:dequeueItem()

		if not var_17_0 then
			var_17_0 = arg_17_0.list:newItem()
		else
			var_17_0:removeAllChildren(true)
		end

		local var_17_1 = 1280
		local var_17_2 = 720

		var_17_0:setItemSize(var_17_1, var_17_2)

		local var_17_3 = display.newNode()

		var_17_3:setContentSize(var_17_1, var_17_2)
		arg_17_0:initCell(var_17_3, arg_17_3)
		var_17_0:addContent(var_17_3)

		return var_17_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_17_2 then
		-- block empty
	end
end

function var_0_0.checkTopFloorisFull(arg_18_0)
	local var_18_0 = var_0_6

	if #arg_18_0.listInfo == 1 then
		var_18_0 = var_0_6 - 1
	end

	for iter_18_0 = 1, var_18_0 do
		if not arg_18_0.listInfo[#arg_18_0.listInfo][iter_18_0] then
			return false
		end
	end

	return true
end

function var_0_0.initCell(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = var_0_6

	if arg_19_2 == #arg_19_0.listInfo then
		var_19_0 = var_0_6 - 1
	end

	local var_19_1

	if arg_19_0.floorState == xyd.DormType.NORMAL then
		if arg_19_2 == #arg_19_0.listInfo then
			var_19_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/dorm/floor_view/normal_floor_1.csb")
		else
			var_19_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/dorm/floor_view/normal_floor_2.csb")
		end
	elseif arg_19_0.floorState == xyd.DormType.FOREIGN then
		if arg_19_2 == #arg_19_0.listInfo then
			var_19_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/dorm/floor_view/foreign_floor_1.csb")
		else
			var_19_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/dorm/floor_view/foreign_floor_2.csb")
		end
	elseif arg_19_0.floorState == xyd.DormType.VILLA then
		if arg_19_2 == #arg_19_0.listInfo then
			var_19_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/dorm/floor_view/villa_floor_1.csb")
		else
			var_19_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/dorm/floor_view/villa_floor_2.csb")
		end
	end

	var_19_1:setPosition(0, 0)
	var_19_1:setAnchorPoint(0, 0)
	arg_19_1:addChild(var_19_1)

	for iter_19_0 = 1, var_19_0 do
		local var_19_2 = var_19_1:getChildByName("bg")
		local var_19_3 = arg_19_0.listInfo[#arg_19_0.listInfo - arg_19_2 + 1][iter_19_0]

		if var_19_3 and not arg_19_0.dorm:isSelfDorm() and var_19_3.is_hide == 1 then
			var_19_2:getChildByName("lock_room_" .. iter_19_0):setVisible(false)
			var_19_2:getChildByName("empty_room_" .. iter_19_0):setVisible(false)
			var_19_2:getChildByName("full_room_" .. iter_19_0):setVisible(false)
			var_19_2:getChildByName("invisable_room_" .. iter_19_0):setVisible(true)
			var_19_2:getChildByName("invisable_room_" .. iter_19_0):setTouchEnabled(true)
			var_19_2:getChildByName("invisable_room_" .. iter_19_0):setTouchSwallowEnabled(false)
			var_19_2:getChildByName("invisable_room_" .. iter_19_0):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
				if arg_20_0.name == "ended" and not arg_19_0.scrollViewMoved_ and arg_19_0.lockRoomCanTouch then
					local var_20_0 = var_0_3:translation("DORM_ROOM_INVISABLE")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_20_0
					})
				end

				return true
			end)
		elseif var_19_3 and var_19_3.partner_infos and next(var_19_3.partner_infos) then
			var_19_2:getChildByName("lock_room_" .. iter_19_0):setVisible(false)
			var_19_2:getChildByName("empty_room_" .. iter_19_0):setVisible(false)
			var_19_2:getChildByName("full_room_" .. iter_19_0):setVisible(true)
			var_19_2:getChildByName("invisable_room_" .. iter_19_0):setVisible(false)

			if #var_19_3.house_name == 0 then
				var_19_2:getChildByName("full_room_" .. iter_19_0):getChildByName("room_name"):setString(xyd.tables.dormHouse:name(var_19_3.table_id))
			else
				var_19_2:getChildByName("full_room_" .. iter_19_0):getChildByName("room_name"):setString(var_19_3.house_name)
			end

			arg_19_0:addNameEffect(var_19_2:getChildByName("full_room_" .. iter_19_0):getChildByName("room_name"), var_19_3)

			local var_19_4 = var_19_3.partner_infos[1].table_id
			local var_19_5 = var_19_3.partner_infos[1].color
			local var_19_6 = var_19_3.partner_infos[1].star
			local var_19_7 = var_19_3.partner_infos[1].twice_awake_stage == xyd.AwakeTwiceStage.COMPLETE
			local var_19_8 = var_19_3.partner_infos[1].current_skin_id
			local var_19_9 = var_19_3.partner_infos[1].illusion_skin_id

			if var_19_9 then
				if var_19_9 == 0 then
					if var_0_4:beforeAwaken(var_19_4) > 0 then
						var_19_8 = var_0_4:modelID(var_0_4:beforeAwaken(var_19_4))
					else
						var_19_8 = var_0_4:modelID(var_19_4)
					end
				elseif var_19_9 == 1 then
					if var_0_4:beforeAwaken(var_19_4) > 0 then
						var_19_8 = var_0_4:modelID(var_19_4)
					else
						var_19_8 = var_0_4:modelID(var_0_4:afterAwaken(var_19_4))
					end
				else
					var_19_8 = var_19_9
				end
			end

			xyd.setAvatarBorder(var_19_4, var_19_2:getChildByName("full_room_" .. iter_19_0):getChildByName("hero_avatar"), var_19_5, var_19_6, var_19_7, nil, var_19_8)
			var_19_2:getChildByName("full_room_" .. iter_19_0):getChildByName("enter_touch"):setTouchEnabled(true)
			var_19_2:getChildByName("full_room_" .. iter_19_0):getChildByName("enter_touch"):setTouchSwallowEnabled(false)
			var_19_2:getChildByName("full_room_" .. iter_19_0):getChildByName("enter_touch"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_21_0)
				if arg_21_0.name == "ended" and not arg_19_0.scrollViewMoved_ and arg_19_0.lockRoomCanTouch then
					arg_19_0.dorm:toHouse(var_19_3)
				end

				return true
			end)
		elseif var_19_3 and (not var_19_3.partner_infos or not next(var_19_3.partner_infos)) then
			var_19_2:getChildByName("lock_room_" .. iter_19_0):setVisible(false)
			var_19_2:getChildByName("empty_room_" .. iter_19_0):setVisible(true)
			var_19_2:getChildByName("full_room_" .. iter_19_0):setVisible(false)
			var_19_2:getChildByName("invisable_room_" .. iter_19_0):setVisible(false)

			if #var_19_3.house_name == 0 then
				var_19_2:getChildByName("empty_room_" .. iter_19_0):getChildByName("room_name"):setString(xyd.tables.dormHouse:name(var_19_3.table_id))
			else
				var_19_2:getChildByName("empty_room_" .. iter_19_0):getChildByName("room_name"):setString(var_19_3.house_name)
			end

			arg_19_0:addNameEffect(var_19_2:getChildByName("empty_room_" .. iter_19_0):getChildByName("room_name"), var_19_3)
			var_19_2:getChildByName("empty_room_" .. iter_19_0):getChildByName("enter_touch"):setTouchEnabled(true)
			var_19_2:getChildByName("empty_room_" .. iter_19_0):getChildByName("enter_touch"):setTouchSwallowEnabled(false)
			var_19_2:getChildByName("empty_room_" .. iter_19_0):getChildByName("enter_touch"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_22_0)
				if arg_22_0.name == "ended" and not arg_19_0.scrollViewMoved_ and arg_19_0.lockRoomCanTouch then
					arg_19_0.dorm:toHouse(var_19_3)
				end

				return true
			end)
		elseif not var_19_3 then
			var_19_2:getChildByName("lock_room_" .. iter_19_0):setVisible(true)
			var_19_2:getChildByName("empty_room_" .. iter_19_0):setVisible(false)
			var_19_2:getChildByName("full_room_" .. iter_19_0):setVisible(false)
			var_19_2:getChildByName("invisable_room_" .. iter_19_0):setVisible(false)

			if arg_19_0.dorm:isSelfDorm() then
				var_19_2:getChildByName("lock_room_" .. iter_19_0):setTouchEnabled(true)
				var_19_2:getChildByName("lock_room_" .. iter_19_0):setTouchSwallowEnabled(false)
				var_19_2:getChildByName("lock_room_" .. iter_19_0):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_23_0)
					if arg_23_0.name == "ended" and not arg_19_0.scrollViewMoved_ and arg_19_0.lockRoomCanTouch then
						if not arg_19_0:checkHasKey(arg_19_0.floorState) then
							local var_23_0 = var_0_3:translation("DORM_HAS_NO_KEY")

							xyd.WindowManager.get():openWindow("toast", {
								message = var_23_0
							})
						else
							local var_23_1 = {
								keyType = arg_19_0.floorState,
								floor = #arg_19_0.listInfo - arg_19_2 + 1,
								pos = iter_19_0,
								callback = function(arg_24_0)
									local var_24_0 = var_19_2:getChildByName("lock_room_" .. iter_19_0)

									var_24_0:getChildByName("islock"):setVisible(false)

									local var_24_1 = display.newNode()

									var_24_1:addTo(var_24_0)
									var_24_1:setPosition(var_24_0:getChildByName("islock"):getPositionX(), var_24_0:getChildByName("islock"):getPositionY() - 10)
									var_24_1:setScaleX(var_24_0:getChildByName("islock"):getScaleX())
									var_24_1:setScaleY(var_24_0:getChildByName("islock"):getScaleY())

									local var_24_2 = "skeletons/ui_effect/dorm/dorm_key"
									local var_24_3 = var_0_2.new(var_24_2 .. ".json", var_24_2 .. ".atlas", 1)

									var_24_1:removeAllChildren()
									var_24_3:addTo(var_24_1)
									var_24_3:play(nil, false, 1, nil)
								end
							}

							xyd.WindowManager.get():openWindow("select_key", var_23_1)
						end
					end

					return true
				end)
			end
		end
	end
end

function var_0_0.addNameEffect(arg_25_0, arg_25_1, arg_25_2)
	if arg_25_2.expand_lev and arg_25_2.expand_lev > 0 then
		local var_25_0 = xyd.createEffect(var_0_7)

		var_25_0:addTo(arg_25_1)
		var_25_0:setPosition(arg_25_1:getContentSize().width / 2, arg_25_1:getContentSize().height / 2)
		var_25_0:play(nil, true)
	end
end

function var_0_0.checkHasKey(arg_26_0, arg_26_1)
	local var_26_0 = xyd.tables.dormHouseKey:getAllKeysByType(arg_26_1)

	for iter_26_0, iter_26_1 in pairs(var_26_0) do
		if arg_26_0.selfPlayer:getBackpack():getItemNumByID(iter_26_1) > 0 then
			return true
		end
	end

	return false
end

function var_0_0.didClose(arg_27_0)
	var_0_0.super.didClose()

	if arg_27_0.schedulerHandler ~= nil then
		var_0_1.unscheduleGlobal(arg_27_0.schedulerHandler)
	end
end

return var_0_0
