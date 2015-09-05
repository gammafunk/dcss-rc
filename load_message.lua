----------------------------
---- Begin load_message ----
----------------------------

-- Leave a message on save that will be displayed next time the player
-- loads the game. To enable in your rc, add a lua code block with the
-- contents of *load_message.lua*, add a call to `load_message()` in
-- your `ready()` function, and make a macro binding 'S' to
-- `===save_with_message`. Original code by elliptic with some
-- reorganization.

message_color = "white"

-- Wrapper of crawl.mpr() that prints text in white by default.
if not mpr then
    mpr = function (msg, color)
        if not color then
            color = "white"
        end
        crawl.mpr("<" .. color .. ">" .. msg .. "</" .. color .. ">")
    end
end

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
        mpr("MESSAGE: " .. c_persist.message, message_color)
        c_persist.message = nil
    end
end

-----------------------------------
---- End leave message on save ----
-----------------------------------
