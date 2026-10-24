# Parallel Prefix Adders

## Overview

Parallel Prefix Adders are high-speed binary adders that compute carry signals in parallel using **generate** and **propagate** signals.

In a conventional Ripple Carry Adder (RCA), the carry propagates sequentially from the least significant bit (LSB) to the most significant bit (MSB). This creates a delay that increases with the operand width.

Parallel prefix adders reduce carry propagation delay by organizing the carry computation into multiple prefix stages.

The main difference between the different parallel prefix adders is the **topology of the prefix network**.

This repository contains parameterized Verilog RTL implementations of the following parallel prefix adders:

* Kogge-Stone Adder
* Brent-Kung Adder
* Sklansky Adder
* Ladner-Fischer Adder
* Han-Carlson Adder
* Knowles Adder

---

# Directory Structure

```text
ALU/ +-- Adders/ +-- Parallel-Prefix-Adders/ +-- brentkung.v +-- hancarlson.v +-- knowles.v +-- koggestone.v +-- ladnerfischer.v +-- sklanksy.v +-- Readme.md     
```

---

# 1. Generate and Propagate Logic

All the parallel prefix adders in this repository are based on generate and propagate signals.

For each bit `i`:

## Generate

```text
Gi = Ai & Bi
```

`Gi = 1` means that bit `i` generates a carry.

## Propagate

The RTL implementations use XOR propagate:

```text
Pi = Ai ^ Bi
```

`Pi = 1` means that an incoming carry can propagate through bit `i`.

## Carry Equation

The basic carry equation is:

```text
Ci+1 = Gi | (Pi & Ci)
```

where:

* `Gi` = generate
* `Pi` = propagate
* `Ci` = carry entering bit `i`
* `Ci+1` = carry leaving bit `i`

## Sum Equation

```text
Si = Pi ^ Ci
```

Therefore:

```text
Sum = Propagate ^ Carry
```

---

# 2. Prefix Operation

The basic prefix operation combines two generate/propagate groups.

Consider:

```text
(Gi, Pi)
(Gj, Pj)
```

The combined group is:

```text
Gij = Gi | (Pi & Gj)

Pij = Pi & Pj
```

This operation allows multiple bits to be combined into a single group.

For example, a four-bit group can generate:

```text
G3:0 = G3 | P3G2 | P3P2G1 | P3P2P1G0
```

and:

```text
P3:0 = P3 & P2 & P1 & P0
```

The different prefix architectures use this same mathematical operation but arrange the operations differently.

---

# 3. Prefix Cells

## 3.1 Black Cell

A black cell calculates both group generate and group propagate.

```text
Gout = Gleft | (Pleft & Gright)

Pout = Pleft & Pright
```

Conceptually:

```text
              +-------------+
Gleft --------?             ¦
Pleft --------? Black Cell  +----? Gout
Gright -------?             +----? Pout
Pright -------?             ¦
              +-------------+
```

## 3.2 Gray Cell

A gray cell calculates only group generate.

```text
Gout = Gleft | (Pleft & Gright)
```

Conceptually:

```text
              +-------------+
Gleft --------?             ¦
Pleft --------? Gray Cell   +----? Gout
Gright -------?             ¦
              +-------------+
```

---

# 4. Common RTL Flow

All the adders follow the same high-level flow:

```text
             A
             ¦
             ¦
             ?
      Generate / Propagate
             ¦
             ?
       Prefix Network
             ¦
             ?
       Carry Generation
             ¦
             ?
        Sum Generation
             ¦
             ?
        Sum / Carry Out
```

The difference is the structure of the **Prefix Network**.

---

# 5. Kogge-Stone Adder

## 5.1 Overview

The Kogge-Stone Adder (KSA) is a dense parallel-prefix architecture designed for fast carry computation.

Each prefix level increases the distance of the prefix calculation by a factor of two.

For a 16-bit implementation:

```text
Level 0 : Initial Generate / Propagate
Level 1 : Distance = 1
Level 2 : Distance = 2
Level 3 : Distance = 4
Level 4 : Distance = 8
```

The prefix distance follows:

```text
1 ? 2 ? 4 ? 8
```

The number of levels is:

```text
LEVELS = log2(WIDTH)
```

---

## 5.2 Prefix Equations

For each level:

```text
Gnew[i] = Gold[i] | (Pold[i] & Gold[i-distance])

Pnew[i] = Pold[i] & Pold[i-distance]
```

where:

```text
distance = 2^level
```

If the required previous node does not exist, the node is passed through as a buffer.

---

## 5.3 Architecture

```text
A,B
 ¦
 ?
Generate / Propagate
 ¦
 ?
Level 1 -- Distance 1
 ¦
 ?
Level 2 -- Distance 2
 ¦
 ?
Level 3 -- Distance 4
 ¦
 ?
Level 4 -- Distance 8
 ¦
 ?
Carry
 ¦
 ?
Sum
```

---

## 5.4 Characteristics

* Very low prefix logic depth
* Dense prefix network
* Large number of interconnections
* Low carry computation latency
* High routing demand

### How to choose

```text
Aggressive timing target ? Kogge-Stone
```

---

# 6. Brent-Kung Adder

## 6.1 Overview

The Brent-Kung Adder (BKA) uses fewer prefix cells and less wiring than the Kogge-Stone architecture.

The architecture consists of two main operations:

1. Reduction / up-sweep
2. Distribution / down-sweep

The reduction phase calculates selected group prefixes, while the distribution phase provides the required carry information to the remaining bits.

---

## 6.2 Architecture

```text
Generate / Propagate
        ¦
        ?
   Up-Sweep
        ¦
        ?
 Group Prefixes
        ¦
        ?
  Down-Sweep
        ¦
        ?
      Carry
        ¦
        ?
       Sum
```

---

## 6.3 Prefix Equations

The same prefix operation is used:

```text
Gij = Gi | (Pi & Gj)

Pij = Pi & Pj
```

The difference is the way these operations are connected.

---

## 6.4 Characteristics

* Fewer prefix cells than Kogge-Stone
* Lower wiring requirement
* Lower area
* Lower routing complexity
* Greater logic depth than Kogge-Stone

### How to choose

```text
Balanced area and timing with reduced wiring ? Brent-Kung
```

---

# 7. Sklansky Adder

## 7.1 Overview

The Sklansky Adder is also known as a **divide-and-conquer prefix adder**.

It forms larger prefix groups progressively.

For a 16-bit implementation:

```text
Level 1 : Distance = 1
Level 2 : Distance = 2
Level 3 : Distance = 4
Level 4 : Distance = 8
```

---

## 7.2 Group Structure

The prefix groups grow as:

```text
2-bit group
     ?
4-bit group
     ?
8-bit group
     ?
16-bit group
```

For example:

```text
Level 1:

[0 1] [2 3] [4 5] [6 7] [8 9] [10 11] [12 13] [14 15]

Level 2:

[0 1 2 3] [4 5 6 7] [8 9 10 11] [12 13 14 15]

Level 3:

[0 ... 7] [8 ... 15]

Level 4:

[0 ... 15]
```

---

## 7.3 Prefix Equations

The prefix operation is:

```text
Gnew = Gold | (Pold & Gprefix)

Pnew = Pold & Pprefix
```

The beginning of a group provides prefix information to the second half of the group.

---

## 7.4 Characteristics

* Low logic depth
* Divide-and-conquer structure
* High fanout at some nodes
* Significant wiring
* Fast prefix computation

### How to choose

```text
Low prefix depth with group-based distribution ? Sklansky
```

---

# 8. Ladner-Fischer Adder

## 8.1 Overview

The Ladner-Fischer Adder (LFA) is a parallel-prefix architecture that builds group prefix information through a tree structure.

It uses both:

* Buffer nodes
* Prefix combine nodes

For a 16-bit implementation:

```text
Level 1 : Distance = 1
Level 2 : Distance = 2
Level 3 : Distance = 4
Level 4 : Distance = 8
```

---

## 8.2 Architecture

```text
Initial G/P
     ¦
     ?
Prefix Level 1
     ¦
     ?
Prefix Level 2
     ¦
     ?
Prefix Level 3
     ¦
     ?
Prefix Level 4
     ¦
     ?
Carry
     ¦
     ?
Sum
```

---

## 8.3 Prefix Equations

```text
Gij = Gi | (Pi & Gj)

Pij = Pi & Pj
```

At each level, selected nodes combine their prefix information while other nodes are buffered.

---

## 8.4 Characteristics

* Fast carry computation
* Tree-based structure
* Moderate-to-high wiring
* More complex than simple ripple structures
* Suitable for high-speed arithmetic

### How to choose

```text
Fast tree-based prefix computation ? Ladner-Fischer
```

---

# 9. Han-Carlson Adder

## 9.1 Overview

The Han-Carlson Adder (HCA) is a hybrid parallel-prefix architecture.

It combines characteristics of sparse prefix structures with carry-completion logic.

A typical structure can be viewed as:

```text
Generate / Propagate
        ¦
        ?
 Sparse Prefix Network
        ¦
        ?
 Carry Completion
        ¦
        ?
      Carry
        ¦
        ?
       Sum
```

---

## 9.2 Prefix Operation

The basic prefix operation remains:

```text
Gij = Gi | (Pi & Gj)

Pij = Pi & Pj
```

The main difference is how many prefix nodes are calculated and where the carry completion is performed.

---

## 9.3 Characteristics

* Hybrid architecture
* Reduced prefix density compared with a fully dense network
* Good timing characteristics
* Reduced wiring compared with dense prefix structures
* Moderate implementation complexity

### How to choose

```text
Speed with reduced prefix wiring ? Han-Carlson
```

---

# 10. Knowles Adder

## 10.1 Overview

The Knowles Adder is a family of parallel-prefix structures that provides different topology configurations.

The structure uses prefix and buffer nodes to construct group generate and propagate signals.

For a 16-bit implementation:

```text
Level 1 : Distance = 1
Level 2 : Distance = 2
Level 3 : Distance = 4
Level 4 : Distance = 8
```

---

## 10.2 Prefix Equations

The basic operation is:

```text
Gnew = Gold | (Pold & Gprevious)

Pnew = Pold & Pprevious
```

The prefix distance increases at each level.

---

## 10.3 Characteristics

* Flexible prefix topology
* Different possible timing/area trade-offs
* Uses buffer and prefix nodes
* Useful for architectural exploration
* PPA depends on the selected configuration

### How to choose

```text
Flexible prefix topology exploration ? Knowles
```

---

# 11. Architecture Comparison

The following table describes the general architectural characteristics of the implementations.

| Architecture   | Prefix Depth       | Prefix Density | Wiring        | Fanout        | General Characteristic  |
| -------------- | ------------------ | -------------- | ------------- | ------------- | ----------------------- |
| Kogge-Stone    | Low                | High           | High          | Low           | Dense high-speed prefix |
| Brent-Kung     | Higher             | Low            | Low           | Low           | Area-efficient prefix   |
| Sklansky       | Low                | Moderate       | High          | High          | Divide-and-conquer      |
| Ladner-Fischer | Low                | Moderate       | Moderate/High | Moderate/High | Tree-based prefix       |
| Han-Carlson    | Low/Moderate       | Sparse/Hybrid  | Moderate      | Moderate      | Hybrid prefix           |
| Knowles        | Topology dependent | Configurable   | Configurable  | Configurable  | Flexible prefix family  |

> These are architectural characteristics. Actual PPA depends on the target technology, standard-cell library, synthesis constraints, physical implementation, clock target, and routing.

---

# 12. Timing, Area, Power and Routing Trade-offs

Parallel prefix architecture selection involves several PPA trade-offs.

## Kogge-Stone

```text
Low logic depth
      ?
Fast carry calculation
      ?
More prefix cells
      ?
More wiring
      ?
Higher routing complexity
```

## Brent-Kung

```text
Fewer prefix cells
      ?
Less wiring
      ?
Lower area
      ?
More logic depth
```

## Sklansky

```text
Low logic depth
      ?
Common prefix nodes
      ?
Higher fanout
      ?
Potential routing/buffering overhead
```

## Ladner-Fischer

```text
Fast prefix computation
      ?
Tree-based structure
      ?
Moderate/high wiring
```

## Han-Carlson

```text
Sparse prefix network
      ?
Carry completion
      ?
Reduced wiring
      ?
Balanced implementation characteristics
```

## Knowles

```text
Configurable topology
      ?
Different prefix arrangements
      ?
Different timing/area/wiring trade-offs
```

---

# 13. Parameterization

The RTL implementations are parameterized by operand width.

Example:

```verilog
module KoggeStone #(
    parameter WIDTH = 16
)(
    input  [WIDTH-1:0] A,
    input  [WIDTH-1:0] B,
    input              Cin,
    output [WIDTH-1:0] Sum,
    output             Cout
);
```

The number of prefix levels is calculated using:

```verilog
localparam LEVELS = $clog2(WIDTH);
```

### 8-bit

```text
WIDTH = 8

LEVELS = 3

Distances:
1 ? 2 ? 4
```

### 16-bit

```text
WIDTH = 16

LEVELS = 4

Distances:
1 ? 2 ? 4 ? 8
```

### 32-bit

```text
WIDTH = 32

LEVELS = 5

Distances:
1 ? 2 ? 4 ? 8 ? 16
```

This allows the same RTL architecture to be used for multiple operand widths.

---

# 14. Verification

Each adder should be verified against a reference arithmetic model.

The expected result is:

```verilog
Expected = A + B + Cin;
```

The DUT output is:

```verilog
{Cout, Sum}
```

A self-checking testbench can compare:

```verilog
if ({Cout, Sum} !== Expected)
    $display("FAIL");
else
    $display("PASS");
```

---

# 15. Recommended Test Cases

The following test cases should be included for each adder.

## Test 1: Zero Addition

```text
A   = 0000
B   = 0000
Cin = 0
```

Expected:

```text
Sum  = 0000
Cout = 0
```

---

## Test 2: Basic Addition

```text
A   = 0001
B   = 0001
Cin = 0
```

Expected:

```text
Sum = 0002
```

---

## Test 3: Carry-In

```text
A   = 0001
B   = 0001
Cin = 1
```

Expected:

```text
Sum = 0003
```

---

## Test 4: Maximum Value

```text
A   = FFFF
B   = 0000
Cin = 0
```

Expected:

```text
Sum  = FFFF
Cout = 0
```

---

## Test 5: Final Carry

```text
A   = FFFF
B   = 0001
Cin = 0
```

Expected:

```text
Sum  = 0000
Cout = 1
```

---

## Test 6: Maximum + Maximum

```text
A   = FFFF
B   = FFFF
Cin = 0
```

Expected:

```text
Sum  = FFFE
Cout = 1
```

---

## Test 7: MSB Carry

```text
A   = 8000
B   = 8000
Cin = 0
```

Expected:

```text
Sum  = 0000
Cout = 1
```

---

## Test 8: Alternating Pattern

```text
A = AAAA
B = 5555
```

This test checks propagation across alternating bit positions.

---

## Test 9: Random Testing

Random values should be generated for:

```text
A
B
Cin
```

and compared against:

```verilog
Expected = A + B + Cin;
```

---

# 16. Simulation

The RTL can be simulated using Cadence Xcelium.

For example:

```bash
xrun Kogge_Stone.v Kogge_Stone_tb.v -access +rwc
```

For a GUI simulation:

```bash
xrun Kogge_Stone.v Kogge_Stone_tb.v -access +rwc -gui
```

The same flow can be used for the other architectures by replacing the RTL and testbench filenames.

---

# 17. Synthesis and PPA Evaluation

For a meaningful PPA comparison, all architectures should be synthesized using the same:

* Technology library
* Process corner
* Voltage
* Temperature
* Operand width
* Clock constraint
* Input/output constraints
* Synthesis tool
* Optimization settings

The following metrics should be collected.

## Timing

```text
Critical Path Delay
Maximum Frequency
Worst Negative Slack
Total Negative Slack
```

## Area

```text
Total Cell Area
Combinational Area
Sequential Area
Number of Cells
```

## Power

```text
Dynamic Power
Leakage Power
Total Power
```

## Physical Implementation

If place-and-route is performed, additional metrics should be considered:

```text
Placement Area
Routing Area
Wire Length
Routing Congestion
Buffer Count
Fanout
```

---

# 18. PPA Evaluation Flow

```text
        RTL
         ¦
         ?
    RTL Simulation
         ¦
         ?
       Synthesis
         ¦
         +--------------? Area
         ¦
         +--------------? Timing
         ¦
         +--------------? Power
         ¦
         ?
   Place and Route
         ¦
         +--------------? Routing
         ¦
         +--------------? Congestion
         ¦
         +--------------? Post-layout Timing
```

The PPA comparison should be performed only after all architectures have been evaluated under equivalent conditions.

---

# 19. Architecture Selection Guidelines

The following statements summarize the architectural focus of each implementation:

```text
Aggressive high-speed carry computation
? Kogge-Stone

Reduced area and wiring with reasonable timing
? Brent-Kung

Divide-and-conquer prefix computation
? Sklansky

Fast tree-based prefix computation
? Ladner-Fischer

Hybrid speed and wiring trade-off
? Han-Carlson

Flexible prefix topology exploration
? Knowles
```

These are design-direction guidelines rather than universal rankings. The final architecture choice should be based on the requirements and measured implementation results for the target technology.

---

# 20. Key Differences

## Kogge-Stone

```text
Dense prefix network
Low logic depth
High wiring
High routing demand
```

## Brent-Kung

```text
Sparse prefix network
Higher logic depth
Lower wiring
Lower area
```

## Sklansky

```text
Divide-and-conquer
Low logic depth
High fanout
```

## Ladner-Fischer

```text
Tree-based prefix structure
Fast carry computation
Moderate/high wiring
```

## Han-Carlson

```text
Hybrid prefix structure
Sparse prefix computation
Carry completion
```

## Knowles

```text
Flexible prefix family
Configurable topology
Timing/area trade-off depends on configuration
```

---

# 21. Common RTL Design Pattern

The common RTL structure is:

```verilog
// Generate
assign G0 = A & B;

// Propagate
assign P0 = A ^ B;

// Prefix network
// Architecture-specific

// Carry
assign C[i+1] = G[i] | (P[i] & Cin);

// Sum
assign Sum = P0 ^ C[WIDTH-1:0];

// Final carry
assign Cout = C[WIDTH];
```

The prefix network between `G0/P0` and the carry calculation is what distinguishes each architecture.

---

# 22. Verification Status

| Adder          | Parameterized RTL | Testbench | Functional Verification | Synthesis |
| -------------- | ----------------- | --------- | ----------------------- | --------- |
| Kogge-Stone    | Yes               | Yes       | Pending                 | Pending   |
| Brent-Kung     | Yes               | Yes       | Pending                 | Pending   |
| Sklansky       | Yes               | Yes       | Pending                 | Pending   |
| Ladner-Fischer | Yes               | Yes       | Pending                 | Pending   |
| Han-Carlson    | Yes               | Yes       | Pending                 | Pending   |
| Knowles        | Yes               | Yes       | Pending                 | Pending   |

Update this table after running the RTL through the target simulation and synthesis flow.

---

# 23. Conclusion

Parallel Prefix Adders provide an efficient method for reducing carry propagation delay in binary addition.

All the architectures use the same fundamental generate/propagate equations:

```text
Gi = Ai & Bi

Pi = Ai ^ Bi

Gij = Gi | (Pi & Gj)

Pij = Pi & Pj

Ci+1 = Gi | (Pi & Ci)

Si = Pi ^ Ci
```

The main difference is the **prefix network topology**.

The architectures implemented in this repository provide different trade-offs between:

```text
Timing
Area
Power
Fanout
Wiring
Routing Complexity
```

Therefore, the most appropriate architecture depends on the target design requirements and implementation technology.

---

# References

1. P. M. Kogge and H. S. Stone, "A Parallel Algorithm for the Efficient Solution of a General Class of Recurrence Equations," *IEEE Transactions on Computers*, 1973.

2. R. P. Brent and H. T. Kung, "A Regular Layout for Parallel Adders," *IEEE Transactions on Computers*, 1982.

3. J. Sklansky, "Conditional-Sum Addition Logic," *IRE Transactions on Electronic Computers*, 1960.

4. R. E. Ladner and M. J. Fischer, "Parallel Prefix Computation," *Journal of the ACM*, 1980.

5. R. Han and V. G. Carlson, "Fast Area-Efficient VLSI Adders," *Proceedings of the 8th IEEE Symposium on Computer Arithmetic*, 1987.

6. S. Knowles, "A Family of Adders," *Proceedings of the 14th IEEE Symposium on Computer Arithmetic*, 1999.

