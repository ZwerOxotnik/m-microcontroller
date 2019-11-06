HELP_TEXT = [[
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
All arithmetic ops ignore type, type in mem1 is preserved.
ADD M/I M/I : Add [A] + [B], store result in mem1.
SUB M/I M/I : Subtract [A] - [B], store result in mem1.
MUL M/I M/I : Multiply [A] * [B], store result in mem1.
DIV M/I M/I : Divide [A] / [B], store result in mem1.
MOD M/I M/I : Modulo [A] % [B], store result in mem1.
POW M/I M/I : Raise [A] to power of [B], store result in mem1.
DIG M/I     : Gets the [A]th digit from mem1, store result in mem1.
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