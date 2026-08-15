local var_0_0 = class("FifthAnniPartyAwardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.sendPoint_ = {}
	arg_1_0.receivePoint_ = {}
	arg_1_0.giftId_ = {}

	import("app.common.tables.TableParser").parse("fifth_anni_party_award.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.sendPoint_[var_2_0] = tonumber(arg_2_0.send_point)
		arg_1_0.receivePoint_[var_2_0] = tonumber(arg_2_0.receive_point)
		arg_1_0.giftId_[var_2_0] = tonumber(arg_2_0.gift_id)
	end)
end

function var_0_0.all(arg_3_0)
	return #arg_3_0.giftId_
end

function var_0_0.sendPoint(arg_4_0, arg_4_1)
	return arg_4_0.sendPoint_[arg_4_1] or 0
end

function var_0_0.receivePoint(arg_5_0, arg_5_1)
	return arg_5_0.receivePoint_[arg_5_1] or 0
end

function var_0_0.giftId(arg_6_0, arg_6_1)
	return arg_6_0.giftId_[arg_6_1] or 0
end

return var_0_0
