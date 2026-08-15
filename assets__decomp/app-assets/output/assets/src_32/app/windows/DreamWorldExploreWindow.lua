local var_0_0 = class("DreamWorldExploreWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("framework.scheduler")
local var_0_4 = import("app.common.ui.SpineEffect")
local var_0_5 = xyd.tables.item
local var_0_6 = xyd.tables.hero
local var_0_7 = xyd.tables.dreamWorldMapResourceTable
local var_0_8 = xyd.tables.dreamWorldMapCellTable
local var_0_9 = xyd.tables.dreamWorldMapEventTable
local var_0_10 = xyd.tables.dreamWorldStoryTable
local var_0_11 = xyd.tables.dreamWorldMapStoryBranchTable
local var_0_12
local var_0_13
local var_0_14 = 25
local var_0_15 = 150
local var_0_16 = 26
local var_0_17 = 20
local var_0_18 = 50
local var_0_19 = 9 * var_0_15
local var_0_20 = 11
local var_0_21 = 10
local var_0_22 = 1280 / var_0_21 / var_0_15
local var_0_23 = 720 / var_0_15 / var_0_22
local var_0_24 = 10000
local var_0_25 = 1000

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	var_0_12 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	var_0_13 = xyd.ModelManager.get():loadModel(xyd.ModelType.DREAM_WORLD)
	arg_1_0.cell = {}
	arg_1_0.cellType = {}
	arg_1_0.mazeFog = {}
	arg_1_0.mapNodes = {}
	arg_1_0.monsterModels = {}
	arg_1_0.currentPointX = 1
	arg_1_0.currentPointY = 1
	arg_1_0.faceTo = 1
	arg_1_0.eventPointX = 0
	arg_1_0.eventPointY = 0
	arg_1_0.box = {}
	arg_1_0.canGetAward = true

	if arg_1_2 and arg_1_2.showOpenStory then
		arg_1_0.showOpenStory = arg_1_2.showOpenStory
	end

	arg_1_0.layers = {}
	arg_1_0.sprites = {}
end

function var_0_0.convertPositionToNum(arg_2_0, arg_2_1)
	local var_2_0

	return (arg_2_1.y - 1) * var_0_16 + arg_2_1.x
end

function var_0_0.convertNumToPosition(arg_3_0, arg_3_1)
	return {
		x = (arg_3_1 - 1) % var_0_16 + 1,
		y = math.floor((arg_3_1 - 1) / var_0_16) + 1
	}
end

function var_0_0.convertMapToArray(arg_4_0, arg_4_1)
	local var_4_0 = {}

	for iter_4_0 = 1, var_0_17 do
		for iter_4_1 = 1, var_0_16 do
			var_4_0[(iter_4_0 - 1) * var_0_16 + iter_4_1] = arg_4_1[iter_4_0][iter_4_1]
		end
	end

	return var_4_0
end

function var_0_0.KV2Array(arg_5_0, arg_5_1)
	local var_5_0 = {}

	for iter_5_0, iter_5_1 in pairs(arg_5_1) do
		var_5_0[tonumber(iter_5_0)] = iter_5_1
	end

	return var_5_0
end

function var_0_0.willOpen(arg_6_0, arg_6_1)
	var_0_0.super.willOpen(arg_6_0, arg_6_1)

	arg_6_0.mapContainer = display.newNode()

	arg_6_0.mapContainer:setScale(var_0_22)
	arg_6_0.mapContainer:addTo(arg_6_0:nodeByName("map_container"))
	arg_6_0:addMapScrollNode()
	arg_6_0:initMap()

	arg_6_0.hero_id = xyd.tables.misc:getValue("dreamworld_player_model_id")

	local var_6_0 = var_0_13.baseInfo.is_going
	local var_6_1

	if var_6_0 > 1 then
		var_6_1 = arg_6_0:convertNumToPosition(var_6_0)
	else
		var_6_1 = {
			x = xyd.tables.dreamWorldMapReplayTable:startPoint(var_0_13.baseInfo.current_floor)[1],
			y = xyd.tables.dreamWorldMapReplayTable:startPoint(var_0_13.baseInfo.current_floor)[2]
		}
	end

	arg_6_0.endPoint = {
		x = xyd.tables.dreamWorldMapReplayTable:endPoint(var_0_13.baseInfo.current_floor)[1],
		y = xyd.tables.dreamWorldMapReplayTable:endPoint(var_0_13.baseInfo.current_floor)[2]
	}
	arg_6_0.currentPointX = var_6_1.x
	arg_6_0.currentPointY = var_6_1.y

	arg_6_0:layout()

	arg_6_0.model = arg_6_0:createHeroModel()

	arg_6_0:addSprite(arg_6_0.model, var_0_25, 0, 0, 0, 0, true)
	arg_6_0.model:setLocalZOrder(-arg_6_0.currentPointY * var_0_16 + arg_6_0.currentPointX)
	arg_6_0.model:setPosition((arg_6_0.currentPointX - 0.5) * var_0_15, (arg_6_0.currentPointY - 0.8) * var_0_15 + var_0_14)

	arg_6_0.response = nil

	if var_0_13.autoEvent then
		arg_6_0:gridEvent()
	end

	xyd.WindowManager.get():openWindow("dream_world_diary"):hide()
	xyd.WindowManager.get():openWindow("dream_world_collect"):hide()
	xyd.WindowManager.get():openWindow("dream_world_explore_menu")
	arg_6_0:checkOpenStory()
end

function var_0_0.checkOpenStory(arg_7_0)
	if arg_7_0.showOpenStory then
		local var_7_0 = 101011

		xyd.WindowManager.get():openWindow("dream_world_story", {
			notSendMid = true,
			dialogueID = var_7_0
		})
	end
end

function var_0_0.initMap(arg_8_0)
	local var_8_0 = xyd.tables.dreamWorldMapTable:getCells(var_0_13.baseInfo.current_floor)

	for iter_8_0 = 1, #var_8_0 do
		local var_8_1 = (iter_8_0 - 1) % var_0_16 + 1
		local var_8_2 = math.floor((iter_8_0 - 1) / var_0_16) + 1

		if not arg_8_0.cellType[var_8_2] then
			arg_8_0.cellType[var_8_2] = {}
		end

		if not arg_8_0.mazeFog[var_8_2] then
			arg_8_0.mazeFog[var_8_2] = {}
		end

		if not arg_8_0.cell[var_8_2] then
			arg_8_0.cell[var_8_2] = {}
		end

		arg_8_0.cellType[var_8_2][var_8_1] = var_0_8:type(var_8_0[iter_8_0])
		arg_8_0.mazeFog[var_8_2][var_8_1] = var_0_13.mazeFog[iter_8_0]
		arg_8_0.cell[var_8_2][var_8_1] = var_8_0[iter_8_0]

		if not arg_8_0.monsterModels[var_8_2] then
			arg_8_0.monsterModels[var_8_2] = {}
		end
	end
end

function var_0_0.layout(arg_9_0)
	arg_9_0:focusOnHero()
	arg_9_0:refreshTouchNode()
	arg_9_0:refreshMap()
end

function var_0_0.focusOnHero(arg_10_0)
	local var_10_0 = var_0_16 * var_0_15 * var_0_22
	local var_10_1 = var_0_17 * var_0_15 * var_0_22
	local var_10_2 = var_0_21 * var_0_15 * var_0_22
	local var_10_3 = var_0_23 * var_0_15 * var_0_22

	local function var_10_4(arg_11_0, arg_11_1)
		local var_11_0
		local var_11_1
		local var_11_2
		local var_11_3
		local var_11_4 = var_10_2 - var_10_0
		local var_11_5 = 0
		local var_11_6 = var_10_3 - var_10_1
		local var_11_7 = 0

		arg_11_0 = math.min(arg_11_0, var_11_5)
		arg_11_0 = math.max(arg_11_0, var_11_4)
		arg_11_1 = math.min(arg_11_1, var_11_7)
		arg_11_1 = math.max(arg_11_1, var_11_6)

		return arg_11_0, arg_11_1
	end

	local var_10_5 = arg_10_0.currentPointX - math.ceil(var_0_21 / 2)
	local var_10_6 = arg_10_0.currentPointY - math.ceil(var_0_23 / 2)
	local var_10_7 = -var_10_5 * var_0_15 * var_0_22
	local var_10_8 = -var_10_6 * var_0_15 * var_0_22
	local var_10_9, var_10_10 = var_10_4(var_10_7, var_10_8)

	arg_10_0.mapContainer:setPosition(var_10_9, var_10_10)
end

function var_0_0.refreshTouchNode(arg_12_0)
	for iter_12_0 = 1, var_0_17 do
		local var_12_0 = arg_12_0.mapNodes[iter_12_0] or {}

		for iter_12_1 = 1, var_0_16 do
			local var_12_1, var_12_2 = arg_12_0.mapContainer:getPosition()
			local var_12_3 = 1 - var_0_20
			local var_12_4 = 1 - var_0_20
			local var_12_5 = var_0_21 + var_0_20
			local var_12_6 = var_0_23 + var_0_20
			local var_12_7 = var_12_1 / var_0_15 / var_0_22
			local var_12_8 = var_12_2 / var_0_15 / var_0_22 + iter_12_0
			local var_12_9 = var_12_7 + iter_12_1

			if not (var_12_8 < var_12_4) and not (var_12_6 < var_12_8) and not (var_12_9 < var_12_3) and not (var_12_5 < var_12_9) then
				if not arg_12_0.mapContainer:getChildByName("map_node_" .. iter_12_1 .. "_" .. iter_12_0) then
					local var_12_10 = display.newNode()

					var_12_10:setPosition((iter_12_1 - 1) * var_0_15, (iter_12_0 - 1) * var_0_15 + var_0_14)
					var_12_10:setContentSize(var_0_15, var_0_15)
					var_12_10:setAnchorPoint(cc.p(0, 0))
					var_12_10:addTo(arg_12_0.mapContainer, (iter_12_0 - 1) * var_0_16 + iter_12_1)
					var_12_10:setName("map_node_" .. iter_12_1 .. "_" .. iter_12_0)
					var_12_10:setTouchSwallowEnabled(false)
					var_12_10:setTouchEnabled(true)

					var_12_10.nodeInfo = -1
					var_12_10.mazeInfo = -1

					var_12_10:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
						if arg_13_0.name == "began" then
							arg_12_0.mapNodeTouchX = arg_13_0.x
							arg_12_0.mapNodeTouchY = arg_13_0.y
						elseif arg_13_0.name == "ended" and arg_12_0.mazeFog[iter_12_0][iter_12_1] == 0 and math.abs(arg_12_0.mapNodeTouchX - arg_13_0.x) < var_0_15 / 2 and math.abs(arg_12_0.mapNodeTouchY - arg_13_0.y) < var_0_15 / 2 and arg_12_0:checkTouchOnFloor(var_12_10, arg_13_0.x, arg_13_0.y) then
							local var_13_0 = arg_12_0.currentPointX
							local var_13_1 = arg_12_0.currentPointY
							local var_13_2 = arg_12_0:findRoad({
								x = var_13_0,
								y = var_13_1
							}, {
								x = iter_12_1,
								y = iter_12_0
							})

							if var_13_2 and #var_13_2 ~= 0 then
								if (iter_12_1 ~= var_13_2[#var_13_2].x or iter_12_0 ~= var_13_2[#var_13_2].y) and arg_12_0.cellType[iter_12_0][iter_12_1] ~= 0 or arg_12_0.cellType[iter_12_0][iter_12_1] == 9 then
									arg_12_0.eventPointX = iter_12_1
									arg_12_0.eventPointY = iter_12_0
								else
									arg_12_0.eventPointX = 0
									arg_12_0.eventPointY = 0
								end

								arg_12_0:moveModel({
									x = var_13_0,
									y = var_13_1
								}, var_13_2)
							elseif var_13_2 and #var_13_2 == 0 then
								arg_12_0.eventPointX = iter_12_1
								arg_12_0.eventPointY = iter_12_0

								arg_12_0:moveModel({
									x = var_13_0,
									y = var_13_1
								}, var_13_2)
							end
						end

						return true
					end)

					var_12_0[iter_12_1] = var_12_10
				end
			elseif arg_12_0.mapNodes[iter_12_0] and arg_12_0.mapNodes[iter_12_0][iter_12_1] then
				arg_12_0.mapNodes[iter_12_0][iter_12_1].nodeInfo = -1
				arg_12_0.mapNodes[iter_12_0][iter_12_1].mazeInfo = -1

				arg_12_0.mapNodes[iter_12_0][iter_12_1]:removeAllChildren(true)

				arg_12_0.mapNodes[iter_12_0][iter_12_1] = nil

				arg_12_0:clearSprite(iter_12_0, iter_12_1)

				if arg_12_0.mapContainer:getChildByName("map_node_" .. iter_12_1 .. "_" .. iter_12_0) then
					arg_12_0.mapContainer:removeChildByName("map_node_" .. iter_12_1 .. "_" .. iter_12_0)
				end
			end
		end

		arg_12_0.mapNodes[iter_12_0] = var_12_0
	end

	collectgarbage("count")
end

function var_0_0.refreshMap(arg_14_0)
	arg_14_0:clearFog()

	for iter_14_0 = 1, var_0_17 do
		for iter_14_1 = 1, var_0_16 do
			local var_14_0, var_14_1 = arg_14_0.mapContainer:getPosition()
			local var_14_2 = 1 - var_0_20
			local var_14_3 = 1 - var_0_20
			local var_14_4 = var_0_21 + var_0_20
			local var_14_5 = var_0_23 + var_0_20
			local var_14_6 = var_14_0 / var_0_15 / var_0_22
			local var_14_7 = var_14_1 / var_0_15 / var_0_22 + iter_14_0
			local var_14_8 = var_14_6 + iter_14_1

			if not (var_14_7 < var_14_3) and not (var_14_5 < var_14_7) and not (var_14_8 < var_14_2) and not (var_14_4 < var_14_8) and (arg_14_0.mapNodes[iter_14_0][iter_14_1].nodeInfo ~= arg_14_0.cellType[iter_14_0][iter_14_1] or arg_14_0.mapNodes[iter_14_0][iter_14_1].mazeInfo ~= arg_14_0.mazeFog[iter_14_0][iter_14_1]) then
				arg_14_0:updateCell(iter_14_0, iter_14_1)
			end
		end
	end
end

function var_0_0.updateCell(arg_15_0, arg_15_1, arg_15_2)
	if not arg_15_2 then
		local var_15_0 = arg_15_0:convertNumToPosition(arg_15_1)

		arg_15_1, arg_15_2 = var_15_0.y, var_15_0.x
	end

	local var_15_1
	local var_15_2 = arg_15_0.cell[arg_15_1][arg_15_2]

	arg_15_0.mapNodes[arg_15_1][arg_15_2].nodeInfo = arg_15_0.cellType[arg_15_1][arg_15_2]
	arg_15_0.mapNodes[arg_15_1][arg_15_2].mazeInfo = arg_15_0.mazeFog[arg_15_1][arg_15_2]

	arg_15_0.mapNodes[arg_15_1][arg_15_2]:removeAllChildren(true)
	arg_15_0:clearSprite(arg_15_1, arg_15_2)

	if arg_15_0.mazeFog[arg_15_1][arg_15_2] == 1 then
		local var_15_3 = xyd.AssetLoader:get():loadSprite("windows/dream_world/explore/fog.png")

		var_15_3:setAnchorPoint(cc.p(0.5, 0.5))
		var_15_3:setName("fog_" .. arg_15_1 .. arg_15_2)
		arg_15_0:addSprite(var_15_3, var_0_24, arg_15_1, arg_15_2, var_0_15 / 2, var_0_15 / 2, true)

		local var_15_4 = var_0_8:resID(var_15_2)
		local var_15_5 = var_0_8:resScale(var_15_2)
		local var_15_6 = var_0_8:resPosX(var_15_2)
		local var_15_7 = var_0_8:resPosY(var_15_2)
		local var_15_8 = 1
		local var_15_9 = var_0_7:path(var_15_4[var_15_8])
		local var_15_10

		if #var_15_9 == 1 then
			var_15_10 = var_15_9[1]
		else
			var_15_10 = arg_15_0:getRandomPath(arg_15_1, arg_15_2, var_15_9)
		end

		local var_15_11 = xyd.AssetLoader:get():loadSprite(var_15_10)

		var_15_11:setScale(var_15_5[var_15_8])
		var_15_11:setAnchorPoint(cc.p(0, 0))

		local var_15_12 = var_15_6[var_15_8]
		local var_15_13 = var_15_7[var_15_8] - var_0_14

		arg_15_0:addSprite(var_15_11, var_15_8, arg_15_1, arg_15_2, var_15_12, var_15_13)
	else
		local var_15_14 = var_0_8:resID(var_15_2)
		local var_15_15 = var_0_8:resScale(var_15_2)
		local var_15_16 = var_0_8:resPosX(var_15_2)
		local var_15_17 = var_0_8:resPosY(var_15_2)

		for iter_15_0 = 1, #var_15_14 do
			local var_15_18 = var_0_7:path(var_15_14[iter_15_0])
			local var_15_19

			if #var_15_18 == 1 or arg_15_0:isBox(arg_15_2, arg_15_1) then
				var_15_19 = var_15_18[1]
			else
				var_15_19 = arg_15_0:getRandomPath(arg_15_1, arg_15_2, var_15_18)
			end

			local var_15_20 = xyd.AssetLoader:get():loadSprite(var_15_19)

			var_15_20:setScale(var_15_15[iter_15_0])
			var_15_20:setAnchorPoint(cc.p(0, 0))

			if arg_15_0:needAddShadow(arg_15_2, arg_15_1) then
				local var_15_21 = xyd.AssetLoader:get():loadSprite("windows/dream_world/explore/box_shadow.png")

				var_15_21:addTo(var_15_20, -1)
				var_15_21:setPosition(75, 35)

				if not arg_15_0.box[arg_15_1] then
					arg_15_0.box[arg_15_1] = {}
				end

				arg_15_0.box[arg_15_1][arg_15_2] = var_15_20
				var_15_20.replacePath = var_15_18[2]
			end

			local var_15_22 = var_15_16[iter_15_0]
			local var_15_23 = var_15_17[iter_15_0]

			if iter_15_0 == 1 then
				var_15_23 = var_15_23 - var_0_14

				arg_15_0:addSprite(var_15_20, iter_15_0, arg_15_1, arg_15_2, var_15_22, var_15_23)
			elseif arg_15_0.cellType[arg_15_1][arg_15_2] > 0 then
				if var_0_13.eventIndex[arg_15_0:convertPositionToNum(cc.p(arg_15_2, arg_15_1))] ~= 0 then
					arg_15_0:addSprite(var_15_20, iter_15_0, arg_15_1, arg_15_2, var_15_22, var_15_23)
				end
			else
				arg_15_0:addSprite(var_15_20, iter_15_0, arg_15_1, arg_15_2, var_15_22, var_15_23)
			end
		end

		if var_0_13.eventIndex[arg_15_0:convertPositionToNum(cc.p(arg_15_2, arg_15_1))] ~= 0 then
			local var_15_24 = var_0_8:model(var_15_2)
			local var_15_25 = var_0_8:modelScale(var_15_2)
			local var_15_26 = var_0_8:modelDialogue(var_15_2)

			if var_15_24 ~= 0 then
				local var_15_27 = xyd.HeroAnimation.new(nil, var_15_24, var_15_25, {
					loadAttackEffect = true
				})

				var_15_27:idle()
				var_15_27:setFlipX(true)

				if var_15_26 ~= "" then
					local var_15_28 = xyd.AssetLoader.get():loadNodeFromJson("windows/dream_world/explore/dialog.csb")
					local var_15_29 = var_15_28:getChildByName("container")

					var_15_29:getChildByName("text"):setString(var_15_26)
					var_15_29:width(var_15_29:getChildByName("text"):getWidth() + 28)
					var_15_28:addTo(var_15_27)
					var_15_28:setPositionY(var_15_27:getHeight() + 5)
				end

				arg_15_0:addSprite(var_15_27, var_0_25, arg_15_1, arg_15_2, var_0_15 / 2, 0.2 * var_0_15)
			end
		end
	end
end

function var_0_0.clearFog(arg_16_0)
	if arg_16_0.mazeFog[arg_16_0.currentPointY] and arg_16_0.mazeFog[arg_16_0.currentPointY][arg_16_0.currentPointX] and arg_16_0.mazeFog[arg_16_0.currentPointY][arg_16_0.currentPointX] == 1 then
		arg_16_0.mazeFog[arg_16_0.currentPointY][arg_16_0.currentPointX] = 0
	end

	arg_16_0:checkFog(cc.p(arg_16_0.currentPointX + 1, arg_16_0.currentPointY))
	arg_16_0:checkFog(cc.p(arg_16_0.currentPointX + 2, arg_16_0.currentPointY), cc.p(arg_16_0.currentPointX + 1, arg_16_0.currentPointY))
	arg_16_0:checkFog(cc.p(arg_16_0.currentPointX - 1, arg_16_0.currentPointY))
	arg_16_0:checkFog(cc.p(arg_16_0.currentPointX - 2, arg_16_0.currentPointY), cc.p(arg_16_0.currentPointX - 1, arg_16_0.currentPointY))
	arg_16_0:checkFog(cc.p(arg_16_0.currentPointX, arg_16_0.currentPointY + 1))
	arg_16_0:checkFog(cc.p(arg_16_0.currentPointX, arg_16_0.currentPointY + 2), cc.p(arg_16_0.currentPointX, arg_16_0.currentPointY + 1))
	arg_16_0:checkFog(cc.p(arg_16_0.currentPointX, arg_16_0.currentPointY - 1))
	arg_16_0:checkFog(cc.p(arg_16_0.currentPointX, arg_16_0.currentPointY - 2), cc.p(arg_16_0.currentPointX, arg_16_0.currentPointY - 1))
	arg_16_0:checkFog(cc.p(arg_16_0.currentPointX + 1, arg_16_0.currentPointY + 1))
	arg_16_0:checkFog(cc.p(arg_16_0.currentPointX - 1, arg_16_0.currentPointY - 1))
	arg_16_0:checkFog(cc.p(arg_16_0.currentPointX - 1, arg_16_0.currentPointY + 1))
	arg_16_0:checkFog(cc.p(arg_16_0.currentPointX + 1, arg_16_0.currentPointY - 1))
end

function var_0_0.checkFog(arg_17_0, arg_17_1, arg_17_2)
	if arg_17_2 and arg_17_0.cellType[arg_17_2.y] and arg_17_0.cellType[arg_17_2.y][arg_17_2.x] and arg_17_0.cellType[arg_17_2.y][arg_17_2.x] < 0 then
		return
	end

	if arg_17_0.mazeFog[arg_17_1.y] and arg_17_0.mazeFog[arg_17_1.y][arg_17_1.x] and arg_17_0.mazeFog[arg_17_1.y][arg_17_1.x] == 1 then
		arg_17_0.mazeFog[arg_17_1.y][arg_17_1.x] = 0

		arg_17_0:runFogEffect({
			x = arg_17_1.x,
			y = arg_17_1.y
		})
	end
end

function var_0_0.runFogEffect(arg_18_0, arg_18_1)
	local var_18_0 = arg_18_1.y
	local var_18_1 = arg_18_1.x
	local var_18_2 = arg_18_0:getSpriteLayer(var_0_24)

	if not var_18_2 then
		return
	end

	local var_18_3 = var_18_2:getChildByName("fog_" .. var_18_0 .. var_18_1)

	if not var_18_3 then
		return
	end

	var_18_3:runActionOnce(cc.FadeOut:create(0.9), false, function()
		if not tolua.isnull(var_18_3) then
			var_18_3:removeFromParent()
		end
	end)
end

function var_0_0.addMapScrollNode(arg_20_0)
	local function var_20_0(arg_21_0)
		local var_21_0 = 0

		for iter_21_0, iter_21_1 in pairs(arg_21_0) do
			var_21_0 = var_21_0 + 1
		end

		return var_21_0
	end

	local var_20_1 = var_0_16 * var_0_15 * var_0_22
	local var_20_2 = var_0_17 * var_0_15 * var_0_22
	local var_20_3 = var_0_21 * var_0_15 * var_0_22
	local var_20_4 = var_0_23 * var_0_15 * var_0_22

	arg_20_0.touchPoints = {}
	arg_20_0.touchPoints[1] = {}
	arg_20_0.touchPoints[2] = {}

	local var_20_5 = display.newNode()

	var_20_5:addTo(arg_20_0.mapContainer)
	var_20_5:setContentSize(10000, 10000)
	var_20_5:setAllAtOnceTouchEnabled(true)
	var_20_5:setLocalZOrder(10000)
	var_20_5:setTouchSwallowEnabled(false)
	var_20_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_22_0)
		if arg_22_0.name == "began" then
			if not arg_20_0.isAnimating then
				arg_20_0.isStartMoving = false
				arg_20_0.touchPoints[1] = {}
				arg_20_0.touchPoints[2] = {}

				for iter_22_0, iter_22_1 in pairs(arg_22_0.points) do
					arg_20_0.touchPoints[1][tonumber(iter_22_1.id)] = iter_22_1
				end

				arg_20_0.mapTouchBeginX_ = arg_20_0.mapContainer:getX()
				arg_20_0.mapTouchBeginY_ = arg_20_0.mapContainer:getY()

				return true
			end

			return false
		elseif arg_22_0.name == "moved" then
			if arg_20_0.isAnimating then
				return
			end

			arg_20_0.isStartMoving = true

			for iter_22_2, iter_22_3 in pairs(arg_22_0.points) do
				if #arg_22_0.points == 1 then
					arg_20_0.touchPoints[2] = {}
					arg_20_0.touchPoints[2][0] = iter_22_3
				else
					arg_20_0.touchPoints[2][tonumber(iter_22_3.id)] = iter_22_3
				end
			end

			local function var_22_0(arg_23_0, arg_23_1)
				local var_23_0
				local var_23_1
				local var_23_2
				local var_23_3
				local var_23_4 = var_20_3 - var_20_1
				local var_23_5 = 0
				local var_23_6 = var_20_4 - var_20_2
				local var_23_7 = 0

				arg_23_0 = math.min(arg_23_0, var_23_5)
				arg_23_0 = math.max(arg_23_0, var_23_4)
				arg_23_1 = math.min(arg_23_1, var_23_7)
				arg_23_1 = math.max(arg_23_1, var_23_6)

				return arg_23_0, arg_23_1
			end

			if arg_20_0.touchPoints[2][0] and arg_20_0.touchPoints[1][0] and var_20_0(arg_20_0.touchPoints[1]) == 1 and var_20_0(arg_20_0.touchPoints[2]) == 1 then
				local var_22_1 = arg_20_0.touchPoints[2][0].x - arg_20_0.touchPoints[1][0].x
				local var_22_2 = arg_20_0.touchPoints[2][0].y - arg_20_0.touchPoints[1][0].y

				if (math.abs(var_22_1) > var_0_18 or math.abs(var_22_2) > var_0_18 or arg_20_0.isMoving_) and math.abs(var_22_1) < var_0_19 and math.abs(var_22_2) < var_0_19 then
					arg_20_0.isMoving_ = true

					local var_22_3 = arg_20_0.mapTouchBeginX_ + var_22_1
					local var_22_4 = arg_20_0.mapTouchBeginY_ + var_22_2
					local var_22_5, var_22_6 = var_22_0(var_22_3, var_22_4)

					arg_20_0.mapContainer:setPosition(var_22_5, var_22_6)
				end
			end

			return true
		elseif arg_22_0.name == "ended" then
			if arg_20_0.isAnimating then
				return
			end

			if arg_20_0.isMoving_ then
				arg_20_0.isStartMoving = false
				arg_20_0.isMoving_ = false

				arg_20_0:refreshTouchNode()
				arg_20_0:refreshMap()
			end
		end
	end)
end

function var_0_0.checkTouchOnFloor(arg_24_0, arg_24_1, arg_24_2, arg_24_3)
	return true
end

function var_0_0.createHeroModel(arg_25_0)
	local var_25_0 = arg_25_0.hero_id
	local var_25_1 = var_0_12:getHeroByTableID(var_25_0)

	if not var_25_1 then
		var_25_1 = var_0_2.new()

		var_25_1:populateWithTableID(var_25_0)
	end

	local var_25_2 = var_25_1:getHeroModel()

	var_25_2:setScale(xyd.tables.model:scale(var_25_1:getModelID()))

	arg_25_0.heroScale = xyd.tables.model:scale(var_25_1:getModelID())

	return var_25_2
end

function var_0_0.getRandomPath(arg_26_0, arg_26_1, arg_26_2, arg_26_3)
	local var_26_0 = arg_26_1 * arg_26_2 * arg_26_2 * (#arg_26_3 + 5)
	local var_26_1 = math.sin(var_26_0 * var_26_0)
	local var_26_2 = math.abs(var_26_1 + math.pi) * (#arg_26_3 + 997)
	local var_26_3 = var_26_2 * var_26_2

	math.randomseed(var_26_3)

	return arg_26_3[math.random(1, #arg_26_3)]
end

function var_0_0.findRoad(arg_27_0, arg_27_1, arg_27_2)
	local var_27_0 = {}
	local var_27_1 = {}
	local var_27_2 = {}

	table.insert(var_27_0, 1, {
		f = 0,
		h = 0,
		point = arg_27_1
	})

	local function var_27_3(arg_28_0)
		local var_28_0 = false

		for iter_28_0, iter_28_1 in ipairs(var_27_0) do
			if iter_28_1.point.x == arg_28_0.point.x and iter_28_1.point.y == arg_28_0.point.y then
				if iter_28_1.f > arg_28_0.f then
					table.remove(var_27_0, iter_28_0)

					break
				else
					return
				end
			end
		end

		for iter_28_2 = 1, #var_27_0 do
			if var_27_0[iter_28_2].f > arg_28_0.f then
				table.insert(var_27_0, iter_28_2, arg_28_0)

				var_28_0 = true

				break
			end
		end

		if not var_28_0 then
			table.insert(var_27_0, arg_28_0)
		end
	end

	local function var_27_4(arg_29_0, arg_29_1)
		return 0 + arg_29_1 + math.abs(arg_29_0.x - arg_27_2.x) + math.abs(arg_29_0.y - arg_27_2.y)
	end

	local function var_27_5(arg_30_0)
		if tonumber(arg_27_0.cellType[arg_30_0.point.y][arg_30_0.point.x]) == -1 or tonumber(arg_27_0.mazeFog[arg_30_0.point.y][arg_30_0.point.x]) == 1 then
			return true
		end

		return false
	end

	local function var_27_6(arg_31_0)
		if arg_31_0.point and type(arg_31_0.point) == "table" then
			if tonumber(arg_27_0.cellType[arg_31_0.point.y][arg_31_0.point.x]) > 0 and tonumber(var_0_13.eventIndex[arg_27_0:convertPositionToNum(arg_31_0.point)]) ~= 0 or tonumber(arg_27_0.mazeFog[arg_31_0.point.y][arg_31_0.point.x]) == 1 or tonumber(arg_27_0.cellType[arg_31_0.point.y][arg_31_0.point.x]) == -2 then
				return true
			end

			return false
		else
			if tonumber(arg_27_0.cellType[arg_31_0.y][arg_31_0.x]) > 0 and tonumber(var_0_13.eventIndex[arg_27_0:convertPositionToNum(arg_31_0)]) ~= 0 or tonumber(arg_27_0.mazeFog[arg_31_0.y][arg_31_0.x]) == 1 or tonumber(arg_27_0.cellType[arg_31_0.y][arg_31_0.x]) == -2 then
				return true
			end

			return false
		end
	end

	local function var_27_7(arg_32_0)
		if #arg_32_0 > 0 then
			for iter_32_0 = 1, #arg_32_0 do
				if var_27_6(arg_32_0[iter_32_0]) then
					for iter_32_1 = #arg_32_0, iter_32_0, -1 do
						table.remove(arg_32_0, iter_32_1)
					end

					break
				end
			end
		end
	end

	local function var_27_8(arg_33_0)
		for iter_33_0, iter_33_1 in ipairs(var_27_1) do
			if iter_33_1.point.x == arg_33_0.point.x and iter_33_1.point.y == arg_33_0.point.y then
				return true
			end
		end

		return false
	end

	if var_27_5({
		point = arg_27_2
	}) then
		return var_27_2
	end

	while true do
		if #var_27_0 == 0 then
			return var_27_2
		end

		local var_27_9 = var_27_0[1]

		table.remove(var_27_0, 1)
		table.insert(var_27_1, var_27_9)

		if arg_27_2.x == var_27_9.point.x and arg_27_2.y == var_27_9.point.y then
			local var_27_10 = var_27_9

			while true do
				if var_27_10.father then
					table.insert(var_27_2, 1, var_27_10.point)

					var_27_10 = var_27_10.father
				else
					break
				end
			end

			var_27_7(var_27_2)

			break
		end

		if var_27_9.point.x - 1 > 0 then
			local var_27_11 = 0

			if var_27_6({
				x = var_27_9.point.x - 1,
				y = var_27_9.point.y
			}) then
				var_27_11 = var_0_16 * var_0_17
			end

			local var_27_12 = {
				f = var_27_4({
					x = var_27_9.point.x - 1,
					y = var_27_9.point.y
				}, var_27_9.h + 1 + var_27_11),
				point = {
					x = var_27_9.point.x - 1,
					y = var_27_9.point.y
				},
				father = var_27_9,
				h = var_27_9.h + 1 + var_27_11
			}

			if not var_27_8(var_27_12) and not var_27_5(var_27_12) then
				var_27_3(var_27_12)
			end
		end

		if var_27_9.point.x + 1 <= var_0_16 then
			local var_27_13 = 0

			if var_27_6({
				x = var_27_9.point.x + 1,
				y = var_27_9.point.y
			}) then
				var_27_13 = var_0_16 * var_0_17
			end

			local var_27_14 = {
				f = var_27_4({
					x = var_27_9.point.x + 1,
					y = var_27_9.point.y
				}, var_27_9.h + 1 + var_27_13),
				point = {
					x = var_27_9.point.x + 1,
					y = var_27_9.point.y
				},
				father = var_27_9,
				h = var_27_9.h + 1 + var_27_13
			}

			if not var_27_8(var_27_14) and not var_27_5(var_27_14) then
				var_27_3(var_27_14)
			end
		end

		if var_27_9.point.y - 1 > 0 then
			local var_27_15 = 0

			if var_27_6({
				x = var_27_9.point.x,
				y = var_27_9.point.y - 1
			}) then
				var_27_15 = var_0_16 * var_0_17
			end

			local var_27_16 = {
				f = var_27_4({
					x = var_27_9.point.x,
					y = var_27_9.point.y - 1
				}, var_27_9.h + 1 + var_27_15),
				point = {
					x = var_27_9.point.x,
					y = var_27_9.point.y - 1
				},
				father = var_27_9,
				h = var_27_9.h + 1 + var_27_15
			}

			if not var_27_8(var_27_16) and not var_27_5(var_27_16) then
				var_27_3(var_27_16)
			end
		end

		if var_27_9.point.y + 1 <= var_0_17 then
			local var_27_17 = 0

			if var_27_6({
				x = var_27_9.point.x,
				y = var_27_9.point.y + 1
			}) then
				var_27_17 = var_0_16 * var_0_17
			end

			local var_27_18 = {
				f = var_27_4({
					x = var_27_9.point.x,
					y = var_27_9.point.y + 1
				}, var_27_9.h + 1 + var_27_17),
				point = {
					x = var_27_9.point.x,
					y = var_27_9.point.y + 1
				},
				father = var_27_9,
				h = var_27_9.h + 1 + var_27_17
			}

			if not var_27_8(var_27_18) and not var_27_5(var_27_18) then
				var_27_3(var_27_18)
			end
		end
	end

	return var_27_2
end

function var_0_0.moveModel(arg_34_0, arg_34_1, arg_34_2)
	if not arg_34_0.model or tolua.isnull(arg_34_0.model) then
		return
	end

	if arg_34_0.modelDialog and not tolua.isnull(arg_34_0.modelDialog) then
		arg_34_0.modelDialog:removeSelf()
	end

	transition.stopTarget(arg_34_0.model)

	local var_34_0 = {}
	local var_34_1 = {}

	for iter_34_0, iter_34_1 in ipairs(arg_34_2) do
		if iter_34_0 == 1 then
			if iter_34_1.x - arg_34_1.x == -1 then
				arg_34_0.faceTo = -1
			elseif iter_34_1.x - arg_34_1.x == 1 then
				arg_34_0.faceTo = 1
			end
		elseif iter_34_1.x - arg_34_2[iter_34_0 - 1].x == -1 then
			arg_34_0.faceTo = -1
		elseif iter_34_1.x - arg_34_2[iter_34_0 - 1].x == 1 then
			arg_34_0.faceTo = 1
		end

		local var_34_2 = cc.MoveTo:create(1, cc.p((iter_34_1.x - 0.5) * var_0_15, (iter_34_1.y - 0.8) * var_0_15 + var_0_14))
		local var_34_3 = cc.ScaleTo:create(0.1, arg_34_0.heroScale * arg_34_0.faceTo, arg_34_0.heroScale)
		local var_34_4 = cc.Spawn:create({
			var_34_2,
			var_34_3
		})

		var_34_0[iter_34_0] = cc.Sequence:create(var_34_4, cc.CallFunc:create(function()
			arg_34_0.currentPointX = iter_34_1.x
			arg_34_0.currentPointY = iter_34_1.y

			arg_34_0.model:setLocalZOrder(-iter_34_1.y * var_0_16 + iter_34_1.x)
			arg_34_0:refreshMap()
		end))
	end

	local var_34_5 = transition.sequence(var_34_0)

	arg_34_0.isAnimating = true

	arg_34_0.model:walk(true)
	arg_34_0.model:runActionOnce(var_34_5, false, function()
		arg_34_0.isAnimating = false

		arg_34_0.model:idle()
		arg_34_0:gridEvent({
			x = arg_34_0.eventPointX,
			y = arg_34_0.eventPointY
		})

		if arg_34_0.tempAwards then
			var_0_12:handleRewards(arg_34_0.tempAwards)

			arg_34_0.tempAwards = nil
		end
	end)
end

function var_0_0.gridEvent(arg_37_0, arg_37_1)
	if not arg_37_0 or tolua.isnull(arg_37_0) then
		return
	end

	var_0_13.autoEvent = false
	arg_37_1 = arg_37_1 or arg_37_0:convertNumToPosition(var_0_13.lastEventInfo.grid_id)

	if arg_37_1.x == 0 or arg_37_1.y == 0 then
		return
	end

	if not arg_37_0:isNeighBour({
		x = arg_37_0.currentPointX,
		y = arg_37_0.currentPointY
	}, arg_37_1) then
		return
	end

	if arg_37_0.cellType[arg_37_1.y][arg_37_1.x] == -2 then
		arg_37_0.modelDialog = xyd.AssetLoader.get():loadNodeFromJson("windows/dream_world/explore/dialog.csb")

		local var_37_0 = arg_37_0.modelDialog:getChildByName("container")

		var_37_0:getChildByName("text"):setString(xyd.tables.translation:translation("DREAM_WORLD_DOOR_TIP"))
		var_37_0:width(var_37_0:getChildByName("text"):getWidth() + 28)
		arg_37_0.modelDialog:setScaleY(1 / arg_37_0.heroScale)
		arg_37_0.modelDialog:setScaleX(1 / arg_37_0.heroScale * arg_37_0.faceTo)
		arg_37_0.modelDialog:addTo(arg_37_0.model)
		arg_37_0.modelDialog:setPositionY(arg_37_0.model:getHeight() + 5)
		arg_37_0:performWithDelay(function()
			if arg_37_0.modelDialog and not tolua.isnull(arg_37_0.modelDialog) then
				arg_37_0.modelDialog:removeSelf()
			end
		end, 2)

		return
	end

	local var_37_1 = arg_37_0:convertPositionToNum(arg_37_1)
	local var_37_2 = var_0_13.eventIndex[var_37_1]

	if var_37_2 ~= 0 then
		local var_37_3 = var_0_8:events(arg_37_0.cell[arg_37_1.y][arg_37_1.x])[var_37_2]
		local var_37_4 = var_0_9:eventType(var_37_3)
		local var_37_5 = {
			grid_id = arg_37_0:convertPositionToNum(arg_37_1),
			event_idx = var_37_2,
			map = arg_37_0:convertMapToArray(arg_37_0.mazeFog),
			pos = arg_37_0:convertPositionToNum({
				x = arg_37_0.currentPointX,
				y = arg_37_0.currentPointY
			})
		}

		var_0_13:setMapInfo(var_37_5)

		if var_37_4 == xyd.DreamWorldEventType.STORY then
			local var_37_6 = var_0_9:dialogueID(var_37_3)
			local var_37_7 = var_0_11:getReplaceDialogueID(var_37_6)

			for iter_37_0, iter_37_1 in ipairs(var_37_7) do
				local var_37_8 = true

				for iter_37_2, iter_37_3 in ipairs(iter_37_1.characterID) do
					if var_0_13.mapRoles[iter_37_3] < iter_37_1.favorMin[iter_37_2] then
						var_37_8 = false

						break
					end
				end

				if var_37_8 then
					var_37_6 = iter_37_1.replaceID

					break
				end
			end

			xyd.WindowManager.get():openWindow("dream_world_story", {
				dialogueID = var_37_6
			})
		elseif var_37_4 == xyd.DreamWorldEventType.BATTLE then
			xyd.WindowManager.get():openWindow("dream_world_enemy_detail", {
				eventID = var_37_3
			})
		elseif var_37_4 == xyd.DreamWorldEventType.AWARD then
			if arg_37_0:isBox(arg_37_1.x, arg_37_1.y) then
				local var_37_9 = arg_37_0.box[arg_37_1.y][arg_37_1.x]
				local var_37_10 = cc.Director:getInstance():getTextureCache():addImage(var_37_9.replacePath)

				if var_37_10 then
					var_37_9:setTexture(var_37_10)
				end

				if arg_37_0.canGetAward then
					arg_37_0.canGetAward = false

					arg_37_0:performWithDelay(function()
						var_0_13:dealEvent(var_37_5, handler(arg_37_0, arg_37_0.gridEvent))

						arg_37_0.canGetAward = true
					end, 1)
				end
			else
				var_0_13:dealEvent(var_37_5, handler(arg_37_0, arg_37_0.gridEvent))
			end
		end
	end
end

function var_0_0.getSpriteLayer(arg_40_0, arg_40_1)
	return arg_40_0.layers[arg_40_1]
end

function var_0_0.addSprite(arg_41_0, arg_41_1, arg_41_2, arg_41_3, arg_41_4, arg_41_5, arg_41_6, arg_41_7)
	if not arg_41_0.layers[arg_41_2] then
		arg_41_0.layers[arg_41_2] = display.newNode()

		arg_41_0.layers[arg_41_2]:addTo(arg_41_0.mapContainer, arg_41_2)
	end

	if not arg_41_0.sprites[arg_41_3] then
		arg_41_0.sprites[arg_41_3] = {}
	end

	if not arg_41_0.sprites[arg_41_3][arg_41_4] then
		arg_41_0.sprites[arg_41_3][arg_41_4] = {}
	end

	arg_41_1:addTo(arg_41_0.layers[arg_41_2], -arg_41_3 * var_0_16 + arg_41_4)

	if arg_41_0.mapNodes[arg_41_3] and arg_41_0.mapNodes[arg_41_3][arg_41_4] then
		arg_41_5 = arg_41_5 + arg_41_0.mapNodes[arg_41_3][arg_41_4]:getPositionX()
		arg_41_6 = arg_41_6 + arg_41_0.mapNodes[arg_41_3][arg_41_4]:getPositionY()
	end

	arg_41_1:setPosition(arg_41_5, arg_41_6)

	if not arg_41_7 then
		table.insert(arg_41_0.sprites[arg_41_3][arg_41_4], arg_41_1)
	end
end

function var_0_0.clearSprite(arg_42_0, arg_42_1, arg_42_2)
	if not arg_42_0.sprites[arg_42_1] or not arg_42_0.sprites[arg_42_1][arg_42_2] then
		return
	end

	local var_42_0 = arg_42_0.sprites[arg_42_1][arg_42_2]

	for iter_42_0 = 1, #var_42_0 do
		var_42_0[iter_42_0]:removeSelf()
	end

	arg_42_0.sprites[arg_42_1][arg_42_2] = {}
end

function var_0_0.isBox(arg_43_0, arg_43_1, arg_43_2)
	local var_43_0 = arg_43_0.cellType[arg_43_2][arg_43_1]

	return var_43_0 == 1 or var_43_0 == 2 or var_43_0 == 3
end

function var_0_0.needAddShadow(arg_44_0, arg_44_1, arg_44_2)
	local var_44_0 = arg_44_0.cellType[arg_44_2][arg_44_1]

	return var_44_0 == 1 or var_44_0 == 2 or var_44_0 == 3 or var_44_0 == 4 or var_44_0 == 5
end

function var_0_0.willClose(arg_45_0, arg_45_1)
	var_0_0.super.willClose(arg_45_0, arg_45_1)

	local var_45_0 = xyd.WindowManager.get():getWindow("dream_world_explore_menu")

	if var_45_0 and not tolua.isnull(var_45_0) then
		var_45_0:close()
	end

	local var_45_1 = xyd.WindowManager.get():getWindow("dream_world_diary")

	if var_45_1 and not tolua.isnull(var_45_1) then
		var_45_1:close()
	end

	local var_45_2 = xyd.WindowManager.get():getWindow("dream_world_collect")

	if var_45_2 and not tolua.isnull(var_45_2) then
		var_45_2:close()
	end
end

function var_0_0.updateMapInfo(arg_46_0)
	if var_0_13.mapType > 0 then
		var_0_13:updateMapInfo({
			map = arg_46_0:convertMapToArray(arg_46_0.mazeFog),
			pos = arg_46_0:convertPositionToNum({
				x = arg_46_0.currentPointX,
				y = arg_46_0.currentPointY
			})
		})
	end
end

function var_0_0.isNeighBour(arg_47_0, arg_47_1, arg_47_2)
	if arg_47_2.x - arg_47_1.x == 1 and arg_47_2.y == arg_47_1.y or arg_47_2.x - arg_47_1.x == -1 and arg_47_2.y == arg_47_1.y or arg_47_2.y - arg_47_1.y == 1 and arg_47_2.x == arg_47_1.x or arg_47_2.y - arg_47_1.y == -1 and arg_47_2.x == arg_47_1.x then
		return true
	end

	if arg_47_1.x == arg_47_2.x and arg_47_1.y == arg_47_2.y then
		return true
	end

	return false
end

return var_0_0
