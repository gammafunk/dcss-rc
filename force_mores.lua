---------------------------------------
---- Begin conditional force_mores ----
---------------------------------------

-- See README.md for documentation.

last_turn = you.turns()

-- Each entry must have a name field with a descriptive name, a pattern field
-- giving the regexp matching the appropriate monster(s), a cond field giving
-- the condition type, and a cutoff field giving the max value where the
-- force-more is active. Possible values for cond are xl and maxhp. Note that
-- the final pattern will be "(pattern).*into view" where pattern is the value
-- from the entry.

fm_patterns = {
    -- General early game threats
    {pattern = "adder|gnoll|hound", cond = "xl", cutoff = 2,
     name = "XL1"},
    -- Problems for chars with 20, 60, 90, or 120 mhp
    {pattern = "orc|Ogre", cond = "20mhp",
     cutoff = 20, name = "20hp"},
    {pattern = "orc priest", cond = "maxhp", cutoff = 40, name = "40mhp"},
    {pattern = "centaur [^wzs]|drake|blink frog|spiny frog|basilisk" ..
         "|raven|komodo dragon|blink frog|snapping turtle|black mamba" ..
         "|(redback|trapdoor) spider|hill giant|deep elf (summoner|mage)" ..
         "|gargoyle|sixfirhy|sun demon",
     cond = "maxhp", cutoff = 60, name = "60mhp"},
    {pattern = "hydra|death yak|tarantella|(wolf|orb|jumping) spider" ..
         "|alligator|catoblepas|(fire|ice) dragon|spriggan (rider|druid)" ..
         "|torpor|yaktaur|vault guard|manticore|harpy|faun|merfolk|siren" ..
         "|water nymph|mana viper|a wizard|[0-9]+ wizards|ogre mage" ..
         "|deep elf (knight|conjurer)|tengu conjurer|green death" ..
         "|shadow demon",
     cond = "maxhp", cutoff = 90, name = "90mhp"},
    {pattern = "centaur warrior|yaktaur captain" ..
         "|(quicksilver|storm|shadow|iron) dragon|alligator snapping turtle" ..
         "|satyr|naga sharpshooter|merfolk avatar|anaconda|shock serpent" ..
         "|emperor scorpion(stone|frost|fire) giant|titan|entropy weaver" ..
         "|thorn hunter|sphinx|war gargoyle|preserver" ..
         "|vault (warden|sentinel)|convoker|monstrosity|tengu reaver" ..
         "|deep elf (master archer|blademaster|death mage" ..
                    "|sorcerer|demonologist|annihilator)" ..
         "|octopode crusher|yaktaur captain|spriggan (defender|air mage)" ..
         "|reaper|balrug",
     cond = "maxhp", cutoff = 120, name = "120mhp"}
} -- end fm_patterns

active_fm = {}
-- Set to true to get a message when the fm change
notify_fm = false

-- Wrapper of crawl.mpr() that prints text in white by default.
if not mpr then
    mpr = function (msg, color)
        if not color then
            color = "white"
        end
        crawl.mpr("<" .. color .. ">" .. msg .. "</" .. color .. ">")
    end
end

function init_force_mores()
    for i,v in ipairs(fm_patterns) do
        active_fm[#active_fm + 1] = false
    end
end

function update_force_mores()
    local activated = {}
    local deactivated = {}
    local hp, maxhp = you.hp()
    for i,v in ipairs(fm_patterns) do
        local msg = "(" .. v.pattern .. ").*into view"
        local action = nil
        local fm_name = v.pattern
        if v.name then
            fm_name = v.name
        end
        if not v.cond and not active_fm[i] then
            action = "+"
        elseif v.cond == "xl" then
            if active_fm[i] and you.xl() >= v.cutoff then
                action = "-"
            elseif not active_fm[i] and you.xl() < v.cutoff then
                action = "+"
            end
        elseif v.cond == "maxhp" then
            if active_fm[i] and maxhp >= v.cutoff then
                action = "-"
            elseif not active_fm[i] and maxhp < v.cutoff then
                action = "+"
            end
        end
        if action == "+" then
            activated[#activated + 1] = fm_name
        elseif action == "-" then
            deactivated[#deactivated + 1] = fm_name
        end
        if action ~= nil then
            local opt = "force_more_message " .. action .. "= " .. msg
            crawl.setopt(opt)
            active_fm[i] = not active_fm[i]
        end
    end
    if #activated > 0 and notify_fm then
        mpr("Activating force_mores: " .. table.concat(activated, ", "))
    end
    if #deactivated > 0 and notify_fm then
        mpr("Deactivating force_mores: " .. table.concat(deactivated, ", "))
    end
end

local last_turn = nil
function force_mores()
    if last_turn ~= you.turns() then
        update_force_mores()
        last_turn = you.turns()
    end
end

init_force_mores()

-------------------------
---- End force_mores ----
-------------------------
