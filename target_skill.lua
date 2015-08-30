-----------------------------
---- Beging target_skill ----
-----------------------------

-- Opens the skill screen automaticaly when a skill reaches a target level set
-- by the player. To enable in your rc, add a lua code block with the contents
-- of *target_skill.lua* and a call to `target_skill()` in your `ready()`
-- function. Additionally you'll wand to assign a key to a macro with a target
-- of `===set_target_skill` so can change the skill target on the fly. Original
-- code by elliptic with some reorganization.

skill_list = {"Fighting","Short Blades","Long Blades","Axes","Maces & Flails",
              "Polearms","Staves","Unarmed Combat","Bows","Crossbows",
              "Throwing","Slings","Armour","Dodging","Shields","Spellcasting",
              "Conjurations","Hexes","Charms","Summonings","Necromancy",
              "Translocations","Transmutations","Fire Magic","Ice Magic",
              "Air Magic","Earth Magic","Poison Magic","Invocations",
              "Evocations","Stealth"}
local need_target_skill = nil

function record_current_skills(maxlev)
  c_persist.current_skills = { }
  for _,sk in ipairs(skill_list) do
    if you.train_skill(sk) > 0 and you.base_skill(sk) < (maxlev or 27) then
      table.insert(c_persist.current_skills, sk)
    end
  end
end

function check_skills()
  if not c_persist.current_skills or not c_persist.target_skill then
    return
  end
  for _,sk in ipairs(c_persist.current_skills) do
    if you.base_skill(sk) >= c_persist.target_skill then
      crawl.formatted_mpr(sk .. " reached " .. c_persist.target_skill
                          .. ".", "prompt")
      crawl.more()
      set_new_skill_training()
      break
    end
  end
end

function init_target_skill()
  c_persist.target_skill = nill
  c_persist.current_skills = { }
  need_target_skill = true
end

function set_new_skill_training()
  init_target_skill()
  c_persist.target_skill = 0
  crawl.sendkeys("m")
end

function set_target_skill()
  record_current_skills()
  local str = "Currently training: "
  local first_skill = true
  for _,sk in ipairs(c_persist.current_skills) do
    val = you.base_skill(sk)
    if first_skill then
      str = str .. sk .. "(" .. val .. ")"
    else
      str = str .. ", " .. sk .. "(" .. val .. ")"
    end
    first_skill = false
  end
  str = str .. "."
  crawl.formatted_mpr(str, "prompt")
  crawl.formatted_mpr("Choose a target skill level: ", "prompt")
  c_persist.target_skill = tonumber(crawl.c_input_line())
  record_current_skills(c_persist.target_skill)
  -- Update the target skill for char_defaults()
  save_default_target_skill()
end

function control(c)
  return string.char(string.byte(c) - string.byte('a') + 1)
end

-- Moved this to its own function to clean up ready() -gammafunk
function target_skill()
  prev_need_target = need_target_skill
  -- Need to update target_skill at turn 0 no matter what, since it
  -- might carry from a previous game.
  if (prev_need_target == nil and you.turns() == 0)
     or c_persist.target_skill == nil then
    set_new_skill_training()
  end
  if prev_need_target then
    set_target_skill()
    need_target_skill = false
  elseif not need_target_skill then
    check_skills()
  end
end

--------------------------
---- End target_skill ----
--------------------------
