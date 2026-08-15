local var_0_0 = class("ChampionsLeagueWinodw", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = require("framework.scheduler")
local var_0_3 = xyd.tables.misc
local var_0_4 = xyd.tables.gift
local var_0_5 = xyd.tables.translation
local var_0_6 = {
	0,
	116,
	126,
	132,
	116,
	126,
	132
}
local var_0_7 = {
	-10,
	-1,
	8,
	-10,
	-1,
	8
}
local var_0_8 = var_0_3:getValue("cross_arena_protect_time_2")
local var_0_9 = var_0_3:getValue("cross_arena_protect_time")
local var_0_10 = {
	txtLev = var_0_5:translation("PLAYER_LEV"),
	txtGroup1 = var_0_5:translation("CHAMPIONS_LEAGUE_RANK_1"),
	txtGroup2 = var_0_5:translation("CHAMPIONS_LEAGUE_RANK_2"),
	txtGroup3 = var_0_5:translation("CHAMPIONS_LEAGUE_RANK_3"),
	txtRate = var_0_5:translation("WIN_RATE_LABEL"),
	txtWin = var_0_5:translation("WINS_FIELD_NUM"),
	txtScore = var_0_5:translation("THIRD_ANNI_WORD_RANK_TXT1"),
	txtEnemyScore = var_0_5:translation("THIRD_ANNI_WORD_RANK_TXT2"),
	txtFirstWin = var_0_5:translation("CHAMPIONS_LEAGUE_FIRST_WIN"),
	txtHonor = var_0_5:translation("CHAMPIONS_LEAGUE_HONOR"),
	txtRecord = var_0_5:translation("FIGHT_RECORD"),
	txtChange = var_0_5:translation("EXCHANGE"),
	txtTeam = var_0_5:translation("DEFENSE_FORMATION"),
	txtProtect = var_0_5:translation("CHAMPIONS_LEAGUE_PROTECT_TIME"),
	txtHonorClose = var_0_5:translation("CHAMPIONS_LEAGUE_HONOR_CLOSE"),
	txtOutRank = var_0_5:translation("CHAMPIONS_LEAGUE_OUT_RANK"),
	hasEnd = var_0_5:translation("CROSS_ARENA_REST")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.champions = xyd.ModelManager.get():loadModel(xyd.ModelType.CHAMPIONS_LEAGUE)
	arg_1_0.pet = arg_1_2.defense_info.pet or nil
	arg_1_0.teams = arg_1_2.defense_info.heros
	arg_1_0.baseInfo = arg_1_2.base_info
	arg_1_0.rankInfo = arg_1_2.rank_info or nil
	arg_1_0.serverTime = arg_1_2.server_time or 0
	arg_1_0.enemyList = arg_1_2.enemy_info or {}
	arg_1_0.stage = arg_1_2.stage
end

function var_0_0.updateInfo(arg_2_0)
	arg_2_0.champions:loadInfo(function(arg_3_0, arg_3_1)
		if arg_3_0 == xyd.error.OK then
			for iter_3_0 = 1, #arg_2_0.enemyList do
				if arg_2_0.handle_[iter_3_0] then
					var_0_2.unscheduleGlobal(arg_2_0.handle_[iter_3_0])

					arg_2_0.handle_[iter_3_0] = nil
				end
			end

			arg_2_0.pet = arg_3_1.defense_info.pet or nil
			arg_2_0.teams = arg_3_1.defense_info.heros
			arg_2_0.baseInfo = arg_3_1.base_info
			arg_2_0.rankInfo = arg_3_1.rank_info
			arg_2_0.serverTime = arg_3_1.server_time
			arg_2_0.enemyList = arg_3_1.enemy_info

			if arg_2_0.list then
				arg_2_0.handle_ = {}
				arg_2_0.lastTime_ = {}
				arg_2_0.seconds = {}
				arg_2_0.isChallenge = {}

				arg_2_0.list:reload()
			end
		end
	end)
end

function var_0_0.willOpen(arg_4_0)
	local var_4_0 = {
		ecoBarType = xyd.EcoSidebarType.DISPLAY
	}

	var_4_0.ecoCount = 1
	var_4_0.ecoTypes = {
		var_0_3:getValue("cross_arena_magic_cube_new")
	}
	var_4_0.ecoIcons = {
		"windows/champions_league/icon_cube.png"
	}
	var_4_0.show_rule = true

	arg_4_0:addTopSidebar(var_4_0)

	local var_4_1 = arg_4_0:nodeByName("list_rank")
	local var_4_2 = var_4_1:getContentSize()

	arg_4_0.width = var_4_2.width
	arg_4_0.height = var_4_2.height
	arg_4_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_4_0.width, arg_4_0.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(var_4_1):onScroll(handler(arg_4_0, arg_4_0.scrollListener)):setBounceable(false)
	arg_4_0.crazyEndTime = var_0_3:getValue("cross_arena_party_time_start") + var_0_3:getValue("cross_arena_party_time")
	arg_4_0.crazyBeginTime = var_0_3:getValue("cross_arena_party_time_start")
	arg_4_0.midNightTime = math.floor((arg_4_0.serverTime + 28800) / 86400) * 86400 - 28800
	arg_4_0.isCrazy = false

	if arg_4_0.serverTime >= arg_4_0.midNightTime + arg_4_0.crazyBeginTime and arg_4_0.serverTime <= arg_4_0.midNightTime + arg_4_0.crazyEndTime then
		arg_4_0.isCrazy = true
	end

	arg_4_0.redMarkReport = arg_4_0:nodeByName("red_point")

	if arg_4_0.redMarkReport and arg_4_0.selfPlayer.championsRedMarkEnable then
		arg_4_0.redMarkReport:setVisible(true)
	else
		arg_4_0.redMarkReport:setVisible(false)
	end
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	if arg_5_0.champions.isChangeGroup then
		xyd.WindowManager.get():openWindow("champions_switch")
	end

	arg_5_0:onRegister()
	arg_5_0:layout()
end

function var_0_0.willClose(arg_6_0, arg_6_1)
	if xyd.WindowManager.get():getWindow("champions_league") then
		arg_6_0:nodeByName("txt_myprotect"):setVisible(false)

		for iter_6_0 = 1, #arg_6_0.enemyList do
			if arg_6_0.handle_ and arg_6_0.handle_[iter_6_0] then
				var_0_2.unscheduleGlobal(arg_6_0.handle_[iter_6_0])

				arg_6_0.handle_[iter_6_0] = nil
			end
		end

		if arg_6_0.countDown then
			var_0_2.unscheduleGlobal(arg_6_0.countDown)

			arg_6_0.countDown = nil
		end

		if arg_6_0.crazyDown then
			var_0_2.unscheduleGlobal(arg_6_0.crazyDown)

			arg_6_0.crazyDown = nil
		end
	end
end

function var_0_0.myRankEffect(arg_7_0)
	local var_7_0, var_7_1 = arg_7_0:nodeByName("my_rank"):getPosition()

	arg_7_0:nodeByName("my_rank"):setPosition(cc.p(var_7_0 + 72, var_7_1 - 120))
	arg_7_0:nodeByName("my_rank"):setScale(1.38)

	local var_7_2 = cc.Sequence:create({
		cc.Sequence:create({
			cc.MoveBy:create(0.06, cc.p(-2, 2)),
			cc.MoveBy:create(0.06, cc.p(2, -2)),
			cc.MoveBy:create(0.06, cc.p(2, -2)),
			cc.MoveBy:create(0.06, cc.p(-2, 2))
		}),
		cc.DelayTime:create(0.06),
		cc.Sequence:create({
			cc.Spawn:create({
				cc.RotateBy:create(0.06, -5),
				cc.ScaleTo:create(0.06, 1.43)
			}),
			cc.Spawn:create({
				cc.RotateBy:create(0.06, -5),
				cc.ScaleTo:create(0.06, 1.52),
				cc.MoveBy:create(0.06, cc.p(0, -40))
			}),
			cc.Spawn:create({
				cc.RotateBy:create(0.06, 5),
				cc.ScaleTo:create(0.06, 1.15),
				cc.MoveBy:create(0.06, cc.p(-80, 70))
			}),
			cc.Spawn:create({
				cc.RotateBy:create(0.06, 5),
				cc.ScaleTo:create(0.06, 1.05),
				cc.MoveBy:create(0.06, cc.p(-40, 50))
			}),
			cc.Spawn:create({
				cc.RotateBy:create(0.06, 5),
				cc.ScaleTo:create(0.06, 0.9),
				cc.MoveBy:create(0.06, cc.p(48, 40))
			})
		}),
		cc.Spawn:create({
			cc.CallFunc:create(function()
				local var_8_0 = "windows/champions_league/texiao/paimingtisheng"
				local var_8_1 = var_8_0 .. ".json"
				local var_8_2 = var_8_0 .. ".atlas"
				local var_8_3 = var_0_1.new(var_8_1, var_8_2, 1)

				var_8_3:addTo(arg_7_0, 1)
				var_8_3:pos(var_7_0, var_7_1)
				var_8_3:play(function()
					var_8_3:hide()
				end, false)
			end),
			cc.RotateBy:create(0.1, -5),
			cc.ScaleTo:create(0.1, 1)
		}),
		cc.Sequence:create({
			cc.Spawn:create({
				cc.MoveBy:create(0.06, cc.p(-2, 2)),
				cc.ScaleTo:create(0.06, 1.05)
			}),
			cc.Spawn:create({
				cc.MoveBy:create(0.06, cc.p(2, -2)),
				cc.ScaleTo:create(0.06, 0.95)
			}),
			cc.Spawn:create({
				cc.MoveBy:create(0.06, cc.p(-2, 2)),
				cc.ScaleTo:create(0.06, 1)
			}),
			cc.MoveBy:create(0.06, cc.p(2, -2))
		})
	})

	arg_7_0:nodeByName("my_rank"):runActionOnce(var_7_2, false)
end

function var_0_0.onRegister(arg_10_0)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_10_0):addEventListener(xyd.event.CHAMPIONS_DEFENSE_UPDATE, function(arg_11_0)
		if arg_11_0.params.defenseHeroes then
			local var_11_0 = {}

			for iter_11_0 = 1, #arg_11_0.params.defenseHeroes do
				if #var_11_0 >= 5 then
					break
				elseif arg_11_0.params.defenseHeroes[iter_11_0] then
					table.insert(var_11_0, arg_11_0.params.defenseHeroes[iter_11_0]:getHeroID())
				end
			end

			arg_10_0.pet = arg_11_0.params.pet_id
			arg_10_0.teams = var_11_0

			arg_10_0.champions:setDefense(arg_11_0.params)
			arg_10_0:initDefenceTeam()
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_10_0):addEventListener(xyd.event.CHAMPIONS_ECONOMY_AFTER, function(arg_12_0)
		arg_10_0:nodeByName("eco_sidebar"):update({
			true
		})
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_10_0):addEventListener(xyd.event.CHAMPIONS_CHECK_REDMARK, function(arg_13_0)
		if arg_10_0.redMarkReport then
			arg_10_0.redMarkReport:setVisible(true)
		end
	end)
end

function var_0_0.layout(arg_14_0)
	arg_14_0:initCrazyEffect(arg_14_0.isCrazy)

	local var_14_0 = arg_14_0.serverTime
	local var_14_1 = os.time()

	arg_14_0.crazyDown = var_0_2.scheduleGlobal(function(arg_15_0)
		if (not arg_14_0 or tolua.isnull(arg_14_0)) and arg_14_0.crazyDown and not tolua.isnull(arg_14_0.crazyDown) then
			var_0_2.unscheduleGlobal(arg_14_0.crazyDown)

			arg_14_0.crazyDown = nil
		end

		local var_15_0 = os.time()

		var_14_0 = var_14_0 + (var_15_0 - var_14_1)
		var_14_1 = var_15_0
		arg_14_0.isCrazy = false

		if var_14_0 >= arg_14_0.midNightTime + arg_14_0.crazyBeginTime and var_14_0 <= arg_14_0.midNightTime + arg_14_0.crazyEndTime then
			arg_14_0.isCrazy = true

			if arg_14_0.downSecond and arg_14_0.downSecond >= var_0_8 then
				arg_14_0.downSecond = var_0_8
			end

			for iter_15_0 = 1, #arg_14_0.enemyList do
				if arg_14_0.seconds[iter_15_0] and arg_14_0.seconds[iter_15_0] >= var_0_8 then
					arg_14_0.seconds[iter_15_0] = var_0_8
				end
			end
		end

		arg_14_0:initCrazyEffect(arg_14_0.isCrazy)

		if var_14_0 == arg_14_0.midNightTime + 86400 then
			arg_14_0.midNightTime = arg_14_0.midNightTime + 86400
		end
	end, 1)

	arg_14_0:nodeByName("txt_group"):enableOutline(cc.c4b(32, 32, 32, 255), 2)
	arg_14_0:nodeByName("txt_rate"):setString(var_0_10.txtRate)
	arg_14_0:nodeByName("txt_win"):setString(var_0_10.txtWin)
	arg_14_0:nodeByName("txt_score"):setString(var_0_10.txtScore)
	arg_14_0:nodeByName("txt_honor"):setString(var_0_10.txtHonor)
	arg_14_0:nodeByName("txt_record"):setString(var_0_10.txtRecord)
	arg_14_0:nodeByName("txt_change"):setString(var_0_10.txtChange)
	arg_14_0:nodeByName("txt_first_win"):setString(var_0_10.txtFirstWin)
	arg_14_0:nodeByName("txt_team"):setString(var_0_10.txtTeam)
	arg_14_0:nodeByName("txt_team"):enableOutline(cc.c4b(255, 255, 255, 255), 2)

	local var_14_2
	local var_14_3 = arg_14_0.baseInfo.total_fight == 0 and 0 or math.ceil(arg_14_0.baseInfo.win_fight / arg_14_0.baseInfo.total_fight * 10000) / 100

	arg_14_0:nodeByName("num_rate"):setString(var_14_3 .. "%")
	arg_14_0:nodeByName("num_win"):setString(arg_14_0.baseInfo.win_fight)
	arg_14_0:nodeByName("pos_group"):removeAllChildren()

	if arg_14_0.selfPlayer.lev == var_0_3:getValue("cross_arena_group3_level") then
		local var_14_4 = xyd.AssetLoader.get():loadSprite("windows/champions_league/group3.png")

		var_14_4:setAnchorPoint(cc.p(0, 0))
		arg_14_0:nodeByName("pos_group"):addChild(var_14_4)
		arg_14_0:nodeByName("txt_group"):setString(var_0_10.txtLev .. var_0_10.txtGroup3)

		arg_14_0.group = 3
	elseif arg_14_0.selfPlayer.lev >= var_0_3:getValue("cross_arena_group2_level") then
		local var_14_5 = xyd.AssetLoader.get():loadSprite("windows/champions_league/group2.png")

		var_14_5:setAnchorPoint(cc.p(0, 0))
		arg_14_0:nodeByName("pos_group"):addChild(var_14_5)
		arg_14_0:nodeByName("txt_group"):setString(var_0_10.txtLev .. var_0_10.txtGroup2)

		arg_14_0.group = 2
	elseif arg_14_0.selfPlayer.lev >= var_0_3:getValue("cross_arena_group1_level") then
		local var_14_6 = xyd.AssetLoader.get():loadSprite("windows/champions_league/group1.png")

		var_14_6:setAnchorPoint(cc.p(0, 0))
		arg_14_0:nodeByName("pos_group"):addChild(var_14_6)
		arg_14_0:nodeByName("txt_group"):setString(var_0_10.txtLev .. var_0_10.txtGroup1)

		arg_14_0.group = 1
	end

	arg_14_0:initDefenceTeam()
	arg_14_0:initBtn()
	arg_14_0:nodeByName("txt_end"):setString(var_0_10.hasEnd)
	arg_14_0:nodeByName("bg_hero"):setVisible(false)

	if arg_14_0.stage ~= 1 then
		arg_14_0:nodeByName("bg_hero"):setVisible(true)

		return
	end

	arg_14_0:nodeByName("num_score"):setString(math.floor(arg_14_0.rankInfo.point))

	local var_14_7 = display.newNode()

	local function var_14_8(arg_16_0)
		local var_16_0 = "windows/champions_league/r_" .. arg_16_0 .. ".png"

		return xyd.AssetLoader.get():loadSprite(var_16_0)
	end

	local var_14_9 = arg_14_0.rankInfo.rank
	local var_14_10 = 0
	local var_14_11 = 0

	while var_14_9 ~= 0 do
		local var_14_12 = var_14_9 % 10

		var_14_9 = math.floor(var_14_9 / 10)

		local var_14_13 = var_14_8(var_14_12)

		var_14_13:setAnchorPoint(cc.p(1, 0.5))
		var_14_13:addTo(var_14_7)
		var_14_13:setPosition(cc.p(-var_14_11, 0))

		var_14_11 = var_14_11 + var_14_13:getContentSize().width - 8
		var_14_10 = var_14_10 + 1
	end

	if var_14_10 == 1 then
		-- block empty
	elseif var_14_10 == 2 then
		var_14_7:setScale(0.86)
	elseif var_14_10 == 3 then
		var_14_7:setScale(0.72)
	elseif var_14_10 >= 4 then
		var_14_7:setScale(0.58)
	end

	var_14_7:setAnchorPoint(cc.p(1, 0.5))
	var_14_7:addTo(arg_14_0:nodeByName("pos_myrank"))

	if not arg_14_0.champions.oldRank then
		arg_14_0.champions.oldRank = arg_14_0.rankInfo.rank
	else
		if arg_14_0.champions.oldRank > arg_14_0.rankInfo.rank then
			arg_14_0:myRankEffect()
		end

		arg_14_0.champions.oldRank = arg_14_0.rankInfo.rank
	end

	arg_14_0.handle_ = {}
	arg_14_0.lastTime_ = {}
	arg_14_0.seconds = {}
	arg_14_0.isChallenge = {}

	arg_14_0.list:setDelegate(handler(arg_14_0, arg_14_0.delegate))
	arg_14_0.list:reload()
	arg_14_0:nodeByName("txt_myprotect"):enableOutline(cc.c4b(135, 56, 31, 255), 2)

	local var_14_14

	if arg_14_0.baseInfo.last_attacked_time == 0 then
		var_14_14 = 0
	elseif arg_14_0.isCrazy then
		local var_14_15 = arg_14_0.midNightTime + arg_14_0.crazyBeginTime - arg_14_0.baseInfo.last_attacked_time

		if var_14_15 >= 0 then
			local var_14_16 = var_0_9 - var_14_15

			if var_14_16 >= var_0_8 then
				var_14_14 = var_0_8 - (arg_14_0.serverTime - (arg_14_0.midNightTime + arg_14_0.crazyBeginTime))
			else
				var_14_14 = var_14_16
			end
		else
			local var_14_17 = arg_14_0.serverTime - arg_14_0.baseInfo.last_attacked_time

			var_14_17 = var_14_17 > 0 and var_14_17 or 0
			var_14_14 = var_0_8 - var_14_17

			if var_14_14 <= 0 then
				var_14_14 = 0
			end
		end
	else
		local var_14_18 = arg_14_0.serverTime - arg_14_0.baseInfo.last_attacked_time

		var_14_18 = var_14_18 > 0 and var_14_18 or 0
		var_14_14 = var_0_9 - var_14_18

		if var_14_14 <= 0 then
			var_14_14 = 0
		end
	end

	arg_14_0.downSecond = var_14_14
	arg_14_0.lastSecond = os.time()
	arg_14_0.countDown = var_0_2.scheduleGlobal(function(arg_17_0)
		if not arg_14_0 or tolua.isnull(arg_14_0) or arg_14_0.downSecond <= 0 then
			if not tolua.isnull(arg_14_0.countDown) and arg_14_0.countDown then
				var_0_2.unscheduleGlobal(arg_14_0.countDown)

				arg_14_0.countDown = nil
			end

			if arg_14_0 and not tolua.isnull(arg_14_0) then
				arg_14_0:nodeByName("txt_myprotect"):setVisible(false)
			end

			return
		end

		local var_17_0 = os.time()

		arg_14_0.downSecond = arg_14_0.downSecond - (var_17_0 - arg_14_0.lastSecond)
		arg_14_0.lastSecond = var_17_0

		local var_17_1 = math.floor(arg_14_0.downSecond / 60)

		if var_17_1 < 10 then
			var_17_1 = "0" .. var_17_1
		end

		local var_17_2 = arg_14_0.downSecond % 60

		if var_17_2 < 10 then
			var_17_2 = "0" .. var_17_2
		end

		if arg_14_0 and not tolua.isnull(arg_14_0) then
			arg_14_0:nodeByName("txt_myprotect"):setVisible(true)
			arg_14_0:nodeByName("txt_myprotect"):setString(var_0_10.txtProtect .. var_17_1 .. ":" .. var_17_2)
		end
	end, 1)

	arg_14_0:initFirstWinPresent()
end

function var_0_0.initCrazyEffect(arg_18_0, arg_18_1)
	if arg_18_1 then
		if arg_18_0.crazyEffect1 then
			return
		end

		local var_18_0, var_18_1 = arg_18_0:nodeByName("my_rank"):getPosition()
		local var_18_2 = "windows/champions_league/texiao/kuangre"
		local var_18_3 = var_18_2 .. ".json"
		local var_18_4 = var_18_2 .. ".atlas"

		arg_18_0.crazyEffect1 = var_0_1.new(var_18_3, var_18_4, 1)

		arg_18_0.crazyEffect1:addTo(arg_18_0, 1)
		arg_18_0.crazyEffect1:pos(var_18_0 - 15, var_18_1 - 2)
		arg_18_0.crazyEffect1:play(function()
			return
		end, true)

		local var_18_5 = arg_18_0:nodeByName("container"):getContentSize()
		local var_18_6 = "windows/champions_league/texiao/huoxing"
		local var_18_7 = var_18_6 .. ".json"
		local var_18_8 = var_18_6 .. ".atlas"

		arg_18_0.crazyEffect2 = var_0_1.new(var_18_7, var_18_8, 1)

		arg_18_0.crazyEffect2:addTo(arg_18_0, 1)
		arg_18_0.crazyEffect2:pos(var_18_5.width / 2, var_18_5.height / 2)
		arg_18_0.crazyEffect2:setTouchSwallowEnabled(true)
		arg_18_0.crazyEffect2:play(function()
			return
		end, true)
	elseif arg_18_0.crazyEffect1 then
		arg_18_0.crazyEffect1:hide()
		arg_18_0.crazyEffect1:stop()
		arg_18_0.crazyEffect2:hide()
		arg_18_0.crazyEffect2:stop()
	end
end

function var_0_0.initFirstWinPresent(arg_21_0)
	local var_21_0 = math.floor((arg_21_0.serverTime + 28800 - var_0_3:getValue("cross_arena_first_win_time")) / 86400) * 86400 - 28800 + var_0_3:getValue("cross_arena_first_win_time")
	local var_21_1, var_21_2 = arg_21_0:nodeByName("icon_box"):getPosition()
	local var_21_3 = "windows/champions_league/texiao/lihe"
	local var_21_4 = var_21_3 .. ".json"
	local var_21_5 = var_21_3 .. ".atlas"

	arg_21_0.presentEffect = var_0_1.new(var_21_4, var_21_5, 1)

	arg_21_0.presentEffect:addTo(arg_21_0, 1)
	arg_21_0.presentEffect:pos(var_21_1, var_21_2 + 15)

	arg_21_0.isOpenEffect = false

	local var_21_6 = arg_21_0:initPresentPreview()

	var_21_6:setPosition(cc.p(var_21_1, var_21_2))
	var_21_6:addTo(arg_21_0, 3)
	var_21_6:setVisible(false)

	arg_21_0.isPreview = false

	local var_21_7 = display.newNode()

	var_21_7:setContentSize(cc.size(100, 100))
	var_21_7:setAnchorPoint(cc.p(0.5, 0.5))
	var_21_7:setPosition(var_21_1, var_21_2)
	var_21_7:addTo(arg_21_0, 2)
	var_21_7:setTouchSwallowEnabled(false)
	var_21_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_22_0)
		if arg_22_0.name == "began" then
			if arg_21_0.isPreview then
				var_21_6:setVisible(true)
			end

			return true
		elseif arg_22_0.name == "ended" then
			if arg_21_0.isPreview then
				var_21_6:setVisible(false)

				return
			end

			if arg_21_0.isOpenEffect then
				return
			end

			if arg_21_0.presentEffect then
				arg_21_0.presentEffect:hide()
			end

			arg_21_0.isOpenEffect = true

			local var_22_0 = "windows/champions_league/texiao/lihedakai"
			local var_22_1 = var_22_0 .. ".json"
			local var_22_2 = var_22_0 .. ".atlas"
			local var_22_3 = var_0_1.new(var_22_1, var_22_2, 1)

			var_22_3:addTo(arg_21_0, 1)
			var_22_3:pos(var_21_1, var_21_2 + 15)
			var_22_3:play(function()
				local var_23_0 = cc.Spawn:create({
					cc.MoveBy:create(0.06, cc.p(30, 0)),
					cc.RotateBy:create(0.06, 30)
				})

				arg_21_0:nodeByName("icon_cover"):runActionOnce(var_23_0, false)
				arg_21_0.champions:getDailyAward(function(arg_24_0, arg_24_1)
					if arg_24_0 == xyd.error.OK then
						arg_21_0.selfPlayer:handleRewards(arg_24_1.awards)
						xyd.EventDispatcher.get():dispatchEvent({
							name = xyd.event.CHAMPIONS_ECONOMY_AFTER
						})
					end
				end)

				arg_21_0.isOpenEffect = false

				var_21_7:setTouchEnabled(false)
				var_22_3:hide()
				var_22_3:stop()
			end, false)
		end
	end)

	if var_21_0 < arg_21_0.baseInfo.last_win_time then
		if arg_21_0.baseInfo.can_daily_award == 1 then
			var_21_7:setTouchEnabled(true)
			arg_21_0.presentEffect:show()
			arg_21_0.presentEffect:play(function()
				return
			end, true)
		else
			var_21_7:setTouchEnabled(false)
			arg_21_0:nodeByName("icon_cover"):setPosition(var_21_1 + 30, var_21_2 + 25)
			arg_21_0:nodeByName("icon_cover"):rotation(30)
		end
	else
		var_21_7:setTouchEnabled(true)

		arg_21_0.isPreview = true
	end
end

function var_0_0.initPresentPreview(arg_26_0)
	local var_26_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/champions_league/gift_tip.csb")
	local var_26_1 = var_26_0:getChildByName("container")
	local var_26_2 = arg_26_0.champions:getAwardPreviewInfo(arg_26_0.baseInfo.last_day_group, arg_26_0.baseInfo.last_day_rank)
	local var_26_3 = var_0_4:items(var_26_2)
	local var_26_4 = var_0_4:itemNum(var_26_2)
	local var_26_5 = #var_26_3
	local var_26_6 = 0

	for iter_26_0 = 1, var_26_5 do
		local var_26_7 = display.newNode()

		var_26_7:setContentSize(cc.size(60, 60))
		var_26_7:setAnchorPoint(cc.p(0, 0))
		xyd.setItemBorder(var_26_7, var_26_3[iter_26_0])
		var_26_7:addTo(var_26_1)
		var_26_7:setPosition(20, 40 + var_26_6 * 70)

		local var_26_8 = {
			size = 24,
			color = cc.c3b(255, 255, 255)
		}
		local var_26_9 = xyd.AssetLoader.get():loadLabel(var_26_8)

		var_26_9:setString("x" .. var_26_4[iter_26_0])
		var_26_9:addTo(var_26_1)
		var_26_9:setAnchorPoint(cc.p(0, 0.5))
		var_26_9:setPosition(100, 70 + var_26_6 * 70)

		var_26_6 = var_26_6 + 1
	end

	local var_26_10 = var_0_4:energy(var_26_2)

	if var_26_10 > 0 then
		local var_26_11 = xyd.AssetLoader.get():loadSprite("images/icon/eco/icon_energy.png")

		var_26_11:setAnchorPoint(cc.p(0, 0))
		var_26_11:addTo(var_26_1)
		var_26_11:setPosition(20, 40 + var_26_6 * 70)

		local var_26_12 = {
			size = 24,
			color = cc.c3b(255, 255, 255)
		}
		local var_26_13 = xyd.AssetLoader.get():loadLabel(var_26_12)

		var_26_13:setString("x" .. var_26_10)
		var_26_13:addTo(var_26_1)
		var_26_13:setAnchorPoint(cc.p(0, 0.5))
		var_26_13:setPosition(100, 70 + var_26_6 * 70)

		var_26_6 = var_26_6 + 1
	end

	var_26_1:setContentSize(165, 50 + 70 * var_26_6)

	return var_26_0
end

function var_0_0.initBtn(arg_27_0)
	local var_27_0 = arg_27_0:nodeByName("btn_record")

	var_27_0:addTouchEventListener(function(arg_28_0, arg_28_1)
		if arg_28_1 == ccui.TouchEventType.began then
			var_27_0:setScale(0.9)
		elseif arg_28_1 == ccui.TouchEventType.ended or arg_28_1 == ccui.TouchEventType.canceled then
			var_27_0:setScale(1)

			if arg_27_0.stage ~= 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_10.hasEnd
				})

				return
			end

			arg_27_0.champions:getRecord(function(arg_29_0, arg_29_1)
				if arg_29_0 == xyd.error.OK then
					if arg_27_0.redMarkReport then
						arg_27_0.redMarkReport:setVisible(false)
					end

					local var_29_0 = {
						records = arg_29_1
					}

					xyd.WindowManager.get():openWindow("champions_record", var_29_0)
				end
			end)
		end
	end)

	local var_27_1 = arg_27_0:nodeByName("btn_change")

	var_27_1:addTouchEventListener(function(arg_30_0, arg_30_1)
		if arg_30_1 == ccui.TouchEventType.began then
			var_27_1:setScale(0.9)
		elseif arg_30_1 == ccui.TouchEventType.ended or arg_30_1 == ccui.TouchEventType.canceled then
			var_27_1:setScale(1)

			if arg_27_0.stage ~= 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_10.hasEnd
				})

				return
			end

			xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadShopList({}, function()
				xyd.WindowManager.get():openWindow("champions_shop", {
					shop_type = 35
				})
			end)
		end
	end)

	local var_27_2 = arg_27_0:nodeByName("btn_honor")

	var_27_2:addTouchEventListener(function(arg_32_0, arg_32_1)
		if arg_32_1 == ccui.TouchEventType.began then
			var_27_2:setScale(0.9)
		elseif arg_32_1 == ccui.TouchEventType.ended or arg_32_1 == ccui.TouchEventType.canceled then
			var_27_2:setScale(1)
			arg_27_0.champions:getHonorRankInfo(function(arg_33_0, arg_33_1)
				if arg_33_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("champions_honor_rank", arg_33_1)
				end
			end)
		end
	end)

	local var_27_3 = arg_27_0:nodeByName("top_sidebar"):nodeByName("rule")

	var_27_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_34_0)
		if arg_34_0.name == "began" then
			var_27_3:setScale(0.9)

			return true
		elseif arg_34_0.name == "ended" then
			var_27_3:setScale(1)

			local var_34_0

			if arg_27_0.stage == 1 then
				var_34_0 = {
					group = arg_27_0.rankInfo.ori_group or arg_27_0.rankInfo.group,
					rank = arg_27_0.rankInfo.ori_rank or arg_27_0.rankInfo.rank,
					style = xyd.RuleStyle.YELLOW
				}
			else
				var_34_0 = {
					group = arg_27_0.group,
					stage = arg_27_0.stage
				}
			end

			xyd.WindowManager.get():openWindow("champions_rule", var_34_0)
		end
	end)
end

function var_0_0.delegate(arg_35_0, arg_35_1, arg_35_2, arg_35_3)
	if cc.ui.UIListView.COUNT_TAG == arg_35_2 then
		return #arg_35_0.enemyList
	elseif cc.ui.UIListView.CELL_TAG == arg_35_2 then
		local var_35_0 = arg_35_0.list:dequeueItem()

		if not var_35_0 then
			var_35_0 = arg_35_0.list:newItem()
		else
			var_35_0:removeAllChildren(true)
		end

		local var_35_1 = arg_35_0:createRankItem(arg_35_3)
		local var_35_2 = var_35_1:getContentSize()

		var_35_0:setItemSize(var_35_2.width, var_35_2.height + 5)
		var_35_0:addContent(var_35_1)

		arg_35_0.ITEM_HEIGHT = var_35_2.height + 5

		return var_35_0
	end
end

function var_0_0.createRankItem(arg_36_0, arg_36_1)
	local var_36_0 = display.newNode()
	local var_36_1 = arg_36_0.enemyList[arg_36_1]

	if not var_36_1 then
		return
	end

	local var_36_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/champions_league/item_rank.csb")
	local var_36_3 = var_36_2:getChildByName("container")

	var_36_3:getChildByName("bg_1"):setVisible(false)
	var_36_3:getChildByName("bg_2"):setVisible(false)
	var_36_3:getChildByName("bg_3"):setVisible(false)

	local var_36_4
	local var_36_5

	if arg_36_0.selfPlayer.lev == var_0_3:getValue("cross_arena_group3_level") then
		var_36_3:getChildByName("bg_3"):setVisible(true)

		var_36_4 = cc.c4b(92, 36, 32, 255)
		var_36_5 = cc.c4b(92, 36, 32, 255)
	elseif arg_36_0.selfPlayer.lev >= var_0_3:getValue("cross_arena_group2_level") then
		var_36_3:getChildByName("bg_2"):setVisible(true)

		var_36_4 = cc.c4b(52, 84, 139, 255)
		var_36_5 = cc.c4b(52, 84, 139, 255)
	elseif arg_36_0.selfPlayer.lev >= var_0_3:getValue("cross_arena_group1_level") then
		var_36_3:getChildByName("bg_1"):setVisible(true)

		var_36_4 = cc.c4b(73, 16, 102, 255)
		var_36_5 = cc.c4b(87, 31, 50, 255)
	end

	var_36_3:getChildByName("txt_name"):setString(var_36_1.player_name)
	var_36_3:getChildByName("num_score"):enableOutline(var_36_5, 2)
	var_36_3:getChildByName("num_count_down"):enableOutline(var_36_5, 2)
	var_36_3:getChildByName("txt_score"):setColor(var_36_4)
	var_36_3:getChildByName("txt_count_down"):setColor(var_36_4)
	var_36_3:getChildByName("txt_score"):setString(var_0_10.txtEnemyScore)
	var_36_3:getChildByName("num_score"):setString(math.floor(var_36_1.point))
	var_36_3:getChildByName("txt_count_down"):setString(var_0_10.txtProtect)
	var_36_3:getChildByName("txt_count_down"):setVisible(false)
	var_36_3:getChildByName("num_count_down"):setVisible(false)

	arg_36_0.isChallenge[arg_36_1] = false

	local var_36_6

	if var_36_1.last_attacked_time == 0 then
		var_36_6 = 0
	elseif arg_36_0.isCrazy then
		local var_36_7 = arg_36_0.midNightTime + arg_36_0.crazyBeginTime - var_36_1.last_attacked_time

		if var_36_7 >= 0 then
			local var_36_8 = var_0_9 - var_36_7

			if var_36_8 >= var_0_8 then
				var_36_6 = var_0_8 - (arg_36_0.serverTime - (arg_36_0.midNightTime + arg_36_0.crazyBeginTime))
			else
				var_36_6 = var_36_8
			end
		else
			local var_36_9 = arg_36_0.serverTime - var_36_1.last_attacked_time

			var_36_9 = var_36_9 > 0 and var_36_9 or 0
			var_36_6 = var_0_8 - var_36_9

			if var_36_6 <= 0 then
				var_36_6 = 0
			end
		end
	else
		local var_36_10 = arg_36_0.serverTime - var_36_1.last_attacked_time

		var_36_10 = var_36_10 > 0 and var_36_10 or 0
		var_36_6 = var_0_9 - var_36_10

		if var_36_6 <= 0 then
			var_36_6 = 0
		end
	end

	if not arg_36_0.lastTime_[arg_36_1] then
		arg_36_0.seconds[arg_36_1] = var_36_6
	end

	arg_36_0.lastTime_[arg_36_1] = os.time()

	if arg_36_0.seconds[arg_36_1] > 0 then
		local var_36_11 = math.floor(arg_36_0.seconds[arg_36_1] / 60)

		if var_36_11 < 10 then
			var_36_11 = "0" .. var_36_11
		end

		local var_36_12 = arg_36_0.seconds[arg_36_1] % 60

		if var_36_12 < 10 then
			var_36_12 = "0" .. var_36_12
		end

		if var_36_3 and not tolua.isnull(var_36_3) and var_36_3:getChildByName("txt_count_down") then
			var_36_3:getChildByName("txt_count_down"):setVisible(true)
			var_36_3:getChildByName("num_count_down"):setVisible(true)
			var_36_3:getChildByName("num_count_down"):setString(var_36_11 .. ":" .. var_36_12)
		end
	end

	if arg_36_0.seconds[arg_36_1] and arg_36_0.seconds[arg_36_1] > 0 then
		arg_36_0.isChallenge[arg_36_1] = false
	else
		arg_36_0.isChallenge[arg_36_1] = true
	end

	arg_36_0.handle_[arg_36_1] = var_0_2.scheduleGlobal(function(arg_37_0)
		if not arg_36_0 or tolua.isnull(arg_36_0) or arg_36_0.seconds[arg_36_1] <= 0 then
			if not tolua.isnull(arg_36_0.handle_) and arg_36_0.handle_[arg_36_1] then
				var_0_2.unscheduleGlobal(arg_36_0.handle_[arg_36_1])

				arg_36_0.handle_[arg_36_1] = nil
			end

			if var_36_3 and not tolua.isnull(var_36_3) and var_36_3:getChildByName("txt_count_down") then
				var_36_3:getChildByName("txt_count_down"):setVisible(false)
				var_36_3:getChildByName("num_count_down"):setVisible(false)

				arg_36_0.isChallenge[arg_36_1] = true
			end

			return
		end

		local var_37_0 = os.time()

		arg_36_0.seconds[arg_36_1] = arg_36_0.seconds[arg_36_1] - (var_37_0 - arg_36_0.lastTime_[arg_36_1])
		arg_36_0.lastTime_[arg_36_1] = var_37_0

		local var_37_1 = math.floor(arg_36_0.seconds[arg_36_1] / 60)

		if var_37_1 < 10 then
			var_37_1 = "0" .. var_37_1
		end

		local var_37_2 = arg_36_0.seconds[arg_36_1] % 60

		if var_37_2 < 10 then
			var_37_2 = "0" .. var_37_2
		end

		if var_36_3 and not tolua.isnull(var_36_3) and var_36_3:getChildByName("txt_count_down") then
			arg_36_0.isChallenge[arg_36_1] = false

			var_36_3:getChildByName("txt_count_down"):setVisible(true)
			var_36_3:getChildByName("num_count_down"):setVisible(true)
			var_36_3:getChildByName("num_count_down"):setString(var_37_1 .. ":" .. var_37_2)
		end
	end, 1)

	local var_36_13 = display.newNode()

	local function var_36_14(arg_38_0)
		local var_38_0 = "windows/champions_league/w_" .. arg_38_0 .. ".png"

		return xyd.AssetLoader.get():loadSprite(var_38_0)
	end

	local var_36_15 = var_36_1.rank
	local var_36_16 = 0

	while var_36_15 ~= 0 do
		local var_36_17 = var_36_15 % 10

		var_36_15 = math.floor(var_36_15 / 10)

		local var_36_18 = var_36_14(var_36_17)

		var_36_18:setAnchorPoint(cc.p(1, 0))
		var_36_18:addTo(var_36_13)
		var_36_18:setPosition(cc.p(-var_36_16, 0))

		var_36_16 = var_36_16 + var_36_18:getContentSize().width
	end

	var_36_13:setAnchorPoint(cc.p(0, 0))
	var_36_13:addTo(var_36_3:getChildByName("pos_rank"))
	var_36_13:setPosition(cc.p(var_36_16 / 2, 0))
	var_36_2:addTo(var_36_0)
	var_36_2:setAnchorPoint(cc.p(0, 0))
	var_36_0:setContentSize(var_36_3:getContentSize())
	var_36_0:setTouchEnabled(true)
	var_36_0:setTouchSwallowEnabled(false)

	if var_36_1.player_id == arg_36_0.selfPlayer.playerID then
		var_36_0:setTouchEnabled(false)
	end

	local var_36_19, var_36_20 = arg_36_0:nodeByName("list_rank"):getPosition()

	var_36_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_39_0)
		if arg_39_0.name == "began" then
			var_36_0:setScale(0.9)

			return true
		elseif arg_39_0.name == "canceled" then
			var_36_0:setScale(1)
		elseif arg_39_0.name == "ended" then
			var_36_0:setScale(1)

			if not arg_36_0.scrollViewMoved_ then
				xyd.playButtonSound()

				if arg_36_0.champions.isChangeGroup then
					xyd.WindowManager.get():openWindow("champions_switch")
				else
					if arg_36_1 - arg_36_0.rankInfo.rank > 10 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_10.txtOutRank
						})

						return
					end

					local var_39_0 = arg_36_0.list.scrollNode:getPositionY()
					local var_39_1

					if var_39_0 % arg_36_0.ITEM_HEIGHT > arg_36_0.ITEM_HEIGHT / 2 then
						var_39_1 = math.ceil(var_39_0 / arg_36_0.ITEM_HEIGHT)
					else
						var_39_1 = math.floor(var_39_0 / arg_36_0.ITEM_HEIGHT)
					end

					if var_39_1 <= 3 then
						var_39_1 = 3
					end

					if var_39_1 - arg_36_1 >= 4 then
						var_39_1 = var_39_1 - 1
					end

					if var_39_1 - arg_36_1 < 0 then
						var_39_1 = var_39_1 + 1
					end

					local var_39_2 = arg_36_0.ITEM_HEIGHT * var_39_1

					arg_36_0.list.scrollNode:setPositionY(var_39_2)

					local var_39_3 = {
						enemy_id = var_36_1.player_id
					}

					arg_36_0.champions:getEnemy(var_39_3, function(arg_40_0, arg_40_1)
						if arg_40_0 == xyd.error.OK and arg_36_0 and not tolua.isnull(arg_36_0) then
							local var_40_0 = {
								player_id = var_36_1.player_id,
								player_name = var_36_1.player_name,
								rank = var_36_1.rank,
								posX = var_36_19,
								posY = var_39_2 + var_36_20 - arg_36_0.ITEM_HEIGHT * arg_36_1,
								heros = arg_40_1.heros,
								pet = arg_40_1.pet,
								isChallenge = arg_36_0.isChallenge[arg_36_1]
							}

							xyd.WindowManager.get():openWindow("champions_rank", var_40_0)
						end
					end)
				end
			end
		end
	end)

	return var_36_0
end

function var_0_0.initDefenceTeam(arg_41_0)
	arg_41_0:nodeByName("pos_team"):removeAllChildren()

	local var_41_0 = display.newNode()
	local var_41_1 = 0 + var_0_6[1] / 0.9
	local var_41_2

	if arg_41_0.pet and arg_41_0.pet ~= 0 then
		var_41_2 = arg_41_0.selfPlayer:getPetByID(tonumber(arg_41_0.pet))
	else
		var_41_2 = nil
	end

	local var_41_3 = arg_41_0:initCard(var_41_2, 1, true)
	local var_41_4 = var_41_3:getContentSize()

	var_41_3:setPosition(cc.p(var_41_1 + var_41_4.width / 2, var_41_4.height / 2))
	var_41_3:addTo(var_41_0)

	for iter_41_0 = 1, 5 do
		var_41_1 = var_41_1 + var_0_6[iter_41_0 + 1] / 0.9

		local var_41_5

		if iter_41_0 <= #arg_41_0.teams then
			var_41_5 = arg_41_0.selfPlayer:getHero(tonumber(arg_41_0.teams[iter_41_0]))
		else
			var_41_5 = nil
		end

		local var_41_6 = arg_41_0:initCard(var_41_5, iter_41_0 + 1, false)
		local var_41_7 = var_41_6:getContentSize()

		var_41_6:setPosition(cc.p(var_41_1 + var_41_7.width / 2, var_41_7.height / 2))
		var_41_6:addTo(var_41_0)
	end

	var_41_0:addTo(arg_41_0:nodeByName("pos_team"))
end

function var_0_0.initCard(arg_42_0, arg_42_1, arg_42_2, arg_42_3)
	local var_42_0 = (arg_42_2 - 1) % 3 + 1
	local var_42_1 = display.newNode()
	local var_42_2 = cc.ClippingNode:create()
	local var_42_3 = xyd.AssetLoader:get():loadSprite("windows/champions_league/bg_stencil" .. var_42_0 .. ".png")
	local var_42_4 = var_42_3:getContentSize()
	local var_42_5 = var_42_4.width
	local var_42_6 = var_42_4.height

	var_42_3:setPosition(var_42_5 / 2, var_42_6 / 2)
	var_42_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_42_2:setStencil(var_42_3)
	var_42_2:setInverted(false)
	var_42_2:setAlphaThreshold(0)
	var_42_1:addChild(var_42_2)

	local var_42_7

	if arg_42_1 then
		if arg_42_3 then
			local var_42_8 = xyd.AssetLoader.get():loadSprite("windows/champions_league/bg_pet.png")

			var_42_2:addChild(var_42_8)
			var_42_8:setPosition(var_42_5 / 2, var_42_6 / 2)
			var_42_8:setAnchorPoint(cc.p(0.5, 0.5))

			local var_42_9 = arg_42_1:getAvatar(2)
			local var_42_10 = xyd.AssetLoader.get():loadSprite(var_42_9)

			var_42_2:addChild(var_42_10)
			var_42_10:setPosition(var_42_5 / 2, var_42_6 / 2)
			var_42_10:setAnchorPoint(cc.p(0.5, 0.5))
		else
			local var_42_11 = xyd.getNormalCard(arg_42_1, 6)
			local var_42_12 = var_42_6 / var_42_11:getHeight()

			var_42_11:setScale(var_42_12)
			var_42_2:addChild(var_42_11)
			var_42_11:setPosition(var_42_5 / 2, var_42_6 / 2)
			var_42_11:setAnchorPoint(cc.p(0.5, 0.5))
		end
	else
		local var_42_13 = xyd.AssetLoader.get():loadSprite("windows/champions_league/bg_pet.png")

		var_42_2:addChild(var_42_13)
		var_42_13:setPosition(var_42_5 / 2, var_42_6 / 2)
		var_42_13:setAnchorPoint(cc.p(0.5, 0.5))

		local var_42_14 = xyd.AssetLoader.get():loadSprite("windows/champions_league/icon_add.png")

		var_42_2:addChild(var_42_14)
		var_42_14:setPosition(var_42_5 / 2, var_42_6 / 2)
		var_42_14:setAnchorPoint(cc.p(0.5, 0.5))
	end

	local var_42_15 = xyd.AssetLoader:get():loadSprite("windows/champions_league/bg_frame" .. var_42_0 .. ".png")

	var_42_15:setPosition(var_42_5 / 2, var_42_6 / 2)
	var_42_15:setAnchorPoint(cc.p(0.5, 0.5))
	var_42_1:addChild(var_42_15)

	if arg_42_1 then
		local var_42_16 = xyd.AssetLoader:get():loadSprite("windows/champions_league/bg_name" .. var_42_0 .. ".png")

		var_42_2:addChild(var_42_16)
		var_42_16:setPosition(var_42_5 / 2 + var_0_7[arg_42_2], 0)
		var_42_16:setAnchorPoint(cc.p(0.5, 0))

		local var_42_17 = var_42_16:getContentSize()
		local var_42_18 = arg_42_1:getName()
		local var_42_19 = {
			size = 20,
			align = cc.ui.TEXT_ALIGN_CENTER,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			color = cc.c4b(255, 245, 180, 255),
			text = var_42_18
		}
		local var_42_20 = xyd.AssetLoader.get():loadLabel(var_42_19)

		var_42_2:addChild(var_42_20)
		var_42_20:setPosition(var_42_5 / 2 + var_0_7[arg_42_2], var_42_17.height / 2 + 5)
		var_42_20:setAnchorPoint(cc.p(0.5, 0.5))

		local var_42_21 = arg_42_1:getStar()

		local function var_42_22()
			local var_43_0
			local var_43_1 = xyd.isSuperHero(arg_42_1) and var_42_21 > xyd.MAX_STAR_LEVEL and "windows/common/hero_common/icon_pink_star.png" or "windows/common/hero_common/icon_hero_star.png"

			return xyd.AssetLoader.get():loadSprite(var_43_1)
		end

		local var_42_23 = var_42_21

		if var_42_23 > xyd.MAX_STAR_LEVEL then
			var_42_23 = var_42_23 - xyd.MAX_STAR_LEVEL
		end

		local var_42_24 = var_42_22()
		local var_42_25 = var_42_24:getWidth()
		local var_42_26 = var_42_25 + (var_42_23 - 1) * 20
		local var_42_27 = var_42_24:getHeight()
		local var_42_28 = display.newNode()

		var_42_28:setContentSize(var_42_26, var_42_27)
		var_42_28:setAnchorPoint(0.5, 0.5)
		var_42_28:setPosition(cc.p(0.5 * var_42_4.width, var_42_27 / 2))
		var_42_24:addTo(var_42_28, 10)
		var_42_24:setAnchorPoint(0.5, 0.5)
		var_42_24:setPosition(var_42_25 / 2, var_42_27 / 2 + 2)

		for iter_42_0 = 1, var_42_23 - 1 do
			local var_42_29 = var_42_22()

			var_42_29:addTo(var_42_28, 10 - iter_42_0)
			var_42_29:setAnchorPoint(0.5, 0.5)
			var_42_29:setPosition(var_42_25 / 2 + iter_42_0 * 20, var_42_27 / 2 + 2)
		end

		var_42_28:setScale(0.75)
		var_42_2:addChild(var_42_28)
		var_42_28:setPosition(var_42_5 / 2 + var_0_7[arg_42_2], var_42_17.height + var_42_27 / 2 + 5)
		var_42_28:setAnchorPoint(cc.p(0.5, 0.5))
	end

	var_42_2:setLocalZOrder(-1)

	local var_42_30 = display.newNode()

	var_42_30:setContentSize(var_42_4.width - 30, var_42_4.height)
	var_42_30:addTo(var_42_1)
	var_42_30:setAnchorPoint(cc.p(0.5, 0.5))
	var_42_30:setPosition(cc.p(var_42_4.width / 2, var_42_4.height / 2))
	var_42_30:setTouchEnabled(true)
	var_42_30:setTouchSwallowEnabled(false)
	var_42_30:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_44_0)
		if arg_44_0.name == "began" then
			var_42_1:setScale(0.95)

			return true
		elseif arg_44_0.name == "canceled" then
			var_42_1:setScale(1)
		elseif arg_44_0.name == "ended" then
			var_42_1:setScale(1)

			if arg_42_0.stage ~= 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_10.hasEnd
				})

				return
			end

			local var_44_0 = {}
			local var_44_1 = {}
			local var_44_2 = {}

			for iter_44_0 = 1, #arg_42_0.teams do
				table.insert(var_44_2, tonumber(arg_42_0.teams[iter_44_0]))
				table.insert(var_44_1, arg_42_0.selfPlayer:getHero(tonumber(arg_42_0.teams[iter_44_0])))
			end

			var_44_0.type = xyd.SelectTeamType.CHAMPIONS_DEFENSE
			var_44_0.selected = var_44_2
			var_44_0.preHeros = var_44_1

			if arg_42_0.pet and arg_42_0.pet ~= 0 then
				var_44_0.prePet = {}

				table.insert(var_44_0.prePet, arg_42_0.selfPlayer:getPetByID(arg_42_0.pet))

				var_44_0.petSelect = {}

				table.insert(var_44_0.petSelect, arg_42_0.selfPlayer:getPetByID(arg_42_0.pet))
			end

			xyd.WindowManager.get():openWindow("champions_select_team", var_44_0)
		end
	end)
	var_42_1:setContentSize(var_42_15:getContentSize())
	var_42_1:setAnchorPoint(cc.p(0.5, 0.5))

	return var_42_1
end

function var_0_0.scrollListener(arg_45_0, arg_45_1)
	if arg_45_1.name == "began" then
		arg_45_0.scrollViewMoved_ = false
		arg_45_0.prevY_ = arg_45_1.y
	elseif arg_45_1.name == "moved" and 20 <= math.abs(arg_45_1.y - arg_45_0.prevY_) then
		arg_45_0.scrollViewMoved_ = true
	end
end

return var_0_0
