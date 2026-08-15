local var_0_0 = class("ActivityCvWarmupTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.keyWords_ = {}
	arg_1_0.cvPicBig_ = {}
	arg_1_0.girls_ = {}
	arg_1_0.girlsVoice_ = {}
	arg_1_0.voicesTime_ = {}

	import("app.common.tables.TableParser").parse("activity_cv_warmup.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.keyWords_[var_2_0] = xyd.split(arg_2_0.key_words, "|")
		arg_1_0.cvPicBig_[var_2_0] = arg_2_0.cv_pic_big
		arg_1_0.girls_[var_2_0] = xyd.splitToNumber(arg_2_0.girls, "|")
		arg_1_0.girlsVoice_[var_2_0] = xyd.split(arg_2_0.girls_voice, "|")
		arg_1_0.voicesTime_[var_2_0] = xyd.splitToNumber(arg_2_0.voices_time, "|")
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.keyWords(arg_4_0, arg_4_1)
	return arg_4_0.keyWords_[arg_4_1] or {}
end

function var_0_0.cvPicBig(arg_5_0, arg_5_1)
	return arg_5_0.cvPicBig_[arg_5_1] or ""
end

function var_0_0.girls(arg_6_0, arg_6_1)
	return arg_6_0.girls_[arg_6_1] or {}
end

function var_0_0.girlsVoice(arg_7_0, arg_7_1)
	return arg_7_0.girlsVoice_[arg_7_1] or {}
end

function var_0_0.voicesTime(arg_8_0, arg_8_1)
	return arg_8_0.voicesTime_[arg_8_1] or {}
end

return var_0_0
