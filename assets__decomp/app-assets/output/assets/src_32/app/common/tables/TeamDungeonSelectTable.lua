local var_0_0 = class("TeamDungeonSelectTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.headPortrait_ = {}
	arg_1_0.chapterName_ = {}
	arg_1_0.itemDisplay_ = {}
	arg_1_0.dungeonOpen_ = {}
	arg_1_0.coinReward_ = {}
	arg_1_0.additionReward_ = {}
	arg_1_0.plotNum_ = {}
	arg_1_0.ids_ = {}

	import("app.common.tables.TableParser").parse("team_dungeon_select.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.headPortrait_[var_2_0] = tonumber(arg_2_0.head_portrait)
		arg_1_0.chapterName_[var_2_0] = arg_2_0.chapter_name
		arg_1_0.itemDisplay_[var_2_0] = xyd.splitToNumber(arg_2_0.item_display, "|")
		arg_1_0.dungeonOpen_[var_2_0] = tonumber(arg_2_0.dungeon_open)
		arg_1_0.coinReward_[var_2_0] = tonumber(arg_2_0.coin_reward)
		arg_1_0.additionReward_[var_2_0] = tonumber(arg_2_0.addition_reward)
		arg_1_0.plotNum_[var_2_0] = tonumber(arg_2_0.plot_num)
	end)
end

function var_0_0.headPortrait(arg_3_0, arg_3_1)
	return arg_3_0.headPortrait_[arg_3_1] or 0
end

function var_0_0.chapterName(arg_4_0, arg_4_1)
	return arg_4_0.chapterName_[arg_4_1] or ""
end

function var_0_0.itemDisplay(arg_5_0, arg_5_1)
	return arg_5_0.itemDisplay_[arg_5_1] or {}
end

function var_0_0.dungeonOpen(arg_6_0, arg_6_1)
	return arg_6_0.dungeonOpen_[arg_6_1] or 0
end

function var_0_0.coinReward(arg_7_0, arg_7_1)
	return arg_7_0.coinReward_[arg_7_1] or 0
end

function var_0_0.additionReward(arg_8_0, arg_8_1)
	return arg_8_0.additionReward_[arg_8_1] or 0
end

function var_0_0.plotNum(arg_9_0, arg_9_1)
	return arg_9_0.plotNum_[arg_9_1] or 0
end

function var_0_0.getLastChapter(arg_10_0)
	return arg_10_0.ids_[#arg_10_0.ids_] or 0
end

return var_0_0
