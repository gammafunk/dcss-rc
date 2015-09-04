------------------------
---- Begin safe_eat ----
------------------------

-- Prompt when eating in LOS of charmed tier-one demon, such as those made by
-- summon greater demon, since they can become hostile mid-meal. To enable in
-- your rc, add a lua code block with the contents of *force_mores.lua* and
-- make a macro binding your 'e' key to `===safe_eat`.

function safe_eat()
  tier_one_demons = {["executioner"] = true, ["shadow fiend"] = true,
                     ["ice fiend"] = true, ["brimstone fiend"] = true,
                     ["hell sentinel"] = true}
  have_t1 = false
  for x = -7,7 do
    for y = -7,7 do
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
