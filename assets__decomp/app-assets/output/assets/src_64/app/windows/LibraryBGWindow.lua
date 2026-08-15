local var_0_0 = class("LibraryBGWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.libraryBG
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.translation
local var_0_4 = 6
local var_0_5 = 762
local var_0_6 = 220
local var_0_7 = 360
local var_0_8 = 203
local var_0_9 = 80
local var_0_10 = 50001648
local var_0_11 = 1
local var_0_12 = 2

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.library = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.index = 1
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.bgs = arg_2_0.library.bgInfo
	arg_2_0.bgMain = arg_2_0.library.bgMain
	arg_2_0.bgRoom = arg_2_0.library.bgRoom
	arg_2_0.scroll = arg_2_0:nodeByName("scroll")
	arg_2_0.unlockBtn = arg_2_0:nodeByName("btn_unlock")
	arg_2_0.mainBtn = arg_2_0:nodeByName("btn_main")
	arg_2_0.roomBtn = arg_2_0:nodeByName("btn_room")

	arg_2_0:nodeByName("tip"):setString(var_0_3:translation("LIBRARY_CG_TIPS"))
	arg_2_0:nodeByName("txt_have"):setString(var_0_3:translation("ITEM_OWN"))
	arg_2_0:nodeByName("txt_way"):setString(var_0_3:translation("LIBRARY_BG_GET_WAY"))
	arg_2_0:nodeByName("set_main"):setString(var_0_3:translation("LIBRARY_BG_MAIN"))
	arg_2_0:nodeByName("set_room"):setString(var_0_3:translation("LIBRARY_BG_HOUSE"))

	local var_2_0 = arg_2_0.selfPlayer:getBackpack():getItemNumByID(var_0_10)

	arg_2_0:nodeByName("txt_num"):setString("x " .. var_2_0)

	local var_2_1 = display.newNode()

	var_2_1:setContentSize(var_0_9, var_0_9)
	var_2_1:setAnchorPoint(0.5, 0.5)
	var_2_1:addTo(arg_2_0:nodeByName("item_pos"))
	xyd.setItemAndAddTips(var_2_1, var_0_10)
	arg_2_0:sortBGs()

	local var_2_2 = arg_2_0.scroll:getContentSize()

	arg_2_0.bgCellList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_2_2.width, var_2_2.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_2_0.scroll):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.bgCellList:setDelegate(handler(arg_2_0, arg_2_0.cellListDelegate))
	arg_2_0.bgCellList:reload()
	arg_2_0:addBtnEvents()
	arg_2_0:updateLeft()
end

function var_0_0.scrollListener(arg_3_0, arg_3_1)
	if arg_3_1.name == "began" then
		arg_3_0.scrollViewMoved_ = false
		arg_3_0.prevY_ = arg_3_1.y
	elseif arg_3_1.name == "moved" and 20 <= math.abs(arg_3_1.y - arg_3_0.prevY_) then
		arg_3_0.scrollViewMoved_ = true
	end
end

function var_0_0.cellListDelegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return math.ceil(#arg_4_0.bgs / 2)
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		local var_4_0
		local var_4_1 = arg_4_0.bgCellList:dequeueItem()

		if not var_4_1 then
			var_4_1 = arg_4_0.bgCellList:newItem()
		else
			var_4_1:removeAllChildren()
		end

		local var_4_2 = display.newNode()

		for iter_4_0 = arg_4_3 * 2 - 1, arg_4_3 * 2 do
			if iter_4_0 > #arg_4_0.bgs then
				break
			end

			local var_4_3 = arg_4_0.bgs[iter_4_0].id
			local var_4_4 = arg_4_0.bgs[iter_4_0].isUnlock
			local var_4_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/library/background/bg_cell.csb")
			local var_4_6 = var_4_5:getChildByName("container")

			var_4_5:addTo(var_4_2)
			var_4_5:setPosition(0, 0)

			if iter_4_0 == arg_4_3 * 2 then
				var_4_5:setPosition(var_4_6:getWidth() + var_0_4, 0)
			end

			if iter_4_0 == arg_4_0.index then
				var_4_6:getChildByName("bg1"):setVisible(false)
				var_4_6:getChildByName("bg2"):setVisible(true)

				arg_4_0.chosenCell = var_4_6
			else
				var_4_6:getChildByName("bg1"):setVisible(true)
				var_4_6:getChildByName("bg2"):setVisible(false)
			end

			if var_4_3 == arg_4_0.bgMain then
				arg_4_0.mainCell = var_4_6
			end

			if var_4_3 == arg_4_0.bgRoom then
				arg_4_0.roomCell = var_4_6
			end

			if var_4_3 == var_0_11 then
				arg_4_0.defaultMainCell = var_4_6
			end

			if var_4_3 == var_0_12 then
				arg_4_0.defaultRoomCell = var_4_6
			end

			var_4_6:getChildByName("icon"):setLocalZOrder(100)

			if var_4_3 == arg_4_0.bgMain or var_4_3 == arg_4_0.bgRoom then
				var_4_6:getChildByName("icon"):getChildByName("set"):setVisible(true)
			elseif arg_4_0:isFreeTime(var_4_3) then
				var_4_6:getChildByName("icon"):getChildByName("new"):setVisible(true)
			else
				var_4_6:getChildByName("icon"):setVisible(false)
			end

			var_4_6:getChildByName("bg_time"):setLocalZOrder(100)

			if not var_4_4 and arg_4_0:isFreeTime(var_4_3) then
				var_4_6:getChildByName("bg_time"):setVisible(true)

				local var_4_7 = var_4_6:getChildByName("bg_time"):getChildByName("time")
				local var_4_8 = var_0_1:getTime(var_4_3) - xyd.ServerTime.get():getServerTime()

				var_4_7:setString(var_0_3:translation("TEAM_DRINK_LEFT_TIME") .. xyd.secondsToString1(var_4_8))

				if arg_4_0.countDownHandle then
					var_0_2.unscheduleGlobal(arg_4_0.countDownHandle)
				end

				arg_4_0.countDownHandle = var_0_2.scheduleGlobal(function()
					var_4_8 = var_4_8 - 1

					if var_4_8 <= 0 then
						if var_4_3 == arg_4_0.bgMain then
							arg_4_0.bgMain = var_0_11

							if arg_4_0.defaultMainCell and not tolua.isnull(arg_4_0.defaultMainCell) then
								arg_4_0.defaultMainCell:getChildByName("icon"):setVisible(true)
								arg_4_0.defaultMainCell:getChildByName("icon"):getChildByName("new"):setVisible(false)
								arg_4_0.defaultMainCell:getChildByName("icon"):getChildByName("set"):setVisible(true)
							end
						end

						if var_4_3 == arg_4_0.bgRoom then
							arg_4_0.bgRoom = var_0_11

							if arg_4_0.defaultRoomCell and not tolua.isnull(arg_4_0.defaultRoomCell) then
								arg_4_0.defaultRoomCell:getChildByName("icon"):setVisible(true)
								arg_4_0.defaultRoomCell:getChildByName("icon"):getChildByName("new"):setVisible(false)
								arg_4_0.defaultRoomCell:getChildByName("icon"):getChildByName("set"):setVisible(true)
							end
						end

						var_4_6:getChildByName("bg_time"):setVisible(false)
						arg_4_0:updateLeft()
						var_0_2.unscheduleGlobal(arg_4_0.countDownHandle)

						arg_4_0.countDownHandle = nil
					elseif var_4_6 and not tolua.isnull(var_4_6) then
						var_4_7:setString(var_0_3:translation("TEAM_DRINK_LEFT_TIME") .. xyd.secondsToString1(var_4_8))
					end
				end, 1)
			else
				var_4_6:getChildByName("bg_time"):setVisible(false)
			end

			local var_4_9
			local var_4_10 = xyd.SpriteLoader.new(var_0_1:getBG(var_4_3), nil, var_4_9, xyd.DefaultImageType.CG)
			local var_4_11 = var_4_10:getContentSize()

			var_4_10:setScaleX(var_0_7 / var_4_11.width)
			var_4_10:setScaleY(var_0_7 / var_4_11.width)
			var_4_10:setAnchorPoint(0.5, 0.5)
			var_4_10:addTo(var_4_6)
			var_4_10:setPosition(var_4_6:getChildByName("img_pos"):getPosition())
			var_4_10:setLocalZOrder(99)
			var_4_10:setTouchEnabled(true)
			var_4_10:setTouchSwallowEnabled(false)

			if not var_4_4 and not arg_4_0:isFreeTime(var_4_3) then
				xyd.GrayNode(var_4_10)
			end

			var_4_10:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
				if arg_6_0.name == "ended" and not arg_4_0.isAnimation and not arg_4_0.scrollViewMoved_ then
					if arg_4_0.index ~= iter_4_0 then
						if arg_4_0.chosenCell and not tolua.isnull(arg_4_0.chosenCell) then
							arg_4_0.chosenCell:getChildByName("bg1"):setVisible(true)
							arg_4_0.chosenCell:getChildByName("bg2"):setVisible(false)
						end

						arg_4_0.chosenCell = var_4_6

						arg_4_0.chosenCell:getChildByName("bg1"):setVisible(false)
						arg_4_0.chosenCell:getChildByName("bg2"):setVisible(true)

						arg_4_0.index = iter_4_0

						arg_4_0:updateLeft()

						return
					end

					local var_6_0 = var_4_6:getChildByName("img_pos"):convertToWorldSpace(cc.p(0, 0))
					local var_6_1 = cc.Director:getInstance():getVisibleSize()
					local var_6_2 = var_6_1.width / 2 - var_6_0.x
					local var_6_3 = var_6_1.height / 2 - var_6_0.y

					if arg_4_0.cardClicked_ then
						if not var_4_4 and not arg_4_0:isFreeTime(var_4_3) then
							xyd.GrayNode(var_4_10)
						end

						local var_6_4 = cc.Spawn:create(cc.DelayTime:create(0.4), cc.FadeIn:create(0.2))
						local var_6_5 = cc.Spawn:create(cc.ScaleTo:create(0.4, var_0_7 / var_4_11.width, var_0_7 / var_4_11.width), cc.MoveBy:create(0.4, cc.p(-var_6_2, -var_6_3)), cc.DelayTime:create(0.2))

						arg_4_0.isAnimation = true

						if var_4_6:getChildByName("icon"):isVisible() then
							var_4_6:getChildByName("icon"):runActionOnce(var_6_4)
						end

						var_4_10:runActionOnce(var_6_5, false, function()
							arg_4_0.cardClicked_ = false
							arg_4_0.isAnimation = false

							arg_4_0.bgCellList:setTouchEnabled(true)
							arg_4_0:nodeByName("close"):setTouchEnabled(true)
							var_4_6:getChildByName("bg_time"):setVisible(arg_4_0:isFreeTime(var_4_3))
							var_4_10:setTouchSwallowEnabled(false)
							var_4_10:setGlobalZOrder(0)
							var_4_10:setLocalZOrder(99)
						end)
					else
						if not var_4_4 and not arg_4_0:isFreeTime(var_4_3) then
							xyd.unGrayNode(var_4_10)
						end

						var_4_10:setGlobalZOrder(100)

						local var_6_6 = cc.FadeOut:create(0.2)
						local var_6_7 = cc.Spawn:create(cc.DelayTime:create(0.2), cc.ScaleTo:create(0.4, 1), cc.MoveBy:create(0.4, cc.p(var_6_2, var_6_3)))

						arg_4_0.isAnimation = true

						arg_4_0:nodeByName("close"):setTouchEnabled(false)
						arg_4_0.bgCellList:setTouchEnabled(false)
						var_4_10:setTouchSwallowEnabled(true)

						if var_4_6:getChildByName("icon"):isVisible() then
							var_4_6:getChildByName("icon"):runActionOnce(var_6_6)
						end

						var_4_6:getChildByName("bg_time"):setVisible(false)
						var_4_10:runActionOnce(var_6_7, false, function()
							arg_4_0.cardClicked_ = true
							arg_4_0.isAnimation = false
						end)
					end
				end

				return true
			end)
		end

		var_4_2:setContentSize(var_0_5, var_0_6)
		var_4_1:setItemSize(var_0_5, var_0_6)
		var_4_1:addContent(var_4_2)

		return var_4_1
	end
end

function var_0_0.addBtnEvents(arg_9_0)
	arg_9_0.unlockBtn:addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended and not arg_9_0.isAnimation then
			local var_10_0 = arg_9_0.selfPlayer:getBackpack():getItemNumByID(var_0_10)
			local var_10_1 = arg_9_0.bgs[arg_9_0.index]

			if var_10_1.isUnlock then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("LIBRARY_BG_TIPS2")
				})
			elseif var_10_0 <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("LIBRARY_BG_NO")
				})
			else
				arg_9_0.library:unlockLibraryBG({
					bg_id = var_10_1.id
				}, function()
					arg_9_0.selfPlayer:getBackpack():removeItem({
						itemNum = 1,
						itemID = var_0_10
					})

					local var_11_0 = arg_9_0.selfPlayer:getBackpack():getItemNumByID(var_0_10)

					arg_9_0:nodeByName("txt_num"):setString("x " .. var_11_0)

					arg_9_0.bgs[arg_9_0.index].isUnlock = true

					arg_9_0:sortBGs()

					if arg_9_0.countDownHandle then
						var_0_2.unscheduleGlobal(arg_9_0.countDownHandle)

						arg_9_0.countDownHandle = nil
					end

					local var_11_1

					for iter_11_0 = 1, #arg_9_0.bgs do
						if arg_9_0.bgs[iter_11_0].id == var_10_1.id then
							var_11_1 = iter_11_0

							break
						end
					end

					arg_9_0.index = var_11_1

					arg_9_0:updateLeft()
					arg_9_0.bgCellList:reload()

					local var_11_2 = (math.ceil(var_11_1 / 2) + 1) * var_0_6 + 26

					if var_11_2 > math.ceil(#arg_9_0.bgs / 2) * var_0_6 then
						arg_9_0.bgCellList:scrollTo(0, math.ceil(#arg_9_0.bgs / 2) * var_0_6)
					else
						arg_9_0.bgCellList:scrollTo(0, var_11_2)
					end
				end)
			end
		end
	end)
	arg_9_0.mainBtn:addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended and not arg_9_0.isAnimation then
			local var_12_0 = arg_9_0.bgs[arg_9_0.index].id

			arg_9_0.library:setLibraryBG({
				_type = 1,
				bg_id = var_12_0
			}, function()
				if var_12_0 == arg_9_0.bgMain then
					arg_9_0.mainBtn:getChildByName("chose"):setVisible(false)
				else
					arg_9_0.mainBtn:getChildByName("chose"):setVisible(true)
				end

				if arg_9_0.mainCell and not tolua.isnull(arg_9_0.mainCell) and arg_9_0.bgMain ~= arg_9_0.bgRoom then
					arg_9_0.mainCell:getChildByName("icon"):getChildByName("set"):setVisible(false)

					if arg_9_0:isFreeTime(arg_9_0.bgMain) then
						arg_9_0.mainCell:getChildByName("icon"):getChildByName("new"):setVisible(true)
					else
						arg_9_0.mainCell:getChildByName("icon"):setVisible(false)
					end
				end

				if var_12_0 == arg_9_0.bgMain then
					arg_9_0.bgMain = var_0_11
					arg_9_0.library.bgMain = var_0_11
					arg_9_0.mainCell = arg_9_0.defaultMainCell
				else
					arg_9_0.bgMain = var_12_0
					arg_9_0.library.bgMain = var_12_0
					arg_9_0.mainCell = arg_9_0.chosenCell
				end

				if arg_9_0.mainCell and not tolua.isnull(arg_9_0.mainCell) then
					arg_9_0.mainCell:getChildByName("icon"):setVisible(true)
					arg_9_0.mainCell:getChildByName("icon"):getChildByName("new"):setVisible(false)
					arg_9_0.mainCell:getChildByName("icon"):getChildByName("set"):setVisible(true)
				end

				arg_9_0:updateLeft()

				if display.getRunningScene().__cname == "MainScene" then
					display.getRunningScene():setupBackground()
				end
			end)
		end
	end)
	arg_9_0.roomBtn:addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended and not arg_9_0.isAnimation then
			local var_14_0 = arg_9_0.bgs[arg_9_0.index].id

			arg_9_0.library:setLibraryBG({
				_type = 2,
				bg_id = var_14_0
			}, function()
				if var_14_0 == arg_9_0.bgRoom then
					arg_9_0.roomBtn:getChildByName("chose"):setVisible(false)
				else
					arg_9_0.roomBtn:getChildByName("chose"):setVisible(true)
				end

				if arg_9_0.roomCell and not tolua.isnull(arg_9_0.roomCell) and arg_9_0.bgMain ~= arg_9_0.bgRoom then
					arg_9_0.roomCell:getChildByName("icon"):getChildByName("set"):setVisible(false)

					if arg_9_0:isFreeTime(arg_9_0.bgRoom) then
						arg_9_0.roomCell:getChildByName("icon"):getChildByName("new"):setVisible(true)
					else
						arg_9_0.roomCell:getChildByName("icon"):setVisible(false)
					end
				end

				if var_14_0 == arg_9_0.bgRoom then
					arg_9_0.bgRoom = var_0_12
					arg_9_0.library.bgRoom = var_0_12
					arg_9_0.roomCell = arg_9_0.defaultRoomCell
				else
					arg_9_0.bgRoom = var_14_0
					arg_9_0.library.bgRoom = var_14_0
					arg_9_0.roomCell = arg_9_0.chosenCell
				end

				if arg_9_0.roomCell and not tolua.isnull(arg_9_0.roomCell) then
					arg_9_0.roomCell:getChildByName("icon"):setVisible(true)
					arg_9_0.roomCell:getChildByName("icon"):getChildByName("new"):setVisible(false)
					arg_9_0.roomCell:getChildByName("icon"):getChildByName("set"):setVisible(true)
				end

				arg_9_0:updateLeft()
			end)
		end
	end)
end

function var_0_0.updateLeft(arg_16_0)
	local var_16_0 = arg_16_0.bgs[arg_16_0.index]
	local var_16_1 = arg_16_0:isFreeTime(var_16_0.id)

	arg_16_0.mainBtn:setBright((var_16_0.isUnlock or var_16_1) and (var_16_0.id ~= var_0_11 or arg_16_0.bgMain ~= var_0_11))
	arg_16_0.roomBtn:setBright((var_16_0.isUnlock or var_16_1) and (var_16_0.id ~= var_0_12 or arg_16_0.bgRoom ~= var_0_12))
	arg_16_0.mainBtn:setTouchEnabled((var_16_0.isUnlock or var_16_1) and (var_16_0.id ~= var_0_11 or arg_16_0.bgMain ~= var_0_11))
	arg_16_0.roomBtn:setTouchEnabled((var_16_0.isUnlock or var_16_1) and (var_16_0.id ~= var_0_12 or arg_16_0.bgRoom ~= var_0_12))
	arg_16_0.mainBtn:getChildByName("chose"):setVisible(var_16_0.id == arg_16_0.bgMain)
	arg_16_0.roomBtn:getChildByName("chose"):setVisible(var_16_0.id == arg_16_0.bgRoom)
end

function var_0_0.sortBGs(arg_17_0)
	table.sort(arg_17_0.bgs, function(arg_18_0, arg_18_1)
		if arg_18_0.id == arg_17_0.bgMain then
			return true
		end

		if arg_18_1.id == arg_17_0.bgMain then
			return false
		end

		if arg_18_0.id == arg_17_0.bgRoom then
			return true
		end

		if arg_18_1.id == arg_17_0.bgRoom then
			return false
		end

		if var_0_1:getLimit(arg_18_0.id) == 2 then
			return true
		end

		if var_0_1:getLimit(arg_18_1.id) == 2 then
			return false
		end

		if arg_18_0.isUnlock and not arg_18_1.isUnlock then
			return true
		end

		if not arg_18_0.isUnlock and arg_18_1.isUnlock then
			return false
		end

		return arg_18_0.id < arg_18_1.id
	end)
end

function var_0_0.isFreeTime(arg_19_0, arg_19_1)
	return var_0_1:getLimit(arg_19_1) == 2 and var_0_1:getTime(arg_19_1) > xyd.ServerTime.get():getServerTime()
end

function var_0_0.didOpen(arg_20_0, arg_20_1)
	arg_20_0:setTouchSwallowEnabled(true)
	arg_20_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 0))
end

function var_0_0.didClose(arg_21_0)
	if arg_21_0.countDownHandle then
		var_0_2.unscheduleGlobal(arg_21_0.countDownHandle)

		arg_21_0.countDownHandle = nil
	end
end

return var_0_0
