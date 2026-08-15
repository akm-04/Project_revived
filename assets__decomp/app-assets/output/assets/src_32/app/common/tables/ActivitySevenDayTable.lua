local var_0_0 = class("ActivitySevenDayTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.date_ = {}
	arg_1_0.awardGiftId_ = {}
	arg_1_0.mainitemPic_ = {}
	arg_1_0.mainitempicLabel_ = {}
	arg_1_0.adcopywritting1_ = {}
	arg_1_0.adcopywritting2_ = {}
	arg_1_0.adcopywritting3_ = {}
	arg_1_0.url_ = {}

	import("app.common.tables.TableParser").parse("activity_seven_day.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.date_[var_2_0] = arg_2_0.date
		arg_1_0.awardGiftId_[var_2_0] = tonumber(arg_2_0.award_gift_id)
		arg_1_0.mainitemPic_[var_2_0] = arg_2_0.mainitem_pic
		arg_1_0.mainitempicLabel_[var_2_0] = arg_2_0.mainitempic_label
		arg_1_0.adcopywritting1_[var_2_0] = arg_2_0.adcopywritting1
		arg_1_0.adcopywritting2_[var_2_0] = arg_2_0.adcopywritting2
		arg_1_0.adcopywritting3_[var_2_0] = arg_2_0.adcopywritting3
		arg_1_0.url_[var_2_0] = arg_2_0.url
	end)
end

function var_0_0.date(arg_3_0, arg_3_1)
	return arg_3_0.date_[arg_3_1] or ""
end

function var_0_0.awardGiftId(arg_4_0, arg_4_1)
	return arg_4_0.awardGiftId_[arg_4_1] or 0
end

function var_0_0.mainitemPic(arg_5_0, arg_5_1)
	return arg_5_0.mainitemPic_[arg_5_1] or ""
end

function var_0_0.mainitempicLabel(arg_6_0, arg_6_1)
	return arg_6_0.mainitempicLabel_[arg_6_1] or ""
end

function var_0_0.adcopywritting1(arg_7_0, arg_7_1)
	return arg_7_0.adcopywritting1_[arg_7_1] or ""
end

function var_0_0.adcopywritting2(arg_8_0, arg_8_1)
	return arg_8_0.adcopywritting2_[arg_8_1] or ""
end

function var_0_0.adcopywritting3(arg_9_0, arg_9_1)
	return arg_9_0.adcopywritting3_[arg_9_1] or ""
end

function var_0_0.url(arg_10_0, arg_10_1)
	return arg_10_0.url_[arg_10_1] or ""
end

return var_0_0
