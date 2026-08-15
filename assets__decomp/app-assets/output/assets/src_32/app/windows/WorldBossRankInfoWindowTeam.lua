local var_0_0 = class("WorldBossRankInfoWindowTeam", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.illusionAward

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
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:init()
end

function var_0_0.init(arg_3_0)
	arg_3_0:nodeByName("damage_num_words"):setString(var_0_2:translation("HISTORY_DAMAGE") .. var_0_2:translation("COLON"))
	arg_3_0:nodeByName("reward_words"):setString(var_0_2:translation("WORLD_BOSS_RANK_REWARD"))
	arg_3_0:nodeByName("guild_words"):setString(var_0_2:translation("FROM_GUILD"))
	xyd.setPlayerAvatar(arg_3_0:nodeByName("icon_container"), {
		showLevel = false,
		avatar_id = arg_3_0.avatar_id,
		avatar_frame_id = arg_3_0.avatar_frame_id
	})
	arg_3_0:nodeByName("lev_text"):setString(arg_3_0.level)
	arg_3_0:nodeByName("name_text"):setString(arg_3_0.p_name)
	arg_3_0:nodeByName("damage_num_text"):setString(arg_3_0.hurt)

	if arg_3_0.guild_name and arg_3_0.guild_name ~= "" then
		arg_3_0:nodeByName("guild_text"):setString(arg_3_0.guild_name)
	else
		arg_3_0:nodeByName("guild_text"):setVisible(false)
		arg_3_0:nodeByName("guild_words"):setVisible(false)
		arg_3_0:nodeByName("bg"):setContentSize(arg_3_0:nodeByName("bg"):getWidth(), arg_3_0:nodeByName("bg"):getHeight() - 50)
	end

	if arg_3_0.rankType == xyd.RankType.WB then
		arg_3_0:nodeByName("reward_1_text"):setString(xyd.tables.worldBossReward:getMana(arg_3_0.rank))
		arg_3_0:nodeByName("reward_2_text"):setString(xyd.tables.worldBossReward:getDiamond(arg_3_0.rank))
		arg_3_0:rewardFormat(arg_3_0:nodeByName("reward_container"), xyd.tables.worldBoss.stone[arg_3_0.boss_id], xyd.tables.worldBossReward:getStone(arg_3_0.rank))
	elseif arg_3_0.rankType == xyd.RankType.Illusion then
		arg_3_0:createIllusionRewards()
	end
end

function var_0_0.rewardFormat(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = arg_4_1:getContentSize().height
	local var_4_1 = var_4_0 / 4
	local var_4_2 = {
		arg_4_2
	}

	if #var_4_2 == 1 and var_4_2[1] == 0 then
		var_4_2 = {}
	end

	local var_4_3 = {
		arg_4_3
	}
	local var_4_4 = #var_4_2

	for iter_4_0 = 1, #var_4_2 do
		if var_4_3[iter_4_0] > 0 then
			local var_4_5 = display.newNode()

			var_4_5:setContentSize(var_4_0, var_4_0)

			if xyd.tables.item:type(var_4_2[iter_4_0]) == -1 then
				xyd.setAvatarBorder(var_4_2[iter_4_0], var_4_5, 1, xyd.tables.hero:initialStar(var_4_2[iter_4_0]))
			else
				xyd.setItemBorder(var_4_5, var_4_2[iter_4_0], false, false, 1)
				arg_4_0:nodeByName("reward_3_text"):setString(var_4_3[iter_4_0])
			end

			var_4_5:addTo(arg_4_1)
			var_4_5:setAnchorPoint(cc.p(0, 0))
			var_4_5:setPosition((iter_4_0 - 1) * (var_4_0 + var_4_1), 0)

			local var_4_6 = {
				id = var_4_2[iter_4_0],
				lev = xyd.tables.item:level(var_4_2[iter_4_0])
			}

			if xyd.tables.item:type(var_4_2[iter_4_0]) == -1 then
				var_4_6.tipsType = 0
				var_4_6.desc1 = xyd.tables.hero:getDes(var_4_2[iter_4_0])
			else
				var_4_6.tipsType = 1
				var_4_6.desc1 = xyd.tables.item:desc1(var_4_2[iter_4_0])
				var_4_6.desc2 = xyd.tables.item:desc2(var_4_2[iter_4_0])
			end

			var_4_6.hasNum = arg_4_0.player:getBackpack():getItemNumByID(var_4_2[iter_4_0])
			var_4_6.name = xyd.tables.item:name(var_4_2[iter_4_0])

			arg_4_0:addTips(var_4_5, var_4_6)
		else
			arg_4_0:nodeByName("reward_3_text"):setVisible(false)
		end
	end

	return arg_4_1
end

function var_0_0.createIllusionRewards(arg_5_0)
	local var_5_0 = var_0_3:getID(arg_5_0.rank)
	local var_5_1 = var_0_3:illusionCoin(var_5_0)

	arg_5_0:nodeByName("jinbi"):setTexture("images/icon/eco/illusion_coin.png")
	arg_5_0:nodeByName("reward_1_text"):setString(var_5_1)

	local var_5_2 = var_0_3:item(var_5_0)
	local var_5_3 = var_0_3:itemNum(var_5_0)

	if #var_5_2 == 0 or var_5_2[1] == 0 then
		arg_5_0:nodeByName("zuanshi"):setVisible(false)
		arg_5_0:nodeByName("reward_2_text"):setVisible(false)
		arg_5_0:nodeByName("reward_container"):setVisible(false)
		arg_5_0:nodeByName("reward_3_text"):setVisible(false)
	elseif #var_5_2 == 1 then
		arg_5_0:nodeByName("zuanshi"):setVisible(false)

		local var_5_4 = cc.p(arg_5_0:nodeByName("zuanshi"):getPosition())
		local var_5_5 = display.newNode()

		var_5_5:setContentSize(40, 40)
		var_5_5:setAnchorPoint(cc.p(0.5, 0.5))
		var_5_5:addTo(arg_5_0:nodeByName("background"))
		var_5_5:setPosition(cc.p(var_5_4))
		xyd.setItemBorder(var_5_5, var_5_2[1])
		arg_5_0:nodeByName("reward_2_text"):setString(var_5_3[1])
		arg_5_0:nodeByName("reward_container"):setVisible(false)
		arg_5_0:nodeByName("reward_3_text"):setVisible(false)
	elseif #var_5_2 == 2 then
		arg_5_0:nodeByName("zuanshi"):setVisible(false)

		local var_5_6 = cc.p(arg_5_0:nodeByName("zuanshi"):getPosition())
		local var_5_7 = display.newNode()

		var_5_7:setContentSize(40, 40)
		var_5_7:setAnchorPoint(cc.p(0.5, 0.5))
		var_5_7:addTo(arg_5_0:nodeByName("background"))
		var_5_7:setPosition(cc.p(var_5_6))
		xyd.setItemBorder(var_5_7, var_5_2[1])
		arg_5_0:nodeByName("reward_2_text"):setString(var_5_3[1])
		xyd.setItemBorder(arg_5_0:nodeByName("reward_container"), var_5_2[2])
		arg_5_0:nodeByName("reward_3_text"):setString(var_5_3[2])
	end
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	var_0_0.super:didOpen(arg_6_1)

	local function var_6_0(arg_7_0, arg_7_1)
		xyd.WindowManager.get():closeWindow(arg_6_0, callback)

		return true
	end

	local var_6_1 = cc.EventListenerTouchOneByOne:create()

	var_6_1:setSwallowTouches(true)
	var_6_1:registerScriptHandler(var_6_0, cc.Handler.EVENT_TOUCH_BEGAN)
	arg_6_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(var_6_1, arg_6_0)
end

return var_0_0
