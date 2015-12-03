-----------------------------
---- Begin toggle_options ---
-----------------------------

-- Wrapper of crawl.mpr() that prints text in white by default.
if not mpr then
    mpr = function (msg, color)
        if not color then
            color = "white"
        end
        crawl.mpr("<" .. color .. ">" .. msg .. "</" .. color .. ">")
    end
end

function set_option_group_state(group, enable, verbose)
    if not group then
        return
    end

    found = false
    state_key = enable and "on" or "off"
    for g,opts in pairs(option_groups) do
        if group == g then
            for i, opt in ipairs(opts) do
                local opt_val = opt.option:gsub("%%t", opt[state_key])
                crawl.setopt(opt_val)
            end
            c_persist.enabled_options[group] = enable
            found = true
            break
        end
    end
    if not found then
        mpr("Error: Unable to find option group '" .. group .. "'.")
        return
    end
    if verbose then
        local verb = enable and "Enabling" or "Disabling"
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
        local found = false
        for g,enabled in pairs(c_persist.enabled_options) do
            if group == g then
                local toggle_func = function()
                    toggle_options(g)
                end
                _G["toggle_" .. g .. "_options"] = toggle_func
                if enabled then
                    set_option_group_state(g, true, false)
                end
                found = true
                break
            end
        end
        if not found then
            c_persist.enabled_options[group] = false
        end
    end
end

init_toggle_options()

---------------------------
---- End toggle_options ---
---------------------------
