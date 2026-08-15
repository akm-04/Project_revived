local var_0_0 = class("CourseApplySucceedWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.course = xyd.ModelManager.get():loadModel(xyd.ModelType.COURSE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.hero = arg_1_2.hero
	arg_1_0.courseId = arg_1_2.course_id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("course_name_txt"):setString(xyd.tables.objectBook:name(arg_3_0.courseId))
	arg_3_0:nodeByName("apply_succeed_text"):setString(string.format(var_0_1:translation("APPLY_COURSE_SUCCEED_TEXT"), arg_3_0.hero:getName()))
	arg_3_0:setButtonClick()
end

function var_0_0.setButtonClick(arg_4_0)
	arg_4_0:nodeByName("to_self_study_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_5_0 = {}

			arg_4_0.course:getStudyroomInfo(var_5_0, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("course_studyroom")
					xyd.WindowManager.get():closeWindow(arg_4_0)
				end
			end)
		end
	end)
end

return var_0_0
