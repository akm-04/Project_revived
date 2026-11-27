-- x06 experimental: play the generic awakening spine over the awakening cutscene.
--
-- The 1.631.0 client replaced the old full-screen awakening animation (the lost
-- plist row "juexing/" -> atlases/awake.plist, 46 frames, one shared effect for
-- every girl) with the card cutscene in AwakeHeroWindow. This overlay puts the
-- official awakening burst back at the start of that cutscene, using the same
-- generic spine the completion window already plays for every girl
-- (AwakeCompleteWindow.lua:29), so no per-girl asset is involved.
--
-- Tuning knobs: GXB_AWAKE_SPINE_SCALE (one constant), and removing this patch
-- directory restores the stock behaviour.

local GXB_AWAKE_SPINE = "skeletons/ui_effect/awake/character_awaken"
local GXB_AWAKE_SPINE_SCALE = 2.6
local GXB_AWAKE_SPINE_Z = 1000

local function gxbAwakeSpinePlayNext(spine)
	if tolua.isnull(spine) then
		return
	end
	spine:play(function()
		if not tolua.isnull(spine) then
			spine:removeSelf()
		end
	end, false, nil, "texiao02")
end

local function gxbAwakeSpineShow(window)
	local spine = var_0_1.new(GXB_AWAKE_SPINE .. ".json", GXB_AWAKE_SPINE .. ".atlas", 1)
	if not spine then
		return
	end
	spine:setAnchorPoint(0.5, 0.5)
	spine:setPosition(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2)
	spine:setScale(GXB_AWAKE_SPINE_SCALE)
	spine:setLocalZOrder(GXB_AWAKE_SPINE_Z)
	window:addChild(spine)
	spine:play(function()
		gxbAwakeSpinePlayNext(spine)
	end, false, nil, "texiao01")
end

local gxbAwakeDidOpen = var_0_0.didOpen

function var_0_0.didOpen(gxbAwakeSelf, gxbAwakeParams)
	gxbAwakeDidOpen(gxbAwakeSelf, gxbAwakeParams)
	gxbAwakeSpineShow(gxbAwakeSelf)
end
