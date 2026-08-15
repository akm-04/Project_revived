local var_0_0 = class("SocialScene", import("app.common.ui.BaseScene"))
local var_0_1 = "sound/main.ogg"

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	if arg_1_1 and arg_1_1.viewConf then
		arg_1_0.viewConf_ = arg_1_1.viewConf
	end

	local var_1_0 = xyd.AssetLoader.get():loadSprite("images/scene_bg.png"):pos(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2):addTo(arg_1_0)
end

function var_0_0.onEnterTransitionFinish(arg_2_0)
	var_0_0.super.onEnterTransitionFinish(arg_2_0)
	xyd.LoadingProxy.get():addLoading()
	arg_2_0:loadFriends()
end

function var_0_0.onExit(arg_3_0)
	var_0_0.super.onExit(arg_3_0)
end

function var_0_0.loadFriends(arg_4_0)
	local var_4_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.FRIENDS)
	local var_4_1 = arg_4_0

	var_4_0:load(function(arg_5_0, arg_5_1)
		if arg_5_0 ~= xyd.error.OK then
			xyd.errorAlert(arg_5_1, nil, function()
				xyd.LoadingProxy.get():removeLoading()

				if display.getRunningScene() == var_4_1 then
					cc.Director:getInstance():popScene()
				end
			end)
		end

		arg_4_0:loadSendRequestPlayers()
	end)
end

function var_0_0.loadSendRequestPlayers(arg_7_0)
	local var_7_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SEND_REQUEST_PLAYERS)
	local var_7_1 = arg_7_0

	var_7_0:load(function(arg_8_0, arg_8_1)
		if arg_8_0 ~= xyd.error.OK then
			xyd.errorAlert(arg_8_1, nil, function()
				xyd.LoadingProxy.get():removeLoading()

				if display.getRunningScene() == var_7_1 then
					cc.Director:getInstance():popScene()
				end
			end)
		end

		arg_7_0:loadGetRequestPlayers()
	end)
end

function var_0_0.loadGetRequestPlayers(arg_10_0)
	local var_10_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.GET_REQUEST_PLAYERS)
	local var_10_1 = arg_10_0

	var_10_0:load(function(arg_11_0, arg_11_1)
		if arg_11_0 ~= xyd.error.OK then
			xyd.errorAlert(arg_11_1, nil, function()
				xyd.LoadingProxy.get():removeLoading()

				if display.getRunningScene() == var_10_1 then
					cc.Director:getInstance():popScene()
				end
			end)
		end

		arg_10_0:loadRecommendFriends()
	end)
end

function var_0_0.loadRecommendFriends(arg_13_0)
	local var_13_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.RECOMMEND_FRIENDS)
	local var_13_1 = arg_13_0

	var_13_0:load(function(arg_14_0, arg_14_1)
		if arg_14_0 ~= xyd.error.OK then
			xyd.errorAlert(arg_14_1, nil, function()
				xyd.LoadingProxy.get():removeLoading()

				if display.getRunningScene() == var_13_1 then
					cc.Director:getInstance():popScene()
				end
			end)
		end

		arg_13_0:display()
	end)
end

function var_0_0.display(arg_16_0)
	local var_16_0 = xyd.WindowManager.get():openWindow("social", {
		viewConf = arg_16_0.viewConf_
	})

	if var_16_0 ~= nil then
		xyd.LoadingProxy.get():removeLoading()

		local var_16_1 = arg_16_0

		cc.EventProxy.new(var_16_0, var_16_0):addEventListener(xyd.event.EXIT_SOCIAL, function()
			if display.getRunningScene() == var_16_1 then
				cc.Director:getInstance():popScene()
			end
		end)
	end
end

return var_0_0
