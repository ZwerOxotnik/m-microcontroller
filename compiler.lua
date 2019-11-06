require('constants')
require('stdlib/table')
local Entity = require('stdlib/entity/entity')

-- Split a string in to tokens using whitespace as a seperator.
local function split( str )
    local result = {}
    for sub in string.gmatch( str, "%S+" ) do
        table.insert( result, sub )
    end
    return result
end

-- Parse tokens in to an AST we can store and evaluate later.
local function parse( tokens )
    if #tokens == 0 then
        return OP_NOP
    end

    local c = 1
    local parseExpr
    local peek = function() return tokens[c] end
    local consume = function()
        local result = peek()
        c = c + 1
        return result
    end
    local parseNum = function()
        return { val = tonumber(consume()), type = 'num' }
    end
    local parseOp = function()
        local node = { val = consume(), type = 'op', expr = {} }
        while(peek()) do
            local expr = parseExpr()
            if expr then
                table.insert( node.expr, expr )
            else
                break
            end
        end
        return node
    end
    local parseAddress = function(name)
        local token = consume()
        if string.find(token, "@%d") then
            local addr = string.gsub(token, name.."@(%d+)", "%1")
            return {val = tonumber(addr), pointer = true}
        else
            local index = string.gsub(token, name.."(%d+)", "%1")
            return {val = tonumber(index), pointer = false}
        end
    end
    local parseWire = function(name)
        local address = parseAddress(name)
        return { type = "wire", color = name, val = address.val, pointer = address.pointer}
    end
    local parseRegister = function(name)
        local address = parseAddress(name)
        return { type = "register", location = name, val = address.val, pointer = address.pointer }
    end
    local parseReadOnlyRegister = function( name, index )
        consume()
        return { type = "register", location = "mem", val = tonumber(index) }
    end
    local parseOutput = function(name)
        consume()
        return { type = "register", location = "out" }
    end
    local parseLabel = function()
        local label = consume()
        return { type = "label", label = label }
    end

    parseExpr = function()
        if peek() then
            if string.sub(peek(), 1, 1) == "#" then
                return OP_NOP
            elseif string.sub(peek(), 1, 1) == ":" then
                return parseLabel()
            elseif string.find( peek(), "%d" ) == 1 then
                return parseNum()
            elseif string.find(peek(), "red") then
                return parseWire("red")
            elseif string.find(peek(), "green") then
                return parseWire("green")
            elseif string.find(peek(), "mem") then
                return parseRegister("mem")
            elseif string.find(peek(), "out") then
                return parseOutput("out")
            elseif string.find(peek(), "ipt") then
                return parseReadOnlyRegister("ipt", 5)
            elseif string.find(peek(), "cnr") then
                return parseReadOnlyRegister("cnr", 6)
            elseif string.find(peek(), "cng") then
                return parseReadOnlyRegister("cng", 7)
            elseif string.find(peek(), "clk") then
                return parseReadOnlyRegister("clk", 8)
            else
                return parseOp()
            end
        end
    end
    return parseExpr()
end

--- Throws an exception, the exception has a control character prepended to that
--- we can substring the message to only display the error message and not the stack-trace
--- to the user.
local function exception( val )
    error("@"..val, 2)
end

--- Evaluates an AST.
local function eval( ast, control, memory, modules, program_counter, clock )
    local wires = {}
    wires.red = control.get_circuit_network(defines.wire_type.red, defines.circuit_connector_id.combinator_input)
    wires.green = control.get_circuit_network(defines.wire_type.green, defines.circuit_connector_id.combinator_input)

    local node, num
    -- Assertion Helper Functions
    local assert_inout = function( _ )
        if #_ ~= 2 then
            exception("Expecting two parameters after opcode")
        end
    end
    local assert_in = function( _ )
        if #_ ~= 1 then
            exception("Expecting one parameter after opcode")
        end
    end
    local assert_in_register = function( _ )
        if _.type ~= "register" then
            exception("Expecting 1st parameter to be a memory or output register")
        end
    end
    local assert_in_mem = function( _ )
        if _.type ~= "register" or _.location ~= "mem" then
            exception("Expecting 1st parameter to be a memory register")
        end
    end
    local assert_in_register_or_wire = function( _ )
        if not (_.type == "register" or _.type == "wire") then
            exception("Expecting 1st parameter to be a register or wire input")
        end
    end
    local assert_in_mem_or_val = function( _ )
        if not ((_.type == "register" and _.location == "mem") or _.type == "num") then
            exception("Expecting 1st parameter to be an integer or memory register")
        end
    end
    local assert_in_mem_or_val_or_label = function( _ )
        if not ((_.type == "register" and _.location == "mem") or _.type == "num" or _.type == "label") then
            exception("Expecting 1st parameter to be an integer, memory register or label")
        end
    end
    local assert_in_wire = function( _ )
        if _.type ~= "wire" then
            exception("Expecting 1st parameter to be a wire input")
        end
    end
    local assert_out_mem = function( _ )
        if _.type ~= "register" or _.location ~= "mem" then
            exception("Expecting 2nd parameter to be a memory register")
        end
    end
    local assert_out_register = function( _ )
        if _.type ~= "register" then
            exception("Expecting 2nd parameter to be a memory or output register")
        end
    end
    local assert_out_mem_or_val = function( _ )
        if not ((_.type == "register" and _.location == "mem") or _.type == "num") then
            exception("Expecting 2nd parameter to be an integer or memory register")
        end
    end
    local assert_memory_index_range = function( index, max )
        if index == nil then
            exception("No register address specified.")
        end
        if index < 1 or index > max then
            exception("Invalid memory address: "..index..". Out of range.")
        end
    end
    -- Memory Register Helper Functions
    -- Read only registers
    local getmem, setmem
    local function readOnlyRegister( index )
        if index == 5 then
            return program_counter
        elseif index == 6 then
            if wires.red and wires.red.signals then
                return #wires.red.signals
            else
                return 0
            end
        elseif index == 7 then
            if wires.green and wires.green.signals then
                return #wires.green.signals
            else
                return 0
            end
        elseif index == 8 then
            return clock
        end
    end
    local memindex = function( _ )
        if _.pointer then
            --assert_memory_index_range(_.val, 8)
            return getmem(_, true).count
        else
            return _.val
        end
    end
    getmem = function( index_expr, ignore_pointer )
        local index
        if not ignore_pointer then
            index = memindex(index_expr)
        else
            index = index_expr.val
        end
        if index > 10 and index < 45 then
            local direction = math.floor(index / 10)
            local module_index = index - (direction * 10)
            assert_memory_index_range(module_index, 4)
            local module = modules[direction]
            if module then
                if module.name == "microcontroller-ram" then
                    return table.deepcopy(module.get_control_behavior().get_signal(module_index))
                elseif module.name == "microcontroller" then
                    return table.deepcopy(Entity.get_data(module).memory[module_index])
                end
            else
                exception("Module "..direction.." not found.")
            end
        elseif index > 4 then
            assert_memory_index_range(index, 8)
            local result = table.deepcopy(NULL_SIGNAL)
            result.count = readOnlyRegister(index)
            return result
        else
            assert_memory_index_range(index, 4)
            return table.deepcopy(memory[index])
        end
    end
    setmem = function( index_expr, value )
        local index = memindex(index_expr)
        local signal = table.deepcopy(value)
        if index > 10 and index < 45 then
            local direction = math.floor(index / 10)
            local module_index = index - (direction * 10)
            assert_memory_index_range(module_index, 4)
            local module = modules[direction]
            if module then
                if module.name == "microcontroller-ram" then
                    module.get_control_behavior().set_signal(module_index, signal)
                elseif module.name == "microcontroller" then
                    local other_mc_state = Entity.get_data(module)
                    other_mc_state.memory[module_index] = signal
                end
            else
                exception("Module "..direction.." not found.")
            end
        else
            assert_memory_index_range(index, 4)
            memory[index] = signal
        end
    end
    local setmem_count = function( index_expr, count )
        local value = getmem(index_expr)
        value.count = count
        setmem(index_expr, value)
    end
    -- Output Register Helper Functions
    local getout = function()
        local signalID = control.parameters.parameters.output_signal
        local value = control.parameters.parameters.first_constant
        return {signal = signalID, count = value}
    end
    local setout = function( value )
        local params = control.parameters
        params.parameters.first_constant = value.count
        params.parameters.output_signal = value.signal
        control.parameters = params
    end
    local setout_count = function( count )
        local params = control.parameters
        params.parameters.first_constant = count
        control.parameters = params
    end
    -- Multiplex Helper Functions
    local function getregister( index_expr )
        if index_expr.location == 'mem' then
            return getmem(index_expr)
        elseif index_expr.location == 'out' then
            return getout()
        end
    end
    local function setregister( index_expr, value )
        if index_expr.location == 'mem' then
            setmem(index_expr, value)
        elseif index_expr.location == 'out' then
            setout(value)
        end
    end
    local function setregister_count( index_expr, count )
        if index_expr.location == 'mem' then
            setmem_count(index_expr, count)
        elseif index_expr.location == 'out' then
            setout_count(count)
        end
    end
    local function const_num( number )
        return {type = "num", val = number}
    end
    local function memcount_or_val( _ )
        if _.type == 'num' then
            return num(_)
        elseif _.type == 'register' and _.location == 'mem' then
            return getmem(_).count
        end
    end
    -- Wire Helper Functions
    local function getwire( _ )
        local index = memindex(_)
        if not wires[_.color] then
            exception("Tried to access ".._.color.." wire when input not present.")
        end
        if wires[_.color].signals then
            return wires[_.color].signals[index] or NULL_SIGNAL
        end
        return NULL_SIGNAL
    end
    local function find_signal_in_wire( wire, signal_to_find )
        if signal_to_find and wire.signals then
            for index, wire_signal in pairs(wire.signals) do
                if wire_signal and wire_signal.signal.name == signal_to_find.signal.name then
                    return wire.signals[index]
                end
            end
        end
        return NULL_SIGNAL
    end
    -- Setup Helper Functions
    local standard_op = function( _ )
        assert_inout(_)
        local _in = _[1]
        assert_in_mem_or_val(_in)
        local _out = _[2]
        assert_out_mem_or_val(_out)
        return _in, _out
    end
    local test_op = function( _ )
        assert_inout(_)
        local _in = _[1]
        assert_in_mem_or_val(_in)
        local _out = _[2]
        assert_out_mem_or_val(_out)
        return _in, _out
    end

    --------------------
    -- OPCODE Functions
    --------------------
    local ops = {
        -- W = wire
        -- I = integer constant
        -- M = memory register
        -- O = output register
        -- R = Register (memory or output)
        -- + = zero, one or more parameters
        nop = function(_)
        end,
        mov = function(_) -- MOV W/R R -- Move
            local _in = _[1]
            assert_in_register_or_wire(_in)

            local out_val = nil
            if _in.type == 'wire' then
                out_val = getwire(_in)
            elseif _in.type == 'register' then
                out_val = getregister(_in)
            end

            if #_ > 2 then
                for i = 2, #_ do
                    assert_out_register(_[i])
                    setregister(_[i], out_val)
                end
            else
                local _out = _[2]
                assert_out_register(_out)
                setregister(_out, out_val)
            end
        end,
        set = function(_) -- SET M/I R -- Set Count
            assert_inout(_)
            local _in = _[1]
            assert_in_mem_or_val(_in)
            local _out = _[2]
            assert_out_register(_out)
            if _in.type == 'register' then
                setregister_count(_out, getregister(_in).count)
            elseif _in.type == 'num' then
                setregister_count(_out, num(_in))
            end
        end,
        clr = function(_) -- CLR R+ -- Clear
            if #_ > 0 then
                for i, expr in ipairs(_) do
                    setregister(_[i], NULL_SIGNAL)
                end
            else
                for i = 1, #memory do
                    memory[i] = NULL_SIGNAL
                end
                for i = 1, 4 do
                    if modules[i] then
                        for k = 1, 4 do
                            setmem(const_num(i*10 + k, NULL_SIGNAL))
                        end
                    end
                end
                setout(NULL_SIGNAL)
            end
        end,
        fir = function(_) -- FIR R -- Find (from) Red
            assert_in(_)
            local _in = _[1]
            assert_in_register(_in)
            local signal = getregister(_in)
            local wire_signal = find_signal_in_wire(wires.red, signal)
            setmem(const_num(1), wire_signal)
        end,
        fig = function(_) -- FIG R -- Find (from) Green
            assert_in(_)
            local _in = _[1]
            assert_in_register(_in)
            local signal = getregister(_in)
            local wire_signal = find_signal_in_wire(wires.green, signal)
            setmem(const_num(1), wire_signal)
        end,
        swp = function(_) -- SWP R R -- Swap
            assert_inout(_)
            local _in = _[1]
            assert_in_register(_in)
            local _out = _[2]
            assert_out_register(_out)
            local inSignal = getregister(_in)
            local outSignal = getregister(_out)
            setregister(_in, outSignal)
            setregister(_out, inSignal)
        end,
        syn = function(_) -- SYN
            return {type = "sync"}
        end,
        add = function(_) -- ADD M/I M/I -- Add
            local _in, _out = standard_op(_)
            setmem_count(const_num(1), memcount_or_val(_in) + memcount_or_val(_out))
        end,
        sub = function(_) -- SUB M/I M/I -- Subtract
            local _in, _out = standard_op(_)
            setmem_count(const_num(1), memcount_or_val(_in) - memcount_or_val(_out))
        end,
        mul = function(_) -- MUL M/I M/I -- Multiply
            local _in, _out = standard_op(_)
            setmem_count(const_num(1), memcount_or_val(_in) * memcount_or_val(_out))
        end,
        div = function(_) -- DIV M/I M/I -- Divide
            local _in, _out = standard_op(_)
            setmem_count(const_num(1), memcount_or_val(_in) / memcount_or_val(_out))
        end,
        mod = function(_) -- MOD M/I M/I -- Modulo
            local _in, _out = standard_op(_)
            setmem_count(const_num(1), memcount_or_val(_in) % memcount_or_val(_out))
        end,
        pow = function(_) -- POW M/I M/I -- Exponetiation
            local _in, _out = standard_op(_)
            setmem_count(const_num(1), memcount_or_val(_in) ^ memcount_or_val(_out))
        end,
        bnd = function(_) -- BND M/I M/I -- Bitwise AND
            local _in, _out = standard_op(_)
            local result = bit32.band(memcount_or_val(_in), memcount_or_val(_out))
            setmem_count(const_num(1), result)
        end,
        bor = function(_) -- BOR M/I M/I -- Bitwise OR
            local _in, _out = standard_op(_)
            local result = bit32.bor(memcount_or_val(_in), memcount_or_val(_out))
            setmem_count(const_num(1), result)
        end,
        bxr = function(_) -- BXR M/I M/I -- Bitwise XOR
            local _in, _out = standard_op(_)
            local result = bit32.bxor(memcount_or_val(_in), memcount_or_val(_out))
            setmem_count(const_num(1), result)
        end,
        bls = function(_) -- BLS M/I M/I -- Bitwise left shift
            local _in, _out = standard_op(_)
            local result = bit32.lshift(memcount_or_val(_in), memcount_or_val(_out))
            setmem_count(const_num(1), result)
        end,
        brs = function(_) -- BRS M/I M/I -- Bitwise right shift
            local _in, _out = standard_op(_)
            local result = bit32.rshift(memcount_or_val(_in), memcount_or_val(_out))
            setmem_count(const_num(1), result)
        end,
        blr = function(_) -- BLR M/I M/I -- Bitwise left rotate
            local _in, _out = standard_op(_)
            local result = bit32.lrotate(memcount_or_val(_in), memcount_or_val(_out))
            setmem_count(const_num(1), result)
        end,
        brr = function(_) -- BRR M/I M/I -- Bitwise right rotate
            local _in, _out = standard_op(_)
            local result = bit32.rrotate(memcount_or_val(_in), memcount_or_val(_out))
            setmem_count(const_num(1), result)
        end,
        bno = function(_) -- BNO M/I M/I -- Bitwise NOT
            assert_in(_)
            local _in = _[1]
            assert_in_mem_or_val(_in)
            local result = bit32.bnot(memcount_or_val(_in))
            setmem_count(const_num(1), result)
        end,
        slp = function(_) -- SLP M/I -- Sleep
            assert_in(_)
            local _in = _[1]
            assert_in_mem_or_val(_in)
            return { type = "sleep", val = memcount_or_val(_in) }
        end,
        jmp = function(_) -- JMP M/I/L -- Jump
            assert_in(_)
            local _in = _[1]
            assert_in_mem_or_val_or_label(_in)
            if _in.type == 'label' then
                return { type = "jump", label = _in.label }
            else
                return { type = "jump", val = memcount_or_val(_in) }
            end
        end,
        hlt = function(_) -- HLT -- Halt
            return { type = "halt" }
        end,
        tgt = function(_) -- TGT M/I M/I -- Test Greater Than
            local _in, _out = test_op(_)
            if memcount_or_val(_in) > memcount_or_val(_out) then
                return { type = "skip" }
            end
        end,
        tlt = function(_) -- TLT M/I M/I -- Test Less Than
            local _in, _out = test_op(_)
            if memcount_or_val(_in) < memcount_or_val(_out) then
                return { type = "skip" }
            end
        end,
        teq = function(_) -- TEQ M/I M/I -- Test Equal (Signal count)
            local _in, _out = test_op(_)
            if memcount_or_val(_in) == memcount_or_val(_out) then
                return { type = "skip" }
            end
        end,
        tnq = function(_) -- TNG M/I M/I -- Test Not Equal (Signal count)
            local _in, _out = test_op(_)
            if memcount_or_val(_in) ~= memcount_or_val(_out) then
                return { type = "skip" }
            end
        end,
        tte = function(_) -- TTE M M -- Test Equal (Signal type)
            assert_inout(_)
            local _in = _[1]
            assert_in_mem(_in)
            local _out = _[2]
            assert_out_mem(_out)
            if getmem(_in).signal.name == getmem(_out).signal.name then
                return { type = "skip" }
            end
        end,
        ttn = function(_) -- TTN M M -- Test Not Equal (Signal type)
            assert_inout(_)
            local _in = _[1]
            assert_in_mem(_in)
            local _out = _[2]
            assert_out_mem(_out)
            if getmem(_in).signal.name ~= getmem(_out).signal.name then
                return { type = "skip" }
            end
        end,
        dig = function(_) -- DIG M/I -- Get Digit (from memory1)
            assert_in(_)
            local _in = _[1]
            assert_in_mem_or_val(_in)
            local i = memcount_or_val(_in)
            local value = getmem(const_num(1)).count
            local digit = tonumber(string.sub(tostring(value), -i, -i))
            setmem_count(const_num(1), digit)
        end,
        dis = function(_) -- DIS M/I M/I -- Set Digit (in memory1)
            assert_inout(_)
            local _in = _[1]
            assert_in_mem_or_val(_in)
            local _out = _[2]
            assert_out_mem_or_val(_out)
            local str_value = tostring(getmem(const_num(1)).count)
            local selector = string.len(str_value) - memcount_or_val(_in) + 1
            local digit = memcount_or_val(_out)
            local p1 = string.sub(str_value, 1, selector-1)
            local p2 = string.sub(str_value, selector, selector)
            local p3 = string.sub(str_value, selector+1, -1)
            p2 = string.sub(tostring(digit), -1)
            setmem_count(const_num(1), tonumber(p1..p2..p3))
        end,
        bkr = function(_) -- BKR M/I -- Block until there are at least [a] red signals.
            assert_in(_)
            local _in = _[1]
            assert_in_mem_or_val(_in)
            local count = memcount_or_val(_in)
            if wires.red.signals == nil or #wires.red.signals < count then
                return {type = "block"}
            end
        end,
        bkg = function(_) -- BKG M/I -- Block until there are at least [a] green signals.
            assert_in(_)
            local _in = _[1]
            assert_in_mem_or_val(_in)
            local count = memcount_or_val(_in)
            if wires.green.signals == nil or #wires.green.signals < count then
                return {type = "block"}
            end
        end,
    }

    -- TODO: Tidy this up, we've got functions being declared in two different ways here
    -- and also some before the op codes and some after.
    num = function( _ )
        return _.val
    end
    node = function( _ )
        if _.type == 'num' then
            return num(_)
        elseif _.type == 'op' then
            if not ops[_.val] then
                exception("Unknown opcode: ".._.val)
            else
                return ops[_.val](_.expr)
            end
        elseif _.type == 'nop' or _.type == 'label' then
            -- do nothing
        else
            exception("Unable to parse code")
        end
    end

    if ast then
        local result = node(ast)
        if type(result) == "number" then
            exception("Expected an opcode but instead read an integer.")
        end
        return result
    end
end

local compiler = {}

function compiler.compile( lines )
    local ast = {}
    for i, line in ipairs(lines) do
        ast[i] = parse(split(line))
    end
    return ast
end

function compiler.eval( ast, control, state )
    local status, results = pcall(eval, ast, control, state.memory, state.adjacent_modules, state.program_counter, state.clock)
    if not status then
        local start_index = string.find(results, "@") or 1
        results = string.sub(results, start_index+1, -1)
    end
    return status, results
end

return compiler