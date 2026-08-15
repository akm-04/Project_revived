local var_0_0 = class("ZhugeNewAdventureWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.zhugeMazeEvent
local var_0_4 = xyd.tables.translation
local var_0_5 = 4
local var_0_6 = 5
local var_0_7 = 140
local var_0_8 = 0.12

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.zhugeModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.mapInfos = {}
	arg_1_0.isShowAnimation = 0
	arg_1_0.curIndex = {
		x = -1,
		y = -1
	}
	arg_1_0.kuangNodes = {}
	arg_1_0.isFirstInit = true
	arg_1_0.isClickNode_ = false
	arg_1_0.flowerPoint_ = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:initData()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:checkNeedOpenEvent()
end

function var_0_0.checkNeedOpenEvent(arg_4_0)
	local var_4_0 = arg_4_0.zhugeModel:getBaseInfo()

	if var_4_0.cur_point ~= 0 then
		local var_4_1 = arg_4_0.zhugeModel:getMapPointByIndex(var_4_0.cur_point)

		if var_4_1 and var_4_1.is_passed == 0 and var_4_1.is_searched ~= 0 and var_4_1.point == 0 and var_4_1.event_id > 0 then
			arg_4_0:playEvent(var_4_1, var_4_0.cur_point, var_4_1.x, var_4_1.y)
		end
	end
end

function var_0_0.initData(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_0.zhugeModel:getMapInfo()

	arg_5_0.mapInfos = var_5_0.map
	arg_5_0.points = var_5_0.points

	local var_5_1 = arg_5_0.zhugeModel:getBaseInfo()

	if var_5_1.cur_point ~= 0 then
		local var_5_2 = arg_5_0.zhugeModel:getMapPointByIndex(var_5_1.cur_point)

		if var_5_2 and var_5_2.point == 0 then
			if arg_5_1 and arg_5_0.curIndex and arg_5_0.curIndex.x ~= var_5_2.x or arg_5_0.curIndex.y ~= var_5_2.y then
				arg_5_0.isFirstInit = true
			end

			arg_5_0.curIndex = {
				x = var_5_2.x,
				y = var_5_2.y,
				point = var_5_2
			}
		end
	end
end

function var_0_0.layout(arg_6_0)
	arg_6_0:createMap()
	arg_6_0:setupButton()
	arg_6_0:updateBasic()
	arg_6_0:showSkill(false, false)
	arg_6_0:nodeByName("text_total_hp"):setString(var_0_4:translation("ZHUGE_ADVENTURE_TIPS_8"))
	arg_6_0:nodeByName("text_total_energy"):setString(var_0_4:translation("ZHUGE_ADVENTURE_TIPS_9"))
end

function var_0_0.updateBasic(arg_7_0)
	local var_7_0 = arg_7_0.zhugeModel:getBaseInfo()
	local var_7_1 = arg_7_0.backpack:getItemNumByID(xyd.tables.misc.zhugeRecoverEnergyItem)

	arg_7_0:nodeByName("text_box_num"):setString(string.format(var_0_4:translation("ZHUGE_ADVENTURE_TIPS_10"), var_7_1))

	local var_7_2 = math.floor(var_7_0.pass_count / var_7_0.block_num * 100)

	arg_7_0:nodeByName("text_progress"):setString(var_0_4:translation("ZHUGE_ADVENTURE_TIPS_11"))

	local var_7_3 = math.floor(100 * var_7_0.pass_count / var_7_0.block_num)

	arg_7_0:nodeByName("text_progress_num"):setString(var_7_3 .. "%")
	arg_7_0:nodeByName("energy_bar"):setPercent(math.floor(var_7_0.cur_energy / xyd.tables.misc.zhugeMaxEnergy * 100))
	arg_7_0:nodeByName("progress_bar"):setPercent(var_7_2)
	arg_7_0:nodeByName("text_energy_num"):setString(string.format(var_0_4:translation("ZHUGE_ADVENTURE_TIPS_12"), var_7_0.cur_energy, xyd.tables.misc.zhugeMaxEnergy))

	local var_7_4, var_7_5 = arg_7_0.zhugeModel:getTotalHp()

	arg_7_0:nodeByName("text_hp_num"):setString(string.format(var_0_4:translation("ZHUGE_ADVENTURE_TIPS_12"), var_7_5, var_7_4))
	arg_7_0:nodeByName("hp_bar"):setPercent(math.floor(var_7_5 / var_7_4 * 100))

	local var_7_6 = string.format(var_0_4:translation("ZHUGE_ADVENTURE_TIPS_28"), var_7_0.cur_cost)

	arg_7_0:nodeByName("text_cur_cost"):setString(var_7_6)
end

function var_0_0.updateAll(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if not arg_8_0:checkEnd() then
		arg_8_0:initData(true)
		arg_8_0:updateMap()
		arg_8_0:checkSkillIsUse(false)
		arg_8_0:showEventToast(arg_8_3)
	end
end

function var_0_0.updateMap(arg_9_0, arg_9_1)
	arg_9_0:nodeByName("left_list"):removeAllChildren()
	arg_9_0:createMap(arg_9_1)
	arg_9_0:updateBasic()
end

function var_0_0.createMap(arg_10_0, arg_10_1)
	arg_10_0.kuangNodes = {}

	local var_10_0 = 0
	local var_10_1 = 0
	local var_10_2

	for iter_10_0 = 1, var_0_6 do
		for iter_10_1 = 1, var_0_5 do
			local var_10_3 = arg_10_0:createGezi(iter_10_0, iter_10_1, arg_10_1)

			var_10_3:addTo(arg_10_0:nodeByName("left_list"))
			var_10_3:setPosition(cc.p(var_10_0, var_10_1))

			if iter_10_0 == arg_10_0.curIndex.x and iter_10_1 == arg_10_0.curIndex.y then
				var_10_2 = arg_10_0:nodeByName("left_layout"):convertToNodeSpace(var_10_3:getParent():convertToWorldSpace(cc.p(var_10_3:getPosition())))
			end

			var_10_1 = var_10_1 + var_0_7
		end

		var_10_1 = 0
		var_10_0 = var_10_0 + var_0_7
	end

	if var_10_2 and arg_10_0.isFirstInit and arg_10_0.isShowAnimation <= 0 then
		arg_10_0.isFirstInit = false

		local var_10_4, var_10_5 = arg_10_0:getPlayerAvatar()

		var_10_4:setPosition(cc.p(var_10_2.x + 25, var_10_2.y + 100))

		for iter_10_2 = 1, #arg_10_0.kuangNodes do
			arg_10_0.kuangNodes[iter_10_2]:show()
		end

		return
	end
end

function var_0_0.createGezi(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	local function var_11_0(arg_12_0, arg_12_1)
		local var_12_0 = arg_11_0.mapInfos

		if var_12_0[arg_12_0] and var_12_0[arg_12_0][arg_12_1] and arg_11_0.points[var_12_0[arg_12_0][arg_12_1]] and arg_11_0.points[var_12_0[arg_12_0][arg_12_1]].is_passed == 0 and arg_11_0.points[var_12_0[arg_12_0][arg_12_1]].point ~= 0 then
			return true
		else
			return false
		end
	end

	local var_11_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/zhugeliang/new_adventure/gezi.csb")
	local var_11_2 = var_11_1:getChildByName("container")

	for iter_11_0 = 1, 4 do
		for iter_11_1 = 1, 4 do
			var_11_2:getChildByName("gezi" .. iter_11_0 .. "_" .. iter_11_1):setVisible(false)
		end
	end

	var_11_2:getChildByName("mask"):setVisible(false)
	var_11_2:getChildByName("mask"):setScale(0.9)

	if not arg_11_0.mapInfos[arg_11_1] or not arg_11_0.mapInfos[arg_11_1][arg_11_2] or not arg_11_0.points[arg_11_0.mapInfos[arg_11_1][arg_11_2]] then
		return var_11_1
	end

	local var_11_3 = arg_11_0.points[arg_11_0.mapInfos[arg_11_1][arg_11_2]]

	if var_11_3.is_passed == 0 and var_11_3.point > 0 then
		if not var_11_0(arg_11_1 - 1, arg_11_2) and var_11_0(arg_11_1, arg_11_2 - 1) then
			var_11_2:getChildByName("gezi1_1"):setVisible(true)
		elseif not var_11_0(arg_11_1 - 1, arg_11_2) and not var_11_0(arg_11_1, arg_11_2 - 1) then
			var_11_2:getChildByName("gezi1_2"):setVisible(true)
		elseif var_11_0(arg_11_1 - 1, arg_11_2) and not var_11_0(arg_11_1, arg_11_2 - 1) then
			var_11_2:getChildByName("gezi1_4"):setVisible(true)
		elseif not var_11_0(arg_11_1 - 1, arg_11_2 - 1) then
			var_11_2:getChildByName("gezi1_3"):setVisible(true)
		end

		if not var_11_0(arg_11_1, arg_11_2 - 1) and var_11_0(arg_11_1 + 1, arg_11_2) then
			var_11_2:getChildByName("gezi2_1"):setVisible(true)
		elseif not var_11_0(arg_11_1, arg_11_2 - 1) and not var_11_0(arg_11_1 + 1, arg_11_2) then
			var_11_2:getChildByName("gezi2_2"):setVisible(true)
		elseif var_11_0(arg_11_1, arg_11_2 - 1) and not var_11_0(arg_11_1 + 1, arg_11_2) then
			var_11_2:getChildByName("gezi2_4"):setVisible(true)
		elseif not var_11_0(arg_11_1 + 1, arg_11_2 - 1) then
			var_11_2:getChildByName("gezi2_3"):setVisible(true)
		end

		if not var_11_0(arg_11_1 + 1, arg_11_2) and var_11_0(arg_11_1, arg_11_2 + 1) then
			var_11_2:getChildByName("gezi3_1"):setVisible(true)
		elseif not var_11_0(arg_11_1 + 1, arg_11_2) and not var_11_0(arg_11_1, arg_11_2 + 1) then
			var_11_2:getChildByName("gezi3_2"):setVisible(true)
		elseif var_11_0(arg_11_1 + 1, arg_11_2) and not var_11_0(arg_11_1, arg_11_2 + 1) then
			var_11_2:getChildByName("gezi3_4"):setVisible(true)
		elseif not var_11_0(arg_11_1 + 1, arg_11_2 + 1) then
			var_11_2:getChildByName("gezi3_3"):setVisible(true)
		end

		if not var_11_0(arg_11_1, arg_11_2 + 1) and var_11_0(arg_11_1 - 1, arg_11_2) then
			var_11_2:getChildByName("gezi4_1"):setVisible(true)
		elseif not var_11_0(arg_11_1, arg_11_2 + 1) and not var_11_0(arg_11_1 - 1, arg_11_2) then
			var_11_2:getChildByName("gezi4_2"):setVisible(true)
		elseif var_11_0(arg_11_1, arg_11_2 + 1) and not var_11_0(arg_11_1 - 1, arg_11_2) then
			var_11_2:getChildByName("gezi4_4"):setVisible(true)
		elseif not var_11_0(arg_11_1 - 1, arg_11_2 + 1) then
			var_11_2:getChildByName("gezi4_3"):setVisible(true)
		end
	elseif var_11_3.is_passed == 1 or var_11_3.point == 0 then
		for iter_11_2 = 1, 4 do
			var_11_2:getChildByName("gezi" .. iter_11_2 .. "_0"):setVisible(false)
		end

		local var_11_4 = var_0_3:icon(var_11_3.event_id)

		if var_11_4 and var_11_4 ~= "" then
			local var_11_5 = xyd.AssetLoader.get():loadSprite(var_11_4)

			var_11_5:setAnchorPoint(cc.p(0.5, 0.5))
			var_11_5:addTo(var_11_2, -1)
			var_11_5:setPosition(cc.p(var_0_7 / 2, var_0_7 / 2))

			local var_11_6 = var_11_5:getContentSize()

			var_11_5:setScale(0.35)
		end

		local var_11_7 = var_0_3:name(var_11_3.event_id)
		local var_11_8 = arg_11_0:createTextLabel(var_11_7, var_0_7, cc.ui.TEXT_ALIGN_CENTER, 24)

		var_11_8:addTo(var_11_2)
		var_11_8:setAnchorPoint(cc.p(0.5, 0.5))
		var_11_8:setPosition(cc.p(var_0_7 / 2, 30))

		if var_11_3.is_passed == 1 then
			var_11_2:getChildByName("mask"):setLocalZOrder(5)
			var_11_2:getChildByName("mask"):setVisible(true)
		end
	end

	if var_11_3.is_passed == 0 and var_11_3.point > 0 and var_0_3:enemyAlert(var_11_3.event_id) == 1 then
		local var_11_9 = xyd.AssetLoader.get():loadSprite("windows/zhugeliang/new_adventure/icon_3.png")

		var_11_9:addTo(var_11_1)
		var_11_9:setAnchorPoint(cc.p(0.5, 0.5))
		var_11_9:setPosition(cc.p(var_0_7 / 2 + 10, var_0_7 / 2))
	end

	arg_11_0:updateFlower(var_11_1, var_11_3, arg_11_0.mapInfos[arg_11_1][arg_11_2])

	if var_11_3.is_searched ~= 0 and var_11_3.point > 0 then
		local var_11_10 = xyd.AssetLoader.get():loadLabel(nil, "zhuge_step")

		var_11_10:setString(var_11_3.point)
		var_11_10:setScale(2)
		var_11_10:addTo(var_11_1)
		var_11_10:setAnchorPoint(cc.p(0, 0))

		local var_11_11 = var_11_10:getContentSize()

		var_11_10:setPosition(cc.p(var_0_7 - var_11_11.width * 2 - 20, 0))
	end

	local var_11_12 = false
	local var_11_13 = arg_11_0.curIndex.point

	if arg_11_0.curIndex.x == -1 and arg_11_0.curIndex.y == -1 then
		var_11_12 = true
	elseif arg_11_0.curIndex.x == arg_11_1 and arg_11_0.curIndex.y == arg_11_2 and var_11_3.point <= 0 then
		var_11_12 = false
	elseif arg_11_0:checkAddKuang(arg_11_1, arg_11_2, var_11_3, var_11_13) then
		var_11_12 = true

		local var_11_14 = "skeletons/ui_effect/zhugeliang/zhuge_05"
		local var_11_15 = cc.p(var_0_7 / 2 - 4, var_0_7 / 2)
		local var_11_16 = arg_11_0:createEffect(var_11_14, var_11_1, var_11_15, 1.2)

		var_11_16:play(nil, true)

		if arg_11_3 then
			var_11_16:setVisible(false)
		end

		table.insert(arg_11_0.kuangNodes, var_11_16)
	end

	if var_11_12 then
		var_11_1:setTouchEnabled(true)
		var_11_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
			if arg_13_0.name == "began" and not arg_11_0.isClickNode_ then
				if var_11_3.is_passed == 0 then
					arg_11_0:showTouchEffect(var_11_1)
				end
			elseif arg_13_0.name == "ended" and arg_11_0.isShowAnimation <= 0 and not arg_11_0.isClickNode_ and arg_11_0:checkCanTouch(var_11_3) then
				local function var_13_0()
					arg_11_0.isClickNode_ = true

					if not arg_11_0.isSpecialOpen_ then
						local var_14_0 = {
							index = arg_11_0.mapInfos[arg_11_1][arg_11_2]
						}

						arg_11_0.zhugeModel:startAdventure(var_14_0, function(arg_15_0, arg_15_1)
							if arg_15_0 == xyd.error.OK and arg_11_0 and not tolua.isnull(arg_11_0) then
								local var_15_0 = clone(arg_11_0.curIndex)

								arg_11_0:initData()
								arg_11_0:updateBasic()
								arg_11_0:checkSkillIsUse(true)
								arg_11_0:touchNode(arg_11_1, arg_11_2, var_15_0)
							end

							arg_11_0.isClickNode_ = false
						end)
					else
						arg_11_0:endCurDialog(arg_11_0.mapInfos[arg_11_1][arg_11_2])
					end
				end

				if arg_11_0.curIndex and arg_11_0.curIndex.x == -1 and arg_11_0.curIndex.y == -1 then
					arg_11_0:beforeClick(function()
						var_13_0()
					end)
				else
					var_13_0()
				end
			end

			return true
		end)
	end

	return var_11_1
end

function var_0_0.beforeClick(arg_17_0, arg_17_1)
	local var_17_0 = arg_17_0.zhugeModel:getBaseInfo()

	if var_17_0.free_times == 0 and var_17_0.status == 0 then
		local var_17_1 = xyd.tables.misc.zhugeForestCost
		local var_17_2 = string.format(var_0_4:translation("ZHUGE_FOREST_TIPS_4"), var_17_1)

		xyd.AlertWindow.open(xyd.AlertType.YES_NO, {
			var_17_2
		}, function(arg_18_0)
			if arg_18_0 then
				if var_17_1 > arg_17_0.selfPlayer.crystal then
					arg_17_0.isAnimation = false

					local var_18_0 = var_0_4:translation("ZHUGE_FOREST_TIPS_5")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_18_0
					})

					return
				end

				arg_17_1()
			end
		end)
	elseif var_17_0.free_times > 0 and var_17_0.status == 0 then
		local var_17_3 = var_0_4:translation("ZHUGE_FOREST_TIPS_41")

		xyd.AlertWindow.open(xyd.AlertType.YES_NO, {
			var_17_3
		}, function(arg_19_0)
			if arg_19_0 then
				arg_17_1()
			end
		end)
	else
		arg_17_1()
	end
end

function var_0_0.updateFlower(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	if not arg_20_2 or not next(arg_20_2) then
		return
	end

	local function var_20_0(arg_21_0, arg_21_1)
		local var_21_0 = xyd.AssetLoader.get():loadSprite("windows/zhugeliang/new_adventure/icon_2.png")

		var_21_0:addTo(arg_21_0)
		var_21_0:setAnchorPoint(cc.p(0.5, 0.5))
		var_21_0:setPosition(cc.p(arg_21_1))
	end

	if arg_20_2.is_passed == 0 and arg_20_2.point > 0 and var_0_3:enemyAlert(arg_20_2.event_id) == 0 then
		local var_20_1

		if arg_20_0.flowerPoint_[arg_20_3] and arg_20_0.flowerPoint_[arg_20_3].isFlower then
			local var_20_2 = cc.p(arg_20_0.flowerPoint_[arg_20_3].x, arg_20_0.flowerPoint_[arg_20_3].y)

			var_20_0(arg_20_1, var_20_2)
		elseif not arg_20_0.flowerPoint_[arg_20_3] then
			if xyd.weightedChoise({
				var_0_8,
				1 - var_0_8
			}) == 1 or arg_20_2.event_id == 5 then
				local var_20_3 = math.random(40, 100)
				local var_20_4 = math.random(40, 100)
				local var_20_5 = cc.p(var_20_3, var_20_4)

				var_20_0(arg_20_1, var_20_5)

				arg_20_0.flowerPoint_[arg_20_3] = {
					isFlower = true,
					x = var_20_3,
					y = var_20_4
				}
			else
				arg_20_0.flowerPoint_[arg_20_3] = {
					isFlower = false
				}
			end
		end
	end
end

function var_0_0.checkCanTouch(arg_22_0, arg_22_1)
	local var_22_0, var_22_1 = arg_22_0.zhugeModel:getTotalHp()

	if var_22_1 <= 0 then
		local var_22_2 = var_0_4:translation("ZHUGE_ADVENTURE_TIPS_15")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_22_2
		})

		return false
	end

	local var_22_3 = arg_22_0.zhugeModel:getBaseInfo()

	if var_22_3.cur_energy <= 0 or arg_22_1.is_searched > 0 and var_22_3.cur_energy < arg_22_1.point then
		local var_22_4 = var_0_4:translation("ZHUGE_ADVENTURE_TIPS_16")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_22_4
		})

		return false
	end

	return true
end

function var_0_0.checkAddKuang(arg_23_0, arg_23_1, arg_23_2, arg_23_3, arg_23_4)
	if (arg_23_0.curIndex.x == arg_23_1 and math.abs(arg_23_0.curIndex.y - arg_23_2) <= 1 or arg_23_0.curIndex.y == arg_23_2 and math.abs(arg_23_0.curIndex.x - arg_23_1) <= 1) and arg_23_4 and arg_23_4.is_passed == 1 then
		return true
	end

	if arg_23_0.isSpecialOpen_ and arg_23_3.is_passed == 0 then
		return true
	end

	return false
end

function var_0_0.specialOpenGezi(arg_24_0, arg_24_1)
	arg_24_0.isSpecialOpen_ = true
	arg_24_0.specialParams = arg_24_1

	arg_24_0:updateMap()
end

function var_0_0.endCurDialog(arg_25_0, arg_25_1)
	if not arg_25_0.specialParams or not next(arg_25_0.specialParams) then
		return
	end

	local var_25_0 = {}

	if arg_25_1 then
		var_25_0.open_index = arg_25_1
	end

	arg_25_0.zhugeModel:endCurDialog(arg_25_0.specialParams.eventID, arg_25_0.specialParams.dialogID, arg_25_0.specialParams.mapIndex, var_25_0, function(arg_26_0, arg_26_1)
		if arg_26_0 == xyd.error.OK and arg_25_0 and not tolua.isnull(arg_25_0) then
			arg_25_0.isSpecialOpen_ = false

			arg_25_0:updateAll(arg_25_0.specialParams.curX_, arg_25_0.specialParams.curY_)

			arg_25_0.specialParams = nil
		end

		arg_25_0.isClickNode_ = false
	end)
end

function var_0_0.touchNode(arg_27_0, arg_27_1, arg_27_2, arg_27_3)
	if not arg_27_0.mapInfos[arg_27_1] or not arg_27_0.mapInfos[arg_27_1][arg_27_2] or not arg_27_0.points[arg_27_0.mapInfos[arg_27_1][arg_27_2]] then
		return false
	end

	local var_27_0 = arg_27_0.points[arg_27_0.mapInfos[arg_27_1][arg_27_2]]

	if var_27_0.is_passed == 0 and var_27_0.point == 0 and var_27_0.event_id > 0 then
		local var_27_1 = false

		if arg_27_3.x ~= -1 and arg_27_3.y ~= -1 then
			local var_27_2 = arg_27_1 - arg_27_3.x
			local var_27_3 = arg_27_2 - arg_27_3.y

			arg_27_0:moveAvatar(var_27_2, var_27_3, function()
				arg_27_0:playEvent(var_27_0, arg_27_0.mapInfos[arg_27_1][arg_27_2], arg_27_1, arg_27_2)
			end)

			var_27_1 = true
		end

		arg_27_0.curIndex = {
			x = arg_27_1,
			y = arg_27_2,
			point = var_27_0
		}

		arg_27_0:updateMap(true)

		if not var_27_1 then
			arg_27_0:playEvent(var_27_0, arg_27_0.mapInfos[arg_27_1][arg_27_2], arg_27_1, arg_27_2)
		end

		return
	elseif var_27_0.is_passed == 1 and var_27_0.point == 0 then
		if arg_27_3.x ~= -1 and arg_27_3.y ~= -1 then
			local var_27_4 = arg_27_1 - arg_27_3.x
			local var_27_5 = arg_27_2 - arg_27_3.y

			arg_27_0:moveAvatar(var_27_4, var_27_5)

			isMove = true
		end

		arg_27_0.curIndex = {
			x = arg_27_1,
			y = arg_27_2,
			point = var_27_0
		}

		arg_27_0:updateMap(true)

		return
	else
		arg_27_0:updateMap()
	end
end

function var_0_0.setupButton(arg_29_0)
	arg_29_0:nodeByName("btn_add_energy"):addTouchEventListener(function(arg_30_0, arg_30_1)
		if arg_30_1 == ccui.TouchEventType.ended and arg_29_0.isShowAnimation <= 0 then
			local var_30_0 = arg_29_0.backpack:getItemNumByID(xyd.tables.misc.zhugeRecoverEnergyItem)
			local var_30_1 = xyd.tables.misc.zhugeRecoverEnergy
			local var_30_2 = xyd.tables.misc.zhugeRecoverEnergyCost
			local var_30_3 = ""

			if var_30_0 > 0 then
				var_30_3 = string.format(var_0_4:translation("ZHUGE_ADVENTURE_TIPS_1"), 1, var_30_1)
			else
				if var_30_2 > arg_29_0.selfPlayer.crystal then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_4:translation("ZHUGE_FOREST_TIPS_5")
					})

					return
				end

				var_30_3 = string.format(var_0_4:translation("ZHUGE_ADVENTURE_TIPS_2"), var_30_2, var_30_1)
			end

			xyd.AlertWindow.open(xyd.AlertType.YES_NO, {
				var_30_3
			}, function(arg_31_0)
				if arg_31_0 then
					arg_29_0.zhugeModel:recoverEnergy(1, 1, function(arg_32_0, arg_32_1)
						if arg_32_0 == xyd.error.OK then
							if arg_32_1.cost_type ~= xyd.Currency.CRYSTAL then
								local var_32_0 = {
									itemNum = 1,
									itemID = xyd.tables.misc.zhugeRecoverEnergyItem
								}

								arg_29_0.backpack:removeItem(var_32_0)
							end

							arg_29_0:updateBasic()
						end
					end)
				end
			end)
		end
	end)
	arg_29_0:nodeByName("btn_team_info"):addTouchEventListener(function(arg_33_0, arg_33_1)
		if arg_33_1 == ccui.TouchEventType.ended and arg_29_0.isShowAnimation <= 0 then
			local var_33_0 = {}

			xyd.WindowManager.get():openWindow("zhuge_team_info", var_33_0)
		end
	end)
	arg_29_0:nodeByName("btn_record"):addTouchEventListener(function(arg_34_0, arg_34_1)
		if arg_34_1 == ccui.TouchEventType.ended and arg_29_0.isShowAnimation <= 0 then
			arg_29_0.zhugeModel:getAdventureLog(function(arg_35_0, arg_35_1)
				if arg_35_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("zhuge_records", arg_35_1)
				end
			end)
		end
	end)
	arg_29_0:nodeByName("btn_jump"):addTouchEventListener(function(arg_36_0, arg_36_1)
		if arg_36_1 == ccui.TouchEventType.ended and arg_29_0.isShowAnimation <= 0 then
			local var_36_0 = xyd.tables.misc:getValue("activity_zhuge_skip_1")
			local var_36_1 = xyd.tables.misc:getValue("activity_zhuge_skip_2")
			local var_36_2 = string.format(var_0_4:translation("ZHUGE_FOREST_SKIP"), var_36_0, var_36_1)

			xyd.AlertWindow.open(xyd.AlertType.YES_NO, {
				var_36_2
			}, function(arg_37_0)
				if arg_37_0 then
					if arg_29_0.selfPlayer.crystal < var_36_0 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_4:translation("ZHUGE_FOREST_DIAMOND_NOT_ENOUGH")
						})
					end

					arg_29_0.zhugeModel:skipAdventure(function(arg_38_0, arg_38_1)
						if arg_38_0 == xyd.error.OK then
							arg_29_0:checkEnd(true)
						end
					end)
				end
			end)
		end
	end)
end

function var_0_0.showEventToast(arg_39_0, arg_39_1)
	if arg_39_0.curIndex and arg_39_0.curIndex.point then
		local var_39_0 = arg_39_0.curIndex.point.dialog_id
		local var_39_1 = xyd.tables.zhugeEventDialog:resultType(var_39_0)
		local var_39_2 = xyd.tables.zhugeEventDialog:resultNum(var_39_0)
		local var_39_3 = xyd.tables.zhugeEventResultType:toastText(var_39_1)
		local var_39_4 = var_0_4:translation("ZHUGE_ADVENTURE_TIPS_34")

		if var_39_1 == xyd.ZhugeNewEventType.RE_HP or var_39_1 == xyd.ZhugeNewEventType.ADD_ENERGY then
			local var_39_5 = ""

			if var_39_2 > 0 then
				var_39_5 = var_39_5 .. "+" .. var_39_2
			else
				var_39_5 = var_39_5 .. var_39_2
			end

			var_39_4 = string.format(var_39_3, var_39_5)
		elseif var_39_1 == xyd.ZhugeNewEventType.OPEN_GEZI then
			var_39_4 = var_39_3
		elseif (var_39_1 == xyd.ZhugeNewEventType.REBORN or var_39_1 == xyd.ZhugeNewEventType.KILL_ONE or var_39_1 == xyd.ZhugeNewEventType.ADD_BUFF) and arg_39_1 and arg_39_1 ~= "" then
			var_39_4 = string.format(var_39_3, arg_39_1)
		end

		if var_39_4 ~= "" and var_39_1 ~= xyd.ZhugeNewEventType.AWARD then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_39_4
			})
		end
	end
end

function var_0_0.checkSkillIsUse(arg_40_0, arg_40_1)
	local var_40_0 = arg_40_0.zhugeModel:getSkillEffect()

	if var_40_0 and var_40_0 > 0 then
		arg_40_0.zhugeModel:updateSkillEffect(0)
		arg_40_0:showSkill(true, true, arg_40_1)
	end
end

function var_0_0.getSkillHero(arg_41_0, arg_41_1)
	local var_41_0 = arg_41_0.zhugeModel:getMemberInfos()
	local var_41_1 = {}

	for iter_41_0 = 1, #var_41_0 do
		local var_41_2 = var_41_0[iter_41_0]
		local var_41_3 = xyd.tables.zhugeHero:zhugeSkill(var_41_2.init_id)

		if var_41_2.health ~= 2 and var_41_3 > 0 then
			local var_41_4 = xyd.tables.zhugeSkill:type(var_41_3)
			local var_41_5 = 0

			if arg_41_0.curIndex and arg_41_0.curIndex.point then
				local var_41_6 = arg_41_0.curIndex.point.dialog_id

				var_41_5 = xyd.tables.zhugeEventDialog:skillType(var_41_6)
			end

			if arg_41_1 and var_41_4 == xyd.ZhugeSkillType.NO_ENERGY then
				table.insert(var_41_1, var_41_2.table_id)
			elseif not arg_41_1 and var_41_4 == var_41_5 then
				table.insert(var_41_1, var_41_2.table_id)
			end
		end
	end

	local var_41_7 = 0

	if #var_41_1 > 0 then
		var_41_7 = var_41_1[math.random(1, #var_41_1)]
	end

	return var_41_7
end

function var_0_0.showSkill(arg_42_0, arg_42_1, arg_42_2, arg_42_3)
	local var_42_0 = arg_42_0:nodeByName("skill")

	if not arg_42_1 and not arg_42_2 then
		var_42_0:setVisible(false)

		return
	end

	if arg_42_1 then
		local var_42_1 = arg_42_0:getSkillHero(arg_42_3)

		if not var_42_1 or var_42_1 == 0 then
			return
		end

		local var_42_2 = xyd.tables.hero:modelID(var_42_1)
		local var_42_3 = xyd.tables.model:transparentCard(var_42_2)

		var_42_0:getChildByName("skill_role"):setTexture(var_42_3)
		var_42_0:getChildByName("skill_role"):setLocalZOrder(5)
	end

	local var_42_4 = var_42_0:getContentSize()

	var_42_0:setVisible(true)

	if arg_42_1 then
		arg_42_0.isShowAnimation = arg_42_0.isShowAnimation + 1

		var_42_0:setPosition(cc.p(xyd.STAGE_WIDTH, 0))
		transition.moveTo(var_42_0, {
			time = 0.5,
			y = 0,
			x = xyd.STAGE_WIDTH - var_42_4.width,
			onComplete = function()
				arg_42_0:playSkillAnimation()
				var_0_1.performWithDelayGlobal(function()
					if arg_42_0 and not tolua.isnull(arg_42_0) then
						arg_42_0:showSkill(false, true)
					end
				end, 2)
			end
		})
	else
		transition.moveTo(var_42_0, {
			time = 0.5,
			y = 0,
			x = xyd.STAGE_WIDTH,
			onComplete = function()
				if var_42_0 and not tolua.isnull(var_42_0) then
					var_42_0:setVisible(false)
				end

				if arg_42_0:nodeByName("skill"):getChildByName("effect_light") then
					arg_42_0:nodeByName("skill"):removeChildByName("effect_light")
				end

				if arg_42_0:nodeByName("skill"):getChildByName("effect_word") then
					arg_42_0:nodeByName("skill"):removeChildByName("effect_word")
				end

				arg_42_0.isShowAnimation = arg_42_0.isShowAnimation - 1
			end
		})
	end
end

function var_0_0.playSkillAnimation(arg_46_0)
	local var_46_0 = "skeletons/ui_effect/zhugeliang/zhuge_02"
	local var_46_1 = cc.p(-100, 360)
	local var_46_2 = arg_46_0:createEffect(var_46_0, arg_46_0:nodeByName("skill"), var_46_1)

	var_46_2:setName("effect_light")
	var_46_2:play(function()
		return
	end, true)

	local var_46_3 = "skeletons/ui_effect/zhugeliang/zhuge_03"
	local var_46_4 = cc.p(-100, 360)
	local var_46_5 = arg_46_0:createEffect(var_46_3, arg_46_0:nodeByName("skill"), var_46_4)

	var_46_5:setName("effect_word")
	var_46_5:setLocalZOrder(10)
	var_46_5:play(function()
		return
	end, false)
end

function var_0_0.getPlayerAvatar(arg_49_0)
	local var_49_0 = false

	if not arg_49_0.playerAvatar or tolua.isnull(arg_49_0.playerAvatar) then
		local var_49_1 = {
			avatar_id = arg_49_0.selfPlayer:getMyCurrentAvatarID(),
			avatar_frame_id = arg_49_0.selfPlayer.avatarFrame
		}
		local var_49_2 = display.newNode()

		var_49_2:setContentSize(80, 80)
		xyd.setPlayerAvatar(var_49_2, var_49_1)
		var_49_2:setAnchorPoint(cc.p(0.5, 0.5))
		var_49_2:addTo(arg_49_0:nodeByName("left_layout"))

		arg_49_0.playerAvatar = var_49_2
		var_49_0 = true
	end

	return arg_49_0.playerAvatar, var_49_0
end

function var_0_0.moveAvatar(arg_50_0, arg_50_1, arg_50_2, arg_50_3)
	local var_50_0, var_50_1 = arg_50_0:getPlayerAvatar()

	arg_50_0.isShowAnimation = arg_50_0.isShowAnimation + 1

	transition.moveBy(var_50_0, {
		time = 0.5,
		x = arg_50_1 * var_0_7,
		y = arg_50_2 * var_0_7,
		onComplete = function()
			arg_50_0.isShowAnimation = arg_50_0.isShowAnimation - 1

			if arg_50_0 and not tolua.isnull(arg_50_0) then
				if arg_50_0.kuangNodes and next(arg_50_0.kuangNodes) then
					for iter_51_0 = 1, #arg_50_0.kuangNodes do
						arg_50_0.kuangNodes[iter_51_0]:show()
					end
				end

				if arg_50_3 then
					arg_50_3()
				end
			end
		end
	})
end

function var_0_0.playEvent(arg_52_0, arg_52_1, arg_52_2, arg_52_3, arg_52_4)
	if arg_52_1 and arg_52_1.is_passed == 0 and arg_52_1.event_id > 0 then
		if arg_52_0.zhugeModel:checkFightFail() then
			local var_52_0 = {
				eventID = arg_52_1.event_id,
				dialogID = arg_52_1.dialog_id,
				mapIndex = arg_52_2,
				x_ = arg_52_3,
				y_ = arg_52_4,
				selectType = xyd.ZhugeTeamWndType.BATTLE_LOSE
			}

			xyd.WindowManager.get():openWindow("zhuge_team_info", var_52_0)

			return
		else
			local var_52_1 = {
				event_id = arg_52_1.event_id,
				index = arg_52_2,
				x_ = arg_52_3,
				y_ = arg_52_4
			}

			xyd.WindowManager.get():openWindow("zhuge_new_event", var_52_1)
		end
	end
end

function var_0_0.showTouchEffect(arg_53_0, arg_53_1)
	local var_53_0 = "skeletons/ui_effect/zhugeliang/zhuge_04"
	local var_53_1 = arg_53_0:nodeByName("left_layout"):convertToNodeSpace(arg_53_1:getParent():convertToWorldSpace(cc.p(arg_53_1:getPosition())))
	local var_53_2 = cc.p(var_53_1.x + var_0_7 / 2, var_53_1.y + var_0_7 / 2)
	local var_53_3 = arg_53_0:createEffect(var_53_0, arg_53_0:nodeByName("left_layout"), var_53_2, 2)

	var_53_3:play(function()
		var_53_3:hide()
	end, false)
end

function var_0_0.createEffect(arg_55_0, arg_55_1, arg_55_2, arg_55_3, arg_55_4)
	local var_55_0 = arg_55_4 or 1
	local var_55_1 = var_0_2.new(arg_55_1 .. ".json", arg_55_1 .. ".atlas", var_55_0)

	var_55_1:addTo(arg_55_2)
	var_55_1:setPosition(arg_55_3)

	return var_55_1
end

function var_0_0.checkEnd(arg_56_0, arg_56_1)
	if arg_56_0.zhugeModel:checkIsComplete() then
		arg_56_0.zhugeModel:updateMemberInfo(nil)

		if arg_56_0.zhugeModel:checkIsFirstComplete() then
			arg_56_0.activities:getActivityInfo(xyd.Activities.ZhugeFestival).details.base_info.is_passed = 1

			arg_56_0:playStory()
		else
			local var_56_0 = var_0_4:translation("ZHUGE_ADVENTURE_TIPS_27")

			if arg_56_1 then
				if not xyd.WindowManager.get():getWindow("zhuge_main_wnd") then
					xyd.WindowManager.get():openWindow("zhuge_main_wnd")
				end

				xyd.WindowManager.get():closeWindow(arg_56_0)
			else
				xyd.AlertWindow.open(xyd.AlertType.YES_NO, {
					var_56_0
				}, function(arg_57_0)
					if arg_57_0 then
						if not xyd.WindowManager.get():getWindow("zhuge_main_wnd") then
							xyd.WindowManager.get():openWindow("zhuge_main_wnd")
						end

						xyd.WindowManager.get():closeWindow(arg_56_0)
					end
				end)
			end
		end

		return true
	end

	return false
end

function var_0_0.playStory(arg_58_0)
	local var_58_0 = {
		talk_id = "zhuge02",
		callback = function()
			xyd.WindowManager.get():openWindow("zhuge_small_house")
		end
	}

	xyd.WindowManager.get():openWindow("school_story_talk", var_58_0)
	xyd.WindowManager.get():closeWindow(arg_58_0)
end

function var_0_0.createTextLabel(arg_60_0, arg_60_1, arg_60_2, arg_60_3, arg_60_4, arg_60_5)
	local var_60_0 = {
		text = arg_60_1,
		align = arg_60_3 or cc.ui.TEXT_ALIGN_LEFT,
		color = arg_60_5 or cc.c3b(255, 255, 255),
		size = arg_60_4 or 24,
		dimensions = cc.size(arg_60_2, 0)
	}

	return (xyd.AssetLoader.get():loadLabel(var_60_0))
end

return var_0_0
