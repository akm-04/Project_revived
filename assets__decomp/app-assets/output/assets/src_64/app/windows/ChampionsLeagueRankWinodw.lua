local var_0_0 = class("ChampionsLeagueRankWinodw", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = import("app.model.Pet")
local var_0_3 = import("app.model.Hero")
local var_0_4 = xyd.tables.translation
local var_0_5 = xyd.tables.hero
local var_0_6 = xyd.tables.misc
local var_0_7 = {
	txtChallenge = var_0_4:translation("CHAMPIONS_LEAGUE_RANK_4"),
	txtNotChallenge = var_0_4:translation("CHAMPIONS_LEAGUE_RANK_5")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.champions = xyd.ModelManager.get():loadModel(xyd.ModelType.CHAMPIONS_LEAGUE)
	arg_1_0.heros = arg_1_2.heros
	arg_1_0.pet = arg_1_2.pet
	arg_1_0.player_id = arg_1_2.player_id
	arg_1_0.player_name = arg_1_2.player_name
	arg_1_0.conquer_lev = arg_1_2.conquer_lev or 0
	arg_1_0.isChallenge = arg_1_2.isChallenge
	arg_1_0.region = math.floor(arg_1_0.player_id / 100000)
	arg_1_0.regionName = xyd.tables.serverSelect:name(arg_1_0.region)
	arg_1_0.rank = arg_1_2.rank
	arg_1_0.posX = arg_1_2.posX
	arg_1_0.posY = arg_1_2.posY
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("container"):setPosition(cc.p(arg_2_0.posX, arg_2_0.posY))
	arg_2_0:nodeByName("container"):setScale(0.7555555555555555)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	local var_4_0

	arg_4_0:nodeByName("container"):getChildByName("bg_1"):setVisible(false)
	arg_4_0:nodeByName("container"):getChildByName("bg_2"):setVisible(false)
	arg_4_0:nodeByName("container"):getChildByName("bg_3"):setVisible(false)

	if arg_4_0.selfPlayer.lev == var_0_6:getValue("cross_arena_group3_level") then
		arg_4_0:nodeByName("container"):getChildByName("bg_3"):setVisible(true)

		var_4_0 = cc.c4b(92, 36, 32, 255)
	elseif arg_4_0.selfPlayer.lev >= var_0_6:getValue("cross_arena_group2_level") then
		arg_4_0:nodeByName("container"):getChildByName("bg_2"):setVisible(true)

		var_4_0 = cc.c4b(52, 84, 139, 255)
	elseif arg_4_0.selfPlayer.lev >= var_0_6:getValue("cross_arena_group1_level") then
		arg_4_0:nodeByName("container"):getChildByName("bg_1"):setVisible(true)

		var_4_0 = cc.c4b(87, 31, 50, 255)
	end

	local var_4_1 = cc.Sequence:create({
		cc.CallFunc:create(function()
			local var_5_0 = "windows/champions_league/texiao/paihangbangyeqian"
			local var_5_1 = var_5_0 .. ".json"
			local var_5_2 = var_5_0 .. ".atlas"

			arg_4_0.energyEffect_ = var_0_1.new(var_5_1, var_5_2, 1)

			arg_4_0.energyEffect_:addTo(arg_4_0, 1)

			local var_5_3 = arg_4_0:nodeByName("container"):getContentSize()

			arg_4_0.energyEffect_:pos(arg_4_0.posX + 150, arg_4_0.posY + 70)
			arg_4_0.energyEffect_:play(function()
				arg_4_0.energyEffect_:stop()
			end, false)
		end),
		cc.DelayTime:create(0.3),
		cc.ScaleTo:create(0.3, 1.3235294117647058)
	})

	arg_4_0:nodeByName("container"):runActionOnce(var_4_1, false)
	arg_4_0:nodeByName("txt_name"):setString(arg_4_0.player_name)
	arg_4_0:nodeByName("num_rank"):setString(arg_4_0.rank)
	arg_4_0:nodeByName("num_rank"):enableOutline(var_4_0, 2)
	arg_4_0:nodeByName("txt_challage"):setString(var_0_7.txtChallenge)
	arg_4_0:initHeroCell()
end

function var_0_0.initHeroCell(arg_7_0)
	local var_7_0 = {}
	local var_7_1

	if arg_7_0.pet and arg_7_0.pet.pet_id then
		local var_7_2 = arg_7_0.pet

		if type(var_7_2.equips) == "string" then
			var_7_2.equips = xyd.splitToNumber(var_7_2.equips, "|")
		end

		local var_7_3 = var_0_2.new()

		var_7_3:populate(var_7_2)

		var_7_1 = var_7_3
	else
		var_7_1 = nil
	end

	if var_7_1 then
		local var_7_4 = display.newNode()

		var_7_4:setContentSize(60, 60)
		xyd.setPetAvatarNewUI(var_7_4, var_7_1, nil, true)
		var_7_4:setAnchorPoint(cc.p(0.5, 0, 5))
		var_7_4:setScale(0.6)
		var_7_4:addTo(arg_7_0:nodeByName("list_avatar"))
		var_7_4:setPosition(cc.p(30, 18))
	end

	if arg_7_0.heros and next(arg_7_0.heros) then
		for iter_7_0, iter_7_1 in pairs(arg_7_0.heros) do
			local var_7_5 = iter_7_1

			if type(var_7_5.equips) == "string" then
				var_7_5.equips = xyd.splitToNumber(var_7_5.equips, "|")
			end

			if arg_7_0.heros[iter_7_0].book_shelf_lev and arg_7_0.heros[iter_7_0].book_shelf_lev > 0 then
				var_7_5.book_shelf_lev = arg_7_0.heros[iter_7_0].book_shelf_lev
			else
				var_7_5.book_shelf_lev = 0
			end

			local var_7_6 = var_0_3.new()

			var_7_6:populate(var_7_5)

			if arg_7_0.conquer_lev and arg_7_0.conquer_lev > 0 then
				var_7_6:setConquerSchoolLev(arg_7_0.conquer_lev)
			end

			table.insert(var_7_0, var_7_6)
		end
	end

	for iter_7_2 = 1, #var_7_0 do
		local var_7_7 = display.newNode()

		var_7_7:setContentSize(60, 60)
		xyd.setAvatarBorderNewUI(var_7_0[iter_7_2], var_7_7, nil, nil, nil, nil, nil, nil, false)
		var_7_7:addTo(arg_7_0:nodeByName("list_avatar"))
		var_7_7:setPosition(cc.p(70 * iter_7_2, 5))
	end

	arg_7_0:initChallengeBtn(var_7_0, var_7_1)
end

function var_0_0.initChallengeBtn(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = arg_8_0:nodeByName("btn_challage")

	var_8_0:addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.began then
			var_8_0:setScale(0.9)
		elseif arg_9_1 == ccui.TouchEventType.ended then
			var_8_0:setScale(1)
			xyd.playButtonSound()

			if arg_8_0.isChallenge then
				local var_9_0 = {
					my_id = arg_8_0.selfPlayer.playerID,
					enemy_id = arg_8_0.player_id or 0,
					enemy_name = arg_8_0.player_name or 0,
					enemy_region = arg_8_0.region,
					enemy_region_name = arg_8_0.regionName,
					enemy_title_info = arg_8_0.title_info or {}
				}
				local var_9_1 = {
					is_avenge = 0,
					showEnemy = true,
					type = xyd.SelectTeamType.CHAMPIONS,
					campaignType = xyd.CampaignType.ARENA,
					fighterInfo = var_9_0,
					enemyHeroes = arg_8_1,
					enemyPets = arg_8_2
				}

				xyd.WindowManager.get():openWindow("champions_select_team", var_9_1)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_7.txtNotChallenge
				})
			end
		end
	end)
end

return var_0_0
