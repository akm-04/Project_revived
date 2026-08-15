local var_0_0 = class("LibraryTalkTable")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.chapterName_ = {}
	arg_1_0.talkName_ = {}
	arg_1_0.unlock_ = {}
	arg_1_0.unlockHero_ = {}
	arg_1_0.unlockParam_ = {}
	arg_1_0.item_ = {}
	arg_1_0.itemNum_ = {}
	arg_1_0.gold_ = {}
	arg_1_0.diamond_ = {}
	arg_1_0.idPrefixToIdList_ = {}
	arg_1_0.totalNum = 0

	import("app.common.tables.TableParser").parse("library_talk", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.talk_id)

		arg_1_0.chapterName_[var_2_0] = arg_2_0.chapter_name
		arg_1_0.talkName_[var_2_0] = arg_2_0.talk_name
		arg_1_0.unlock_[var_2_0] = xyd.splitToNumber(arg_2_0.unlock, "|")
		arg_1_0.unlockHero_[var_2_0] = xyd.splitToNumber(arg_2_0.unlock_hero, "|")
		arg_1_0.unlockParam_[var_2_0] = xyd.splitToNumber(arg_2_0.unlock_param, "|")
		arg_1_0.item_[var_2_0] = tonumber(arg_2_0.item)
		arg_1_0.itemNum_[var_2_0] = tonumber(arg_2_0.item_num)
		arg_1_0.gold_[var_2_0] = tonumber(arg_2_0.gold)
		arg_1_0.diamond_[var_2_0] = tonumber(arg_2_0.diamond)

		local var_2_1 = math.floor(var_2_0 / 1000)

		if not arg_1_0.idPrefixToIdList_[var_2_1] then
			arg_1_0.idPrefixToIdList_[var_2_1] = {}
			arg_1_0.totalNum = arg_1_0.totalNum + 1
		end

		table.insert(arg_1_0.idPrefixToIdList_[var_2_1], var_2_0)
	end)
end

function var_0_0.getChapterName(arg_3_0, arg_3_1)
	return arg_3_0.chapterName_[arg_3_1]
end

function var_0_0.getTalkName(arg_4_0, arg_4_1)
	return arg_4_0.talkName_[arg_4_1]
end

function var_0_0.getUnlockConditionTypes(arg_5_0, arg_5_1)
	return arg_5_0.unlock_[arg_5_1] or {}
end

function var_0_0.getUnlockHero(arg_6_0, arg_6_1)
	return arg_6_0.unlockHero_[arg_6_1] or {}
end

function var_0_0.getUnlockParam(arg_7_0, arg_7_1)
	return arg_7_0.unlockParam_[arg_7_1] or {}
end

function var_0_0.item(arg_8_0, arg_8_1)
	return arg_8_0.item_[arg_8_1] or 0
end

function var_0_0.itemNum(arg_9_0, arg_9_1)
	return arg_9_0.itemNum_[arg_9_1] or 0
end

function var_0_0.gold(arg_10_0, arg_10_1)
	return arg_10_0.gold_[arg_10_1] or 0
end

function var_0_0.diamond(arg_11_0, arg_11_1)
	return arg_11_0.diamond_[arg_11_1] or 0
end

function var_0_0.getTalkIdsByIdPrefix(arg_12_0, arg_12_1)
	return arg_12_0.idPrefixToIdList_[arg_12_1] or {}
end

function var_0_0.getChapterNameByIdPrefix(arg_13_0, arg_13_1)
	return arg_13_0:getChapterName(arg_13_0.idPrefixToIdList_[arg_13_1][1])
end

function var_0_0.getStoryTotalNum(arg_14_0)
	return arg_14_0.totalNum
end

return var_0_0
