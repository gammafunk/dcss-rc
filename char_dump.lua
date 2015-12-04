-------------------------
---- Begin char_dump ----
-------------------------

-- See README.md for documentation.

local dump_count = you.turns()
local dump_period = 1000

function char_dump()
    if you.turns() >= dump_count then
        dump_count = dump_count + dump_period
        crawl.dump_char()
    end
end

-----------------------
---- End char_dump ----
-----------------------
