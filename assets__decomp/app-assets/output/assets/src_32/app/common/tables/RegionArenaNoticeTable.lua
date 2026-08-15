local var_0_0 = class("RegionArenaNoticeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.noticeItem = {}
	arg_1_0.noticeDesc = {}
	arg_1_0.order = {}

	import("app.common.tables.TableParser").parse("region_arena_notice.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.noticeItem[var_2_0] = tonumber(arg_2_0.notice_item)
		arg_1_0.noticeDesc[var_2_0] = arg_2_0.notice_desc
		arg_1_0.order[var_2_0] = tonumber(arg_2_0.order)
	end)
end

function var_0_0.getNoticeItem(arg_3_0, arg_3_1)
	return arg_3_0.noticeItem[arg_3_1] or 0
end

function var_0_0.getNoticeDesc(arg_4_0, arg_4_1)
	return arg_4_0.noticeDesc[arg_4_1] or 0
end

function var_0_0.getNoticeItemByOrder(arg_5_0, arg_5_1)
	for iter_5_0, iter_5_1 in pairs(arg_5_0.order) do
		if iter_5_1 == arg_5_1 then
			return arg_5_0.noticeItem[iter_5_0]
		end
	end

	return nil
end

function var_0_0.getNoticeDescByOrder(arg_6_0, arg_6_1)
	for iter_6_0, iter_6_1 in pairs(arg_6_0.order) do
		if iter_6_1 == arg_6_1 then
			return arg_6_0.noticeDesc[iter_6_0]
		end
	end

	return nil
end

return var_0_0
