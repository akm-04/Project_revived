local var_0_0 = class("Course", import(".BaseModel"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.roomInfo = {}
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.applyCourse(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = arg_3_1 or {}

	xyd.Backend.get():request(xyd.mid.APPLY_COURSE, var_3_0, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK and arg_4_1 then
			arg_3_0:handleInfos(arg_4_1, var_3_0)
		end

		if arg_3_2 then
			arg_3_2(arg_4_0, arg_4_1)
		end
	end)
end

function var_0_0.getStudyroomInfo(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_STUDYROOM_INFO, var_5_0, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			arg_5_0.roomInfo = arg_6_1

			arg_5_0:handleInfos(arg_6_1)
		end

		if arg_5_2 then
			arg_5_2(arg_6_0, arg_6_1)
		end
	end)
end

function var_0_0.getCourseInfo(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_COURSE_INFO, var_7_0, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK then
			arg_7_0:handleInfos(arg_8_1, var_7_0)
		end

		if arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.study(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_1 or {}

	xyd.Backend.get():request(xyd.mid.STUDY, var_9_0, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			arg_9_0:handleInfos(arg_10_1, var_9_0)
		end

		if arg_9_2 then
			arg_9_2(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.continueStudy(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_1 or {}

	xyd.Backend.get():request(xyd.mid.CONTINUE_STUDY, var_11_0, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			arg_11_0:handleInfos(arg_12_1, var_11_0)
		end

		if arg_11_2 then
			arg_11_2(arg_12_0, arg_12_1)
		end
	end)
end

function var_0_0.speedStudy(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = arg_13_1 or {}

	xyd.Backend.get():request(xyd.mid.SPEED_STUDY, var_13_0, function(arg_14_0, arg_14_1)
		if arg_14_0 == xyd.error.OK then
			arg_13_0:handleInfos(arg_14_1, var_13_0)
		end

		if arg_13_2 then
			arg_13_2(arg_14_0, arg_14_1)
		end
	end)
end

function var_0_0.handleInfos(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = arg_15_2 or {}
	local var_15_1 = var_15_0.partner_id
	local var_15_2 = var_15_0.course_id

	if arg_15_1.study_infos then
		arg_15_0.roomInfo.study_infos = arg_15_1.study_infos

		table.sort(arg_15_0.roomInfo.study_infos, function(arg_16_0, arg_16_1)
			return arg_16_0.enter_time < arg_16_1.enter_time
		end)
	end

	if arg_15_1.partner_courses then
		arg_15_0.selfPlayer:getHero(var_15_1):setCoursesInfo(arg_15_1.partner_courses)
	end

	if arg_15_1.course_info then
		arg_15_0.selfPlayer:getHero(var_15_1):setCourseInfo(arg_15_1.course_info, var_15_2)
	end

	if arg_15_1.is_has_gift then
		arg_15_0.isHasGift = arg_15_1.is_has_gift
	end

	if arg_15_1.gift_box_info and arg_15_1.gift_box_info.is_has_gift then
		arg_15_0.isHasGift = arg_15_1.gift_box_info.is_has_gift
	end

	if arg_15_1.study_infos or arg_15_1.study_info or arg_15_1.is_has_gift or arg_15_1.gift_box_info then
		arg_15_0:refreshCourseWindow()
	end
end

function var_0_0.addSkill(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = arg_17_1 or {}

	xyd.Backend.get():request(xyd.mid.ADD_SKILL, var_17_0, function(arg_18_0, arg_18_1)
		if arg_18_0 == xyd.error.OK then
			arg_17_0:handleInfos(arg_18_1, var_17_0)
		end

		if arg_17_2 then
			arg_17_2(arg_18_0, arg_18_1)
		end
	end)
end

function var_0_0.forgetCourse(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = arg_19_1 or {}

	xyd.Backend.get():request(xyd.mid.FORGET_COURSE, var_19_0, function(arg_20_0, arg_20_1)
		if arg_20_0 == xyd.error.OK then
			arg_19_0:handleInfos(arg_20_1, var_19_0)
		end

		if arg_19_2 then
			arg_19_2(arg_20_0, arg_20_1)
		end
	end)
end

function var_0_0.enterRoom(arg_21_0, arg_21_1, arg_21_2)
	local var_21_0 = arg_21_1 or {}

	xyd.Backend.get():request(xyd.mid.ENTER_ROOM, var_21_0, function(arg_22_0, arg_22_1)
		if arg_22_0 == xyd.error.OK then
			arg_21_0:handleInfos(arg_22_1, var_21_0)
		end

		if arg_21_2 then
			arg_21_2(arg_22_0, arg_22_1)
		end
	end)
end

function var_0_0.leaveRoom(arg_23_0, arg_23_1, arg_23_2)
	local var_23_0 = arg_23_1 or {}

	xyd.Backend.get():request(xyd.mid.LEAVE_ROOM, var_23_0, function(arg_24_0, arg_24_1)
		if arg_24_0 == xyd.error.OK then
			arg_23_0:handleInfos(arg_24_1, var_23_0)
		end

		if arg_23_2 then
			arg_23_2(arg_24_0, arg_24_1)
		end
	end)
end

function var_0_0.cancelStudy(arg_25_0, arg_25_1, arg_25_2)
	local var_25_0 = arg_25_1 or {}

	xyd.Backend.get():request(xyd.mid.CANCEL_STUDY, var_25_0, function(arg_26_0, arg_26_1)
		if arg_26_0 == xyd.error.OK then
			arg_25_0:handleInfos(arg_26_1, var_25_0)
		end

		if arg_25_2 then
			arg_25_2(arg_26_0, arg_26_1)
		end
	end)
end

function var_0_0.getGiftBoxInfo(arg_27_0, arg_27_1, arg_27_2)
	local var_27_0 = arg_27_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_GIFT_BOX_INFO, var_27_0, function(arg_28_0, arg_28_1)
		if arg_28_0 == xyd.error.OK then
			arg_27_0:handleInfos(arg_28_1)
		end

		if arg_27_2 then
			arg_27_2(arg_28_0, arg_28_1)
		end
	end)
end

function var_0_0.incrCoureseExp(arg_29_0, arg_29_1, arg_29_2)
	local var_29_0 = arg_29_1 or {}

	xyd.Backend.get():request(xyd.mid.INCR_COURESE_EXP, var_29_0, function(arg_30_0, arg_30_1)
		if arg_30_0 == xyd.error.OK then
			arg_29_0:handleInfos(arg_30_1, var_29_0)
		end

		if arg_29_2 then
			arg_29_2(arg_30_0, arg_30_1)
		end
	end)
end

function var_0_0.openGiftBox(arg_31_0, arg_31_1, arg_31_2)
	local var_31_0 = arg_31_1 or {}

	xyd.Backend.get():request(xyd.mid.OPEN_GIFT_BOX, var_31_0, function(arg_32_0, arg_32_1)
		if arg_32_0 == xyd.error.OK then
			arg_31_0:handleInfos(arg_32_1)
		end

		if arg_31_2 then
			arg_31_2(arg_32_0, arg_32_1)
		end
	end)
end

function var_0_0.getCoursesRecommend(arg_33_0, arg_33_1, arg_33_2)
	local var_33_0 = arg_33_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_COURSES_RECOMMEND, var_33_0, function(arg_34_0, arg_34_1)
		if arg_34_0 == xyd.error.OK then
			-- block empty
		end

		if arg_33_2 then
			arg_33_2(arg_34_0, arg_34_1)
		end
	end)
end

function var_0_0.setStudyInfos(arg_35_0, arg_35_1)
	if arg_35_1 and arg_35_1.study_infos then
		arg_35_0.roomInfo.study_infos = arg_35_1.study_infos
	end
end

function var_0_0.isPatnerInRoom(arg_36_0, arg_36_1)
	for iter_36_0, iter_36_1 in pairs(arg_36_0.roomInfo.study_infos or {}) do
		if iter_36_1.partner_id == arg_36_1 then
			return true
		end
	end

	return false
end

function var_0_0.isCourseRedPointShow(arg_37_0)
	if not arg_37_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_COURSE) then
		return false
	end

	if arg_37_0:isBookStoreRedPointShow() then
		return true
	end
end

function var_0_0.isBookStoreRedPointShow(arg_38_0)
	if arg_38_0.isHasGift and arg_38_0.isHasGift == 1 then
		return true
	else
		return false
	end
end

function var_0_0.getBooks(arg_39_0)
	local var_39_0 = arg_39_0.selfPlayer:getBackpack()
	local var_39_1 = xyd.tables.misc.objectBoxBooks
	local var_39_2 = {}

	for iter_39_0 = 1, #var_39_1 do
		local var_39_3 = var_39_0:getItemByID(var_39_1[iter_39_0])

		if var_39_3 then
			table.insert(var_39_2, var_39_3)
		end
	end

	return var_39_2
end

function var_0_0.refreshCourseWindow(arg_40_0)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.CHECK_MIDDLE_RED_MARK,
		params = xyd.CheckMiddleRed.COURSE
	})
end

function var_0_0.sortHeros(arg_41_0, arg_41_1)
	local var_41_0 = {}

	for iter_41_0, iter_41_1 in ipairs(arg_41_0.roomInfo.study_infos) do
		var_41_0[iter_41_1.partner_id] = true
	end

	local var_41_1 = {}
	local var_41_2 = {}

	for iter_41_2, iter_41_3 in ipairs(arg_41_1) do
		for iter_41_4, iter_41_5 in pairs(iter_41_3:getCoursesInfo()) do
			if iter_41_5.progress > 0 and iter_41_5.progress < 100 then
				var_41_2[iter_41_3:getHeroID()] = true
			elseif iter_41_5.add_skill == 0 then
				var_41_1[iter_41_3:getHeroID()] = true
			end
		end
	end

	table.sort(arg_41_1, function(arg_42_0, arg_42_1)
		if var_41_2[arg_42_0:getHeroID()] and not var_41_2[arg_42_1:getHeroID()] then
			return true
		elseif not var_41_2[arg_42_0:getHeroID()] and var_41_2[arg_42_1:getHeroID()] then
			return false
		elseif var_41_1[arg_42_0:getHeroID()] and not var_41_1[arg_42_1:getHeroID()] then
			return true
		elseif not var_41_1[arg_42_0:getHeroID()] and var_41_1[arg_42_1:getHeroID()] then
			return false
		elseif var_41_0[arg_42_0:getHeroID()] and not var_41_0[arg_42_1:getHeroID()] then
			return true
		elseif not var_41_0[arg_42_0:getHeroID()] and var_41_0[arg_42_1:getHeroID()] then
			return false
		elseif #table.keys(arg_42_0:getCoursesInfo()) ~= #table.keys(arg_42_1:getCoursesInfo()) then
			return #table.keys(arg_42_0:getCoursesInfo()) > #table.keys(arg_42_1:getCoursesInfo())
		end

		return xyd.heroNormalSort(arg_42_0, arg_42_1) or false
	end)

	return arg_41_1
end

function var_0_0.enterCourseWindow(arg_43_0, arg_43_1, arg_43_2)
	local var_43_0

	if arg_43_1 then
		var_43_0 = arg_43_1
	else
		local var_43_1 = arg_43_0:sortHeros(clone(arg_43_0.selfPlayer.heros_))

		var_43_0 = arg_43_0.selfPlayer:getHero(var_43_1[1]:getHeroID())
	end

	local var_43_2 = {
		partner_id = var_43_0:getHeroID()
	}

	arg_43_0:getCourseInfo(var_43_2, function(arg_44_0, arg_44_1)
		if arg_44_0 == xyd.error.OK then
			local var_44_0 = {
				hero = var_43_0,
				partner_courses = arg_44_1.partner_courses,
				callback = arg_43_2,
				study_infos = arg_44_1.study_infos or {}
			}

			xyd.WindowManager.get():openWindow("course", var_44_0)
		end
	end)
end

return var_0_0
