local var_0_0 = class("SeasonAwardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.regionArena = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)
	arg_1_0.seasonCount = arg_1_2.count
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0
	local var_3_1
	local var_3_2
	local var_3_3
	local var_3_4 = xyd.tables.misc.regionArenaStartTime
	local var_3_5 = xyd.tables.misc.regionArenaEndTime
	local var_3_6 = string.sub(var_3_4, 1, 4)
	local var_3_7 = string.sub(var_3_4, 5, 6)
	local var_3_8 = string.sub(var_3_4, 7, 8)
	local var_3_9 = string.sub(var_3_5, 1, 4)
	local var_3_10 = string.sub(var_3_5, 5, 6)
	local var_3_11 = string.sub(var_3_5, 7, 8)
	local var_3_12 = var_3_6 .. var_0_1:translation("YEAR") .. var_3_7 .. var_0_1:translation("MONTH") .. var_3_8 .. var_0_1:translation("DAY")
	local var_3_13 = var_3_9 .. var_0_1:translation("YEAR") .. var_3_10 .. var_0_1:translation("MONTH") .. var_3_11 .. var_0_1:translation("DAY")

	arg_3_0:nodeByName("season_time"):setString(var_3_12 .. "-" .. var_3_13)

	local var_3_14 = xyd.tables.regionArenaNotice:getNoticeDescByOrder(1)
	local var_3_15 = xyd.tables.regionArenaNotice:getNoticeDescByOrder(2)
	local var_3_16 = xyd.tables.regionArenaNotice:getNoticeDescByOrder(3)
	local var_3_17 = arg_3_0:generateSeasonCount(arg_3_0.seasonCount)

	arg_3_0:nodeByName("title"):setString(string.format(var_0_1:translation("REGION_ARENA_TIP35"), var_3_17))
	arg_3_0:nodeByName("season_time_txt"):setString(var_0_1:translation("REGION_ARENA_TIP36"))
	arg_3_0:nodeByName("award_desc_1"):setString(string.format(var_0_1:translation("REGION_ARENA_TIP37"), var_3_14))
	arg_3_0:nodeByName("award_desc_2"):setString(string.format(var_0_1:translation("REGION_ARENA_TIP38"), var_3_15))
	arg_3_0:nodeByName("award_desc_3"):setString(string.format(var_0_1:translation("REGION_ARENA_TIP38"), var_3_16))

	local var_3_18 = xyd.tables.regionArenaNotice:getNoticeItemByOrder(1)
	local var_3_19 = xyd.tables.regionArenaNotice:getNoticeItemByOrder(2)
	local var_3_20 = xyd.tables.regionArenaNotice:getNoticeItemByOrder(3)

	xyd.setItemBorder(arg_3_0:nodeByName("award1"), var_3_18)
	arg_3_0:nodeByName("award_name_1"):setString(xyd.tables.item:name(var_3_18))
	xyd.setItemBorder(arg_3_0:nodeByName("award2"), var_3_19)
	arg_3_0:nodeByName("award_name_2"):setString(xyd.tables.item:name(var_3_19))
	xyd.setItemBorder(arg_3_0:nodeByName("award3"), var_3_20)
	arg_3_0:nodeByName("award_name_3"):setString(xyd.tables.item:name(var_3_20))
end

function var_0_0.generateSeasonCount(arg_4_0, arg_4_1)
	local var_4_0 = ""

	if arg_4_1 > 0 and arg_4_1 < 100 then
		local var_4_1 = math.floor(arg_4_1 / 10)
		local var_4_2 = arg_4_1 % 10

		if var_4_1 > 0 then
			if var_4_1 > 1 then
				var_4_0 = var_4_0 .. var_0_1:translation("TRADITION_NUM_" .. var_4_1) .. var_0_1:translation("TRADITION_NUM_10")
			else
				var_4_0 = var_4_0 .. var_0_1:translation("TRADITION_NUM_10")
			end
		end

		if var_4_2 == 0 and var_4_1 > 0 then
			var_4_2 = 10
		end

		if var_4_2 ~= 10 then
			var_4_0 = var_4_0 .. var_0_1:translation("TRADITION_NUM_" .. var_4_2)
		end

		return var_4_0
	else
		return nil
	end
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super:didOpen(arg_5_1)
	arg_5_0:addBlockLayer()
end

return var_0_0
