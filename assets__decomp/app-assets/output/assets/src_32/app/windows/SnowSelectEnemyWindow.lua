local var_0_0 = class("SnowSelectEnemyWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.item
local var_0_4 = import("app.model.Hero")
local var_0_5 = import("app.model.ActivityHero")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.snowActivity = xyd.ModelManager.get():loadModel(xyd.ModelType.SNOW_ACTIVITY)
	arg_1_0.preHeros_ = arg_1_2.preHeros
	arg_1_0.preSelect_ = arg_1_2.selected
	arg_1_0.matchInfos = arg_1_2.match_infos
	arg_1_0.heroModels_ = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
	arg_2_0:updateList()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	var_0_1.performWithDelayGlobal(function()
		arg_3_0:updateHeroModels()
	end, 0.034)
end

function var_0_0.layout(arg_5_0)
	arg_5_0:setupButton()
end

function var_0_0.setupButton(arg_6_0)
	xyd.imgEvent(arg_6_0:nodeByName("img_refresh"), function()
		arg_6_0.snowActivity:matchEnemy(function(arg_8_0, arg_8_1)
			if arg_8_0 == xyd.error.OK then
				arg_6_0.matchInfos = arg_8_1.match_infos

				arg_6_0:updateList()
				arg_6_0:updateHeroModels()
			end
		end)
	end)
	xyd.imgEvent(arg_6_0:nodeByName("img_close"), function()
		xyd.WindowManager.get():closeWindow(arg_6_0)
	end)
end

function var_0_0.updateList(arg_10_0)
	local var_10_0 = 0

	arg_10_0:nodeByName("list"):removeAllChildren()

	arg_10_0.heroContainers_ = {}

	for iter_10_0 = 1, #arg_10_0.matchInfos do
		local var_10_1 = arg_10_0.matchInfos[iter_10_0]
		local var_10_2 = var_10_1.player_info
		local var_10_3 = var_10_1.rank_info
		local var_10_4 = var_10_1.act_info.effect_id
		local var_10_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/snow/snow_battle/enemy_item.csb")
		local var_10_6 = var_10_5:getChildByName("container")
		local var_10_7 = var_10_6:getContentSize()

		var_10_5:addTo(arg_10_0:nodeByName("list"))
		var_10_5:setPosition(cc.p(var_10_0, 0))

		var_10_0 = var_10_0 + var_10_7.width + 20

		table.insert(arg_10_0.heroContainers_, var_10_6:getChildByName("hero"))
		var_10_6:getChildByName("text_name"):setString(var_10_2.player_name)
		var_10_6:getChildByName("text_region"):setString("S" .. var_10_2.region)
		var_10_6:getChildByName("text_score_num"):setString(var_10_3.point)
		var_10_6:getChildByName("text_lev_num"):setString(var_10_1.act_partner_lev or 0)
		var_10_6:getChildByName("text_lev"):setString(var_0_2:translation("SNOW_ACTIVITY_SNOW_LEV"))
		var_10_6:getChildByName("text_score"):setString(var_0_2:translation("SNOW_ACTIVITY_BATTLE_SCORE"))
		xyd.imgEvent(var_10_6:getChildByName("btn_fight"), function()
			local var_11_0 = {
				enemy_id = var_10_2.player_id
			}

			arg_10_0.snowActivity:getFightEnemyInfo(var_11_0, function(arg_12_0, arg_12_1)
				if arg_12_0 == xyd.error.OK then
					local var_12_0 = arg_12_1.hero_infos or {}
					local var_12_1 = arg_12_1.act_partner_info or {}
					local var_12_2 = {}

					for iter_12_0 = 1, #var_12_0 do
						local var_12_3 = var_0_4.new()

						var_12_3:populate(var_12_0[iter_12_0])
						table.insert(var_12_2, var_12_3)
					end

					arg_10_0.snowActivity:formatNewHeros(var_12_2, var_12_1.lev or 1, var_12_1.color or 1)

					local var_12_4

					if var_12_1 and next(var_12_1) then
						var_12_4 = var_0_5.new()

						var_12_4:populate(var_12_1)

						local var_12_5 = xyd.tables.activitySnowEffect:buff(var_10_4)

						var_12_4:setEffectBuffID(var_12_5 or 0)
					end

					local var_12_6 = {
						showEnemy = true,
						teamType = xyd.SnowSelectTeamType.BATTLE,
						enemyHeroes = var_12_2,
						enemyMainRole = var_12_4,
						enemyRankInfo = var_10_3,
						enemy_id = var_10_2.player_id
					}

					xyd.WindowManager.get():openWindow("snow_select_team", var_12_6)
					xyd.WindowManager.get():closeWindow(arg_10_0)
				end
			end)
		end)
	end
end

function var_0_0.updateHeroModels(arg_13_0)
	if not arg_13_0.heroModels_ or not next(arg_13_0.heroModels_) then
		local var_13_0 = arg_13_0.snowActivity:getHero():getModelID()

		for iter_13_0 = 1, 3 do
			local var_13_1 = xyd.HeroAnimation.new(nil, var_13_0, xyd.tables.model:uiScale(var_13_0), {})

			if var_13_1 then
				var_13_1:idle()
				var_13_1:setScale(0.55)
				var_13_1:retain()
				table.insert(arg_13_0.heroModels_, var_13_1)
			end
		end
	end

	if arg_13_0.heroContainers_ and next(arg_13_0.heroContainers_) then
		for iter_13_1 = 1, #arg_13_0.heroContainers_ do
			local var_13_2 = (arg_13_0.matchInfos[iter_13_1].act_info or {}).effect_id or 1
			local var_13_3 = arg_13_0.heroModels_[iter_13_1]

			if var_13_3 then
				var_13_3:idle()
				var_13_3:addTo(arg_13_0.heroContainers_[iter_13_1])
				var_13_3:setPosition(cc.p(arg_13_0.heroContainers_[iter_13_1]:getContentSize().width / 2, 10))

				if var_13_3:getChildByName("hero_effect") then
					var_13_3:removeChildByName("hero_effect")
				end

				local var_13_4 = arg_13_0.snowActivity:updateHeroEffect(var_13_2, var_13_3)

				if var_13_4 then
					var_13_4:setName("hero_effect")
					var_13_4:setPosition(cc.p(0, var_13_3:getContentSize().height / 2))
				end
			end
		end
	end
end

function var_0_0.willClose(arg_14_0)
	if arg_14_0.heroModels_ and next(arg_14_0.heroModels_) then
		for iter_14_0 = 1, #arg_14_0.heroModels_ do
			arg_14_0.heroModels_[iter_14_0]:release()
		end
	end

	arg_14_0.heroModels_ = {}
end

return var_0_0
