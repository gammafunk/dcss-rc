-----------------------------
---- Begin char_defaults ----
-----------------------------

-- See README.md for documentation.

weapon_skills = {"Unarmed Combat", "Short Blades", "Long Blades", "Axes",
                 "Maces & Flails", "Polearms", "Staves"}
ranged_skills = {"Throwing", "Bows", "Crossbows", "Slings"}
other_skills = {"Fighting", "Armour", "Dodging",
                "Shields", "Spellcasting", "Conjurations", "Hexes", "Charms",
                "Summonings", "Necromancy", "Translocations", "Transmutations",
                "Fire Magic", "Ice Magic", "Air Magic", "Earth Magic",
                "Poison Magic", "Invocations", "Evocations","Stealth"}
skill_glyphs = { [1] = "+", [2] = "*" }
chdat = nil
char_combo = you.race() .. you.class()
loaded_attempted = false

-- Wrapper of crawl.mpr() that prints text in white by default.
if not mpr then
  mpr = function (msg, color)
    if not color then
      color = "white"
    end
    crawl.mpr("<" .. color .. ">" .. msg .. "</" .. color .. ">")
  end
end

function skill_message(prefix, skill, skill_type, value)
  local msg = ""
  if prefix then
    msg = prefix .. ";"
  end
  if skill_type then
    msg = msg .. skill_type .. "(" .. skill .. "):" .. value
  else
    msg = msg .. skill .. ":" .. value
  end
  return msg
end

function save_char_defaults(quiet)
  if you.class() == "Wanderer" then
    return
  end
  if not c_persist.char_defaults then
    c_persist.char_defaults = { }
  end
  c_persist.char_defaults[char_combo] = { }
  chdat = c_persist.char_defaults[char_combo]
  local msg = nil
  local have_weapon = false
  for _,sk in ipairs(weapon_skills) do
    if you.train_skill(sk) > 0 then
      chdat["Weapon"] = you.train_skill(sk)
      msg = skill_message(nil, sk, "Weapon",
                          skill_glyphs[chdat["Weapon"]])
      have_weapon = true
      break
    end
  end
  if not have_weapon then
    chdat["Weapon"] = nil
  end
  local have_ranged = false
  for _,sk in ipairs(ranged_skills) do
    if you.train_skill(sk) > 0 then
      chdat["Ranged"] = you.train_skill(sk)
      msg = skill_message(msg, sk, "Ranged",
                          skill_glyphs[chdat["Ranged"]])
      have_ranged = true
      break
    end
  end
  if not have_ranged then
    chdat["Ranged"] = nil
  end
  for _,sk in ipairs(other_skills) do
    if you.train_skill(sk) > 0 then
      chdat[sk] = you.train_skill(sk)
      msg = skill_message(msg, sk, nil, skill_glyphs[chdat[sk]])
    else
      chdat[sk] = nil
    end
  end
  if not quiet then
    mpr("Saved default for " .. char_combo .. ": " .. msg)
  end
end

function have_defaults()
  return  you.class() ~= "Wanderer"
    and c_persist.char_defaults ~= nil
    and c_persist.char_defaults[char_combo] ~= nil
end

function load_char_defaults(quiet)
  if not have_defaults() then
    return
  end
  local msg = nil
  local found_weapon = false
  chdat = c_persist.char_defaults[char_combo]
  for _,sk in ipairs(weapon_skills) do
    if you.base_skill(sk) > 0 and chdat["Weapon"] then
      you.train_skill(sk, chdat["Weapon"])
      msg = skill_message(msg, sk, "Weapon",
                          skill_glyphs[chdat["Weapon"]])
      found_weapon = true
    else
      you.train_skill(sk, 0)
    end
  end
  if chdat["Weapon"] and not found_weapon then
    you.train_skill("Unarmed Combat", chdat["Weapon"])
    msg = skill_message(msg, "Unarmed Combat", "Weapon",
                        skill_glyphs[chdat["Weapon"]])
  end
  local found_ranged = false
  for _,sk in ipairs(ranged_skills) do
    if you.base_skill(sk) > 0 and chdat["Ranged"] then
      you.train_skill(sk, chdat["Ranged"])
      msg = skill_message(msg, sk, "Ranged",
                          skill_glyphs[chdat["Ranged"]])
      found_ranged = true
    else
      you.train_skill(sk, 0)
    end
  end
  if chdat["Ranged"] and not found_ranged then
    you.train_skill("Throwing", chdat["Ranged"])
    msg = skill_message(msg, "Throwing", "Ranged",
                        skill_glyphs[chdat["Ranged"]])
  end
  for _,sk in ipairs(other_skills) do
    if chdat[sk] then
      you.train_skill(sk, chdat[sk])
      msg = skill_message(msg, sk, nil, skill_glyphs[chdat[sk]])
    else
      you.train_skill(sk, 0)
    end
  end
  if not quiet and msg ~= "" then
    mpr("Loaded default for " .. char_combo .. ": " .. msg)
  end
end

function char_defaults(quiet)
  if you.turns() ~= 0 then
    return
  end

  if not load_attempted then
    load_char_defaults(quiet)
    load_attempted = true

    -- Open the skill menu if we don't have settings to load.
    if not have_defaults() then
      crawl.sendkeys("m")
    end
  end
end

---------------------------
---- End char_defaults ----
---------------------------
