local mod_storage = minetest.get_mod_storage()

local class_stats = {
    warrior = {vig = 4, dex = 2, str = 4, cha = 1, int = 1}, -- Total: 12
    knight = {vig = 4, dex = 1, str = 5, cha = 1, int = 1}, -- Total: 12
    mage = {vig = 1, dex = 1, str = 1, cha = 3, int = 6},   -- Total: 12
    builder = {vig = 3, dex = 3, str = 2, cha = 2, int = 2}, -- Total: 12
    miner = {vig = 5, dex = 2, str = 3, cha = 1, int = 1},   -- Total: 12
    rogue = {vig = 2, dex = 6, str = 2, cha = 1, int = 1}    -- Total: 12
}

-- Save player data
local function save_player_data(player_name, character_data)
    mod_storage:set_string(player_name, minetest.serialize(character_data))
end

-- Retrieve character data
local function get_character_data(player_name)
    local character_data = mod_storage:get_string(player_name)
    if character_data and character_data ~= "" then
        local data = minetest.deserialize(character_data)
        -- Ensure that all required fields are initialized
        if data and data.stats then
            data.stats.points_available = data.stats.points_available or 0
            return data
        end
    end
    return nil
end

-- Check if a character name is already taken
local function is_name_taken(character_name)
    local data = mod_storage:to_table()
    for key, serialized_data in pairs(data.fields) do
        local player_data = minetest.deserialize(serialized_data)
        if player_data and player_data.name == character_name then
            return true
        end
    end
    return false
end

minetest.register_on_chat_message(function(name, message)
    local character_data = get_character_data(name)
    local display_name = character_data and character_data.name or name
    minetest.chat_send_all("<" .. display_name .. "> " .. message)
    return true
end)

-- Function to capitalize the first letter of a string
local function capitalize(str)
    return (str:gsub("^%l", string.upper))
end

local function show_character_creation_form(player, message)
    local player_name = player:get_player_name()
    local character_data = get_character_data(player_name) or {
        name = "",
        class = "warrior",  -- Default class is Warrior
        stats = {
            level = 1,
            vig = 0,
            dex = 0,
            str = 0,
            cha = 0,
            int = 0,
            points_available = 12
        }
    }

    local stats = character_data.stats
    local class_points = class_stats[character_data.class]

    if class_points and character_data.class ~= "custom" then
        -- Initialize stats based on class selection if not custom
        stats.vig = class_points.vig
        stats.dex = class_points.dex
        stats.str = class_points.str
        stats.cha = class_points.cha
        stats.int = class_points.int
        stats.points_available = 12 - (stats.vig + stats.dex + stats.str + stats.cha + stats.int)
    else
        -- Custom class or no class selected, reset points
        stats.vig = stats.vig or 0
        stats.dex = stats.dex or 0
        stats.str = stats.str or 0
        stats.cha = stats.cha or 0
        stats.int = stats.int or 0
        stats.points_available = 12 - (stats.vig + stats.dex + stats.str + stats.cha + stats.int)
    end

    local function button_text(class)
        return (class == selected_class and ">> " or "") .. capitalize(class) .. (class == selected_class and " <<" or "")
    end

    -- Generate stats display text
    local stats_display = ""
    if character_data.class ~= "custom" and class_stats[character_data.class] then
        local class_stat = class_stats[character_data.class]
        stats_display = string.format(
            "Class Stats:\nVigor: %d\nDexterity: %d\nStrength: %d\nCharisma: %d\nIntelligence: %d",
            class_stat.vig, class_stat.dex, class_stat.str, class_stat.cha, class_stat.int
        )
    end

    -- Define the formspec with conditional length for custom class
    local formspec = "size[12,14]" ..
                    --"label[1,1;" .. (message or "") .. "]" ..
                    --"field[1,2;10,1;name;Enter your character's name:;" .. (character_data.name or "") .. "]" ..
                    "label[1,3;Select Your Class:]" ..
                    "button[1,4;3,1;warrior;" .. button_text("warrior") .. "]" ..
                    "button[4,4;3,1;knight;" .. button_text("knight") .. "]" ..
                    "button[7,4;3,1;mage;" .. button_text("mage") .. "]" ..
                    "button[1,5;3,1;builder;" .. button_text("builder") .. "]" ..
                    "button[4,5;3,1;miner;" .. button_text("miner") .. "]" ..
                    "button[7,5;3,1;rogue;" .. button_text("rogue") .. "]" ..
                    "button[1,6;3,1;custom;" .. button_text("custom") .. "]" ..
                    "button[9,10;3,1;save;Save]" ..
                    -- Display class stats if not custom
                    (character_data.class ~= "custom" and
                        "label[1,7;" .. stats_display .. "]" ..
                        "label[1,10;Points Available: " .. stats.points_available .. "]"
                    or
                        "label[1,7;Allocate Your Stats (Level: " .. stats.level .. ")]" ..
                        "label[1,8;Points Available: " .. stats.points_available .. "]" ..
                        "label[1,9;Vigor (VIG):]" ..
                        "button[4,9;1,1;vig_decrease;-]" ..
                        "label[5,9;" .. stats.vig .. "]" ..
                        "button[5.3,9;1,1;vig_increase;+]" ..

                        "label[1,10;Dexterity (DEX):]" ..
                        "button[4,10;1,1;dex_decrease;-]" ..
                        "label[5,10;" .. stats.dex .. "]" ..
                        "button[5.3,10;1,1;dex_increase;+]" ..

                        "label[1,11;Strength (STR):]" ..
                        "button[4,11;1,1;str_decrease;-]" ..
                        "label[5,11;" .. stats.str .. "]" ..
                        "button[5.3,11;1,1;str_increase;+]" ..

                        "label[1,12;Charisma (CHA):]" ..
                        "button[4,12;1,1;cha_decrease;-]" ..
                        "label[5,12;" .. stats.cha .. "]" ..
                        "button[5.3,12;1,1;cha_increase;+]" ..

                        "label[1,13;Intelligence (INT):]" ..
                        "button[4,13;1,1;int_decrease;-]" ..
                        "label[5,13;" .. stats.int .. "]" ..
                        "button[5.3,13;1,1;int_increase;+]" ..
                        "button[9,13;3,1;save;Save]" 
                    )

    minetest.show_formspec(player_name, "character_creation:form", formspec)
end


-- Function to update the character class
local function update_character_class(player_name, new_class)
    local character_data = get_character_data(player_name)
    
    if not character_data then
        character_data = {
            name = "",
            class = "warrior",  -- Default class is Warrior
            stats = {
                level = 1,
                vig = 0,
                dex = 0,
                str = 0,
                cha = 0,
                int = 0,
                points_available = 12
            }
        }
    end
    
    -- Update the class and reset stats if necessary
    character_data.class = new_class
    local class_points = class_stats[new_class]
    
    if class_points and new_class ~= "custom" then
        character_data.stats.vig = class_points.vig
        character_data.stats.dex = class_points.dex
        character_data.stats.str = class_points.str
        character_data.stats.cha = class_points.cha
        character_data.stats.int = class_points.int
        character_data.stats.points_available = 12 - (character_data.stats.vig + character_data.stats.dex + character_data.stats.str + character_data.stats.cha + character_data.stats.int)
    else
        -- Custom class or no class selected, reset points
        character_data.stats.vig = 0
        character_data.stats.dex = 0
        character_data.stats.str = 0
        character_data.stats.cha = 0
        character_data.stats.int = 0
        character_data.stats.points_available = 12
    end

    -- Save updated character data
    save_player_data(player_name, character_data)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "character_creation:form" then
        local player_name = player:get_player_name()
        local character_data = get_character_data(player_name) or {
            name = "",
            class = "warrior",
            stats = {
                level = 1,
                vig = 0,
                dex = 0,
                str = 0,
                cha = 0,
                int = 0,
                points_available = 12
            }
        }

        -- Debug: Print all received fields
        --[[for k, v in pairs(fields) do
            minetest.chat_send_player(player_name, "Field: " .. k .. " Value: " .. tostring(v))
        end]]

        -- Handling class selection
        if fields.warrior or fields.knight or fields.mage or fields.builder or fields.miner or fields.rogue or fields.custom then
            selected_class = fields.warrior and "warrior" or
                             fields.knight and "knight" or
                             fields.mage and "mage" or
                             fields.builder and "builder" or
                             fields.miner and "miner" or
                             fields.rogue and "rogue" or
                             "custom"
            update_character_class(player_name, selected_class)
            show_character_creation_form(player, "Class changed to " .. capitalize(selected_class))
        elseif fields.vig_decrease or fields.vig_increase or fields.dex_decrease or fields.dex_increase or fields.str_decrease or fields.str_increase or fields.cha_decrease or fields.cha_increase or fields.int_decrease or fields.int_increase then
            local stat = fields.vig_decrease and "vig" or
                         fields.vig_increase and "vig" or
                         fields.dex_decrease and "dex" or
                         fields.dex_increase and "dex" or
                         fields.str_decrease and "str" or
                         fields.str_increase and "str" or
                         fields.cha_decrease and "cha" or
                         fields.cha_increase and "cha" or
                         fields.int_decrease and "int" or
                         fields.int_increase and "int"
                         
            if stat then
                if fields[stat .. "_decrease"] and character_data.stats[stat] > 0 then
                    character_data.stats[stat] = character_data.stats[stat] - 1
                    character_data.stats.points_available = character_data.stats.points_available + 1
                elseif fields[stat .. "_increase"] and character_data.stats.points_available > 0 then
                    character_data.stats[stat] = character_data.stats[stat] + 1
                    character_data.stats.points_available = character_data.stats.points_available - 1
                end
                save_player_data(player_name, character_data)
                show_character_creation_form(player, "")
            end
        elseif fields.save then
            character_data.name = fields.name or character_data.name
            save_player_data(player_name, character_data)
            show_character_creation_form(player, "Character Saved Successfully, Please press ESC to close...")
            minetest.close_formspec(player_name, "character_creation:form")

        end
    end
end)
-- Show form on player join
minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()
    if not get_character_data(player_name) then
        minetest.after(1, show_character_creation_form, player)
    end
end)

-- Customize chat messages
minetest.register_on_chat_message(function(name, message)
    local character_data = get_character_data(name)
    local display_name = character_data and character_data.name or name
    minetest.chat_send_all("<" .. display_name .. "> " .. message)
    return true
end)

local function show_stats_form(player)
    local player_name = player:get_player_name()
    local character_data = get_character_data(player_name) or {
        name = player_name,
        class = "custom",
        stats = {
            level = 0,
            vig = 0,
            dex = 0,
            str = 0,
            cha = 0,
            int = 0,
            points_available = 0
        }
    }

    local stats = character_data.stats
    local class_defaults = class_stats[character_data.class] or {}
    local formspec = "size[12,13;]" ..  -- Adjusted height for the Save button
                     "label[1,1;Character: " .. character_data.name .. "]" ..
                     "label[1,2;Class: " .. character_data.class .. "]" ..
                     "label[1,3;Level: " .. stats.level .. "]" ..
                     "label[1,4;Points Available: " .. stats.points_available .. "]" ..
                     "label[1,5;Vigor (VIG): " .. stats.vig .. "]" ..
                     "button[4,5;1,1;vig_increase;+]" ..
                     "button[5,5;1,1;vig_decrease;-]" ..
                     "label[1,6;Dexterity (DEX): " .. stats.dex .. "]" ..
                     "button[4,6;1,1;dex_increase;+]" ..
                     "button[5,6;1,1;dex_decrease;-]" ..
                     "label[1,7;Strength (STR): " .. stats.str .. "]" ..
                     "button[4,7;1,1;str_increase;+]" ..
                     "button[5,7;1,1;str_decrease;-]" ..
                     "label[1,8;Charisma (CHA): " .. stats.cha .. "]" ..
                     "button[4,8;1,1;cha_increase;+]" ..
                     "button[5,8;1,1;cha_decrease;-]" ..
                     "label[1,9;Intelligence (INT): " .. stats.int .. "]" ..
                     "button[4,9;1,1;int_increase;+]" ..
                     "button[5,9;1,1;int_decrease;-]" ..
                     "button[4,10;2,1;save;Save]"  -- Added Save button

    minetest.show_formspec(player_name, "character_creation:stats", formspec)
end

local function adjust_stat(stats, stat, increase, class_defaults)
    local default_value = class_defaults[stat] or 0
    if increase then
        if stats.points_available > 0 then
            stats[stat] = (stats[stat] or default_value) + 1
            stats.points_available = stats.points_available - 1
            print("Increased " .. stat .. " to " .. stats[stat])
        else
            print("No points available to increase " .. stat)
        end
    else
        if stats[stat] and stats[stat] > default_value then
            stats[stat] = stats[stat] - 1
            stats.points_available = stats.points_available + 1
            print("Decreased " .. stat .. " to " .. stats[stat])
        else
            print("Cannot decrease " .. stat .. " below default value")
        end
    end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "character_creation:stats" then
        local player_name = player:get_player_name()
        local character_data = get_character_data(player_name) or {
            name = player_name,
            class = "custom",
            stats = {
                level = 0,
                vig = 0,
                dex = 0,
                str = 0,
                cha = 0,
                int = 0,
                points_available = 0
            }
        }

        local stats = character_data.stats
        local class_defaults = class_stats[character_data.class] or {}

        -- Increase or decrease stats based on button clicks
        if fields.vig_increase then
            adjust_stat(stats, "vig", true, class_defaults)
        elseif fields.vig_decrease then
            adjust_stat(stats, "vig", false, class_defaults)
        end

        if fields.dex_increase then
            adjust_stat(stats, "dex", true, class_defaults)
        elseif fields.dex_decrease then
            adjust_stat(stats, "dex", false, class_defaults)
        end

        if fields.str_increase then
            adjust_stat(stats, "str", true, class_defaults)
        elseif fields.str_decrease then
            adjust_stat(stats, "str", false, class_defaults)
        end

        if fields.cha_increase then
            adjust_stat(stats, "cha", true, class_defaults)
        elseif fields.cha_decrease then
            adjust_stat(stats, "cha", false, class_defaults)
        end

        if fields.int_increase then
            adjust_stat(stats, "int", true, class_defaults)
        elseif fields.int_decrease then
            adjust_stat(stats, "int", false, class_defaults)
        end

        -- Save updated data
        save_player_data(player_name, character_data)

        if fields.save then
            save_player_data(player_name, character_data)
            minetest.chat_send_player(player_name, "Character saved successfully!")
            minetest.close_formspec(player_name, "character_creation:stats")
        end

        show_stats_form(player)
    end
end)


minetest.register_chatcommand("attributes", {
    description = "Show your current stats and points",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            show_stats_form(player)
        end
    end
})

-- Command to give stat points to a player
minetest.register_chatcommand("give_points", {
    params = "<player> <amount>",
    description = "Give stat points to a player. Usage: /give_points <player> <amount>",
    privs = {server = true}, -- Only server admins can use this command
    func = function(name, param)
        local player_name, amount = param:match("^(%S+)%s(%d+)$")
        amount = tonumber(amount)

        if not player_name or not amount then
            return false, "Invalid parameters. Usage: /give_points <player> <amount>"
        end

        -- Ensure amount is positive
        if amount <= 0 then
            return false, "Amount must be positive."
        end

        local character_data = get_character_data(player_name)
        if not character_data then
            return false, "Player does not have character data."
        end

        local stats = character_data.stats
        stats.points_available = (stats.points_available or 0) + amount

        save_player_data(player_name, character_data)
        return true, "Added " .. amount .. " points to " .. player_name .. "'s available points."
    end
})

-- Refresh the player's stats form when points are added
local function refresh_player_stats_form(player)
    minetest.after(0, function()
        show_stats_form(player)
    end)
end

minetest.register_on_chat_message(function(name, message)
    -- If the chat message is the command, refresh the stats form
    if message:match("^/give_points") then
        local player = minetest.get_player_by_name(name)
        if player then
            refresh_player_stats_form(player)
        end
    end
end)
