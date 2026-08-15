local var_0_0 = class("JunkChestFinishBookWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.cabinetBookTable
local var_0_4 = xyd.tables.cabinetSkillTable

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.skillId = arg_1_0.eventCentre.recentCompleteSkill
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = var_0_4:skillbook(arg_4_0.skillId)

	xyd.setItemBorder(arg_4_0:nodeByName("icon"), var_4_0)
	arg_4_0:nodeByName("name_text"):setString(var_0_3:name(var_4_0))
	arg_4_0:nodeByName("des_text"):setString(string.format(var_0_2:translation("GET_KNOWLEDGE_EXP"), xyd.tables.misc.eventCentreBookExp[var_0_3:star(var_4_0)]))
end

return var_0_0
