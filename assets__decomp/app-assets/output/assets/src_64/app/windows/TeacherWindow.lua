local var_0_0 = class("TeacherWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.indiegogoTable
local var_0_3 = require("framework.scheduler")
local var_0_4 = 120
local var_0_5 = 40
local var_0_6 = 30
local var_0_7 = 17
local var_0_8 = 3
local var_0_9 = 80
local var_0_10 = {
	TRAVEL = 5,
	TEACHER = 1,
	HOMEWORK = 4,
	LIST = 3,
	STUDENT = 2
}
local var_0_11 = {
	STUDENT = 2,
	TEACHER = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.invite = xyd.ModelManager.get():loadModel(xyd.ModelType.INVITE_FRIENDS_INFOS)
	arg_1_0.originY = 0
	arg_1_0.data = {}
	arg_1_0.releaseList = {}
	arg_1_0.leftBtnType = arg_1_2.functionId or var_0_10.TEACHER
	arg_1_0.missionFreshing = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.REFRESH_CLASS_MISSION_RED, function(arg_3_0)
		if arg_2_0 and not tolua.isnull(arg_2_0) then
			arg_2_0:updateMissionRedPoint(arg_3_0.classType)
		end
	end)
	arg_2_0:layout()
end

function var_0_0.updateApplyRed(arg_4_0)
	if arg_4_0.socialSystem:checkHasTeacherApplyRed() then
		arg_4_0:nodeByName("red_point_" .. var_0_10.LIST):setVisible(true)
	else
		arg_4_0:nodeByName("red_point_" .. var_0_10.LIST):setVisible(false)
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.REFRESH_MASTER_APPLY_RED
	})
end

function var_0_0.updateMissionRedPoint(arg_5_0, arg_5_1)
	arg_5_0:nodeByName("red_point_" .. var_0_10.HOMEWORK):setVisible(false)

	for iter_5_0, iter_5_1 in pairs(arg_5_0.socialSystem.classMissionList[var_0_11.TEACHER]) do
		if iter_5_1.is_complete == 1 and iter_5_1.is_awarded == 0 then
			arg_5_0:nodeByName("red_point_" .. var_0_10.HOMEWORK):setVisible(true)

			break
		end
	end

	arg_5_0:nodeByName("red_point_" .. var_0_10.TRAVEL):setVisible(false)

	for iter_5_2, iter_5_3 in pairs(arg_5_0.socialSystem.classMissionList[var_0_11.STUDENT]) do
		if iter_5_3.is_complete == 1 and iter_5_3.is_awarded == 0 then
			arg_5_0:nodeByName("red_point_" .. var_0_10.TRAVEL):setVisible(true)

			break
		end
	end

	arg_5_0:refreshMission(arg_5_1)
end

function var_0_0.layout(arg_6_0)
	local var_6_0 = arg_6_0:nodeByName("detail_container")
	local var_6_1 = var_6_0:getContentSize()

	arg_6_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_6_1.width, var_6_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_6_0):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	arg_6_0.list:setDelegate(handler(arg_6_0, arg_6_0.delegate))
	arg_6_0:nodeByName("gay_num"):enableOutline(cc.c4b(254, 83, 119, 180), 2)
	arg_6_0:nodeByName("txt_" .. var_0_10.TEACHER):setString(var_0_1:translation("MY_CLASS_TEXT_" .. var_0_10.TEACHER))
	arg_6_0:nodeByName("btn_" .. var_0_10.TEACHER):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended and arg_6_0.leftBtnType ~= var_0_10.TEACHER then
			arg_6_0:updateLeftBtn(var_0_10.TEACHER)
		end
	end)
	arg_6_0:nodeByName("txt_" .. var_0_10.STUDENT):setString(var_0_1:translation("MY_CLASS_TEXT_" .. var_0_10.STUDENT))
	arg_6_0:nodeByName("btn_" .. var_0_10.STUDENT):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended and arg_6_0.leftBtnType ~= var_0_10.STUDENT then
			arg_6_0:updateLeftBtn(var_0_10.STUDENT)
		end
	end)
	arg_6_0:nodeByName("txt_" .. var_0_10.LIST):setString(var_0_1:translation("MY_CLASS_TEXT_" .. var_0_10.LIST))
	arg_6_0:nodeByName("btn_" .. var_0_10.LIST):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended and arg_6_0.leftBtnType ~= var_0_10.LIST then
			arg_6_0:updateLeftBtn(var_0_10.LIST)
		end
	end)
	arg_6_0:nodeByName("txt_" .. var_0_10.HOMEWORK):setString(var_0_1:translation("MY_CLASS_TEXT_" .. var_0_10.HOMEWORK))
	arg_6_0:nodeByName("btn_" .. var_0_10.HOMEWORK):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended and arg_6_0.leftBtnType ~= var_0_10.HOMEWORK then
			arg_6_0:updateLeftBtn(var_0_10.HOMEWORK)
		end
	end)
	arg_6_0:nodeByName("txt_" .. var_0_10.TRAVEL):setString(var_0_1:translation("MY_CLASS_TEXT_" .. var_0_10.TRAVEL))
	arg_6_0:nodeByName("btn_" .. var_0_10.TRAVEL):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended and arg_6_0.leftBtnType ~= var_0_10.TRAVEL then
			arg_6_0:updateLeftBtn(var_0_10.TRAVEL)
		end
	end)
	arg_6_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_12_0, arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended then
			local var_12_0 = {
				ruleType = 2
			}

			xyd.WindowManager.get():openWindow("teacher_rule", var_12_0)
		end
	end)
	arg_6_0:nodeByName("search_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		xyd.buttonScaleAnim(arg_13_0, arg_13_1)

		if arg_13_1 == ccui.TouchEventType.ended then
			if arg_6_0.leftBtnType == var_0_10.TEACHER then
				local var_13_0 = {
					relation_type = var_0_11.TEACHER
				}

				arg_6_0.socialSystem:getFindingList(var_13_0, function(arg_14_0, arg_14_1)
					if arg_14_0 == xyd.error.OK then
						xyd.playButtonSound()

						local var_14_0 = {
							data = arg_14_1.player_list,
							relation = var_0_11.TEACHER
						}

						xyd.WindowManager.get():openWindow("find_teach_wnd", var_14_0)
					end
				end)
			elseif arg_6_0.leftBtnType == var_0_10.STUDENT then
				if arg_6_0.selfPlayer.lev < xyd.tables.misc.teacherLev then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("TEACHER_MAIN_TIP2")
					})

					return
				end

				local var_13_1 = {
					relation_type = var_0_11.STUDENT
				}

				arg_6_0.socialSystem:getFindingList(var_13_1, function(arg_15_0, arg_15_1)
					if arg_15_0 == xyd.error.OK then
						xyd.playButtonSound()

						local var_15_0 = {
							data = arg_15_1.player_list,
							relation = var_0_11.STUDENT
						}

						xyd.WindowManager.get():openWindow("find_teach_wnd", var_15_0)
					end
				end)
			else
				local var_13_2 = {}

				var_13_2.is_deny_all = 1

				if #arg_6_0.data > 0 then
					arg_6_0.socialSystem:denyTeachApply(var_13_2, function(arg_16_0, arg_16_1)
						if arg_16_0 == xyd.error.OK then
							arg_6_0.data = {}

							arg_6_0.list:reload()
						end
					end)
				end
			end
		end
	end)
	arg_6_0:nodeByName("btn_teacher"):setBrightStyle(ccui.BrightStyle.highlight)
	arg_6_0:nodeByName("btn_teacher"):setTouchEnabled(false)

	local var_6_2 = xyd.WindowManager.get():getWindow("social_system")

	arg_6_0:nodeByName("btn_indiegogo"):addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.ended then
			if arg_6_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_INDIEGOGO) then
				var_6_2:gotoIndiegogo()
			else
				local var_17_0 = var_0_1:translation("FUNCTION_OPEN_TIP_OTHER")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_17_0
				})
			end
		end
	end)
	arg_6_0:nodeByName("btn_friend"):addTouchEventListener(function(arg_18_0, arg_18_1)
		if arg_18_1 == ccui.TouchEventType.ended then
			var_6_2:gotoFriend()
		end
	end)

	local var_6_3 = xyd.tables.misc.indiegogoStorageUpper

	arg_6_0:updateLeftBtn(arg_6_0.leftBtnType)
	arg_6_0:checkFunctionIsOpen()
	arg_6_0:updateMissionRedPoint()
	arg_6_0:updateApplyRed()
end

function var_0_0.checkFunctionIsOpen(arg_19_0)
	return
end

function var_0_0.scrollListener(arg_20_0, arg_20_1)
	if arg_20_1.name == "began" then
		arg_20_0.scrollViewMoved_ = false
		arg_20_0.prevY_ = arg_20_1.y
	elseif arg_20_1.name == "moved" and 10 <= math.abs(arg_20_1.y - arg_20_0.prevY_) then
		arg_20_0.scrollViewMoved_ = true
	end

	arg_20_0.originY = arg_20_0.list.scrollNode:getPositionY()
end

function var_0_0.updateLeftBtn(arg_21_0, arg_21_1)
	local var_21_0 = arg_21_0:checkBtnShow() or arg_21_1

	arg_21_0.leftBtnType = var_21_0

	for iter_21_0, iter_21_1 in pairs(var_0_10) do
		arg_21_0:nodeByName("btn_" .. iter_21_1):setTouchEnabled(true)
		arg_21_0:nodeByName("btn_" .. iter_21_1):setBrightStyle(ccui.BrightStyle.normal)
	end

	arg_21_0:nodeByName("btn_" .. var_21_0):setTouchEnabled(false)
	arg_21_0:nodeByName("btn_" .. var_21_0):setBrightStyle(ccui.BrightStyle.highlight)
	arg_21_0:nodeByName("search_btn"):setVisible(true)
	arg_21_0:nodeByName("gay_words"):setVisible(true)
	arg_21_0:nodeByName("gay_num"):setVisible(true)
	arg_21_0:nodeByName("hero_panel"):setVisible(false)

	if var_21_0 == var_0_10.TEACHER then
		if type(arg_21_0.socialSystem.teacherInfo.idInfo) ~= "table" or not arg_21_0.socialSystem.teacherInfo.idInfo.player_id then
			arg_21_0:nodeByName("hero_panel"):setVisible(true)
			arg_21_0:nodeByName("tip_words"):setString(string.format(var_0_1:translation("TEACHER_MAIN_TIP1"), var_0_1:translation("TEACHER_NAME1")))

			arg_21_0.data = {}
		else
			arg_21_0:nodeByName("hero_panel"):setVisible(false)

			arg_21_0.data = {
				arg_21_0.socialSystem.teacherInfo.idInfo
			}
		end

		arg_21_0:nodeByName("search_text"):setString(var_0_1:translation("MY_CLASS_TEXT_6"))
		arg_21_0:nodeByName("gay_words"):setString(string.format(var_0_1:translation("TEACHER_RELATION"), var_0_1:translation("TEACHER_NAME1")))
	elseif var_21_0 == var_0_10.STUDENT then
		if type(arg_21_0.socialSystem.studentInfo.idInfo) ~= "table" or not arg_21_0.socialSystem.studentInfo.idInfo.player_id then
			arg_21_0:nodeByName("hero_panel"):setVisible(true)

			if arg_21_0.selfPlayer.lev < xyd.tables.misc.teacherLev then
				arg_21_0:nodeByName("tip_words"):setString(var_0_1:translation("TEACHER_MAIN_TIP2"))
			else
				arg_21_0:nodeByName("tip_words"):setString(string.format(var_0_1:translation("TEACHER_MAIN_TIP1"), var_0_1:translation("TEACHER_NAME2")))
			end

			arg_21_0.data = {}
		else
			arg_21_0:nodeByName("hero_panel"):setVisible(false)

			arg_21_0.data = {
				arg_21_0.socialSystem.studentInfo.idInfo
			}
		end

		arg_21_0:nodeByName("search_text"):setString(var_0_1:translation("MY_CLASS_TEXT_7"))
		arg_21_0:nodeByName("gay_words"):setString(string.format(var_0_1:translation("TEACHER_RELATION"), var_0_1:translation("TEACHER_NAME2")))
	elseif var_21_0 == var_0_10.LIST then
		arg_21_0.data = arg_21_0.socialSystem.classApplyList

		if #arg_21_0.data == 0 then
			arg_21_0:nodeByName("hero_panel"):setVisible(true)
			arg_21_0:nodeByName("tip_words"):setString(var_0_1:translation("TEACHER_SEND_NO"))
			arg_21_0:nodeByName("search_btn"):setVisible(false)
		else
			arg_21_0:nodeByName("hero_panel"):setVisible(false)
			arg_21_0:nodeByName("search_btn"):setVisible(true)
		end

		arg_21_0:nodeByName("search_text"):setString(var_0_1:translation("MY_CLASS_TEXT_8"))
		arg_21_0:nodeByName("gay_words"):setVisible(false)
		arg_21_0:nodeByName("gay_num"):setVisible(false)
	elseif var_21_0 == var_0_10.HOMEWORK then
		arg_21_0:nodeByName("search_btn"):setVisible(false)

		arg_21_0.data = arg_21_0.socialSystem.classMissionList[var_0_11.TEACHER] or {}

		arg_21_0:nodeByName("gay_words"):setString(string.format(var_0_1:translation("TEACHER_RELATION"), var_0_1:translation("TEACHER_NAME2")))
	elseif var_21_0 == var_0_10.TRAVEL then
		arg_21_0:nodeByName("search_btn"):setVisible(false)

		arg_21_0.data = arg_21_0.socialSystem.classMissionList[var_0_11.STUDENT] or {}

		arg_21_0:nodeByName("gay_words"):setString(string.format(var_0_1:translation("TEACHER_RELATION"), var_0_1:translation("TEACHER_NAME1")))
	end

	arg_21_0.list:reload()
	arg_21_0:updateIntimacy()
end

function var_0_0.checkBtnShow(arg_22_0)
	local var_22_0 = true

	for iter_22_0, iter_22_1 in pairs(arg_22_0.socialSystem.classMissionList[var_0_11.STUDENT]) do
		local var_22_1 = iter_22_1.table_id

		if xyd.tables.teacherMission:openLev(var_22_1) > 0 and iter_22_1.is_awarded == 0 then
			var_22_0 = false

			break
		end
	end

	local var_22_2 = false

	if type(arg_22_0.socialSystem.teacherInfo.idInfo) ~= "table" or not arg_22_0.socialSystem.teacherInfo.idInfo.player_id then
		if arg_22_0.selfPlayer.lev >= xyd.tables.misc.studentLevLimit then
			var_22_2 = true
		end
	elseif var_22_0 then
		var_22_2 = true
	end

	if var_22_2 then
		arg_22_0:nodeByName("btn_" .. var_0_10.TEACHER):setVisible(false)
		arg_22_0:nodeByName("btn_" .. var_0_10.TRAVEL):setVisible(false)

		for iter_22_2 = var_0_10.STUDENT, var_0_10.HOMEWORK do
			arg_22_0:nodeByName("btn_" .. iter_22_2):setPositionY(arg_22_0:nodeByName("btn_1"):getPositionY() - var_0_9 * (iter_22_2 - var_0_10.STUDENT))
		end

		if arg_22_0.leftBtnType == var_0_10.TEACHER then
			arg_22_0.leftBtnType = var_0_10.STUDENT

			return arg_22_0.leftBtnType
		end
	end
end

function var_0_0.refreshMission(arg_23_0, arg_23_1)
	local function var_23_0(arg_24_0)
		arg_23_0.data = arg_23_0.socialSystem.classMissionList[arg_24_0] or {}

		arg_23_0.list:reload()
		arg_23_0.list:scrollTo(0, arg_23_0.originY)
	end

	if not arg_23_1 then
		if arg_23_0.leftBtnType == var_0_10.HOMEWORK then
			var_23_0(var_0_11.TEACHER)
		elseif arg_23_0.leftBtnType == var_0_10.TRAVEL then
			var_23_0(var_0_11.STUDENT)
		end

		return
	end

	if not arg_23_0.missionFreshing then
		arg_23_0.missionFreshing = true
		arg_23_0.refreshMissionHandle = var_0_3.performWithDelayGlobal(function()
			if arg_23_1 == 1 and arg_23_0.leftBtnType == var_0_10.HOMEWORK then
				var_23_0(arg_23_1)
			elseif arg_23_1 == 2 and arg_23_0.leftBtnType == var_0_10.TRAVEL then
				var_23_0(arg_23_1)
			end

			arg_23_0.missionFreshing = false
		end, 2)
	end
end

function var_0_0.delegate(arg_26_0, arg_26_1, arg_26_2, arg_26_3)
	if cc.ui.UIListView.COUNT_TAG == arg_26_2 then
		return #arg_26_0.data
	elseif cc.ui.UIListView.CELL_TAG == arg_26_2 then
		if arg_26_3 > #arg_26_0.data then
			return
		end

		local var_26_0 = arg_26_0.list:dequeueItem() or arg_26_0.list:newItem()

		var_26_0:removeAllChildren(true)

		local var_26_1

		if arg_26_0.leftBtnType == var_0_10.LIST then
			var_26_1 = arg_26_0:createApplyItemContent(arg_26_3)
		elseif arg_26_0.leftBtnType == var_0_10.TEACHER or arg_26_0.leftBtnType == var_0_10.STUDENT then
			var_26_1 = arg_26_0:createFriendItemContent(arg_26_3)
		elseif arg_26_0.leftBtnType == var_0_10.HOMEWORK then
			local var_26_2 = arg_26_0.socialSystem.classMissionFinishNum[1] or 0

			var_26_1 = arg_26_0:createRecallAwardContent(arg_26_3, var_26_2, 1)
		elseif arg_26_0.leftBtnType == var_0_10.TRAVEL then
			local var_26_3 = arg_26_0.socialSystem.classMissionFinishNum[2] or 0

			var_26_1 = arg_26_0:createRecallAwardContent(arg_26_3, var_26_3, 2)
		end

		local var_26_4 = var_26_1:getWidth()
		local var_26_5 = var_26_1:getHeight()

		var_26_0:setItemSize(var_26_4, var_26_5 + var_0_8)
		var_26_0:addContent(var_26_1)

		return var_26_0
	end
end

function var_0_0.freshInfos(arg_27_0)
	if arg_27_0.leftBtnType == var_0_10.TEACHER or arg_27_0.leftBtnType == var_0_10.STUDENT then
		arg_27_0:updateLeftBtn(arg_27_0.leftBtnType)
	else
		arg_27_0:updateIntimacy()
	end
end

function var_0_0.createRecallAwardContent(arg_28_0, arg_28_1, arg_28_2, arg_28_3)
	local var_28_0 = display.newNode()
	local var_28_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/social_system/friend_recall/recall_award_item.csb")
	local var_28_2 = var_28_1:getChildByName("container")

	var_28_2:getChildByName("process_txt"):setVisible(false)
	var_28_2:getChildByName("reach_goal_text"):setVisible(false)
	var_28_2:getChildByName("has_gotten_text"):setVisible(false)

	local var_28_3 = arg_28_0.data[arg_28_1].table_id

	if arg_28_1 <= arg_28_2 then
		var_28_2:getChildByName("item_bg2"):setVisible(false)
		var_28_2:getChildByName("reach_goal_text"):setVisible(true)
		var_28_1:setTouchEnabled(true)
		var_28_1:setTouchSwallowEnabled(false)
		var_28_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_29_0)
			if arg_29_0.name == "began" then
				var_28_2:setScale(0.9)

				return true
			elseif arg_29_0.name == "moved" then
				if arg_28_0.scrollViewMoved_ then
					var_28_2:setScale(1)
				end

				return true
			elseif arg_29_0.name == "ended" then
				var_28_2:setScale(1)

				if not arg_28_0.scrollViewMoved_ then
					local var_29_0 = {
						mission_id = var_28_3
					}
					local var_29_1 = false

					local function var_29_2()
						arg_28_0.socialSystem:getClassAward(var_29_0, function(arg_31_0, arg_31_1)
							if arg_31_0 == xyd.error.OK then
								if arg_31_1 and arg_31_1.awards then
									xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards(arg_31_1.awards)
								end

								local var_31_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)

								var_31_0.classMissionList[arg_28_3][arg_28_1].is_awarded = 1

								table.remove(var_31_0.classMissionList[arg_28_3], arg_28_1)

								if var_31_0.classMissionFinishNum[arg_28_3] > 0 then
									var_31_0.classMissionFinishNum[arg_28_3] = var_31_0.classMissionFinishNum[arg_28_3] - 1
								end

								xyd.EventDispatcher.get():dispatchEvent({
									name = xyd.event.REFRESH_CLASS_MISSION_RED,
									hasRed = var_31_0:sortClassMissionList()
								})

								if not arg_28_0 or tolua.isnull(arg_28_0) then
									return
								end

								if var_29_1 then
									arg_28_0.socialSystem:getClassInfo(function(arg_32_0, arg_32_1)
										if arg_32_0 == xyd.error.OK then
											arg_28_0:updateLeftBtn(var_0_10.STUDENT)
											xyd.WindowManager.get():openWindow("graduation")
										end
									end)
								end
							end
						end)
					end

					if xyd.tables.teacherMission:openLev(var_28_3) > 0 and arg_28_0.selfPlayer.lev >= xyd.tables.teacherMission:openLev(var_28_3) then
						var_29_1 = true

						if arg_28_0.socialSystem.classMissionFinishNum[2] > 1 then
							local var_29_3 = var_0_1:translation("IS_GRADUATION")

							xyd.AlertWindow.open(xyd.AlertType.YES_NO, {
								var_29_3
							}, function(arg_33_0)
								if arg_33_0 then
									var_29_2()
								end
							end)
						else
							var_29_2()
						end
					else
						var_29_2()
					end
				end
			end
		end)
	elseif arg_28_1 <= #arg_28_0.data then
		var_28_2:getChildByName("process_txt"):setVisible(true)

		local var_28_4 = arg_28_0.data[arg_28_1].progress

		var_28_2:getChildByName("process_txt"):setString(var_28_4 .. "/" .. xyd.tables.teacherMission:condition(var_28_3))

		if xyd.tables.teacherMission:openLev(var_28_3) > 0 and arg_28_0.selfPlayer.lev >= xyd.tables.teacherMission:openLev(var_28_3) then
			var_28_2:getChildByName("go_btn"):setVisible(true)
			var_28_2:getChildByName("go_btn"):getChildByName("text_go"):setString(var_0_1:translation("BUTTON_NAME_GO"))
			var_28_2:getChildByName("process_txt"):setVisible(false)
			var_28_2:getChildByName("go_btn"):addTouchEventListener(function(arg_34_0, arg_34_1)
				xyd.buttonScaleAnim(arg_34_0, arg_34_1)

				if arg_34_1 == ccui.TouchEventType.ended then
					local var_34_0 = {
						star = 0,
						dailyLimit = 1,
						resetCount = 0,
						campaignID = xyd.tables.teacherMission:extraInfo(var_28_3),
						campaignType = xyd.CampaignType.STUDENT_OVER
					}

					xyd.WindowManager.get():openWindow("map_detail_window", var_34_0)
				end
			end)
		end
	end

	var_28_2:getChildByName("item_title"):setString(xyd.tables.teacherMission:desc(var_28_3))

	local var_28_5 = xyd.tables.teacherMission:gift(var_28_3)
	local var_28_6 = xyd.tables.gift:items(var_28_5)
	local var_28_7 = xyd.tables.gift:itemNum(var_28_5)
	local var_28_8 = var_28_2:getChildByName("reward_pos"):getChildByName("award_num")
	local var_28_9

	if xyd.tables.gift:crystal(var_28_5) > 0 then
		var_28_2:getChildByName("reward_pos"):getChildByName("award_num"):setString("x" .. xyd.tables.gift:crystal(var_28_5))

		var_28_9 = var_28_8:getPositionX() + var_28_8:getContentSize().width + 10
	else
		local var_28_10 = var_28_2:getChildByName("reward_pos"):getChildByName("yuanbao")

		var_28_9 = var_28_10:getPositionX() - var_28_10:getWidth() / 2

		var_28_2:getChildByName("reward_pos"):getChildByName("award_num"):setVisible(false)
		var_28_2:getChildByName("reward_pos"):getChildByName("yuanbao"):setVisible(false)
	end

	if #var_28_6 > 0 and var_28_6[1] ~= 0 then
		for iter_28_0 = 1, #var_28_6 do
			local var_28_11 = arg_28_0:createRewardContent(var_28_6[iter_28_0], var_28_7[iter_28_0])

			var_28_11:setAnchorPoint(cc.p(0, 0))
			var_28_11:addTo(var_28_2:getChildByName("reward_pos"))
			var_28_11:setPosition(var_28_9 + var_28_11:getContentSize().width * (iter_28_0 - 1), 2)
		end
	end

	var_28_1:addTo(var_28_0)
	var_28_1:setAnchorPoint(cc.p(0, 0))
	var_28_0:setContentSize(var_28_2:getWidth(), var_28_2:getHeight())
	var_28_1:setName("source")

	return var_28_0
end

function var_0_0.createRewardContent(arg_35_0, arg_35_1, arg_35_2)
	local var_35_0 = display.newNode()
	local var_35_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/social_system/friend_recall/reward_item.csb")
	local var_35_2 = var_35_1:getChildByName("container")

	var_35_2:getChildByName("icon_container"):setTouchSwallowEnabled(false)
	xyd.setItemAndAddTips(var_35_2:getChildByName("icon_container"), arg_35_1)
	var_35_2:getChildByName("item_num_txt"):setString(arg_35_2)
	var_35_1:addTo(var_35_0)
	var_35_1:setAnchorPoint(cc.p(0, 0))
	var_35_1:setPosition(0, 0)
	var_35_0:setContentSize(var_35_2:getContentSize())
	var_35_1:setName("source")

	return var_35_0
end

function var_0_0.createApplyItemContent(arg_36_0, arg_36_1)
	local var_36_0 = display.newNode()
	local var_36_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/social_system/manage_friend/apply_list_item.csb")
	local var_36_2 = var_36_1:getChildByName("container")
	local var_36_3 = var_36_2:getChildByName("name_bg")
	local var_36_4 = arg_36_0.data[arg_36_1]
	local var_36_5 = var_36_4.player_info
	local var_36_6 = {
		avatar_id = var_36_5.avatar_id,
		avatar_frame_id = var_36_5.avatar_frame_id
	}

	if var_36_4.is_online == 0 then
		var_36_6.isGray = true
	end

	var_36_6.playerInfo = var_36_4

	xyd.setPlayerAvatar(var_36_2:getChildByName("avtar_container"), var_36_6)

	if var_36_5.conquer_lev and var_36_5.conquer_lev > 0 then
		xyd.setConquerLev(var_36_5.conquer_lev, var_36_3:getChildByName("lev_txt"), var_36_3:getChildByName("dengjiquan"), nil, nil, nil, nil, var_36_5.conquer_loop_id)
	else
		var_36_3:getChildByName("lev_txt"):setString(var_36_5.lev)
	end

	var_36_3:getChildByName("name_txt"):setString(var_36_5.player_name)
	var_36_1:addTo(var_36_0)
	var_36_1:setAnchorPoint(cc.p(0, 0))

	local var_36_7 = {
		size = 20,
		color = cc.c3b(93, 32, 32)
	}
	local var_36_8 = xyd.AssetLoader.get():loadLabel(var_36_7)

	var_36_8:setMaxLineWidth(274)
	var_36_8:setLineBreakWithoutSpace(true)

	local var_36_9 = var_36_4.msg or ""

	if var_36_9 == "" then
		if var_36_4.relation_type == var_0_11.TEACHER then
			var_36_9 = var_0_1:translation("TEACHER_SEND_TIP2")
		else
			var_36_9 = var_0_1:translation("TEACHER_SEND_TIP1")
		end
	end

	var_36_8:setString(var_36_9)
	var_36_8:setAnchorPoint(cc.p(0, 0.5))
	var_36_8:addTo(var_36_2)
	var_36_8:setPosition(var_36_2:getChildByName("request_msg_point"):getPosition())
	var_36_0:setContentSize(var_36_2:getContentSize())
	var_36_1:setName("source")

	arg_36_0.friendlistID = {}

	for iter_36_0, iter_36_1 in ipairs(arg_36_0.socialSystem.friendlist) do
		table.insert(arg_36_0.friendlistID, iter_36_1.player_id)
	end

	var_36_2:getChildByName("agree_btn"):addTouchEventListener(function(arg_37_0, arg_37_1)
		xyd.buttonScaleAnim(arg_37_0, arg_37_1)

		if arg_37_1 == ccui.TouchEventType.ended then
			local var_37_0 = false

			for iter_37_0, iter_37_1 in ipairs(arg_36_0.friendlistID) do
				if iter_37_1 == var_36_5.player_id then
					var_37_0 = true

					break
				end
			end

			if arg_36_0.socialSystem:getFriendsCount() >= xyd.tables.misc.friendNumberLimit and not var_37_0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("FRIEND_NUM_LIMIT_TIPS")
				})

				return
			end

			local var_37_1 = ""

			if var_36_4.relation_type == var_0_11.TEACHER then
				var_37_1 = var_0_1:translation("IS_GET_TEACHER")
			else
				var_37_1 = var_0_1:translation("IS_GET_STUDENT")
			end

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_37_1, function()
				local var_38_0 = {
					from_player_id = var_36_5.player_id
				}

				arg_36_0.socialSystem:acceptTeachApply(var_38_0, function(arg_39_0, arg_39_1)
					if arg_39_0 == xyd.error.OK then
						table.remove(arg_36_0.data, arg_36_1)

						if not var_37_0 then
							table.insert(arg_36_0.socialSystem.friendlist, arg_39_1.base_info.relations[var_36_4.relation_type])
						end
					else
						table.remove(arg_36_0.data, arg_36_1)
					end

					arg_36_0.list:reload()
					arg_36_0:updateApplyRed()
				end)
			end, nil, nil, arg_36_0.colorMode)
		end
	end)
	var_36_2:getChildByName("refuse_btn"):addTouchEventListener(function(arg_40_0, arg_40_1)
		xyd.buttonScaleAnim(arg_40_0, arg_40_1)

		if arg_40_1 == ccui.TouchEventType.ended then
			local var_40_0 = {
				from_player_id = var_36_5.player_id
			}

			arg_36_0.socialSystem:denyTeachApply(var_40_0, function(arg_41_0, arg_41_1)
				if arg_41_0 == xyd.error.OK then
					table.remove(arg_36_0.data, arg_36_1)
					arg_36_0.list:reload()
					arg_36_0:updateApplyRed()
				end
			end)
		end
	end)
	var_36_2:getChildByName("ignore_btn"):addTouchEventListener(function(arg_42_0, arg_42_1)
		xyd.buttonScaleAnim(arg_42_0, arg_42_1)

		if arg_42_1 == ccui.TouchEventType.ended then
			var_36_6.player_id = var_36_5.player_id

			arg_36_0.socialSystem:addBlackList(var_36_6, function(arg_43_0, arg_43_1)
				if arg_43_0 == xyd.error.OK then
					table.insert(arg_36_0.socialSystem.blacklist, var_36_4.player_info)
					table.remove(arg_36_0.data, arg_36_1)
					arg_36_0.list:reload()
					arg_36_0:updateApplyRed()

					local var_43_0 = xyd.WindowManager.get():getWindow("social_system")

					if var_43_0 and not tolua.isnull(var_43_0) then
						var_43_0:updateRightList()
					end
				end
			end)
		end
	end)

	return var_36_0
end

function var_0_0.createFriendItemContent(arg_44_0, arg_44_1)
	local var_44_0 = display.newNode()
	local var_44_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/social_system/manage_friend/friend_item.csb")
	local var_44_2 = var_44_1:getChildByName("container")
	local var_44_3 = var_44_2:getChildByName("name_bg")
	local var_44_4 = arg_44_0.data[arg_44_1]
	local var_44_5 = {
		avatar_id = var_44_4.avatar_id,
		avatar_frame_id = var_44_4.avatar_frame_id
	}

	if var_44_4.is_online == 0 then
		var_44_5.isGray = true
	end

	var_44_5.playerInfo = var_44_4

	xyd.setPlayerAvatar(var_44_2:getChildByName("avtar_container"), var_44_5)
	var_44_2:getChildByName("avtar_container"):setPositionX(var_44_2:getChildByName("avtar_container"):getPositionX() + 5)
	arg_44_0.socialSystem:setNameBg(var_44_3, var_44_4)

	local var_44_6 = var_0_11.STUDENT

	if arg_44_0.leftBtnType == var_0_10.TEACHER then
		var_44_3:getChildByName("region_txt"):setString(var_0_1:translation("TEACHER_NAME1"))

		var_44_6 = var_0_11.TEACHER
	else
		var_44_3:getChildByName("region_txt"):setString(var_0_1:translation("TEACHER_NAME2"))
	end

	var_44_2:getChildByName("newmsg_tip"):getChildByName("right_txt"):setString(var_0_1:translation("HAVE_NEW_MESSAGE_TEXT") .. "]")

	if xyd.db.newMessagesCount:getCount(arg_44_0.selfPlayer.playerID, var_44_4.player_id) > 0 then
		var_44_2:getChildByName("newmsg_tip"):setVisible(true)
		var_44_2:getChildByName("friend_state_txt"):setVisible(false)
	else
		var_44_2:getChildByName("newmsg_tip"):setVisible(false)
		var_44_2:getChildByName("friend_state_txt"):setVisible(true)
		arg_44_0.socialSystem:setOnlineState(var_44_2:getChildByName("friend_state_txt"), var_44_4)
	end

	var_44_1:addTo(var_44_0)
	var_44_1:setAnchorPoint(cc.p(0, 0))
	var_44_1:setScale(0.97)
	var_44_0:setContentSize(var_44_2:getContentSize().width, var_44_2:getContentSize().height * 0.97)
	var_44_1:setName("source")
	var_44_2:getChildByName("chat_btn"):addTouchEventListener(function(arg_45_0, arg_45_1)
		xyd.buttonScaleAnim(arg_45_0, arg_45_1)

		if arg_45_1 == ccui.TouchEventType.ended and arg_44_0.scrollViewMoved_ == false then
			local var_45_0 = {
				currentFriend = var_44_4
			}

			xyd.WindowManager.get():openWindow("social_system_chat_window", var_45_0)
		end
	end)
	var_44_2:getChildByName("delete_btn"):addTouchEventListener(function(arg_46_0, arg_46_1)
		xyd.buttonScaleAnim(arg_46_0, arg_46_1)

		if arg_46_1 == ccui.TouchEventType.ended then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
				var_0_1:translation("TEACHER_RELATION_BROKEN_TIP1")
			}, function()
				local var_47_0 = {
					relation_type = var_44_6
				}

				arg_44_0.socialSystem:terminateRelation(var_47_0, function(arg_48_0, arg_48_1)
					if arg_48_0 == xyd.error.OK then
						arg_44_0.data = {}

						arg_44_0.list:reload()
					end
				end)
			end, nil, nil, arg_44_0.colorMode)
		end
	end)
	var_44_2:getChildByName("compare_btn"):addTouchEventListener(function(arg_49_0, arg_49_1)
		xyd.buttonScaleAnim(arg_49_0, arg_49_1)

		if arg_49_1 == ccui.TouchEventType.ended then
			if arg_44_0.selfPlayer.lev < xyd.tables.misc.friendBattleLevel or var_44_4.lev < xyd.tables.misc.friendBattleLevel then
				local var_49_0 = string.format(var_0_1:translation("UNDER_FRIEND_BATTLE_LEV"), xyd.tables.misc.friendBattleLevel)

				xyd.WindowManager.get():openWindow("toast", {
					message = var_49_0
				})

				return
			end

			local var_49_1 = {
				friend_id = var_44_4.player_id
			}

			xyd.WindowManager.get():openWindow("social_system_select_mode", var_49_1)
		end
	end)

	if var_44_4.is_sent == true then
		var_44_2:getChildByName("send_gift_btn"):setBright(false)
		var_44_2:getChildByName("send_gift_btn"):setTouchEnabled(false)
	end

	var_44_2:getChildByName("send_gift_btn"):addTouchEventListener(function(arg_50_0, arg_50_1)
		xyd.buttonScaleAnim(arg_50_0, arg_50_1)

		if arg_50_1 == ccui.TouchEventType.ended then
			if arg_44_0.socialSystem.sendGiftCount >= xyd.tables.misc.giftSendLimit then
				local var_50_0 = var_0_1:translation("REACH_SEND_GIFT_LIMIT_TEXT")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_50_0
				})

				return
			end

			local var_50_1 = {
				player_id = var_44_4.player_id
			}

			arg_44_0.socialSystem:sendSocialGift(var_50_1, function(arg_51_0, arg_51_1)
				if arg_51_0 == xyd.error.OK then
					arg_44_0.socialSystem.sendGiftCount = arg_44_0.socialSystem.sendGiftCount + 1
					var_44_4.is_sent = true

					for iter_51_0, iter_51_1 in pairs(arg_44_0.socialSystem.friendlist) do
						if iter_51_1.player_id == var_44_4.player_id then
							iter_51_1.is_sent = true

							break
						end
					end

					var_44_2:getChildByName("send_gift_btn"):setBright(false)
					var_44_2:getChildByName("send_gift_btn"):setTouchEnabled(false)

					local var_51_0 = string.format(var_0_1:translation("SEND_SOCIAL_GIFT_SUCCEED"), arg_44_0.invite:getInvitorName())

					xyd.WindowManager.get():openWindow("toast", {
						message = var_51_0
					})

					local var_51_1 = xyd.WindowManager.get():getWindow("social_system")

					if var_51_1 and not tolua.isnull(var_51_1) then
						var_51_1.getWindowBackFromTeacher = true

						var_51_1:updateRightList()

						var_51_1.getWindowBackFromTeacher = false
					end

					arg_44_0:updateIntimacy()
				end
			end)
		end
	end)

	return var_44_0
end

function var_0_0.updateIntimacy(arg_52_0)
	if arg_52_0.leftBtnType == var_0_10.TEACHER or arg_52_0.leftBtnType == var_0_10.TRAVEL then
		local var_52_0 = arg_52_0.socialSystem.teacherInfo.intimacy or 0

		arg_52_0:nodeByName("gay_num"):setString(var_52_0)
	elseif arg_52_0.leftBtnType == var_0_10.STUDENT or arg_52_0.leftBtnType == var_0_10.HOMEWORK then
		local var_52_1 = arg_52_0.socialSystem.studentInfo.intimacy or 0

		arg_52_0:nodeByName("gay_num"):setString(var_52_1)
	end
end

function var_0_0.openCheckOrderWnd(arg_53_0, arg_53_1)
	arg_53_0.socialSystem:getInfoByID(arg_53_1, function(arg_54_0, arg_54_1)
		if arg_54_0 == xyd.error.OK then
			xyd.WindowManager.get():openWindow("indiegogo_check_order", arg_54_1)
		else
			local var_54_0 = var_0_1:translation("INDIEGOGO_HAVE_OVER")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_54_0
			})
		end
	end)
end

function var_0_0.didOpen(arg_55_0, arg_55_1)
	var_0_0.super:didOpen(arg_55_1)
	arg_55_0.list:reload()
	arg_55_0:IsGotoCheckWnd()
end

function var_0_0.IsGotoCheckWnd(arg_56_0)
	if arg_56_0.isGotoCheck and arg_56_0.gotoFundID then
		local var_56_0 = {
			fund_id = arg_56_0.gotoFundID
		}

		arg_56_0:openCheckOrderWnd(var_56_0)
	end
end

function var_0_0.willClose(arg_57_0)
	local var_57_0 = xyd.WindowManager.get():getWindow("social_system")

	if var_57_0 then
		var_57_0.teacherState = arg_57_0.leftBtnType
	end

	if arg_57_0.refreshMissionHandle then
		var_0_3.unscheduleGlobal(arg_57_0.refreshMissionHandle)
	end
end

return var_0_0
