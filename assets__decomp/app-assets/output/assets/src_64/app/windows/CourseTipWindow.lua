local var_0_0 = class("CourseTipWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.bookId = arg_1_2.book_id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("course_name_txt"):setString(xyd.tables.objectBook:name(arg_3_0.bookId))
	arg_3_0:nodeByName("course_desc_txt"):setString(xyd.tables.objectBook:des(arg_3_0.bookId))

	local var_3_0 = xyd.tables.objectBook:icon(arg_3_0.bookId)

	xyd.setSpriteBorder(arg_3_0:nodeByName("icon_container"), var_3_0, 1)
end

return var_0_0
