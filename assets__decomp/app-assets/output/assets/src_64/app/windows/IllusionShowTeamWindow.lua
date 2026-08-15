local var_0_0 = class("IllusionShowTeamWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Pet")
local var_0_2 = import("app.model.Hero")
local var_0_3 = xyd.tables.translation
local var_0_4 = import("app.common.ui.SpineEffect")
local var_0_5 = 160
local var_0_6 = 3

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.illusion = xyd.ModelManager.get():loadModel(xyd.ModelType.ILLUSION)
	arg_1_0.heroItems_ = {}
	arg_1_0.prepareBtnCanUse = true
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar({
		show_rule = true
	})
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:setButtonClick()
	arg_3_0:updateHeros()
	arg_3_0:showChatWin()
	arg_3_0:nodeByName("word_prepare"):setString(var_0_3:translation("PARADISE_TEXT_1"))
	arg_3_0:nodeByName("word_cancel"):setString(var_0_3:translation("CANCEL"))

	arg_3_0.rule_btn = arg_3_0:nodeByName("top_sidebar"):nodeByName("rule")

	xyd.addTouchEvent(arg_3_0.rule_btn, function()
		xyd.WindowManager.get():openWindow("illusion_rule", {
			rank = arg_3_0.illusion.rank
		})
	end)
end

function var_0_0.updatePrepareBtn(arg_5_0)
	if arg_5_0.illusion:getSelfStatus() == 1 then
		arg_5_0:nodeByName("btn_prepare"):getChildByName("word_cancel"):setVisible(true)
		arg_5_0:nodeByName("btn_prepare"):getChildByName("word_prepare"):setVisible(false)

		arg_5_0.isPrepare = true
	else
		arg_5_0.isPrepare = false

		arg_5_0:nodeByName("btn_prepare"):getChildByName("word_cancel"):setVisible(false)
		arg_5_0:nodeByName("btn_prepare"):getChildByName("word_prepare"):setVisible(true)
	end
end

function var_0_0.setButtonClick(arg_6_0)
	arg_6_0:updatePrepareBtn()
	xyd.nodeEventSample(arg_6_0:nodeByName("btn_prepare"), nil, function()
		xyd.playButtonSound()

		if not arg_6_0.prepareBtnCanUse then
			local var_7_0 = var_0_3:translation("ILLUSION_TEAM_TIPS_27")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_7_0
			})

			return
		end

		arg_6_0.prepareBtnCanUse = false

		arg_6_0:performWithDelay(function()
			if arg_6_0 and not tolua.isnull(arg_6_0) then
				arg_6_0.prepareBtnCanUse = true
			end
		end, var_0_6)

		if arg_6_0.illusion:getSelfStatus() == 0 then
			if arg_6_0:checkCanPrepareFight() then
				arg_6_0.illusion:prepareFight()
			else
				local var_7_1 = var_0_3:translation("ILLUSION_TEAM_TIPS_17")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_7_1
				})
			end
		else
			arg_6_0.illusion:cancelPrepareFight()
		end
	end)
	xyd.nodeEventSample(arg_6_0:nodeByName("btn_fight"), nil, function()
		xyd.playButtonSound()

		if arg_6_0:checkIsMaster() and arg_6_0:checkCanFight() then
			arg_6_0.illusion:startTeamFight()
		else
			local var_9_0 = var_0_3:translation("ILLUSION_TEAM_TIPS_16")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_9_0
			})
		end
	end)

	for iter_6_0 = 1, 3 do
		arg_6_0:nodeByName("bottom_item_" .. iter_6_0):setTouchEnabled(true)
		arg_6_0:nodeByName("bottom_item_" .. iter_6_0):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
			if arg_10_0.name == "began" then
				arg_6_0:nodeByName("bottom_item_" .. iter_6_0):getChildByName("img_add_" .. iter_6_0):setScale(0.9)

				return true
			elseif arg_10_0.name == "ended" and not arg_6_0.isPrepare then
				arg_6_0:nodeByName("bottom_item_" .. iter_6_0):getChildByName("img_add_" .. iter_6_0):setScale(1)

				local var_10_0 = {
					index = iter_6_0,
					isPet = iter_6_0 == 3 and true or false,
					selfHeros = arg_6_0.selfHeroIDs
				}

				xyd.WindowManager.get():openWindow("illusion_select_hero", var_10_0)
			end
		end)
	end

	if arg_6_0:checkIsMaster() then
		arg_6_0:nodeByName("bottom_item_2"):setVisible(false)
	else
		arg_6_0:nodeByName("bottom_item_3"):setVisible(false)
		arg_6_0:nodeByName("btn_fight"):setVisible(false)
		arg_6_0:nodeByName("btn_prepare"):runAction(cc.MoveBy:create(0, cc.p(-35, 0)))
	end

	arg_6_0:nodeByName("img_chat"):setTouchEnabled(true)
	arg_6_0:nodeByName("img_chat"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
		if arg_11_0.name == "began" then
			arg_6_0:nodeByName("img_chat"):setScale(0.9)

			return true
		elseif arg_11_0.name == "ended" then
			arg_6_0:nodeByName("img_chat"):setScale(1)
			arg_6_0:showChatWin()
			arg_6_0:updateRedMark(false)
		end
	end)
end

function var_0_0.updateHeros(arg_12_0)
	arg_12_0.selfHeroIDs = arg_12_0.illusion:getSelfHeroID()
	arg_12_0.selfHeroInfos = arg_12_0.illusion:getSelfHeros()
	arg_12_0.selfHeros = {}

	for iter_12_0 = 1, #arg_12_0.selfHeroInfos do
		if arg_12_0.selfHeroInfos[iter_12_0] and next(arg_12_0.selfHeroInfos[iter_12_0]) and arg_12_0.selfHeroInfos[iter_12_0].table_id ~= 0 then
			local var_12_0 = var_0_2.new()

			var_12_0:populate(arg_12_0.selfHeroInfos[iter_12_0])
			arg_12_0:updateHeroSelect(iter_12_0, var_12_0)
			table.insert(arg_12_0.selfHeros, var_12_0)
		end
	end

	if arg_12_0:checkIsMaster() then
		local var_12_1 = arg_12_0.illusion:getTeamInfo()

		if var_12_1.master_pet_detail and next(var_12_1.master_pet_detail) and var_12_1.master_pet_detail.table_id ~= 0 then
			local var_12_2 = var_0_1.new()

			var_12_2:populate(var_12_1.master_pet_detail)
			arg_12_0:updateHeroSelect(3, var_12_2)
		end
	end

	arg_12_0:updateHeroList()
end

function var_0_0.updateHeroSelect(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = arg_13_0:nodeByName("bottom_item_" .. arg_13_1)

	if arg_13_2 then
		var_13_0:getChildByName("img_add_" .. arg_13_1):setVisible(false)
	end

	var_13_0:getChildByName("hero_" .. arg_13_1):removeAllChildren(true)

	if arg_13_1 == 3 then
		xyd.setPetAvatar(var_13_0:getChildByName("hero_" .. arg_13_1), arg_13_2, nil, true)
	else
		xyd.setAvatarBorderNewUI(arg_13_2, var_13_0:getChildByName("hero_" .. arg_13_1))
	end
end

function var_0_0.checkIsMaster(arg_14_0)
	local var_14_0 = arg_14_0.illusion:getMasterID()

	if arg_14_0.selfPlayer.playerID == var_14_0 then
		return true
	end

	return false
end

function var_0_0.updateHeroList(arg_15_0)
	for iter_15_0 = 1, 6 do
		if iter_15_0 == 1 then
			arg_15_0:createPet(iter_15_0)
		else
			arg_15_0:createHero(iter_15_0)
		end
	end
end

function var_0_0.createPet(arg_16_0, arg_16_1)
	local var_16_0 = arg_16_0.illusion:getTeamInfo()
	local var_16_1 = var_16_0.master_pet_detail or {}
	local var_16_2 = arg_16_0.heroItems_[arg_16_1]

	if not var_16_2 or tolua.isnull(var_16_2) then
		var_16_2 = display.newNode()

		var_16_2:setContentSize(var_0_5, var_0_5)
		var_16_2:setAnchorPoint(cc.p(0, 0))
		var_16_2:addTo(arg_16_0:nodeByName("hero_list"))
		var_16_2:setPosition(cc.p(0, 0))

		arg_16_0.heroItems_[arg_16_1] = var_16_2
	end

	if var_16_2.data and next(var_16_1) and var_16_2.data:getTableID() == var_16_1.table_id then
		if var_16_0.master_status ~= var_16_2.status then
			var_16_2.status = var_16_0.master_status

			arg_16_0:updateHeroItemPrepare(var_16_2)
		end

		return
	elseif not var_16_1 or not next(var_16_1) then
		arg_16_0.havePet = false

		return
	end

	local var_16_3 = var_0_1.new()

	var_16_3:populate(var_16_1)

	var_16_2.data = var_16_3
	var_16_2.status = 0
	var_16_2.playerInfo = var_16_0.master_id_info

	local var_16_4 = (var_16_2.count or 0) + 1

	var_16_2.count = var_16_4

	local var_16_5 = var_16_3:getHeroModel()

	var_16_5:setScale(0.75)
	var_16_5:addTo(var_16_2)
	var_16_5:setName("count_" .. var_16_4)
	var_16_5:setPosition(cc.p(var_0_5 / 2, 0))
	var_16_5:setVisible(false)

	arg_16_0.havePet = true

	arg_16_0:updateHeroItemPrepare(var_16_2)
	arg_16_0:addClickEvent(var_16_2)

	if var_16_4 ~= 1 then
		var_16_2:removeChildByName("count_" .. var_16_4 - 1)

		if var_16_2:getChildByName("effect") then
			var_16_2:removeChildByName("effect")
		end
	end

	arg_16_0:showSummonEffcet(var_16_2, function()
		if arg_16_0 and not tolua.isnull(arg_16_0) then
			var_16_5:setVisible(true)
		end
	end)
end

function var_0_0.createHero(arg_18_0, arg_18_1)
	local var_18_0 = arg_18_0.illusion:getHeroInfoByIndex(arg_18_1)
	local var_18_1 = arg_18_0.heroItems_[arg_18_1]

	if not var_18_1 or tolua.isnull(var_18_1) then
		var_18_1 = display.newNode()

		var_18_1:setContentSize(var_0_5, var_0_5)
		var_18_1:setAnchorPoint(cc.p(0, 0))
		var_18_1:addTo(arg_18_0:nodeByName("hero_list"))
		var_18_1:setPosition(cc.p((var_0_5 + 20) * (arg_18_1 - 1), 0))

		arg_18_0.heroItems_[arg_18_1] = var_18_1
	end

	if var_18_1.data and next(var_18_0) and var_18_1.data:getTableID() == var_18_0.table_id then
		if var_18_1.status ~= var_18_0.team_status then
			var_18_1.status = var_18_0.team_status

			arg_18_0:updateHeroItemPrepare(var_18_1)
		end

		return
	elseif not var_18_0 or not next(var_18_0) or var_18_0.table_id == 0 then
		return
	end

	local var_18_2 = var_0_2.new()

	var_18_2:populate(var_18_0)

	if var_18_0.player_info and var_18_0.player_info.conquer_lev then
		local var_18_3 = var_18_0.player_info.conquer_lev

		var_18_2:setConquerSchoolLev(var_18_3)
	end

	var_18_1.data = var_18_2
	var_18_1.playerInfo = var_18_0.player_info
	var_18_1.status = 0

	local var_18_4 = (var_18_1.count or 0) + 1

	var_18_1.count = var_18_4

	local var_18_5 = var_18_2:getHeroModel()

	var_18_5:setScale(0.75)
	var_18_5:addTo(var_18_1)
	var_18_5:setPosition(cc.p(var_0_5 / 2, 0))
	var_18_5:setName("count_" .. var_18_4)
	var_18_5:setVisible(false)
	arg_18_0:updateHeroItemPrepare(var_18_1)
	arg_18_0:addClickEvent(var_18_1)

	if var_18_4 ~= 1 then
		var_18_1:removeChildByName("count_" .. var_18_4 - 1)

		if var_18_1:getChildByName("effect") then
			var_18_1:removeChildByName("effect")
		end
	end

	arg_18_0:showSummonEffcet(var_18_1, function()
		if arg_18_0 and not tolua.isnull(arg_18_0) then
			var_18_5:setVisible(true)
		end
	end)
end

function var_0_0.showSummonEffcet(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0 = "skeletons/ui_effect/effect_summon/effect_summon"
	local var_20_1 = arg_20_1:getContentSize()
	local var_20_2 = var_0_4.new(var_20_0 .. ".json", var_20_0 .. ".atlas", 1)

	var_20_2:addTo(arg_20_1)
	var_20_2:setPosition(cc.p(var_20_1.width / 2, 0))
	var_20_2:setName("effect")
	var_20_2:play(function()
		if arg_20_2 then
			arg_20_2()
		end
	end, false)
end

function var_0_0.updateHeroItemPrepare(arg_22_0, arg_22_1)
	local var_22_0 = arg_22_1.status == 1 and true or false

	if not arg_22_1:getChildByName("hero_prepare") then
		local var_22_1 = {
			size = 24,
			color = cc.c3b(255, 233, 50)
		}
		local var_22_2 = xyd.AssetLoader.get():loadLabel(var_22_1)

		var_22_2:setString(var_0_3:translation("PARADISE_TEXT_2"))
		var_22_2:setAnchorPoint(cc.p(0.5, 0.5))
		var_22_2:enableOutline(cc.c4b(65, 74, 84, 255), 2)
		var_22_2:addTo(arg_22_1)
		var_22_2:setPosition(cc.p(var_0_5 / 2, var_0_5 + 100))
		var_22_2:setName("hero_prepare")
		var_22_2:setLocalZOrder(100)
	end

	arg_22_1:getChildByName("hero_prepare"):setVisible(var_22_0)
end

function var_0_0.checkCanFight(arg_23_0)
	local var_23_0 = arg_23_0.illusion:getTeamInfo()

	if var_23_0.master_status == 1 and var_23_0.mate_1_status == 1 and var_23_0.mate_2_status == 1 then
		local var_23_1 = arg_23_0.illusion:getSelectHeros()
		local var_23_2 = {}

		for iter_23_0 = 1, #var_23_1 do
			if var_23_2[var_23_1[iter_23_0]] then
				return false
			else
				local var_23_3 = xyd.tables.hero:beforeAwaken(var_23_1[iter_23_0])
				local var_23_4 = xyd.tables.hero:afterAwaken(var_23_1[iter_23_0])

				var_23_2[var_23_3] = true
				var_23_2[var_23_4] = true
			end
		end

		return true
	end

	return false
end

function var_0_0.checkCanPrepareFight(arg_24_0)
	if #arg_24_0.selfHeros == 1 and arg_24_0:checkIsMaster() and arg_24_0.havePet or #arg_24_0.selfHeros == 2 then
		return true
	end

	return false
end

function var_0_0.showChatWin(arg_25_0)
	if arg_25_0.chatWinIsShow then
		arg_25_0.chatWinIsShow = false

		arg_25_0:playChatWinMove(arg_25_0.chatWinIsShow)

		return
	elseif arg_25_0.chatIsInit then
		arg_25_0.chatWinIsShow = true

		arg_25_0:playChatWinMove(arg_25_0.chatWinIsShow)

		return
	end

	local var_25_0 = arg_25_0:nodeByName("chat_container")

	var_25_0:setTouchSwallowEnabled(true)
	var_25_0:removeAllChildren()

	local var_25_1 = import("app.windows.IllusionChatWnd").new()
	local var_25_2 = {}

	var_25_1:setParams(var_25_2)
	var_25_1:addTo(var_25_0)
	var_25_1:setPosition(cc.p(0, 0))
	var_25_1:setName("chat_wnd")
	var_25_0:setVisible(false)

	arg_25_0.chatIsInit = true
	arg_25_0.chatWinIsShow = false

	var_25_1:updateList()
	arg_25_0:updateRedMark(false)
end

function var_0_0.updateRedMark(arg_26_0, arg_26_1)
	if arg_26_0.chatWinIsShow then
		arg_26_0:nodeByName("red_p"):setVisible(false)
	else
		arg_26_0:nodeByName("red_p"):setVisible(arg_26_1)
	end
end

function var_0_0.playChatWinMove(arg_27_0, arg_27_1)
	local var_27_0 = arg_27_0:nodeByName("chat_container")
	local var_27_1 = var_27_0:getContentSize()
	local var_27_2 = cc.p(arg_27_0:nodeByName("img_chat"):getPosition())

	if arg_27_1 then
		var_27_0:setPosition(cc.p(-var_27_1.width, 0))
		var_27_0:setVisible(true)
		transition.moveTo(var_27_0, {
			time = 0.3,
			x = 0,
			y = 0
		})
		transition.moveTo(arg_27_0:nodeByName("img_chat"), {
			time = 0.3,
			x = var_27_2.x + var_27_1.width,
			y = var_27_2.y
		})
	else
		transition.moveTo(var_27_0, {
			time = 0.3,
			y = 0,
			x = -var_27_1.width
		})
		transition.moveTo(arg_27_0:nodeByName("img_chat"), {
			time = 0.3,
			x = var_27_2.x - var_27_1.width,
			y = var_27_2.y
		})
	end
end

function var_0_0.addClickEvent(arg_28_0, arg_28_1)
	arg_28_1:setTouchEnabled(true)
	arg_28_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_29_0)
		if arg_29_0.name == "began" then
			arg_28_0:showHeroDetail(arg_28_1, true)

			arg_28_0.preX_ = arg_29_0.x
			arg_28_0.preY_ = arg_29_0.y
			arg_28_0.isScrollMove = false

			return true
		elseif arg_29_0.name == "moved" then
			if math.abs(arg_28_0.preX_ - arg_29_0.x) >= 20 or math.abs(arg_28_0.preY_ - arg_29_0.y) >= 20 then
				arg_28_0.isScrollMove = true

				arg_28_0:showHeroDetail(arg_28_1, false)
			end

			return true
		elseif arg_29_0.name == "ended" and not arg_28_0.isScrollMove then
			arg_28_0:showHeroDetail(arg_28_1, false)
		end
	end)
end

function var_0_0.showHeroDetail(arg_30_0, arg_30_1, arg_30_2)
	if not arg_30_2 and arg_30_0.heroDetailWnd and not tolua.isnull(arg_30_0.heroDetailWnd) then
		arg_30_0.heroDetailWnd:setVisible(false)

		return
	end

	if not arg_30_1.data then
		return
	end

	if not arg_30_0.heroDetailWnd or tolua.isnull(arg_30_0.heroDetailWnd) then
		local var_30_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/illusion/cooperation_new/hero_detail.csb")

		var_30_0:addTo(arg_30_0:nodeByName("hero_list"))

		arg_30_0.heroDetailWnd = var_30_0
	end

	local var_30_1 = cc.p(arg_30_1:getPosition())

	arg_30_0.heroDetailWnd:setPosition(cc.p(var_30_1.x - var_0_5 / 2, var_0_5 + 100))

	local var_30_2 = arg_30_0.heroDetailWnd:getChildByName("container")
	local var_30_3 = arg_30_1.data
	local var_30_4 = arg_30_1.playerInfo

	var_30_2:getChildByName("hero"):removeAllChildren()
	xyd.setAvatarBorderNewUI(var_30_3, var_30_2:getChildByName("hero"))
	var_30_2:getChildByName("text_name"):setString(var_30_3:getName())

	local var_30_5

	if var_30_3.force_ and var_30_3.force_ > 0 then
		var_30_5 = var_30_3.force_
	else
		var_30_5 = var_30_3:getZhandouli()
	end

	var_30_2:getChildByName("text_zhandouli"):setString(var_0_3:translation("HERO_INFO_ZHANDOULI") .. var_30_5)
	var_30_2:getChildByName("text_player_name"):setString(var_0_3:translation("ILLUSION_TEAM_TIPS_15") .. var_30_4.player_name)
	var_30_2:getChildByName("text_hero_tips"):setString(var_30_3:getDes())
	arg_30_0.heroDetailWnd:setVisible(true)
end

function var_0_0.lockReport(arg_31_0, arg_31_1)
	arg_31_0.isLockReport_ = arg_31_1

	if not arg_31_0.isLockReport_ and arg_31_0.needPlayReport and arg_31_0.recordData_ then
		arg_31_0:playReport(arg_31_0.recordData_)
	end
end

function var_0_0.playReport(arg_32_0, arg_32_1)
	if arg_32_1 == nil then
		return
	end

	if not arg_32_0 or tolua.isnull(arg_32_0) then
		return
	end

	if arg_32_0.isLockReport_ then
		arg_32_0.needPlayReport = true
		arg_32_0.recordData_ = arg_32_1

		return
	end

	local var_32_0 = {}
	local var_32_1 = json.decode(arg_32_1[1].content)

	var_32_0.herosA = {}
	var_32_0.herosB = {}
	var_32_0.summonMonsters = {}
	var_32_0.campaignType = xyd.CampaignType.ILLUSION_COOPERATION
	var_32_0.battleID = xyd.tables.illusionCampaign:fightId(arg_32_0.illusion.id)
	var_32_0.battleType = xyd.BattleType.ReplayReport
	ngx.ctx.battle.reportData = var_32_1

	local var_32_2 = {}
	local var_32_3 = {}
	local var_32_4
	local var_32_5

	for iter_32_0, iter_32_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_32_6 = string.sub(iter_32_0, 1, 1)
		local var_32_7 = tonumber(string.sub(iter_32_0, 3, 3))

		if var_32_6 == "A" and tonumber(iter_32_1.summon_type) == xyd.summonMonsterType.None then
			local var_32_8 = var_0_2.new()

			var_32_8:populate(iter_32_1.hero)
			var_32_8:setReportData(iter_32_1)

			if var_32_5 then
				var_32_8.harms = iter_32_1.harms
				var_32_8.willDie = (iter_32_1.die_count or 0) ~= -1
			end

			var_32_0.herosA[var_32_7] = var_32_8
		elseif var_32_6 == "A" and tonumber(iter_32_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_32_9 = var_0_1.new()

			var_32_9:populate(iter_32_1.hero)
			var_32_9:setReportData(iter_32_1)

			if var_32_5 then
				var_32_9.harms = iter_32_1.harms
				var_32_9.willDie = (iter_32_1.die_count or 0) ~= -1
				var_32_0.petA = {
					var_32_9
				}
			else
				var_32_0.petsA = {
					var_32_9
				}
			end
		elseif var_32_6 == "B" and tonumber(iter_32_1.summon_type) == xyd.summonMonsterType.None then
			local var_32_10 = var_0_2.new()

			var_32_10:populate(iter_32_1.hero)
			var_32_10:setReportData(iter_32_1)

			if var_32_5 then
				var_32_10.harms = iter_32_1.harms
				var_32_10.willDie = (iter_32_1.die_count or 0) ~= -1
				var_32_0.herosB[var_32_7] = var_32_10
			else
				var_32_2[var_32_7] = var_32_10
			end
		elseif var_32_6 == "B" and tonumber(iter_32_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_32_11 = var_0_1.new()

			var_32_11:populate(iter_32_1.hero)
			var_32_11:setReportData(iter_32_1)

			if var_32_5 then
				var_32_11.harms = iter_32_1.harms
				var_32_11.willDie = (iter_32_1.die_count or 0) ~= -1
				var_32_0.petB = {
					var_32_11
				}
			else
				var_32_0.petsB = {
					var_32_11
				}
			end
		elseif var_32_6 == "C" then
			local var_32_12 = var_0_2.new()

			var_32_12:populate(iter_32_1.hero)
			var_32_12:setReportData(iter_32_1)

			if not var_32_5 then
				var_32_4 = var_32_12
			end
		elseif tonumber(iter_32_1.summon_type) ~= xyd.summonMonsterType.None and tonumber(iter_32_1.summon_type) ~= xyd.summonMonsterType.Pet then
			local var_32_13 = var_0_2.new()

			var_32_13:populate(iter_32_1.hero)
			var_32_13:setReportData(iter_32_1)

			var_32_3[iter_32_0] = var_32_13
		end
	end

	var_32_0.herosB = {
		var_32_2
	}
	var_32_0.sceneFighter = var_32_4
	var_32_0.summonMonsters = var_32_3
	var_32_0.reportStar = tonumber(var_32_1.star)

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "illusion"
		}
	})
	xyd.WindowManager.get():retainHistory()
	xyd.pushBattleScene(var_32_0)
end

return var_0_0
