local var_0_0 = class("EventCentreUpgradeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.type = arg_1_2.type
	arg_1_0.lev = arg_1_2.lev
	arg_1_0.canNotUpgrade = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("past_lev_txt"):setString("LV" .. arg_3_0.lev)
	arg_3_0:nodeByName("new_lev_txt"):setString("LV" .. arg_3_0.lev + 1)
	arg_3_0:nodeByName("title_txt"):setString(xyd.tables.eventCentreTable:name(arg_3_0.type))
	arg_3_0:nodeByName("require_text"):setString(var_0_1:translation("REQUIRE_TEXT"))
	arg_3_0:nodeByName("time_text"):setString(var_0_1:translation("TIME_TEXT"))
	arg_3_0:nodeByName("consume_text"):setString(var_0_1:translation("CONSUME_TEXT"))

	local var_3_0
	local var_3_1
	local var_3_2
	local var_3_3
	local var_3_4
	local var_3_5
	local var_3_6
	local var_3_7

	if arg_3_0.type == xyd.EventCentreBuildingType.TRASH then
		var_3_0 = xyd.tables.eventCentreRecycleTable
	elseif arg_3_0.type == xyd.EventCentreBuildingType.DESK then
		var_3_0 = xyd.tables.eventCentreProductionTable
	elseif arg_3_0.type == xyd.EventCentreBuildingType.CABINET then
		var_3_0 = xyd.tables.cabinetTable
	elseif arg_3_0.type == xyd.EventCentreBuildingType.ADMIN then
		var_3_0 = xyd.tables.eventAdminTable
	elseif arg_3_0.type == xyd.EventCentreBuildingType.BOOKSHELF then
		var_3_0 = xyd.tables.bookShelfTable
	elseif arg_3_0.type == xyd.EventCentreBuildingType.BOARD then
		var_3_0 = xyd.tables.eventCentreNoticeBoardTable
	elseif arg_3_0.type == xyd.EventCentreBuildingType.PETROOM then
		var_3_0 = xyd.tables.eventCentrePetRoom
	end

	local var_3_8 = var_3_0:desc(arg_3_0.lev)
	local var_3_9 = var_3_0:desc(arg_3_0.lev + 1)
	local var_3_10 = var_3_0:resourcesId(arg_3_0.lev)
	local var_3_11 = var_3_0:resourcesNum(arg_3_0.lev)
	local var_3_12 = var_3_0:typeRequest(arg_3_0.lev)
	local var_3_13 = var_3_0:functionRequestLevel(arg_3_0.lev)
	local var_3_14 = xyd.tables.eventCentreTable:name(var_3_12)

	arg_3_0:nodeByName("require_txt"):setString(var_3_14 .. var_3_13 .. var_0_1:translation("LEV_TEXT"))

	if var_3_13 > arg_3_0.eventCentre.buidingInfo[tostring(var_3_12)].lev then
		arg_3_0:nodeByName("require_txt"):setColor(cc.c3b(255, 0, 0))

		arg_3_0.canNotUpgrade = true
	end

	local var_3_15 = var_3_0:time(arg_3_0.lev)
	local var_3_16 = xyd.secondsToString1(var_3_15)

	arg_3_0:nodeByName("time_txt"):setString(var_3_16)

	for iter_3_0 = 1, #var_3_8 do
		arg_3_0:nodeByName("org_desc_" .. iter_3_0):setString(var_3_8[iter_3_0])
	end

	for iter_3_1 = 1, #var_3_9 do
		arg_3_0:nodeByName("new_desc_" .. iter_3_1):setString(var_3_9[iter_3_1])
	end

	local var_3_17 = arg_3_0:createItemsContent(var_3_10, var_3_11)

	var_3_17:setAnchorPoint(cc.p(0, 0.5))
	var_3_17:addTo(arg_3_0:nodeByName("consume_pos"))
	var_3_17:setPosition(cc.p(0, 0))

	if arg_3_0.canNotUpgrade == true then
		arg_3_0:nodeByName("upgrade_btn"):setVisible(false)
	end

	xyd.nodeEventSample(arg_3_0:nodeByName("upgrade_btn"), nil, function(arg_4_0)
		local var_4_0 = {
			type = arg_3_0.type
		}

		arg_3_0.eventCentre:upgradeBuilding(var_4_0, function(arg_5_0, arg_5_1)
			if arg_5_0 == xyd.error.OK then
				if arg_5_1.type == xyd.EventCentreBuildingType.CABINET then
					local var_5_0 = xyd.WindowManager.get():getWindow("junk_chest")

					arg_3_0.eventCentre.cabinetStartTime = arg_5_1.start_time
					arg_3_0.eventCentre.cabinetNeedTime = arg_5_1.need_time
					arg_3_0.eventCentre.cabinetLev = arg_5_1.lev

					var_5_0:updateUpgradeTime()
				elseif arg_5_1.type == xyd.EventCentreBuildingType.DESK then
					local var_5_1 = xyd.WindowManager.get():getWindow("production_table")

					var_5_1.deskInfo.building_info.start_time = arg_5_1.start_time
					var_5_1.deskInfo.building_info.need_time = arg_5_1.need_time
					var_5_1.deskInfo.building_info.lev = arg_5_1.lev

					var_5_1:initialVariable()
					var_5_1:update()
				elseif arg_5_1.type == xyd.EventCentreBuildingType.TRASH then
					local var_5_2 = xyd.WindowManager.get():getWindow("recycle")

					var_5_2.recycleInfo.building_info.start_time = arg_5_1.start_time
					var_5_2.recycleInfo.building_info.need_time = arg_5_1.need_time
					var_5_2.recycleInfo.building_info.lev = arg_5_1.lev

					var_5_2:initialVariable()
					var_5_2:update()
				elseif arg_5_1.type == xyd.EventCentreBuildingType.BOOKSHELF then
					local var_5_3 = xyd.WindowManager.get():getWindow("bookshelf")

					var_5_3.bookShelfInfo = arg_5_1

					var_5_3:init()
				elseif arg_5_1.type == xyd.EventCentreBuildingType.ADMIN then
					local var_5_4 = xyd.WindowManager.get():getWindow("event_admin")

					arg_3_0.eventCentre.adminStartTime = arg_5_1.start_time
					arg_3_0.eventCentre.adminNeedTime = arg_5_1.need_time
					arg_3_0.eventCentre.adminLev = arg_5_1.lev

					var_5_4:updateUpgradeTime()
				elseif arg_5_1.type == xyd.EventCentreBuildingType.BOARD then
					local var_5_5 = xyd.WindowManager.get():getWindow("board_main_window")

					arg_3_0.eventCentre.boardStartTime = arg_5_1.start_time
					arg_3_0.eventCentre.boardNeedTime = arg_5_1.need_time
					arg_3_0.eventCentre.boardLev = arg_5_1.lev

					var_5_5:updateUpgradeTime()
				elseif arg_5_1.type == xyd.EventCentreBuildingType.PETROOM then
					local var_5_6 = xyd.WindowManager.get():getWindow("pet_room")

					var_5_6.petRoomInfo.building_info.start_time = arg_5_1.start_time
					var_5_6.petRoomInfo.building_info.need_time = arg_5_1.need_time
					var_5_6.petRoomInfo.building_info.lev = arg_5_1.lev

					var_5_6:initialVariable()
					var_5_6:update()
				end

				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.REFRESH_MAGIC_RES
				})
				xyd.WindowManager.get():closeWindow(arg_3_0)
			end
		end)
	end)
end

function var_0_0.createItemsContent(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = display.newNode()
	local var_6_1 = -30
	local var_6_2 = 25

	for iter_6_0 = 1, #arg_6_1 do
		var_6_1 = var_6_1 + 30

		local var_6_3

		if arg_6_1[iter_6_0] == 11 then
			var_6_3 = "images/icon/eco/magic_dust_small.png"
		elseif arg_6_1[iter_6_0] == 12 then
			var_6_3 = "images/icon/eco/magic_liquid_small.png"
		elseif arg_6_1[iter_6_0] == 13 then
			var_6_3 = "images/icon/eco/magic_energy_small.png"
		elseif arg_6_1[iter_6_0] == 14 then
			var_6_3 = "images/icon/eco/magic_exp.png"
		end

		local var_6_4

		if var_6_3 then
			var_6_4 = xyd.AssetLoader.get():loadSprite(var_6_3)
		end

		var_6_4:addTo(var_6_0)
		var_6_4:setAnchorPoint(0, 0.5)
		var_6_4:setPosition(var_6_1, var_6_2)

		var_6_1 = var_6_1 + var_6_4:getContentSize().width + 10

		local var_6_5

		if iter_6_0 == 1 and arg_6_0.selfPlayer.magicDust < arg_6_2[iter_6_0] or iter_6_0 == 2 and arg_6_0.selfPlayer.magicLiquid < arg_6_2[iter_6_0] or iter_6_0 == 3 and arg_6_0.selfPlayer.magicEnergy < arg_6_2[iter_6_0] or iter_6_0 == 4 and arg_6_0.selfPlayer.magicExp < arg_6_2[iter_6_0] then
			var_6_5 = cc.c3b(255, 0, 0)
			arg_6_0.canNotUpgrade = true
		end

		local var_6_6 = arg_6_0:createItemNumLabel(arg_6_2[iter_6_0], var_6_5)

		var_6_6:addTo(var_6_0)
		var_6_6:setAnchorPoint(0, 0.5)
		var_6_6:setPosition(var_6_1, var_6_2)

		var_6_1 = var_6_1 + var_6_6:getContentSize().width
	end

	var_6_0:setContentSize(var_6_1, 50)

	return var_6_0
end

function var_0_0.createItemNumLabel(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = {
		font = "fonts/main_font.ttf",
		size = 22,
		color = arg_7_2 or cc.c3b(65, 121, 205)
	}
	local var_7_1 = xyd.AssetLoader.get():loadLabel(var_7_0)

	var_7_1:setMaxLineWidth(250)
	var_7_1:setString(arg_7_1)

	return var_7_1
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	var_0_0.super:didOpen(arg_8_1)
	arg_8_0:addBlockLayer()
end

return var_0_0
