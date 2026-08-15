local var_0_0 = class("ChangeEquipWnd", function()
	return xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1226/fishing/change_equip.csb")
end)
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc
local var_0_3 = xyd.tables.item
local var_0_4 = {
	FISHING_ROD = 1,
	FISHING_BAIT = 3,
	FISHINGHOOK = 2
}
local var_0_5 = {
	[var_0_4.FISHING_ROD] = "btn_rod",
	[var_0_4.FISHINGHOOK] = "btn_hook",
	[var_0_4.FISHING_BAIT] = "btn_bait"
}
local var_0_6 = {
	[var_0_4.FISHING_ROD] = xyd.mid.ACTIVITY_FISHING_CHANGE_ROD,
	[var_0_4.FISHINGHOOK] = xyd.mid.ACTIVITY_FISHING_CHANGE_HOOK,
	[var_0_4.FISHING_BAIT] = xyd.mid.ACTIVITY_FISHING_CHANGE_BAIT
}
local var_0_7 = {
	[var_0_4.FISHING_ROD] = "fishing_rod",
	[var_0_4.FISHINGHOOK] = "fishhook",
	[var_0_4.FISHING_BAIT] = "fishing_bait"
}
local var_0_8 = {
	[var_0_4.FISHING_ROD] = var_0_2:getValue("activity_fishing_rod_item_ids"),
	[var_0_4.FISHINGHOOK] = var_0_2:getValue("activity_fishhook_item_ids"),
	[var_0_4.FISHING_BAIT] = var_0_2:getValue("activity_fishing_bait_item_ids")
}

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.backpack = arg_2_0.selfPlayer:getBackpack()
	arg_2_0.params = arg_2_1

	arg_2_0:layout(arg_2_1)
	arg_2_0:addBlockLayer()
end

function var_0_0.layout(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_0:getChildByName("container")
	local var_3_1 = arg_3_0:getChildByName(var_0_5[arg_3_1.type_])
	local var_3_2 = var_3_0:getChildByName("bg")
	local var_3_3 = false

	arg_3_0.disX = var_3_0:getPositionX()

	var_3_1:setVisible(true)
	var_3_1:setTouchEnabled(true)

	local var_3_4 = var_0_8[arg_3_1.type_][arg_3_1.id]
	local var_3_5 = var_0_3:icon(var_3_4)
	local var_3_6 = xyd.SpriteLoader.new(var_3_5, nil, nil, xyd.DefaultImageType.ITEM_ICON, var_3_1:getChildByName("pos"))

	var_3_6:setNormalizedPosition(cc.p(0.5, 0.5))
	var_3_1:getChildByName("pos"):addChild(var_3_6)

	if var_3_1:getChildByName("txt") then
		local var_3_7 = arg_3_0.backpack:getItemNumByID(var_3_4)

		var_3_3 = true

		var_3_1:getChildByName("txt"):setString(var_3_7)
		var_3_1:getChildByName("txt"):enableOutline(cc.c4b(0, 88, 146, 255), 2)
	end

	var_3_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
		if arg_4_0.name == "began" then
			return true
		elseif arg_4_0.name == "ended" then
			arg_3_0:close()
		end
	end)

	for iter_3_0, iter_3_1 in ipairs(var_0_8[arg_3_1.type_]) do
		local var_3_8 = arg_3_0.backpack:getItemNumByID(iter_3_1)
		local var_3_9 = var_0_3:icon(iter_3_1)
		local var_3_10 = var_3_2:getChildByName("equip_" .. iter_3_0)
		local var_3_11

		if arg_3_1.type_ ~= var_0_4.FISHING_BAIT and iter_3_0 == 1 and var_3_8 == 0 then
			arg_3_0.backpack:setItemNumByID(iter_3_1, 1)

			var_3_8 = 1
		end

		if var_3_8 > 0 then
			var_3_11 = xyd.SpriteLoader.new(var_3_9, nil, nil, xyd.DefaultImageType.ITEM_ICON, var_3_10)
		else
			local var_3_12 = {
				filter = {}
			}

			var_3_12.filter.name = "GRAY"
			var_3_12.filter.value = {
				0.2,
				0.3,
				0.5,
				0.1
			}
			var_3_11 = xyd.SpriteLoader.new(var_3_9, nil, var_3_12, xyd.DefaultImageType.ITEM_ICON, var_3_10)
		end

		var_3_11:setNormalizedPosition(cc.p(0.5, 0.5))
		var_3_10:addChild(var_3_11)

		if var_3_3 then
			local var_3_13 = xyd.createLabel(20, cc.c3b(255, 255, 255))

			var_3_13:setAnchorPoint(0.5, 0.5)
			var_3_13:setPosition(37.5, 0)
			var_3_13:setString(var_3_8)
			var_3_13:enableOutline(cc.c4b(51, 31, 37, 255), 2)
			var_3_10:addChild(var_3_13)
		end

		var_3_10:addTouchEventListener(function(arg_5_0, arg_5_1)
			if arg_5_1 == ccui.TouchEventType.ended then
				if var_3_8 == 0 or iter_3_0 == arg_3_1.id then
					return
				end

				xyd.Backend.get():request(var_0_6[arg_3_1.type_], {
					id = iter_3_0
				}, function(arg_6_0, arg_6_1)
					if arg_6_0 == xyd.error.OK then
						arg_3_0:equip(iter_3_0)

						if arg_3_1.callback then
							arg_3_1.callback(iter_3_0)
						end

						arg_3_0:close()
					end
				end)
			end
		end)

		if iter_3_0 == arg_3_1.id then
			var_3_2:getChildByName("bg_equip_select_" .. iter_3_0):setVisible(true)
		end
	end

	var_3_2:setPositionX(-arg_3_0.disX)
	transition.moveBy(var_3_2, {
		easing = "sineOut",
		time = 0.3,
		y = 0,
		x = arg_3_0.disX,
		onComplete = function()
			return
		end
	})
	arg_3_0:setPosition(arg_3_1.x, arg_3_1.y)
	arg_3_1.parent:addChild(arg_3_0)
end

function var_0_0.equip(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_0:getChildByName("container"):getChildByName("bg")
	local var_8_1 = arg_8_0:getChildByName(var_0_5[arg_8_0.params.type_])
	local var_8_2 = var_0_8[arg_8_0.params.type_][arg_8_1]
	local var_8_3 = var_0_3:icon(var_8_2)
	local var_8_4 = xyd.SpriteLoader.new(var_8_3, nil, nil, xyd.DefaultImageType.ITEM_ICON, var_8_1:getChildByName("pos"))

	for iter_8_0 = 1, 3 do
		var_8_0:getChildByName("bg_equip_select_" .. iter_8_0):setVisible(false)
	end

	var_8_0:getChildByName("bg_equip_select_" .. arg_8_1):setVisible(true)
	var_8_1:getChildByName("pos"):removeAllChildren()
	var_8_4:setNormalizedPosition(cc.p(0.5, 0.5))
	var_8_1:getChildByName("pos"):addChild(var_8_4)

	if var_8_1:getChildByName("txt") then
		local var_8_5 = arg_8_0.backpack:getItemNumByID(var_8_2)

		var_8_1:getChildByName("txt"):setString(var_8_5)
	end
end

function var_0_0.addBlockLayer(arg_9_0)
	arg_9_0.blockLayer_ = display.newColorLayer(cc.c4b(0, 0, 0, 0))

	local var_9_0 = arg_9_0:convertToWorldSpace(cc.p(0, 0))

	arg_9_0.blockLayer_:pos(-var_9_0.x, -var_9_0.y):addTo(arg_9_0, -1)

	local function var_9_1(arg_10_0, arg_10_1)
		return true
	end

	local function var_9_2(arg_11_0, arg_11_1)
		arg_9_0:close()
	end

	arg_9_0.layerListener = cc.EventListenerTouchOneByOne:create()

	arg_9_0.layerListener:setSwallowTouches(true)
	arg_9_0.layerListener:registerScriptHandler(var_9_1, cc.Handler.EVENT_TOUCH_BEGAN)
	arg_9_0.layerListener:registerScriptHandler(var_9_2, cc.Handler.EVENT_TOUCH_ENDED)
	arg_9_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(arg_9_0.layerListener, arg_9_0)
end

function var_0_0.close(arg_12_0)
	local var_12_0 = arg_12_0:getChildByName("container"):getChildByName("bg")

	transition.moveBy(var_12_0, {
		easing = "sineIn",
		time = 0.3,
		y = 0,
		x = -arg_12_0.disX,
		onComplete = function()
			arg_12_0:removeFromParent()
		end
	})
end

local var_0_9 = class("ActivityFishingMainWindow", import("app.common.ui.BaseWindow"))
local var_0_10 = require("framework.scheduler")
local var_0_11 = import("app.common.ui.SpriteNodeButton")
local var_0_12 = import("app.common.ui.EcoDisplaySidebar")
local var_0_13 = xyd.tables.activityFish
local var_0_14 = {
	NORMAL = 1,
	STRONGLY_ROCK = 4,
	END = 5,
	PREPARE = 2,
	SLIGHTLY_ROCK = 3
}
local var_0_15 = var_0_2:getValue("activity_fishing_coin_item_id")

function var_0_9.ctor(arg_14_0, arg_14_1, arg_14_2)
	var_0_9.super.ctor(arg_14_0, arg_14_1, arg_14_2)

	arg_14_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_14_0.backpack = arg_14_0.selfPlayer:getBackpack()
	arg_14_0.fishingInfo = arg_14_2.fishing_info
	arg_14_0.shopInfo = arg_14_2.shop_info
	arg_14_0.stage = var_0_14.NORMAL
end

function var_0_9.willOpen(arg_15_0)
	arg_15_0:layout()
	arg_15_0:initBtns()
	arg_15_0:initTextString()
end

function var_0_9.layout(arg_16_0)
	local var_16_0 = {
		is_new = true,
		avatar_id = arg_16_0.selfPlayer:getMyCurrentAvatarID(),
		avatar_frame_id = arg_16_0.selfPlayer.avatarFrame
	}

	xyd.setPlayerAvatar(arg_16_0:nodeByName("player_avatar"), var_16_0)

	arg_16_0.model = xyd.createEffect("skeletons/ui_effect/activity_fishing/lvmeng", 0.25)

	arg_16_0.model:addTo(arg_16_0:nodeByName("pos_hero"))
	arg_16_0.model:play(nil, true, nil, "idle")

	local var_16_1 = {
		ecoCount = 1,
		colorMode = arg_16_0.colorMode,
		ecoTypes = {
			var_0_15
		},
		ecoIcons = {
			"windows/activities/1226/fishing/coin.png"
		}
	}

	arg_16_0.ecoSidebar = var_0_12.new(xyd.WidgetName.ecoDisplaySidebar, var_16_1)

	arg_16_0.ecoSidebar:setPosition(436, -46)
	arg_16_0:nodeByName("title"):addChild(arg_16_0.ecoSidebar)
	arg_16_0:updateBtnShow()
	arg_16_0:updateLevel()
end

function var_0_9.initBtns(arg_17_0)
	xyd.nodeEventSample(arg_17_0:nodeByName("btn_book"), nil, function()
		if arg_17_0.stage ~= var_0_14.NORMAL then
			return
		end

		xyd.Backend.get():request(xyd.mid.ACTIVITY_FISHING_COLLECT_INFO, nil, function(arg_19_0, arg_19_1)
			if arg_19_0 == xyd.error.OK then
				local var_19_0 = {}

				var_19_0.type_ = 1
				var_19_0.is_award = arg_19_1.is_award
				var_19_0.self_collect = arg_19_1.self_collect
				var_19_0.server_collect = arg_19_1.server_collect

				xyd.WindowManager.get():openWindow("activity_fishing_book", var_19_0)
			end
		end)
	end)
	xyd.nodeEventSample(arg_17_0:nodeByName("btn_shop"), nil, function()
		if arg_17_0.stage ~= var_0_14.NORMAL then
			return
		end

		local var_20_0 = {
			info = arg_17_0.shopInfo,
			lev = arg_17_0.lev
		}

		xyd.WindowManager.get():openWindow("activity_fishing_shop", var_20_0)
	end)
	xyd.nodeEventSample(arg_17_0:nodeByName("btn_start_1"), nil, function()
		arg_17_0:startGame()
	end)
	xyd.nodeEventSample(arg_17_0:nodeByName("btn_start_2"), nil, function()
		arg_17_0:startGame()
	end)
	xyd.nodeEventSample(arg_17_0:nodeByName("btn_end_1"), nil, function()
		if arg_17_0.stage == var_0_14.STRONGLY_ROCK then
			arg_17_0:endGame(true)
		elseif arg_17_0.stage == var_0_14.SLIGHTLY_ROCK then
			arg_17_0:endGame(false)
		end
	end)
	xyd.nodeEventSample(arg_17_0:nodeByName("btn_end_2"), nil, function()
		if arg_17_0.stage == var_0_14.STRONGLY_ROCK then
			arg_17_0:endGame(true)
		elseif arg_17_0.stage == var_0_14.SLIGHTLY_ROCK then
			arg_17_0:endGame(false)
		end
	end)
	xyd.nodeEventSample(arg_17_0:nodeByName("btn_rule"), nil, function()
		local var_25_0 = {
			title_name = "ACTIVITY_FISHING_RULE_TITLE",
			rule = "ACTIVITY_FISHING_RULE_TEXT"
		}

		xyd.WindowManager.get():openWindow("new_text_rule", var_25_0)
	end)

	for iter_17_0 = 1, 3 do
		local var_17_0 = arg_17_0:nodeByName(var_0_5[iter_17_0])

		arg_17_0:updateBtnIcon(iter_17_0)
		var_17_0:setTouchEnabled(true)
		var_17_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_26_0)
			if arg_26_0.name == "began" then
				return true
			elseif arg_26_0.name == "ended" then
				if arg_17_0.stage ~= var_0_14.NORMAL then
					return
				end

				local var_26_0 = {
					x = var_17_0:getPositionX(),
					y = var_17_0:getPositionY(),
					type_ = iter_17_0,
					parent = arg_17_0,
					id = arg_17_0.fishingInfo[var_0_7[iter_17_0]],
					callback = function(arg_27_0)
						if not arg_17_0 or tolua.isnull(arg_17_0) then
							return
						end

						arg_17_0.fishingInfo[var_0_7[iter_17_0]] = arg_27_0

						arg_17_0:updateBtnIcon(iter_17_0)
					end
				}

				var_0_0.new(var_26_0)
			end
		end)
	end

	local var_17_1 = var_0_11.new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(xyd.ColorMode.BLUE)
	})

	var_17_1:addTo(arg_17_0:nodeByName("title"))
	var_17_1:setAnchorPoint(0.5, 0.5)
	var_17_1:setPosition(43, -23)
	var_17_1:addTouchEvent(function(arg_28_0)
		if arg_28_0.name == "ended" then
			if arg_17_0.stage == var_0_14.NORMAL then
				arg_17_0:close()
			else
				local var_28_0 = var_0_1:translation("ACTIVITY_FISHING_TEXT_5")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_28_0, function()
					xyd.WindowManager.get():closeWindow("activity_fishing_success")
					xyd.WindowManager.get():closeWindow("activity_fishing_failure")
					arg_17_0:close()
				end)
			end
		end
	end)
end

function var_0_9.initTextString(arg_30_0)
	arg_30_0:nodeByName("txt_lv"):enableOutline(cc.c4b(51, 31, 37, 255), 2)
	arg_30_0:nodeByName("btn_bait"):getChildByName("txt"):enableOutline(cc.c4b(0, 88, 146, 255), 2)
	arg_30_0:nodeByName("txt_title"):setString(var_0_1:translation("ACTIVITY_FISHING_TEXT_1"))
	arg_30_0:nodeByName("txt_tips"):setString(var_0_1:translation("ACTIVITY_FISHING_TEXT_2"))
	arg_30_0:nodeByName("txt_book"):setString(var_0_1:translation("ACTIVITY_FISHING_TEXT_3"))
	arg_30_0:nodeByName("txt_shop"):setString(var_0_1:translation("ACTIVITY_FISHING_TEXT_4"))
end

function var_0_9.startGame(arg_31_0)
	if arg_31_0.stage ~= var_0_14.NORMAL then
		return
	end

	local var_31_0 = var_0_8[var_0_4.FISHING_BAIT][arg_31_0.fishingInfo.fishing_bait]

	if arg_31_0.backpack:getItemNumByID(var_31_0) <= 0 then
		local var_31_1 = var_0_1:translation("ACTIVITY_FISHING_TEXT_6")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_31_1
		})

		return
	end

	arg_31_0.stage = var_0_14.PREPARE

	arg_31_0:updateBtnShow()
	xyd.Backend.get():request(xyd.mid.ACTIVITY_FISHING_START, nil, function(arg_32_0, arg_32_1)
		if arg_32_0 == xyd.error.OK then
			local var_32_0 = var_0_8[var_0_4.FISHING_BAIT][arg_31_0.fishingInfo.fishing_bait]

			arg_31_0.backpack:addItemsByID(var_32_0, -1)
			arg_31_0:updateBaitNum()

			arg_31_0.co = coroutine.create(function()
				arg_31_0.model:play(function()
					if not arg_31_0 or tolua.isnull(arg_31_0) then
						return
					end

					coroutine.resume(arg_31_0.co)
				end, nil, nil, "start")
				coroutine.yield()
				arg_31_0.model:play(nil, true, nil, "idle")
				var_0_10.performWithDelayGlobal(function()
					if not arg_31_0 or tolua.isnull(arg_31_0) then
						return
					end

					coroutine.resume(arg_31_0.co)
				end, math.random(5, 20) / 10)
				coroutine.yield()

				arg_31_0.stage = var_0_14.SLIGHTLY_ROCK

				for iter_33_0 = 1, math.random(1, 3) do
					arg_31_0.model:play(function()
						if not arg_31_0 or tolua.isnull(arg_31_0) or arg_31_0.stage ~= var_0_14.SLIGHTLY_ROCK then
							return
						end

						coroutine.resume(arg_31_0.co)
					end, nil, nil, "reaction1")
					coroutine.yield()
				end

				arg_31_0.stage = var_0_14.STRONGLY_ROCK

				arg_31_0:nodeByName("txt_tips"):setString(var_0_1:translation("ACTIVITY_FISHING_TEXT_38"))
				arg_31_0.model:play(function()
					if not arg_31_0 or tolua.isnull(arg_31_0) or arg_31_0.stage ~= var_0_14.STRONGLY_ROCK then
						return
					end

					coroutine.resume(arg_31_0.co)
				end, nil, nil, "reaction2")
				coroutine.yield()
				arg_31_0:endGame(false)
			end)

			coroutine.resume(arg_31_0.co)
		end
	end)
end

function var_0_9.endGame(arg_38_0, arg_38_1)
	if arg_38_0.stage ~= var_0_14.SLIGHTLY_ROCK and arg_38_0.stage ~= var_0_14.STRONGLY_ROCK then
		return
	end

	arg_38_0:nodeByName("txt_tips"):setString(var_0_1:translation("ACTIVITY_FISHING_TEXT_2"))

	if arg_38_1 then
		arg_38_0.stage = var_0_14.END

		arg_38_0.model:play(function()
			if not arg_38_0 or tolua.isnull(arg_38_0) then
				return
			end

			arg_38_0.model:play(nil, true, nil, "idle")
			xyd.Backend.get():request(xyd.mid.ACTIVITY_FISHING_END, {
				is_success = 1
			}, function(arg_40_0, arg_40_1)
				if arg_40_0 == xyd.error.OK then
					if not arg_38_0 or tolua.isnull(arg_38_0) then
						return
					end

					local var_40_0 = var_0_13:price(tonumber(arg_40_1.fish_id))

					arg_38_0.backpack:addItemsByID(var_0_15, var_40_0)
					arg_38_0:updateEco()

					local var_40_1 = var_0_13:exp(tonumber(arg_40_1.fish_id))

					arg_38_0.fishingInfo.fishing_exp = arg_38_0.fishingInfo.fishing_exp + var_40_1

					arg_38_0:updateLevel()
					xyd.WindowManager.get():openWindow("activity_fishing_success", arg_40_1)

					arg_38_0.stage = var_0_14.NORMAL

					arg_38_0:updateBtnShow()
				end
			end)
		end, nil, nil, "success")
	else
		arg_38_0.stage = var_0_14.END

		arg_38_0.model:play(function()
			if not arg_38_0 or tolua.isnull(arg_38_0) then
				return
			end

			arg_38_0.model:play(nil, true, nil, "idle")
			xyd.Backend.get():request(xyd.mid.ACTIVITY_FISHING_END, {
				is_success = 0
			}, function(arg_42_0, arg_42_1)
				if arg_42_0 == xyd.error.OK then
					if not arg_38_0 or tolua.isnull(arg_38_0) then
						return
					end

					xyd.WindowManager.get():openWindow("activity_fishing_failure")

					arg_38_0.stage = var_0_14.NORMAL

					arg_38_0:updateBtnShow()
				end
			end)
		end, nil, nil, "fail")
	end
end

function var_0_9.updateBtnIcon(arg_43_0, arg_43_1)
	local var_43_0 = arg_43_0:nodeByName(var_0_5[arg_43_1])
	local var_43_1 = var_0_8[arg_43_1][arg_43_0.fishingInfo[var_0_7[arg_43_1]]]
	local var_43_2 = var_0_3:icon(var_43_1)
	local var_43_3 = xyd.SpriteLoader.new(var_43_2, nil, nil, xyd.DefaultImageType.ITEM_ICON, var_43_0:getChildByName("pos"))

	if var_43_0:getChildByName("txt") then
		local var_43_4 = arg_43_0.backpack:getItemNumByID(var_43_1)

		var_43_0:getChildByName("txt"):setString(var_43_4)
	end

	var_43_3:setNormalizedPosition(cc.p(0.5, 0.5))
	var_43_0:getChildByName("pos"):removeAllChildren()
	var_43_0:getChildByName("pos"):addChild(var_43_3)
end

function var_0_9.updateEco(arg_44_0)
	arg_44_0.ecoSidebar:update({
		true
	})
end

function var_0_9.updateBaitNum(arg_45_0)
	local var_45_0 = var_0_8[var_0_4.FISHING_BAIT][arg_45_0.fishingInfo.fishing_bait]
	local var_45_1 = arg_45_0.backpack:getItemNumByID(var_45_0)

	arg_45_0:nodeByName("btn_bait"):getChildByName("txt"):setString(var_45_1)
end

function var_0_9.updateBtnShow(arg_46_0)
	local var_46_0 = arg_46_0.stage == var_0_14.NORMAL

	arg_46_0:nodeByName("btn_start_1"):setVisible(var_46_0)
	arg_46_0:nodeByName("btn_start_2"):setVisible(var_46_0)
	arg_46_0:nodeByName("btn_end_1"):setVisible(not var_46_0)
	arg_46_0:nodeByName("btn_end_2"):setVisible(not var_46_0)
end

function var_0_9.updateLevel(arg_47_0)
	local var_47_0 = 1
	local var_47_1 = arg_47_0.fishingInfo.fishing_exp
	local var_47_2 = var_0_2:getValue("activity_fishing_levels_exp")

	for iter_47_0, iter_47_1 in ipairs(var_47_2) do
		if iter_47_1 <= var_47_1 then
			var_47_0 = var_47_0 + 1
			var_47_1 = var_47_1 - iter_47_1
		else
			break
		end
	end

	arg_47_0.lev = var_47_0

	arg_47_0:nodeByName("txt_lv"):setString("LV." .. var_47_0)

	if var_47_0 <= #var_47_2 then
		arg_47_0:nodeByName("txt_exp"):setString(var_47_1 .. "/" .. var_47_2[var_47_0])
		arg_47_0:nodeByName("bar"):setPercent(100 * var_47_1 / var_47_2[var_47_0])
	else
		arg_47_0:nodeByName("txt_exp"):setString(var_0_1:translation("ACTIVITY_FISHING_TEXT_7"))
		arg_47_0:nodeByName("bar"):setPercent(100)
	end
end

return var_0_9
