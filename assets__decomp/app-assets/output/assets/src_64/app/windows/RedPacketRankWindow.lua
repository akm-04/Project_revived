local var_0_0 = class("RedPacketRankWindow", import("app.windows.SnowRankWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.initCell(arg_1_0, arg_1_1, arg_1_2)
	local var_1_0 = arg_1_0.rankList[arg_1_2]
	local var_1_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/red_envelope/rank_item.csb")
	local var_1_2 = var_1_1:getChildByName("container")
	local var_1_3 = var_1_2:getContentSize()

	var_1_1:addTo(arg_1_1)
	arg_1_1:setContentSize(var_1_3)

	var_1_0.playerInfo = var_1_0

	xyd.setPlayerAvatar(var_1_2:getChildByName("avatar"), var_1_0)

	if var_1_0.conquer_lev and var_1_0.conquer_lev > 0 then
		xyd.setConquerLev(var_1_0.conquer_lev, var_1_2:getChildByName("text_lev"), var_1_2:getChildByName("level_bg"))
	else
		var_1_2:getChildByName("text_lev"):setString(var_1_0.lev)
	end

	var_1_2:getChildByName("text_name"):setString(var_1_0.player_name)
	var_1_2:getChildByName("text_region"):setString("S" .. xyd.getPlayerRegion(var_1_0.player_id))
	var_1_2:getChildByName("text_score_num"):setString(var_1_0.point)
	var_1_2:getChildByName("text_score"):setString(var_0_1:translation("RED_ENVELOPE_RANK_TIPS"))
	arg_1_0:initRankNum(var_1_2, arg_1_2)
end

function var_0_0.layout(arg_2_0)
	arg_2_0:nodeByName("text_rank"):enableOutline(cc.c4b(152, 22, 22, 255), 2)
	arg_2_0:nodeByName("text_score"):enableOutline(cc.c4b(152, 22, 22, 255), 2)
	arg_2_0:nodeByName("text_score_num"):enableOutline(cc.c4b(152, 22, 22, 255), 2)
	arg_2_0:nodeByName("text_rank"):setString(var_0_1:translation("SNOW_ACTIVITY_MY_RANK"))
	arg_2_0:nodeByName("text_score"):setString(var_0_1:translation("RED_ENVELOPE_RANK_TIPS"))
	arg_2_0:nodeByName("text_score_num"):setString(math.floor(arg_2_0.myRank.score or 0))

	if arg_2_0.myRank.rank and arg_2_0.myRank.rank > 0 then
		local var_2_0 = xyd.AssetLoader.get():loadLabel(nil, "inscription_lev")

		var_2_0:setString(math.floor(arg_2_0.myRank.rank or 0))
		var_2_0:setScale(1.5)
		var_2_0:addTo(arg_2_0:nodeByName("container"))

		local var_2_1 = cc.p(arg_2_0:nodeByName("my_rank_pos"):getPosition())

		var_2_0:setPosition(cc.p(var_2_1))
	end
end

return var_0_0
