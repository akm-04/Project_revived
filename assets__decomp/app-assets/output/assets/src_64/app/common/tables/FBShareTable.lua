local var_0_0 = class("FBShareTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.type_ = {}
	arg_1_0.title_ = {}
	arg_1_0.content_ = {}
	arg_1_0.link_ = {}
	arg_1_0.imgLink_ = {}

	import("app.common.tables.TableParser").parse("fb_share.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.type_[var_2_0] = arg_2_0.type
		arg_1_0.title_[var_2_0] = arg_2_0.title
		arg_1_0.content_[var_2_0] = arg_2_0.content
		arg_1_0.link_[var_2_0] = arg_2_0.link
		arg_1_0.imgLink_[var_2_0] = arg_2_0.img_link
	end)
end

function var_0_0.type(arg_3_0, arg_3_1)
	return arg_3_0.type_[arg_3_1] or ""
end

function var_0_0.title(arg_4_0, arg_4_1)
	return arg_4_0.title_[arg_4_1] or ""
end

function var_0_0.content(arg_5_0, arg_5_1)
	return arg_5_0.content_[arg_5_1] or ""
end

function var_0_0.link(arg_6_0, arg_6_1)
	return arg_6_0.link_[arg_6_1] or ""
end

function var_0_0.imgLink(arg_7_0, arg_7_1)
	return arg_7_0.imgLink_[arg_7_1] or ""
end

return var_0_0
