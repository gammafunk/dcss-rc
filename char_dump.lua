-------------------------
---- Begin char_dump ----
-------------------------

-- Make a character dump every N turns (default of 1000).  To enable in your
-- rc, add a lua code block with the contents of *char_defaults.lua* and a call
-- to `char_defaults()` in your `ready()` function.

local dump_count = you.turns()
local _ = you.turns()

function char_dump()
  if you.turns() >= dump_count then
    dump_count = dump_count + 1000
    crawl.dump_char()
  end
end

-----------------------
---- End char_dump ----
-----------------------
