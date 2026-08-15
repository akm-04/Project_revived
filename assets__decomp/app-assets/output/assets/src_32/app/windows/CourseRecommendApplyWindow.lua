local var_0_0 = class("CourseRecommendApplyWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.objectBook
local var_0_3 = xyd.tables.hero

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.course = xyd.ModelManager.get():loadModel(xyd.ModelType.COURSE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.hero = arg_1_2.hero
	arg_1_0.bookId = arg_1_2.book_id
	arg_1_0.info = arg_1_2.info
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("name_txt"):setString(var_0_2:name(arg_3_0.bookId))

	if arg_3_0.info.add_skill and arg_3_0.info.add_skill > 0 then
		local var_3_0 = var_0_3:getSkill(arg_3_0.hero:getTableID(), arg_3_0.info.add_skill)

		arg_3_0:nodeByName("skill_name_txt"):setString(xyd.tables.skill:name(var_3_0))
	else
		arg_3_0:nodeByName("skill_name_txt"):setVisible(false)
	end

	arg_3_0:nodeByName("add_skill_text"):setString(var_0_1:translation("COURSE_ADD_SKILL_TEXT"))

	local var_3_1 = var_0_2:icon(arg_3_0.bookId)

	xyd.setSpriteBorder(arg_3_0:nodeByName("icon_container"), var_3_1, arg_3_0.info.quality, false)

	local var_3_2 = var_0_2:des(arg_3_0.bookId, arg_3_0.info.quality)

	arg_3_0:nodeByName("txt_desc"):getVirtualRenderer():setLineHeight(26)
	arg_3_0:nodeByName("txt_desc"):setString(var_3_2)
end

return var_0_0
