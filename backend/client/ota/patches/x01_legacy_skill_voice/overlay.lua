-- x01: the ultimate voice line in battle comes from skill.lua, not from the hero table.
--
-- skill.lua's `sound` column names the file the battle plays when a skill fires; 236 of its 239 hero paths are
-- <girl>_voice9.ogg, the ultimate line. BaseFighter pushes that path into the battle sound queue, which plays it
-- straight through audio.playSound, so neither the hero-table redirect nor the on-demand fetch ever saw it - the ult
-- stayed on the modern cast while every other line switched.
--
-- Route it through the same map the hero and model accessors use, so the skill table inherits the same manifest,
-- setting and fallback behaviour.

local function gxbSkillVoiceMap(path)
	local legacyVoice = xyd.gxbLegacyVoice

	if not legacyVoice or not legacyVoice.map then
		return path
	end

	return legacyVoice.map(path)
end

local gxbSkillVoiceSound = var_0_2.sound

function var_0_2.sound(gxbSkillVoiceSelf, gxbSkillVoiceId)
	return gxbSkillVoiceMap(gxbSkillVoiceSound(gxbSkillVoiceSelf, gxbSkillVoiceId))
end
