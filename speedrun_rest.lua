-----------------------------
---- Begin speedrun_rest ----
-----------------------------

-- See README.md for documentation.

-- How many turns to rest at max.
num_rest_turns = 30

-- If true, look for a foot item inventory slot and use fallback_slot if we
-- can't find a ration. If false, always use fallback_slot.
automatic_slot = true

-- Slot where you keep your slow swing item.
fallback_slot = "c"

-- Set to true to have Na characters always walk instead of item swing if
-- they're able to walk slowly. This is not as turncount efficient for non-Chei
-- worshipers, but some Na players may prefer it over having to change the
-- wielded weapon.
naga_always_walk = false

-- Delay in milliseconds before sending the next walk command. Makes the
-- visuals a bit less jarring when using walk resting. Set to 0 to disable.
walk_delay = 50

-- To have the multi-turn rest ignore status change messages, add an entry here
-- giving the pattern of the message you'd like to ignore. The entries below
-- cover the transition messages from the regen spell, Trog's hand, and poison
-- status. The key should be the status that's seen in the output of
-- `you.status()` when the status is active, and the value should be a single
-- pattern string or an array of pattern strings matching the message you'd
-- like to ignore. See the lua string library manual for details on making
-- patterns.
status_messages = {
  ["poisoned"] = {"You feel[^%.]+sick%.",
                  "You are no longer poisoned%."},
  ["regenerating"] = {"You feel the effects of Trog's Hand fading%.",
                      "Your skin is crawling a little less now%."}
} --end status_messages

-- Like status_messages above, but for arbitrary messages. Any message matching
-- one of these patterns is ignored.
ignore_messages = {
  --RandomTiles messages
  "Trog roars: Now[^!]+!+",
  "Sif Muna whispers: Become[^!]+!+",
  "[^:]+ says: Become[^!]+!+",
  --Debug messages
  "Dbg:.*",
} -- end ignore_messages

-- NOTE: No configuration past this point.

ATT_NEUTRAL = 1

version = 0.15
if crawl.version then
  version = tonumber(crawl.version("major"))
end
los_range = version >= 0.17 and 7 or 8

-- Wrapper of crawl.mpr() that prints text in white by default.
if not mpr then
  mpr = function (msg, color)
    if not color then
      color = "white"
    end
    crawl.mpr("<" .. color .. ">" .. msg .. "</" .. color .. ">")
  end
end

function control(c)
  return string.char(string.byte(c) - string.byte('a') + 1)
end

function delta_to_vi(dx, dy)
  local d2v = {
    [-1] = { [-1] = 'y', [0] = 'h', [1] = 'b'},
    [0]  = { [-1] = 'k',            [1] = 'j'},
    [1]  = { [-1] = 'u', [0] = 'l', [1] = 'n'},
  } -- hack
  return d2v[dx][dy]
end

function reset_rest()
  if not rstate then
    rstate = { }
    rstate.set_slot = false
    rstate.dir_x = nil
    rstate.dir_y = nil
  end
  rstate.last_acted = nil
  rstate.wielding = false
  rstate.resting = false
  rstate.num_turns = nil
  rstate.rest_start = nil
  rstate.start_hp = nil
  rstate.start_status = { }
  rstate.start_message = nil
end

function abort_rest(msg)
  if msg then
    mpr(msg, "lightred")
  end
  reset_rest()
end

function crawl_message(i)
  local msg = crawl.messages(i):gsub("\n", "")
  msg = msg:gsub("^%c* *", "")
  msg = msg:gsub(" *%c*?$", "")
  return msg
end

function record_status()
  -- Record starting status to track any status changes.
  rstate.start_status = { }
  local status = you.status()
  for s,_ in pairs(status_messages) do
    if status:find(s) then
      rstate.start_status[s] = true
    end
  end
  rstate.start_message = get_last_message()
end

function in_water()
  return view.feature_at(0, 0):find("water") and not you.status("flying")
end

function get_last_message()
  local rest_type = get_rest_type()
  local in_water = in_water()
  -- Ignore these movement messages when walking.
  local move_patterns = {"There is a[^%.]+here.",
                         "Things that are here:.*",
                         "Items here:.*"}
  for i = 1,200 do
    local msg = crawl_message(i)
    for s,_ in pairs(rstate.start_status) do
      if type(status_messages[s]) == "table" then
        for _,p in ipairs(status_messages[s]) do
          msg = msg:gsub(p, "")
        end
      else
        msg = msg:gsub(status_messages[s], "")
      end
    end
    if rest_type == "walk" then
      for _,p in ipairs(move_patterns) do
        -- Also remove any whitespace.
        msg = msg:gsub(" *" .. p .. " *", "")
      end
    end
    msg = msg:gsub(" *Beep! [^%.]+%. *", "")
    for _,p in ipairs(ignore_messages) do
      msg = msg:gsub(p, "")
    end
    if msg ~= "" then
      return msg
    end
  end
  return nil
end

function wield_swing_item()
  rstate.wielding = true
  rstate.last_acted = you.turns()
  record_status()
  crawl.sendkeys("w*" .. c_persist.swing_slot)
end

function find_swing_slot()
  rstate.set_slot = true
  if not automatic_slot then
    c_persist.swing_slot = fallback_slot
    return
  end
  c_persist.swing_slot = nil
  for _,item in ipairs(items.inventory()) do
    if item.class() == "Comestibles"
      or item.class() == "Books"
      or item.class() == "Wands"
      or item.class() == "Missiles"
      or item.class() == "Miscellaneous"
      or (item.class() == "Hand Weapons"
            and (item.subtype():find("bow")
                 or item.subtype():find("sling")
                 or item.subtype():find("crossbow")
                 or item.subtype():find("blowgun"))) then
        c_persist.swing_slot = items.index_to_letter(item.slot)
        break
    end
  end
  if not c_persist.swing_slot then
    c_persist.swing_slot = fallback_slot
  end
end

function swing_item_wielded()
  local weapon = items.equipped_at("Weapon")
  return weapon
    and c_persist.swing_slot ~= nil
    and weapon.slot == items.letter_to_index(c_persist.swing_slot)
end

function hostile_in_los()
  local have_t1 = false
  for x = -los_range,los_range do
    for y = -los_range,los_range do
      m = monster.get_monster_at(x, y)
      if m and not m:is_safe() then
        return true
      end
    end
  end
  return false
end

function ponderous_level()
  local level = 0
  for _,item in ipairs(items.inventory()) do
    local ego = item.ego()
    if item.equipped and ego == "ponderousness" then
      level = level + 1
    end
  end
  return level
end

-- XXX See if we can move at least some of this into clua, since it's
-- recreating play_movement_speed() and player_speed(). The aim is to determine
-- if slow move is more regen-efficient and that the saving is worth the
-- hassle, this calculates the minimum move speed, which can normally vary at
-- random from randomized delay (e.g. water) and the many uses of
-- div_rand_round().
function player_move_speed()
  if you.transform() == "tree" then
    return 0
  end

  local in_water = in_water()
  local walk_water = you.race() == "Merfolk"
    or you.race() == "Octopode"
    or you.race() == "Barachi"
    or you.god() == "Beogh" and you.piety_rank() == 5
    or you.transform == "ice"

  -- This is player action speed, based on things that affect all actions.
  local player_speed = 10
  if you.status("slowed") then
    player_speed = math.floor(player_speed * 3 / 2)
  end
  if you.status("berserking") and you.god() ~= "Cheibriados"
  or  you.status("hasted") then
    player_speed = math.floor(player_speed * 2 / 3)
  end
  if you.transform() == "statue" or you.status("petrifying") then
    player_speed = math.floor(player_speed * 3 / 2)
  end
  if in_water and not walk_water then
    player_speed = math.floor(player_speed * 13 / 10)
  end

  -- This is the base player movement speed given all things that affect only
  -- movement.
  local move_speed = 10
  if you.transform() == "bat" then
    move_speed = 5
  elseif you.transform() == "pig" then
    move_speed = 7
  elseif you.transform() == "porcupine" or you.transform == "wisp" then
    move_speed = 8
  elseif in_water and (you.transform() == "hydra"
                       or you.race() == "Merfolk") then
    move_speed = 6
  elseif you.race() == "Tengu" and you.status("flying") then
    move_speed = 9
  end

  local boots = items.equipped_at("Boots")
  local running_level = 0
  if boots
    and not boots.is_melded
    and boots.ego()
  and boots.ego() == "running" then
    running_level = 1
  end
  move_speed = move_speed - running_level
  move_speed = move_speed + ponderous_level()

  if you.god() == "Cheibriados" then
    -- Calculate this based on the minimum piety at the observed rank,
    -- since we can't know the true piety level.
    local piety_breaks = { 1, 30, 50, 75, 100, 120, 160 }
    move_speed = move_speed + 2 +
      math.floor(math.min(piety_breaks[you.piety_rank() + 1] / 20, 8))
  end

  if you.status("frozen") then
    move_speed = move_speed + 4
  end
  if you.status("grasped by roots") then
    move_speed = move_speed + 3
  end

  local speed_mut = you.mutation("speed")
  local slow_mut = you.mutation("slowness")
  if speed_mut > 0 then
    move_speed = move_speed - speed_mut - 1
  elseif slow_mut > 0 then
    move_speed = math.floor(move_speed * (10 +  slow_mut * 2) / 10)
  end

  if not in_water and you.status("sluggish") then
    if move_speed >= 8 then
      move_speed = math.floor(move_speed * 3 / 2)
    elseif move_speed == 7 then
      move_speed = math.floor(7 * 6 / 5)
    end
  elseif not in_water and you.status("swift") then
    move_speed = math.floor(move_speed * 3 / 4)
  end
  if move_speed < 6 then
    move_speed = 6
  end
  return math.floor(player_speed * move_speed / 10)
end

function get_rest_type()
  if you.race() == "Naga" and naga_always_walk
    or you.god() == "Cheibriados"
    or (not swing_item_wielded()
        and not weapon_can_swap()) then
    return "walk"
  else
    return "item"
  end
end

function bad_to_act()
  local hp, mhp = you.hp()
  local rest_type = get_rest_type()
  -- Stop multiple turn action when our hp recovers.
  if rstate.rest_start and rstate.start_hp < mhp and hp == mhp then
    mpr("HP restored.")
    reset_rest()
    return true
  end
  if you.status("manticore barbs") then
    abort_rest("You must remove the manticore barbs first.")
    return true
  end
  if you.hunger_name() == "fainting" or you.hunger_name() == "starving" then
    abort_rest("You need to eat!")
    return true
  end
  if hostile_in_los() then
    if not rstate.rest_start then
      abort_rest("You can't rest with a hostile monster in view!")
    else
      abort_rest()
    end
    return true
  end

  -- If any unrecognized message occurs, assume we need to stop resting.
  if rstate.last_acted then
    local msg = get_last_message()
    if not msg then
      abort_rest("Unable to find a previous message!")
      return true
    end
    local wield_pt = "^ *" .. c_persist.swing_slot .. " - .+[%)}] *$"
    local swing_pt = "^ *You swing at nothing%. *$"
    local pattern = rstate.wielding and wield_pt or swing_pt
    if (rest_type == "item" and not msg:find(pattern))
    or rest_type == "walk" and msg ~= rstate.start_message then
      abort_rest()
      return true
    end
  end

  if rest_type == "walk" and player_move_speed() <= 10 then
    abort_rest("You cannot walk slowly right now!")
    return true
  end
  return false
end

function feat_is_open(feat)
  local fname = feat:lower()
  -- Unique substrings that identify solid features.
  local solid_features = {"wall", "grate", "tree", "mangrove",
                          "endless_lava", "open_sea", "statue", "idol",
                          "malign_gateway", "sealed_door", "closed_door",
                          "runed_door", "explore_horizon"}

  for i,p in ipairs(solid_features) do
    if fname:find(p) then
      return false
    end
  end
  return true
end

function safe_walk_pos(x, y)
  local in_water = in_water()
  local pos_is_water = view.feature_at(x, y):find("water")
  -- Don't allow walking out of water if we're in water
  return (in_water and pos_is_water
          -- Don't allow walking into water if we're not in it
            or not in_water and not pos_is_water)
  -- Require the destination to be safe.
    and view.is_safe_square(x, y)
end

function safe_swing_pos(x, y)
  return not monster.get_monster_at(x, y)
    and feat_is_open(view.feature_at(x,y))
end

function safe_direction(x, y)
  if get_rest_type() == "walk" then
    return safe_walk_pos(x, y)
  else
    return safe_swing_pos(x, y)
  end
end

function weapon_can_swap()
  local weapon = items.equipped_at("Weapon")
  if not weapon then
    return true
  end
  if weapon.cursed then
    return false
  end

  local ego = weapon.ego()
  -- Some unrands like Plut. sword have no ego.
  if ego
    and (ego == "vampirism"
         or ego == "distortion" and you.god() ~= "Lugonu") then
      return false
  end

  if weapon.artefact then
    local artp = weapon.artprops
    return not (artp["*Contam"] or artp["*Curse"] or artp["*Drain"])
  end
  return true
end

function get_safe_direction()
  local have_t1 = false
  for x = -1,1 do
    for y = -1,1 do
      if (x ~= 0 or y ~= 0) and safe_direction(x, y) then
        return x, y
      end
    end
  end
  return nil
end

function do_resting()
  -- Our first turn of resting.
  if not rstate.rest_start then
    record_status()
    rstate.rest_start = you.turns()
    rstate.start_hp = you.hp()
  end
  rstate.last_acted = you.turns()
  local rest_type = get_rest_type()
  if rest_type == "item" then
    crawl.sendkeys(control(delta_to_vi(rstate.dir_x, rstate.dir_y)))
  else
    local cur_x = rstate.dir_x
    local cur_y = rstate.dir_y
    -- Save the return direction as our next direction.
    rstate.dir_x = -rstate.dir_x
    rstate.dir_y = -rstate.dir_y
    crawl.sendkeys(delta_to_vi(cur_x, cur_y))
    crawl.delay(walk_delay)
  end
end

function one_turn_rest()
  rstate.resting = true
  rstate.num_turns = 1
end

function start_resting()
  rstate.resting = true
  rstate.num_turns = num_rest_turns
end

function set_swing_slot()
  crawl.formatted_mpr("Enter an slot letter for the swing item: ", "prompt")
  local letter = crawl.c_input_line()
  local index = items.letter_to_index(letter)
  if not index or index < 0 then
    mpr("Must be a letter (a-z or A-Z)!", "lightred")
    return
  end
  c_persist.swing_slot = letter
  rstate.set_slot = true
  mpr("Set swing slot to " .. letter .. ".")
end

function speedrun_rest()
  local rest_type = get_rest_type()
  if rest_type == "item"
    and (not c_persist.swing_slot
         or you.turns() == 0 and not rstate.set_slot) then
      find_swing_slot()
  end

  if not rstate.resting then
    return
  end

  -- Only act once per turn.
  if rstate.last_acted == you.turns() then
    -- An error happened with the 'w' command
    if rstate.wielding and not swing_item_wielded() then
      abort_rest("Unable to wield swing item on slot " ..
                   c_persist.swing_slot .. "!")
    end
    return
  end

  if rstate.last_acted and rstate.rest_start
  and rstate.last_acted + 1 >= rstate.rest_start + rstate.num_turns then
    reset_rest()
    return
  end

  if bad_to_act() then
    return
  end

  if rest_type == "item" and not swing_item_wielded() then
    wield_swing_item()
    return
  end

  rstate.wielding = false
  if not rstate.dir_x
  -- Don't try to reuse our position if we were walk resting and did
  -- something inbetween our last rest.
    or swing_type == "walk" and rstat.last_acted ~= you.turns() - 1
  or not safe_direction(rstate.dir_x, rstate.dir_y) then
    rstate.dir_x, rstate.dir_y = get_safe_direction()
    if not rstate.dir_x then
      abort_rest("No safe direction found!")
      return
    end
  end
  do_resting()
end

reset_rest()

---------------------------
---- End speedrun_rest ----
---------------------------
