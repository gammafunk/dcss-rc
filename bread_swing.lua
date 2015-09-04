---------------------------
---- Begin bread_swing ----
---------------------------

-- Automatic bread swinging for either a single or fixed number of turns. An
-- item in a fixed inventory slot (default is 'c') is automatically wielded if
-- it isn't already. This function prevents you from swinging if hostiles are
-- in LOS and interrupts multi-turn swings if hostiles wander into LOS or if
-- any unrecognized message occurs.  To enable in your rc, add a lua code block
-- with the contents of *bread_swing.lua* and a call to `bread_swing()` in your
-- `ready()` function. Additionally assign two macro keys, one with a target of
-- `===one_bread_swing` for the single-turn swing and one with a target of
-- `===start_bread_swing` for the multiple turn swing.

-- Max number of turns for multi-turn bread swinging.
num_swing_turns = 20

-- Slot where you keep your bread-like item.
bread_slot = "c"

-- To have the multi-turn swing ignore status change messages, add an entry
-- here giving the pattern of the message you'd like to ignore. The entries
-- below cover the transition messages from the regen spell, Trog's hand, and
-- poison status. The key should be the status that's seen in the output of
-- `you.status()` when the status is active, and the value should be a single
-- pattern string or an array of pattern strings matching the message you'd
-- like to ignore. Note the need for `%c* *` and ` *%c*` at the beginning and
-- end. See the lua string library manual for details on making patterns.
status_messages = {
  ["poisoned"] = "%c* *You feel[^%.]+sick\.%c*",
  ["regenerating"] = {"%c* *You feel the effects of Trog's Hand fading%. *%c*",
                      "%c* *Your skin is crawling a little less now%. *%c*"}}

-- NOTE: No configuration past this point.

ATT_NEUTRAL = 1
brdat = nil

function hostile_in_los()
  local have_t1 = false
  for x = -7,7 do
    for y = -7,7 do
      m = monster.get_monster_at(x, y)
      if m and m:attitude() <= ATT_NEUTRAL then
        return true
      end
    end
  end
  return false
end

function get_last_message()
  for i = 1,50 do
    local msg = crawl.messages(i)
    for s,_ in pairs(brdat.start_status) do
      if type(status_messages[s]) == "table" then
        for _,p in ipairs(status_messages[s]) do
          msg = msg:gsub(p, "")
        end
      else
        msg = msg:gsub(status_messages[s], "")
      end
    end
    msg = msg:gsub("%c* *Beep! [^%.]+%. *%c*", "")
    if msg ~= "" then
      return msg
    end
  end
  return nil
end

function status_changed()
  if not brdat.start_status then
    return false
  end
  local status = you.status()
  for s,_ in pairs(brdat.start_status) do
    if not status:find(s) then
      return true
    end
  end
  return false
end

function unsafe_to_swing()
  if you.status("manticore barbs") then
    abort_bread_swing("You must remove the manticore barbs first.")
    return true
  end
  if you.hunger_name() == "fainting" or you.hunger_name() == "starving" then
    abort_bread_swing("You need to eat bread, not swing it!")
    return true
  end
  if hostile_in_los() then
    if not brdat.swing_start then
      abort_bread_swing("You can't swing bread with a hostile monster in view!")
    else
      abort_bread_swing()
    end
    return true
  end
  if brdat.last_acted then
    msg = get_last_message()
    if not msg then
      abort_bread_swing("Unable to find a valid previous message!")
      return true
    end
    local good_msg
    if brdat.wielding then
      good_msg = msg:find("^%c* *" .. bread_slot .. " - .+[)}] *%c*$")
    else
      good_msg = msg:find("^%c* *You swing at nothing%. *%c*$") 
    end
    if not good_msg then
      abort_bread_swing()
      return true
    end
  end
  return false
end

function feat_is_open(feat)
  local fname = feat:lower()
  local feat_patterns = {"wall", "grate", "tree", "mangrove", "endless lava",
                         "open sea", "statue", "idol", "somewhere",
                         "sealed door", "closed door", "runed door"}
  for i,p in ipairs(feat_patterns) do
    if fname:find(p) then
      return false
    end
  end
  return true
end

function pos_is_open(x, y)
  return not monster.get_monster_at(x, y) and feat_is_open(view.feature_at(x,y))
end

function get_safe_direction()
  local have_t1 = false
  for x = -1,1 do
    for y = -1,1 do
      if (x ~= 0 or y ~= 0) and pos_is_open(x, y) then
        return x, y
      end
    end
  end
  return nil
end

function wield_bread()
  brdat.wielding = true
  brdat.last_acted = you.turns()
  -- Wield message will become the first message examined.
  brdat.start_message = nil
  crawl.sendkeys("w" .. bread_slot)
end

function bread_wielded()
  return items.equipped_at("Weapon").slot == items.letter_to_index(bread_slot)
end

function reset_bread_swing()
  if not c_persist.bread then
    c_persist.bread = { }
    brdat = c_persist.bread
    brdat.dir_x = nil
    brdat.dir_y = nil
  end
  brdat = c_persist.bread
  brdat.last_acted = nil
  brdat.wielding = false
  brdat.swinging = false
  brdat.num_swings = nil
  brdat.swing_start = nil
  brdat.start_status = { }
end

function abort_bread_swing(msg)
  if msg then
    crawl.mpr("<lightred>" .. msg .. "</lightred>")
  end
  reset_bread_swing()
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

function do_swing_bread()
  -- Our first turn of bread swinging.
  if not brdat.swing_start then
    -- Record starting status to track any status changes.
    brdat.start_status = { }
    local status = you.status()
    for s,_ in pairs(status_messages) do
      if status:find(s) then
        brdat.start_status[s] = true
      end
    end
    brdat.swing_start = you.turns()
  end
  brdat.last_acted = you.turns()
  crawl.sendkeys(control(delta_to_vi(brdat.dir_x, brdat.dir_y)))
end

function one_bread_swing()
  brdat.swinging = true
  brdat.num_swings = 1
end

function start_bread_swing()
  brdat.swinging = true
  brdat.num_swings = num_swing_turns
end

function bread_swing()
  if not brdat.swinging or brdat.last_acted == you.turns() then
    return
  end
  if brdat.last_acted and brdat.swing_start
    and (brdat.last_acted + 1 >= brdat.swing_start + brdat.num_swings
         or status_changed()) then
    reset_bread_swing()
    return
  end
  if unsafe_to_swing() then
    return
  end
  if not bread_wielded() then
    if brdat.wielding then
      abort_bread_swing("Unable to wield bread on slot " .. bread_slot)
      return
    end
    wield_bread()
    return
  end
  brdat.wielding = false
  if not brdat.dir_x or not pos_is_open(brdat.dir_x, brdat.dir_y) then
    brdat.dir_x, brdat.dir_y = get_safe_direction()
    if not brdat.dir_x then
      abort_bread_swing("No safe direction found!")
      return
    end
  end
  do_swing_bread()
end

reset_bread_swing()

-------------------------
---- End bread_swing ----
-------------------------
