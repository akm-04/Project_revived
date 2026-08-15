local var_0_0 = class("EventCentreMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.common.ui.WndTopSidebar")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.item

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setTouchSwallowEnabled(true)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.hasClickJunk = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:addTopSidebar()
	arg_2_0:layout()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.REFRESH_MAGIC_RES, function(arg_3_0)
		arg_2_0:updateTop()
	end)
end

function var_0_0.updateTop(arg_4_0)
	arg_4_0.dustNum:setString(xyd.num2ThousandsStr(arg_4_0.selfPlayer.magicDust))
	arg_4_0.liquidNum:setString(xyd.num2ThousandsStr(arg_4_0.selfPlayer.magicLiquid))
	arg_4_0.energyNum:setString(xyd.num2ThousandsStr(arg_4_0.selfPlayer.magicEnergy))
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	arg_5_0.dustNum:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_5_0.liquidNum:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_5_0.energyNum:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	var_0_0.super:didOpen(arg_5_1)

	if not arg_5_0.selfPlayer.backpackLoaded_ then
		arg_5_0.selfPlayer:loadBackpack(function(arg_6_0)
			if arg_6_0 == xyd.error.OK then
				arg_5_0.backpack_ = arg_5_0.selfPlayer:getBackpack()
			end
		end)
	else
		arg_5_0.backpack_ = arg_5_0.selfPlayer:getBackpack()
	end

	local var_5_0 = arg_5_0.backpack_:getItems()
	local var_5_1 = {}

	for iter_5_0, iter_5_1 in ipairs(var_5_0) do
		if var_0_4:subType(iter_5_1.itemID) == 12 then
			table.insert(var_5_1, {
				item_id = iter_5_1.itemID,
				item_num = iter_5_1.itemNum
			})
		end
	end

	if #var_5_1 > 0 then
		xyd.WindowManager.get():openWindow("event_centre_sell", {
			items = var_5_1
		})
	end
end

function var_0_0.layout(arg_7_0)
	arg_7_0:updateTop()
	xyd.nodeEventSample(arg_7_0:nodeByName("storage_btn"), nil, function(arg_8_0)
		xyd.playButtonSound()
		arg_7_0:enterJunkChest()
	end)
	xyd.nodeEventSample(arg_7_0:nodeByName("desk_btn"), nil, function(arg_9_0)
		xyd.playButtonSound()
		arg_7_0:enterDesk()
	end)
	xyd.nodeEventSample(arg_7_0:nodeByName("trash_btn"), nil, function(arg_10_0)
		xyd.playButtonSound()
		arg_7_0:enterTrash()
	end)
	arg_7_0:nodeByName("board_btn"):setVisible(false)
	xyd.nodeEventSample(arg_7_0:nodeByName("admin_btn"), nil, function(arg_11_0)
		xyd.playButtonSound()
		arg_7_0:enterAdmin()
	end)
	xyd.nodeEventSample(arg_7_0:nodeByName("bookshelf_btn"), nil, function(arg_12_0)
		xyd.playButtonSound()
		arg_7_0:enterBookShelf()
	end)
	xyd.nodeEventSample(arg_7_0:nodeByName("pet_room_btn"), nil, function(arg_13_0)
		xyd.playButtonSound()
		arg_7_0:enterPetRoom()
	end)
	arg_7_0:updateRedPointShow()
end

function var_0_0.addTopSidebar(arg_14_0)
	if not arg_14_0:background() then
		return
	end

	arg_14_0:setTouchEnabled(true)
	arg_14_0:setTouchSwallowEnabled(true)

	if arg_14_0:nodeByName("top_sidebar") then
		return
	end

	local var_14_0 = {
		isEcoBar = 0,
		show_rule = true,
		colorMode = arg_14_0.colorMode,
		parent = arg_14_0,
		title = xyd.tables.window:title(arg_14_0.name)
	}
	local var_14_1 = var_0_2.new(xyd.WidgetName.wndTopSidebar, var_14_0)

	var_14_1:setAnchorPoint(0, 1)
	var_14_1:addTo(arg_14_0:background())
	var_14_1:setPosition(arg_14_0:nodeByName("pos_top_sidebar"):getPosition())
	xyd.nodeEventSample(var_14_1:nodeByName("rule"), nil, function(arg_15_0)
		xyd.playButtonSound()

		local var_15_0 = {}

		var_15_0.title_name = "EVENT_CENTRE_RULE_TITLE"
		var_15_0.rule = "EVENT_CENTRE_RULE_TEXT"
		var_15_0.style = xyd.RuleStyle.GREEN

		xyd.WindowManager.get():openWindow("new_text_rule", var_15_0)
	end)

	arg_14_0.ecoSidebar = xyd.AssetLoader.get():loadNodeFromJson("windows/event_centre/main_sence/eco_sidebar.csb")

	local var_14_2 = arg_14_0.ecoSidebar:getChildByName("background")

	arg_14_0.dustNum = var_14_2:getChildByName("eco_dust"):getChildByName("dust_num")
	arg_14_0.liquidNum = var_14_2:getChildByName("eco_liquid"):getChildByName("liquid_num")
	arg_14_0.energyNum = var_14_2:getChildByName("eco_energy"):getChildByName("energy_num")

	arg_14_0.ecoSidebar:addTo(var_14_1:nodeByName("eco_sidebar"))
	arg_14_0.ecoSidebar:setAnchorPoint(0, 0)
	arg_14_0.ecoSidebar:setPosition(-125, 0)
	arg_14_0.ecoSidebar:setName("eco_sidebar")

	arg_14_0.children_.top_sidebar = var_14_1
	arg_14_0.children_.eco_sidebar = var_14_1:nodeByName("eco_sidebar")
end

function var_0_0.updateRedPointShow(arg_16_0)
	arg_16_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)

	for iter_16_0, iter_16_1 in pairs(xyd.EventCentreBuildingType) do
		local var_16_0 = arg_16_0.eventCentre.buidingInfo[tostring(iter_16_1)].new_evolve

		if var_16_0 and var_16_0 == 1 then
			arg_16_0:nodeByName("red_point" .. iter_16_1):setVisible(true)
		else
			arg_16_0:nodeByName("red_point" .. iter_16_1):setVisible(false)
		end
	end

	if arg_16_0.eventCentre.deskInfo.make_item and arg_16_0.eventCentre.deskInfo.make_item > 0 then
		arg_16_0:nodeByName("red_point" .. xyd.EventCentreBuildingType.DESK):setVisible(true)
	end

	if arg_16_0.eventCentre.recentCompleteSkill and arg_16_0.eventCentre.recentCompleteSkill ~= 0 then
		arg_16_0:nodeByName("red_point" .. xyd.EventCentreBuildingType.CABINET):setVisible(true)
	end

	if arg_16_0.eventCentre.petRoomInfo.make_item and arg_16_0.eventCentre.petRoomInfo.make_item > 0 then
		arg_16_0:nodeByName("red_point" .. xyd.EventCentreBuildingType.PETROOM):setVisible(true)
	end
end

function var_0_0.enterJunkChest(arg_17_0)
	arg_17_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.JUNKCHEST)

	arg_17_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)

	if arg_17_0.hasClickJunk then
		arg_17_0.eventCentre:getCabinetInfo(function(arg_18_0, arg_18_1)
			if arg_18_0 == xyd.error.OK then
				arg_17_0.hasClickJunk = true

				xyd.WindowManager.get():openWindow("junk_chest")
			end
		end)
	else
		arg_17_0.eventCentre:getCabinetInfo(function(arg_19_0, arg_19_1)
			if arg_19_0 == xyd.error.OK then
				arg_17_0.hasClickJunk = true

				xyd.WindowManager.get():openWindow("junk_chest")
			end
		end)
	end
end

function var_0_0.enterDesk(arg_20_0)
	arg_20_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.PRODUCT_TABLE)

	arg_20_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)

	arg_20_0.eventCentre:getDeskpInfo({}, function(arg_21_0, arg_21_1)
		if arg_21_0 == xyd.error.OK then
			xyd.WindowManager.get():openWindow("production_table")
		end
	end)
end

function var_0_0.enterTrash(arg_22_0)
	arg_22_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.RECYCLE)

	arg_22_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)

	arg_22_0.eventCentre:getRecycleInfo({}, function(arg_23_0, arg_23_1)
		if arg_23_0 == xyd.error.OK then
			local var_23_0 = {
				recycleInfo = arg_23_1
			}

			xyd.WindowManager.get():openWindow("recycle", var_23_0)
		end
	end)
end

function var_0_0.enterBoard(arg_24_0)
	arg_24_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)

	xyd.WindowManager.get():openWindow("board_main_window")
end

function var_0_0.enterAdmin(arg_25_0)
	arg_25_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.ADMIN)

	arg_25_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)

	arg_25_0.eventCentre:getAdminInfo({}, function(arg_26_0, arg_26_1)
		if arg_26_0 == xyd.error.OK then
			local var_26_0 = {
				adminInfo = arg_26_1
			}

			xyd.WindowManager.get():openWindow("event_admin", var_26_0)
		end
	end)
end

function var_0_0.enterBookShelf(arg_27_0)
	arg_27_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.BOOKSHELF)

	arg_27_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)

	arg_27_0.eventCentre:getBuildingList({}, function(arg_28_0, arg_28_1)
		if arg_28_0 == xyd.error.OK then
			local var_28_0 = {}
			local var_28_1 = arg_28_1.building_list[tostring(xyd.EventCentreBuildingType.BOOKSHELF)]

			xyd.WindowManager.get():openWindow("bookshelf", var_28_1)
		end
	end)
end

function var_0_0.enterPetRoom(arg_29_0)
	arg_29_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.PET_ROOM)

	arg_29_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)

	arg_29_0.eventCentre:getPetRoomInfo({}, function(arg_30_0, arg_30_1)
		if arg_30_0 == xyd.error.OK then
			xyd.WindowManager.get():openWindow("pet_room")
		end
	end)
end

function var_0_0.willClose(arg_31_0, arg_31_1)
	var_0_0.super.willClose(arg_31_1)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.UPDATE_HERO_BOOK
	})
end

return var_0_0
