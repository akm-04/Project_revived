local var_0_0 = class("AcademyArenaWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc
local var_0_3 = xyd.tables.academyArenaMap
local var_0_4 = xyd.tables.academyArenaResource
local var_0_5 = 2
local var_0_6 = 1
local var_0_7 = 50
local var_0_8 = {
	END_SIGN_UP = 2,
	END = 4,
	SIGN_UP = 1,
	BATTLE = 3
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.ACADEMY_ARENA)
	arg_1_0.arrowList = {}
	arg_1_0.resourceItems = {}
	arg_1_0.teamNumItem = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:initMap()
	arg_2_0.model:getInfo(function()
		arg_2_0:updateStage()
	end)
end

function var_0_0.layout(arg_4_0, arg_4_1)
	arg_4_0.topContainer = arg_4_0:nodeByName("top_container")
	arg_4_0.bottomContainer = arg_4_0:nodeByName("bg_bottom")

	arg_4_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("activity_gacha_rule", {
				rule = "ACADEMY_ARENA_RULE_TEXT",
				title = "ACADEMY_ARENA_RULE_TITLE"
			})
		end
	end)
	arg_4_0:nodeByName("award_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadShopList({}, function()
				xyd.WindowManager.get():openWindow("shop", {
					shop_type = xyd.ShopType.ACADEMY_ARENA
				})
			end)
		end
	end)
	arg_4_0:nodeByName("record_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			arg_4_0.model:getRecordList(function()
				xyd.WindowManager.get():openWindow("academy_arena_record")
			end)
		end
	end)
	arg_4_0:addBlock(arg_4_0:nodeByName("close"))
	arg_4_0:addBlock(arg_4_0.topContainer)
end

function var_0_0.initMap(arg_10_0)
	local var_10_0 = arg_10_0:nodeByName("map_container")
	local var_10_1 = var_10_0:getContentSize()

	arg_10_0.map = xyd.AssetLoader.get():loadNodeFromJson("windows/academy_arena/academy_map.csb")

	arg_10_0.map:addTo(var_10_0)

	arg_10_0.mapScale = var_0_6
	arg_10_0.scrollNode = arg_10_0.map:getChildByName("bg")

	local var_10_2
	local var_10_3
	local var_10_4 = arg_10_0.scrollNode:getContentSize()

	arg_10_0.scrollNode:setTouchEnabled(true)
	arg_10_0.scrollNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
		if arg_11_0.name == "began" then
			arg_10_0.mapMoved = false

			if arg_10_0.mapScale == var_0_5 then
				var_10_2, var_10_3 = arg_11_0.x, arg_11_0.y

				return true
			end
		elseif arg_11_0.name == "moved" then
			if math.abs(arg_11_0.x - var_10_2) > var_0_7 or math.abs(arg_11_0.y - var_10_3) > var_0_7 then
				arg_10_0.mapMoved = true
			end

			local var_11_0, var_11_1 = arg_10_0.map:getPosition()

			arg_10_0.map:setPosition(math.max(var_10_1.width - var_10_4.width * arg_10_0.mapScale, math.min(0, var_11_0 + arg_11_0.x - arg_11_0.prevX)), math.max(var_10_1.height - var_10_4.height * arg_10_0.mapScale, math.min(0, var_11_1 + arg_11_0.y - arg_11_0.prevY)))
		end
	end)

	local var_10_5 = arg_10_0:nodeByName("zoom_in_btn")
	local var_10_6 = arg_10_0:nodeByName("zoom_out_btn")

	var_10_6:setBright(false)
	var_10_6:setTouchEnabled(false)
	arg_10_0:addBlock(var_10_5)
	arg_10_0:addBlock(var_10_6)

	local var_10_7 = -640
	local var_10_8 = -320

	var_10_5:addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			arg_10_0.mapScale = var_0_5

			arg_10_0.map:setScale(var_0_5)
			arg_10_0.map:setPosition(var_10_7, var_10_8)
			var_10_5:setBright(false)
			var_10_5:setTouchEnabled(false)
			var_10_6:setBright(true)
			var_10_6:setTouchEnabled(true)
			arg_10_0:setItemsVisible(arg_10_0.resourceItems, false)
			arg_10_0:setItemsVisible(arg_10_0.arrowList, true)
			arg_10_0:setItemsVisible(arg_10_0.teamNumItem, true)
		end
	end)
	var_10_6:addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			arg_10_0.mapScale = var_0_6

			arg_10_0.map:setScale(var_0_6)

			var_10_7, var_10_8 = arg_10_0.map:getPosition()

			arg_10_0.map:setPosition(0, 0)
			var_10_5:setBright(true)
			var_10_5:setTouchEnabled(true)
			var_10_6:setBright(false)
			var_10_6:setTouchEnabled(false)
			arg_10_0:setItemsVisible(arg_10_0.arrowList, false)
			arg_10_0:setItemsVisible(arg_10_0.teamNumItem, false)
			arg_10_0:setItemsVisible(arg_10_0.resourceItems, true)
		end
	end)
end

function var_0_0.initBattle(arg_14_0)
	local var_14_0 = arg_14_0:nodeByName("visible_btn1")
	local var_14_1 = arg_14_0:nodeByName("visible_btn2")

	var_14_0:setVisible(true)
	var_14_0:addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			var_14_0:setVisible(false)
			var_14_1:setVisible(true)
			arg_14_0.topContainer:setVisible(false)
			arg_14_0.bottomContainer:setVisible(false)
		end
	end)
	var_14_1:addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.ended then
			var_14_0:setVisible(true)
			var_14_1:setVisible(false)
			arg_14_0.topContainer:setVisible(true)
			arg_14_0.bottomContainer:setVisible(true)
		end
	end)
	arg_14_0:addBlock(var_14_0)
	arg_14_0:addBlock(var_14_1)
	arg_14_0:nodeByName("round_num"):setString(string.format(var_0_1:translation(arg_14_0.model.phase == 1 and "ACADEMY_ARENA_ROUND_ORDER" or "ACADEMY_ARENA_ROUND_READY"), arg_14_0.model.round))
	arg_14_0:initFog()

	local var_14_2 = var_0_3:getIds()

	for iter_14_0, iter_14_1 in ipairs(var_14_2) do
		local var_14_3 = arg_14_0.scrollNode:getChildByName(iter_14_1)

		var_14_3:setVisible(true)
		var_14_3:getChildByName("light"):setVisible(false)

		if arg_14_0.model:isOwned(iter_14_1) then
			var_14_3:getChildByName("gray"):setVisible(false)
			arg_14_0:createTeamNumItem(iter_14_1)
		else
			local var_14_4 = arg_14_0.model:getColor(iter_14_1)

			if var_14_4 then
				local var_14_5 = var_14_3:getChildByName("color")

				var_14_5:setVisible(true)
				var_14_5:setColor(var_14_4)
			end
		end

		if not arg_14_0.fogVisible[var_0_3:type(iter_14_1)] and arg_14_0.model.areaInfo[tostring(iter_14_1)].start_production > 0 then
			arg_14_0:createResourceItem(iter_14_1, arg_14_0.model:isOwned(iter_14_1))
		end

		local var_14_6 = var_14_3:getContentSize()
		local var_14_7 = var_14_3:getRotationSkewX() / 180 * math.pi
		local var_14_8 = cc.p(var_14_3:getPosition())
		local var_14_9 = cc.p(var_14_8.x - (math.cos(var_14_7) * var_14_6.width + math.sin(var_14_7) * var_14_6.height) / 2, var_14_8.y + (math.sin(var_14_7) * var_14_6.width - math.cos(var_14_7) * var_14_6.height) / 2)
		local var_14_10 = cc.p(var_14_9.x + math.cos(var_14_7) * var_14_6.width, var_14_9.y - math.sin(var_14_7) * var_14_6.width)
		local var_14_11 = cc.p(var_14_10.x + math.sin(var_14_7) * var_14_6.height, var_14_10.y + math.cos(var_14_7) * var_14_6.height)
		local var_14_12 = cc.p(var_14_9.x + math.sin(var_14_7) * var_14_6.height, var_14_9.y + math.cos(var_14_7) * var_14_6.height)
		local var_14_13 = cc.Node:create()

		var_14_13:setContentSize(var_14_6.width, var_14_6.height)
		var_14_13:addTo(var_14_3)
		var_14_13:setTouchEnabled(true)
		var_14_13:setTouchSwallowEnabled(false)
		var_14_13:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_17_0)
			if arg_17_0.name == "began" then
				local var_17_0 = cc.p(arg_17_0.x, arg_17_0.y)
				local var_17_1 = arg_14_0.scrollNode:convertToNodeSpace(var_17_0)

				if arg_14_0:getCross(var_14_9, var_14_10, var_17_1) * arg_14_0:getCross(var_14_11, var_14_12, var_17_1) >= 0 and arg_14_0:getCross(var_14_10, var_14_11, var_17_1) * arg_14_0:getCross(var_14_12, var_14_9, var_17_1) >= 0 then
					return true
				end
			elseif arg_17_0.name == "ended" and not arg_14_0.mapMoved then
				if arg_14_0.actStatus then
					arg_14_0:actMove(iter_14_1)
				else
					if not arg_14_0.model:isOwned(iter_14_1) then
						return
					end

					var_14_3:getChildByName("light"):setVisible(true)
					xyd.WindowManager.get():openWindow("academy_arena_command", {
						mapId = iter_14_1,
						callback = function()
							var_14_3:getChildByName("light"):setVisible(false)
						end
					})
				end
			end
		end)
	end

	arg_14_0:setItemsVisible(arg_14_0.teamNumItem, false)
	arg_14_0:updateArrow()
end

function var_0_0.getCross(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	return (arg_19_2.x - arg_19_1.x) * (arg_19_3.y - arg_19_1.y) - (arg_19_3.x - arg_19_1.x) * (arg_19_2.y - arg_19_1.y)
end

function var_0_0.setAct(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	arg_20_0.actStatus = arg_20_1
	arg_20_0.actFrom = arg_20_2
	arg_20_0.actTeams = arg_20_3
	arg_20_0.highLightArea = {}
	arg_20_0.moveTarget = arg_20_1 == 1 and var_0_3:adj(arg_20_0.actFrom) or var_0_3:move(arg_20_0.actFrom)

	for iter_20_0, iter_20_1 in ipairs(arg_20_0.moveTarget) do
		local var_20_0 = arg_20_0.model:isOwned(iter_20_1)

		if arg_20_1 == 1 ~= var_20_0 then
			local var_20_1 = arg_20_0.scrollNode:getChildByName(iter_20_1)

			if var_20_1 then
				local var_20_2 = xyd.AssetLoader.get():loadSprite("windows/academy_arena/map/" .. iter_20_1 .. "_light.png")

				var_20_2:setColor(arg_20_1 == 1 and cc.c3b(255, 0, 0) or cc.c3b(0, 255, 0))

				local var_20_3, var_20_4 = var_20_1:getChildByName("light"):getPosition()
				local var_20_5 = var_20_1:getChildByName("light"):getRotationSkewX()

				var_20_2:addTo(var_20_1)
				var_20_2:setPosition(var_20_3, var_20_4)
				var_20_2:setRotation(var_20_5)
				table.insert(arg_20_0.highLightArea, var_20_2)
			end
		end
	end
end

function var_0_0.removeHighLight(arg_21_0)
	for iter_21_0, iter_21_1 in ipairs(arg_21_0.highLightArea) do
		iter_21_1:removeSelf()
	end
end

function var_0_0.actMove(arg_22_0, arg_22_1)
	if arg_22_0.actFrom == arg_22_1 then
		arg_22_0.actStatus = nil

		arg_22_0:removeHighLight()

		local var_22_0 = xyd.WindowManager.get():getWindow("academy_arena_command")

		if var_22_0 then
			var_22_0:setVisible(true)
		end

		return
	end

	if arg_22_0.actStatus == 1 then
		if arg_22_0.model:isOwned(arg_22_1) then
			arg_22_0:openToast("ACADEMY_ARENA_ATTACK_TIP")

			return
		end

		if var_0_3:manor(arg_22_1) > 0 then
			arg_22_0:openToast("ACADEMY_ARENA_IS_BORN_AREA")

			return
		end
	else
		if not arg_22_0.model:isOwned(arg_22_1) then
			arg_22_0:openToast("ACADEMY_ARENA_MOVE_TIP")

			return
		end

		if var_0_3:manor(arg_22_1) > 0 then
			arg_22_0:openToast("ACADEMY_ARENA_MOVE_BASE")

			return
		end
	end

	local var_22_1 = false

	for iter_22_0, iter_22_1 in ipairs(arg_22_0.moveTarget) do
		if iter_22_1 == arg_22_1 then
			var_22_1 = true
		end
	end

	if not var_22_1 then
		arg_22_0:openToast("ACADEMY_ARENA_CANNOT_MOVE")

		return
	end

	if #arg_22_0.actTeams * var_0_3:cost(arg_22_1) > arg_22_0.model.playerInfo.action_point then
		arg_22_0:openToast("ACADEMY_ARENA_ACTION_NOT_ENOUGH")

		return
	end

	arg_22_0.model:move(arg_22_0.actFrom, arg_22_1, arg_22_0.actTeams, function()
		arg_22_0.actStatus = nil

		arg_22_0:removeHighLight()
		xyd.WindowManager.get():closeWindow("academy_arena_command")
		arg_22_0:updateBottom()
		arg_22_0:updateArrow()
	end)
end

function var_0_0.updateStage(arg_24_0)
	local var_24_0 = arg_24_0:nodeByName("sign_up_btn")
	local var_24_1 = arg_24_0:nodeByName("round_num")

	if arg_24_0.model.stage == var_0_8.BATTLE then
		if arg_24_0.model.hasSignup > 0 then
			arg_24_0:initBottom()
			arg_24_0:initBattle()
		else
			var_24_1:setString(var_0_1:translation("ACADEMY_ARENA_NOT_SIGN_UP"))
		end
	elseif arg_24_0.model.stage == var_0_8.END_SIGN_UP then
		if arg_24_0.model.hasSignup > 0 then
			var_24_1:setString(var_0_1:translation("ACADEMY_ARENA_SIGN_UP_END"))
			var_24_0:setVisible(true)
			var_24_0:getChildByName("txt"):setVisible(false)
			var_24_0:setTouchEnabled(false)
			var_24_0:setBright(false)
			var_24_0:getChildByName("gray_txt"):setVisible(true)
		else
			var_24_1:setString(var_0_1:translation("ACADEMY_ARENA_NOT_SIGN_UP"))
		end
	elseif arg_24_0.model.stage == var_0_8.SIGN_UP then
		var_24_0:setVisible(true)

		if arg_24_0.model.stage == var_0_8.END_SIGN_UP then
			var_24_1:setString(var_0_1:translation("ACADEMY_ARENA_SIGN_UP_END"))
		else
			var_24_1:setString(var_0_1:translation("ACADEMY_ARENA_SIGN_UP"))

			if arg_24_0.model.hasSignup > 0 then
				var_24_0:getChildByName("txt"):setVisible(false)
				var_24_0:setTouchEnabled(false)
				var_24_0:setBright(false)
				var_24_0:getChildByName("gray_txt"):setVisible(true)
			else
				var_24_0:addTouchEventListener(function(arg_25_0, arg_25_1)
					if arg_25_1 == ccui.TouchEventType.ended then
						arg_24_0.model:signup(function(arg_26_0)
							var_24_0:getChildByName("txt"):setVisible(false)
							var_24_0:setTouchEnabled(false)
							var_24_0:setBright(false)
							var_24_0:getChildByName("gray_txt"):setVisible(true)
						end)
					end
				end)
			end
		end
	else
		var_24_1:setString(var_0_1:translation("ACADEMY_ARENA_END"))
	end

	arg_24_0:nodeByName("detail_btn"):addTouchEventListener(function(arg_27_0, arg_27_1)
		if arg_27_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_24_0.model.stage == var_0_8.SIGN_UP then
				arg_24_0:openToast("ACADEMY_ARENA_DETAIL_TIP_SIGN_UP")

				return
			elseif arg_24_0.model.hasSignup == 0 then
				arg_24_0:openToast("ACADEMY_ARENA_DETAIL_TIP_SIGN_UP_NOT")

				return
			end

			xyd.WindowManager.get():openWindow("academy_arena_detail")
		end
	end)
end

function var_0_0.initBottom(arg_28_0)
	arg_28_0:updateBottom()
	arg_28_0:nodeByName("recurit_btn"):addTouchEventListener(function(arg_29_0, arg_29_1)
		if arg_29_1 == ccui.TouchEventType.ended then
			arg_28_0.model:getRecruitList(function()
				xyd.WindowManager.get():openWindow("academy_arena_recruit", {})
			end)
		end
	end)
	arg_28_0.bottomContainer:setVisible(true)
	arg_28_0:addBlock(arg_28_0.bottomContainer)

	arg_28_0.tipWindow = arg_28_0:nodeByName("bg_tip")

	arg_28_0:showTipEvent(arg_28_0:nodeByName("icon_action_point"), "windows/academy_arena/icon_action_p.png", "ACADEMY_ARENA_CANDY_TITLE", "ACADEMY_ARENA_CANDY_TEXT", 150, 245)
	arg_28_0:showTipEvent(arg_28_0:nodeByName("icon_summon_point"), "windows/academy_arena/icon_summon_p.png", "ACADEMY_ARENA_WATER_TITLE", "ACADEMY_ARENA_WATER_TEXT", 500, 245)
	arg_28_0:showTipEvent(arg_28_0:nodeByName("icon_agility_point"), "windows/academy_arena/icon_agility_p.png", "ACADEMY_ARENA_FLOWER_TITLE", "ACADEMY_ARENA_FLOWER_TEXT", 700, 245)
end

function var_0_0.showTipEvent(arg_31_0, arg_31_1, arg_31_2, arg_31_3, arg_31_4, arg_31_5, arg_31_6)
	arg_31_1:setTouchEnabled(true)
	arg_31_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_32_0)
		if arg_32_0.name == "began" then
			arg_31_0.tipWindow:setVisible(true)
			arg_31_0.tipWindow:getChildByName("icon"):loadTexture(arg_31_2)
			arg_31_0.tipWindow:getChildByName("title"):setString(var_0_1:translation(arg_31_3))
			arg_31_0.tipWindow:getChildByName("content"):setString(var_0_1:translation(arg_31_4))
			arg_31_0.tipWindow:setPosition(arg_31_5, arg_31_6)

			return true
		elseif arg_32_0.name == "ended" then
			arg_31_0.tipWindow:setVisible(false)
		end
	end)
end

function var_0_0.updateBottom(arg_33_0)
	arg_33_0:nodeByName("action_point"):setString(arg_33_0.model.playerInfo.action_point .. "/" .. var_0_2.academyApUpper)
	arg_33_0:nodeByName("summon_point"):setString(arg_33_0.model.playerInfo.summon_point .. "/" .. var_0_2.academySpUpper)
	arg_33_0:nodeByName("agility_point"):setString(arg_33_0.model.playerInfo.agility_point)

	local var_33_0, var_33_1 = arg_33_0.model:getResourceInc()

	arg_33_0:nodeByName("action_point_inc"):setString("(+" .. var_33_0 .. ")")
	arg_33_0:nodeByName("summon_point_inc"):setString("(+" .. var_33_1 .. ")")
	arg_33_0:nodeByName("agility_point_inc"):setString("(-" .. arg_33_0.model.playerInfo.sx_num .. ")")
end

function var_0_0.addBlock(arg_34_0, arg_34_1)
	local var_34_0 = arg_34_1:getContentSize()
	local var_34_1 = cc.Node:create()

	var_34_1:addTo(arg_34_1, -1)
	var_34_1:setContentSize(var_34_0)
	var_34_1:setTouchEnabled(true)
end

function var_0_0.updateArrow(arg_35_0)
	for iter_35_0, iter_35_1 in ipairs(arg_35_0.arrowList) do
		iter_35_1:removeSelf()

		iter_35_1 = nil
	end

	arg_35_0.arrowList = {}

	for iter_35_2, iter_35_3 in ipairs(arg_35_0.model.commandList) do
		local var_35_0 = cc.p(arg_35_0.scrollNode:getChildByName(iter_35_3.from_id):getPosition())
		local var_35_1 = cc.p(arg_35_0.scrollNode:getChildByName(iter_35_3.to_id):getPosition())
		local var_35_2 = math.sqrt((var_35_0.x - var_35_1.x) * (var_35_0.x - var_35_1.x) + (var_35_0.y - var_35_1.y) * (var_35_0.y - var_35_1.y))
		local var_35_3

		if arg_35_0.model:isOwned(iter_35_3.to_id) then
			var_35_3 = display.newScale9Sprite("windows/academy_arena/arrow_move.png", 0, 0, cc.size(var_35_2, 13), cc.rect(15, 6, 1, 1))
		else
			var_35_3 = display.newScale9Sprite("windows/academy_arena/arrow_attack.png", 0, 0, cc.size(var_35_2, 13), cc.rect(15, 6, 1, 1))
		end

		var_35_3:setAnchorPoint(cc.p(0, 0.5))

		local var_35_4 = math.asin((var_35_0.y - var_35_1.y) / var_35_2) / math.pi * 180

		if var_35_1.x < var_35_0.x then
			var_35_4 = 180 - var_35_4
		end

		var_35_3:setRotation(var_35_4)
		var_35_3:setPosition(var_35_0.x, var_35_0.y)
		var_35_3:addTo(arg_35_0.scrollNode)
		table.insert(arg_35_0.arrowList, var_35_3)
	end

	if arg_35_0.mapScale == var_0_6 then
		arg_35_0:setItemsVisible(arg_35_0.arrowList, false)
	end
end

function var_0_0.createTeamNumItem(arg_36_0, arg_36_1)
	local var_36_0 = arg_36_0.model.areaInfo[tostring(arg_36_1)]
	local var_36_1 = cc.p(arg_36_0.scrollNode:getChildByName(arg_36_1):getPosition())
	local var_36_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/academy_arena/team_num.csb")

	if var_36_0.hasV then
		var_36_2:getChildByName("icon1"):setVisible(true)
	else
		var_36_2:getChildByName("icon2"):setVisible(true)
	end

	var_36_2:getChildByName("num"):setString(#var_36_0.teams)
	var_36_2:addTo(arg_36_0.scrollNode)
	var_36_2:setPosition(var_36_1.x, var_36_1.y)
	table.insert(arg_36_0.teamNumItem, var_36_2)

	if arg_36_1 == arg_36_0.model.baseMapId then
		arg_36_0.baseTeamNum = var_36_2
	end
end

function var_0_0.createResourceItem(arg_37_0, arg_37_1, arg_37_2)
	local var_37_0 = cc.p(arg_37_0.scrollNode:getChildByName(arg_37_1):getPosition())
	local var_37_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/academy_arena/area_resource.csb")
	local var_37_2 = 1
	local var_37_3 = arg_37_0.model.areaInfo[tostring(arg_37_1)].land_id
	local var_37_4 = arg_37_0.model.occupy[var_0_3:type(arg_37_1)]

	if var_0_4:agilityPoint(var_37_3) > 0 then
		arg_37_0:resourceItemLayout(var_37_1:getChildByName("icon" .. var_37_2), "windows/academy_arena/icon_agility_p.png", var_0_4:agilityPoint(var_37_3), arg_37_2, var_37_4)

		var_37_2 = var_37_2 + 1
	end

	if var_0_4:summonPoint(var_37_3) > 0 then
		arg_37_0:resourceItemLayout(var_37_1:getChildByName("icon" .. var_37_2), "windows/academy_arena/icon_summon_p.png", var_0_4:summonPoint(var_37_3), arg_37_2, var_37_4)

		var_37_2 = var_37_2 + 1
	end

	if var_0_4:actionPoint(var_37_3) > 0 then
		arg_37_0:resourceItemLayout(var_37_1:getChildByName("icon" .. var_37_2), "windows/academy_arena/icon_action_p.png", var_0_4:actionPoint(var_37_3), arg_37_2, var_37_4)

		local var_37_5 = var_37_2 + 1
	end

	var_37_1:addTo(arg_37_0.scrollNode)
	var_37_1:setPosition(var_37_0.x, var_37_0.y)
	table.insert(arg_37_0.resourceItems, var_37_1)
end

function var_0_0.resourceItemLayout(arg_38_0, arg_38_1, arg_38_2, arg_38_3, arg_38_4, arg_38_5)
	arg_38_1:setVisible(true)
	arg_38_1:loadTexture(arg_38_2)

	if arg_38_4 then
		local var_38_0 = arg_38_1:getChildByName("num")

		if arg_38_5 then
			var_38_0:setColor(cc.c3b(0, 255, 0))

			arg_38_3 = arg_38_3 * 2
		end

		var_38_0:setString(arg_38_3)
	end
end

function var_0_0.setItemsVisible(arg_39_0, arg_39_1, arg_39_2)
	for iter_39_0, iter_39_1 in ipairs(arg_39_1) do
		iter_39_1:setVisible(arg_39_2)
	end
end

function var_0_0.initFog(arg_40_0)
	arg_40_0.fogVisible = {}

	for iter_40_0 = 1, 16 do
		arg_40_0.fogVisible[iter_40_0] = true
	end

	for iter_40_1, iter_40_2 in ipairs(arg_40_0.model.visitedList) do
		local var_40_0 = clone(var_0_3:adj(iter_40_2))

		table.insert(var_40_0, iter_40_2)

		for iter_40_3, iter_40_4 in ipairs(var_40_0) do
			if var_0_3:type(iter_40_4) > 0 then
				arg_40_0.fogVisible[var_0_3:type(iter_40_4)] = false
			end
		end
	end

	for iter_40_5, iter_40_6 in ipairs(arg_40_0.fogVisible) do
		arg_40_0.scrollNode:getChildByName("fog" .. iter_40_5):setVisible(iter_40_6)
	end
end

function var_0_0.openToast(arg_41_0, arg_41_1)
	xyd.WindowManager.get():closeWindow("toast")
	xyd.WindowManager.get():openWindow("toast", {
		message = var_0_1:translation(arg_41_1)
	})
end

return var_0_0
