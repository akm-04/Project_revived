local var_0_0 = class("ArenaTeamInfoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = "arena_team_info"
local var_0_2 = import("app.model.Pet")
local var_0_3 = import("app.common.ui.SplitLine")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.team = arg_1_2.team
	arg_1_0.arenaType_ = arg_1_2.arena_type
	arg_1_0.isRed = arg_1_2.is_red
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	local var_2_0 = arg_2_0:container()
	local var_2_1 = var_2_0:getContentSize()
	local var_2_2 = cc.p(var_2_0:getPosition())

	local function var_2_3(arg_3_0, arg_3_1)
		xyd.WindowManager.get():closeWindow(var_0_1, callback)

		return true
	end

	local var_2_4 = cc.EventListenerTouchOneByOne:create()

	var_2_4:setSwallowTouches(true)
	var_2_4:registerScriptHandler(var_2_3, cc.Handler.EVENT_TOUCH_BEGAN)
	arg_2_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(var_2_4, arg_2_0)

	arg_2_0.playerName = arg_2_0:nodeByName("text_player_name")
	arg_2_0.avatarPanel = arg_2_0:nodeByName("avatar")
	arg_2_0.textForce = arg_2_0:nodeByName("text_force")
	arg_2_0.textWin = arg_2_0:nodeByName("text_win")
	arg_2_0.heroesContainer1 = arg_2_0:nodeByName("heroes_container")
	arg_2_0.titleScore = arg_2_0:nodeByName("lbl_force")
	arg_2_0.titleRank = arg_2_0:nodeByName("lbl_rank")

	arg_2_0.titleRank:enableOutline(cc.c4b(133, 35, 63, 255), 2)
	arg_2_0.titleRank:setString(xyd.tables.translation:translation("RANKING") .. xyd.tables.translation:translation("COLON"))
	arg_2_0.titleScore:setString(xyd.tables.translation:translation("TOTAL_TEAM_POWER"))
	arg_2_0:nodeByName("txt_team"):setString(xyd.tables.translation:translation("SYSTEM_DINGLOU_BATTLE_ARRAY"))

	if arg_2_0.team.win then
		arg_2_0:nodeByName("lbl_win"):setString(xyd.tables.translation:translation("WINS_FIELD_NUM"))
	else
		arg_2_0:nodeByName("lbl_win"):setVisible(false)
	end

	arg_2_0:nodeByName("guild_words"):setString(xyd.tables.translation:translation("BELONG_TO_GUILD"))

	arg_2_0.heroesContainer2 = arg_2_0:nodeByName("heroes_container2")
	arg_2_0.heroesContainer3 = arg_2_0:nodeByName("heroes_container3")

	arg_2_0:updateTeamInfo()

	local var_2_5

	if arg_2_0.isRed then
		arg_2_0:nodeByName("container"):setBackGroundImage("windows/common/panel/bg_red_tips2.png")
		arg_2_0:nodeByName("bg_name"):setVisible(false)
		arg_2_0:nodeByName("icon_battle"):setVisible(false)
		arg_2_0:nodeByName("bg_team"):setVisible(false)
		arg_2_0:nodeByName("bg_name_red"):setVisible(true)
		arg_2_0:nodeByName("icon_battle_red"):setVisible(true)
		arg_2_0:nodeByName("bg_team_red"):setVisible(true)
		arg_2_0:nodeByName("lbl_force"):setColor(cc.c3b(139, 47, 76))
		arg_2_0:nodeByName("lbl_win"):setColor(cc.c3b(139, 47, 76))
		arg_2_0:nodeByName("guild_words"):setColor(cc.c3b(133, 20, 76))

		var_2_5 = var_0_3.new({
			color = "#b3668a",
			size = 522
		})
	else
		var_2_5 = var_0_3.new({
			color = "#edc671",
			size = 522
		})
	end

	arg_2_0:nodeByName("pos_line"):addChild(var_2_5)

	if arg_2_0.team and arg_2_0.team.heroes and next(arg_2_0.team.heroes) then
		arg_2_0:nodeByName("btn_copy"):setVisible(true)
		arg_2_0:nodeByName("text_copy"):setString(xyd.tables.translation:translation("COPY_TEAM"))
		arg_2_0:nodeByName("btn_copy"):addTouchEventListener(function(arg_4_0, arg_4_1)
			xyd.buttonScaleAnim(arg_4_0, arg_4_1)

			if arg_4_1 == ccui.TouchEventType.ended then
				local var_4_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
				local var_4_1 = xyd.tables.vip:presetNum(var_4_0.vip)

				if var_4_1 <= 0 then
					var_4_1 = 10
				end

				if var_4_1 <= #var_4_0:getSaveTeams() then
					xyd.WindowManager.get():openWindow("toast", {
						message = xyd.tables.translation:translation("PRESET_MEMBER_IS_MAX_NUM")
					})

					return
				end

				local var_4_2 = {}

				for iter_4_0, iter_4_1 in ipairs(arg_2_0.team.heroes) do
					table.insert(var_4_2, iter_4_1:getFirstTableID())
				end

				local var_4_3 = {}

				for iter_4_2, iter_4_3 in ipairs(var_4_2) do
					local var_4_4 = var_4_0:getHeroIgnoreAwaken(iter_4_3)

					if var_4_4 then
						table.insert(var_4_3, var_4_4)
					end
				end

				local var_4_5

				if arg_2_0.team.pet then
					local var_4_6 = var_0_2.new()

					var_4_6:populate(arg_2_0.team.pet)

					var_4_5 = var_4_0:getPetIgnoreAwaken(var_4_6:getFirstTableID())
				end

				local var_4_7 = {
					type = xyd.SelectTeamType.HERO_PRESET,
					presetHeroType = xyd.PresetHeroType.NEW_TEAM,
					presetHeroIndex = #var_4_0:getSaveTeams(),
					selected = var_4_2,
					preHeros = var_4_3,
					prePet = {
						var_4_5
					}
				}

				xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_4_7)
				arg_2_0:close()
			end
		end)
	end
end

function var_0_0.updateTeamInfo(arg_5_0)
	local var_5_0 = {
		showLevel = true,
		is_new = true,
		avatar_id = arg_5_0.team.avatar_id,
		avatar_frame_id = arg_5_0.team.avatar_frame_id,
		playerInfo = arg_5_0.team,
		level = arg_5_0.team.level,
		conquerLev = arg_5_0.team.conquer_lev,
		conquerLoopID = arg_5_0.team.conquer_loop_id
	}

	xyd.setPlayerAvatar(arg_5_0.avatarPanel, var_5_0)
	arg_5_0.playerName:setString(arg_5_0.team.name)
	arg_5_0.textForce:setString(arg_5_0.team.force)

	if arg_5_0.team.win then
		arg_5_0.textWin:setString(arg_5_0.team.win)
	else
		arg_5_0.textWin:setVisible(false)
	end

	if arg_5_0.team.guild ~= nil and arg_5_0.team.guild ~= "" then
		arg_5_0:nodeByName("guild_words"):setVisible(true)
		arg_5_0:nodeByName("guild_text"):setVisible(true)
		arg_5_0:nodeByName("guild_text"):setString(arg_5_0.team.guild)
	else
		arg_5_0:nodeByName("guild_words"):setVisible(false)
		arg_5_0:nodeByName("guild_text"):setVisible(false)
	end

	arg_5_0:updateRank()
	arg_5_0:addHeroCells()
end

function var_0_0.updateRank(arg_6_0)
	if type(arg_6_0.team.rank) ~= "number" then
		return
	end

	arg_6_0:nodeByName("rank_txt"):setString(tostring(arg_6_0.team.rank))
end

function var_0_0.addHeroCells(arg_7_0)
	arg_7_0.heroesContainer1:removeAllChildren()

	if not arg_7_0.team or not arg_7_0.team.heroes or not next(arg_7_0.team.heroes) then
		return
	end

	local var_7_0 = 0

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.team.heroes) do
		local var_7_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena/team_info_item.csb")
		local var_7_2 = var_7_1:getChildByName("container")

		var_7_1:setPosition(108 * var_7_0, 0)
		xyd.setAvatarBorderNewUI(iter_7_1, var_7_2:getChildByName("avatar"))
		var_7_2:getChildByName("txt_name"):setString(iter_7_1:getName())

		if arg_7_0.isRed then
			var_7_2:getChildByName("bg_hero_name"):setVisible(false)
			var_7_2:getChildByName("bg_hero_name_red"):setVisible(true)
		end

		if iter_7_1.isLeader then
			local var_7_3 = xyd.AssetLoader.get():loadSprite("windows/arena/mode/lead_icon.png")

			var_7_3:addTo(var_7_2:getChildByName("avatar"))
			var_7_3:setPosition(20, 65)
		end

		var_7_0 = var_7_0 + 1

		arg_7_0.heroesContainer1:addChild(var_7_1)
	end

	if arg_7_0.team.pet then
		local var_7_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena/team_info_item.csb")
		local var_7_5 = var_7_4:getChildByName("container")
		local var_7_6 = var_0_2.new()

		var_7_6:populate(arg_7_0.team.pet)
		var_7_4:setPosition(108 * var_7_0, 0)
		xyd.setPetAvatar(var_7_5:getChildByName("avatar"), var_7_6, nil, true)
		var_7_5:getChildByName("avatar"):setScale(0.8)
		var_7_5:getChildByName("txt_name"):setString(var_7_6:getName())

		if arg_7_0.isRed then
			var_7_5:getChildByName("bg_hero_name"):setVisible(false)
			var_7_5:getChildByName("bg_hero_name_red"):setVisible(true)
		end

		arg_7_0.heroesContainer1:addChild(var_7_4)
	end
end

function var_0_0.didClose(arg_8_0)
	var_0_0.super.didClose()
end

function var_0_0.container(arg_9_0)
	return arg_9_0:nodeByName("container")
end

return var_0_0
