----------------------------
---- Begin load_message ----
----------------------------

-- Leave a message on save that will be displayed next time the player
-- loads the game. To enable in your rc, add a lua code block with the
-- contents of *load_message.lua*, add a call to `load_message()` in
-- your `ready()` function, and make a macro binding 'S' to
-- `===save_with_message`. Original code by elliptic with some
-- reorganization.

local message_color = "white"

function save_with_message()
  if you.turns() == 0 then
    crawl.sendkeys("S")
    return
  end
  crawl.formatted_mpr("Save game and exit?", "prompt")
  local res = crawl.getch()
  if not (string.char(res) == "y" or string.char(res) == "Y") then
    crawl.formatted_mpr("Okay, then.", "prompt")
    return
  end
  crawl.formatted_mpr("Leave a message: ", "prompt")
  local res = crawl.c_input_line()
  c_persist.message = res
  crawl.sendkeys(control("s"))
end

function load_message()
  if c_persist.message and c_persist.message ~= "nil"
     and c_persist.message ~= "" then
        crawl.mpr("<" .. message_color .. ">" .. "MESSAGE: " ..
                  c_persist.message .. "</" .. message_color .. ">")
    c_persist.message = nil
  end
end

-----------------------------------
---- End leave message on save ----
-----------------------------------
