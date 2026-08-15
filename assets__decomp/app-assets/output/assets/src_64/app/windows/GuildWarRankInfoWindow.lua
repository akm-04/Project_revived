local var_0_0 = class("GuildWarRankInfoWindow", import("app.common.ui.BaseWindow"))

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.avatar_id = arg_1_2.avatar_id
	arg_1_0.avatar_frame_id = arg_1_2.avatar_frame_id
	arg_1_0.level = arg_1_2.level
	arg_1_0.alive_num = arg_1_2.alive_num
	arg_1_0.kill_num = arg_1_2.kill_num
	arg_1_0.player_name = arg_1_2.name
	arg_1_0.coin_num = arg_1_2.coin_num
	arg_1_0.rank = arg_1_2.rank
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = arg_4_0:nodeByName("container")
	local var_4_1 = var_4_0:getContentSize()
	local var_4_2 = cc.p(var_4_0:getPosition())

	local function var_4_3(arg_5_0, arg_5_1)
		xyd.WindowManager.get():closeWindow(arg_4_0, callback)

		return true
	end

	local var_4_4 = cc.EventListenerTouchOneByOne:create()

	var_4_4:setSwallowTouches(true)
	var_4_4:registerScriptHandler(var_4_3, cc.Handler.EVENT_TOUCH_BEGAN)
	arg_4_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(var_4_4, arg_4_0)

	arg_4_0.playerName = arg_4_0:nodeByName("text_player_name")
	arg_4_0.avatarPanel = arg_4_0:nodeByName("avatar")
	arg_4_0.textLevel = arg_4_0:nodeByName("text_level")
	arg_4_0.heroesContainer = arg_4_0:nodeByName("heroes_container")

	arg_4_0:nodeByName("lbl_rank"):setString(xyd.tables.translation:translation("RANKING") .. xyd.tables.translation:translation("COLON"))
	arg_4_0:nodeByName("lbl_win"):setString(xyd.tables.translation:translation("KILL") .. xyd.tables.translation:translation("COLON"))
	arg_4_0:nodeByName("lbl_force"):setString(xyd.tables.translation:translation("ALIVE") .. xyd.tables.translation:translation("COLON"))
	arg_4_0:nodeByName("guild_words"):setString(xyd.tables.translation:translation("MAYBE_REWARD") .. xyd.tables.translation:translation("COLON"))
	arg_4_0:nodeByName("text_win"):setPosition(arg_4_0:nodeByName("rank_txt"):getX(), arg_4_0:nodeByName("text_win"):getY())
	arg_4_0:nodeByName("text_force"):setPosition(arg_4_0:nodeByName("rank_txt"):getX(), arg_4_0:nodeByName("text_force"):getY())
	arg_4_0:updateTeamInfo()
end

function var_0_0.updateTeamInfo(arg_6_0)
	xyd.setPlayerAvatar(arg_6_0.avatarPanel, {
		avatar_id = arg_6_0.avatar_id,
		avatar_frame_id = arg_6_0.avatar_frame_id
	})
	arg_6_0.playerName:setString(arg_6_0.player_name)
	arg_6_0.textLevel:setString(arg_6_0.level)
	arg_6_0:nodeByName("text_win"):setString(arg_6_0.kill_num)
	arg_6_0:nodeByName("text_force"):setString(arg_6_0.alive_num)
	arg_6_0:nodeByName("guild_text"):setVisible(false)
	arg_6_0:updateRank()
	arg_6_0:addHeroCells()
end

function var_0_0.updateRank(arg_7_0)
	if type(arg_7_0.rank) ~= "number" then
		return
	end

	arg_7_0.rankLabel = arg_7_0:nodeByName("rank_txt")

	arg_7_0.rankLabel:setString(tostring(arg_7_0.rank))
end

function var_0_0.addHeroCells(arg_8_0)
	arg_8_0.heroesContainer:removeAllChildren()

	local var_8_0 = 1

	if arg_8_0.coin_num and arg_8_0.coin_num ~= 0 then
		local var_8_1 = display.newNode()

		var_8_1:setContentSize(80, 80)
		var_8_1:setPosition(cc.p(85 * (var_8_0 - 1), 0))
		xyd.setItemBorder(var_8_1, -6, nil, nil, arg_8_0.coin_num)
		arg_8_0.heroesContainer:addChild(var_8_1)

		var_8_0 = var_8_0 + 1
	end

	if xyd.tables.guildBattleGiftTable:giftItem(arg_8_0.rank) then
		for iter_8_0, iter_8_1 in pairs(xyd.tables.guildBattleGiftTable:giftItem(arg_8_0.rank)) do
			local var_8_2 = display.newNode()

			var_8_2:setContentSize(80, 80)
			var_8_2:setPosition(cc.p(85 * (var_8_0 - 1), 0))
			xyd.setItemBorder(var_8_2, iter_8_1, nil, nil, xyd.tables.guildBattleGiftTable:giftNum(arg_8_0.rank)[iter_8_0])
			arg_8_0.heroesContainer:addChild(var_8_2)

			var_8_0 = var_8_0 + 1
		end
	end
end

function var_0_0.didClose(arg_9_0)
	var_0_0.super.didClose()
end

return var_0_0
