local var_0_0 = import(".CCSUILoader")
local var_0_1 = class("CCSSceneLoader")

function var_0_1.load(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.params_ = arg_1_2

	local var_1_0 = arg_1_0:createGameObject(arg_1_1)
	local var_1_1 = arg_1_1.CanvasSize._width
	local var_1_2 = arg_1_1.CanvasSize._height

	arg_1_0.params_ = nil

	return var_1_0
end

function var_0_1.createGameObject(arg_2_0, arg_2_1)
	local var_2_0 = display.newNode()

	var_2_0.name = arg_2_1.name or "no name"

	var_2_0:setRotation(arg_2_1.rotation or 0)
	var_2_0:setScaleX(arg_2_1.scalex or 1)
	var_2_0:setScaleY(arg_2_1.scaley or 1)

	if not arg_2_1.visible or arg_2_1.visible == 0 then
		var_2_0:setVisible(false)
	else
		var_2_0:setVisible(true)
	end

	var_2_0:setLocalZOrder(arg_2_1.zorder or 0)
	var_2_0:setTag(arg_2_1.objecttag or 0)
	var_2_0:setPosition(arg_2_1.x, arg_2_1.y)

	if arg_2_1.components then
		for iter_2_0, iter_2_1 in ipairs(arg_2_1.components) do
			arg_2_0:addComponent(var_2_0, iter_2_1, iter_2_0)
		end
	end

	if arg_2_1.gameobjects then
		local var_2_1

		for iter_2_2, iter_2_3 in ipairs(arg_2_1.gameobjects) do
			local var_2_2 = arg_2_0:createGameObject(iter_2_3)

			if var_2_2 then
				var_2_0:addChild(var_2_2)
			end
		end
	end

	return var_2_0
end

function var_0_1.addComponent(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	local var_3_0

	if arg_3_2.fileData then
		arg_3_0:loadTexture(arg_3_2.fileData.plistFile)
	end

	if arg_3_2.classname == "CCScene" then
		var_3_0 = arg_3_0:createScene(arg_3_2)
	elseif arg_3_2.classname == "CCSprite" then
		var_3_0 = arg_3_0:createSprite(arg_3_2)
	elseif arg_3_2.classname == "CCArmature" then
		var_3_0 = arg_3_0:createArmature(arg_3_2)
	elseif arg_3_2.classname == "GUIComponent" then
		var_3_0 = arg_3_0:createGUIComponent(arg_3_2)
	elseif arg_3_2.classname == "CCParticleSystemQuad" then
		var_3_0 = arg_3_0:createParticleSystem(arg_3_2)
	else
		print("CCSSceneLoader - not support classname:" .. arg_3_2.classname)
	end

	if var_3_0 then
		var_3_0.name = "Component" .. arg_3_3

		arg_3_1:addChild(var_3_0)
	end

	return arg_3_1
end

function var_0_1.createScene(arg_4_0, arg_4_1)
	return (cc.Scene:create())
end

function var_0_1.createBackgroundAudio(arg_5_0, arg_5_1)
	return
end

function var_0_1.createSprite(arg_6_0, arg_6_1)
	local var_6_0

	if arg_6_0:isNil(arg_6_1.fileData.plistFile) then
		var_6_0 = arg_6_1.fileData.path
	else
		var_6_0 = "#" .. arg_6_1.fileData.path
	end

	return (display.newSprite(var_6_0))
end

function var_0_1.createArmature(arg_7_0, arg_7_1)
	ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(arg_7_1.fileData.path)

	return (ccs.Armature:create(io.pathinfo(arg_7_1.fileData.path).basename))
end

function var_0_1.createGUIComponent(arg_8_0, arg_8_1)
	return (var_0_0:loadFile(arg_8_1.fileData.path, arg_8_0.params_))
end

function var_0_1.createParticleSystem(arg_9_0, arg_9_1)
	local var_9_0 = cc.ParticleSystemQuad:create(arg_9_1.fileData.path)

	var_9_0:setPosition(0, 0)

	return var_9_0
end

function var_0_1.loadTexture(arg_10_0, arg_10_1, arg_10_2)
	if not arg_10_1 or string.utf8len(arg_10_1) == 0 then
		return
	end

	local var_10_0 = cc.SpriteFrameCache:getInstance()

	if arg_10_2 then
		var_10_0:addSpriteFrames(arg_10_1, arg_10_2)
	else
		var_10_0:addSpriteFrames(arg_10_1)
	end
end

function var_0_1.isNil(arg_11_0, arg_11_1)
	if not arg_11_1 or string.utf8len(arg_11_1) == 0 then
		return true
	else
		return false
	end
end

return var_0_1
