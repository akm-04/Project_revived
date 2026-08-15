local var_0_0 = class("GuildBattleGiftTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.gift_item_ = {}
	arg_1_0.gift_num_ = {}

	import("app.common.tables.TableParser").parse("guild_battle_gift.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.gift_item_[var_2_0] = xyd.splitToNumber(arg_2_0.gift_item, "|")
		arg_1_0.gift_num_[var_2_0] = xyd.splitToNumber(arg_2_0.gift_num, "|")
	end)
end

function var_0_0.giftItem(arg_3_0, arg_3_1)
	return arg_3_0.gift_item_[arg_3_1] or {}
end

function var_0_0.giftNum(arg_4_0, arg_4_1)
	return arg_4_0.gift_num_[arg_4_1] or {}
end

return var_0_0
