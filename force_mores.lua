---------------------------------------
---- Begin conditional force_mores ----
---------------------------------------

-- Add and remove force-more messages based on hp/xl conditions. A force-more
-- is triggered the first time it comes into view if it's of a certain kind and
-- requires the player to hit e.g. space to continue. These messages can help
-- to avoid killing your weaker characters under manual movement (e.g. in
-- speedruns). To enable in your rc, add a lua code block with the contents of
-- *force_mores.lua* and a call to `force_mores()` in your `ready()` function.

local last_turn = you.turns()
local fm_patterns = {
                  -- General early game threats
                  {pattern = "(adder|gnoll|hound)", cond = "xl", cutoff = 2,
                   name = "XL1"},
                  {pattern = "orc wizard|Ogre|orc warrior", cond = "maxhp",
                   cutoff = 20},
                  {pattern = "orc priest", cond = "maxhp", cutoff = 40},
                  -- Problems for squishies with 60 or 90 hp
                  {pattern = "(centaur [^wzs]|yaktaur|drake" ..
                      "|blink frog|torpor|spiny frog|blink frog" ..
                      "|black mamba|hydra|spriggan|alligator|snapping turtle" ..
                      "|manticore|harpy|faun|merfolk|siren|water nymph" ..
                      "|jumping spider|mana viper|hill giant|vault guard" ..
                      "|preserver|a wizard|[0-9]+ wizards|ogre mage" ..
                      "|deep elf (knight|sorceror)",
                   cond = "maxhp", cutoff = 60, name = "squishy_60hp"},
                  {pattern = "(centaur warrior|yaktaur captain|dragon|hydra" ..
                      "|dragon|alligator snapping turtle|satyr" ..
                      "|naga sharpshooter|merfolk avatar|anaconda" ..
                      "|shock serpent|guardian serpent|emperor scorpion" ..
                      "|stone giant|titan|fire giant|sphinx|frost giant" ..
                      "|war gargoyle|vault warden|convoker|monstrosity" ..
                      "|tengu reaver" ..
                      "|deep elf (master archer|blade master|death mage" ..
                                 "|sorceror|summoner)" ..
                      "|octopode crusher|yaktaur captain)",
                   cond = "maxhp", cutoff = 90, name = "squishy_90hp"}}

local active_fm = {}
-- Set to true to get a message when the fm change
local notify_fm = false
function init_force_mores()
   for i,v in ipairs(fm_patterns) do
       active_fm[#active_fm + 1] = false
   end
end

function update_force_mores()
   activated = {}
   deactivated = {}
   hp, maxhp = you.hp()
   for i,v in ipairs(fm_patterns) do
      msg = v.pattern .. ".*into view"
      action = nil
      fm_name = v.pattern
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
      elseif v.cond == "br" then
         if active_fm[i] and you.branch():lower() ~= v.value:lower() then
             action = "-"
         elseif not active_fm[i] and you.branch():lower() == v.value:lower() then
             action = "+"
         end
      end
      if action == "+" then
          activated[#activated + 1] = fm_name
      elseif action == "-" then
          deactivated[#deactivated + 1] = fm_name
      end
      if action ~= nil then
         opt = "force_more_message " .. action .. "= " .. msg
         crawl.setopt(opt)
         active_fm[i] = not active_fm[i]
      end
   end
   if #activated > 0 and notify_fm then
      crawl.mpr("<white>Activating force_mores: " ..
                table.concat(activated, ", ") .. "</white>")
   end
   if #deactivated > 0 and notify_fm then
      crawl.mpr("<white>Deactivating force_mores: " ..
                table.concat(deactivated, ", ") .. "</white>")
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
