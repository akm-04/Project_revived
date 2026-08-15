local var_0_0 = class("PeakTeamInfoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = "arena_team_info"
local var_0_2 = import("app.model.Pet")
local var_0_3 = import("app.common.ui.SplitLine")
local var_0_4 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.rank = arg_1_2.rank
	arg_1_0.playerInfo = arg_1_2.playerInfo
	arg_1_0.teams = arg_1_2.teams
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.playerName = arg_2_0:nodeByName("text_player_name")

	arg_2_0.playerName:setString(arg_2_0.playerInfo.player_name)

	local var_2_0 = {
		showLevel = true,
		is_new = true,
		avatar_id = arg_2_0.playerInfo.avatar_id,
		avatar_frame_id = arg_2_0.playerInfo.avatar_frame_id,
		level = arg_2_0.playerInfo.lev,
		conquerLev = arg_2_0.playerInfo.conquer_lev,
		conquerLoopID = arg_2_0.playerInfo.conquer_loop_id
	}

	xyd.setPlayerAvatar(arg_2_0:nodeByName("avatar"), var_2_0)
	arg_2_0:nodeByName("lbl_rank"):setString(var_0_4:translation("RANKING") .. xyd.tables.translation:translation("COLON"))
	arg_2_0:nodeByName("lbl_region"):setString(var_0_4:translation("LEGEND_WINDOW_SERVERS"))
	arg_2_0:nodeByName("txt_region"):setString("S" .. math.floor(arg_2_0.playerInfo.player_id / 100000))
	arg_2_0:nodeByName("rank_txt"):setString(arg_2_0.rank)
	arg_2_0:nodeByName("lbl_rank"):enableOutline(cc.c4b(133, 35, 63, 255), 2)
	arg_2_0:initTeamList()
end

function var_0_0.initTeamList(arg_3_0)
	local var_3_0 = arg_3_0:nodeByName("team_list")
	local var_3_1 = var_3_0:getContentSize()

	arg_3_0.teamList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_TOP
	}):addTo(var_3_0)

	local var_3_2 = 160
	local var_3_3 = false

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.teams) do
		if #arg_3_0.teams > 3 and iter_3_0 > #arg_3_0.teams / 2 + 1 then
			local var_3_4 = true
		else
			local var_3_5 = arg_3_0.teamList:newItem()
			local var_3_6 = arg_3_0:newTeamItem(iter_3_0, iter_3_1)

			var_3_6:setContentSize(var_3_1.width, var_3_2)
			var_3_5:addContent(var_3_6)
			var_3_5:setItemSize(var_3_1.width, var_3_2 + 14)
			arg_3_0.teamList:addItem(var_3_5)
		end
	end

	local var_3_7 = arg_3_0.teamList:newItem()
	local var_3_8 = display.newNode()
	local var_3_9 = xyd.createLabel(20, cc.c3b(179, 102, 138))
	local var_3_10 = var_0_3.new({
		color = "#b3668a",
		size = 624
	})

	var_3_10:setPosition(5, 30)
	var_3_9:setAnchorPoint(0.5, 0)
	var_3_9:setPosition(var_3_1.width / 2, 0)
	var_3_9:setString(var_0_4:translation("SYSTEM_BATTLE_ARRAY_PRIVTE"))
	var_3_8:setContentSize(var_3_1.width, 40)
	var_3_8:addChild(var_3_10)
	var_3_8:addChild(var_3_9)
	var_3_7:addContent(var_3_8)
	var_3_7:setItemSize(var_3_1.width, 40)
	arg_3_0.teamList:addItem(var_3_7)
	arg_3_0.teamList:reload()
end

function var_0_0.newTeamItem(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/peak_arena/team_info_item.csb")
	local var_4_1 = var_4_0:getChildByName("container")
	local var_4_2 = 0
	local var_4_3 = 0

	var_4_1:getChildByName("txt_team"):setString(var_0_4:translation("SYSTEM_DOUNIU_BATTLE_ARRAY") .. arg_4_1)
	var_4_1:getChildByName("txt_force"):setString(var_0_4:translation("SYSTEM_CHECKOUT_POWER"))

	for iter_4_0, iter_4_1 in ipairs(arg_4_2.heros) do
		local var_4_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/peak_arena/team_info_cell.csb")
		local var_4_5 = var_4_4:getChildByName("container")

		xyd.setAvatarBorderNewUI(iter_4_1, var_4_5:getChildByName("avatar"))
		var_4_5:getChildByName("txt_name"):setString(iter_4_1:getName())
		var_4_1:addChild(var_4_4)
		var_4_4:setPosition(var_4_3 * 108, 0)

		if iter_4_1.force_ and iter_4_1.force_ ~= 0 then
			var_4_2 = var_4_2 + iter_4_1.force_
		else
			var_4_2 = var_4_2 + iter_4_1:getZhandouli()
		end

		var_4_3 = var_4_3 + 1
	end

	if arg_4_2.pet then
		local var_4_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/peak_arena/team_info_cell.csb")
		local var_4_7 = var_4_6:getChildByName("container")

		xyd.setPetAvatarNewUI(var_4_7:getChildByName("avatar"), arg_4_2.pet)
		var_4_7:getChildByName("txt_name"):setString(arg_4_2.pet:getName())
		var_4_7:getChildByName("avatar"):setScale(0.8)
		var_4_1:addChild(var_4_6)
		var_4_6:setPosition(var_4_3 * 108, 0)

		var_4_2 = var_4_2 + arg_4_2.pet:getZhandouli()
	end

	var_4_1:getChildByName("force"):setString(var_4_2)

	return var_4_0
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	arg_5_0:addBlockLayer()
end

return var_0_0
