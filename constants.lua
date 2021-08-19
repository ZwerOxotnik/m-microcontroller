NULL_SIGNAL = {signal = { type = "virtual", name = "signal-black" }, count = 0}
HALT_SIGNAL = {signal = { type = "virtual", name = "signal-mc-halt"}, count = 1}
RUN_SIGNAL = {signal = { type = "virtual", name = "signal-mc-run"}, count = 1}
STEP_SIGNAL = {signal = { type = "virtual", name = "signal-mc-step"}, count = 1}
SLEEP_SIGNAL = {signal = { type = "virtual", name = "signal-mc-sleep"}, count = 1}
JUMP_SIGNAL = {signal = { type = "virtual", name = "signal-mc-jump"}, count = 1}
OP_NOP = {type = 'nop'}
MC_LINES = 32

-- {type = "instruction", name = ""}
-- {type = "description", name = "", with_example = true}
-- with_note = true

local OLD_HELP_TEXT = [[
-- Registers (Read/Write):
mem1 mem2 mem3 mem4 out
-- Registers (Read Only):
mem5/ipt    : Instruction pointer index
mem6/cnr    : Number of signals on the red wire
mem7/cng    : Number of signals on the green wire
mem8/clk    : Clock (monotonic, always runnning)
-- Modules:
You can connect RAM Modules or other MicroControllers by placing
them above or below this MicroController.
External memory is mapped to:
mem11-14 (North Port 1)
mem21-24 (South Port 1)
mem31-34 (North Port 2)
mem41-44 (South Port 2)
MicroControllers can only connect to North and South port 1.
--- Wires:
red1 red2 redN...
green1 green2 greenN...
--- Pointers:
mem@N   : Access memN where X is the value at memN
red@N   : Access redX where X is the value at memN
green@N : Access greenX where X is the value at memN
--- Glossary:
Signal      : A type and integer value.
Value       : The integer value part of a signal.
Move        : Copy a signal from one source to another.
Set         : Set the Value of a register.
Register    : A place that can store a signal.
Clear       : Reset a register back to Black 0 (the NULL signal).
Find signal : Looks for a signal that has the same type
              as the type stored in a register.
Label       : A text identifier used for jumps.
--- Key:
W = Wire, I = Integer
M = Memory, O = Output
R = Register (Memory or Output)
L = Label (:id)
------- OP CODES ---------
OP  A   B   : DESCRIPTION
------------:-------------
MOV W/R R...: Move signal from [A] to register(s).
SET M/I R   : Set [B] signal count to [A].
SWP R R     : Swap [A] with [B].
CLR R...    : Clear register(s). Clears all if none specified.
FIR R       : Find signal R from the red wire and move to mem1.
FIG R       : Find signal R from the green wire and move to mem1.
JMP M/I/L   : Jump to line [A] or label.
HLT         : Halt the program.
NOP         : No Operation.
--- Arithmetic Op Codes:
All arithmetic ops ignore type, type in memN is preserved.
ADD M/I M/I : Add [A] + [B], store result in memN.
SUB M/I M/I : Subtract [A] - [B], store result in memN.
MUL M/I M/I : Multiply [A] * [B], store result in memN.
DIV M/I M/I : Divide [A] / [B], store result in memN.
MOD M/I M/I : Modulo [A] % [B], store result in memN.
POW M/I M/I : Raise [A] to power of [B], store result in memN.
DIG M/I     : Gets the [A]th digit from mem1, store result in memN.
DIS M/I M/I : Sets the [A]th digit from mem1 to the 1st digit from [B].
BND M/I M/I : Bitwise [A] AND [B]
BOR M/I M/I : Bitwise [A] OR [B]
BXR M/I M/I : Bitwise [A] XOR [B]
BNO M/I     : Bitwise NOT [A]
BLS M/I M/I : Bitwise LEFT SHIFT [A] by [B]
BRS M/I M/I : Bitwise RIGHT SHIFT [A] by [B]
BLR M/I M/I : Bitwise LEFT ROTATE [A] by [B]
BRR M/I M/I : Bitwise RIGHT ROTATE [A] by [B]
--- Test Op Codes:
Test Ops will skip the next line if the test is successful.
TGT M/I M/I : Tests if [A] value greater than [B] value.
TLT M/I M/I : Tests if [A] value less than [B] value.
TEQ M/I M/I : Tests if [A] value equals [B] value.
TNQ M/I M/I : Tests if [A] value does not equal [B] value.
TTE M M     : Tests if [A] type equals [B] type.
TTN M M     : Tests if [A] type does not equal [B] type.
--- Blocking Op Codes:
Blocking Ops will pause the program until the operation is complete.
SLP M/I     : Sleep for [A] ticks.
BKR M/I     : Block until there's [a]+ signals on the red wire.
BKG M/I     : Block until there's [a]+ signals on the green wire.
SYN         : Blocks until all other connected microcontrollers SYN.
--- Interrupts:
You can send interrupting signals to a microcontroller.
There are: HLT (halt), RUN (run), STP (step), SLP (sleep) and JMP (jump).
If a microcontroller receives any one of these signals it will
execute them immediately.
-------------------------------------------------------------------------
-------------------------------------------------------------------------
-- Example 1:
# Outputs the first signal
# from red multiplied by 2.
mov red1 mem1
mul mem1 2
mov mem1 out
jmp 2
-- Example 2:
# accumulates first 4
# signals on the red wire.
:SETUP
clr
set 11 mem2
set 1 mem3
:LOOP
mov red@3 mem1
add mem1 mem@2
mov mem1 mem@2
:NEXT
add mem2 1
tlt mem1 15
set 11 mem1
mov mem1 mem2
add mem3 1
tlt mem1 5
set 1 mem1
mov mem1 mem3
jmp :LOOP
]]

local BIS_DESCRIPTION = [[
local BIS_DESCRIPTION = [[
<:I> specifies a parameter that takes a literal integer.
<:R> specifies a parameter that takes a register address.
<:W> specifies a parameter that takes a wire Input address.
<:L> specifies a parameter that takes a label.
]]

local EXAMPLE1 = ":LOOP\njmp :LOOP"
local EXAMPLE2 = "fig mem21\nmul mem1 2\nmov mem1 out"
local EXAMPLE3 = ":60 second clock.\nadd mem1 1\nmod mem1 60\njmp 1"
local EXAMPLE4 = [[
mov red1 mem1
mul mem1 2
mov mem1 out
]]
local EXAMPLE5 = [[
clr
set 11 mem2
set 3 mem2
:loop
mov red@3 mem1
add mem1 mem@2
mov mem1 mem@2
add mem2 1
tlt mem1 15
set 11 mem1
mov mem1 mem2
add mem3 1
tlt mem1 5
set 1 mem1
mov mem1 mem3
]]

DOCS = {
    {
        name = "overview",
        content = {
            {name = "registers"},
            {name = "mapped-memory"}
        }
    },
    {
        name = "glossary",
        content = {
            {name = "signal_glossary"},
            {name = "type_glossary"},
            {name = "value_glossary"},
            {name = "move_glossary"},
            {name = "set_glossary"},
            {name = "register_glossary"},
            {name = "clear_glossary"},
            {name = "null_glossary"},
            {name = "label_glossary"}
        }
    },
    {
        name = "basic_instructions_set",
        content = {
            {example = BIS_DESCRIPTION},
            {name = "description_BIS"},
            {name = "comments_BIS", syntax = "#<comment>"},
            {name = "labels_BIS", syntax = "#<label>", example = EXAMPLE1},
            {name = "NOP_BIS", syntax = "nop"},
            {name = "MOV_BIS", syntax = "mov <SRC:W/R> <DST:R>"},
            {name = "SET_BIS", syntax = "set <SRC:I> <DST:R>"},
            {name = "SWP_BIS", syntax = "swp <SRC:R> <DST:R>"},
            {name = "CLR_BIS", syntax = "clr <DST:R>…"},
            {name = "FIG_BIS", syntax = "fig <SRC:R>", example = EXAMPLE2},
            {name = "FIR_BIS", syntax = "fir <SRC:R>"},
            {name = "JMP_BIS", syntax = "jmp <SRC:I/R/L>", example = EXAMPLE1},
            {name = "HLT_BIS", syntax = "hlt <SRC:R>"}
        }
    },
    {
        name = "arithmetic_instructions",
        content = {
            {name = "ADD_AI", syntax = "add <SRC:I/R> <DST:I/R>"},
            {name = "SUB_AI", syntax = "sub <SRC:I/R> <DST:I/R>"},
            {name = "MUL_AI", syntax = "mul <SRC:I/R> <DST:I/R>"},
            {name = "DIV_AI", syntax = "div <SRC:I/R> <DST:I/R>"},
            {name = "MOD_AI", syntax = "mod <SRC:I/R> <DST:I/R>", example = EXAMPLE3},
            {name = "POW_AI", syntax = "pow <SRC:I/R> <DST:I/R>"},
            {name = "DIG_AI", syntax = "swp <SRC:I/R>"},
            {name = "DIS_AI", syntax = "dis <SRC:I/R> <DST:I/R>"},
            {name = "BND_AI", syntax = "bnd <SRC:I/R> <DST:I/R"},
            {name = "BOR_AI", syntax = "bor <SRC:I/R> <DST:I/R>"},
            {name = "BXR_AI", syntax = "bxr <SRC:I/R> <DST:I/R>"},
            {name = "BND2_AI", syntax = "bnd <SRC:I/R>"},
            {name = "BLS_AI", syntax = "bls <SRC:I/R> <DST:I/R>"},
            {name = "BRS_AI", syntax = "brs <SRC:I/R> <DST:I/R>"},
            {name = "BLR_AI", syntax = "blr <SRC:I/R> <DST:I/R>"},
            {name = "BRR_AI", syntax = "brr <SRC:I/R> <DST:I/R>"}
        }
    },
    {
        name = "test_instructions",
        content = {
            {name = "TGT_TI", syntax = "tgt <SRC:I/R> <DST:I/R>"},
            {name = "TLT_TI", syntax = "tlt <SRC:I/R> <DST:I/R>"},
            {name = "TEQ_TI", syntax = "teq <SRC:I/R> <DST:I/R>"},
            {name = "TTE_TI", syntax = "tte <SRC:R> <DST:R>"},
            {name = "TTN_TI", syntax = "ttn <SRC:R> <DST:R>"}
        }
    },
    {
        name = "blocking_instructions",
        content = {
            {name = "SLP_BI", syntax = "slp <SRC:I/R>"},
            {name = "BKR_BI", syntax = "bkr <SRC:I/R>"},
            {name = "BKG_BI", syntax = "bkg <SRC:I/R>"},
            {name = "SYN_BI", syntax = "SYN"}
        }
    },
    {
        name = "interrupt_signals",
        content = {
            {name = "HLT_IS"},
            {name = "RUN_IS"},
            {name = "STP_IS"},
            {name = "SLP_IS"},
            {name = "JMP_IS"}
        }
    },
    {
        name = "pointers",
        content = {
            {name = "MEM_pointer"},
            {name = "RED_pointer"},
            {name = "GREEN_pointer"}
        }
    },
    {
        name = "example_programs",
        content = {
            {name = "MULTIPLY_INPUT_EP", example = EXAMPLE4},
            {name = "ACCUMULATE_INPUT_EP", example = EXAMPLE5},
        }
    },
    {
        name = "old-help-text",
        content = {
            {example = OLD_HELP_TEXT}
        }
    }
}
