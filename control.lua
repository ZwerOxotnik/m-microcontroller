require('mod-gui')
local Entity = require("stdlib/entity/entity")
local Surface = require("stdlib/surface")
local microcontroller = require('microcontroller')
require('stdlib/string')
require('constants')
require('stdlib/area/tile')

function get_player_data(player_index)
    if global.player_data == nil then
        global.player_data = {}
    end
    local player_data = global.player_data[player_index] or {}
    return player_data
end

function set_player_data(player_index, data)
    if global.player_data == nil then
        global.player_data = {}
    end
    global.player_data[player_index] = data
end

-- Handle MicroController OPEN event.
script.on_event("open-gui", function(event)
    local player_index = event.player_index
    local player = game.get_player(player_index)
    if not (player and player.valid) then return end
    local entity = player.selected
    if not (entity and entity.valid) then return end

    if entity.name == "microcontroller" then
        entity.operable = false
        local player_data = get_player_data(player_index)
        player_data.open_microcontroller = entity
        set_player_data(player_index, player_data)
        microcontrollerGui(player, entity)
    end
end)

local function check_adjacency_microcontroller(offset, index)
    if offset >= 0 and index == 1 then
        return 1
    elseif offset >= 0 and index == 2 then
        return 2
    elseif offset < 0 and index == 1 then
        return 3
    else
        return 4
    end
end

local function attach_microcontroller(entity)
    local adjacent = {{x = entity.position.x, y = entity.position.y + 1}, {x = entity.position.x, y = entity.position.y - 1}}
    local inverse = {2, 1, 3, 4}
    -- Iterate over adjacent positions.
    for index, pos in pairs(adjacent) do
        -- Check if there is a MicroController adjacent.
        local mc = entity.surface.find_entity("microcontroller", pos)
        if mc then
            index = check_adjacency_microcontroller(mc.position.x - pos.x, index)
            microcontroller.attach_module(mc, entity, index)
            microcontroller.attach_module(entity, mc, inverse[index])
        end
    end
end


local function attach_microcontroller_ram(entity)
    local adjacent = {{x = entity.position.x, y = entity.position.y + 1}, {x = entity.position.x, y = entity.position.y - 1}}
    -- Iterate over adjacent positions.
    for index, pos in pairs(adjacent) do
        -- Check if there is a MicroController adjacent.
        local mc = entity.surface.find_entity("microcontroller", pos)
        if mc then
            index = check_adjacency_microcontroller(mc.position.x - pos.x, index)
            microcontroller.attach_module(mc, entity, index)
        end
    end
end

-- Handle Entity built event.
script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity}, function(event)
    local entity = event.created_entity
    if not (entity and entity.valid) then return end

    if entity.name == "microcontroller" then
        -- Init and insert new microcontroller to global state.
        microcontroller.init(entity, {})
        local didFind = false
        for _, mc in ipairs(global.microcontrollers) do
            if mc == entity then
                didFind = true
            end
        end
        if not didFind then
            table.insert(global.microcontrollers, entity)
        end

        attach_microcontroller(entity)
    elseif entity.name == "microcontroller-ram" then
        attach_microcontroller_ram(entity)
    end
end)

-- Handle Entity settings pasted event.
script.on_event({defines.events.on_entity_settings_pasted}, function(event)
    local source = event.source
    local destination = event.destination

    if source.name == "microcontroller" and destination.name == source.name then
        Entity.set_data(destination, Entity.get_data(source)) -- TODO: test it
    end
end)

-- Handle MicroController GUI Close event.
script.on_event("microcontroller-close", function(event)
    local player_index = event.player_index
    local player = game.get_player(player_index)
    if not (player and player.valid) then return end

    local player_data = get_player_data(player_index)
    if player_data.open_microcontroller_gui then
        microcontroller.update_program_text(player_data.open_microcontroller, player_data.open_microcontroller_gui.outer.scroll_pane.inner['program-input'].text)
        player_data.open_microcontroller_gui.destroy()
        player_data.open_microcontroller_gui = nil
    end
    local docs = player.gui.center['mc-docs']
    if docs then
        docs.destroy()
    end
    set_player_data(player_index, player_data)
end)

-- Handle GUI text changed event.
script.on_event(defines.events.on_gui_text_changed, function(event)
    local player_data = get_player_data(event.player_index)
    local element = event.element
    if element.name and element.name == "program-input" then
        local lines = string.split(element.text, '\n', false)
        local mc_lines=microcontroller.get_max_lines(game.players[event.player_index].force)
        if #lines > mc_lines then
            for i = 1, #lines - mc_lines do
                table.remove(lines, #lines)
            end
            element.text = table.concat(lines, '\n')
        end
        microcontroller.update_program_text(player_data.open_microcontroller, element.text)
    end
    set_player_data(event.player_index, player_data)
end)

local function update_topics_gui(gui)
    gui.clear()
    local doc = DOCS[gui.parent.parent.mc_doc_list.selected_index]
    local topics = doc.content
    gui.add{type = "label", caption = {"microcontroller.hover-text-hint"}, tooltip = {"microcontroller.doc." .. doc.name .. "_description"}}
    gui.add{type = "label"}
    for _, topic in pairs(topics) do
        if topic.name then
            if topic.syntax then
                gui.add{type = "label", caption = {"microcontroller.topics." .. topic.name}, tooltip = {"microcontroller.topics." .. topic.name .. "_description"}}
                gui.add{type = "label", caption = {"", {"microcontroller.syntax"}, {"colon"}, " " .. topic.syntax}}
            else
                gui.add{type = "label", caption = {"microcontroller.topics." .. topic.name}, tooltip = {"microcontroller.topics." .. topic.name .. "_description"}}
            end
        end
        if topic.example then
            gui.add{type = "label", caption = {"", {"microcontroller.example"}, {"colon"}}}
            local textbox = gui.add{type = "text-box", text = topic.example}
            textbox.read_only = true
            local style = textbox.style
            style.maximal_width = 0
            style.minimal_height = 60
            style.maximal_height = 140
            style.horizontally_stretchable = true
            style.vertically_stretchable = true
            style.height = 130
        end
    end
end



-- Handle selection in GUI.
script.on_event(defines.events.on_gui_selection_state_changed, function(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then return end
    local element = event.element
    if not (element and element.valid and element.name) then return end

    if element.name == "mc_doc_list" then
        update_topics_gui(element.parent.mc_scroll_pane.mc_topics_gui)
    end
end)

-- Handle GUI button presses.
script.on_event(defines.events.on_gui_click, function(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then return end
    local element = event.element
    local player_data = get_player_data(event.player_index)
    if element and element.valid and element.name then
        -- RUN button pressed:
        if element.name == "run-program" then
            local mc_state = Entity.get_data(player_data.open_microcontroller)
            element.parent.parent.error_message.caption = ""
            microcontroller.compile(player_data.open_microcontroller, mc_state)
            microcontroller.run(player_data.open_microcontroller, mc_state)
        -- HALT button pressed:
        elseif element.name == "halt-program" then
            local mc_state = Entity.get_data(player_data.open_microcontroller)
            microcontroller.halt(player_data.open_microcontroller, mc_state)
        -- STEP button pressed:
        elseif element.name == "step-program" then
            local mc_state = Entity.get_data(player_data.open_microcontroller)
            element.parent.parent.error_message.caption = ""
            microcontroller.compile(player_data.open_microcontroller, mc_state)
            microcontroller.step(player_data.open_microcontroller, mc_state)
        -- CLOSE button pressed:
        elseif element.name == "close-microcontroller-window" then
            microcontroller.update_program_text(player_data.open_microcontroller, player_data.open_microcontroller_gui.outer.scroll_pane.inner['program-input'].text)
            player_data.open_microcontroller_gui.destroy();
            player_data.open_microcontroller_gui = nil
            if player.gui.center['mc-docs'] then
                player.gui.center['mc-docs'].destroy()
            end
        -- COPY button pressed:
        elseif element.name == "copy-program" then
            player_data.program_clipboard = player.gui.left.microcontroller.outer.scroll_pane.inner['program-input'].text
        -- PASTE button pressed:
        elseif element.name == "paste-program" and player_data.program_clipboard then
            player_data.open_microcontroller_gui.outer.scroll_pane.inner['program-input'].text = player_data.program_clipboard
        -- SHOW/HIDE DOCS button pressed:
        elseif element.name == "mc-help-button" then
            if player.gui.screen['mc-docs'] then
                player.gui.screen['mc-docs'].destroy()
            else
                local docs_frame = player.gui.screen.add{type = "frame", name = "mc-docs", caption = {"microcontroller.wiki"}}
                docs_frame.style.maximal_width = 0
                docs_frame.style.maximal_height = 300
                docs_frame.style.horizontally_stretchable = true
                local doc_table = docs_frame.add{type = "table", name = "mc_doc_table", vertical_centering = false, column_count = 2}
                doc_table.style.maximal_width = 0
                doc_table.style.horizontally_stretchable = true
                doc_table.style.horizontal_align = "left"

                local items = {}
                for _, doc in pairs(DOCS) do
                    items[#items+1] = {"microcontroller.doc." .. doc.name}
                end
                local doc_list = doc_table.add{type = "list-box", name = "mc_doc_list", items = items, selected_index = 1}
                doc_list.style.maximal_width = 140
                doc_list.style.horizontally_stretchable = true

                local scroll_pane = doc_table.add{type = "scroll-pane", name = "mc_scroll_pane"}
                local topics_gui = scroll_pane.add{type = "table", name = "mc_topics_gui", column_count = 1}
                topics_gui.style.maximal_width = 0
                topics_gui.style.horizontally_stretchable = true
                topics_gui.style.width = 350
                update_topics_gui(topics_gui)
            end
        end
    end
    set_player_data(event.player_index, player_data)
end)

-- Handle MicroController ERROR event.
script.on_event(microcontroller.event_error, function(event)
    local mc = event.entity
    local mc_state = event.state
    for _, player in pairs(game.players) do
        local player_data = get_player_data(player.index)
        if player_data.open_microcontroller_gui then
            -- Display error message.
            player_data.open_microcontroller_gui.outer.error_message.caption = event.message
        end
    end
end)

-- Handle MicroController HALT event.
script.on_event(microcontroller.event_halt, function(event)
    local mc = event.entity
    local mc_state = event.state
    for _, player in pairs(game.players) do
        local player_data = get_player_data(player.index)
        if player.opened == player_data.open_microcontroller and player_data.open_microcontroller then
            local state = Entity.get_data(player_data.open_microcontroller)
            player.opened = nil
            Entity.set_data(player_data.open_microcontroller, state)
        end
    end
end)

local function signalToSpritePath(signal)
    if signal.type == "virtual" then
        return "virtual-signal/" .. signal.name
    else
        return signal.type .. '/' .. signal.name
    end
end

local update_tick_time = settings.startup["mc_update_tick_time"].value
script.on_nth_tick(update_tick_time, function()
    -- Ensure we have a table to store microcontrollers in the global state.
    if not global.microcontrollers then
        global.microcontrollers = {}
    end

    local do_update_gui = true
    if update_tick_time < 30 then
        do_update_gui = (game.tick % 60 == 0)
    end

    -- Iterate through all stored microcontrollers.
    for i = #global.microcontrollers, 1, -1 do
        local mc = global.microcontrollers[i]
        if mc.valid then
            local mc_state = Entity.get_data(mc)
            if mc_state then
                -- Enable/Disable the run/step button.
                if mc_state.gui_run_button and mc_state.gui_run_button.valid then
                    if microcontroller.is_running(mc) then
                        mc_state.gui_run_button.enabled = false
                        mc_state.gui_step_button.enabled = false
                    else
                        mc_state.gui_run_button.enabled = true
                        mc_state.gui_step_button.enabled = true
                    end
                end
                -- Make text read-only while running
                if mc_state.gui_program_input and mc_state.gui_program_input.valid then
                    mc_state.gui_program_input.read_only = microcontroller.is_running(mc)
                end

                if do_update_gui then
                    -- Update the program lines in the GUI.
                    if mc_state.gui_line_numbers and mc_state.gui_line_numbers.valid then
                        updateLines(mc_state.gui_line_numbers, mc_state, mc.force)
                    end

                    -- Update the inspector GUI.
                    if mc_state.inspector and mc_state.inspector.valid then
                        for i = 1, 4 do -- TODO: check with various entites
                            mc_state.inspector['mem'..i..'-inspect'].sprite = signalToSpritePath( mc_state.memory[i].signal)
                            mc_state.inspector['mem'..i..'-inspect'].number = mc_state.memory[i].count
                        end
                    end
                end

                -- Check adjacent modules still exists.
                if mc_state.adjacent_modules ~= nil then
                    for i = 4, 1, -1 do
                        local module = mc_state.adjacent_modules[i]
                        if module and not module.valid then
                            mc_state.adjacent_modules[i] = nil
                        end
                    end
                end
                -- Tick the microcontroller.
                microcontroller.tick(mc, mc_state)
            end
        else
            -- Microcontroller no longer exists, remove from global state.
            for player_index, player in pairs(game.players) do
                local player_data = get_player_data(player_index)
                if player_data.open_microcontroller_gui and player_data.open_microcontroller_gui.valid then
                    player_data.open_microcontroller_gui.destroy()
                    player_data.open_microcontroller_gui = nil
                end
                if player.gui.center['mc-docs'] then
                    player.gui.center['mc-docs'].destroy()
                end
                set_player_data(player_index, player_data)
            end
            table.remove(global.microcontrollers, i)
        end
    end
end)

function updateLines(element, state, force)
    local lines = {}
    for i = 1, microcontroller.get_max_lines(force) do
        local line = tostring(i)
        if i < 10 then line = "0"..i end
        if i == state.error_line then
            line = '!'..line
        elseif i == state.program_counter then
            line = '>'..line
        else
            line = ' '..line
        end
        lines[#lines+1] = line
    end
    element.text = table.concat( lines, "\n" )
end

function microcontrollerGui( player, entity )
    local leftGui = player.gui.left
    if leftGui.microcontroller then
        leftGui.microcontroller.destroy()
    end
    local state = Entity.get_data(entity)
    local player_data = get_player_data(player.index)

    local gWindow = leftGui.add{type = "frame", name = "microcontroller", caption = "Microcontroller"}
    player_data.open_microcontroller_gui = gWindow
    local outerflow = gWindow.add{type = "table", name = "outer", column_count = 1}

    local buttons_row = outerflow.add{type = "flow", name = "buttons_row", column_count = 1}
    state.gui_run_button = buttons_row.add{type = "sprite-button", name = "run-program", sprite = "microcontroller-play-sprite"}
    state.gui_step_button = buttons_row.add{type = "sprite-button", name = "step-program", sprite = "microcontroller-next-sprite"}
    state.gui_halt_button = buttons_row.add{type = "sprite-button", name = "halt-program", sprite = "microcontroller-stop-sprite"}
    state.gui_copy_button = buttons_row.add{type = "sprite-button", name = "copy-program", sprite = "microcontroller-copy-sprite"}
    state.gui_paste_button = buttons_row.add{type = "sprite-button", name = "paste-program", sprite = "microcontroller-paste-sprite"}
    buttons_row.add{type = "sprite-button", name = "mc-help-button", sprite = "microcontroller-info-sprite"}
    state.gui_exit_button = buttons_row.add{type = "sprite-button", name = "close-microcontroller-window", sprite = "microcontroller-exit-sprite"}

    local scroll_pane = outerflow.add{type = "scroll-pane", name = "scroll_pane"}
    scroll_pane.style.maximal_height = 455
    local flow = scroll_pane.add{type = "table", name = "inner", column_count = 2}
    flow.style.horizontally_stretchable = true

    state.gui_line_numbers = flow.add{type = "text-box", style = "mc_notice_textbox", ignored_by_interaction = true}
    local style = state.gui_line_numbers.style
    style.font_color = {r = 0.9, g = 0.9, b = 0.975}
    style.horizontally_stretchable = false
    style.vertically_stretchable = false
    style.maximal_width = 40
    updateLines(state.gui_line_numbers, state, player.force)

    local textbox = flow.add{type = "text-box", name = "program-input", style = "mc_program_input"}
    textbox.text = state.program_text
    state.gui_program_input = textbox

    if microcontroller.is_running(entity) then
        state.gui_run_button.enabled = false
    else
        state.gui_run_button.enabled = true
    end

    outerflow.add{type = "label", name = "error_message", caption = "", style = "bold_red_label"}

    local inspectorflow = outerflow.add{type = "frame", direction = "horizontal"}
    inspectorflow.style.horizontally_stretchable = true
    inspectorflow.style.width = 368
    inspectorflow.style.left_padding = 64
    -- inspectorflow.style.right_padding = 64
    -- inspectorflow.style.minimal_width = 172
    -- inspectorflow.style.maximal_width = 0
    for i = 1, 4 do
        local sb = inspectorflow.add{type = "sprite-button", name = "mem"..i.."-inspect", tooltip = "mem"..i}
        sb.style.horizontally_stretchable = true
        sb.style.horizontal_align = "right"
    end
    state.inspector = inspectorflow

    Entity.set_data(entity, state)
    set_player_data(player.index, player_data)
end

script.on_configuration_changed(function(event)
    local mod_changes = event.mod_changes["m-microcontroller"]
    if not (mod_changes and mod_changes.old_version) then return end

    local version = tonumber(string.gmatch(mod_changes.old_version, "%d+.%d+")())
    if version <= 0.9 then
        for _, mc in pairs(global.microcontrollers) do
            if mc.valid then
                local control_behavior = mc.get_control_behavior()
                if control_behavior.parameters.second_constant == 0 then
                    local params = table.deepcopy(control_behavior.parameters) -- it worked before without this
                    params.second_constant = 1
                    control_behavior.parameters = params
                end
            end
        end
    end
end)
