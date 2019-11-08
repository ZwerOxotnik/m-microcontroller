# Contents

* [Description](#description)
* [Examples](#examples)
    * [1-st](#1-st)
    * [2-nd](#2-nd)
* [Terms of use](#terms-of-use)
* [Credit](#credit)
* [Disclaimer](#disclaimer)

# Description

Handle your signals like a pro by writing FAL (Factorio Assembly Language).
This state of the art MicroController has 4 memory registers, can take any number of inputs on two channels, red and green plus 1 output register.\
The MicroController can do everything a combinator can do, only more and better!

FAL has 34 Opcodes and can read 32 lines of instructions.

[FAL Reference Document](/FAL_REFERENCE.pdf)

# Examples

## 1-st

\# Outputs the first signal\
\# from red multiplied by 2.\
mov red1 mem1\
mul mem1 2\
mov mem1 out\
jmp 2

## 2-nd

\# accumulates first 4\
\# signals on the red wire.\
:SETUP\
clr\
set 11 mem2\
set 1 mem3\
:LOOP\
mov red@3 mem1\
add mem1 mem@2\
mov mem1 mem@2\
:NEXT\
add mem2 1\
tlt mem1 15\
set 11 mem1\
mov mem1 mem2\
add mem3 1\
tlt mem1 5\
set 1 mem1\
mov mem1 mem3\
jmp :LOOP

# <a name="terms-of-use"></a> Terms of use

[![Creative Commons License](https://licensebuttons.net/l/by/4.0/88x31.png)](https://creativecommons.org/licenses/by/4.0/)

This work is a derivative of "MicroController" by Luke Perkin, used under [Creative Commons Attribution 4.0 Unported license](https://creativecommons.org/licenses/by/4.0/). This work is attributed to Luke Perkin and ZwerOxotnik, and the original version can be found [here](https://mods.factorio.com/mod/microcontroller).

This work is licensed under a [Creative Commons Attribution 4.0 International License](/LICENSE).

# Credit

Roundicons and Flaticons.com for the icon sprites.

# Disclaimer

THE WORK IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE WORK OR THE USE OR OTHER DEALINGS IN THE
WORK.
