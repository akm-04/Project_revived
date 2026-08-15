local var_0_0 = class("SpriteLoader", function(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4)
	local var_1_0 = arg_1_2 or {}

	var_1_0.capInsets = arg_1_1

	if arg_1_1 ~= nil then
		var_1_0.class = ccui.Scale9Sprite
	end

	local var_1_1 = ""

	if arg_1_3 == xyd.DefaultImageType.SKILL_ICON then
		var_1_1 = "images/icon/skill_icon/wenhao.png"
	elseif arg_1_3 == xyd.DefaultImageType.ITEM_ICON then
		var_1_1 = "images/icon/black_bg.png"
	elseif arg_1_3 == xyd.DefaultImageType.HOME_CARD then
		var_1_1 = "images/common/home_card_common.png"
	elseif arg_1_3 == xyd.DefaultImageType.SMALL_CARD then
		var_1_1 = "images/common/small_card_common.png"
	elseif arg_1_3 == xyd.DefaultImageType.MAP then
		var_1_1 = "images/maps/map_images/lt_2.png"
	elseif arg_1_3 == xyd.DefaultImageType.AVATAR then
		var_1_1 = "images/avatars/10002003.png"
	elseif arg_1_3 == xyd.DefaultImageType.HERO_CARD then
		var_1_1 = "images/common/hero_card_common.png"
	elseif arg_1_3 == xyd.DefaultImageType.AVATAR_FRAME then
		var_1_1 = "images/avatar_frames/120001001.png"
	elseif arg_1_3 == xyd.DefaultImageType.ACTIVITIY_ICON then
		var_1_1 = "images/activities/common_activity.png"
	elseif arg_1_3 == xyd.DefaultImageType.CHAPTER_MAP then
		var_1_1 = "images/maps/chapter_bg1.png"
	elseif arg_1_3 == xyd.DefaultImageType.ACHIEVEMENT_ICON then
		var_1_1 = "images/achievement/100001_icon_1.png"
	elseif arg_1_3 == xyd.DefaultImageType.BLOODLINE then
		var_1_1 = "images/bust/common.png"
	elseif arg_1_3 == xyd.DefaultImageType.AWAKE_HERO_ICON then
		var_1_1 = "images/bust/common.png"
	elseif arg_1_3 == xyd.DefaultImageType.AWAKE_PET_ICON then
		var_1_1 = "images/bust/common.png"
	elseif arg_1_3 == xyd.DefaultImageType.CAMPAIGN_CARD then
		var_1_1 = "images/maps/map_avatar/10002001.png"
	elseif arg_1_3 == xyd.DefaultImageType.SERVER_SELECT then
		var_1_1 = "images/server_select/100200.png"
	elseif arg_1_3 == xyd.DefaultImageType.INSCRIPTION then
		var_1_1 = "images/icon/transparent_icon/common.png"
	elseif arg_1_3 == xyd.DefaultImageType.SMALL_MAP_BG then
		var_1_1 = "images/maps/map_small_bg/sakura02.png"
	elseif arg_1_3 == xyd.DefaultImageType.CG then
		var_1_1 = "images/cg/0.png"
	elseif arg_1_3 == xyd.DefaultImageType.BG_MAIN then
		var_1_1 = "images/main_scene.png"
	elseif arg_1_3 == xyd.DefaultImageType.BG_ROOM then
		var_1_1 = "windows/library/dialog/bg.png"
	elseif arg_1_3 == xyd.DefaultImageType.CHARGE then
		var_1_1 = "images/vip_recharge/default.png"
	elseif arg_1_3 == xyd.DefaultImageType.MAIN_ACT then
		var_1_1 = "images/main_act/common.png"
	elseif arg_1_3 == xyd.DefaultImageType.S_CARD then
		var_1_1 = "images/common/s_card_common.png"
	elseif arg_1_3 == xyd.DefaultImageType.COMMON_TITLE then
		var_1_1 = "images/common/unknown.png"
	elseif arg_1_3 == xyd.DefaultImageType.ACTIVITIY_ICON_CLICK then
		var_1_1 = "images/activities/common_activity_0.png"
	elseif arg_1_3 == xyd.DefaultImageType.BUBBLE_BG then
		var_1_1 = "images/bubble/bg/10001.png"
	elseif arg_1_3 == xyd.DefaultImageType.BUBBLE_ARROW then
		var_1_1 = "images/bubble/arrow/10001.png"
	elseif arg_1_3 == xyd.DefaultImageType.QUESTION_MARK then
		var_1_1 = "images/question_mark.png"
	elseif arg_1_3 == xyd.DefaultImageType.QUESTION_MARK2 then
		var_1_1 = "images/question_mark.png"
	end

	local var_1_2

	if var_1_0.filter and next(var_1_0.filter) then
		var_1_2 = display.newFilteredSprite(var_1_1, var_1_0.filter.name, var_1_0.filter.value)
	else
		var_1_2 = display.newSprite(var_1_1, 0, 0, var_1_0)
	end

	if arg_1_4 and not tolua.isnull(arg_1_4) then
		var_1_2:scale(arg_1_4:getContentSize().width / var_1_2:getContentSize().width)
	end

	return var_1_2
end)

function var_0_0.ctor(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6)
	if arg_2_4 ~= xyd.DefaultImageType.AVATAR_FRAME and arg_2_4 ~= xyd.DefaultImageType.BUBBLE_BG and arg_2_4 ~= xyd.DefaultImageType.BUBBLE_ARROW then
		local var_2_0 = {
			size = 28,
			color = cc.c3b(255, 255, 255)
		}

		if arg_2_4 == xyd.DefaultImageType.CG or arg_2_4 == xyd.DefaultImageType.BG_MAIN or arg_2_4 == xyd.DefaultImageType.BG_ROOM then
			var_2_0.size = 120
		end

		arg_2_0.label = xyd.AssetLoader.get():loadLabel(var_2_0)

		arg_2_0.label:setMaxLineWidth(50)
		arg_2_0.label:addTo(arg_2_0)
		arg_2_0.label:setName("progress")
		arg_2_0.label:setAnchorPoint(0.5, 0.5)
		arg_2_0.label:setPosition(arg_2_0:getContentSize().width / 2, arg_2_0:getContentSize().height / 2)
		arg_2_0.label:setString("")
		arg_2_0.label:enableOutline(cc.c4b(136, 15, 0, 255), 1)
	end

	xyd.AssetDownload.get():downloadSpriteByPath(arg_2_0, arg_2_1, function()
		if arg_2_0 and not tolua.isnull(arg_2_0) then
			if arg_2_4 == xyd.DefaultImageType.AVATAR then
				local var_3_0 = cc.FileUtils:getInstance():fullPathForFilename(arg_2_1)

				if io.exists(var_3_0) ~= true then
					arg_2_1 = "images/avatars/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarId] .. ".png"
				end
			end

			local var_3_1

			if arg_2_2 then
				local var_3_2 = xyd.AssetLoader.get():loadSprite(arg_2_1, nil, arg_2_3)

				if var_3_2.getSpriteFrame then
					arg_2_0:setSpriteFrame(var_3_2:getSpriteFrame(), arg_2_2)
				else
					arg_2_0:setSpriteFrame(var_3_2:getSprite():getSpriteFrame(), arg_2_2)
				end

				if arg_2_3.size then
					arg_2_0:setContentSize(arg_2_3.size)
				end
			else
				local var_3_3 = xyd.AssetLoader.get():loadSprite(arg_2_1, arg_2_2, arg_2_3)

				arg_2_0:setTexture(var_3_3:getTexture())
				arg_2_0:setTextureRect(cc.rect(0, 0, var_3_3:getContentSize().width, var_3_3:getContentSize().height))
			end

			if arg_2_0.label and not tolua.isnull(arg_2_0.label) then
				arg_2_0.label:removeSelf()

				arg_2_0.label = nil
			end

			if arg_2_5 and not tolua.isnull(arg_2_5) then
				arg_2_0:scale(arg_2_5:getContentSize().width / (arg_2_0:getContentSize().width + 3))
			end

			if arg_2_6 then
				arg_2_6()
			end
		end
	end)
end

function var_0_0.setPercent(arg_4_0, arg_4_1)
	if arg_4_0.label and not tolua.isnull(arg_4_0.label) and arg_4_1 then
		arg_4_0.label:setVisible(true)
		arg_4_0.label:setString(arg_4_1 .. "%")
	end
end

return var_0_0
