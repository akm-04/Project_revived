local var_0_0 = class("HeroScene", import("app.common.ui.BaseScene"))
local var_0_1 = "sound/main.ogg"

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	if arg_1_1 then
		if arg_1_1.viewConf then
			arg_1_0.viewConf_ = arg_1_1.viewConf
		end

		if arg_1_1.player then
			arg_1_0.player_ = arg_1_1.player
		end
	else
		arg_1_0.viewConf_ = {}
		arg_1_0.viewConf_.modeSwitchEnabled = true
		arg_1_0.viewConf_.viewMode = xyd.HeroViewMode.SINGLE_VIEW
		arg_1_0.viewConf_.sortType = xyd.HeroDataSortType.BY_LEVEL
	end

	local var_1_0 = xyd.AssetLoader.get():loadSprite("images/scene_bg.png"):pos(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2):addTo(arg_1_0)
end

function var_0_0.onEnterTransitionFinish(arg_2_0)
	arg_2_0.super.onEnterTransitionFinish(arg_2_0)
	xyd.LoadingProxy.get():addLoading()
	arg_2_0:loadHeros()
end

function var_0_0.onExit(arg_3_0)
	var_0_0.super.onExit(arg_3_0)
end

function var_0_0.loadHeros(arg_4_0)
	local var_4_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_4_1 = arg_4_0.player_ == nil or arg_4_0.player_.playerID == var_4_0.playerID
	local var_4_2

	if var_4_1 then
		var_4_2 = {}
	else
		var_4_2 = {
			player_id = arg_4_0.player_.playerID
		}
	end

	if not arg_4_0.player_ then
		arg_4_0.player_ = var_4_0
	end

	local var_4_3 = arg_4_0

	arg_4_0.player_:loadHeros(var_4_2, function(arg_5_0, arg_5_1)
		if arg_5_0 ~= xyd.error.OK then
			xyd.errorAlert(arg_5_1, nil, function()
				xyd.LoadingProxy.get():removeLoading()

				if display.getRunningScene() == var_4_3 then
					cc.Director:getInstance():popScene()
				end
			end)
		end

		arg_4_0:loadEssences()
	end)
end

function var_0_0.loadEssences(arg_7_0)
	local var_7_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if arg_7_0.player_ == nil or arg_7_0.player_.playerID == var_7_0.playerID then
		local var_7_1 = arg_7_0

		var_7_0:loadEssences(function(arg_8_0, arg_8_1)
			if arg_8_0 ~= xyd.error.OK then
				xyd.errorAlert(arg_8_1, nil, function()
					xyd.LoadingProxy.get():removeLoading()

					if display.getRunningScene() == var_7_1 then
						cc.Director:getInstance():popScene()
					end
				end)
			end

			arg_7_0:display()
		end)
	else
		arg_7_0:display()
	end
end

function var_0_0.display(arg_10_0)
	local var_10_0 = xyd.WindowManager.get():openWindow("hero", {
		viewConf = arg_10_0.viewConf_,
		player = arg_10_0.player_
	})

	if var_10_0 ~= nil then
		xyd.LoadingProxy.get():removeLoading()

		local var_10_1 = arg_10_0

		cc.EventProxy.new(var_10_0, var_10_0):addEventListener(xyd.event.EXIT_HERO, function()
			if display.getRunningScene() == var_10_1 then
				cc.Director:getInstance():popScene()
			end
		end)
	end
end

return var_0_0
