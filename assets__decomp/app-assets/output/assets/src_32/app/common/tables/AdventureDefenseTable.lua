local var_0_0 = class("AdventureDefenseTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.battleId_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.models_ = {}

	import("app.common.tables.TableParser").parse("adventure_campaign.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.battleId_[var_2_0] = xyd.splitToNumber(arg_2_0.battle_ids, "|")
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.models_[var_2_0] = xyd.luaStringSplit(arg_2_0.models, "|")
	end)
end

function var_0_0.battleId(arg_3_0, arg_3_1)
	return arg_3_0.battleId_[arg_3_1] or {}
end

function var_0_0.gift(arg_4_0, arg_4_1)
	return arg_4_0.gift_[arg_4_1] or 0
end

function var_0_0.models(arg_5_0, arg_5_1)
	return arg_5_0.models_[arg_5_1] or {}
end

return var_0_0
