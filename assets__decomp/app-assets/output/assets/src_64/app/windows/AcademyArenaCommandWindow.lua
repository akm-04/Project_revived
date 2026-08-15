local var_0_0 = class("AcademyArenaCommandWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.academyArenaMap
local var_0_4 = {
	attack = 1,
	cancel = 3,
	move = 2,
	none = 0
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.mapId = arg_1_2.mapId
	arg_1_0.closeCallback = arg_1_2.callback
	arg_1_0.status = var_0_4.none
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.ACADEMY_ARENA)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.detailContainer = arg_2_0:nodeByName("bg_detail2")
	arg_2_0.attackBtn = arg_2_0:nodeByName("btn_attack")
	arg_2_0.moveBtn = arg_2_0:nodeByName("btn_move")
	arg_2_0.cancelBtn = arg_2_0:nodeByName("btn_cancel")

	arg_2_0:nodeByName("txt_name"):enableOutline(cc.c4b(22, 82, 191, 255), 2)
	arg_2_0:nodeByName("txt_name"):setString(var_0_3:name(arg_2_0.mapId))
	arg_2_0:nodeByName("txt_dec"):setString(var_0_3:description(arg_2_0.mapId))
	arg_2_0:nodeByName("txt_tip2"):enableOutline(cc.c4b(22, 82, 191, 255), 2)
	arg_2_0:nodeByName("txt_tip2"):setString(var_0_2:translation("ACADEMY_ARENA_ACTION_TEAM_TITLE"))

	if not arg_2_0.model.areaInfo[tostring(arg_2_0.mapId)].hasV then
		arg_2_0:nodeByName("converge"):setVisible(true)
	end

	local var_2_0 = arg_2_0:nodeByName("team_container1")
	local var_2_1 = var_2_0:getContentSize()

	arg_2_0.width1 = var_2_1.width
	arg_2_0.teamList1 = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_2_0.width1, var_2_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(var_2_0):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.teamList1:setDelegate(handler(arg_2_0, arg_2_0.delegate1))
	arg_2_0:updateList(function()
		arg_2_0:initDetailContainer()
	end)
end

function var_0_0.initDetailContainer(arg_4_0)
	local var_4_0 = arg_4_0:nodeByName("team_container2")
	local var_4_1 = var_4_0:getContentSize()

	arg_4_0.width2 = var_4_1.width
	arg_4_0.teamList2 = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_4_0.width2, var_4_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(var_4_0):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.teamList2:setDelegate(handler(arg_4_0, arg_4_0.delegate2))
	arg_4_0:addStatusBtnTouch(arg_4_0.attackBtn, var_0_4.attack)
	arg_4_0:addStatusBtnTouch(arg_4_0.moveBtn, var_0_4.move)
	arg_4_0:addStatusBtnTouch(arg_4_0.cancelBtn, var_0_4.cancel)
	arg_4_0:addStatusBtnTouch(arg_4_0:nodeByName("close_team"), var_0_4.none)
	arg_4_0:nodeByName("btn_confirm"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			if not arg_4_0.chooseList or not next(arg_4_0.chooseList) then
				return
			end

			if arg_4_0.status == var_0_4.cancel then
				arg_4_0.model:cancelTeam(arg_4_0.chooseList, function()
					arg_4_0:updateList(function()
						local var_7_0 = xyd.WindowManager.get():getWindow("academy_arena")

						if var_7_0 then
							var_7_0:updateBottom()
							var_7_0:updateArrow()
						end
					end)
				end)

				return
			end

			local var_5_0 = xyd.WindowManager.get():getWindow("academy_arena")

			if var_5_0 then
				var_5_0:setAct(arg_4_0.status, arg_4_0.mapId, arg_4_0.chooseList)
				arg_4_0:setVisible(false)
			end
		end
	end)
end

function var_0_0.addStatusBtnTouch(arg_8_0, arg_8_1, arg_8_2)
	arg_8_1:addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			if arg_8_2 ~= var_0_4.none and arg_8_0.model.phase == 2 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("ACADEMY_ARENA_PHASE_TIP")
				})

				return
			end

			arg_8_0:changeStatus(arg_8_2)
		end
	end)
end

function var_0_0.changeStatus(arg_10_0, arg_10_1)
	arg_10_0.status = arg_10_1

	if arg_10_1 == var_0_4.attack then
		arg_10_0:initActList(2)
		arg_10_0.attackBtn:setBrightStyle(ccui.BrightStyle.highlight)
	else
		arg_10_0.attackBtn:setBrightStyle(ccui.BrightStyle.normal)
	end

	if arg_10_1 == var_0_4.move then
		arg_10_0:initActList(2)
		arg_10_0.moveBtn:setBrightStyle(ccui.BrightStyle.highlight)
	else
		arg_10_0.moveBtn:setBrightStyle(ccui.BrightStyle.normal)
	end

	if arg_10_1 == var_0_4.cancel then
		arg_10_0:initActList(1)
		arg_10_0.cancelBtn:setBrightStyle(ccui.BrightStyle.highlight)
	else
		arg_10_0.cancelBtn:setBrightStyle(ccui.BrightStyle.normal)
	end

	if arg_10_1 == var_0_4.none then
		arg_10_0.detailContainer:setVisible(false)
	else
		arg_10_0:nodeByName("txt_team_num2"):setString(string.format(var_0_2:translation("ACADEMY_ARENA_ACTION_TEAM_NUM"), #arg_10_0.actList, #arg_10_0.teamList))
		arg_10_0.teamList2:reload()
		arg_10_0.detailContainer:setVisible(true)
	end
end

function var_0_0.updateList(arg_11_0, arg_11_1)
	arg_11_0:changeStatus(var_0_4.none)
	arg_11_0.model:loadTeam(arg_11_0.mapId, function(arg_12_0)
		arg_11_0.teamList = arg_12_0

		for iter_12_0, iter_12_1 in ipairs(arg_11_0.teamList) do
			local var_12_0 = arg_11_0.model:getCommandInfo(iter_12_1.team_id)

			if var_12_0 then
				if arg_11_0.model:isOwned(var_12_0) then
					iter_12_1.status = 2
				else
					iter_12_1.status = 1
				end
			end
		end

		arg_11_0:nodeByName("txt_team_num"):setString(string.format(var_0_2:translation("ACADEMY_ARENA_GARRISON_TEAM_NUM"), #arg_11_0.teamList, var_0_3:ceiling(arg_11_0.mapId)))
		arg_11_0.teamList1:reload()

		if arg_11_1 then
			arg_11_1()
		end
	end)
end

function var_0_0.initActList(arg_13_0, arg_13_1)
	arg_13_0.actList = {}

	for iter_13_0, iter_13_1 in ipairs(arg_13_0.teamList) do
		if arg_13_1 == 1 then
			if iter_13_1.status then
				table.insert(arg_13_0.actList, iter_13_1)
			end
		elseif arg_13_1 == 2 and not iter_13_1.status then
			table.insert(arg_13_0.actList, iter_13_1)
		end
	end

	arg_13_0.chooseList = {}
end

function var_0_0.scrollListener(arg_14_0, arg_14_1)
	if arg_14_1.name == "began" then
		arg_14_0.scrollViewMoved_ = false
		arg_14_0.prevX_ = arg_14_1.x
	elseif arg_14_1.name == "moved" and 20 <= math.abs(arg_14_1.x - arg_14_0.prevX_) then
		arg_14_0.scrollViewMoved_ = true
	end
end

function var_0_0.delegate1(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	if cc.ui.UIListView.COUNT_TAG == arg_15_2 then
		return #arg_15_0.teamList
	elseif cc.ui.UIListView.CELL_TAG == arg_15_2 then
		local var_15_0 = arg_15_0.teamList1:dequeueItem()

		if not var_15_0 then
			var_15_0 = arg_15_0.teamList1:newItem()
		else
			var_15_0:removeAllChildren(true)
		end

		local var_15_1 = 60
		local var_15_2 = arg_15_0:createTeamItem1(arg_15_0.teamList[arg_15_3], var_15_1)

		var_15_0:setItemSize(arg_15_0.width1, var_15_1)
		var_15_0:addContent(var_15_2)

		return var_15_0
	end
end

function var_0_0.createTeamItem1(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/academy_arena/command/team_item1.csb")

	var_16_0:setContentSize(arg_16_0.width1, arg_16_2)

	for iter_16_0, iter_16_1 in ipairs(arg_16_1.table_ids) do
		local var_16_1 = arg_16_0.model.recruitHeros[tostring(iter_16_1)]
		local var_16_2 = var_16_0:getChildByName("hp" .. iter_16_0)

		var_16_2:setVisible(true)

		if var_16_1.health > 0 then
			var_16_2:getChildByName("hp_bar"):setPercent(math.max(var_16_1.hp, 1) / var_16_1.total_hp * 100)
		end

		xyd.setAvatarBorder(arg_16_0:newHero(iter_16_1), var_16_0:getChildByName("hero" .. iter_16_0))
	end

	local var_16_3 = var_16_0:getChildByName("icon_status")

	if not arg_16_1.status then
		var_16_3:loadTexture("windows/academy_arena/command/icon_free.png")
	elseif arg_16_1.status == 1 then
		var_16_3:loadTexture("windows/academy_arena/command/icon_attack.png")
	else
		var_16_3:loadTexture("windows/academy_arena/command/icon_move.png")
	end

	return var_16_0
end

function var_0_0.delegate2(arg_17_0, arg_17_1, arg_17_2, arg_17_3)
	if cc.ui.UIListView.COUNT_TAG == arg_17_2 then
		return #arg_17_0.actList
	elseif cc.ui.UIListView.CELL_TAG == arg_17_2 then
		local var_17_0 = arg_17_0.teamList2:dequeueItem()

		if not var_17_0 then
			var_17_0 = arg_17_0.teamList2:newItem()
		else
			var_17_0:removeAllChildren(true)
		end

		local var_17_1 = 60
		local var_17_2 = arg_17_0:createTeamItem2(arg_17_0.actList[arg_17_3], var_17_1)

		var_17_0:setItemSize(arg_17_0.width2, var_17_1)
		var_17_0:addContent(var_17_2)

		return var_17_0
	end
end

function var_0_0.createTeamItem2(arg_18_0, arg_18_1, arg_18_2)
	local var_18_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/academy_arena/command/team_item2.csb")

	var_18_0:setContentSize(arg_18_0.width2, arg_18_2)

	for iter_18_0, iter_18_1 in ipairs(arg_18_1.table_ids) do
		local var_18_1 = arg_18_0.model.recruitHeros[tostring(iter_18_1)]
		local var_18_2 = var_18_0:getChildByName("hp" .. iter_18_0)

		var_18_2:setVisible(true)

		if var_18_1.health > 0 then
			var_18_2:getChildByName("hp_bar"):setPercent(math.max(var_18_1.hp, 1) / var_18_1.total_hp * 100)
		end

		xyd.setAvatarBorder(arg_18_0:newHero(iter_18_1), var_18_0:getChildByName("hero" .. iter_18_0))
	end

	local var_18_3 = var_18_0:getChildByName("icon_status")

	if not arg_18_1.status then
		var_18_3:loadTexture("windows/academy_arena/command/icon_free.png")
	elseif arg_18_1.status == 1 then
		var_18_3:loadTexture("windows/academy_arena/command/icon_attack.png")
	else
		var_18_3:loadTexture("windows/academy_arena/command/icon_move.png")
	end

	local var_18_4 = var_18_0:getChildByName("check")
	local var_18_5 = var_18_4:getChildByName("icon_check")
	local var_18_6 = false

	var_18_5:setVisible(false)
	var_18_4:setTouchEnabled(true)
	var_18_4:setTouchSwallowEnabled(false)
	var_18_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_19_0)
		if arg_19_0.name == "began" then
			return true
		elseif arg_19_0.name == "ended" and not arg_18_0.scrollViewMoved_ then
			if var_18_6 then
				for iter_19_0, iter_19_1 in ipairs(arg_18_0.chooseList) do
					if iter_19_1 == arg_18_1.team_id then
						table.remove(arg_18_0.chooseList, iter_19_0)

						break
					end
				end

				var_18_6 = false

				var_18_5:setVisible(false)
			else
				table.insert(arg_18_0.chooseList, arg_18_1.team_id)

				var_18_6 = true

				var_18_5:setVisible(true)
			end
		end
	end)

	return var_18_0
end

function var_0_0.newHero(arg_20_0, arg_20_1)
	local var_20_0 = var_0_1.new()

	var_20_0:initUnCollected(arg_20_1)

	local var_20_1 = arg_20_0.selfPlayer:getHeroIgnoreAwaken(arg_20_1)

	if var_20_1 then
		var_20_0.star_ = var_20_1.star_
		var_20_0.awakeTwiceStage_ = var_20_1.awakeTwiceStage_
	end

	xyd.formatAcademyArenaHero(var_20_0)

	return var_20_0
end

function var_0_0.didOpen(arg_21_0, arg_21_1)
	arg_21_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.didClose(arg_22_0, arg_22_1)
	if arg_22_0.closeCallback then
		arg_22_0.closeCallback()
	end
end

return var_0_0
