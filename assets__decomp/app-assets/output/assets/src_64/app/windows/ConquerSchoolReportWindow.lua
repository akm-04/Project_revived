local var_0_0 = class("ConquerSchoolReportWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.conquerSchoolCampaign
local var_0_3 = import("app.model.Hero")
local var_0_4 = import("app.model.Pet")
local var_0_5 = 52

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.conquerSchool = xyd.ModelManager.get():loadModel(xyd.ModelType.CONQUER_SCHOOL)
	arg_1_0.reports = arg_1_2.reports or {}
	arg_1_0.campaignID = arg_1_2.campaign_id
	arg_1_0.teamID = arg_1_2.team_id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:initListview()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0.list:reload()
end

function var_0_0.initListview(arg_4_0)
	local var_4_0 = arg_4_0:nodeByName("list")
	local var_4_1 = var_4_0:getContentSize().width
	local var_4_2 = var_4_0:getContentSize().height

	arg_4_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_1, var_4_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_4_0)

	arg_4_0.list:setDelegate(handler(arg_4_0, arg_4_0.delegate))
end

function var_0_0.layout(arg_5_0)
	if #arg_5_0.reports == 0 then
		local var_5_0 = var_0_1:translation("CONQUER_SCHOOL_TIPS_1")
		local var_5_1 = arg_5_0:nodeByName("list"):getContentSize()
		local var_5_2 = {
			size = 30,
			text = var_5_0,
			align = cc.ui.TEXT_ALIGN_CENTER,
			color = cc.c3b(255, 255, 255),
			dimensions = cc.size(var_5_1.width, 0)
		}
		local var_5_3 = xyd.AssetLoader.get():loadLabel(var_5_2)

		var_5_3:addTo(arg_5_0:nodeByName("list"))
		var_5_3:setAnchorPoint(cc.p(0, 1))
		var_5_3:setPosition(cc.p(0, var_5_1.height / 2))
	end

	arg_5_0:nodeByName("text_title"):setString(var_0_1:translation("CONQUER_SCHOOL_TEXT_5"))
end

function var_0_0.delegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = #arg_6_0.reports

	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return var_6_0
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_1
		local var_6_2
		local var_6_3
		local var_6_4 = arg_6_0.list:dequeueItem()

		if not var_6_4 then
			var_6_4 = arg_6_0.list:newItem()
		else
			var_6_4:removeAllChildren()
		end

		local var_6_5 = display.newNode()

		var_6_5:setTouchSwallowEnabled(false)

		local var_6_6 = display.newNode()

		arg_6_0:initReportItem(var_6_6, arg_6_3)

		local var_6_7 = var_6_6:getContentSize().width
		local var_6_8 = var_6_6:getContentSize().height

		var_6_5:addChild(var_6_6)
		var_6_5:setContentSize(cc.size(arg_6_0.list.viewRect_.width, var_6_6:getContentSize().height + 5))
		var_6_4:setItemSize(arg_6_0.list.viewRect_.width, var_6_6:getContentSize().height + 5)
		var_6_4:addContent(var_6_5)

		return var_6_4
	end
end

function var_0_0.initReportItem(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_0.reports[arg_7_2]
	local var_7_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/conquer_school/report_item.csb")

	var_7_1:addTo(arg_7_1)

	local var_7_2 = var_7_1:getChildByName("container")
	local var_7_3 = var_7_2:getContentSize()

	arg_7_1:setContentSize(var_7_3)
	var_7_2:getChildByName("text_name"):setString(var_7_0.player_name)

	if var_7_0.conquer_lev and var_7_0.conquer_lev > 0 then
		xyd.setConquerLev(var_7_0.conquer_lev, var_7_2:getChildByName("text_lev"), var_7_2:getChildByName("level_bg"), nil, nil, nil, nil, var_7_0.conquer_loop_id)
	else
		var_7_2:getChildByName("text_lev"):setString(var_7_0.lev)
	end

	var_7_2:getChildByName("text_region"):setString("S" .. var_7_0.region)
	var_7_2:getChildByName("text_region"):enableOutline(cc.c4b(153, 84, 53, 255), 2)
	arg_7_0:initPlayerAvatar(var_7_2, var_7_0.avatar_id, var_7_0.avatar_frame_id)
	var_7_2:getChildByName("btn_record"):addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_8_0, arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			arg_7_0:getReport(var_7_0.report_key, true)
		end
	end)
	var_7_2:getChildByName("btn_replay"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_9_0, arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			arg_7_0:getReport(var_7_0.report_key, false)
		end
	end)
	var_7_2:getChildByName("btn_copy"):getChildByName("text_copy"):setString(xyd.tables.translation:translation("COPY_TEAM"))
	var_7_2:getChildByName("btn_copy"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_10_0, arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			local var_10_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
			local var_10_1 = xyd.tables.vip:presetNum(var_10_0.vip)

			if var_10_1 <= 0 then
				var_10_1 = 10
			end

			if var_10_1 <= #var_10_0:getSaveTeams() then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("PRESET_MEMBER_IS_MAX_NUM")
				})

				return
			end

			local var_10_2 = {}

			for iter_10_0, iter_10_1 in ipairs(var_7_0.heroes) do
				local var_10_3 = var_0_3.new()

				var_10_3:populate(iter_10_1)
				table.insert(var_10_2, var_10_3:getFirstTableID())
			end

			local var_10_4 = {}

			for iter_10_2, iter_10_3 in ipairs(var_10_2) do
				local var_10_5 = var_10_0:getHeroIgnoreAwaken(iter_10_3)

				if var_10_5 then
					table.insert(var_10_4, var_10_5)
				end
			end

			local var_10_6

			if var_7_0.pet and next(var_7_0.pet) then
				local var_10_7 = var_0_4.new()

				var_10_7:populate(var_7_0.pet)

				var_10_6 = var_10_0:getPetIgnoreAwaken(var_10_7:getFirstTableID())
			end

			local var_10_8 = {
				type = xyd.SelectTeamType.HERO_PRESET,
				presetHeroType = xyd.PresetHeroType.NEW_TEAM,
				presetHeroIndex = #var_10_0:getSaveTeams(),
				selected = var_10_2,
				preHeros = var_10_4,
				prePet = {
					var_10_6
				}
			}

			xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_10_8)
		end
	end)

	local var_7_4 = 0

	for iter_7_0, iter_7_1 in pairs(var_7_0.heroes) do
		local var_7_5 = var_0_3.new()

		var_7_5:populate(iter_7_1)

		local var_7_6 = display.newNode()

		var_7_6:setContentSize(var_0_5, var_0_5)
		var_7_6:setPosition(cc.p(var_7_4, 0))
		xyd.setAvatarBorderNewUI(var_7_5, var_7_6, var_7_5:getColor(), var_7_5:getStar(), var_7_5:isAwakeTwice())
		var_7_6:addTo(var_7_2:getChildByName("hero_list"))

		local var_7_7 = {}
		local var_7_8 = cc.Node:create()

		var_7_8:setAnchorPoint(cc.p(0, 0))
		var_7_8:setContentSize(50, 50)
		var_7_6:addChild(var_7_8)

		var_7_7.id = var_7_0.heroes[iter_7_0].table_id
		var_7_7.desc = xyd.tables.hero:getDes(var_7_0.heroes[iter_7_0].table_id)
		var_7_7.name = xyd.tables.hero:name(var_7_0.heroes[iter_7_0].table_id)
		var_7_7.hero = var_7_5
		var_7_7.lev = var_7_5.level
		var_7_7.hero = var_7_5
		var_7_7.lev = var_7_5.level_
		var_7_7.isHero = true

		var_7_8:setTouchEnabled(true)
		var_7_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
			if arg_11_0.name == "began" then
				local var_11_0 = xyd.WindowManager.get():getWindow("new_item_tips")
				local var_11_1 = arg_7_0:convertToWorldSpace(cc.p(0, 0))

				if not var_11_0 then
					local var_11_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_7_7)

					xyd.adaptToWorldPosition(var_7_8, var_11_2)
				end

				return true
			elseif arg_11_0.name == "ended" and xyd.WindowManager.get():getWindow("new_item_tips") then
				local var_11_3 = xyd.WindowManager.get():closeWindow("new_item_tips")
			end
		end)

		var_7_4 = var_7_4 + var_0_5 + 9
	end

	if var_7_0.pet and next(var_7_0.pet) then
		local var_7_9 = var_0_4.new()

		var_7_9:populate(var_7_0.pet)

		local var_7_10 = display.newNode()

		var_7_10:setContentSize(var_0_5 + 20, var_0_5 + 20)

		local var_7_11 = var_7_4 + 15

		var_7_10:setPosition(cc.p(var_7_11, 10))
		xyd.setPetAvatar(var_7_10, var_7_9, nil, true)
		var_7_10:setScale(0.6)
		var_7_10:addTo(var_7_2:getChildByName("hero_list"))

		local var_7_12 = {}
		local var_7_13 = cc.Node:create()

		var_7_13:setAnchorPoint(cc.p(0, 0))
		var_7_13:setContentSize(70, 70)
		var_7_10:addChild(var_7_13)

		var_7_12.id = var_7_0.pet.table_id
		var_7_12.desc = xyd.tables.hero:getDes(var_7_0.pet.table_id)
		var_7_12.name = xyd.tables.hero:name(var_7_0.pet.table_id)
		var_7_12.lev = var_7_9.level_
		var_7_12.hero = var_7_9
		var_7_12.lev = var_7_9.level_
		var_7_12.hero = var_7_9
		var_7_12.isHero = true

		var_7_13:setTouchEnabled(true)
		var_7_13:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
			if arg_12_0.name == "began" then
				local var_12_0 = xyd.WindowManager.get():getWindow("new_item_tips")
				local var_12_1 = arg_7_0:convertToWorldSpace(cc.p(0, 0))

				if not var_12_0 then
					local var_12_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_7_12)

					xyd.adaptToWorldPosition(var_7_13, var_12_2)
				end

				return true
			elseif arg_12_0.name == "ended" and xyd.WindowManager.get():getWindow("new_item_tips") then
				local var_12_3 = xyd.WindowManager.get():closeWindow("new_item_tips")
			end
		end)
	end
end

function var_0_0.initPlayerAvatar(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	xyd.setAvatarClip(arg_13_1:getChildByName("avatar"), arg_13_2, 1)

	local var_13_0 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarFrameId] .. ".png"

	if arg_13_3 and arg_13_3 ~= 0 then
		var_13_0 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[arg_13_3] .. ".png"
	end

	local var_13_1 = xyd.AssetLoader.get():loadSprite(var_13_0)
	local var_13_2 = var_13_1:getContentSize()

	var_13_1:setAnchorPoint(cc.p(0.5, 0.5))

	local var_13_3 = arg_13_1:getChildByName("avatar_frame"):getContentSize()

	var_13_1:setPosition(var_13_3.width / 2, var_13_3.height / 2)
	var_13_1:setScale(0.58)
	arg_13_1:getChildByName("avatar_frame"):addChild(var_13_1)
end

function var_0_0.getReport(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = {
		report_key = arg_14_1
	}

	arg_14_0.conquerSchool:getReport(var_14_0, function(arg_15_0, arg_15_1)
		if arg_15_0 == xyd.error.OK then
			arg_14_0:replayRecord(arg_15_1.report, arg_14_2)
		end
	end)
end

function var_0_0.replayRecord(arg_16_0, arg_16_1, arg_16_2)
	if arg_16_1 == nil or next(arg_16_1) == nil then
		return
	end

	local var_16_0 = {}
	local var_16_1 = json.decode(arg_16_1.report)

	var_16_0.herosA = {}
	var_16_0.herosB = {}
	var_16_0.summonMonsters = {}
	var_16_0.campaignType = xyd.CampaignType.CONQUER_SCHOOL
	var_16_0.campaignID = arg_16_0.campaignID
	var_16_0.battleID = var_0_2:fightIDs(arg_16_0.campaignID)[arg_16_0.teamID]
	var_16_0.battleType = xyd.BattleType.ReplayReport
	ngx.ctx.battle.reportData = var_16_1

	local var_16_2 = {}
	local var_16_3 = {}

	for iter_16_0, iter_16_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_16_4 = string.sub(iter_16_0, 1, 1)
		local var_16_5 = tonumber(string.sub(iter_16_0, 3, 3))

		if var_16_4 == "A" and tonumber(iter_16_1.summon_type) == xyd.summonMonsterType.None then
			local var_16_6 = var_0_3.new()

			var_16_6:populate(iter_16_1.hero)
			var_16_6:setReportData(iter_16_1)

			if arg_16_2 then
				var_16_6.harms = iter_16_1.harms
				var_16_6.willDie = (iter_16_1.die_count or 0) ~= -1
			end

			var_16_0.herosA[var_16_5] = var_16_6
		elseif var_16_4 == "A" and tonumber(iter_16_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_16_7 = var_0_4.new()

			var_16_7:populate(iter_16_1.hero)
			var_16_7:setReportData(iter_16_1)

			if arg_16_2 then
				var_16_7.harms = iter_16_1.harms
				var_16_7.willDie = (iter_16_1.die_count or 0) ~= -1
				var_16_0.petA = {
					var_16_7
				}
			else
				var_16_0.petsA = {
					var_16_7
				}
			end
		elseif var_16_4 == "B" and tonumber(iter_16_1.summon_type) == xyd.summonMonsterType.None then
			local var_16_8 = var_0_3.new()
			local var_16_9 = arg_16_0.conquerSchool:getLoopID()
			local var_16_10 = xyd.tables.ConquerSchoolLoop:ratio(var_16_9)

			var_16_8:populate(iter_16_1.hero)

			local var_16_11 = var_16_8.getTotalAttr

			function var_16_8.getTotalAttr(arg_17_0, arg_17_1)
				local var_17_0 = var_16_11(arg_17_0, arg_17_1)

				if arg_17_1 == xyd.AttributeType.HP or arg_17_1 == xyd.AttributeType.AD or arg_17_1 == xyd.AttributeType.AP or arg_17_1 == xyd.AttributeType.HUJIA or arg_17_1 == xyd.AttributeType.MOKANG or arg_17_1 == xyd.AttributeType.AD_BAOJI or arg_17_1 == xyd.AttributeType.AP_BAOJI or arg_17_1 == xyd.AttributeType.SHANBI or arg_17_1 == xyd.AttributeType.D_HUJIA or arg_17_1 == xyd.AttributeType.D_MOKANG or arg_17_1 == xyd.AttributeType.MINGZHONG then
					return var_17_0 * var_16_10
				else
					return var_17_0
				end
			end

			var_16_8:setReportData(iter_16_1)

			if arg_16_2 then
				var_16_8.harms = iter_16_1.harms
				var_16_8.willDie = (iter_16_1.die_count or 0) ~= -1
				var_16_0.herosB[var_16_5] = var_16_8
			else
				var_16_2[var_16_5] = var_16_8
			end
		elseif var_16_4 == "B" and tonumber(iter_16_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_16_12 = var_0_4.new()

			var_16_12:populate(iter_16_1.hero)
			var_16_12:setReportData(iter_16_1)

			if arg_16_2 then
				var_16_12.harms = iter_16_1.harms
				var_16_12.willDie = (iter_16_1.die_count or 0) ~= -1
				var_16_0.petB = {
					var_16_12
				}
			else
				var_16_0.petsB = {
					var_16_12
				}
			end
		elseif var_16_4 == "C" then
			local var_16_13 = var_0_3.new()

			var_16_13:populate(iter_16_1.hero)
			var_16_13:setReportData(iter_16_1)

			if not arg_16_2 then
				sceneFighter = var_16_13
			end
		elseif tonumber(iter_16_1.summon_type) ~= xyd.summonMonsterType.None and tonumber(iter_16_1.summon_type) ~= xyd.summonMonsterType.Pet then
			local var_16_14 = var_0_3.new()

			var_16_14:populate(iter_16_1.hero)
			var_16_14:setReportData(iter_16_1)

			var_16_3[iter_16_0] = var_16_14
		end
	end

	if arg_16_2 then
		collectgarbage("collect")

		var_16_0.isBeforeBattle = true

		xyd.WindowManager.get():openWindow(xyd.WindowName.battleResultDataWnd, var_16_0)
	else
		var_16_0.herosB = {
			var_16_2
		}
		var_16_0.sceneFighter = sceneFighter
		var_16_0.summonMonsters = var_16_3
		var_16_0.reportStar = tonumber(var_16_1.star)

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
			params = {
				window = "conquer_school"
			}
		})
		xyd.WindowManager.get():retainHistory()
		xyd.pushBattleScene(var_16_0)
	end
end

return var_0_0
