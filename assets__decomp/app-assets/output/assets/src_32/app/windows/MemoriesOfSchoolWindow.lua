local var_0_0 = class("MemoriesOfSchoolWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("framework.scheduler")
local var_0_4 = import("app.common.ui.SpineEffect")
local var_0_5 = import("app.common.ui.SpriteNodeButton")
local var_0_6 = xyd.tables.item
local var_0_7 = xyd.tables.hero
local var_0_8
local var_0_9
local var_0_10 = 102
local var_0_11 = 9
local var_0_12 = 6
local var_0_13 = 2
local var_0_14 = 0.6
local var_0_15 = "windows/memories_of_school/map_detail/photo"
local var_0_16 = "windows/memories_of_school/map_detail/map_unit.png"
local var_0_17 = "windows/memories_of_school/map_detail/start_point.png"
local var_0_18 = "windows/memories_of_school/map_detail/start_point_open.png"
local var_0_19 = "windows/memories_of_school/map_detail/final_point.png"
local var_0_20 = "windows/memories_of_school/map_detail/final_point_open.png"
local var_0_21 = "windows/memories_of_school/map_detail/wall.png"
local var_0_22 = "windows/memories_of_school/map_detail/book_small.png"
local var_0_23 = "windows/memories_of_school/map_detail/book_big.png"
local var_0_24 = "windows/memories_of_school/map_detail/book_small_open.png"
local var_0_25 = "windows/memories_of_school/map_detail/book_big_open.png"
local var_0_26 = "windows/memories_of_school/map_mask/"
local var_0_27 = "xiangshang"
local var_0_28 = "xianghou"
local var_0_29 = "xiangzuo"
local var_0_30 = "xiangyou"
local var_0_31 = 50001401
local var_0_32 = 50001400
local var_0_33 = "skeletons/ui_effect/memories_of_school/card-break"
local var_0_34 = "skeletons/ui_effect/memories_of_school/girl-ring"
local var_0_35 = "skeletons/ui_effect/memories_of_school/maze_key_small"
local var_0_36 = "skeletons/ui_effect/memories_of_school/maze_key_big"
local var_0_37 = "skeletons/ui_effect/memories_of_school/maze_book_small"
local var_0_38 = "skeletons/ui_effect/memories_of_school/book_red"
local var_0_39 = "skeletons/ui_effect/memories_of_school/door-close-big"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.map = {}
	arg_1_0.mazeFog = {}
	arg_1_0.mapNodes = {}
	arg_1_0.monsterModels = {}
	arg_1_0.currentPointX = 1
	arg_1_0.currentPointY = 1
	arg_1_0.faceTo = 1
	arg_1_0.eventPointX = 0
	arg_1_0.eventPointY = 0
	var_0_8 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	var_0_9 = xyd.ModelManager.get():loadModel(xyd.ModelType.MEMORIES_OF_SCHOOL)

	if arg_1_2 and arg_1_2.response then
		arg_1_0.response = arg_1_2.response
	end
end

function var_0_0.convertPositionToNum(arg_2_0, arg_2_1)
	local var_2_0

	return (arg_2_1.y - 1) * var_0_11 + arg_2_1.x
end

function var_0_0.convertNumToPosition(arg_3_0, arg_3_1)
	return {
		x = (arg_3_1 - 1) % var_0_11 + 1,
		y = math.floor((arg_3_1 - 1) / var_0_11) + 1
	}
end

function var_0_0.convertMapToArray(arg_4_0, arg_4_1)
	local var_4_0 = {}

	for iter_4_0 = 1, var_0_12 do
		for iter_4_1 = 1, var_0_11 do
			var_4_0[(iter_4_0 - 1) * var_0_11 + iter_4_1] = arg_4_1[iter_4_0][iter_4_1]
		end
	end

	return var_4_0
end

function var_0_0.willClose(arg_5_0, arg_5_1)
	var_0_0.super:willClose(arg_5_0, arg_5_1)
end

function var_0_0.KV2Array(arg_6_0, arg_6_1)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in pairs(arg_6_1) do
		var_6_0[tonumber(iter_6_0)] = iter_6_1
	end

	return var_6_0
end

function var_0_0.willOpen(arg_7_0, arg_7_1)
	var_0_0.super:willOpen(arg_7_0, arg_7_1)

	local var_7_0 = arg_7_0.response

	arg_7_0:initMap(var_7_0.maze_info.maze_map, arg_7_0:KV2Array(var_7_0.maze_info.map_open))

	arg_7_0.hero_id = var_7_0.base_info.hero_id

	local var_7_1 = arg_7_0:convertNumToPosition(var_7_0.base_info.now_pos)
	local var_7_2 = arg_7_0:convertNumToPosition(var_7_0.base_info.end_pos)

	arg_7_0.map[var_7_2.y][var_7_2.x] = xyd.MazeType.FINAL_POINT
	arg_7_0.currentPointX = var_7_1.x
	arg_7_0.currentPointY = var_7_1.y

	local var_7_3 = {
		ecoCount = 1,
		show_rule = true,
		ecoBarType = xyd.EcoSidebarType.DISPLAY,
		ecoTypes = {
			3
		},
		ecoIcons = {
			"images/icon/eco/icon_energy.png"
		},
		ecoIsAdd = {
			true
		},
		callback = function()
			var_0_9:updateMapInfo({
				map = arg_7_0:convertMapToArray(arg_7_0.mazeFog),
				pos = arg_7_0:convertPositionToNum({
					x = arg_7_0.currentPointX,
					y = arg_7_0.currentPointY
				})
			})

			local var_8_0 = xyd.tables.sound:getSound("ui_close_window")

			if xyd.WindowManager.get():getWindow("memories_of_school_main") then
				xyd.WindowManager.get():getWindow("memories_of_school_main"):updateWindow(var_0_9:getLocalParams())
			end

			xyd.WindowManager.get():closeWindow(arg_7_0)
		end
	}

	arg_7_0:addTopSidebar(var_7_3)
	arg_7_0:nodeByName("top_sidebar"):setLocalZOrder(1)

	arg_7_0.rule_btn = arg_7_0:nodeByName("top_sidebar"):nodeByName("rule")

	xyd.addTouchEvent(arg_7_0.rule_btn, function()
		local var_9_0 = {}

		var_9_0.title_name = "MAZE_RULE_TITLE"
		var_9_0.rule = "MAZE_RULE_TEXT"
		var_9_0.style = xyd.RuleStyle.BLUE

		xyd.WindowManager.get():openWindow("new_text_rule", var_9_0)
	end)
	arg_7_0:nodeByName("eco_sidebar"):nodeByName("txt_eco_val_1"):setString(var_0_8.energy .. "/" .. var_0_8:getEnergyLimit())
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_7_0):addEventListener(xyd.event.ECONOMY_AFTER, handler(arg_7_0, arg_7_0.updateEnergy))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_7_0):addEventListener(xyd.event.TICK_UPDATE, handler(arg_7_0, arg_7_0.updateEnergy))
	arg_7_0:layout()

	arg_7_0.model = arg_7_0:createHeroModel()

	arg_7_0.model:addTo(arg_7_0:nodeByName("map_container"))
	arg_7_0.model:setPosition((arg_7_0.currentPointX - 0.5) * var_0_10, (arg_7_0.currentPointY - 0.8) * var_0_10)

	arg_7_0.response = nil
end

function var_0_0.didOpen(arg_10_0, arg_10_1)
	var_0_0.super:didOpen(arg_10_0, arg_10_1)
end

function var_0_0.updateEnergy(arg_11_0)
	local var_11_0 = arg_11_0:nodeByName("eco_sidebar"):nodeByName("txt_eco_val_1"):getString()
	local var_11_1 = var_0_8:getEnergy() .. "/" .. var_0_8:getEnergyLimit()

	if var_11_0 == var_11_1 then
		return
	end

	arg_11_0:nodeByName("eco_sidebar"):nodeByName("txt_eco_val_1"):setString(var_11_1)

	local var_11_2 = transition.sequence({
		cc.ScaleTo:create(0.3, 1.5),
		cc.ScaleTo:create(0.3, 1)
	})
	local var_11_3 = cc.Spawn:create(var_11_2)

	arg_11_0:nodeByName("eco_sidebar"):nodeByName("txt_eco_val_1"):runAction(var_11_3)
end

function var_0_0.clearMapInfo(arg_12_0)
	arg_12_0.map = {}
	arg_12_0.mazeInfo = {}
	arg_12_0.mapNodes = {}

	arg_12_0:nodeByName("map_container"):removeAllChildren()
end

function var_0_0.initMap(arg_13_0, arg_13_1, arg_13_2)
	for iter_13_0 = 1, #arg_13_1 do
		local var_13_0 = (iter_13_0 - 1) % var_0_11 + 1
		local var_13_1 = math.floor((iter_13_0 - 1) / var_0_11) + 1

		if not arg_13_0.map[var_13_1] then
			arg_13_0.map[var_13_1] = {}
		end

		if not arg_13_0.mazeFog[var_13_1] then
			arg_13_0.mazeFog[var_13_1] = {}
		end

		arg_13_0.map[var_13_1][var_13_0] = arg_13_1[iter_13_0]
		arg_13_0.mazeFog[var_13_1][var_13_0] = arg_13_2[iter_13_0]

		if not arg_13_0.monsterModels[var_13_1] then
			arg_13_0.monsterModels[var_13_1] = {}
		end
	end
end

function var_0_0.moveModel(arg_14_0, arg_14_1, arg_14_2)
	if not arg_14_0.model or tolua.isnull(arg_14_0.model) then
		return
	end

	transition.stopTarget(arg_14_0.model)

	local var_14_0 = {}

	for iter_14_0, iter_14_1 in ipairs(arg_14_2) do
		if iter_14_0 == 1 then
			if iter_14_1.x - arg_14_1.x == -1 then
				arg_14_0.faceTo = -1
			elseif iter_14_1.x - arg_14_1.x == 1 then
				arg_14_0.faceTo = 1
			end
		elseif iter_14_1.x - arg_14_2[iter_14_0 - 1].x == -1 then
			arg_14_0.faceTo = -1
		elseif iter_14_1.x - arg_14_2[iter_14_0 - 1].x == 1 then
			arg_14_0.faceTo = 1
		end

		moveAction = cc.MoveTo:create(0.5, cc.p((iter_14_1.x - 0.5) * var_0_10, (iter_14_1.y - 0.8) * var_0_10))
		scaleAction = cc.ScaleTo:create(0.05, arg_14_0.heroScale * arg_14_0.faceTo, arg_14_0.heroScale)
		spawn = cc.Spawn:create({
			moveAction,
			scaleAction
		})
		var_14_0[iter_14_0] = cc.Sequence:create(spawn, cc.CallFunc:create(function()
			arg_14_0.currentPointX = iter_14_1.x
			arg_14_0.currentPointY = iter_14_1.y

			arg_14_0:refreshMap()
		end))
	end

	local var_14_1 = transition.sequence(var_14_0)

	arg_14_0.isAnimating = true

	arg_14_0.model:walk(true)
	arg_14_0.model:runActionOnce(var_14_1, false, function()
		arg_14_0.isAnimating = false

		arg_14_0.model:idle()
		arg_14_0:gridEvent({
			x = arg_14_0.eventPointX,
			y = arg_14_0.eventPointY
		})

		if arg_14_0.tempAwards then
			var_0_8:handleRewards(arg_14_0.tempAwards)

			arg_14_0.tempAwards = nil
		end
	end)
end

function var_0_0.refreshMap(arg_17_0)
	local var_17_0 = os.clock()

	arg_17_0:clearFog()

	for iter_17_0 = 1, var_0_12 do
		for iter_17_1 = 1, var_0_11 do
			local var_17_1
			local var_17_2
			local var_17_3

			if arg_17_0.mapNodes[iter_17_0][iter_17_1].nodeInfo ~= arg_17_0.map[iter_17_0][iter_17_1] or arg_17_0.mapNodes[iter_17_0][iter_17_1].mazeInfo ~= arg_17_0.mazeFog[iter_17_0][iter_17_1] then
				arg_17_0.mapNodes[iter_17_0][iter_17_1].nodeInfo = arg_17_0.map[iter_17_0][iter_17_1]
				arg_17_0.mapNodes[iter_17_0][iter_17_1].mazeInfo = arg_17_0.mazeFog[iter_17_0][iter_17_1]

				arg_17_0.mapNodes[iter_17_0][iter_17_1]:removeAllChildren(true)

				if arg_17_0.mazeFog[iter_17_0][iter_17_1] == 0 then
					var_17_1 = cc.Sprite:create(var_0_26 .. var_0_9.baseInfo.hero_id .. ".png", cc.rect((iter_17_1 - 1) * var_0_10, (var_0_12 - iter_17_0) * var_0_10, var_0_10, var_0_10))

					var_17_1:setAnchorPoint(cc.p(0, 0))
					var_17_1:setName("fog")

					var_17_2 = cc.Sprite:create(var_0_16)

					var_17_2:setAnchorPoint(cc.p(0, 0))
				else
					var_17_1 = cc.Sprite:create(var_0_15 .. var_0_9.baseInfo.now_floor .. ".png", cc.rect((iter_17_1 - 1) * var_0_10, (var_0_12 - iter_17_0) * var_0_10, var_0_10, var_0_10))

					var_17_1:setAnchorPoint(cc.p(0, 0))

					var_17_2 = cc.Sprite:create(var_0_16)

					var_17_2:setAnchorPoint(cc.p(0, 0))

					if arg_17_0.map[iter_17_0][iter_17_1] == xyd.MazeType.WALL then
						var_17_3 = cc.Sprite:create(var_0_21)

						var_17_3:setAnchorPoint(cc.p(0, 0))
					elseif arg_17_0.map[iter_17_0][iter_17_1] == xyd.MazeType.BOSS then
						if tolua.isnull(arg_17_0.monsterModels[iter_17_0][iter_17_1]) then
							local var_17_4 = xyd.tables.mazeCampaign:tableID(tonumber(var_0_9.enemyInfos[tostring(arg_17_0:convertPositionToNum({
								x = iter_17_1,
								y = iter_17_0
							}))]))
							local var_17_5 = xyd.tables.mazeCampaign:modelID(tonumber(var_0_9.enemyInfos[tostring(arg_17_0:convertPositionToNum({
								x = iter_17_1,
								y = iter_17_0
							}))]))

							arg_17_0.monsterModels[iter_17_0][iter_17_1] = xyd.HeroAnimation.new(nil, tonumber(var_17_5), xyd.tables.model:scale(tonumber(var_17_5)) * 0.7, {
								loadAttackEffect = true
							})

							arg_17_0.monsterModels[iter_17_0][iter_17_1]:setContentSize(1, 1)
							arg_17_0.monsterModels[iter_17_0][iter_17_1]:addTo(arg_17_0:nodeByName("map_container"))
							arg_17_0.monsterModels[iter_17_0][iter_17_1]:setPosition((iter_17_1 - 0.5) * var_0_10, (iter_17_0 - 0.8) * var_0_10)
							arg_17_0.monsterModels[iter_17_0][iter_17_1]:idle()
							arg_17_0.monsterModels[iter_17_0][iter_17_1]:setFlipX(true)
						end
					elseif arg_17_0.map[iter_17_0][iter_17_1] == xyd.MazeType.MONSTER then
						if tolua.isnull(arg_17_0.monsterModels[iter_17_0][iter_17_1]) then
							local var_17_6 = xyd.tables.mazePartnerCampaign:monsterDisplay(tonumber(var_0_9.enemyInfos[tostring(arg_17_0:convertPositionToNum({
								x = iter_17_1,
								y = iter_17_0
							}))]))
							local var_17_7 = var_0_2.new()

							var_17_7:populateWithTableID(var_17_6)

							local var_17_8 = var_17_7:getModelID()

							arg_17_0.monsterModels[iter_17_0][iter_17_1] = xyd.HeroAnimation.new(nil, var_17_8, xyd.tables.model:scale(var_17_8) * 0.7, {
								loadAttackEffect = true
							})

							arg_17_0.monsterModels[iter_17_0][iter_17_1]:setContentSize(1, 1)
							arg_17_0.monsterModels[iter_17_0][iter_17_1]:addTo(arg_17_0:nodeByName("map_container"))
							arg_17_0.monsterModels[iter_17_0][iter_17_1]:setPosition((iter_17_1 - 0.5) * var_0_10, (iter_17_0 - 0.8) * var_0_10)
							arg_17_0.monsterModels[iter_17_0][iter_17_1]:idle()
							arg_17_0.monsterModels[iter_17_0][iter_17_1]:setFlipX(true)
						end
					elseif arg_17_0.map[iter_17_0][iter_17_1] == xyd.MazeType.PLAYER then
						if tolua.isnull(arg_17_0.monsterModels[iter_17_0][iter_17_1]) then
							local var_17_9 = xyd.tables.mazeFloor:tableID(tonumber(var_0_9.baseInfo.now_floor))
							local var_17_10 = xyd.tables.mazeFloor:arenaPlayerModel(tonumber(var_0_9.baseInfo.now_floor))

							arg_17_0.monsterModels[iter_17_0][iter_17_1] = xyd.HeroAnimation.new(nil, var_17_10, xyd.tables.model:scale(var_17_10) * 0.7, {
								loadAttackEffect = true
							})

							arg_17_0.monsterModels[iter_17_0][iter_17_1]:setContentSize(1, 1)
							arg_17_0.monsterModels[iter_17_0][iter_17_1]:addTo(arg_17_0:nodeByName("map_container"))
							arg_17_0.monsterModels[iter_17_0][iter_17_1]:setPosition((iter_17_1 - 0.5) * var_0_10, (iter_17_0 - 0.8) * var_0_10)
							arg_17_0.monsterModels[iter_17_0][iter_17_1]:idle()
							arg_17_0.monsterModels[iter_17_0][iter_17_1]:setFlipX(true)
						end
					elseif arg_17_0.map[iter_17_0][iter_17_1] == xyd.MazeType.BIG_BOX then
						var_17_3 = cc.Sprite:create(var_0_23)

						var_17_3:setAnchorPoint(cc.p(0, 0))

						local var_17_11 = var_0_38 .. ".json"
						local var_17_12 = var_0_38 .. ".atlas"
						local var_17_13
						local var_17_14 = var_0_4.new(var_17_11, var_17_12, 1)

						var_17_14:setAnchorPoint(cc.p(0.5, 0.5))
						var_17_14:addTo(var_17_3)
						var_17_14:setPosition(var_0_10 / 2, var_0_10 / 2)
						var_17_14:setScale(0.5)
						var_17_14:play(nil, true)
					elseif arg_17_0.map[iter_17_0][iter_17_1] == xyd.MazeType.SMALL_BOX then
						var_17_3 = cc.Sprite:create(var_0_22)

						var_17_3:setAnchorPoint(cc.p(0, 0))

						local var_17_15 = var_0_37 .. ".json"
						local var_17_16 = var_0_37 .. ".atlas"
						local var_17_17
						local var_17_18 = var_0_4.new(var_17_15, var_17_16, 1)

						var_17_18:setAnchorPoint(cc.p(0.5, 0.5))
						var_17_18:addTo(var_17_3)
						var_17_18:setPosition(var_0_10 / 2, var_0_10 / 2)
						var_17_18:play(nil, true)
					elseif arg_17_0.map[iter_17_0][iter_17_1] == xyd.MazeType.BIG_BOX_OPEN then
						var_17_3 = cc.Sprite:create(var_0_25)

						var_17_3:setAnchorPoint(cc.p(0, 0))
					elseif arg_17_0.map[iter_17_0][iter_17_1] == xyd.MazeType.SMALL_BOX_OPEN then
						var_17_3 = cc.Sprite:create(var_0_24)

						var_17_3:setAnchorPoint(cc.p(0, 0))
					elseif arg_17_0:convertNumToPosition(var_0_9.baseInfo.start_pos).y == iter_17_0 and arg_17_0:convertNumToPosition(var_0_9.baseInfo.start_pos).x == iter_17_1 and var_0_9.baseInfo.now_floor == 1 then
						var_17_3 = cc.Sprite:create(var_0_17)

						var_17_3:setAnchorPoint(cc.p(0, 0))
					elseif arg_17_0:convertNumToPosition(var_0_9.baseInfo.end_pos).y == iter_17_0 and arg_17_0:convertNumToPosition(var_0_9.baseInfo.end_pos).x == iter_17_1 then
						var_17_3 = cc.Sprite:create(var_0_19)

						var_17_3:setAnchorPoint(cc.p(0, 0))

						local var_17_19 = var_0_39 .. ".json"
						local var_17_20 = var_0_39 .. ".atlas"
						local var_17_21
						local var_17_22 = var_0_4.new(var_17_19, var_17_20, 1)

						var_17_22:setAnchorPoint(cc.p(0.5, 0.5))
						var_17_22:addTo(var_17_3)
						var_17_22:setPosition(var_0_10 / 2 - 2, var_0_10 / 2 - 8)
						var_17_22:play(nil, true)
					elseif not tolua.isnull(arg_17_0.monsterModels[iter_17_0][iter_17_1]) then
						arg_17_0.monsterModels[iter_17_0][iter_17_1] = nil
					end
				end

				if var_17_1 then
					arg_17_0.mapNodes[iter_17_0][iter_17_1]:addChild(var_17_1)
				end

				if var_17_2 then
					arg_17_0.mapNodes[iter_17_0][iter_17_1]:addChild(var_17_2)
				end

				if var_17_3 then
					arg_17_0.mapNodes[iter_17_0][iter_17_1]:addChild(var_17_3)
				end
			end
		end
	end

	arg_17_0:updateLeftContainer()
end

function var_0_0.clearFog(arg_18_0)
	if arg_18_0.mazeFog[arg_18_0.currentPointY] and arg_18_0.mazeFog[arg_18_0.currentPointY][arg_18_0.currentPointX] and arg_18_0.mazeFog[arg_18_0.currentPointY][arg_18_0.currentPointX] == 0 then
		arg_18_0.mazeFog[arg_18_0.currentPointY][arg_18_0.currentPointX] = 1
	end

	if arg_18_0.mazeFog[arg_18_0.currentPointY] and arg_18_0.mazeFog[arg_18_0.currentPointY][arg_18_0.currentPointX + 1] and arg_18_0.mazeFog[arg_18_0.currentPointY][arg_18_0.currentPointX + 1] == 0 then
		arg_18_0.mazeFog[arg_18_0.currentPointY][arg_18_0.currentPointX + 1] = 1

		arg_18_0:runFogEffect({
			x = arg_18_0.currentPointX + 1,
			y = arg_18_0.currentPointY
		}, var_0_30)
	end

	if arg_18_0.mazeFog[arg_18_0.currentPointY] and arg_18_0.mazeFog[arg_18_0.currentPointY][arg_18_0.currentPointX - 1] and arg_18_0.mazeFog[arg_18_0.currentPointY][arg_18_0.currentPointX - 1] == 0 then
		arg_18_0.mazeFog[arg_18_0.currentPointY][arg_18_0.currentPointX - 1] = 1

		arg_18_0:runFogEffect({
			x = arg_18_0.currentPointX - 1,
			y = arg_18_0.currentPointY
		}, var_0_29)
	end

	if arg_18_0.mazeFog[arg_18_0.currentPointY + 1] and arg_18_0.mazeFog[arg_18_0.currentPointY][arg_18_0.currentPointX] and arg_18_0.mazeFog[arg_18_0.currentPointY + 1][arg_18_0.currentPointX] == 0 then
		arg_18_0.mazeFog[arg_18_0.currentPointY + 1][arg_18_0.currentPointX] = 1

		arg_18_0:runFogEffect({
			x = arg_18_0.currentPointX,
			y = arg_18_0.currentPointY + 1
		}, var_0_27)
	end

	if arg_18_0.mazeFog[arg_18_0.currentPointY - 1] and arg_18_0.mazeFog[arg_18_0.currentPointY][arg_18_0.currentPointX] and arg_18_0.mazeFog[arg_18_0.currentPointY - 1][arg_18_0.currentPointX] == 0 then
		arg_18_0.mazeFog[arg_18_0.currentPointY - 1][arg_18_0.currentPointX] = 1

		arg_18_0:runFogEffect({
			x = arg_18_0.currentPointX,
			y = arg_18_0.currentPointY - 1
		}, var_0_28)
	end
end

function var_0_0.runFogEffect(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = var_0_33 .. ".json"
	local var_19_1 = var_0_33 .. ".atlas"
	local var_19_2
	local var_19_3 = var_0_4.new(var_19_0, var_19_1, 1)

	var_19_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_19_3:addTo(arg_19_0:nodeByName("map_container"))

	if arg_19_2 == var_0_30 then
		var_19_3:setPosition(arg_19_0.mapNodes[arg_19_1.y][arg_19_1.x]:getPositionX() + arg_19_0.mapNodes[arg_19_1.y][arg_19_1.x]:getContentSize().width / 2, arg_19_0.mapNodes[arg_19_1.y][arg_19_1.x]:getPositionY() + arg_19_0.mapNodes[arg_19_1.y][arg_19_1.x]:getContentSize().height / 2 - 8)
	else
		var_19_3:setPosition(arg_19_0.mapNodes[arg_19_1.y][arg_19_1.x]:getPositionX() + arg_19_0.mapNodes[arg_19_1.y][arg_19_1.x]:getContentSize().width / 2, arg_19_0.mapNodes[arg_19_1.y][arg_19_1.x]:getPositionY() + arg_19_0.mapNodes[arg_19_1.y][arg_19_1.x]:getContentSize().height / 2 + 8)
	end

	var_19_3:setName("effect" .. arg_19_1.x .. arg_19_1.y)
	var_19_3:play(nil, false, nil, arg_19_2)
	var_19_3:setLocalZOrder(1)

	local var_19_4 = cc.Sprite:create(var_0_26 .. var_0_9.baseInfo.hero_id .. ".png", cc.rect((arg_19_1.x - 1) * var_0_10, (var_0_12 - arg_19_1.y) * var_0_10, var_0_10, var_0_10))

	var_19_4:setAnchorPoint(cc.p(0, 1))
	var_19_4:addTo(arg_19_0:nodeByName("map_container"))

	if arg_19_2 == var_0_30 then
		var_19_4:setAnchorPoint(cc.p(1, 1))
		var_19_4:setPosition(arg_19_0.mapNodes[arg_19_1.y][arg_19_1.x]:getPositionX() + var_0_10, arg_19_0.mapNodes[arg_19_1.y][arg_19_1.x]:getPositionY() + var_0_10)
		var_19_4:runActionOnce(cc.ScaleTo:create(0.9, 0, 1), false, function()
			if not tolua.isnull(var_19_4) then
				var_19_4:removeFromParent()
			end
		end)
	elseif arg_19_2 == var_0_29 then
		var_19_4:setAnchorPoint(cc.p(0, 0))
		var_19_4:setPosition(arg_19_0.mapNodes[arg_19_1.y][arg_19_1.x]:getPositionX(), arg_19_0.mapNodes[arg_19_1.y][arg_19_1.x]:getPositionY())
		var_19_4:runActionOnce(cc.ScaleTo:create(0.9, 0, 1), false, function()
			if not tolua.isnull(var_19_4) then
				var_19_4:removeFromParent()
			end
		end)
	elseif arg_19_2 == var_0_28 then
		var_19_4:setAnchorPoint(cc.p(0, 0))
		var_19_4:setPosition(arg_19_0.mapNodes[arg_19_1.y][arg_19_1.x]:getPositionX(), arg_19_0.mapNodes[arg_19_1.y][arg_19_1.x]:getPositionY())
		var_19_4:runActionOnce(cc.ScaleTo:create(1.1, 1, 0), false, function()
			if not tolua.isnull(var_19_4) then
				var_19_4:removeFromParent()
			end
		end)
	elseif arg_19_2 == var_0_27 then
		var_19_4:setAnchorPoint(cc.p(1, 1))
		var_19_4:setPosition(arg_19_0.mapNodes[arg_19_1.y][arg_19_1.x]:getPositionX() + var_0_10, arg_19_0.mapNodes[arg_19_1.y][arg_19_1.x]:getPositionY() + var_0_10)
		var_19_4:runActionOnce(cc.ScaleTo:create(0.9, 1, 0), false, function()
			if not tolua.isnull(var_19_4) then
				var_19_4:removeFromParent()
			end
		end)
	end
end

function var_0_0.findRoad(arg_24_0, arg_24_1, arg_24_2)
	local var_24_0 = {}
	local var_24_1 = {}
	local var_24_2 = {}

	table.insert(var_24_0, 1, {
		f = 0,
		h = 0,
		point = arg_24_1
	})

	local function var_24_3(arg_25_0)
		local var_25_0 = false

		for iter_25_0, iter_25_1 in ipairs(var_24_0) do
			if iter_25_1.point.x == arg_25_0.point.x and iter_25_1.point.y == arg_25_0.point.y then
				if iter_25_1.f > arg_25_0.f then
					table.remove(var_24_0, iter_25_0)

					break
				else
					return
				end
			end
		end

		for iter_25_2 = 1, #var_24_0 do
			if var_24_0[iter_25_2].f > arg_25_0.f then
				table.insert(var_24_0, iter_25_2, arg_25_0)

				var_25_0 = true

				break
			end
		end

		if not var_25_0 then
			table.insert(var_24_0, arg_25_0)
		end
	end

	local function var_24_4(arg_26_0, arg_26_1)
		return 0 + arg_26_1 + math.abs(arg_26_0.x - arg_24_2.x) + math.abs(arg_26_0.y - arg_24_2.y)
	end

	local function var_24_5(arg_27_0)
		if tonumber(arg_24_0.map[arg_27_0.point.y][arg_27_0.point.x]) == 1 or tonumber(arg_24_0.mazeFog[arg_27_0.point.y][arg_27_0.point.x]) == 0 then
			return true
		end

		return false
	end

	local function var_24_6(arg_28_0)
		if arg_28_0.point and type(arg_28_0.point) == "table" then
			if tonumber(arg_24_0.map[arg_28_0.point.y][arg_28_0.point.x]) ~= 0 and tonumber(arg_24_0.map[arg_28_0.point.y][arg_28_0.point.x]) ~= 9 or tonumber(arg_24_0.mazeFog[arg_28_0.point.y][arg_28_0.point.x]) == 0 then
				return true
			end

			return false
		else
			if tonumber(arg_24_0.map[arg_28_0.y][arg_28_0.x]) ~= 0 and tonumber(arg_24_0.map[arg_28_0.y][arg_28_0.x]) ~= 9 or tonumber(arg_24_0.mazeFog[arg_28_0.y][arg_28_0.x]) == 0 then
				return true
			end

			return false
		end
	end

	local function var_24_7(arg_29_0)
		if #arg_29_0 > 0 then
			for iter_29_0 = 1, #arg_29_0 do
				if var_24_6(arg_29_0[iter_29_0]) then
					for iter_29_1 = #arg_29_0, iter_29_0, -1 do
						table.remove(arg_29_0, iter_29_1)
					end

					break
				end
			end
		end
	end

	local function var_24_8(arg_30_0)
		for iter_30_0, iter_30_1 in ipairs(var_24_1) do
			if iter_30_1.point.x == arg_30_0.point.x and iter_30_1.point.y == arg_30_0.point.y then
				return true
			end
		end

		return false
	end

	if var_24_5({
		point = arg_24_2
	}) then
		return var_24_2
	end

	while true do
		if #var_24_0 == 0 then
			return var_24_2
		end

		local var_24_9 = var_24_0[1]

		table.remove(var_24_0, 1)
		table.insert(var_24_1, var_24_9)

		if arg_24_2.x == var_24_9.point.x and arg_24_2.y == var_24_9.point.y then
			local var_24_10 = var_24_9

			while true do
				if var_24_10.father then
					table.insert(var_24_2, 1, var_24_10.point)

					var_24_10 = var_24_10.father
				else
					break
				end
			end

			var_24_7(var_24_2)

			break
		end

		if var_24_9.point.x - 1 > 0 then
			local var_24_11 = 0

			if var_24_6({
				x = var_24_9.point.x - 1,
				y = var_24_9.point.y
			}) then
				var_24_11 = 54
			end

			local var_24_12 = {
				f = var_24_4({
					x = var_24_9.point.x - 1,
					y = var_24_9.point.y
				}, var_24_9.h + 1 + var_24_11),
				point = {
					x = var_24_9.point.x - 1,
					y = var_24_9.point.y
				},
				father = var_24_9,
				h = var_24_9.h + 1 + var_24_11
			}

			if not var_24_8(var_24_12) and not var_24_5(var_24_12) then
				var_24_3(var_24_12)
			end
		end

		if var_24_9.point.x + 1 <= var_0_11 then
			local var_24_13 = 0

			if var_24_6({
				x = var_24_9.point.x + 1,
				y = var_24_9.point.y
			}) then
				var_24_13 = 54
			end

			local var_24_14 = {
				f = var_24_4({
					x = var_24_9.point.x + 1,
					y = var_24_9.point.y
				}, var_24_9.h + 1 + var_24_13),
				point = {
					x = var_24_9.point.x + 1,
					y = var_24_9.point.y
				},
				father = var_24_9,
				h = var_24_9.h + 1 + var_24_13
			}

			if not var_24_8(var_24_14) and not var_24_5(var_24_14) then
				var_24_3(var_24_14)
			end
		end

		if var_24_9.point.y - 1 > 0 then
			local var_24_15 = 0

			if var_24_6({
				x = var_24_9.point.x,
				y = var_24_9.point.y - 1
			}) then
				var_24_15 = 54
			end

			local var_24_16 = {
				f = var_24_4({
					x = var_24_9.point.x,
					y = var_24_9.point.y - 1
				}, var_24_9.h + 1 + var_24_15),
				point = {
					x = var_24_9.point.x,
					y = var_24_9.point.y - 1
				},
				father = var_24_9,
				h = var_24_9.h + 1 + var_24_15
			}

			if not var_24_8(var_24_16) and not var_24_5(var_24_16) then
				var_24_3(var_24_16)
			end
		end

		if var_24_9.point.y + 1 <= var_0_12 then
			local var_24_17 = 0

			if var_24_6({
				x = var_24_9.point.x,
				y = var_24_9.point.y + 1
			}) then
				var_24_17 = 54
			end

			local var_24_18 = {
				f = var_24_4({
					x = var_24_9.point.x,
					y = var_24_9.point.y + 1
				}, var_24_9.h + 1 + var_24_17),
				point = {
					x = var_24_9.point.x,
					y = var_24_9.point.y + 1
				},
				father = var_24_9,
				h = var_24_9.h + 1 + var_24_17
			}

			if not var_24_8(var_24_18) and not var_24_5(var_24_18) then
				var_24_3(var_24_18)
			end
		end
	end

	return var_24_2
end

function var_0_0.updateLeftContainer(arg_31_0)
	arg_31_0:nodeByName("page_txt"):setString(var_0_1:translation("MEMORIES_OF_SCHOOL_TIPS1"))
	arg_31_0:nodeByName("page_num"):setString(var_0_9.baseInfo.now_floor .. "/3")
	arg_31_0:nodeByName("key_num"):setString(var_0_8:getBackpack():getItemNumByID(var_0_31))
	arg_31_0:nodeByName("memories_num"):setString(var_0_8:getBackpack():getItemNumByID(var_0_32))
end

function var_0_0.isEndPoint(arg_32_0, arg_32_1)
	if arg_32_0:convertPositionToNum(arg_32_1) == tonumber(var_0_9.baseInfo.end_pos) then
		return true
	else
		return false
	end
end

function var_0_0.gridEvent(arg_33_0, arg_33_1)
	if arg_33_1.x == 0 or arg_33_1.y == 0 then
		return
	end

	local var_33_0 = arg_33_0.map[arg_33_1.y][arg_33_1.x]

	if var_33_0 == xyd.MazeType.MONSTER then
		var_0_9:getEnemyInfo({
			grid_pos = arg_33_0:convertPositionToNum(arg_33_1)
		}, function()
			local var_34_0 = {
				battleID = tonumber(var_0_9.enemyInfos[tostring(arg_33_0:convertPositionToNum(arg_33_1))])
			}

			if var_33_0 == xyd.MazeType.BOSS then
				var_34_0.battleID = tonumber(xyd.tables.mazeCampaign:fightID(tonumber(var_0_9.enemyInfos[tostring(arg_33_0:convertPositionToNum(arg_33_1))])))
			end

			var_34_0.enemiesinfo, var_34_0.currentRound = var_0_9:getTempEnemiesInfo()
			var_34_0.pos = arg_33_0:convertPositionToNum(arg_33_1)

			xyd.WindowManager.get():openWindow("memories_of_school_team_info", var_34_0)
		end)
		var_0_9:updateMapInfo({
			map = arg_33_0:convertMapToArray(arg_33_0.mazeFog),
			pos = arg_33_0:convertPositionToNum({
				x = arg_33_0.currentPointX,
				y = arg_33_0.currentPointY
			})
		})
	elseif var_33_0 == xyd.MazeType.BOSS then
		var_0_9:getEnemyInfo({
			grid_pos = arg_33_0:convertPositionToNum(arg_33_1)
		}, function()
			local var_35_0 = {
				battleID = tonumber(var_0_9.enemyInfos[tostring(arg_33_0:convertPositionToNum(arg_33_1))])
			}

			if var_33_0 == xyd.MazeType.BOSS then
				var_35_0.battleID = tonumber(xyd.tables.mazeCampaign:fightID(tonumber(var_0_9.enemyInfos[tostring(arg_33_0:convertPositionToNum(arg_33_1))])))
			end

			var_35_0.enemiesinfo, var_35_0.currentRound = var_0_9:getTempEnemiesInfo()
			var_35_0.boss_id = tonumber(var_0_9.enemyInfos[tostring(arg_33_0:convertPositionToNum(arg_33_1))])
			var_35_0.pos = arg_33_0:convertPositionToNum(arg_33_1)

			var_0_9:updateMapInfo({
				map = arg_33_0:convertMapToArray(arg_33_0.mazeFog),
				pos = arg_33_0:convertPositionToNum({
					x = arg_33_0.currentPointX,
					y = arg_33_0.currentPointY
				})
			})
			xyd.WindowManager.get():openWindow("memories_of_school_boss_info", var_35_0)
		end)
	elseif var_33_0 == xyd.MazeType.PLAYER then
		var_0_9:getEnemyInfo({
			grid_pos = arg_33_0:convertPositionToNum(arg_33_1)
		}, function(arg_36_0, arg_36_1)
			local var_36_0 = {
				team = arg_36_1.enemy_info,
				battleID = tonumber(var_0_9.enemyInfos[tostring(arg_33_0:convertPositionToNum(arg_33_1))])
			}

			var_36_0.enemiesinfo, var_36_0.currentRound = var_0_9:getTempEnemiesInfo()
			var_36_0.pos = arg_33_0:convertPositionToNum(arg_33_1)
			var_36_0.isBoss = true

			xyd.WindowManager.get():openWindow("memories_of_school_team_info", var_36_0)
			var_0_9:updateMapInfo({
				map = arg_33_0:convertMapToArray(arg_33_0.mazeFog),
				pos = arg_33_0:convertPositionToNum({
					x = arg_33_0.currentPointX,
					y = arg_33_0.currentPointY
				})
			})
		end)
	elseif var_33_0 == xyd.MazeType.BIG_BOX then
		local var_33_1 = arg_33_0.currentPointX
		local var_33_2 = arg_33_0.currentPointY

		if arg_33_0:isNeighBour({
			x = var_33_1,
			y = var_33_2
		}, arg_33_1) then
			if var_0_8:getBackpack():getItemNumByID(var_0_32) > 0 then
				var_0_9:openBox({
					grid_pos = arg_33_0:convertPositionToNum(arg_33_1)
				}, function(arg_37_0, arg_37_1)
					if arg_37_0 == xyd.error.OK then
						var_0_8:handleRewards(arg_37_1.awards)

						arg_33_0.map[arg_33_1.y][arg_33_1.x] = xyd.MazeType.BIG_BOX_OPEN

						local var_37_0 = {
							itemID = var_0_32
						}

						var_37_0.itemNum = 1

						var_0_8:getBackpack():removeItem(var_37_0)
						arg_33_0:refreshMap()
					end
				end)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("MEMORIES_OF_SCHOOL_KEY_NOT_ENOUGH")
				})
			end
		end
	elseif var_33_0 == xyd.MazeType.SMALL_BOX then
		local var_33_3 = arg_33_0.currentPointX
		local var_33_4 = arg_33_0.currentPointY

		if arg_33_0:isNeighBour({
			x = var_33_3,
			y = var_33_4
		}, arg_33_1) then
			if var_0_8:getBackpack():getItemNumByID(var_0_31) > 0 then
				var_0_9:openBox({
					grid_pos = arg_33_0:convertPositionToNum(arg_33_1)
				}, function(arg_38_0, arg_38_1)
					if arg_38_0 == xyd.error.OK then
						var_0_8:handleRewards(arg_38_1.awards)

						arg_33_0.map[arg_33_1.y][arg_33_1.x] = xyd.MazeType.SMALL_BOX_OPEN

						local var_38_0 = {
							itemID = var_0_31
						}

						var_38_0.itemNum = 1

						var_0_8:getBackpack():removeItem(var_38_0)
						arg_33_0:refreshMap()
					end
				end)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("MEMORIES_OF_SCHOOL_KEY_NOT_ENOUGH")
				})
			end
		end
	elseif var_33_0 == xyd.MazeType.FINAL_POINT then
		local var_33_5

		if var_0_9.baseInfo.now_floor == 3 then
			var_33_5 = xyd.tables.translation:translation("MAZE_PASS_TIP")
		else
			var_33_5 = xyd.tables.translation:translation("MEMORIES_OF_SCHOOL_NEXT_FLOOR")
		end

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_33_5, function()
			if arg_33_0:isNeighBour({
				x = arg_33_0.currentPointX,
				y = arg_33_0.currentPointY
			}, arg_33_1) and var_0_9.baseInfo.now_floor < 3 then
				var_0_9:enterNextFloor({
					grid_pos = arg_33_0:convertPositionToNum(arg_33_1)
				}, function(arg_40_0, arg_40_1)
					arg_33_0:clearMapInfo()
					arg_33_0:initMap(arg_40_1.maze_info.maze_map, arg_33_0:KV2Array(arg_40_1.maze_info.map_open))

					arg_33_0.hero_id = arg_40_1.base_info.hero_id

					local var_40_0 = arg_33_0:convertNumToPosition(arg_40_1.base_info.now_pos)
					local var_40_1 = arg_33_0:convertNumToPosition(arg_40_1.base_info.end_pos)

					arg_33_0.map[var_40_1.y][var_40_1.x] = xyd.MazeType.FINAL_POINT
					arg_33_0.currentPointX = var_40_0.x
					arg_33_0.currentPointY = var_40_0.y

					arg_33_0:layout()

					arg_33_0.model = arg_33_0:createHeroModel()

					arg_33_0.model:addTo(arg_33_0:nodeByName("map_container"))
					arg_33_0.model:setPosition((arg_33_0.currentPointX - 0.5) * var_0_10, (arg_33_0.currentPointY - 0.5) * var_0_10)
				end)
			elseif arg_33_0:isNeighBour({
				x = arg_33_0.currentPointX,
				y = arg_33_0.currentPointY
			}, arg_33_1) and var_0_9.baseInfo.now_floor == 3 then
				xyd.WindowManager.get():openWindow("memories_of_school_final_reward", {
					grid_pos = arg_33_0:convertPositionToNum(arg_33_1)
				})
			end
		end, nil, nil, arg_33_0.colorMode)
	end
end

function var_0_0.isNeighBour(arg_41_0, arg_41_1, arg_41_2)
	if arg_41_2.x - arg_41_1.x == 1 and arg_41_2.y == arg_41_1.y or arg_41_2.x - arg_41_1.x == -1 and arg_41_2.y == arg_41_1.y or arg_41_2.y - arg_41_1.y == 1 and arg_41_2.x == arg_41_1.x or arg_41_2.y - arg_41_1.y == -1 and arg_41_2.x == arg_41_1.x then
		return true
	end

	if arg_41_1.x == arg_41_2.x and arg_41_1.y == arg_41_2.y then
		return true
	end

	return false
end

function var_0_0.updateMapItemDetails(arg_42_0)
	arg_42_0:nodeByName("page_num"):setString()
	arg_42_0:nodeByName("key_num"):setString()
	arg_42_0:nodeByName("memories_num"):setString()
end

function var_0_0.layout(arg_43_0)
	arg_43_0:nodeByName("txt_reborn"):setString(var_0_1:translation("MEMORIES_OF_SCHOOL_TIPS8"))
	arg_43_0:nodeByName("txt_abandon"):setString(var_0_1:translation("MEMORIES_OF_SCHOOL_TIPS9"))

	for iter_43_0 = 1, var_0_12 do
		local var_43_0 = {}

		for iter_43_1 = 1, var_0_11 do
			local var_43_1 = cc.c4b(math.floor(arg_43_0.map[iter_43_0][iter_43_1] / 4) * 255, math.floor(arg_43_0.map[iter_43_0][iter_43_1] / 2) % 2 * 255, arg_43_0.map[iter_43_0][iter_43_1] % 2 * 255, 200)
			local var_43_2 = display.newNode()

			var_43_2:setPosition((iter_43_1 - 1) * var_0_10, (iter_43_0 - 1) * var_0_10)
			var_43_2:setContentSize(var_0_10, var_0_10)
			var_43_2:setAnchorPoint(cc.p(0, 0))
			var_43_2:addTo(arg_43_0:nodeByName("map_container"))
			var_43_2:setName("map_node_" .. iter_43_1 .. "_" .. iter_43_0)
			var_43_2:setTouchSwallowEnabled(false)
			var_43_2:setTouchEnabled(true)

			var_43_2.nodeInfo = -1
			var_43_2.mazeInfo = -1

			var_43_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_44_0)
				if arg_44_0.name == "began" then
					-- block empty
				elseif arg_44_0.name == "ended" and not arg_43_0.isAnimating and arg_43_0.mazeFog[iter_43_0][iter_43_1] == 1 then
					local var_44_0 = arg_43_0.currentPointX
					local var_44_1 = arg_43_0.currentPointY
					local var_44_2 = arg_43_0:findRoad({
						x = var_44_0,
						y = var_44_1
					}, {
						x = iter_43_1,
						y = iter_43_0
					})

					if var_44_2 and #var_44_2 ~= 0 then
						arg_43_0.currentPointX = var_44_2[#var_44_2].x
						arg_43_0.currentPointY = var_44_2[#var_44_2].y

						if (iter_43_1 ~= var_44_2[#var_44_2].x or iter_43_0 ~= var_44_2[#var_44_2].y) and arg_43_0.map[iter_43_0][iter_43_1] ~= 0 or arg_43_0.map[iter_43_0][iter_43_1] == 9 then
							arg_43_0.eventPointX = iter_43_1
							arg_43_0.eventPointY = iter_43_0
						else
							arg_43_0.eventPointX = 0
							arg_43_0.eventPointY = 0
						end

						arg_43_0:moveModel({
							x = var_44_0,
							y = var_44_1
						}, var_44_2)
					elseif var_44_2 and #var_44_2 == 0 then
						arg_43_0.eventPointX = iter_43_1
						arg_43_0.eventPointY = iter_43_0

						arg_43_0:moveModel({
							x = var_44_0,
							y = var_44_1
						}, var_44_2)
					end
				end

				return true
			end)

			var_43_0[iter_43_1] = var_43_2
		end

		arg_43_0.mapNodes[iter_43_0] = var_43_0
	end

	arg_43_0:refreshMap()
	arg_43_0:nodeByName("abandon_btn"):addTouchEventListener(function(arg_45_0, arg_45_1)
		xyd.buttonScaleAnim(arg_45_0, arg_45_1)

		if arg_45_1 == ccui.TouchEventType.ended then
			local var_45_0 = xyd.tables.translation:translation("MEMORIES_OF_SCHOOL_ABANDON_CONFIRM")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_45_0, function()
				var_0_9:abandonGame({}, function(arg_47_0, arg_47_1)
					if arg_47_0 == xyd.error.OK then
						if xyd.WindowManager.get():getWindow("memories_of_school") then
							xyd.WindowManager.get():closeWindow("memories_of_school")
						end

						if xyd.WindowManager.get():getWindow("memories_of_school_main") then
							xyd.WindowManager.get():getWindow("memories_of_school_main"):updateWindow(var_0_9:getLocalParams())
						end
					end
				end)
			end, nil, nil, arg_43_0.colorMode)
		end
	end)
	arg_43_0:nodeByName("reborn_btn"):addTouchEventListener(function(arg_48_0, arg_48_1)
		xyd.buttonScaleAnim(arg_48_0, arg_48_1)

		if arg_48_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("memories_of_school_reborn")
		end
	end)

	local var_43_3 = var_0_35 .. ".json"
	local var_43_4 = var_0_35 .. ".atlas"
	local var_43_5
	local var_43_6 = var_0_4.new(var_43_3, var_43_4, 1)

	var_43_6:setAnchorPoint(cc.p(0.5, 0.5))
	var_43_6:addTo(arg_43_0:nodeByName("small_key_icon"))
	var_43_6:setScale(var_0_14)
	var_43_6:play(nil, true)

	local var_43_7 = var_0_36 .. ".json"
	local var_43_8 = var_0_36 .. ".atlas"
	local var_43_9
	local var_43_10 = var_0_4.new(var_43_7, var_43_8, 1)

	var_43_10:setAnchorPoint(cc.p(0.5, 0.5))
	var_43_10:addTo(arg_43_0:nodeByName("big_key_icon"))
	var_43_10:setScale(var_0_14)
	var_43_10:play(nil, true)
end

function var_0_0.createHeroModel(arg_49_0)
	local var_49_0 = arg_49_0.hero_id
	local var_49_1 = var_0_8:getHeroByTableID(var_49_0)

	if not var_49_1 then
		var_49_1 = var_0_2.new()

		var_49_1:populateWithTableID(var_49_0)
	end

	local var_49_2 = var_49_1:getHeroModel()
	local var_49_3 = var_0_34 .. ".json"
	local var_49_4 = var_0_34 .. ".atlas"
	local var_49_5
	local var_49_6 = var_0_4.new(var_49_3, var_49_4, 1)

	var_49_6:setAnchorPoint(cc.p(0.5, 0.5))
	var_49_2:setScale(xyd.tables.model:scale(var_49_1:getModelID()))
	var_49_2:setContentSize(1, 1)

	arg_49_0.heroScale = xyd.tables.model:scale(var_49_1:getModelID())

	var_49_6:addTo(var_49_2)
	var_49_6:setScale(var_0_13)
	var_49_6:play(nil, true)

	return var_49_2
end

return var_0_0
