local var_0_0 = class("ActivityAnniJigsaw2RewardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.id_ = {}
	arg_1_0.pieceIds_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.gift_ = {}

	import("app.common.tables.TableParser").parse("activity_anni_jigsaw2_reward.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.pieceIds_[var_2_0] = xyd.splitToNumber(arg_2_0.piece_id, "|")
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift_id)
	end)
end

function var_0_0.pieceIds(arg_3_0, arg_3_1)
	return arg_3_0.pieceIds_[arg_3_1] or {}
end

function var_0_0.desc(arg_4_0, arg_4_1)
	return arg_4_0.desc_[arg_4_1] or ""
end

function var_0_0.gift(arg_5_0, arg_5_1)
	return arg_5_0.gift_[arg_5_1]
end

function var_0_0.counts(arg_6_0)
	return #arg_6_0.desc_
end

return var_0_0
