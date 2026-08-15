local var_0_0 = class("AchievementDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = "skeletons/ui_effect/achievement/achievement_cup_silver"
local var_0_3 = "skeletons/ui_effect/achievement/achievement_cup_gold"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.data = arg_1_2.data
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.achievement = xyd.ModelManager.get():loadModel(xyd.ModelType.ACHIEVEMENT)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = arg_4_0.data
	local var_4_1 = xyd.tables.achievement:name(var_4_0.achieve_id)

	arg_4_0:nodeByName("title"):setString(var_4_1)
	arg_4_0:nodeByName("words_txt"):setString(xyd.tables.achievement:tip(var_4_0.achieve_id))

	if xyd.tables.achievement:stamp(var_4_0.achieve_id) == 1 then
		local var_4_2 = xyd.AssetLoader.get():loadSprite("windows/achievement/achieve/only_one_icon.png")

		var_4_2:addTo(arg_4_0:nodeByName("container"))
		var_4_2:setPosition(cc.p(90, 435))
		var_4_2:setScale(1.5)
	end

	for iter_4_0 = 1, #arg_4_0.data.complete_time do
		local var_4_3 = arg_4_0:nodeByName("achieve" .. iter_4_0)

		var_4_3:getChildByName("name_txt"):setString(var_4_1)
		var_4_3:getChildByName("points_text"):setString(var_0_1:translation("ACHIEVEMENT_POINT_TEXT"))
		var_4_3:getChildByName("points_txt"):setString(xyd.tables.achievement:points(var_4_0.achieve_id)[iter_4_0])

		local var_4_4 = string.format(xyd.tables.achievement:desc(var_4_0.achieve_id), xyd.tables.achievement:condition(var_4_0.achieve_id)[iter_4_0])
		local var_4_5 = arg_4_0:createDescLabel(var_4_4)

		var_4_5:setAnchorPoint(cc.p(0.5, 1))
		var_4_5:addTo(var_4_3:getChildByName("desc_pos"))

		local var_4_6 = var_4_3:getChildByName("desc_pos"):getPositionY() - var_4_5:getContentSize().height - 10

		var_4_3:getChildByName("progress_txt"):setPositionY(var_4_6)
		var_4_3:getChildByName("select"):setPositionY(var_4_6 + 5 - var_4_3:getChildByName("select"):getContentSize().height / 2)

		if arg_4_0.data.complete_time[iter_4_0] > 0 then
			var_4_3:getChildByName("progress_txt"):setString(arg_4_0.achievement:createFinishedTimeString(arg_4_0.data.complete_time[iter_4_0]))
			var_4_3:getChildByName("progress_txt"):setColor(cc.c4b(77, 191, 58, 255))
			var_4_3:getChildByName("select"):setVisible(true)
		else
			var_4_3:getChildByName("progress_txt"):setString("(" .. var_4_0.progress .. "/" .. xyd.tables.achievement:condition(var_4_0.achieve_id)[iter_4_0] .. ")")
			var_4_3:getChildByName("progress_txt"):setPositionX(var_4_3:getChildByName("desc_pos"):getPositionX())
			var_4_3:getChildByName("progress_txt"):setColor(cc.c4b(95, 112, 121, 255))
			var_4_3:getChildByName("select"):setVisible(false)
		end

		local var_4_7 = xyd.tables.achievement:icon(var_4_0.achieve_id) .. iter_4_0 .. ".png"

		if arg_4_0.data.complete_time[iter_4_0] == 0 then
			local var_4_8 = {
				filter = {}
			}

			var_4_8.filter.name = "GRAY"
			var_4_8.filter.value = {
				0.2,
				0.3,
				0.5,
				0.1
			}
			achieveIcon = xyd.SpriteLoader.new(var_4_7, nil, var_4_8, xyd.DefaultImageType.ACHIEVEMENT_ICON)
		else
			achieveIcon = xyd.SpriteLoader.new(var_4_7, nil, nil, xyd.DefaultImageType.ACHIEVEMENT_ICON)
		end

		achieveIcon:setAnchorPoint(cc.p(0.5, 0))
		achieveIcon:addTo(var_4_3:getChildByName("icon_pos"))
		achieveIcon:setScale(0.45)

		if arg_4_0.data.complete_time[iter_4_0] == 0 then
			-- block empty
		elseif iter_4_0 == 3 then
			arg_4_0.achievement:addEffect(var_0_3, var_4_3:getChildByName("icon_pos"), cc.p(0, 85))
		elseif iter_4_0 == 2 then
			arg_4_0.achievement:addEffect(var_0_2, var_4_3:getChildByName("icon_pos"), cc.p(0, 85))
		end
	end
end

function var_0_0.createDescLabel(arg_5_0, arg_5_1)
	local var_5_0 = {
		font = "fonts/main_font.ttf",
		size = 18,
		color = cc.c4b(95, 112, 121, 255),
		align = cc.ui.TEXT_ALIGN_CENTER
	}
	local var_5_1 = xyd.AssetLoader.get():loadLabel(var_5_0)

	var_5_1:setMaxLineWidth(165)
	var_5_1:setString(arg_5_1)

	return var_5_1
end

return var_0_0
