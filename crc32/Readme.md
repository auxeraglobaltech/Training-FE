# CRC-32 RTL Implementation

## Overview

This project implements a **parameterized CRC (Cyclic Redundancy Check) generator** in Verilog RTL.

The design is based on the commonly used **CRC-32 polynomial**:

```text
0x04C11DB7
```

The implementation supports:

* Configurable CRC width
* Configurable input data width
* Configurable polynomial
* Configurable initial CRC value
* Reflected input processing
* Reflected output configuration
* Configurable final XOR value
* Synchronous CRC register update
* Synchronous reset
* Soft reset
* `valid_i` controlled CRC calculation

The default parameters correspond to the standard CRC-32 configuration:

```text
Polynomial : 0x04C11DB7
Initial    : 0xFFFFFFFF
RefIn      : 1
RefOut     : 1
XorOut     : 0xFFFFFFFF
```

---

# 1. CRC Introduction

CRC stands for **Cyclic Redundancy Check**.

CRC is an error-detection technique used to detect accidental changes in digital data during:

* Data transmission
* Network communication
* Storage
* Memory interfaces
* Communication protocols
* Ethernet
* USB
* Storage systems

The transmitter calculates a CRC value from the input data and sends the CRC along with the data.

The receiver calculates the CRC again and compares the result.

### Basic concept

```text
             Transmitter
                 |
                 v
        +----------------+
Data -->|   CRC Engine   |----> CRC
        +----------------+
                 |
                 v
             Data + CRC
                 |
                 v
        Communication Channel
                 |
                 v
             Receiver
                 |
                 v
        +----------------+
Data -->|   CRC Engine   |
        +----------------+
                 |
                 v
            CRC Compare
                 |
          +------+------+
          |             |
        Match        Mismatch
          |             |
        Valid         Error
```

---

# 2. CRC Working Principle

CRC treats the input data as a polynomial.

For CRC-32, the generator polynomial is:

```text
x^32 + x^26 + x^23 + x^22 + x^16
+ x^12 + x^11 + x^10 + x^8
+ x^7 + x^5 + x^4 + x^2 + x + 1
```

The corresponding hexadecimal representation is:

```text
0x04C11DB7
```

The CRC calculation is essentially polynomial division using XOR instead of normal subtraction.

---

# 3. CRC-32 Parameters

The default configuration in this RTL is:

| Parameter    |          Value | Description                              |
| ------------ | -------------: | ---------------------------------------- |
| `CRC_SIZE`   |             32 | CRC register width                       |
| `DATA_WIDTH` |              8 | Number of input bits processed per cycle |
| `POLY`       | `32'h04C11DB7` | CRC-32 polynomial                        |
| `INIT`       | `32'hFFFFFFFF` | Initial CRC value                        |
| `REF_IN`     |            `1` | Reflected input                          |
| `REF_OUT`    |            `1` | Reflected output                         |
| `XOR_OUT`    | `32'hFFFFFFFF` | Final XOR value                          |

This configuration is commonly associated with **CRC-32/ISO-HDLC**, also known as the Ethernet CRC-32 convention.

---

# 4. Module Interface

```verilog
module crc32_calc
#(
    parameter CRC_SIZE   = 32,
    parameter DATA_WIDTH = 8,

    parameter [31:0] POLY    = 32'h04C11DB7,
    parameter [31:0] INIT    = 32'hFFFFFFFF,
    parameter REF_IN         = 1,
    parameter REF_OUT        = 1,
    parameter [31:0] XOR_OUT = 32'hFFFFFFFF
)
(
    input                     clk_i,
    input                     rst_i,
    input                     soft_reset_i,
    input                     valid_i,

    input  [DATA_WIDTH-1:0]   data_i,

    output [CRC_SIZE-1:0]     crc_o
);
```

---

# 5. Port Description

| Signal         | Direction | Description                                                |
| -------------- | --------- | ---------------------------------------------------------- |
| `clk_i`        | Input     | Clock                                                      |
| `rst_i`        | Input     | Synchronous reset                                          |
| `soft_reset_i` | Input     | Resets CRC calculation without resetting the entire module |
| `valid_i`      | Input     | Indicates that `data_i` contains valid data                |
| `data_i`       | Input     | Input data                                                 |
| `crc_o`        | Output    | Current final CRC value                                    |

---

# 6. Internal Registers

The design contains three important registers:

```verilog
reg [CRC_SIZE-1:0] crc;
reg [CRC_SIZE-1:0] crc_next;
reg [CRC_SIZE-1:0] crc_prev;
```

### `crc`

Stores the current CRC state.

```text
crc
 |
 +---- Current CRC value
```

It is updated on the rising edge of the clock.

---

### `crc_next`

Stores the CRC value calculated from:

```text
Current CRC + input data
```

It is generated combinationally.

---

### `crc_prev`

Stores the intermediate CRC state while processing each input bit.

It allows the RTL to process the input byte one bit at a time inside the combinational calculation.

---

# 7. CRC Register

The sequential logic is:

```verilog
always @(posedge clk_i)
begin
    if(rst_i)
        crc <= INIT;

    else if(soft_reset_i)
        crc <= INIT;

    else if(valid_i)
        crc <= crc_next;
end
```

The behavior is:

```text
                +----------------+
                |   Rising Edge  |
                +--------+-------+
                         |
                         v
                   rst_i = 1?
                    /       \
                  Yes        No
                  /           \
                 v             v
               INIT      soft_reset_i?
                              /    \
                            Yes     No
                            /        \
                           v          v
                         INIT     valid_i?
                                     / \
                                   Yes  No
                                   /     \
                                  v       |
                              crc_next   Hold
```

### Reset

When:

```verilog
rst_i = 1
```

the CRC register becomes:

```text
CRC = INIT
```

For the default configuration:

```text
CRC = FFFFFFFF
```

---

### Soft Reset

When:

```verilog
soft_reset_i = 1
```

the CRC calculation is restarted:

```text
CRC = INIT
```

This is useful when starting a new independent data packet without necessarily resetting the complete system.

---

### Valid

When:

```verilog
valid_i = 1
```

the calculated CRC is loaded:

```text
crc <= crc_next
```

When:

```verilog
valid_i = 0
```

the CRC register holds its previous value.

---

# 8. CRC Output

The final CRC is generated using:

```verilog
assign crc_o = crc ^ XOR_OUT;
```

For the default configuration:

```text
XOR_OUT = FFFFFFFF
```

Therefore:

```text
CRC_OUT = CRC_REGISTER XOR FFFFFFFF
```

This is called the **final XOR operation**.

---

# 9. CRC Calculation

The combinational CRC calculation starts with:

```verilog
crc_next = crc;
crc_prev = crc;
```

This means the current CRC state is used as the starting point.

The input data is then processed one bit at a time.

```verilog
for(i = 0; i < DATA_WIDTH; i = i + 1)
```

For the default configuration:

```text
DATA_WIDTH = 8
```

Therefore:

```text
8 input bits
      |
      v
bit 0
bit 1
bit 2
bit 3
bit 4
bit 5
bit 6
bit 7
```

are processed sequentially inside the combinational logic.

---

# 10. Reflected Input Processing

Because:

```text
REF_IN = 1
```

the input byte is processed starting from the least significant bit.

For example:

```text
data_i = 8'bABCDEFGH
```

is conceptually processed as:

```text
H -> G -> F -> E -> D -> C -> B -> A
```

where `H` represents bit 0.

In the RTL this is implemented using:

```verilog
data_i[i]
```

with:

```verilog
i = 0,1,2,...,7
```

Therefore:

```text
data_i[0]
data_i[1]
data_i[2]
...
data_i[7]
```

are processed in that order.

---

# 11. CRC Feedback Bit

The important calculation is:

```verilog
crc_next[31] = crc_prev[0] ^ data_i[i];
```

The feedback bit is:

```text
feedback = crc_prev[0] XOR input_bit
```

This is characteristic of the reflected/right-shifting implementation.

The feedback determines whether the polynomial needs to be applied during the current bit operation.

---

# 12. Polynomial Operation

The RTL checks the polynomial bits:

```verilog
if(POLY[j])
```

If the corresponding polynomial bit is `1`, the CRC calculation includes the feedback term:

```verilog
crc_next[CRC_SIZE-1-j] =
    crc_prev[CRC_SIZE-j] ^
    crc_prev[0] ^
    data_i[i];
```

If the polynomial bit is `0`:

```verilog
crc_next[CRC_SIZE-1-j] =
    crc_prev[CRC_SIZE-j];
```

Thus, the polynomial controls which CRC register bits receive the XOR feedback.

---

# 13. Bit-Level CRC Operation

Conceptually, each input bit performs:

```text
                Current CRC
                     |
                     v
              +-------------+
              | CRC register|
              +-------------+
                     |
                     v
                 CRC[0]
                     |
                     +------+
                     |      |
                     | XOR  | <--- input bit
                     |      |
                     +------+
                        |
                        v
                    Feedback
                        |
                        v
               Polynomial XOR
                        |
                        v
                Next CRC state
```

The operation is repeated for every input bit.

---

# 14. Processing One Input Byte

For:

```text
DATA_WIDTH = 8
```

one clock cycle can calculate the CRC for an entire byte.

Conceptually:

```text
              data_i[0]
                  |
                  v
             CRC update
                  |
                  v
              data_i[1]
                  |
                  v
             CRC update
                  |
                  v
              data_i[2]
                  |
                  v
                 ...
                  |
                  v
              data_i[7]
                  |
                  v
             Final CRC
```

The entire combinational calculation occurs between two clock edges.

Therefore, when `valid_i` is asserted at a clock edge:

```text
CRC register
     |
     v
CRC calculation for data_i
     |
     v
crc_next
     |
     v
CRC register updated
```

---

# 15. Complete RTL Data Flow

```text
                     +----------------+
                     |    data_i      |
                     |   DATA_WIDTH   |
                     +-------+--------+
                             |
                             v
                  +---------------------+
                  | CRC Combinational   |
                  |     Calculation     |
                  +----------+----------+
                             |
                             v
                        crc_next
                             |
                             |
                +------------v-------------+
                |       CRC Register       |
                |          crc             |
                +------------+-------------+
                             |
                             v
                      XOR_OUT operation
                             |
                             v
                          crc_o
```

---

# 16. Clock-by-Clock Operation

Assume:

```text
INIT = FFFFFFFF
```

After reset:

```text
crc = FFFFFFFF
```

When the first byte is valid:

```text
valid_i = 1
data_i  = 8'hXX
```

the combinational block calculates:

```text
crc_next = CRC(FFFFFFFF, XX)
```

At the next rising edge:

```text
crc <= crc_next
```

The next input byte can then be processed using this new CRC state.

Example:

```text
Reset
  |
  v
CRC = FFFFFFFF
  |
  v
Byte 1
  |
  v
CRC = CRC(FFFFFFFF, Byte1)
  |
  v
Byte 2
  |
  v
CRC = CRC(CRC1, Byte2)
  |
  v
Byte 3
  |
  v
CRC = CRC(CRC2, Byte3)
```

After the final byte:

```text
crc_o = crc ^ XOR_OUT
```

---

# 17. Why `crc_prev` Is Required

Inside the loop, the CRC calculation is performed repeatedly.

For example:

```verilog
crc_prev = crc_next;
```

at the end of each iteration.

This means:

```text
Initial CRC
    |
    v
Process bit 0
    |
    v
crc_prev = result of bit 0
    |
    v
Process bit 1
    |
    v
crc_prev = result of bit 1
    |
    v
Process bit 2
    |
    v
...
```

So `crc_prev` represents the CRC state entering the current bit operation.

---

# 18. Why `crc_next` Is Required

`crc` is the registered state.

It should not be directly modified inside the combinational calculation.

Therefore the design follows the standard RTL structure:

```text
crc
 |
 | current state
 v
Combinational logic
 |
 | next state
 v
crc_next
 |
 | clock edge
 v
crc
```

This is the common **current-state / next-state** design pattern.

---

# 19. Sequential and Combinational Logic

The design contains two main blocks.

### Sequential block

```verilog
always @(posedge clk_i)
```

Responsible for:

* Reset
* Soft reset
* Register update
* Holding CRC state

### Combinational block

```verilog
always @(*)
```

Responsible for:

* CRC calculation
* Polynomial processing
* Input-bit processing
* Generating `crc_next`

Therefore:

```text
             +-----------------------+
             | Combinational Logic   |
             |                       |
crc -------->| CRC Calculation       |----> crc_next
             |                       |
data_i ------>|                       |
             +-----------+-----------+
                         |
                         v
                  +-------------+
clk ------------->| CRC Register|
                  +-------------+
                         |
                         v
                        crc
```

---

# 20. `valid_i` Operation

`valid_i` controls when the calculated CRC is accepted.

### `valid_i = 1`

```text
data_i is valid
       |
       v
Calculate CRC
       |
       v
Update CRC register
```

### `valid_i = 0`

```text
No valid data
      |
      v
CRC register holds
previous value
```

This allows the CRC engine to remain idle when there is no input data.

---

# 21. Reset vs Soft Reset

### Hardware Reset

```text
rst_i = 1
```

resets the CRC state.

### Soft Reset

```text
soft_reset_i = 1
```

also resets the CRC state to `INIT`.

The difference is generally at the system level.

A hardware reset is normally associated with initialization of the block/system, whereas a soft reset can be used to start a new CRC calculation during normal operation.

---

# 22. CRC Processing Example

Suppose:

```text
INIT    = FFFFFFFF
POLY    = 04C11DB7
XOR_OUT = FFFFFFFF
```

and the input data stream is:

```text
12 34 56 78
```

The CRC engine operates as:

```text
Initial CRC
FFFFFFFF
   |
   v
Process 12
   |
   v
CRC1
   |
   v
Process 34
   |
   v
CRC2
   |
   v
Process 56
   |
   v
CRC3
   |
   v
Process 78
   |
   v
Final CRC state
   |
   v
XOR FFFFFFFF
   |
   v
crc_o
```

For a standard CRC-32/ISO-HDLC implementation, the final CRC for the ASCII string:

```text
"123456789"
```

is the well-known check value:

```text
CBF43926
```

This is a useful reference value for verification.

---

# 23. CRC-32 Standard Check Value

A standard CRC implementation can be verified using:

```text
Input:
123456789

Expected CRC-32:
CBF43926
```

This is one of the most commonly used CRC-32 verification vectors.

---

# 24. RTL Implementation Flow

The implementation flow is:

```text
              Define CRC parameters
                       |
                       v
               Initialize CRC
                       |
                       v
                Receive data
                       |
                       v
                  valid_i = 1
                       |
                       v
             Process input bits
                       |
                       v
              Apply polynomial
                       |
                       v
                 crc_next
                       |
                       v
              Register at clock
                       |
                       v
               Process next byte
                       |
                       v
                 Final XOR
                       |
                       v
                    crc_o
```

---

# 25. Advantages

* Parameterized CRC width
* Parameterized data width
* Polynomial is configurable
* Initial value is configurable
* Final XOR is configurable
* Supports byte-at-a-time processing
* Synthesizable RTL structure
* Simple synchronous interface
* Suitable for FPGA/ASIC RTL implementation
* `valid_i` provides simple flow control

---

# 26. Important RTL Considerations

The CRC calculation is implemented as combinational logic:

```verilog
for(i = 0; i < DATA_WIDTH; i = i + 1)
```

and:

```verilog
for(j = 1; j < CRC_SIZE; j = j + 1)
```

Therefore, increasing:

```text
DATA_WIDTH
```

or:

```text
CRC_SIZE
```

can increase the amount of combinational logic and potentially increase timing delay.

For example:

```text
8-bit input
    |
    v
8 CRC iterations
```

is generally easier to meet timing than:

```text
64-bit input
    |
    v
64 CRC iterations
```

in one combinational cycle.

For very high-speed designs, CRC calculations are often implemented using:

* Parallel CRC logic
* Pipelining
* Byte/word-wide CRC equations
* Multiple CRC lanes

---

# 27. Latency

For this implementation, the CRC state is updated on the rising edge of `clk_i`.

If a valid byte is presented:

```text
valid_i = 1
```

the new CRC state is loaded on the active clock edge.

Therefore, the CRC operation has a **one-clock registered update per valid input word**.

The combinational CRC logic itself calculates the complete `DATA_WIDTH`-bit update between clock edges.

---

# 28. Throughput

With:

```text
DATA_WIDTH = 8
```

the design can process:

```text
8 bits / clock
```

for every cycle where:

```text
valid_i = 1
```

For a clock frequency of `Fclk`:

```text
Throughput = DATA_WIDTH × Fclk
```

For example, at:

```text
Fclk = 100 MHz
DATA_WIDTH = 8
```

the theoretical input throughput is:

```text
8 × 100 MHz = 800 Mbit/s
```

assuming `valid_i` is asserted every cycle.

---

# 29. Verification Strategy

A CRC RTL implementation should be verified using known CRC reference values.

Recommended verification steps:

### Test 1  Reset

Assert:

```text
rst_i = 1
```

and verify:

```text
crc = INIT
```

---

### Test 2  Soft Reset

Assert:

```text
soft_reset_i = 1
```

and verify that the CRC returns to:

```text
INIT
```

---

### Test 3  Invalid Data

Set:

```text
valid_i = 0
```

and verify that the CRC state does not change.

---

### Test 4  Known CRC Vector

Use:

```text
"123456789"
```

and verify:

```text
Expected CRC = CBF43926
```

---

### Test 5  Multiple Bytes

Test a stream such as:

```text
12 34 56 78 AA 55 FF
```

and compare the RTL result against a software/reference CRC implementation.

---

# 30. Suggested Testbench Structure

```text
                  Testbench
                     |
                     v
              +-------------+
              | CRC DUT      |
              +-------------+
               |    |    |
               |    |    |
              clk  rst  data
                     |
                     v
                 valid_i
                     |
                     v
              Expected CRC
                     |
                     v
                 Comparison
                     |
              +------+------+
              |             |
            PASS          FAIL
```

A self-checking testbench should calculate or store the expected CRC and compare it against:

```verilog
crc_o
```

using:

```verilog
if(crc_o == expected_crc)
    $display("TEST PASS");
else
    $display("TEST FAIL");
```

---

# 31. Simulation

The design can be simulated using Cadence Xcelium.

Example:

```bash
xrun crc32.v crc32_tb.v -access +rwc
```

For GUI simulation:

```bash
xrun crc32.v crc32_tb.v -access +rwc -gui
```

If a file list is used:

```bash
xrun -f flist.f -access +rwc
```

Example `flist.f`:

```text
crc32.v
crc32_tb.v
```

---

# 32. Expected Simulation Sequence

A typical waveform should show:

```text
clk_i
  _   _   _   _   _   _
_| |_| |_| |_| |_| |_| |_

rst_i
____|??|________________

valid_i
________|???|_|???|____

data_i
        12      34      56

crc
FFFFFFFF
        |
        +---- CRC after 12
                    |
                    +---- CRC after 34
                              |
                              +---- CRC after 56

crc_o
Final CRC value
```

---

# 33. File Structure

A recommended project structure is:

```text
CRC32/
¦
+-- crc32.v
+-- crc32_tb.v
+-- Readme.md
¦
+-- simulation/
    +-- ...
```

---

# 34. Key RTL Concepts Used

This implementation demonstrates several important RTL concepts:

### Parameterization

```verilog
parameter CRC_SIZE
parameter DATA_WIDTH
parameter POLY
```

allows the module to be reused for different CRC configurations.

### Sequential Logic

```verilog
always @(posedge clk_i)
```

stores the CRC state.

### Combinational Logic

```verilog
always @(*)
```

calculates the next CRC state.

### Nonblocking Assignment

```verilog
crc <= crc_next;
```

is used for sequential logic.

### Blocking Assignment

```verilog
crc_next = crc;
crc_prev = crc;
```

is used for combinational calculations.

### Generate-like Iteration

The `for` loops describe repeated CRC bit operations that synthesis tools can expand into hardware.

---

# 35. Important Note About `REF_IN` and `REF_OUT`

The parameters:

```verilog
parameter REF_IN  = 1,
parameter REF_OUT = 1
```

are declared in the module.

However, in the RTL shown, these parameters are **not explicitly used in conditional logic**.

The current implementation directly performs reflected input processing through:

```verilog
data_i[i]
```

starting at:

```text
i = 0
```

and uses the reflected/right-shifting CRC formulation.

Similarly, the output is directly:

```verilog
crc_o = crc ^ XOR_OUT;
```

There is no separate conditional output reflection based on `REF_OUT`.

Therefore, although `REF_IN` and `REF_OUT` exist as parameters, the current RTL behavior is effectively fixed to the reflected configuration.

If the goal is a **fully generic CRC engine supporting both reflected and non-reflected modes**, additional logic is required to make `REF_IN` and `REF_OUT` control the calculation.

---

# 36. Design Summary

```text
+------------------------------------------------+
|                  CRC-32 RTL                    |
|                                                |
|  data_i                                        |
|     |                                          |
|     v                                          |
|  Bit-by-bit CRC calculation                   |
|     |                                          |
|     | POLY = 04C11DB7                         |
|     v                                          |
|  crc_next                                      |
|     |                                          |
|     v                                          |
|  +-----------+                                 |
|  | CRC Reg   | <---- clk_i                    |
|  +-----------+                                 |
|     |                                          |
|     v                                          |
|  XOR_OUT                                       |
|     |                                          |
|     v                                          |
|   crc_o                                        |
+------------------------------------------------+
```

---

# 37. Key Takeaways

* CRC is an **error-detection mechanism**.
* CRC calculation is based on **polynomial division using XOR operations**.
* `POLY` defines the generator polynomial.
* `INIT` defines the starting CRC state.
* `XOR_OUT` defines the final XOR operation.
* `valid_i` determines when input data updates the CRC.
* `crc` stores the current CRC state.
* `crc_next` stores the calculated next state.
* `crc_prev` stores intermediate CRC states during bit processing.
* The default design processes **8 bits per clock**.
* The default polynomial is **CRC-32 polynomial `0x04C11DB7`**.
* The standard CRC-32 check value for `"123456789"` is **`0xCBF43926`**.
* The current RTL performs reflected processing directly; `REF_IN` and `REF_OUT` are not dynamically applied as parameters.
* Increasing data width increases the amount of combinational CRC logic and can affect timing.

---

# 38. Reference Configuration

For the default CRC-32 configuration:

```text
CRC width      = 32 bits
Data width     = 8 bits
Polynomial     = 0x04C11DB7
Initial value  = 0xFFFFFFFF
RefIn          = TRUE
RefOut         = TRUE
XorOut         = 0xFFFFFFFF
```

Standard check vector:

```text
Input          = "123456789"
Expected CRC   = 0xCBF43926
```

This configuration can be used as the primary reference for RTL simulation and verification.

