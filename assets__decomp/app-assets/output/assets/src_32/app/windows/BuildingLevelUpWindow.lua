local var_0_0 = class("LevelUpWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.type = arg_1_2.type
	arg_1_0.lev = arg_1_2.lev
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	local var_4_0
	local var_4_1

	if arg_4_0.type == xyd.EventCentreBuildingType.TRASH then
		buildingTable = xyd.tables.eventCentreRecycleTable
	elseif arg_4_0.type == xyd.EventCentreBuildingType.DESK then
		buildingTable = xyd.tables.eventCentreProductionTable
	elseif arg_4_0.type == xyd.EventCentreBuildingType.CABINET then
		buildingTable = xyd.tables.cabinetTable
	elseif arg_4_0.type == xyd.EventCentreBuildingType.ADMIN then
		buildingTable = xyd.tables.eventAdminTable
	elseif arg_4_0.type == xyd.EventCentreBuildingType.BOOKSHELF then
		buildingTable = xyd.tables.bookShelfTable
	elseif arg_4_0.type == xyd.EventCentreBuildingType.BOARD then
		buildingTable = xyd.tables.eventCentreNoticeBoardTable
	elseif arg_4_0.type == xyd.EventCentreBuildingType.PETROOM then
		buildingTable = xyd.tables.eventCentrePetRoom
	end

	local var_4_2 = buildingTable:desc(arg_4_0.lev - 1)
	local var_4_3 = buildingTable:desc(arg_4_0.lev)

	for iter_4_0 = 1, #var_4_2 do
		arg_4_0:nodeByName("org_desc_" .. iter_4_0):setString(var_4_2[iter_4_0])
	end

	for iter_4_1 = 1, #var_4_3 do
		arg_4_0:nodeByName("new_desc_" .. iter_4_1):setString(var_4_3[iter_4_1])
	end

	arg_4_0:nodeByName("lv_1"):setString("Lv  " .. arg_4_0.lev - 1)
	arg_4_0:nodeByName("lv_2"):setString("Lv  " .. arg_4_0.lev)

	local var_4_4 = xyd.tables.eventCentreTable:icon(arg_4_0.type)

	xyd.setSpriteBorder(arg_4_0:nodeByName("building_icon1"), var_4_4, xyd.ItemQuality.White)
	xyd.setSpriteBorder(arg_4_0:nodeByName("building_icon2"), var_4_4, xyd.ItemQuality.White)
end

return var_0_0
