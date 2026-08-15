local var_0_0 = class("GuildWarPathStateWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.guildBattleTable
local var_0_3 = 1
local var_0_4 = 2
local var_0_5 = 2
local var_0_6 = 3
local var_0_7 = 4
local var_0_8 = 5

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

	arg_1_0:setTouchSwallowEnabled(true)

	arg_1_0.path = arg_1_2.path

	if arg_1_0.guild.warSide and arg_1_0.guild.warSide == 1 then
		arg_1_0.enSide = "red"
		arg_1_0.side = "blue"
	else
		arg_1_0.enSide = "blue"
		arg_1_0.side = "red"
	end

	arg_1_0.state = var_0_3
end

function var_0_0.scrollListener(arg_2_0, arg_2_1)
	if arg_2_1.name == "began" then
		arg_2_0.scrollViewMoved_ = false
		arg_2_0.prevY_ = arg_2_1.y
	elseif arg_2_1.name == "moved" and 20 <= math.abs(arg_2_1.y - arg_2_0.prevY_) then
		arg_2_0.scrollViewMoved_ = true
	end
end

function var_0_0.updateListData(arg_3_0)
	arg_3_0.list = {}

	if arg_3_0.state == var_0_4 then
		for iter_3_0, iter_3_1 in pairs(arg_3_0.guild.guildWarFinishList) do
			local var_3_0 = {
				type = var_0_8,
				mine = iter_3_1.mine,
				enemy = iter_3_1.enemy
			}

			table.insert(arg_3_0.list, var_3_0)
		end
	end

	if arg_3_0.state == var_0_3 then
		for iter_3_2, iter_3_3 in pairs(arg_3_0.guild.guildWarFightList) do
			local var_3_1 = {
				type = var_0_5,
				mine = iter_3_3.mine,
				enemy = iter_3_3.enemy
			}

			table.insert(arg_3_0.list, var_3_1)
		end

		if #arg_3_0.guild.guildWarWaitList ~= 0 then
			local var_3_2 = {
				type = var_0_7
			}

			table.insert(arg_3_0.list, var_3_2)
		end

		for iter_3_4, iter_3_5 in pairs(arg_3_0.guild.guildWarWaitList) do
			local var_3_3 = {
				type = var_0_6,
				mine = iter_3_5.mine,
				enemy = iter_3_5.enemy
			}

			table.insert(arg_3_0.list, var_3_3)
		end
	end
end

function var_0_0.delegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = arg_4_0.list

	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return #var_4_0
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		if arg_4_3 > #var_4_0 then
			return nil
		end

		local var_4_1 = arg_4_0.listView:dequeueItem()

		if not var_4_1 then
			var_4_1 = arg_4_0.listView:newItem()
		else
			var_4_1:removeAllChildren(true)
		end

		local var_4_2 = var_4_0[arg_4_3]
		local var_4_3 = display.newNode()

		arg_4_0:initCell(var_4_3, var_4_2)

		local var_4_4 = display.newNode()

		var_4_4:addChild(var_4_3)
		var_4_4:setContentSize(var_4_3:getContentSize())
		var_4_1:setItemSize(var_4_3:getContentSize().width, var_4_3:getContentSize().height)
		var_4_1:addContent(var_4_4)

		return var_4_1
	end
end

function var_0_0.initCell(arg_5_0, arg_5_1, arg_5_2)
	local function var_5_0(arg_6_0)
		if arg_5_2.mine == nil then
			arg_6_0:getChildByName(arg_5_0.side .. "_container"):setVisible(false)
			arg_6_0:getChildByName("vs"):setVisible(false)
			arg_6_0:getChildByName("fighting"):setVisible(false)
			arg_6_0:getChildByName("waiting"):setVisible(false)
		else
			if arg_5_2.type ~= var_0_8 then
				arg_6_0:getChildByName(arg_5_0.side .. "_container"):getChildByName("fail_bg"):setVisible(false)
				arg_6_0:getChildByName(arg_5_0.side .. "_container"):getChildByName("win_bg"):setVisible(false)
			elseif arg_5_2.mine.is_win == 1 then
				arg_6_0:getChildByName(arg_5_0.side .. "_container"):getChildByName("fail_bg"):setVisible(false)
			elseif arg_5_2.mine.is_win == 0 then
				arg_6_0:getChildByName(arg_5_0.side .. "_container"):getChildByName("win_bg"):setVisible(false)
			else
				arg_6_0:getChildByName(arg_5_0.side .. "_container"):getChildByName("fail_bg"):setVisible(false)
				arg_6_0:getChildByName(arg_5_0.side .. "_container"):getChildByName("win_bg"):setVisible(false)
			end

			xyd.setAvatarClip(arg_6_0:getChildByName(arg_5_0.side .. "_container"):getChildByName("icon"), arg_5_2.mine.player_avatar, 1)

			local var_6_0 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarFrameId] .. ".png"

			if arg_5_2.mine.player_frame and arg_5_2.mine.player_frame ~= 0 then
				var_6_0 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[arg_5_2.mine.player_frame] .. ".png"
			end

			local var_6_1 = xyd.AssetLoader.get():loadSprite(var_6_0)

			var_6_1:setPosition(35, 35)
			arg_6_0:getChildByName(arg_5_0.side .. "_container"):getChildByName("icon_border"):addChild(var_6_1)
			arg_6_0:getChildByName(arg_5_0.side .. "_container"):getChildByName("name"):setString(arg_5_2.mine.player_name)

			if arg_5_2.mine.player_conquer_lev and arg_5_2.mine.player_conquer_lev > 0 then
				local var_6_2 = arg_6_0:getChildByName(arg_5_0.side .. "_container")
				local var_6_3 = {
					x = -2,
					y = 2
				}

				xyd.setConquerLev(arg_5_2.mine.player_conquer_lev, var_6_2:getChildByName("lev_text"), var_6_2:getChildByName("lev_bg"), var_6_3, nil, nil, nil, arg_5_2.mine.player_conquer_loop_id)
			else
				arg_6_0:getChildByName(arg_5_0.side .. "_container"):getChildByName("lev_text"):setString(arg_5_2.mine.player_lev)
			end
		end

		if arg_5_2.enemy == nil then
			arg_6_0:getChildByName(arg_5_0.enSide .. "_container"):setVisible(false)
			arg_6_0:getChildByName("vs"):setVisible(false)
			arg_6_0:getChildByName("fighting"):setVisible(false)
			arg_6_0:getChildByName("waiting"):setVisible(false)
		else
			if arg_5_2.type ~= var_0_8 then
				arg_6_0:getChildByName(arg_5_0.enSide .. "_container"):getChildByName("fail_bg"):setVisible(false)
				arg_6_0:getChildByName(arg_5_0.enSide .. "_container"):getChildByName("win_bg"):setVisible(false)
			elseif arg_5_2.enemy.is_win == 1 then
				arg_6_0:getChildByName(arg_5_0.enSide .. "_container"):getChildByName("fail_bg"):setVisible(false)
			elseif arg_5_2.enemy.is_win == 0 then
				arg_6_0:getChildByName(arg_5_0.enSide .. "_container"):getChildByName("win_bg"):setVisible(false)
			else
				arg_6_0:getChildByName(arg_5_0.enSide .. "_container"):getChildByName("fail_bg"):setVisible(false)
				arg_6_0:getChildByName(arg_5_0.enSide .. "_container"):getChildByName("win_bg"):setVisible(false)
			end

			xyd.setAvatarClip(arg_6_0:getChildByName(arg_5_0.enSide .. "_container"):getChildByName("icon"), arg_5_2.enemy.player_avatar, 1)

			local var_6_4 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarFrameId] .. ".png"

			if arg_5_2.enemy.player_frame and arg_5_2.enemy.player_frame ~= 0 then
				var_6_4 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[arg_5_2.enemy.player_frame] .. ".png"
			end

			local var_6_5 = xyd.AssetLoader.get():loadSprite(var_6_4)

			var_6_5:setPosition(35, 35)
			arg_6_0:getChildByName(arg_5_0.enSide .. "_container"):getChildByName("icon_border"):addChild(var_6_5)
			arg_6_0:getChildByName(arg_5_0.enSide .. "_container"):getChildByName("name"):setString(arg_5_2.enemy.player_name)

			if arg_5_2.enemy.player_conquer_lev and arg_5_2.enemy.player_conquer_lev > 0 then
				local var_6_6 = arg_6_0:getChildByName(arg_5_0.enSide .. "_container")
				local var_6_7 = {
					x = -2,
					y = 2
				}

				xyd.setConquerLev(arg_5_2.enemy.player_conquer_lev, var_6_6:getChildByName("lev_text"), var_6_6:getChildByName("lev_bg"), var_6_7, nil, nil, nil, arg_5_2.enemy.player_conquer_loop_id)
			else
				arg_6_0:getChildByName(arg_5_0.enSide .. "_container"):getChildByName("lev_text"):setString(arg_5_2.enemy.player_lev)
			end
		end
	end

	local var_5_1
	local var_5_2

	if arg_5_2.type == var_0_7 then
		var_5_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/fight_state/text_item.csb")
		var_5_2 = var_5_1:getChildByName("container")

		var_5_2:getChildByName("text"):setString(var_0_1:translation("WAITING_TEAM"))
		var_5_2:getChildByName("text"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	elseif arg_5_2.type == var_0_5 then
		var_5_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/fight_state/fight_item.csb")
		var_5_2 = var_5_1:getChildByName("container")

		var_5_2:getChildByName("vs"):setVisible(false)
		var_5_2:getChildByName("waiting"):setVisible(false)
		var_5_0(var_5_2)
	elseif arg_5_2.type == var_0_6 then
		var_5_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/fight_state/fight_item.csb")
		var_5_2 = var_5_1:getChildByName("container")

		var_5_2:getChildByName("vs"):setVisible(false)
		var_5_2:getChildByName("fighting"):setVisible(false)
		var_5_0(var_5_2)
	elseif arg_5_2.type == var_0_8 then
		var_5_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/fight_state/fight_item.csb")
		var_5_2 = var_5_1:getChildByName("container")

		var_5_2:getChildByName("fighting"):setVisible(false)
		var_5_2:getChildByName("waiting"):setVisible(false)
		var_5_0(var_5_2)

		local var_5_3 = display.newNode()

		var_5_3:setContentSize(var_5_2:getWidth(), var_5_2:getHeight())
		var_5_3:setTouchEnabled(true)
		var_5_3:setTouchSwallowEnabled(false)
		var_5_3:setAnchorPoint(cc.p(0, 0))
		var_5_3:setPosition(0, 0)
		var_5_2:addChild(var_5_3)
		var_5_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
			if arg_7_0.name == "began" then
				return true
			elseif arg_7_0.name == "ended" and arg_5_0.scrollViewMoved_ == false then
				xyd.playButtonSound()

				local var_7_0 = {
					enemy = arg_5_2.enemy,
					mine = arg_5_2.mine,
					side = arg_5_0.side
				}

				xyd.WindowManager.get():openWindow("guild_war_record", var_7_0)
			end
		end)
	end

	local var_5_4 = var_5_2:getContentSize()

	var_5_1:setContentSize(var_5_4)
	arg_5_1:setContentSize(var_5_4)
	var_5_1:setName("layout")
	var_5_1:setPosition(cc.p(0, 0))
	arg_5_1:addChild(var_5_1)
	arg_5_1:setTouchSwallowEnabled(false)
	arg_5_1:setTouchEnabled(true)
end

function var_0_0.willOpen(arg_8_0, arg_8_1)
	var_0_0.super:willOpen(arg_8_1)
	arg_8_0:updateListData()

	arg_8_0.scrollViewMoved_ = false
	arg_8_0.listView = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_8_0:nodeByName("list"):getWidth(), arg_8_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_8_0:nodeByName("list")):onScroll(handler(arg_8_0, arg_8_0.scrollListener))

	arg_8_0.listView:setBounceable(true)
	arg_8_0.listView:setDelegate(handler(arg_8_0, arg_8_0.delegate))
	arg_8_0.listView:reload()
	arg_8_0:layout()
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	var_0_0.super:didOpen(arg_9_1)
end

function var_0_0.layout(arg_10_0)
	local var_10_0 = ""

	if arg_10_0.path == xyd.GuildWarPath.TOP then
		var_10_0 = var_0_1:translation("TOP_PATH")
	elseif arg_10_0.path == xyd.GuildWarPath.MID then
		var_10_0 = var_0_1:translation("MID_PATH")
	else
		var_10_0 = var_0_1:translation("BOTTOM_PATH")
	end

	arg_10_0:nodeByName("title_text"):setString(string.format(var_0_1:translation("FIGHTING_STATE"), var_10_0))
	arg_10_0:nodeByName("recent_btn"):setBrightStyle(ccui.BrightStyle.highlight)
	arg_10_0:nodeByName("recent_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_10_0.state = var_0_3

			arg_10_0:updateListData()
			arg_10_0.listView:reload()
			arg_10_0:nodeByName("recent_btn"):setBrightStyle(ccui.BrightStyle.highlight)
			arg_10_0:nodeByName("history_btn"):setBrightStyle(ccui.BrightStyle.normal)
		end
	end)
	arg_10_0:nodeByName("history_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_10_0.state = var_0_4

			arg_10_0:updateListData()
			arg_10_0.listView:reload()
			arg_10_0:nodeByName("history_btn"):setBrightStyle(ccui.BrightStyle.highlight)
			arg_10_0:nodeByName("recent_btn"):setBrightStyle(ccui.BrightStyle.normal)
		end
	end)

	if arg_10_0.side == "blue" then
		arg_10_0:nodeByName("name_1"):setString(arg_10_0.guild.guild_name)

		if arg_10_0.guild.warEnemy.guildId ~= 0 then
			arg_10_0:nodeByName("name_2"):setString(arg_10_0.guild.warEnemy.name)
			xyd.setTeamBorder(arg_10_0.guild.warEnemy.icon, arg_10_0:nodeByName("guild_icon_2"))
		else
			arg_10_0:nodeByName("name_2"):setString(var_0_1:translation("GUILD_BATTLE_NAME"))
			xyd.setTeamBorder(xyd.tables.misc.teamIcons[1], arg_10_0:nodeByName("guild_icon_1"))
		end

		xyd.setTeamBorder(arg_10_0.guild.guild_icon, arg_10_0:nodeByName("guild_icon_1"))
		arg_10_0:nodeByName("team_num_1"):setString(string.format(var_0_1:translation("LEFT_TEAM"), arg_10_0.guild.guildWarSelfLeft, arg_10_0.guild.guildWarSelfTotal))
		arg_10_0:nodeByName("team_num_2"):setString(string.format(var_0_1:translation("LEFT_TEAM"), arg_10_0.guild.guildWarEnemyLeft, arg_10_0.guild.guildWarEnemyTotal))
	else
		arg_10_0:nodeByName("name_2"):setString(arg_10_0.guild.guild_name)

		if arg_10_0.guild.warEnemy.guildId ~= 0 then
			arg_10_0:nodeByName("name_1"):setString(arg_10_0.guild.warEnemy.name)
			xyd.setTeamBorder(arg_10_0.guild.warEnemy.icon, arg_10_0:nodeByName("guild_icon_1"))
		else
			arg_10_0:nodeByName("name_1"):setString(var_0_1:translation("GUILD_BATTLE_NAME"))
			xyd.setTeamBorder(xyd.tables.misc.teamIcons[1], arg_10_0:nodeByName("guild_icon_1"))
		end

		xyd.setTeamBorder(arg_10_0.guild.guild_icon, arg_10_0:nodeByName("guild_icon_2"))
		arg_10_0:nodeByName("team_num_1"):setString(string.format(var_0_1:translation("LEFT_TEAM"), arg_10_0.guild.guildWarEnemyLeft, arg_10_0.guild.guildWarEnemyTotal))
		arg_10_0:nodeByName("team_num_2"):setString(string.format(var_0_1:translation("LEFT_TEAM"), arg_10_0.guild.guildWarSelfLeft, arg_10_0.guild.guildWarSelfTotal))
	end

	arg_10_0:addBlockLayer()
end

function var_0_0.willClose(arg_13_0, arg_13_1)
	var_0_0.super:willClose(arg_13_1)
end

return var_0_0
