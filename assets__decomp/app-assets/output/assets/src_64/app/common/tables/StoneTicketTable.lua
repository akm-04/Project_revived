local var_0_0 = class("StoneTicketTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.stoneTicketItems_ = {}

	import("app.common.tables.TableParser").parse("stone_ticket.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.stoneTicketItems_[var_2_0] = xyd.splitToNumber(arg_2_0.stone_ticket_items, "|")
	end)
end

function var_0_0.stoneTicketItems(arg_3_0, arg_3_1)
	return arg_3_0.stoneTicketItems_[arg_3_1] or {}
end

return var_0_0
