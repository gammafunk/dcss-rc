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
    for s,_ in pairs(brstate.start_status) do
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

function bad_to_swing()
  local hp, mhp = you.hp()
  -- Stop multiple turn swing when our hp recovers.
  if brstate.swing_start and brstate.start_hp < mhp and hp == mhp then
    mpr("HP restored.")
    reset_bread_swing()
    return true
  end
  if you.status("manticore barbs") then
    abort_bread_swing("You must remove the manticore barbs first.")
    return true
  end
  if you.hunger_name() == "fainting" or you.hunger_name() == "starving" then
    abort_bread_swing("You need to eat bread, not swing it!")
    return true
  end
  if hostile_in_los() then
    if not brstate.swing_start then
      abort_bread_swing("You can't swing bread with a hostile monster in view!")
    else
      abort_bread_swing()
    end
    return true
  end
  if brstate.last_acted then
    msg = get_last_message()
    if not msg then
      abort_bread_swing("Unable to find a valid previous message!")
      return true
    end
    local good_msg
    if brstate.wielding then
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
  brstate.wielding = true
  brstate.last_acted = you.turns()
  crawl.sendkeys("w" .. bread_slot)
end

function bread_wielded()
  return items.equipped_at("Weapon").slot == items.letter_to_index(bread_slot)
end

function reset_bread_swing()
  -- Clear out table in old versions
  if c_persist.bread then
    c_persist.bread = nil
  end
  if not brstate then
    brstate = { }
    brstate.dir_x = nil
    brstate.dir_y = nil
  end
  brstate.last_acted = nil
  brstate.wielding = false
  brstate.swinging = false
  brstate.num_swings = nil
  brstate.swing_start = nil
  brstate.start_hp = nil
  brstate.start_status = { }
end

-- Wrapper of crawl.mpr() that prints text in white by default.
if not mpr then
  mpr = function (msg, color)
    if not color then
      color = "white"
    end
    crawl.mpr("<" .. color .. ">" .. msg .. "</" .. color .. ">")
  end
end

function abort_bread_swing(msg)
  if msg then
    mpr(msg, "lightred")
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
  if not brstate.swing_start then
    -- Record starting status to track any status changes.
    brstate.start_status = { }
    local status = you.status()
    for s,_ in pairs(status_messages) do
      if status:find(s) then
        brstate.start_status[s] = true
      end
    end
    brstate.swing_start = you.turns()
    brstate.start_hp = you.hp()
  end
  brstate.last_acted = you.turns()
  crawl.sendkeys(control(delta_to_vi(brstate.dir_x, brstate.dir_y)))
end

function one_bread_swing()
  brstate.swinging = true
  brstate.num_swings = 1
end

function start_bread_swing()
  brstate.swinging = true
  brstate.num_swings = num_swing_turns
end

function bread_swing()
  if not brstate.swinging or brstate.last_acted == you.turns() then
    return
  end
  if brstate.last_acted and brstate.swing_start
  and brstate.last_acted + 1 >= brstate.swing_start + brstate.num_swings then
    reset_bread_swing()
    return
  end
  if bad_to_swing() then
    return
  end
  if not bread_wielded() then
    if brstate.wielding then
      abort_bread_swing("Unable to wield bread on slot " .. bread_slot)
      return
    end
    wield_bread()
    return
  end
  brstate.wielding = false
  if not brstate.dir_x or not pos_is_open(brstate.dir_x, brstate.dir_y) then
    brstate.dir_x, brstate.dir_y = get_safe_direction()
    if not brstate.dir_x then
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
