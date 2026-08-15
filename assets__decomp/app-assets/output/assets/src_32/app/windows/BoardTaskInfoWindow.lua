local var_0_0 = class("BoardTaskInfoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("framework.scheduler")
local var_0_4 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.treasure = xyd.ModelManager.get():loadModel(xyd.ModelType.TREASURE)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)
	arg_1_0.heros = clone(arg_1_0.selfPlayer.heros_)
end

function var_0_0.registerUpgrade(arg_2_0)
	arg_2_0:nodeByName("speed_up_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			local var_3_0 = arg_2_0.eventCentre.boardNeedTime - (xyd.ServerTime.get():getServerTime() - arg_2_0.eventCentre.boardStartTime)
			local var_3_1

			if var_3_0 < 14400 then
				var_3_1 = var_3_0 / 72
			elseif var_3_0 < 43200 then
				var_3_1 = (var_3_0 - 14400) / 144 + 200
			else
				var_3_1 = (var_3_0 - 43200) / 432 + 400
			end

			local var_3_2 = math.ceil(var_3_1)
			local var_3_3 = string.format(var_0_1:translation("COST_TO_UPGRADE"), var_3_2, arg_2_0.lev + 1)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_3_3, function()
				if var_3_2 > arg_2_0.selfPlayer.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_5_0 = {}

						var_5_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_5_0)
					end, nil, nil, arg_2_0.colorMode)
				else
					local var_4_0 = {
						type = xyd.EventCentreBuildingType.BOARD
					}

					arg_2_0.eventCentre:speedUpBuilding(var_4_0, function(arg_6_0, arg_6_1)
						if arg_6_0 == xyd.error.OK then
							arg_2_0.eventCentre.boardStartTime = 0
							arg_2_0.eventCentre.boardNeedTime = 0
							arg_2_0.eventCentre.boardLev = arg_6_1.lev
							arg_2_0.eventCentre.buidingInfo["" .. xyd.EventCentreBuildingType.BOARD].lev = arg_2_0.eventCentre.boardLev

							arg_2_0:updateUpgradeTime()
							xyd.WindowManager.get():getWindow("board_main_window"):updateUpgradeTime()
							arg_2_0:levupSucceed()
						end
					end)
				end
			end, nil, 0, arg_2_0.colorMode)
		end
	end)
	arg_2_0:nodeByName("cancel_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			local var_7_0 = var_0_1:translation("CANCEL_UPGRADE")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_7_0, function()
				local var_8_0 = {
					type = xyd.EventCentreBuildingType.BOARD
				}

				arg_2_0.eventCentre:cancelEvolveBuilding(var_8_0, function(arg_9_0, arg_9_1)
					if arg_9_0 == xyd.error.OK then
						arg_2_0.eventCentre.boardStartTime = arg_9_1.building_info.start_time
						arg_2_0.eventCentre.boardNeedTime = arg_9_1.building_info.need_time
						arg_2_0.eventCentre.boardLev = arg_9_1.building_info.lev
						arg_2_0.eventCentre.buidingInfo["" .. xyd.EventCentreBuildingType.BOARD].lev = arg_2_0.eventCentre.boardLev

						xyd.EventDispatcher.get():dispatchEvent({
							name = xyd.event.REFRESH_MAGIC_RES
						})
						arg_2_0:updateUpgradeTime()
						xyd.WindowManager.get():getWindow("board_main_window"):updateUpgradeTime()

						local var_9_0 = {
							resolve_types = arg_9_1.return_res_id,
							resolve_nums = arg_9_1.return_res_num,
							resolve_crits = {}
						}

						xyd.WindowManager.get():openWindow("recycle_award", var_9_0)
					end
				end)
			end, nil, nil, arg_2_0.colorMode)
		end
	end)
end

function var_0_0.updateUpgradeTime(arg_10_0)
	if arg_10_0.handle1 then
		var_0_3.unscheduleGlobal(arg_10_0.handle1)

		arg_10_0.handle1 = nil
	end

	local var_10_0

	if arg_10_0.eventCentre.boardStartTime > 0 then
		var_10_0 = arg_10_0.eventCentre.boardNeedTime - (xyd.ServerTime.get():getServerTime() - arg_10_0.eventCentre.boardStartTime)

		arg_10_0:nodeByName("upgrade_time_bg"):setVisible(true)
		arg_10_0:nodeByName("upgrade_time_txt"):setString(xyd.secondsToString1(var_10_0))
	else
		var_10_0 = 0

		arg_10_0:nodeByName("upgrade_time_bg"):setVisible(false)
	end

	if var_10_0 > 0 then
		arg_10_0:nodeByName("upgrade_time_bg"):setVisible(true)

		arg_10_0.handle1 = var_0_3.scheduleGlobal(function()
			var_10_0 = var_10_0 - 1

			if not tolua.isnull(arg_10_0) then
				arg_10_0:nodeByName("upgrade_time_bg"):setVisible(true)
				arg_10_0:nodeByName("upgrade_time_txt"):setString(xyd.secondsToString1(var_10_0))
			end

			if var_10_0 <= 0 and arg_10_0.handle1 then
				arg_10_0.eventCentre.boardLev = arg_10_0.eventCentre.boardLev + 1
				arg_10_0.eventCentre.buidingInfo["" .. xyd.EventCentreBuildingType.BOARD].lev = arg_10_0.eventCentre.boardLev
				arg_10_0.eventCentre.boardNeedTime = 0
				arg_10_0.eventCentre.boardStartTime = 0

				var_0_3.unscheduleGlobal(arg_10_0.handle1)

				arg_10_0.handle1 = nil

				if not tolua.isnull(arg_10_0) then
					arg_10_0:nodeByName("upgrade_time_bg"):setVisible(false)
				end
			end
		end, 1)
	else
		arg_10_0:nodeByName("upgrade_time_bg"):setVisible(false)

		if arg_10_0.handle1 then
			var_0_3.unscheduleGlobal(arg_10_0.handle1)

			arg_10_0.handle1 = nil
		end
	end

	if arg_10_0.eventCentre.boardLev ~= arg_10_0.lev then
		arg_10_0.lev = arg_10_0.eventCentre.boardLev

		arg_10_0:updateBoardLev()
	end
end

function var_0_0.levupSucceed(arg_12_0)
	local var_12_0 = {
		type = xyd.EventCentreBuildingType.BOARD
	}

	arg_12_0.eventCentre:confirmBuildingUpgrade(var_12_0, function(arg_13_0, arg_13_1)
		if arg_13_0 == xyd.error.OK then
			local var_13_0 = {
				type = xyd.EventCentreBuildingType.BOARD,
				lev = arg_12_0.eventCentre.boardLev
			}

			xyd.WindowManager.get():openWindow("building_levelup", var_13_0)

			arg_12_0.eventCentre.boardNewEvolve = 0
		end
	end)
end

function var_0_0.willOpen(arg_14_0, arg_14_1)
	var_0_0.super:willOpen(arg_14_1)
	arg_14_0.selfPlayer:loadUsedPartners(function(arg_15_0)
		arg_14_0.busyheros = clone(arg_15_0)

		arg_14_0:filtCanUseHeros()
		arg_14_0:sortHeros(arg_14_0.heros)
		arg_14_0:initHeroList()
		arg_14_0.herolist:setDelegate(handler(arg_14_0, arg_14_0.heroListDelegate))
		arg_14_0.herolist:reload()
	end)

	arg_14_0.hasLeader = false
	arg_14_0.useCrystal = false
	arg_14_0.isChoosingLeader = false
	arg_14_0.isChoosingMember = false
	arg_14_0.cells = {}
	arg_14_0.leader = 0
	arg_14_0.mission = arg_14_1
	arg_14_0.zhandouli = 0
	arg_14_0.enemyRate = 0
	arg_14_0.targetzhandouli = xyd.tables.eventCentreMissionTable:fighting(arg_14_0.mission.mission_id)
	arg_14_0.targetLeader = xyd.tables.eventCentreMissionTable:heroId(arg_14_0.mission.mission_id)
	arg_14_0.hasTargetLeader = false
	arg_14_0.canUseTargetLeader = true
	arg_14_0.leastzhandouli = 0
	arg_14_0.members = {
		0,
		0,
		0,
		0,
		0
	}

	arg_14_0:nodeByName("task_bonus_title"):setString(xyd.tables.translation:translation("EVENT_CENTRE_BOARD_TASK_BONUS_LABEL"))
	arg_14_0:nodeByName("task_time_title"):setString(xyd.tables.translation:translation("EVENT_CENTRE_BOARD_TASK_TIME_LABEL"))
	arg_14_0:nodeByName("enemy_rate_title"):setString(xyd.tables.translation:translation("EVENT_CENTRE_BOARD_ENEMY_RATE_TITLE"))
	arg_14_0:nodeByName("power_title"):setString(xyd.tables.translation:translation("EVENT_CENTRE_BOARD_POWER_TITLE"))
	arg_14_0:nodeByName("use_label"):setString(xyd.tables.translation:translation("EVENT_CENTRE_BOARD_USE_LABEL"))
	arg_14_0:nodeByName("others_title"):setString(xyd.tables.translation:translation("EVENT_CENTRE_BOARD_MEMBERS_TITLE"))
	arg_14_0:nodeByName("hours"):setString(xyd.tables.translation:translation("EVENT_CENTRE_BOARD_HOURS"))
	arg_14_0:updateUpgradeTime()
	arg_14_0:registerUpgrade()
	arg_14_0:updateBoardLev()

	if arg_14_0.eventCentre.boardNewEvolve and arg_14_0.eventCentre.boardNewEvolve == 1 then
		arg_14_0:levupSucceed()
	end
end

function var_0_0.refreshEnemyRate(arg_16_0)
	local var_16_0 = 100

	if arg_16_0.leader ~= 0 then
		if arg_16_0.heros[arg_16_0.leader]:getTableID() == arg_16_0.targetLeader or arg_16_0.targetLeader == xyd.tables.hero:beforeAwaken(arg_16_0.heros[arg_16_0.leader]:getTableID()) then
			var_16_0 = 50

			if arg_16_0.heros[arg_16_0.leader]:getZhandouli() > arg_16_0.targetzhandouli then
				var_16_0 = var_16_0 - 31
				var_16_0 = var_16_0 - math.floor((arg_16_0.heros[arg_16_0.leader]:getZhandouli() - arg_16_0.targetzhandouli) / 180)
			else
				var_16_0 = var_16_0 - 31
				var_16_0 = var_16_0 + math.floor((arg_16_0.targetzhandouli - arg_16_0.heros[arg_16_0.leader]:getZhandouli()) / 90)
			end

			if var_16_0 < 20 then
				var_16_0 = 20
			elseif var_16_0 > 50 then
				var_16_0 = 50
			end
		else
			var_16_0 = 100

			if arg_16_0.heros[arg_16_0.leader]:getZhandouli() > arg_16_0.targetzhandouli then
				var_16_0 = var_16_0 - 31
				var_16_0 = var_16_0 - math.floor((arg_16_0.heros[arg_16_0.leader]:getZhandouli() - arg_16_0.targetzhandouli) / 180)
			else
				var_16_0 = var_16_0 - 31
				var_16_0 = var_16_0 + math.floor((arg_16_0.targetzhandouli - arg_16_0.heros[arg_16_0.leader]:getZhandouli()) / 90)
			end

			if var_16_0 < 60 then
				var_16_0 = 60
			elseif var_16_0 > 100 then
				var_16_0 = 100
			end
		end
	end

	for iter_16_0 = 1, 5 do
		if arg_16_0.members[iter_16_0] == 0 then
			arg_16_0:nodeByName("others_title"):setString(string.format(var_0_1:translation("EVENT_CENTRE_BOARD_MEMBERS_TITLE"), iter_16_0 - 1))

			break
		else
			arg_16_0:nodeByName("others_title"):setString(string.format(var_0_1:translation("EVENT_CENTRE_BOARD_MEMBERS_TITLE"), 5))
		end

		local var_16_1 = arg_16_0.heros[arg_16_0.members[iter_16_0]]

		if var_16_1:getZhandouli() > arg_16_0.targetzhandouli then
			var_16_0 = var_16_0 - math.floor((var_16_1:getZhandouli() - arg_16_0.targetzhandouli) / 60000) * 100 - 4
		else
			var_16_0 = var_16_0 - math.max(4 - math.ceil((arg_16_0.targetzhandouli - var_16_1:getZhandouli()) / 2000), 0)
		end
	end

	arg_16_0:nodeByName("enemy_rate"):setString(var_16_0 .. "%")
	arg_16_0:nodeByName("enemy_rate"):setTextColor(cc.c4b(math.floor(var_16_0 / 10) * 25, 255 - math.floor(var_16_0 / 10) * 25, 0, 255))
end

function var_0_0.filtCanUseHeros(arg_17_0)
	for iter_17_0, iter_17_1 in ipairs(arg_17_0.heros) do
		if iter_17_1:getTableID() == arg_17_0.targetLeader or arg_17_0.targetLeader == xyd.tables.hero:beforeAwaken(iter_17_1:getTableID()) then
			arg_17_0.hasTargetLeader = true
			arg_17_0.canUseTargetLeader = true
		end
	end

	for iter_17_2 = 1, #arg_17_0.busyheros do
		for iter_17_3, iter_17_4 in ipairs(arg_17_0.heros) do
			if iter_17_4:getHeroID() == arg_17_0.busyheros[iter_17_2] then
				if arg_17_0.targetLeader ~= iter_17_4:getTableID() and arg_17_0.targetLeader ~= xyd.tables.hero:beforeAwaken(iter_17_4:getTableID()) then
					table.remove(arg_17_0.heros, iter_17_3)

					break
				end

				arg_17_0.canUseTargetLeader = false

				table.remove(arg_17_0.heros, iter_17_3)

				break
			end
		end
	end
end

function var_0_0.didOpen(arg_18_0, arg_18_1)
	var_0_0.super:didOpen(arg_18_1)

	arg_18_0.container = arg_18_0:nodeByName("main_container")
	arg_18_0.triangles = {}
	arg_18_0.chooseContainer = arg_18_0:nodeByName("hero_select_cont")
	arg_18_0.topContainer = arg_18_0:nodeByName("top_container")

	arg_18_0:nodeByName("tick"):setVisible(false)
	arg_18_0:nodeByName("double_icon"):setVisible(false)
	arg_18_0:nodeByName("hero_select_close"):setVisible(true)
	arg_18_0:layout()
	arg_18_0:refreshEnemyRate()
end

function var_0_0.layout(arg_19_0)
	arg_19_0:updateMagicStoneInfos()
	arg_19_0:registerListeners()
	arg_19_0:setMissionAward(false)
end

function var_0_0.updateMagicStoneInfos(arg_20_0)
	arg_20_0.magicStoneNum = arg_20_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.blessing_crystal)

	arg_20_0:nodeByName("use_label"):setString(var_0_1:translation("BACKPACK_USE"))
	arg_20_0:nodeByName("magic_stone_num"):setString(string.format(var_0_1:translation("BOARD_MAGIC_STONE_NUM"), arg_20_0.magicStoneNum, 1))

	if arg_20_0.magicStoneNum <= 0 then
		arg_20_0:nodeByName("magic_stone_num"):setTextColor(cc.c4b(252, 0, 0, 255))
	else
		arg_20_0:nodeByName("magic_stone_num"):setTextColor(cc.c4b(255, 255, 255, 255))
	end
end

function var_0_0.registerListeners(arg_21_0)
	arg_21_0:registerLeader()
	arg_21_0:registerTeamMember()
	arg_21_0:registerEnemyButton()
	arg_21_0:registerCheckbox()
	arg_21_0:registerSendButton()
	arg_21_0:registerHeroSelectCloseButton()
	arg_21_0:registerBottomLeft()
	arg_21_0:registerBottomRight()
	arg_21_0:registerMagicStoneIcon()
	arg_21_0:nodeByName("task_name"):setString(xyd.tables.eventCentreMissionTable:name(arg_21_0.mission.mission_id))
	arg_21_0:nodeByName("task_info"):setString(xyd.tables.eventCentreMissionTable:desc(arg_21_0.mission.mission_id))
	arg_21_0:nodeByName("task_time"):setString(xyd.tables.eventCentreMissionTable:time(arg_21_0.mission.mission_id) / 3600)
	arg_21_0:nodeByName("power"):setString(arg_21_0.zhandouli .. "/" .. arg_21_0.targetzhandouli)
	arg_21_0:nodeByName("enemy_rate"):setString(arg_21_0.enemyRate .. "%")
end

function var_0_0.registerMagicStoneIcon(arg_22_0, ...)
	arg_22_0:nodeByName("magic_stone"):setTouchEnabled(true)
	arg_22_0:nodeByName("magic_stone"):setTouchSwallowEnabled(false)
	arg_22_0:nodeByName("magic_stone"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_23_0)
		if arg_23_0.name == "ended" then
			arg_22_0:composeMagicStone()
		end

		return true
	end)
end

function var_0_0.registerBottomLeft(arg_24_0)
	arg_24_0:nodeByName("bottom_left_cont"):setTouchEnabled(true)
	arg_24_0:nodeByName("bottom_left_cont"):setTouchSwallowEnabled(false)
	arg_24_0:nodeByName("bottom_left_cont"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_25_0)
		if arg_25_0.name == "ended" then
			if arg_24_0.topContainer:isVisible() then
				arg_24_0.topContainer:setVisible(false)
				arg_24_0.chooseContainer:setVisible(true)

				arg_24_0.isChoosingLeader = true
				arg_24_0.isChoosingMember = false

				arg_24_0:nodeByName("bottom_left_cont"):setVisible(false)
				arg_24_0:nodeByName("bottom_right_cont_hl"):setVisible(false)
				arg_24_0:nodeByName("bottom_left_cont_hl"):setVisible(true)
				arg_24_0:nodeByName("bottom_right_cont"):setVisible(true)
			elseif not arg_24_0.isChoosingLeader then
				arg_24_0.isChoosingLeader = true
				arg_24_0.isChoosingMember = false

				arg_24_0:nodeByName("bottom_left_cont"):setVisible(false)
				arg_24_0:nodeByName("bottom_right_cont_hl"):setVisible(false)
				arg_24_0:nodeByName("bottom_left_cont_hl"):setVisible(true)
				arg_24_0:nodeByName("bottom_right_cont"):setVisible(true)
			end
		end

		return true
	end)
end

function var_0_0.registerBottomRight(arg_26_0)
	arg_26_0:nodeByName("bottom_right_cont"):setTouchEnabled(true)
	arg_26_0:nodeByName("bottom_right_cont"):setTouchSwallowEnabled(false)
	arg_26_0:nodeByName("bottom_right_cont"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_27_0)
		if arg_27_0.name == "ended" then
			if arg_26_0.topContainer:isVisible() then
				arg_26_0.topContainer:setVisible(false)
				arg_26_0.chooseContainer:setVisible(true)

				arg_26_0.isChoosingLeader = false
				arg_26_0.isChoosingMember = true

				arg_26_0:nodeByName("bottom_left_cont"):setVisible(true)
				arg_26_0:nodeByName("bottom_right_cont_hl"):setVisible(true)
				arg_26_0:nodeByName("bottom_left_cont_hl"):setVisible(false)
				arg_26_0:nodeByName("bottom_right_cont"):setVisible(false)
			elseif not arg_26_0.isChoosingMember then
				arg_26_0.isChoosingLeader = false
				arg_26_0.isChoosingMember = true

				arg_26_0:nodeByName("bottom_left_cont"):setVisible(true)
				arg_26_0:nodeByName("bottom_right_cont_hl"):setVisible(true)
				arg_26_0:nodeByName("bottom_left_cont_hl"):setVisible(false)
				arg_26_0:nodeByName("bottom_right_cont"):setVisible(false)
			end
		end

		return true
	end)
end

function var_0_0.registerLeader(arg_28_0)
	arg_28_0:nodeByName("leader"):setTouchEnabled(true)
	arg_28_0:nodeByName("leader"):setTouchSwallowEnabled(false)
	arg_28_0:nodeByName("leader"):addTouchEventListener(function(arg_29_0, arg_29_1)
		if arg_29_1 == ccui.TouchEventType.ended then
			arg_28_0:chooseLeader()
		end

		return true
	end)
	arg_28_0:nodeByName("leader_copy"):setTouchEnabled(true)
	arg_28_0:nodeByName("leader_copy"):setTouchSwallowEnabled(false)
	arg_28_0:nodeByName("leader_copy"):addTouchEventListener(function(arg_30_0, arg_30_1)
		if arg_30_1 == ccui.TouchEventType.ended then
			arg_28_0:chooseLeader()
		end

		return true
	end)
end

function var_0_0.chooseLeader(arg_31_0)
	if arg_31_0.topContainer:isVisible() then
		arg_31_0.topContainer:setVisible(false)
		arg_31_0.chooseContainer:setVisible(true)

		arg_31_0.isChoosingLeader = true
		arg_31_0.isChoosingMember = false

		arg_31_0:nodeByName("bottom_left_cont"):setVisible(false)
		arg_31_0:nodeByName("bottom_right_cont_hl"):setVisible(false)
		arg_31_0:nodeByName("bottom_left_cont_hl"):setVisible(true)
		arg_31_0:nodeByName("bottom_right_cont"):setVisible(true)
	elseif not arg_31_0.isChoosingLeader then
		arg_31_0.isChoosingLeader = true
		arg_31_0.isChoosingMember = false

		arg_31_0:nodeByName("bottom_left_cont"):setVisible(false)
		arg_31_0:nodeByName("bottom_right_cont_hl"):setVisible(false)
		arg_31_0:nodeByName("bottom_left_cont_hl"):setVisible(true)
		arg_31_0:nodeByName("bottom_right_cont"):setVisible(true)
	elseif not arg_31_0.topContainer:isVisible() then
		if arg_31_0.leader ~= 0 then
			if not tolua.isnull(arg_31_0.cells[arg_31_0.leader]) then
				arg_31_0.cells[arg_31_0.leader]:getChildByName("background"):getChildByName("chosen"):setVisible(false)
				arg_31_0.cells[arg_31_0.leader]:getChildByName("background"):getChildByName("avatar_mask"):setVisible(false)
			end

			arg_31_0.zhandouli = arg_31_0.zhandouli - arg_31_0.heros[arg_31_0.leader]:getZhandouli()

			arg_31_0:nodeByName("power"):setString(arg_31_0.zhandouli .. "/" .. arg_31_0.targetzhandouli)
		end

		arg_31_0:nodeByName("leader_copy"):setVisible(false)
		arg_31_0:nodeByName("leader_name"):setVisible(false)
		arg_31_0:nodeByName("bottom_left_cont"):setVisible(false)
		arg_31_0:nodeByName("bottom_right_cont_hl"):setVisible(false)
		arg_31_0:nodeByName("bottom_left_cont_hl"):setVisible(true)
		arg_31_0:nodeByName("bottom_right_cont"):setVisible(true)

		arg_31_0.hasLeader = false
		arg_31_0.leader = 0

		arg_31_0:refreshEnemyRate()
	end
end

function var_0_0.registerTeamMember(arg_32_0)
	for iter_32_0 = 1, 5 do
		arg_32_0:nodeByName("member" .. iter_32_0):addTouchEventListener(function(arg_33_0, arg_33_1)
			if arg_33_1 == ccui.TouchEventType.ended then
				arg_32_0:chooseMember(iter_32_0)
			end
		end)
		arg_32_0:nodeByName("member" .. iter_32_0 .. "_copy"):addTouchEventListener(function(arg_34_0, arg_34_1)
			if arg_34_1 == ccui.TouchEventType.ended then
				arg_32_0:chooseMember(iter_32_0)
			end
		end)
	end
end

function var_0_0.chooseMember(arg_35_0, arg_35_1)
	if arg_35_0.topContainer:isVisible() then
		arg_35_0.topContainer:setVisible(false)
		arg_35_0.chooseContainer:setVisible(true)

		arg_35_0.isChoosingLeader = false
		arg_35_0.isChoosingMember = true

		arg_35_0:nodeByName("bottom_left_cont"):setVisible(true)
		arg_35_0:nodeByName("bottom_right_cont_hl"):setVisible(true)
		arg_35_0:nodeByName("bottom_left_cont_hl"):setVisible(false)
		arg_35_0:nodeByName("bottom_right_cont"):setVisible(false)
	elseif not arg_35_0.isChoosingMember then
		arg_35_0.isChoosingLeader = false
		arg_35_0.isChoosingMember = true

		arg_35_0:nodeByName("bottom_left_cont"):setVisible(true)
		arg_35_0:nodeByName("bottom_right_cont_hl"):setVisible(true)
		arg_35_0:nodeByName("bottom_left_cont_hl"):setVisible(false)
		arg_35_0:nodeByName("bottom_right_cont"):setVisible(false)
	elseif not arg_35_0.topContainer:isVisible() then
		arg_35_0:nodeByName("bottom_left_cont"):setVisible(true)
		arg_35_0:nodeByName("bottom_right_cont_hl"):setVisible(true)
		arg_35_0:nodeByName("bottom_left_cont_hl"):setVisible(false)
		arg_35_0:nodeByName("bottom_right_cont"):setVisible(false)
		arg_35_0:cancelMember(arg_35_0.members[arg_35_1])
		arg_35_0:refreshEnemyRate()
	end
end

function var_0_0.cancelMember(arg_36_0, arg_36_1)
	if arg_36_1 == 0 then
		return
	end

	if not tolua.isnull(arg_36_0.cells[arg_36_1]) then
		arg_36_0.cells[arg_36_1]:getChildByName("background"):getChildByName("chosen"):setVisible(false)
		arg_36_0.cells[arg_36_1]:getChildByName("background"):getChildByName("avatar_mask"):setVisible(false)
	end

	for iter_36_0 = 1, 5 do
		if arg_36_0.members[iter_36_0] == arg_36_1 then
			arg_36_0.members[iter_36_0] = 0
		end
	end

	for iter_36_1 = 1, 5 do
		if arg_36_0.members[iter_36_1] == 0 and iter_36_1 ~= 5 then
			if arg_36_0.members[iter_36_1 + 1] ~= 0 then
				arg_36_0.members[iter_36_1] = arg_36_0.members[iter_36_1 + 1]

				arg_36_0:nodeByName("member" .. iter_36_1 .. "_copy"):removeAllChildren()
				xyd.setAvatarBorderWithLevelAndHp(arg_36_0.heros[arg_36_0.members[iter_36_1]], arg_36_0:nodeByName("member" .. iter_36_1 .. "_copy"))
				arg_36_0:nodeByName("member" .. iter_36_1 .. "_copy"):setVisible(true)
				arg_36_0:nodeByName("member" .. iter_36_1 .. "_name"):setVisible(true)
				arg_36_0:nodeByName("member" .. iter_36_1 .. "_name"):setString(arg_36_0.heros[arg_36_0.members[iter_36_1]]:getName())
				arg_36_0:nodeByName("member" .. iter_36_1 + 1 .. "_copy"):setVisible(false)
				arg_36_0:nodeByName("member" .. iter_36_1 + 1 .. "_name"):setVisible(false)

				arg_36_0.members[iter_36_1 + 1] = 0
			elseif arg_36_0.members[iter_36_1 + 1] == 0 then
				arg_36_0:nodeByName("member" .. iter_36_1 .. "_copy"):setVisible(false)
				arg_36_0:nodeByName("member" .. iter_36_1 .. "_name"):setVisible(false)

				break
			end
		end
	end

	arg_36_0:nodeByName("power"):setString(arg_36_0.zhandouli .. "/" .. arg_36_0.targetzhandouli)
	arg_36_0:nodeByName("member5_copy"):setVisible(false)
	arg_36_0:nodeByName("member5_name"):setVisible(false)
end

function var_0_0.registerEnemyButton(arg_37_0)
	arg_37_0:nodeByName("thwart_button"):setTouchEnabled(true)
	arg_37_0:nodeByName("thwart_button"):setTouchSwallowEnabled(false)
	arg_37_0:nodeByName("thwart_button"):addTouchEventListener(function(arg_38_0, arg_38_1)
		if arg_38_1 == ccui.TouchEventType.ended then
			xyd.WindowManager:get():openWindow("board_enemy_team_window", arg_37_0.mission)
		end
	end)
end

function var_0_0.registerCheckbox(arg_39_0)
	arg_39_0:nodeByName("check_box"):setTouchEnabled(true)
	arg_39_0:nodeByName("check_box"):setTouchSwallowEnabled(false)
	arg_39_0:nodeByName("check_box"):addTouchEventListener(function(arg_40_0, arg_40_1)
		if arg_40_1 == ccui.TouchEventType.ended then
			arg_39_0:switchUseCrystal()
		end
	end)
end

function var_0_0.switchUseCrystal(arg_41_0)
	if arg_41_0.useCrystal then
		arg_41_0:nodeByName("tick"):setVisible(false)
		arg_41_0:nodeByName("double_icon"):setVisible(false)

		arg_41_0.useCrystal = false

		arg_41_0:setMissionAward(false)
	elseif not arg_41_0.useCrystal then
		if arg_41_0.magicStoneNum > 0 then
			arg_41_0:nodeByName("tick"):setVisible(true)
			arg_41_0:nodeByName("double_icon"):setVisible(true)

			arg_41_0.useCrystal = true

			arg_41_0:setMissionAward(true)
		else
			local var_41_0 = var_0_1:translation("BOARD_NO_MAGIC_STONE")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_41_0, function()
				arg_41_0:composeMagicStone()
			end)
		end
	end
end

function var_0_0.composeMagicStone(arg_43_0)
	xyd.WindowManager.get():openWindow("fragment_make", {
		itemID = tonumber(xyd.tables.misc.blessing_crystal_debris)
	})
end

function var_0_0.registerSendButton(arg_44_0)
	arg_44_0:nodeByName("send_button"):setTouchEnabled(true)
	arg_44_0:nodeByName("send_button"):setTouchSwallowEnabled(false)
	arg_44_0:nodeByName("send_button"):addTouchEventListener(function(arg_45_0, arg_45_1)
		if arg_45_1 == ccui.TouchEventType.ended then
			if not arg_44_0:isTeam() then
				local var_45_0 = xyd.tables.translation:translation("EVENT_CENTRE_BOARD_NOT_TEAM")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_45_0
				})
			elseif arg_44_0.selfPlayer.mana < xyd.tables.eventCentreMissionTable:deposit(arg_44_0.mission.mission_id) and arg_44_0.mission.type == 2 then
				local var_45_1 = xyd.tables.translation:translation("EVENT_CENTRE_BOARD_NO_GOLD")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_45_1
				})
			else
				params = {}
				params.mission_id = arg_44_0.mission.mission_id
				params.leader = arg_44_0.heros[arg_44_0.leader]:getHeroID()
				params.partners = {}

				for iter_45_0 = 1, #arg_44_0.members do
					if arg_44_0.members[iter_45_0] == 0 then
						break
					else
						params.partners[iter_45_0] = arg_44_0.heros[arg_44_0.members[iter_45_0]]:getHeroID()
					end
				end

				if arg_44_0.useCrystal then
					params.wish_crystal = 1
				else
					params.wish_crystal = 0
				end

				arg_44_0.eventCentre:receiveMission(params, function(arg_46_0, arg_46_1)
					if arg_46_0 == xyd.error.OK then
						local var_46_0 = {}

						if arg_44_0.useCrystal then
							arg_44_0.selfPlayer:getBackpack():removeItem({
								itemNum = 1,
								itemID = xyd.tables.misc.blessing_crystal
							})
						end

						xyd.EventDispatcher.get():dispatchEvent({
							name = xyd.event.BOARD_MISSION_RECEIVE,
							params = {}
						})
						xyd.WindowManager.get():closeWindow(arg_44_0)
					end
				end)
			end
		end
	end)
end

function var_0_0.updateBoardLev(arg_47_0)
	arg_47_0:nodeByName("lv_num"):removeAllChildren()

	arg_47_0.lev = arg_47_0.eventCentre.boardLev

	local var_47_0 = xyd.AssetLoader.get():loadSprite("windows/event_centre/num/words" .. arg_47_0.lev .. ".png")

	arg_47_0:nodeByName("lv_num"):addChild(var_47_0)
end

function var_0_0.registerHeroSelectCloseButton(arg_48_0)
	arg_48_0:nodeByName("hero_select_close"):setTouchEnabled(true)
	arg_48_0:nodeByName("hero_select_close"):setTouchSwallowEnabled(false)
	arg_48_0:nodeByName("hero_select_close"):addTouchEventListener(function(arg_49_0, arg_49_1)
		if arg_49_1 == ccui.TouchEventType.ended then
			arg_48_0.chooseContainer:setVisible(false)
			arg_48_0.topContainer:setVisible(true)
			arg_48_0:nodeByName("bottom_left_cont"):setVisible(true)
			arg_48_0:nodeByName("bottom_right_cont_hl"):setVisible(false)
			arg_48_0:nodeByName("bottom_left_cont_hl"):setVisible(false)
			arg_48_0:nodeByName("bottom_right_cont"):setVisible(true)
		end
	end)
end

function var_0_0.sortHeros(arg_50_0, arg_50_1)
	if not arg_50_0.hasTargetLeader then
		local var_50_0 = var_0_2.new()

		var_50_0:initUnCollected(arg_50_0.targetLeader)
		table.insert(arg_50_1, var_50_0)
	end

	table.sort(arg_50_1, function(arg_51_0, arg_51_1)
		if arg_51_0:getTableID() == arg_50_0.targetLeader or arg_50_0.targetLeader == xyd.tables.hero:beforeAwaken(arg_51_0:getTableID()) then
			return true
		elseif arg_51_1:getTableID() == arg_50_0.targetLeader or arg_50_0.targetLeader == xyd.tables.hero:beforeAwaken(arg_51_1:getTableID()) then
			return false
		end

		return xyd.heroNormalSort(arg_51_0, arg_51_1) or false
	end)
end

function var_0_0.initHeroList(arg_52_0)
	arg_52_0.herolist = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, 1060, 225),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_52_0:nodeByName("hero_list")):align(display.BOTTOM_CENTER, 0, 0):onScroll(handler(arg_52_0, arg_52_0.heroScrollListener)):pos(0, 0)
end

function var_0_0.heroListDelegate(arg_53_0, arg_53_1, arg_53_2, arg_53_3)
	local var_53_0 = math.ceil(#arg_53_0.heros / 7)

	if cc.ui.UIListView.COUNT_TAG == arg_53_2 then
		return math.ceil(#arg_53_0.heros / 7)
	elseif cc.ui.UIListView.CELL_TAG == arg_53_2 then
		local var_53_1
		local var_53_2
		local var_53_3
		local var_53_4 = arg_53_0.herolist:dequeueItem()

		if not var_53_4 then
			var_53_4 = arg_53_0.herolist:newItem()
		else
			var_53_4:removeAllChildren()
		end

		local var_53_5 = display.newNode()

		var_53_5:setTouchSwallowEnabled(false)

		for iter_53_0 = 1, 7 do
			local var_53_6 = (arg_53_3 - 1) * 7 + iter_53_0

			if var_53_6 > #arg_53_0.heros then
				break
			end

			local var_53_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar_ecb.csb")

			arg_53_0.cells[var_53_6] = var_53_7

			var_53_7:setTouchSwallowEnabled(false)

			local var_53_8 = var_53_7:getChildByName("background")

			var_53_7:addTo(var_53_5)
			var_53_7:setPosition((iter_53_0 - 1) * (var_53_8:getChildByName("avatar"):getWidth() + 20), 0)
			xyd.setAvatarBorder(arg_53_0.heros[var_53_6], var_53_8:getChildByName("avatar"))

			local var_53_9 = var_53_8:getChildByName("chosen")
			local var_53_10 = var_53_8:getChildByName("recommended")

			var_53_9:setLocalZOrder(100)
			var_53_9:setVisible(false)

			local var_53_11 = var_53_8:getChildByName("avatar_mask")

			var_53_11:setLocalZOrder(2)
			var_53_11:setVisible(false)

			if var_53_6 == 1 and arg_53_0.canUseTargetLeader then
				local var_53_12 = xyd.AssetLoader.get():loadSprite("images/recommended.png")

				var_53_12:setAnchorPoint(cc.p(0.5, 1))
				var_53_12:setPosition(cc.p(var_53_7:getCascadeBoundingBox().width / 2, var_53_7:getCascadeBoundingBox().height))
				var_53_8:addChild(var_53_12)
			end

			var_53_8:setScale(0.8)
			var_53_8:getChildByName("lv_txt"):setString(arg_53_0.heros[var_53_6]:getLevel())

			local var_53_13 = var_53_8:getChildByName("name_text")

			var_53_13:setString(arg_53_0.heros[var_53_6]:getName())
			var_53_13:enableOutline(cc.c4b(0, 0, 0, 105), 1)

			if xyd.Color2Level[arg_53_0.heros[var_53_6]:getColor()] ~= "" then
				local var_53_14 = {
					size = 20,
					align = cc.ui.TEXT_ALIGN_LEFT,
					valign = cc.ui.TEXT_VALIGN_BOTTOM,
					x = var_53_13:getX() + var_53_13:getWidth() / 2 - 10,
					y = var_53_13:getY(),
					color = xyd.color.HERO_QUALITY[arg_53_0.heros[var_53_6]:getColor()],
					text = xyd.Color2Level[arg_53_0.heros[var_53_6]:getColor()]
				}
				local var_53_15 = xyd.AssetLoader.get():loadLabel(var_53_14)

				var_53_15:addTo(var_53_8)
				var_53_15:align(display.CENTER_LEFT)
				var_53_15:enableOutline(cc.c4b(0, 0, 0, 255), 1)
				var_53_13:x(var_53_13:getX() - 15)
			end

			if var_53_6 == arg_53_0.leader then
				var_53_8:getChildByName("chosen"):setVisible(true)
				var_53_8:getChildByName("avatar_mask"):setVisible(true)
			end

			for iter_53_1 = 1, 5 do
				if var_53_6 == arg_53_0.members[iter_53_1] then
					var_53_8:getChildByName("chosen"):setVisible(true)
					var_53_8:getChildByName("avatar_mask"):setVisible(true)
				end
			end

			if not arg_53_0.hasTargetLeader and var_53_6 == 1 then
				var_53_8:getChildByName("avatar_mask"):setVisible(true)
			end

			local var_53_16 = var_53_8:getChildByName("dead_text")

			if var_53_16 then
				var_53_16:setVisible(false)
			end

			var_53_7:setTouchEnabled(true)
			var_53_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_54_0)
				if not arg_53_0.hasTargetLeader and var_53_6 == 1 then
					local var_54_0 = xyd.tables.translation:translation("EVENT_CENTRE_BOARD_HERO_BUSY")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_54_0
					})

					return
				end

				if arg_54_0.name == "began" then
					var_53_8:setScale(0.7)

					return true
				elseif arg_54_0.name == "ended" then
					var_53_8:setScale(0.8)

					if not arg_53_0.scrollViewMoved_ then
						if arg_53_0.isChoosingLeader then
							if not var_53_8:getChildByName("chosen"):isVisible() and not arg_53_0.hasLeader then
								var_53_8:getChildByName("chosen"):setVisible(true)
								var_53_8:getChildByName("avatar_mask"):setVisible(true)
								arg_53_0:nodeByName("leader_copy"):removeAllChildren()
								xyd.setAvatarBorderWithLevelAndHp(arg_53_0.heros[var_53_6], arg_53_0:nodeByName("leader_copy"))
								arg_53_0:nodeByName("leader_copy"):setVisible(true)
								arg_53_0:nodeByName("leader_name"):setVisible(true)
								arg_53_0:nodeByName("leader_name"):setString(arg_53_0.heros[var_53_6]:getName())

								arg_53_0.hasLeader = true
								arg_53_0.leader = var_53_6
								arg_53_0.zhandouli = arg_53_0.zhandouli + arg_53_0.heros[var_53_6]:getZhandouli()

								arg_53_0:nodeByName("power"):setString(arg_53_0.zhandouli .. "/" .. arg_53_0.targetzhandouli)
								arg_53_0:refreshEnemyRate()
							elseif arg_53_0.leader == var_53_6 then
								var_53_8:getChildByName("chosen"):setVisible(false)
								var_53_8:getChildByName("avatar_mask"):setVisible(false)
								arg_53_0:nodeByName("leader_copy"):setVisible(false)
								arg_53_0:nodeByName("leader_name"):setVisible(false)

								arg_53_0.hasLeader = false
								arg_53_0.leader = 0
								arg_53_0.zhandouli = arg_53_0.zhandouli - arg_53_0.heros[var_53_6]:getZhandouli()

								arg_53_0:nodeByName("power"):setString(arg_53_0.zhandouli .. "/" .. arg_53_0.targetzhandouli)
								arg_53_0:refreshEnemyRate()
							elseif arg_53_0.leader ~= 0 and not arg_53_0.cells[var_53_6]:getChildByName("background"):getChildByName("avatar_mask"):isVisible() then
								if not tolua.isnull(arg_53_0.cells[arg_53_0.leader]) then
									arg_53_0.cells[arg_53_0.leader]:getChildByName("background"):getChildByName("chosen"):setVisible(false)
									arg_53_0.cells[arg_53_0.leader]:getChildByName("background"):getChildByName("avatar_mask"):setVisible(false)
								end

								arg_53_0.zhandouli = arg_53_0.zhandouli - arg_53_0.heros[arg_53_0.leader]:getZhandouli()

								arg_53_0:nodeByName("power"):setString(arg_53_0.zhandouli .. "/" .. arg_53_0.targetzhandouli)
								var_53_8:getChildByName("chosen"):setVisible(true)
								var_53_8:getChildByName("avatar_mask"):setVisible(true)
								arg_53_0:nodeByName("leader_copy"):removeAllChildren()
								xyd.setAvatarBorderWithLevelAndHp(arg_53_0.heros[var_53_6], arg_53_0:nodeByName("leader_copy"))
								arg_53_0:nodeByName("leader_copy"):setVisible(true)
								arg_53_0:nodeByName("leader_name"):setVisible(true)
								arg_53_0:nodeByName("leader_name"):setString(arg_53_0.heros[var_53_6]:getName())

								arg_53_0.hasLeader = true
								arg_53_0.leader = var_53_6
								arg_53_0.zhandouli = arg_53_0.zhandouli + arg_53_0.heros[var_53_6]:getZhandouli()

								arg_53_0:nodeByName("power"):setString(arg_53_0.zhandouli .. "/" .. arg_53_0.targetzhandouli)
								arg_53_0:refreshEnemyRate()
							end
						elseif arg_53_0.isChoosingMember then
							if not var_53_8:getChildByName("chosen"):isVisible() and arg_53_0.members[5] == 0 then
								var_53_8:getChildByName("chosen"):setVisible(true)
								var_53_8:getChildByName("avatar_mask"):setVisible(true)

								for iter_54_0 = 1, 5 do
									if arg_53_0.members[iter_54_0] == 0 then
										arg_53_0:nodeByName("member" .. iter_54_0 .. "_copy"):removeAllChildren()
										xyd.setAvatarBorderWithLevelAndHp(arg_53_0.heros[var_53_6], arg_53_0:nodeByName("member" .. iter_54_0 .. "_copy"))
										arg_53_0:nodeByName("member" .. iter_54_0 .. "_copy"):setVisible(true)
										arg_53_0:nodeByName("member" .. iter_54_0 .. "_name"):setVisible(true)
										arg_53_0:nodeByName("member" .. iter_54_0 .. "_name"):setString(arg_53_0.heros[var_53_6]:getName())

										arg_53_0.members[iter_54_0] = var_53_6

										arg_53_0:nodeByName("power"):setString(arg_53_0.zhandouli .. "/" .. arg_53_0.targetzhandouli)
										arg_53_0:refreshEnemyRate()

										break
									end
								end
							else
								for iter_54_1 = 1, 5 do
									if arg_53_0.members[iter_54_1] == var_53_6 then
										arg_53_0:cancelMember(var_53_6)
										arg_53_0:refreshEnemyRate()
									end
								end
							end
						end
					end
				end

				return true
			end)
		end

		var_53_5:setAnchorPoint(cc.p(0, 0))
		var_53_5:setPosition(0, 0)
		var_53_5:setContentSize(612, 135)
		var_53_4:addContent(var_53_5)
		var_53_4:setItemSize(612, 135)

		return var_53_4
	end
end

function var_0_0.heroScrollListener(arg_55_0, arg_55_1)
	if arg_55_1.name == "began" then
		arg_55_0.scrollViewMoved_ = false
		arg_55_0.prevY_ = arg_55_1.y
	elseif arg_55_1.name == "moved" and 10 <= math.abs(arg_55_1.y - arg_55_0.prevY_) then
		arg_55_0.scrollViewMoved_ = true
	end
end

function var_0_0.setMissionAward(arg_56_0, arg_56_1)
	if arg_56_0.mission.type == 1 then
		arg_56_0.missionAwardItem = xyd.tables.eventCentreMissionAwardTable:itemId(arg_56_0.mission.award_id)
		arg_56_0.missionAwardItemNumber = xyd.tables.eventCentreMissionAwardTable:itemNumber(arg_56_0.mission.award_id)
		arg_56_0.missionAwardRewardId = xyd.luaStringSplit(xyd.tables.eventCentreMissionAwardTable:rewardId(arg_56_0.mission.award_id), "|")
		arg_56_0.missionAwardRewardResource = xyd.luaStringSplit(xyd.tables.eventCentreMissionAwardTable:rewardResource(arg_56_0.mission.award_id), "|")

		local var_56_0 = 0

		if arg_56_0.missionAwardItem ~= "0" then
			arg_56_0:showAward("item", "item_num", tonumber(arg_56_0.missionAwardItemNumber), var_56_0, arg_56_0.missionAwardItem, arg_56_1)

			var_56_0 = var_56_0 + 200
		end

		for iter_56_0 = 1, #arg_56_0.missionAwardRewardId do
			if arg_56_0.missionAwardRewardId[iter_56_0] == "11" then
				arg_56_0:showAward("dust", "dust_num", tonumber(arg_56_0.missionAwardRewardResource[iter_56_0]), var_56_0, 0, arg_56_1)
			elseif arg_56_0.missionAwardRewardId[iter_56_0] == "12" then
				arg_56_0:showAward("liquid", "liquid_num", tonumber(arg_56_0.missionAwardRewardResource[iter_56_0]), var_56_0, 0, arg_56_1)
			elseif arg_56_0.missionAwardRewardId[iter_56_0] == "13" then
				arg_56_0:showAward("energy", "energy_num", tonumber(arg_56_0.missionAwardRewardResource[iter_56_0]), var_56_0, 0, arg_56_1)
			elseif arg_56_0.missionAwardRewardId[iter_56_0] == "14" then
				arg_56_0:showAward("jinbi", "jinbi_num", tonumber(arg_56_0.missionAwardRewardResource[iter_56_0]), var_56_0, 0, arg_56_1)
			end

			var_56_0 = var_56_0 + 200
		end
	elseif arg_56_0.mission.type == 2 then
		arg_56_0:nodeByName("task_bonus_title"):setString(xyd.tables.translation:translation("EVENT_CENTRE_BOARD_DEPOSIT"))
		arg_56_0:nodeByName("jinbi_bonus_title"):setString(xyd.tables.translation:translation("EVENT_CENTRE_BOARD_REWARD_GOLD"))
		arg_56_0:nodeByName("jinbi_bonus_title"):setVisible(true)
		arg_56_0:nodeByName("jinbi_num"):setString("x" .. xyd.tables.eventCentreMissionTable:deposit(arg_56_0.mission.mission_id))
		arg_56_0:nodeByName("jinbi"):setVisible(true)
		arg_56_0:nodeByName("jinbi_num"):setVisible(true)
		arg_56_0:nodeByName("award_jinbi"):setVisible(true)
		arg_56_0:nodeByName("award_jinbi_num"):setVisible(true)

		if not arg_56_0.useCrystal then
			arg_56_0:nodeByName("award_jinbi_num"):setString("x" .. xyd.tables.eventCentreMissionAwardTable:rewardGold(arg_56_0.mission.award_id))
		else
			arg_56_0:nodeByName("award_jinbi_num"):setString("x" .. tonumber(xyd.tables.eventCentreMissionAwardTable:rewardGold(arg_56_0.mission.award_id)) * 2)
			arg_56_0:nodeByName("award_jinbi_num"):setTextColor(cc.c4b(252, 213, 0, 255))
		end
	end
end

function var_0_0.showAward(arg_57_0, arg_57_1, arg_57_2, arg_57_3, arg_57_4, arg_57_5, arg_57_6)
	local var_57_0 = arg_57_0:nodeByName(arg_57_1)

	var_57_0:setVisible(true)

	if arg_57_5 ~= 0 and not arg_57_6 then
		xyd.setItemBorder(var_57_0, tonumber(arg_57_5))
	end

	local var_57_1 = arg_57_0:nodeByName(arg_57_2)

	var_57_1:setVisible(true)

	if arg_57_0.useCrystal then
		var_57_1:setString("x" .. arg_57_3 * 2)
	else
		var_57_1:setString("x" .. arg_57_3)
	end

	if arg_57_4 > 0 then
		local var_57_2, var_57_3 = var_57_0:getPosition()
		local var_57_4 = 220
		local var_57_5, var_57_6 = var_57_1:getPosition()
		local var_57_7 = 270

		var_57_0:setPosition(cc.p(var_57_4 + arg_57_4, var_57_3))
		var_57_1:setPosition(cc.p(var_57_7 + arg_57_4, var_57_6))
	end

	if arg_57_0.useCrystal then
		var_57_1:setTextColor(cc.c4b(252, 213, 0, 255))
	else
		var_57_1:setTextColor(cc.c4b(255, 255, 255, 255))
	end
end

function var_0_0.isTeam(arg_58_0)
	if not arg_58_0.hasLeader then
		return false
	elseif arg_58_0.members[1] == 0 then
		return false
	end

	return true
end

return var_0_0
