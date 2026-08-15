local var_0_0 = class("WorldBossRankInfoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.illusionAward
local var_0_4 = import("app.common.ui.SplitLine")
local var_0_5 = import("app.model.Pet")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.avatar_id = arg_1_2.avatar_id
	arg_1_0.avatar_frame_id = arg_1_2.avatar_frame_id
	arg_1_0.level = arg_1_2.level
	arg_1_0.hurt = arg_1_2.hurt
	arg_1_0.p_name = arg_1_2.p_name
	arg_1_0.rank = arg_1_2.rank
	arg_1_0.boss_id = arg_1_2.boss_id
	arg_1_0.guild_name = arg_1_2.guild_name
	arg_1_0.rankType = arg_1_2.rank_type
	arg_1_0.team = arg_1_2
	arg_1_0.conquerLev = arg_1_2.conquer_lev
	arg_1_0.conquerLoopId = arg_1_2.conquer_loop_id
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.huang_time = arg_1_2.huang_time
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	local var_2_0

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

		var_2_0 = var_0_4.new({
			color = "#b3668a",
			size = 522
		})
	else
		var_2_0 = var_0_4.new({
			color = "#edc671",
			size = 522
		})
	end

	arg_2_0:nodeByName("pos_line"):addChild(var_2_0)

	arg_2_0.heroesContainer1 = arg_2_0:nodeByName("heroes_container")

	arg_2_0:nodeByName("rank_txt"):setString(tostring(arg_2_0.team.rank))
	arg_2_0:nodeByName("time_txt"):setString(var_0_2:translation("RANK_PARADISE_TIME"))
	arg_2_0:nodeByName("time_num"):setString(tostring(arg_2_0.huang_time))
	arg_2_0:nodeByName("second_txt"):setString(var_0_2:translation("UNIT_SECOND"))
	arg_2_0:init()
end

function var_0_0.init(arg_3_0)
	arg_3_0:nodeByName("damage_num_words"):setString(var_0_2:translation("HISTORY_DAMAGE") .. var_0_2:translation("COLON"))
	arg_3_0:nodeByName("reward_words"):setString(var_0_2:translation("WORLD_BOSS_RANK_REWARD"))
	arg_3_0:nodeByName("guild_words"):setString(var_0_2:translation("FROM_GUILD"))

	local var_3_0 = {
		showLevel = true,
		is_new = true,
		avatar_id = arg_3_0.avatar_id,
		avatar_frame_id = arg_3_0.avatar_frame_id,
		level = arg_3_0.level,
		conquerLev = arg_3_0.conquerLev,
		conquerLoopID = arg_3_0.conquerLoopId
	}

	xyd.setPlayerAvatar(arg_3_0:nodeByName("icon_container"), var_3_0)
	arg_3_0:nodeByName("lev_text"):setString(arg_3_0.level)
	arg_3_0:nodeByName("name_text"):setString(arg_3_0.p_name)
	arg_3_0:nodeByName("damage_num_text"):setString(arg_3_0.hurt)

	if arg_3_0.guild_name and arg_3_0.guild_name ~= "" then
		arg_3_0:nodeByName("guild_text"):setString(arg_3_0.guild_name)
	else
		arg_3_0:nodeByName("guild_text"):setVisible(false)
		arg_3_0:nodeByName("guild_words"):setVisible(false)
	end

	if arg_3_0.rankType == xyd.RankType.WB then
		arg_3_0:nodeByName("reward_1_text"):setString(xyd.tables.worldBossReward:getMana(arg_3_0.rank))
		arg_3_0:nodeByName("reward_2_text"):setString(xyd.tables.worldBossReward:getDiamond(arg_3_0.rank))
		arg_3_0:rewardFormat(arg_3_0:nodeByName("reward_container"), xyd.tables.worldBoss.stone[arg_3_0.boss_id], xyd.tables.worldBossReward:getStone(arg_3_0.rank))
	elseif arg_3_0.rankType == xyd.RankType.Illusion then
		arg_3_0:createIllusionRewards()
	end

	arg_3_0:addHeroCells()

	if arg_3_0.team and arg_3_0.team.heroes and next(arg_3_0.team.heroes) then
		arg_3_0:nodeByName("btn_copy"):setVisible(true)
		arg_3_0:nodeByName("text_copy"):setString(xyd.tables.translation:translation("COPY_TEAM"))
		arg_3_0:nodeByName("btn_copy"):addTouchEventListener(function(arg_4_0, arg_4_1)
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

				for iter_4_0, iter_4_1 in ipairs(arg_3_0.team.heroes) do
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

				if arg_3_0.team.pet then
					local var_4_6 = var_0_5.new()

					var_4_6:populate(arg_3_0.team.pet)

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
				arg_3_0:close()
			end
		end)
	else
		arg_3_0:nodeByName("btn_copy"):setVisible(false)
	end
end

function var_0_0.rewardFormat(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = arg_5_1:getContentSize().height
	local var_5_1 = var_5_0 / 4
	local var_5_2 = {
		arg_5_2
	}

	if #var_5_2 == 1 and var_5_2[1] == 0 then
		var_5_2 = {}
	end

	local var_5_3 = {
		arg_5_3
	}
	local var_5_4 = #var_5_2

	for iter_5_0 = 1, #var_5_2 do
		if var_5_3[iter_5_0] > 0 then
			local var_5_5 = display.newNode()

			var_5_5:setContentSize(var_5_0, var_5_0)

			if xyd.tables.item:type(var_5_2[iter_5_0]) == -1 then
				xyd.setAvatarBorder(var_5_2[iter_5_0], var_5_5, 1, xyd.tables.hero:initialStar(var_5_2[iter_5_0]))
			else
				xyd.setItemBorder(var_5_5, var_5_2[iter_5_0], false, false, 1)
				arg_5_0:nodeByName("reward_3_text"):setString(var_5_3[iter_5_0])
			end

			var_5_5:addTo(arg_5_1)
			var_5_5:setAnchorPoint(cc.p(0, 0))
			var_5_5:setPosition((iter_5_0 - 1) * (var_5_0 + var_5_1), 0)

			local var_5_6 = {
				id = var_5_2[iter_5_0],
				lev = xyd.tables.item:level(var_5_2[iter_5_0])
			}

			if xyd.tables.item:type(var_5_2[iter_5_0]) == -1 then
				var_5_6.tipsType = 0
				var_5_6.desc1 = xyd.tables.hero:getDes(var_5_2[iter_5_0])
			else
				var_5_6.tipsType = 1
				var_5_6.desc1 = xyd.tables.item:desc1(var_5_2[iter_5_0])
				var_5_6.desc2 = xyd.tables.item:desc2(var_5_2[iter_5_0])
			end

			var_5_6.hasNum = arg_5_0.player:getBackpack():getItemNumByID(var_5_2[iter_5_0])
			var_5_6.name = xyd.tables.item:name(var_5_2[iter_5_0])

			arg_5_0:addTips(var_5_5, var_5_6)
		else
			arg_5_0:nodeByName("reward_3_text"):setVisible(false)
		end
	end

	return arg_5_1
end

function var_0_0.createIllusionRewards(arg_6_0)
	local var_6_0 = var_0_3:getID(arg_6_0.rank)
	local var_6_1 = var_0_3:illusionCoin(var_6_0)

	arg_6_0:nodeByName("jinbi"):setTexture("images/icon/eco/illusion_coin.png")
	arg_6_0:nodeByName("reward_1_text"):setString(var_6_1)

	local var_6_2 = var_0_3:item(var_6_0)
	local var_6_3 = var_0_3:itemNum(var_6_0)

	if #var_6_2 == 0 or var_6_2[1] == 0 then
		arg_6_0:nodeByName("zuanshi"):setVisible(false)
		arg_6_0:nodeByName("reward_2_text"):setVisible(false)
		arg_6_0:nodeByName("reward_container"):setVisible(false)
		arg_6_0:nodeByName("reward_3_text"):setVisible(false)
	elseif #var_6_2 == 1 then
		arg_6_0:nodeByName("zuanshi"):setVisible(false)

		local var_6_4 = cc.p(arg_6_0:nodeByName("zuanshi"):getPosition())
		local var_6_5 = display.newNode()

		var_6_5:setContentSize(40, 40)
		var_6_5:setAnchorPoint(cc.p(0.5, 0.5))
		var_6_5:addTo(arg_6_0:nodeByName("background"))
		var_6_5:setPosition(cc.p(var_6_4))
		xyd.setItemBorder(var_6_5, var_6_2[1])
		arg_6_0:nodeByName("reward_2_text"):setString(var_6_3[1])
		arg_6_0:nodeByName("reward_container"):setVisible(false)
		arg_6_0:nodeByName("reward_3_text"):setVisible(false)
	elseif #var_6_2 == 2 then
		arg_6_0:nodeByName("zuanshi"):setVisible(false)

		local var_6_6 = cc.p(arg_6_0:nodeByName("zuanshi"):getPosition())
		local var_6_7 = display.newNode()

		var_6_7:setContentSize(40, 40)
		var_6_7:setAnchorPoint(cc.p(0.5, 0.5))
		var_6_7:addTo(arg_6_0:nodeByName("background"))
		var_6_7:setPosition(cc.p(var_6_6))
		xyd.setItemBorder(var_6_7, var_6_2[1])
		arg_6_0:nodeByName("reward_2_text"):setString(var_6_3[1])
		xyd.setItemBorder(arg_6_0:nodeByName("reward_container"), var_6_2[2])
		arg_6_0:nodeByName("reward_3_text"):setString(var_6_3[2])
	end
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
		local var_7_6 = var_0_5.new()

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

function var_0_0.didOpen(arg_8_0, arg_8_1)
	var_0_0.super:didOpen(arg_8_1)

	local function var_8_0(arg_9_0, arg_9_1)
		xyd.WindowManager.get():closeWindow(arg_8_0, callback)

		return true
	end

	local var_8_1 = cc.EventListenerTouchOneByOne:create()

	var_8_1:setSwallowTouches(true)
	var_8_1:registerScriptHandler(var_8_0, cc.Handler.EVENT_TOUCH_BEGAN)
	arg_8_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(var_8_1, arg_8_0)
end

return var_0_0
