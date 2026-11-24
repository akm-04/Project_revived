-- x01: with the 2018 cast on, every voice line is unlocked, as it was in the 1.164.0 client.
--
-- HeroMainWindow and the other 2.5D/battle taps only play a model sound when getHeroVoiceState marks that slot open:
-- voice 2 needs level 10, voice 3 favour 2, voice 4 quality 4, voice 5 stars 3. That gate is progress, not audio, and
-- on a low-progress girl it drops four of the seven bust taps, which reads as "the 2018 lines are missing". The guide's
-- voice tab never consults the gate, so the same nine lines play there; this makes the model taps agree with it while
-- the legacy cast is selected. SuperHero already returns all nine open; only NormalHero needs the wrapper.

local GXB_LEGACY_VOICE_KEY = "gxb_legacy_voice"
local gxbHeroVoiceState = var_0_3.getHeroVoiceState

function var_0_3.getHeroVoiceState(gxbUnlockSelf)
	local order, unlocked = gxbHeroVoiceState(gxbUnlockSelf)

	if type(order) ~= "table" or not cc.UserDefault:getInstance():getBoolForKey(GXB_LEGACY_VOICE_KEY, false) then
		return order, unlocked
	end

	local allUnlocked = {}

	for index = 1, #order do
		allUnlocked[index] = true
	end

	return order, allUnlocked
end
