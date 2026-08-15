local var_0_0 = class("AcademyArenaDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.ACADEMY_ARENA)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.container1 = arg_2_0:nodeByName("bg1")
	arg_2_0.container2 = arg_2_0:nodeByName("bg2")
	arg_2_0.playerBtn = arg_2_0:nodeByName("player_btn")
	arg_2_0.buffBtn = arg_2_0:nodeByName("buff_btn")

	arg_2_0:changeStatus(true)
	arg_2_0.playerBtn:addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			arg_2_0:changeStatus(true)
		end
	end)
	arg_2_0.buffBtn:addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			arg_2_0:changeStatus(false)
		end
	end)
	arg_2_0:nodeByName("title1"):enableOutline(cc.c4b(22, 82, 191, 255), 2)
	arg_2_0:nodeByName("title1"):setString(var_0_1:translation("ACADEMY_ARENA_DETAIL_TITLE"))
	arg_2_0:nodeByName("name_row"):setString(var_0_1:translation("ACADEMY_ARENA_DETAIL_NAME"))
	arg_2_0:nodeByName("land_row"):setString(var_0_1:translation("ACADEMY_ARENA_DETAIL_LAND"))
	arg_2_0:nodeByName("server_row"):setString(var_0_1:translation("ACADEMY_ARENA_DETAIL_SERVER"))
	arg_2_0:nodeByName("title2"):enableOutline(cc.c4b(22, 82, 191, 255), 2)
	arg_2_0:nodeByName("title2"):setString(var_0_1:translation("ACADEMY_ARENA_DETAIL_TITLE2"))

	local var_2_0 = 0

	for iter_2_0, iter_2_1 in pairs(arg_2_0.model.enermyInfo) do
		local var_2_1 = arg_2_0.model:getColor2(iter_2_1.base_map_id)

		if var_2_1 then
			local var_2_2 = tonumber(iter_2_0)

			var_2_0 = var_2_0 + 1

			local var_2_3 = arg_2_0:nodeByName("name" .. var_2_0)

			var_2_3:enableOutline(cc.c4b(0, 0, 0, 255), 1)
			var_2_3:setColor(var_2_1)
			var_2_3:setString(iter_2_1.player_name)
			var_2_3:getChildByName("land_num"):enableOutline(cc.c4b(0, 0, 0, 255), 1)
			var_2_3:getChildByName("land_num"):setString(arg_2_0.model.score[var_2_2])
			var_2_3:getChildByName("server"):enableOutline(cc.c4b(0, 0, 0, 255), 1)
			var_2_3:getChildByName("server"):setString("S" .. math.floor(var_2_2 / 100000))
		end
	end

	local var_2_4 = xyd.split(var_0_1:translation("ACADEMY_ARENA_BUFF"), ",")

	for iter_2_2, iter_2_3 in ipairs(var_2_4) do
		local var_2_5 = arg_2_0:nodeByName("buff" .. iter_2_2)

		if iter_2_2 <= arg_2_0.model.buffCount then
			var_2_5:setColor(cc.c3b(0, 255, 0))
		end

		var_2_5:setString(iter_2_3)
	end
end

function var_0_0.changeStatus(arg_5_0, arg_5_1)
	local var_5_0 = not arg_5_1

	arg_5_0.container1:setVisible(arg_5_1)
	arg_5_0.container2:setVisible(var_5_0)
	arg_5_0.playerBtn:setTouchEnabled(var_5_0)
	arg_5_0.playerBtn:setBright(var_5_0)
	arg_5_0.buffBtn:setTouchEnabled(arg_5_1)
	arg_5_0.buffBtn:setBright(arg_5_1)
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	arg_6_0:addBlockLayer()
end

return var_0_0
