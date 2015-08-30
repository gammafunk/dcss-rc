-----------------------------
---- Begin char_defaults ----
-----------------------------

-- Load default skill settings and a skill target (based on target_skill, if
-- that code is also loaded in your rc) for a specific race+class combination
-- when a game of that type loads. If you change your skills or skill target on
-- turn 0, these are automatically saved as new defaults for that character. To
-- enable in your rc, add a lua code block with the contents of
-- *char_defaults.lua* and a call to `char_defaults()` in your `ready()`
-- function. Additionally, to save your defaults on the fly, you can assign a
-- key to a macro with a target of `===save_char_defaults`.

-- Wrapper of crawl.mpr() that prints text in white.
if not mpr then
   mpr = function (msg)
      crawl.mpr("<white>" .. msg .. "</white>")
   end
end

function save_default_target_skill(quiet)
  combo = you.race() .. you.class()
  if c_persist.char_defaults
     and c_persist.char_defaults[combo]
     and c_persist.char_defaults[combo].target_skill == nill then
      c_persist.char_defaults[combo].target_skill = c_persist.target_skill
    if not quiet then
       mpr("Set default target skill for " .. combo .. ": "
           .. c_persist.target_skill)
    end
  end
  
end

function save_char_defaults(quiet)
  combo = you.race() .. you.class()
  if not c_persist.char_defaults then
    c_persist.char_defaults = { }
  end
  if not c_persist.char_defaults[combo] then
    c_persist.char_defaults[combo] = { }
  end
  skill_msg = ""
  glyph_map = { [1] = "+", [2] = "*" }
  for _,sk in ipairs(skill_list) do
    if you.train_skill(sk) > 0 then
      c_persist.char_defaults[combo][sk] = you.train_skill(sk)
      if skill_msg ~= "" then
        skill_msg = skill_msg .. ";"
      end
      skill_msg = skill_msg .. sk .. ":" .. glyph_map[you.train_skill(sk)]
    else
      c_persist.char_defaults[combo][sk] = nill
    end
  end
  c_persist.char_defaults[combo]["target_skill"] = nill
  if not need_target_skill and c_persist.target_skill ~= nill then
    c_persist.char_defaults[combo]["target_skill"] = c_persist.target_skill
    skill_msg = skill_msg .. ";target:" .. c_persist.target_skill
  end
  if not quiet then
    mpr("Saved default for " .. combo .. ": " .. skill_msg)
  end
end

function have_defaults()
  combo = you.race() .. you.class()
  return c_persist.char_defaults and c_persist.char_defaults[combo]
end

function load_char_defaults(quiet)
  if not have_defaults() then
    return
  end
  combo = you.race() .. you.class()
  skill_msg = ""
  glyph_map = { [1] = "+", [2] = "*" }
  for _,sk in ipairs(skill_list) do
    if c_persist.char_defaults[combo][sk] then
      you.train_skill(sk, c_persist.char_defaults[combo][sk])
      if skill_msg ~= "" then
        skill_msg = skill_msg .. ";"
      end
      skill_msg = skill_msg .. sk .. ":"
                  .. glyph_map[c_persist.char_defaults[combo][sk]]
    else
      you.train_skill(sk, 0)
    end
  end
  if c_persist.char_defaults[combo]["target_skill"] then
    c_persist.target_skill = c_persist.char_defaults[combo]["target_skill"]
    skill_msg = skill_msg .. ";Target:" .. c_persist.target_skill
    need_target_skill = false
    record_current_skills(c_persist.target_skill)
  elseif init_target_skill then
    -- Called by target_skill() trigger setting a skill target. We call it here
    -- here since setting it skips the skills menu, which we don't want that.
    -- This means the call to char_defaults() should come before target_skill()
    -- in ready()
    init_target_skill()
  end
  if not quiet and skill_msg ~= "" then
    mpr("Loaded default for " .. combo .. ": " .. skill_msg)
  end
end

function char_defaults(quiet)
  if you.turns() ~= 0 then
      return
  end

  if need_target_skill == nill then
    load_char_defaults(quiet)
  end
  if need_target_skill ~= nill and not have_defaults() then
    save_char_defaults(quiet)
  end
end

---------------------------
---- End char_defaults ----
---------------------------
