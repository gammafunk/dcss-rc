-- Some simple options good for realtime and turncount runs, set up to be
-- toggleable. Note that I don't have much experience playing realtime runs,
-- those options are just taken from RCs of players who do.

-- Wrapper of crawl.mpr() that prints text in white by default.
if not mpr then
    mpr = function (msg, color)
        if not color then
            color = "white"
        end
        crawl.mpr("<" .. color .. ">" .. msg .. "</" .. color .. ">")
    end
end

function toggle_realtime_options()
    if c_persist.realtime_options then
        disable_realtime_options(true)
    else
        enable_realtime_options(true)
    end
end

function enable_realtime_options(verbose)
    crawl.setopt("ae += >wand of (magic darts|flame|frost)")
    crawl.setopt("ae += >wand of (slowing|polymorph|confusion|paralysis)")
    crawl.setopt("use_animations = ")
    c_persist.realtime_options = true
    if verbose then
        mpr("Enabling realtime options.")
    end
end

function disable_realtime_options(verbose)
    crawl.setopt("ae -= >wand of (magic darts|flame|frost)")
    crawl.setopt("ae -= >wand of (slowing|polymorph|confusion|paralysis)")
    crawl.setopt("use_animations = beam, range, hp, monster_in_sight, " ..
                     "pickup, monster, player, branch_entry")
    c_persist.realtime_options = false
    if verbose then
        mpr("Disabling realtime options.")
    end
end

function toggle_turncount_options()
    if c_persist.turncount_options then
        disable_turncount_options(true)
    else
        enable_turncount_options(true)
    end
end

function enable_turncount_options(verbose)
    crawl.setopt("ae += >wand of (magic darts|flame|frost)")
    crawl.setopt("ae += >wand of (slowing|polymorph|confusion|paralysis)")
    crawl.setopt("use_animations = ")
    c_persist.turncount_options = true
    if verbose then
        mpr("Enabling turncount options.")
    end
end

function disable_turncount_options(verbose)
    crawl.setopt("ae -= >wand of (magic darts|flame|frost)")
    crawl.setopt("ae -= >wand of (slowing|polymorph|confusion|paralysis)")
    crawl.setopt("use_animations = beam, range, hp, monster_in_sight, " ..
                     "pickup, monster, player, branch_entry")
    c_persist.turncount_options = false
    if verbose then
        mpr("Disabling turncount options.")
    end
end


function toggle_turncount_options()

    if c_persist.turncount_options then
        crawl.setopt("confirm_butcher = auto")
        crawl.setop("ai -= (bread|meat) ration:!e")
        crawl.setopt("ai -= scroll.+of.*(acquirement|summoning|teleportation" ..
                         "|fear|magic mapping):!r")
        crawl.setopt("ai -= potion.+of(curing|heal wounds|might|agility" ..
                         "|brilliance|magic|invisibility):!q")
    else
        crawl.setopt("confirm_butcher = never")
        crawl.setop("ai += (bread|meat) ration:!e")
        crawl.setopt("ai += scroll.+of.*(acquirement|summoning|teleportation" ..
                         "|fear|magic mapping):!r")
        crawl.setopt("ai += potion.+of(curing|heal wounds|might|agility" ..
                         "|brilliance|magic|invisibility):!q")
    end
    c_persist.turncount_options = not c_persist.turncount_options
    verb = c_persist.turncount_options and "Enabling" or "Disabling"
    mpr(verb .. " turncount options.")
end

if c_persist.realtime_options == nil then
    c_persist.realtime_options = false
elseif c_persist.realtime_options then
    enable_realtime_options()
end

if c_persist.turncount_options == nil then
    c_persist.turncount_options = false
elseif c_persist.turncount_options then
    enable_turncount_options()
end
