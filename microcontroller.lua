local Compiler = require('compiler')
local Entity = require("stdlib/entity/entity")
require('constants')

local PSTATE_HALTED = 0
local PSTATE_RUNNING = 1
local PSTATE_SLEEPING = 2
local PSTATE_SYNC = 3

function linepairs(s)
    if s:sub(-1)~="\n" then s=s.."\n" end
    return s:gmatch("(.-)\n")
end

local microcontroller = {}

microcontroller.event_error = script.generate_event_name()
microcontroller.event_halt = script.generate_event_name()

function microcontroller.init( mc, state )
    state.program_lines = {}
    state.program_text = ""
    state.program_counter = 1
    state.program_ast = {}
    state.program_state = PSTATE_HALTED
    Entity.set_data(mc, state)

    local control = mc.get_or_create_control_behavior()
    control.parameters = {
        parameters = {
            first_signal = nil,
            second_signal = nil,
            first_constant = 0,
            second_constant = 1,
            operation = "*",
            output_signal = NULL_SIGNAL.signal
        }
    }
    microcontroller.init_memory(mc, state)
end

function microcontroller.init_memory( mc, state )
    if state.memory == nil then
        state.memory = {}
        for i = 1, 4 do
            state.memory[i] = NULL_SIGNAL
        end
    end
    if not state.clock then
        state.clock = 1
    end
    if not state.adjacent_modules then
        state.adjacent_modules = {}
        for i = 1, 4 do
            state.adjacent_modules[i] = nil
        end
    end
end

function microcontroller.update_program_text( mc, program_text )
    local state = Entity.get_data(mc)
    state.program_text = program_text
    Entity.set_data(mc, state)
end

function microcontroller.attach_module( mc, module, direction )
    local state = Entity.get_data(mc)
    if not state then
        state = {}
        microcontroller.init(mc, state)
        microcontroller.init_memory(mc, state)
    end
    if mc.last_user then
        mc.last_user.print("Attached module to MicroController. Memory mapped to mem"..(direction*10 + 1).."-mem"..(direction*10+4)..".")
    end
    state.adjacent_modules[direction] = module
    Entity.set_data(mc, state)
end

function microcontroller.compile( mc, state )
    local program_lines = {}
    for line in linepairs(state.program_text) do
        table.insert(program_lines, line)
    end
    state.program_ast = Compiler.compile(program_lines)
    Entity.set_data(mc, state)
end

function microcontroller.set_error_message( mc, state, error_message )
    state.error_message = "line "..state.program_counter..": "..(error_message or "")
    state.error_line = state.program_counter
    script.raise_event(microcontroller.event_error, {entity = mc, ['state'] = state, message = state.error_message})
end

function microcontroller.set_program_counter( mc, state, value )
    state.program_counter = value
    if #state.program_ast == 0 or state.program_counter > #state.program_ast then
        state.program_counter = 1
        state.program_state = PSTATE_HALTED
        state.do_step = false
        script.raise_event(microcontroller.event_halt, {entity = mc, ['state'] = state})
    else
        local next_ast = state.program_ast[state.program_counter]
        while(next_ast and (next_ast.type == 'nop' or next_ast.type == 'label')) do
            state.program_counter = state.program_counter + 1
            if state.program_counter > #state.program_ast then
                break
            end
            next_ast = state.program_ast[state.program_counter]
        end
        if state.program_counter > #state.program_ast then
            state.program_state = PSTATE_HALTED
            state.do_step = false
            script.raise_event(microcontroller.event_halt, {entity = mc, ['state'] = state})
        end
    end
end

function microcontroller.tick( mc, state )
    microcontroller.init_memory(mc, state)
    state.clock = state.clock + 1

    -- Interrupts
    local control = mc.get_control_behavior()
    local red_input = control.get_circuit_network(defines.wire_type.red, defines.circuit_connector_id.combinator_input)
    local green_input = control.get_circuit_network(defines.wire_type.green, defines.circuit_connector_id.combinator_input)
    local get_signal = function(signal)
        if red_input then
            local result = red_input.get_signal(signal.signal)
            if result ~= nil then
                return result
            end
        end
        if green_input then
            local result = green_input.get_signal(signal.signal)
            if result ~= nil then
                return result
            end
        end
        return 0
    end
    if state.program_state == PSTATE_RUNNING and get_signal(HALT_SIGNAL) > 0 then
        microcontroller.halt(mc, state)
    end
    if state.program_state == PSTATE_HALTED and get_signal(RUN_SIGNAL) > 0 then
        microcontroller.run( mc, state, state.program_counter )
    end
    if state.program_state == PSTATE_HALTED and get_signal(STEP_SIGNAL) > 0 then
        microcontroller.step( mc, state )
    end
    if state.program_state == PSTATE_RUNNING and get_signal(SLEEP_SIGNAL) > 0 then
        local value = get_signal(SLEEP_SIGNAL)
        if value then
            state.program_state = PSTATE_SLEEPING
            state.sleep_time = value
        end
    end
    if get_signal(JUMP_SIGNAL) > 0 then
        local value = get_signal(JUMP_SIGNAL)
        if value then
            microcontroller.set_program_counter(mc, state, value)
        end
    end
    
    -- Run microcontroller code.
    if state.program_state == PSTATE_RUNNING then
        local ast = state.program_ast[state.program_counter]
        local success, result = Compiler.eval(ast, control, state)
        if not success then
            microcontroller.set_error_message(mc, state, result)
            microcontroller.halt(mc, state)
        elseif result then
            if result.type == 'halt' then
                microcontroller.halt(mc, state)
                microcontroller.set_program_counter(mc, state, state.program_counter + 1)
            elseif result.type == 'sleep' then
                state.program_state = PSTATE_SLEEPING
                state.sleep_time = result.val
            elseif result.type == 'jump' then
                if result.label then
                    for line_num, node in ipairs(state.program_ast) do
                        if node.type == 'label' and node.label == result.label then
                            microcontroller.set_program_counter(mc, state, line_num + 1)
                            break
                        end
                    end
                else
                    microcontroller.set_program_counter(mc, state, result.val)
                end
            elseif result.type == 'skip' then
                microcontroller.set_program_counter(mc, state, state.program_counter + 2)
            elseif result.type == 'sync' then
                state.program_state = PSTATE_SYNC
            elseif result.type == 'block' then
                -- Do nothing, keeping the program_counter the same.
            end
        else
            microcontroller.set_program_counter(mc, state, state.program_counter + 1)
        end
    elseif state.program_state == PSTATE_SLEEPING then
        state.sleep_time = state.sleep_time - 1
        if state.sleep_time <= 1 then
            state.program_state = PSTATE_RUNNING
            microcontroller.set_program_counter(mc, state, state.program_counter + 1)
        end
    elseif state.program_state == PSTATE_SYNC then
        local all_sync = true
        for i, module in pairs(state.adjacent_modules) do
            if module.name == "microcontroller" then
                local other_state = Entity.get_data(module)
                if other_state.program_state ~= PSTATE_SYNC then
                    all_sync = false
                    break
                end
            end
        end
        if all_sync then
            microcontroller.set_program_counter(mc, state, state.program_counter + 1)
            state.program_state = PSTATE_RUNNING
            for i, module in pairs(state.adjacent_modules) do
                if module.name == "microcontroller" then
                    local other_state = Entity.get_data(module)
                    microcontroller.set_program_counter(module, other_state, other_state.program_counter + 1)
                    other_state.program_state = PSTATE_RUNNING
                end
            end
        end
    end

    if state.do_step and state.program_state == PSTATE_RUNNING then
        state.do_step = false
        microcontroller.halt(mc, state)
    end

    Entity.set_data(mc, state)
end

function microcontroller.run( mc, state )
    state.program_state = PSTATE_RUNNING
    -- if line == nil then
    --     microcontroller.set_program_counter(mc, state, 1)
    --     state.program_counter = 1
    -- else
    --     if line > #state.program_ast then
    --         line = 1
    --     end
    --     microcontroller.set_program_counter(mc, state, line)
    -- end
    state.error_message = nil
    state.error_line = nil
    state.do_step = false
    Entity.set_data(mc, state)
end

function microcontroller.step( mc, state )
    if state.program_counter > #state.program_ast then
        microcontroller.set_program_counter(mc, state, 1)
    end
    state.program_state = PSTATE_RUNNING
    state.do_step = true
    state.error_message = nil
    state.error_line = nil
    Entity.set_data(mc, state)
end

function microcontroller.halt( mc, state )
    if state.program_state == PSTATE_HALTED then
        microcontroller.set_program_counter(mc, state, 1)
    end
    state.program_state = PSTATE_HALTED
    state.do_step = false
    Entity.set_data(mc, state)
    script.raise_event(microcontroller.event_halt, {entity = mc, ['state'] = state})
end

function microcontroller.is_running( mc )
    return Entity.get_data(mc).program_state ~= PSTATE_HALTED
end

return microcontroller