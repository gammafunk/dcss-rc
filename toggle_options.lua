-----------------------------
---- Begin toggle_options ---
-----------------------------

-- See README.md for documentation.

-- Wrapper of crawl.mpr() that prints text in white by default.
if not mpr then
    mpr = function (msg, color)
        if not color then
            color = "white"
        end
        crawl.mpr("<" .. color .. ">" .. msg .. "</" .. color .. ">")
    end
end

function set_option_group_state(group, is_enabled, verbose)
    if not group then
        return
    end

    found = false
    state_key = is_enabled and "on" or "off"
    for g,opts in pairs(option_groups) do
        if group == g then
            for i, opt in ipairs(opts) do
                local opt_val = opt.option:gsub("%%t", opt[state_key])
                crawl.setopt(opt_val)
            end
            c_persist.enabled_options[group] = is_enabled
            found = true
            break
        end
    end
    if not found then
        mpr("Error: Unable to find option group '" .. group .. "'.")
        return
    end
    if verbose then
        local verb = is_enabled and "Enabling" or "Disabling"
        mpr(verb .. " option group '" .. group .. "'.")
    end
end

function toggle_options(group)
    if not group then
        return
    end

    if c_persist.enabled_options[group] then
        set_option_group_state(group, false, true)
    else
        set_option_group_state(group, true, true)
    end
end


function init_toggle_options()
    if not c_persist.enabled_options then
        c_persist.enabled_options = {}
    end

    if not option_groups then
        mpr("Error: option_groups table undefined.", "lightred")
        return
    end

    for group,_ in pairs(option_groups) do
        -- Create the toggle function
        local toggle_func = function()
            toggle_options(group)
        end
        _G["toggle_" .. group .. "_options"] = toggle_func
        local is_enabled = false
        for g,e in pairs(c_persist.enabled_options) do
            if g == group then
                is_enabled = e
                break
            end
        end
        -- Call this even if is_enabled is false to make sure we override any
        -- options enabled in the rc outside of toggle_options. This makes the
        -- notion of "on" and "off" at least consistent. The user should define
        -- their option_groups entries so that the "off" state is what they'd
        -- want by default and not try to duplicate any of the "on" state
        -- settings elsewhere in their rc.
        set_option_group_state(group, is_enabled)
    end
end

init_toggle_options()

---------------------------
---- End toggle_options ---
---------------------------
