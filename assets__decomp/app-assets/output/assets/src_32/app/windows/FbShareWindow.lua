local var_0_0 = class("FbShareWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.fbShare

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.type = arg_1_2.type or xyd.FBShareType.ARENA
	arg_1_0.heroID = arg_1_2.heroID or 10001001
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0)
	arg_2_0:nodeByName("close"):addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			local var_3_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_3_0, false)

			if arg_2_0.callback then
				arg_2_0.callback()
			end

			xyd.WindowManager.get():closeWindow(arg_2_0)
		end
	end)
	arg_2_0:initAvatarAndCard()
	arg_2_0:nodeByName("share_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_4_0 = ""
			local var_4_1 = xyd.split(arg_2_0.content, "\n")

			for iter_4_0, iter_4_1 in ipairs(var_4_1) do
				var_4_0 = var_4_0 .. iter_4_1
			end

			xyd.fbShare(var_0_2:type(arg_2_0.type), var_0_2:title(arg_2_0.type), var_4_0, var_0_2:link(arg_2_0.type), string.format(var_0_2:imgLink(arg_2_0.type), tostring(arg_2_0.heroID)))
			xyd.Backend.get():request(xyd.mid.FB_SHARE_WEEKLY, {}, function(arg_5_0, arg_5_1)
				if arg_5_0 == xyd.error.OK then
					-- block empty
				end
			end)
		end
	end)
end

function var_0_0.initAvatarAndCard(arg_6_0)
	local var_6_0 = arg_6_0:nodeByName("avatar_container")
	local var_6_1 = display.newNode()

	var_6_1:setContentSize(110, 110)
	var_6_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_6_1:addTo(var_6_0)
	xyd.setAvatarClip(var_6_1, arg_6_0.selfPlayer:getMyCurrentAvatarID(), 0)
	xyd.AssetLoader.get():loadSprite("images/avatar_frames/" .. xyd.tables.avatar.icon_[arg_6_0.selfPlayer.avatarFrame] .. ".png"):addTo(var_6_0)

	local var_6_2 = arg_6_0:nodeByName("card_container")
	local var_6_3 = var_6_2:getHeight()
	local var_6_4

	if arg_6_0.type == xyd.FBShareType.ARENA then
		var_6_4 = xyd.AssetLoader.get():loadSprite("windows/fb_share/arena_pic.png")
	elseif arg_6_0.type == xyd.FBShareType.PET or arg_6_0.type == xyd.FBShareType.PET_AWAKE then
		local var_6_5 = import("app.model.Pet").new()

		var_6_5:initUnCollected(arg_6_0.heroID)

		var_6_4 = xyd.getPetCard(var_6_5)
	elseif arg_6_0.type == xyd.FBShareType.HERO or arg_6_0.type == xyd.FBShareType.HERO_AWAKE then
		local var_6_6 = import("app.model.Hero").new()

		var_6_6:initUnCollected(arg_6_0.heroID)

		var_6_4 = xyd.getHeroCard(var_6_6, 3)
	end

	arg_6_0.content = var_0_2:content(arg_6_0.type)

	arg_6_0:nodeByName("default_txt"):setString(arg_6_0.content)

	if var_6_4 then
		local var_6_7 = var_6_4:getHeight()

		var_6_4:scale(var_6_3 / var_6_7)
		var_6_4:setAnchorPoint(0, 0)
		var_6_4:addTo(var_6_2)
	end
end

function var_0_0.didOpen(arg_7_0)
	arg_7_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
