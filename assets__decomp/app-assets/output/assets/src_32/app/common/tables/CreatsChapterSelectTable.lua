local var_0_0 = class("CreatsChapterSelectTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.chapterModel_ = {}
	arg_1_0.tableID_ = {}
	arg_1_0.chapterName_ = {}
	arg_1_0.chapterDes_ = {}
	arg_1_0.chapterBuff_ = {}
	arg_1_0.mana_ = {}
	arg_1_0.item_ = {}
	arg_1_0.itemNum_ = {}
	arg_1_0.chapterMap_ = {}
	arg_1_0.chapterLine_ = {}
	arg_1_0.campaignMap_ = {}
	arg_1_0.cooperateMap_ = {}
	arg_1_0.itemDisplay_ = {}
	arg_1_0.awakenMissionId_ = {}
	arg_1_0.awakenItem_ = {}
	arg_1_0.awakenNum_ = {}

	import("app.common.tables.TableParser").parse("creats_chapter_select.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.chapter_id)

		arg_1_0.chapterModel_[var_2_0] = tonumber(arg_2_0.chapter_model)
		arg_1_0.tableID_[var_2_0] = tonumber(arg_2_0.table_id)
		arg_1_0.chapterName_[var_2_0] = arg_2_0.chapter_name
		arg_1_0.chapterDes_[var_2_0] = arg_2_0.chapter_des
		arg_1_0.chapterBuff_[var_2_0] = xyd.splitToNumber(arg_2_0.chapter_buff, "|")
		arg_1_0.mana_[var_2_0] = tonumber(arg_2_0.mana)
		arg_1_0.item_[var_2_0] = xyd.splitToNumber(arg_2_0.item, "|")
		arg_1_0.itemNum_[var_2_0] = xyd.splitToNumber(arg_2_0.item_num, "|")
		arg_1_0.chapterMap_[var_2_0] = arg_2_0.chapter_map
		arg_1_0.chapterLine_[var_2_0] = arg_2_0.chapter_line
		arg_1_0.campaignMap_[var_2_0] = arg_2_0.campaign_map
		arg_1_0.cooperateMap_[var_2_0] = arg_2_0.cooperate_map
		arg_1_0.itemDisplay_[var_2_0] = xyd.splitToNumber(arg_2_0.item_display, "|")
		arg_1_0.awakenMissionId_[var_2_0] = xyd.splitToNumber(arg_2_0.awaken_mission_ids, "|")
		arg_1_0.awakenItem_[var_2_0] = xyd.splitToNumber(arg_2_0.awaken_items, "|")
		arg_1_0.awakenNum_[var_2_0] = xyd.splitToNumber(arg_2_0.awaken_nums, "|")
	end)
end

function var_0_0.chapterModel(arg_3_0, arg_3_1)
	return arg_3_0.chapterModel_[arg_3_1] or 0
end

function var_0_0.tableID(arg_4_0, arg_4_1)
	return arg_4_0.tableID_[arg_4_1] or 0
end

function var_0_0.chapterName(arg_5_0, arg_5_1)
	return arg_5_0.chapterName_[arg_5_1] or ""
end

function var_0_0.chapterDes(arg_6_0, arg_6_1)
	return arg_6_0.chapterDes_[arg_6_1] or 0
end

function var_0_0.chapterBuff(arg_7_0, arg_7_1)
	return arg_7_0.chapterBuff_[arg_7_1] or 0
end

function var_0_0.mana(arg_8_0, arg_8_1)
	return arg_8_0.mana_[arg_8_1] or 0
end

function var_0_0.item(arg_9_0, arg_9_1)
	return arg_9_0.item_[arg_9_1] or {}
end

function var_0_0.itemNum(arg_10_0, arg_10_1)
	return arg_10_0.itemNum_[arg_10_1] or {}
end

function var_0_0.chapterMap(arg_11_0, arg_11_1)
	return arg_11_0.chapterMap_[arg_11_1] or ""
end

function var_0_0.chapterLine(arg_12_0, arg_12_1)
	return arg_12_0.chapterLine_[arg_12_1] or ""
end

function var_0_0.campaignMap(arg_13_0, arg_13_1)
	return arg_13_0.campaignMap_[arg_13_1] or ""
end

function var_0_0.cooperateMap(arg_14_0, arg_14_1)
	return arg_14_0.cooperateMap_[arg_14_1] or ""
end

function var_0_0.itemDisplay(arg_15_0, arg_15_1)
	return arg_15_0.itemDisplay_[arg_15_1] or {}
end

function var_0_0.chapterCount(arg_16_0)
	return #arg_16_0.chapterModel_
end

function var_0_0.awakenMissionId(arg_17_0, arg_17_1)
	return arg_17_0.awakenMissionId_[arg_17_1] or {}
end

function var_0_0.awakenItem(arg_18_0, arg_18_1)
	return arg_18_0.awakenItem_[arg_18_1] or {}
end

function var_0_0.awakenNum(arg_19_0, arg_19_1)
	return arg_19_0.awakenNum_[arg_19_1] or {}
end

function var_0_0.getChapterByMissionId(arg_20_0, arg_20_1)
	for iter_20_0, iter_20_1 in pairs(arg_20_0.awakenMissionId_) do
		if xyd.isInTable(iter_20_1, arg_20_1) then
			return iter_20_0
		end
	end
end

return var_0_0
