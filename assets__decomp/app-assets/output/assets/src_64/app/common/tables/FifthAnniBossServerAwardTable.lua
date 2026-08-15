local var_0_0 = class("FifthAnniBossServerAwardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.req_ = {}
	arg_1_0.giftId_ = {}

	import("app.common.tables.TableParser").parse("fifth_anni_boss_server_award.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.req_[var_2_0] = tonumber(arg_2_0.req)
		arg_1_0.giftId_[var_2_0] = tonumber(arg_2_0.gift_id)
	end)
end

function var_0_0.req(arg_3_0, arg_3_1)
	return arg_3_0.req_[arg_3_1] or 0
end

function var_0_0.giftId(arg_4_0, arg_4_1)
	return arg_4_0.giftId_[arg_4_1] or 0
end

function var_0_0.getIds(arg_5_0)
	return arg_5_0.ids_ or {}
end

return var_0_0
