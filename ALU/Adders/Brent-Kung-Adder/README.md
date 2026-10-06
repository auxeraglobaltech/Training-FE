# 32-Bit Brent-Kung Adder

## 1. Introduction

This project presents the RTL implementation and verification of a **32-bit Brent-Kung Adder (BKA)** using Verilog.

A Brent-Kung Adder is a **parallel-prefix adder** that computes carry signals using a tree-based prefix structure. Instead of allowing the carry to propagate sequentially through all bit positions, the architecture combines propagate and generate information in parallel.

The design consists of **pre-processing logic, a Brent-Kung prefix network, and post-processing logic**.

---

## 2. Design Objective

The main objective of this project is to understand and implement the internal structure of a Brent-Kung parallel-prefix adder, including:

* Propagate and generate signal generation
* Prefix computation
* Black Cell operation
* Gray Cell operation
* Carry generation
* Sum generation
* Verification using a Verilog testbench

---

## 3. Brent-Kung Adder Structure

The overall architecture can be represented as:

```text
             A[31:0]
                │
             B[31:0]
                │
                ▼
       ┌─────────────────┐
       │ Pre-Processing  │
       │                 │
       │ Generate P, G   │
       └────────┬────────┘
                │
                ▼
       ┌─────────────────┐
       │  Prefix Network │
       │                 │
       │ Black + Gray    │
       │ Cells           │
       └────────┬────────┘
                │
             Carry
                │
                ▼
       ┌─────────────────┐
       │ Post-Processing │
       │                 │
       │ Generate Sum    │
       └────────┬────────┘
                │
          ┌─────┴─────┐
          ▼           ▼
       SUM[31:0]     COUT
```

---

## 4. Pre-Processing Stage

The pre-processing stage converts the input operands into **propagate (`P`)** and **generate (`G`)** signals.

For each bit `i`:

```text
Pᵢ = Aᵢ XOR Bᵢ

Gᵢ = Aᵢ AND Bᵢ
```

`Pᵢ` indicates whether the bit can propagate an incoming carry, while `Gᵢ` indicates whether the bit generates a carry.

### Pre-Processing Diagram

![alt text](<images/Post Processing Cell.png>)

---

## 5. Prefix Network

The prefix network combines the propagate and generate signals from different bit positions.

The basic prefix operation is:

```text
Gout = Gik OR (Pik AND Gkj)

Pout = Pik AND Pkj
```

By combining multiple bit positions into groups, the carry information can be calculated efficiently.

The Brent-Kung structure uses fewer prefix nodes than some other parallel-prefix architectures, providing a useful balance between speed, hardware complexity, and interconnect.

---

## 6. Black Cell

A Black Cell produces both **group generate** and **group propagate** signals.

```text
Gout = Gik OR (Pik AND Gkj)

Pout = Pik AND Pkj
```

Black Cells are used where both `G` and `P` information is required for further prefix calculations.

### Black Cell Diagram

![alt text](<images/Black cell.png>)

---

## 7. Gray Cell

A Gray Cell produces only the **group generate** signal.

```text
Gout = Gik OR (Pik AND Gkj)
```

Since the propagate output is not required at this stage, the Gray Cell contains only the logic necessary to generate the required carry information.

### Gray Cell Diagram

![alt text](<images/Gray cell.png>)

---

## 8. 32-Bit Prefix Tree

The Black Cells and Gray Cells are connected according to the Brent-Kung prefix structure to form the complete **32-bit prefix tree**.

The prefix tree progressively combines information from smaller groups into larger groups and then distributes the required carry information to the individual bit positions.

### Complete Prefix Tree

![alt text](<images/Brent-Kung Architecture.png>)

The tree structure is responsible for the parallel carry computation that distinguishes the Brent-Kung Adder from a conventional ripple-based adder.

---

## 9. Carry and Post-Processing

The initial carry is:

```text
C₀ = Cin
```

The carry relationship is:

```text
Cᵢ₊₁ = Gᵢ OR (Pᵢ AND Cᵢ)
```

Once the prefix network determines the required carry signals, the post-processing stage generates the sum.

The sum equation is:

```text
Sumᵢ = Pᵢ XOR Cᵢ
```

For the 32-bit implementation:

```text
Sum[31:0] = P[31:0] XOR C[31:0]

Cout = C32
```

### Post-Processing Diagram

![alt text](<images/Post Processing Cell.png>)

---

## 10. RTL Implementation

The design is implemented using **Verilog RTL**.

The RTL follows the Brent-Kung architecture and includes the logic required for:

1. Propagate/generate generation
2. Prefix computation
3. Carry generation
4. Sum generation

The design accepts:

| Signal |   Width | Description    |
| ------ | ------: | -------------- |
| `A`    | 32 bits | First operand  |
| `B`    | 32 bits | Second operand |
| `Cin`  |   1 bit | Input carry    |

The outputs are:

| Signal |   Width | Description     |
| ------ | ------: | --------------- |
| `Sum`  | 32 bits | Addition result |
| `Cout` |   1 bit | Final carry     |

---

## 11. Verification

The RTL is verified using a dedicated **Verilog testbench**.

The testbench applies different combinations of:

```text
A
B
Cin
```

and verifies:

```text
Sum
Cout
```

### Verification Cases

The testbench covers:

* Zero operands
* Basic addition
* Addition with carry-in
* Carry propagation
* Maximum operand values
* Final carry generation
* Multiple input combinations


---

## 12. RTL and Testbench Files

The implementation consists of the Verilog RTL and its corresponding testbench.

```text
Brent-Kung-Adder/
│
├── blackcell.v
├── graycell.v
├── preprocess.v
├── postprocess.v
├── whitecell.v
├── brentkung.v
├── tb_brent_kung_adder.v
│
├── images/
│   ├── Pre Processing Logic Circuit.png
│   ├── Black cell.png
│   ├── Gray cell.png
│   ├── Post Processing Cell.png
│   └── Brent-Kung Architecture.png
│
└── README.md
```



---

## 13. Advantages

* Parallel carry computation
* Reduced carry propagation delay compared with Ripple Carry Adders
* Structured prefix architecture
* Uses separate Black Cell and Gray Cell functions
* Suitable for high-speed arithmetic datapaths
* Provides a good balance between speed and hardware complexity

---

## 14. Conclusion

The 32-bit Brent-Kung Adder was implemented using Verilog RTL and verified using a Verilog testbench.

The implementation demonstrates the complete operation of a parallel-prefix adder, starting from propagate and generate signal generation, followed by prefix computation using Black Cells and Gray Cells, carry generation, and final sum generation.

The project provides practical understanding of **parallel-prefix architectures, carry computation, RTL implementation, verification**.

---

## 15. References

1. R. P. Brent and H. T. Kung, **"A Regular Layout for Parallel Adders,"** IEEE Transactions on Computers, vol. C-31, no. 3, pp. 260–264, March 1982.
   DOI: `10.1109/TC.1982.1675982`

2. R. P. Brent, **"A Regular Layout for Parallel Adders,"** Australian National University, Publications.
   https://maths-people.anu.edu.au/~brent/pub/pub060.html

3. H. T. Kung, **Harvard University Publications – A Regular Layout for Parallel Adders.**
   https://www.eecs.harvard.edu/htk/publications/




