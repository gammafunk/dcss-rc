------------------------
---- Begin safe_eat ----
------------------------

-- See README.md for documentation.

version = 0.15
if crawl.version then
    version = tonumber(crawl.version("major"))
end
los_range = version >= 0.17 and 7 or 8

function safe_eat()
    tier_one_demons = {["executioner"] = true, ["shadow fiend"] = true,
        ["ice fiend"] = true, ["brimstone fiend"] = true,
        ["hell sentinel"] = true}
    have_t1 = false
    for x = -los_range,los_range do
        for y = -los_range,los_range do
            m = monster.get_monster_at(x, y)
            if m and m:status("in your thrall")
            and tier_one_demons[m:desc():lower()] ~= nill then
                have_t1 = true
                t1_desc = m:desc()
                break
            end
        end
    end
    if have_t1 then
        crawl.formatted_mpr("Really eat with the " .. t1_desc .. " in view?",
                            "prompt")
        local res = crawl.getch()
        if not (string.char(res) == "y" or string.char(res) == "Y") then
            crawl.formatted_mpr("Okay, then.", "prompt")
            return
        end
    end
    crawl.sendkeys("e")
end

----------------------
---- End safe_eat ----
----------------------
