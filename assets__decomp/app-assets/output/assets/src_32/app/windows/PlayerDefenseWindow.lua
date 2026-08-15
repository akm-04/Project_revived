local var_0_0 = class("PlayerDefenseWindow", import("app.common.ui.BaseWindow"))

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.otherPlayerID = arg_1_2.player_id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:loadInfo()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.title_ = arg_3_0:nodeByName("title_label"):setString(xyd.tables.translation:translation("PLACE_DEFFENCE"))
	arg_3_0.leaderSkill_ = arg_3_0:nodeByName("leader_skill_label")

	arg_3_0.leaderSkill_:setString("")
end

function var_0_0.addAnimationToPos(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = xyd.HeroAnimation.new(arg_4_1, 0.5)

	var_4_0:setPositionX(var_4_0:getContentSize().width / 2)

	if var_4_0 then
		var_4_0:idle()

		local var_4_1 = arg_4_0:nodeByName("shadow_" .. tostring(arg_4_2 - 1))

		var_4_1:addChild(var_4_0)
		var_4_0:setPosition(var_4_1:getContentSize().width / 2, var_4_1:getContentSize().height / 3)
	end
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super.didOpen(arg_5_0, arg_5_1)
end

function var_0_0.updateLeaderLabel(arg_6_0, arg_6_1)
	local var_6_0 = xyd.tables.hero:leadSkill(arg_6_1)

	if var_6_0 then
		arg_6_0.leaderSkill_:setString(string.format(xyd.tables.translation:translation("DEFFENSE_LEADER_SKILL"), xyd.tables.skill:desc(var_6_0)))
	else
		arg_6_0.leaderSkill_:setString(string.format(xyd.tables.translation:translation("DEFFENSE_LEADER_SKILL"), xyd.tables.translation:translation("NO_BUFF")))
	end
end

function var_0_0.loadInfo(arg_7_0)
	arg_7_0.player_:loadBattleFormation(xyd.FormationType.DEFENSE, 4, function(arg_8_0)
		if arg_8_0 == xyd.error.OK then
			for iter_8_0 = 1, 4 do
				local var_8_0 = arg_7_0.player_.battleFormation_[xyd.FormationType.DEFENSE][arg_7_0.otherPlayerID][iter_8_0]

				if var_8_0.table_id ~= nil and var_8_0.star then
					local var_8_1 = xyd.tables.hero:modelID(var_8_0.table_id, var_8_0.star)

					if var_8_1 then
						arg_7_0:addAnimationToPos(var_8_1, iter_8_0)
					end

					if iter_8_0 == 1 then
						arg_7_0:updateLeaderLabel(var_8_0.table_id)
					end
				end
			end
		end
	end, arg_7_0.otherPlayerID)
end

return var_0_0
