# IWRR Arbiter

## Overview

This project implements an **Interleaved Weighted Round-Robin (IWRR) Arbiter** in synthesizable Verilog RTL.

The arbiter receives requests from multiple clients and selects one requester at a time according to:

* Request status
* Configured weight
* Current IWRR round
* Round-robin pointer
* Whether a requester has already been served in the current round

The design supports:

* Parameterized number of requesters
* Configurable requester weights
* Multiple IWRR rounds
* Round-robin arbitration within each round
* One-hot grant output
* Asynchronous active-low reset
* Synthesizable RTL implementation

---

# 1. What is an Arbiter?

An **arbiter** is a hardware block that decides which requester gets access to a shared resource when multiple requesters request it simultaneously.

For example:

```text
Requester 0 ----\
Requester 1 -----\
Requester 2 ------> Arbiter ----> Shared Resource
Requester 3 -----/
```

If multiple requesters assert their request at the same time:

```text
req = 4'b1111
```

the arbiter selects one requester.

The selected requester receives a grant:

```text
grant = 4'b0001
```

for requester 0, for example.

---

# 2. Why is an Arbiter Needed?

Suppose four masters want to access one shared resource:

```text
             +----------------+
Master 0 --->|                |
Master 1 --->|                |
Master 2 --->|    Arbiter     |----> Shared Resource
Master 3 --->|                |
             +----------------+
```

The resource can normally serve only one requester at a time.

Without an arbiter, multiple requesters could attempt to access it simultaneously, causing:

* Resource conflicts
* Data corruption
* Bus contention
* Unfair access
* Starvation

The arbiter provides controlled access.

---

# 3. Types of Arbiter

Common arbitration techniques include:

* Fixed-priority arbitration
* Round-robin arbitration
* Weighted round-robin
* Interleaved Weighted Round-Robin (IWRR)
* Lottery arbitration
* Time-division arbitration

This project implements:

```text
Interleaved Weighted Round-Robin
```

---

# 4. What is Round-Robin Arbitration?

In a normal round-robin arbiter, each requester receives an equal opportunity.

For four requesters:

```text
0 -> 1 -> 2 -> 3 -> 0 -> 1 -> ...
```

For example:

```text
Request sequence:

0
1
2
3
0
1
2
3
...
```

The pointer determines which requester has priority.

---

# 5. Problem with Normal Round-Robin

Normal round-robin gives every requester equal service.

Suppose:

```text
Requester 0 = high traffic
Requester 1 = low traffic
Requester 2 = medium traffic
Requester 3 = high traffic
```

Equal service may not be appropriate.

Weighted arbitration allows different requesters to receive different amounts of service.

---

# 6. Weighted Round-Robin

In Weighted Round-Robin (WRR), every requester is assigned a weight.

Example:

```text
Requester 0 -> Weight 1
Requester 1 -> Weight 2
Requester 2 -> Weight 3
Requester 3 -> Weight 4
```

A larger weight means the requester can receive more service.

Conceptually:

```text
Requester 0 : ¦
Requester 1 : ¦¦
Requester 2 : ¦¦¦
Requester 3 : ¦¦¦¦
```

However, conventional WRR can create bursts of service.

IWRR improves this behavior by distributing the weighted service across multiple rounds.

---

# 7. What is IWRR?

IWRR stands for:

**Interleaved Weighted Round-Robin**

Instead of giving one requester all of its weighted grants consecutively, IWRR divides service into rounds.

For example, assume:

```text
Weight0 = 1
Weight1 = 2
Weight2 = 3
Weight3 = 4
```

The IWRR rounds are conceptually:

```text
Round 1:
0 1 2 3

Round 2:
1 2 3

Round 3:
2 3

Round 4:
3
```

Thus the total number of services is:

```text
Requester 0 -> 1
Requester 1 -> 2
Requester 2 -> 3
Requester 3 -> 4
```

but the services are interleaved.

---

# 8. IWRR Example

Consider:

```text
Weights:

W0 = 1
W1 = 2
W2 = 3
W3 = 4
```

The rounds are:

```text
Round = 1

Requester 0 -> eligible
Requester 1 -> eligible
Requester 2 -> eligible
Requester 3 -> eligible
```

Possible service order:

```text
0 -> 1 -> 2 -> 3
```

Then:

```text
Round = 2
```

Requester 0 is no longer eligible because:

```text
W0 < 2
```

Remaining:

```text
1 -> 2 -> 3
```

Then:

```text
Round = 3

2 -> 3
```

Then:

```text
Round = 4

3
```

After the final round, the arbiter starts again from round 1.

---

# 9. IWRR Architecture

The main blocks are:

```text
                     +----------------+
req ---------------->|                |
                     |   Eligibility  |
weights ------------>|    Logic       |
                     +-------+--------+
                             |
                             v
                     +----------------+
                     | Round-Robin    |
                     | Priority       |
                     | Encoder        |
                     +-------+--------+
                             |
                             v
                         grant_next
                             |
                             v
                     +----------------+
                     | State Registers|
                     |                |
                     | round          |
                     | ptr            |
                     | served        |
                     +----------------+
```

The state registers control the next arbitration decision.

---

# 10. Module Interface

```verilog
module iwrr_arbiter #(
    parameter N          = 4,
    parameter MAX_WEIGHT = 4,
    parameter PTR_WIDTH  = 2,
    parameter WT_WIDTH   = 3
)(
    input                   clk,
    input                   rst_n,

    input  [N-1:0]          req,

    input  [WT_WIDTH-1:0]   weight0,
    input  [WT_WIDTH-1:0]   weight1,
    input  [WT_WIDTH-1:0]   weight2,
    input  [WT_WIDTH-1:0]   weight3,

    output [N-1:0]          grant
);
```

---

# 11. Parameters

| Parameter    | Default | Description                      |
| ------------ | ------: | -------------------------------- |
| `N`          |       4 | Number of requesters             |
| `MAX_WEIGHT` |       4 | Maximum IWRR round/weight        |
| `PTR_WIDTH`  |       2 | Width of round-robin pointer     |
| `WT_WIDTH`   |       3 | Width of weight and round values |

For the default configuration:

```text
N = 4
```

so there are four requesters:

```text
Requester 0
Requester 1
Requester 2
Requester 3
```

---

# 12. Input and Output Signals

| Signal    | Direction | Width | Description                   |
| --------- | --------- | ----: | ----------------------------- |
| `clk`     | Input     |     1 | Clock                         |
| `rst_n`   | Input     |     1 | Active-low asynchronous reset |
| `req`     | Input     |     4 | Request signals               |
| `weight0` | Input     |     3 | Weight of requester 0         |
| `weight1` | Input     |     3 | Weight of requester 1         |
| `weight2` | Input     |     3 | Weight of requester 2         |
| `weight3` | Input     |     3 | Weight of requester 3         |
| `grant`   | Output    |     4 | One-hot grant                 |

---

# 13. Request Signal

Each bit of `req` represents a requester.

```text
req[0] -> Requester 0
req[1] -> Requester 1
req[2] -> Requester 2
req[3] -> Requester 3
```

Example:

```text
req = 4'b1011
```

means:

```text
Requester 0 -> requesting
Requester 1 -> requesting
Requester 2 -> not requesting
Requester 3 -> requesting
```

---

# 14. Grant Signal

The grant is one-hot.

Only one bit should normally be asserted.

Examples:

```text
grant = 0001 -> requester 0
grant = 0010 -> requester 1
grant = 0100 -> requester 2
grant = 1000 -> requester 3
grant = 0000 -> nobody
```

One-hot arbitration makes it easy to connect the arbiter to a shared resource.

---

# 15. Internal State Registers

The design has three main state registers:

```verilog
reg [WT_WIDTH-1:0] round;
reg [PTR_WIDTH-1:0] ptr;
reg [N-1:0] served;
```

---

# 16. `round`

`round` indicates the current IWRR round.

After reset:

```verilog
round <= 1;
```

For:

```text
MAX_WEIGHT = 4
```

the round sequence is:

```text
1 -> 2 -> 3 -> 4 -> 1 -> 2 -> ...
```

The round determines which requesters are eligible.

---

# 17. `ptr`

`ptr` is the round-robin starting position.

For four requesters:

```text
ptr = 0
```

means priority starts from requester 0.

```text
ptr = 1
```

means priority starts from requester 1.

```text
ptr = 2
```

means priority starts from requester 2.

```text
ptr = 3
```

means priority starts from requester 3.

---

# 18. `served`

`served` records which requesters have already received a grant during the current IWRR round.

Example:

```text
served = 4'b0101
```

means:

```text
Requester 0 -> already served
Requester 1 -> not served
Requester 2 -> already served
Requester 3 -> not served
```

The arbiter prevents already-served requesters from receiving another grant in the same round.

---

# 19. Eligibility Logic

The eligibility condition for requester 0 is:

```verilog
assign eligible[0] = req[0] &&
                     !served[0] &&
                     (weight0 >= round);
```

Therefore requester 0 is eligible only when:

```text
req[0] = 1
AND
served[0] = 0
AND
weight0 >= round
```

The same principle is applied to all requesters.

---

# 20. Eligibility Conditions

For requester `i`:

```text
Eligible[i] =
Request[i]
AND
NOT Served[i]
AND
Weight[i] >= Current Round
```

Therefore:

```text
             req
              |
              v
        +-----------+
        | Request?  |
        +-----+-----+
              |
              v
        +-----------+
        | Not served|
        +-----+-----+
              |
              v
        +-----------+
        |Weight >=  |
        |  round?   |
        +-----+-----+
              |
              v
          eligible
```

---

# 21. Why `weight >= round`?

This is the key IWRR condition.

Suppose:

```text
weight0 = 1
weight1 = 2
weight2 = 3
weight3 = 4
```

At:

```text
round = 1
```

all requesters are eligible.

```text
1 >= 1 -> yes
2 >= 1 -> yes
3 >= 1 -> yes
4 >= 1 -> yes
```

At:

```text
round = 2
```

requester 0 becomes ineligible:

```text
1 >= 2 -> no
```

while:

```text
2 >= 2 -> yes
3 >= 2 -> yes
4 >= 2 -> yes
```

At:

```text
round = 4
```

only requester 3 is eligible:

```text
1 >= 4 -> no
2 >= 4 -> no
3 >= 4 -> no
4 >= 4 -> yes
```

This creates the weighted behavior.

---

# 22. Round-Robin Priority Encoder

After calculating eligibility, the arbiter selects one eligible requester.

The starting point is determined by:

```verilog
ptr
```

For example, if:

```text
ptr = 0
```

priority is:

```text
0 -> 1 -> 2 -> 3
```

If:

```text
ptr = 2
```

priority becomes:

```text
2 -> 3 -> 0 -> 1
```

This prevents a permanently fixed priority.

---

# 23. Priority Rotation

The four possible priority sequences are:

```text
ptr = 0

0 -> 1 -> 2 -> 3
```

```text
ptr = 1

1 -> 2 -> 3 -> 0
```

```text
ptr = 2

2 -> 3 -> 0 -> 1
```

```text
ptr = 3

3 -> 0 -> 1 -> 2
```

This is the round-robin part of IWRR.

---

# 24. `grant_next`

The priority encoder generates:

```verilog
wire [N-1:0] grant_next;
```

For example:

```text
eligible = 1011
ptr      = 0
```

Priority order:

```text
0 -> 1 -> 2 -> 3
```

Requester 0 is eligible, so:

```text
grant_next = 0001
```

---

# 25. Grant Generation

The final output is:

```verilog
assign grant = grant_next;
```

Therefore:

```text
grant
  |
  +----> combinational arbitration result
```

There is no additional output register.

Consequently, `grant` changes whenever the inputs or arbitration state change.

---

# 26. What Happens After a Grant?

Suppose:

```text
grant_next = 0010
```

which means requester 1 was selected.

The design executes:

```verilog
served <= served | grant_next;
```

If:

```text
served = 0000
```

then:

```text
served = 0010
```

Requester 1 is now marked as served.

---

# 27. Pointer Update

After granting requester 1:

```verilog
ptr <= 2'd2;
```

Therefore the next arbitration starts from requester 2.

The pointer update is:

```text
Grant 0 -> ptr = 1
Grant 1 -> ptr = 2
Grant 2 -> ptr = 3
Grant 3 -> ptr = 0
```

This creates circular priority.

---

# 28. Why Update Pointer After Grant?

Suppose the priority order is:

```text
0 -> 1 -> 2 -> 3
```

and requester 1 wins.

The next search starts at:

```text
2
```

instead of starting again at 0.

This prevents requester 0 from continuously winning whenever it requests.

---

# 29. What Happens When No Requester Is Eligible?

The design checks:

```verilog
if (grant_next != {N{1'b0}})
```

If a grant exists, the current round continues.

If:

```text
grant_next = 0000
```

there is no eligible requester.

The design then executes:

```verilog
served <= {N{1'b0}};
ptr    <= {PTR_WIDTH{1'b0}};
```

and advances the round.

---

# 30. Round Transition

The round update is:

```verilog
if (round == MAX_WEIGHT)
    round <= 1;
else
    round <= round + 1;
```

For:

```text
MAX_WEIGHT = 4
```

the sequence is:

```text
1 -> 2 -> 3 -> 4 -> 1
```

When the current round is finished, the next IWRR round begins.

---

# 31. Why Clear `served`?

At the end of a round:

```verilog
served <= {N{1'b0}};
```

This allows every requester to become eligible again in the next round.

Example:

```text
Round 1:

served = 1111
```

After completing the round:

```text
served = 0000
```

The next round can start.

---

# 32. Complete Arbitration Flow

```text
                req
                 |
                 v
        +----------------+
        | Eligibility    |
        | Logic          |
        +-------+--------+
                |
                v
             eligible
                |
                v
        +----------------+
        | Round-Robin    |
        | Priority       |
        | Encoder        |
        +-------+--------+
                |
                v
           grant_next
                |
          +-----+-----+
          |           |
       Grant?       No Grant
          |           |
          v           v
      served |=      Clear served
      grant           Reset ptr
          |           |
          v           v
      Update ptr   round++
          |           |
          +-----+-----+
                |
                v
             New state
```

---

# 33. Complete IWRR Example

Assume:

```text
N = 4

Weight0 = 1
Weight1 = 2
Weight2 = 3
Weight3 = 4
```

and all requesters continuously request:

```text
req = 4'b1111
```

### Round 1

All weights satisfy:

```text
weight >= 1
```

Possible service order:

```text
0 -> 1 -> 2 -> 3
```

---

### Round 2

Requester 0 is no longer eligible:

```text
Weight0 = 1 < 2
```

Remaining:

```text
1 -> 2 -> 3
```

---

### Round 3

Eligible:

```text
2 -> 3
```

---

### Round 4

Eligible:

```text
3
```

---

### Complete weighted sequence

```text
0 1 2 3 | 1 2 3 | 2 3 | 3
```

Count:

```text
Requester 0 = 1 grant
Requester 1 = 2 grants
Requester 2 = 3 grants
Requester 3 = 4 grants
```

Therefore:

```text
Service ratio = 1 : 2 : 3 : 4
```

when all requesters continuously request.

---

# 34. IWRR vs Round-Robin

| Feature                        | Round-Robin   | IWRR                           |
| ------------------------------ | ------------- | ------------------------------ |
| Equal service                  | Yes           | No                             |
| Weighted service               | No            | Yes                            |
| Priority rotates               | Yes           | Yes                            |
| Starvation prevention          | Good          | Good                           |
| Different bandwidth allocation | No            | Yes                            |
| Implementation complexity      | Lower         | Higher                         |
| Main use                       | Equal clients | Different traffic requirements |

---

# 35. IWRR vs Fixed Priority

### Fixed Priority

Example:

```text
0 > 1 > 2 > 3
```

Requester 0 always has the highest priority.

If requester 0 continuously requests, lower-priority requesters may starve.

### IWRR

Priority rotates:

```text
0 -> 1 -> 2 -> 3
```

and weights control the amount of service.

Therefore IWRR provides better fairness while allowing weighted bandwidth allocation.

---

# 36. IWRR State Machine Concept

Although this RTL does not explicitly define a Verilog FSM, its state can be understood as:

```text
+----------------+
| Current Round  |
+-------+--------+
        |
        v
+----------------+
| Find Eligible  |
+-------+--------+
        |
        v
+----------------+
| Grant One      |
+-------+--------+
        |
        v
+----------------+
| Mark Served    |
+-------+--------+
        |
        v
+----------------+
| Update Pointer |
+-------+--------+
        |
        v
  More eligible?
      /    \
    Yes     No
     |       |
     |       v
     |   Next Round
     |       |
     +-------+
```

---

# 37. Reset Behavior

The design uses:

```verilog
always @(posedge clk or negedge rst_n)
```

Therefore the reset is:

**Asynchronous active-low reset.**

When:

```text
rst_n = 0
```

the registers immediately become:

```text
round  = 1
ptr    = 0
served = 0
```

Specifically:

```verilog
round  <= 1;
ptr    <= 0;
served <= 0;
```

---

# 38. Reset State Diagram

```text
              rst_n = 0
                   |
                   v
        +----------------------+
        | Reset State           |
        |                      |
        | round  = 1           |
        | ptr    = 0           |
        | served = 0000        |
        +----------+-----------+
                   |
              rst_n = 1
                   |
                   v
             Arbitration
```

---

# 39. Timing Concept

The eligibility and priority encoder are combinational.

The state is updated at the clock edge.

```text
          Combinational
          arbitration
               |
               v
req ---> eligibility ---> priority ---> grant
                             |
                             v
                         state update
                             |
                         clock edge
                             |
                             v
                       New round/ptr
```

The output grant itself is combinational.

---

# 40. Synthesizable RTL

The design uses synthesizable constructs such as:

```verilog
always @(posedge clk or negedge rst_n)
```

```verilog
assign
```

```verilog
case
```

```verilog
if / else
```

and parameter declarations.

The `for` loop is not required in this implementation because the four requesters are explicitly coded.

---

# 41. Important Parameterization Note

The module declares:

```verilog
parameter N = 4
```

but the current implementation explicitly defines:

```verilog
eligible[0]
eligible[1]
eligible[2]
eligible[3]
```

and the priority encoder explicitly handles four requesters.

Therefore, the current RTL is **functionally designed for 4 requesters**, even though `N` is declared as a parameter.

Similarly, the module explicitly declares:

```verilog
weight0
weight1
weight2
weight3
```

Therefore, changing:

```text
N = 4
```

to another value does not automatically make the module support that number of requesters.

For true arbitrary-`N` parameterization, the weights would normally be represented as an array and the eligibility/priority logic would be generated using loops.

---

# 42. Important Parameterization Consideration for `PTR_WIDTH`

For four requesters:

```text
N = 4
```

two pointer bits are sufficient:

```text
PTR_WIDTH = 2
```

because:

```text
2^2 = 4
```

Therefore:

```text
ptr = 00 -> requester 0
ptr = 01 -> requester 1
ptr = 10 -> requester 2
ptr = 11 -> requester 3
```

For a generic design, pointer width can be derived using:

```verilog
$clog2(N)
```

For example:

```verilog
parameter PTR_WIDTH = $clog2(N);
```

---

# 43. Important Weight Consideration

The weight width is:

```text
WT_WIDTH = 3
```

Therefore the weight can represent:

```text
0 to 7
```

The default maximum weight is:

```text
MAX_WEIGHT = 4
```

The IWRR rounds are therefore:

```text
1
2
3
4
```

A weight of zero means that:

```text
weight < round
```

for every valid round, so that requester will never become eligible.

---

# 44. PPA Considerations

IWRR has more logic than a simple fixed-priority arbiter because it requires:

* Eligibility logic
* Weight comparison
* Served tracking
* Round tracking
* Pointer tracking
* Rotating priority selection

The main timing path is approximately:

```text
req/weight
   |
   v
Eligibility comparison
   |
   v
Round-robin priority encoder
   |
   v
grant
```

As the number of requesters increases, this logic can become larger.

For high-performance implementations, the priority encoder and eligibility logic may need optimization or pipelining.

---

# 45. Applications

IWRR arbiters are useful when multiple clients require shared resources with different bandwidth requirements.

Typical applications include:

* Network switches
* Routers
* NoC (Network-on-Chip)
* AXI/AMBA interconnects
* Memory controllers
* DMA controllers
* Bus arbitration
* Packet schedulers
* Shared SRAM access
* Multi-channel communication systems

---

# 46. Example Network Application

Consider four network queues:

```text
Queue 0 ----\
Queue 1 -----\
Queue 2 ------> IWRR Arbiter ---> Output Link
Queue 3 -----/
```

Weights could be:

```text
Queue 0 = 1
Queue 1 = 2
Queue 2 = 3
Queue 3 = 4
```

This allows higher-weight queues to receive more transmission opportunities.

---

# 47. Example Memory Arbitration

```text
CPU --------\
DMA ---------\
GPU ----------> IWRR ---> SRAM
Network -----/
```

Different weights can be assigned based on desired bandwidth.

For example:

```text
CPU     = 4
DMA     = 2
GPU     = 3
Network = 1
```

The arbiter then provides weighted access to the shared memory.

---

# 48. Verification Strategy

The RTL should be verified for:

### Reset

Verify:

```text
round  = 1
ptr    = 0
served = 0
```

after reset.

### One requester

If only one requester requests:

```text
req = 0001
```

then:

```text
grant = 0001
```

when it is eligible.

### Multiple requesters

For:

```text
req = 1111
```

verify that the grant rotates correctly.

### Weight behavior

Verify:

```text
weight0 = 1
weight1 = 2
weight2 = 3
weight3 = 4
```

produces the expected weighted service.

### No requests

When:

```text
req = 0000
```

verify:

```text
grant = 0000
```

and the round eventually advances.

### Already served requester

Verify that a requester cannot be selected twice during the same IWRR round.

---

# 49. Example Test Cases

### Test Case 1  Reset

```text
rst_n = 0

Expected:

round  = 1
ptr    = 0
served = 0000
grant  = 0000
```

---

### Test Case 2  Only Requester 0

```text
req = 0001
weight0 = 4
```

Expected:

```text
grant = 0001
```

---

### Test Case 3  All Requesters

```text
req = 1111

weight0 = 1
weight1 = 2
weight2 = 3
weight3 = 4
```

Expected weighted service over a complete IWRR cycle:

```text
0 : 1 time
1 : 2 times
2 : 3 times
3 : 4 times
```

---

# 50. Recommended Self-Checking Testbench

A self-checking testbench should:

1. Apply reset.
2. Configure requester weights.
3. Drive request patterns.
4. Observe `grant`.
5. Maintain a software/reference model of IWRR.
6. Compare expected and actual grants.
7. Report PASS/FAIL.

Example:

```verilog
if (grant == expected_grant)
    $display("PASS");
else
    $display("FAIL");
```

---

# 51. Simulation with Cadence Xcelium

Compile the RTL and testbench using:

```bash
xrun iwrr_arbiter.v iwrr_arbiter_tb.v -access +rwc
```

For GUI:

```bash
xrun iwrr_arbiter.v iwrr_arbiter_tb.v -access +rwc -gui
```

Using a file list:

```bash
xrun -f flist.f -access +rwc
```

Example `flist.f`:

```text
iwrr_arbiter.v
iwrr_arbiter_tb.v
```

---

# 52. Expected Waveform

Important signals to observe:

```text
clk
rst_n
req
weight0
weight1
weight2
weight3
round
ptr
served
eligible
grant
```

Conceptually:

```text
             +-----+-----+-----+-----+
clk          |     |     |     |     |
             +-----+-----+-----+-----+

req          1111  1111  1111  1111

round          1     1     2     2
               |
               +---------------->

grant        0001  0010  0010  0100
               |     |     |     |
               v     v     v     v
              R0    R1    R1    R2
```

The exact waveform depends on the request and weight values.

---

# 53. RTL Design Flow

```text
Specification
      |
      v
Define requesters
      |
      v
Assign weights
      |
      v
Calculate eligibility
      |
      v
Round-robin selection
      |
      v
Generate grant
      |
      v
Update served state
      |
      v
Update pointer
      |
      v
Advance IWRR round
      |
      v
Verification
      |
      v
Synthesis / PPA analysis
```

---

# 54. Key Design Equations

The main eligibility equation is:

```text
Eligible[i] =
    Request[i]
    AND
    NOT Served[i]
    AND
    (Weight[i] >= Round)
```

The served-state update is:

```text
Served_next = Served OR Grant
```

When the current round finishes:

```text
Served_next = 0
```

The round update is:

```text
if Round == MAX_WEIGHT
    Round_next = 1
else
    Round_next = Round + 1
```

The pointer moves to the requester after the granted requester:

```text
Grant 0 -> Pointer 1
Grant 1 -> Pointer 2
Grant 2 -> Pointer 3
Grant 3 -> Pointer 0
```

---

# 55. Design Summary

```text
+------------------------------------------------------+
|                    IWRR ARBITER                      |
|                                                      |
|  Requesters                                           |
|  req[3:0]                                             |
|      |                                                |
|      v                                                |
|  +---------------------+                              |
|  | Eligibility Logic   | <--- weights                 |
|  | req & !served       |                              |
|  | weight >= round     |                              |
|  +----------+----------+                              |
|             |                                         |
|             v                                         |
|  +---------------------+                              |
|  | Rotating Priority   | <--- ptr                     |
|  | Encoder             |                              |
|  +----------+----------+                              |
|             |                                         |
|             v                                         |
|          grant_next                                   |
|             |                                         |
|             v                                         |
|  +---------------------+                              |
|  | State Registers     |                              |
|  | round / ptr / served|                              |
|  +---------------------+                              |
|             |                                         |
|             +-----------------------------------------+
+------------------------------------------------------+
```

---

# 56. Key Takeaways

* **IWRR** stands for **Interleaved Weighted Round-Robin**.
* It is an arbitration algorithm for sharing a resource among multiple requesters.
* `weight` determines how much service a requester receives.
* `round` determines which weight levels are currently active.
* `served` prevents the same requester from receiving multiple grants in one IWRR round.
* `ptr` implements rotating round-robin priority.
* `grant` is a one-hot signal.
* The current design supports four explicitly coded requesters.
* The eligibility equation is:

```text
req && !served && (weight >= round)
```

* When no eligible requester remains, the arbiter clears `served` and advances to the next round.
* With weights `1:2:3:4`, a complete IWRR cycle provides approximately:

```text
Requester 0 : 1 service
Requester 1 : 2 services
Requester 2 : 3 services
Requester 3 : 4 services
```

* Compared with fixed priority, IWRR provides better fairness.
* Compared with ordinary round-robin, IWRR supports unequal bandwidth allocation.
* The current RTL is written for a **4-requester implementation**, despite declaring `N` as a parameter.

