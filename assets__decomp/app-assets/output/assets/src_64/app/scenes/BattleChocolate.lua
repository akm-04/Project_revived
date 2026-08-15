local var_0_0 = class("BattleChocolate", import("app.scenes.BattleCreate"))
local var_0_1 = xyd.tables.misc:getValue("activity_chocolate_campaign_special_monster")

function var_0_0.init(arg_1_0)
	var_0_0.super.init(arg_1_0)

	if arg_1_0.group_ == 3 then
		arg_1_0.showStory = true
	end
end

function var_0_0.mainLoop(arg_2_0)
	var_0_0.super.mainLoop(arg_2_0)

	if arg_2_0.showStory then
		arg_2_0:playChocolateStory()
	end
end

function var_0_0.checkEnds(arg_3_0)
	if arg_3_0.group_ == 3 then
		for iter_3_0, iter_3_1 in ipairs(ngx.ctx.battle.teamB) do
			if iter_3_1:isDeath() then
				return true
			end
		end
	end

	return var_0_0.super.checkEnds(arg_3_0)
end

function var_0_0.getBattleStar(arg_4_0)
	if arg_4_0.group_ == 3 then
		for iter_4_0, iter_4_1 in ipairs(ngx.ctx.battle.teamB) do
			if iter_4_1:isDeath() and iter_4_1:getTableID() == var_0_1 then
				return var_0_0.super.getBattleStar(arg_4_0)
			end
		end
	end

	return 0
end

function var_0_0.playChocolateStory(arg_5_0)
	arg_5_0:pauseBattle()

	local var_5_0 = xyd.tables.misc:getValue("activity_chocolate_campaign_special_story")
	local var_5_1 = xyd.WindowManager.get():openWindow("story", {
		story_state = 1,
		is_chocolate_story = true,
		story_id = var_5_0,
		campaign_id = arg_5_0.campaignID,
		campaign_type = arg_5_0.campaignType
	})

	cc.EventProxy.new(var_5_1, var_5_1):addEventListener(xyd.event.STORY_COMPLETE, function(arg_6_0)
		if arg_6_0.state == 1 then
			arg_5_0.showStory = false

			arg_5_0:startBattle()
		end
	end)
end

return var_0_0
