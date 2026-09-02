# RTL Design Specification

## Transition Packer FIFO with AXI Memory Interface

---

## 1. Introduction

This document describes the RTL design of a transition-based data packing and buffering system. The design accepts variable-width transition data, packs the incoming data into fixed-width 64-bit words, stores the packed words in a FIFO buffer, and transfers FIFO data to AXI memory using a 512-bit AXI write interface.

The design consists of multiple functional blocks responsible for data packing, temporary buffering, FIFO management, AXI write transactions, and AXI memory access.

The primary purpose of the design is to efficiently convert variable-width transition data into fixed-size memory words suitable for storage and transfer through a high-bandwidth AXI interface.

---

## 2. Design Objective

The main objectives of the design are:

* Accept variable-width transition data.
* Pack transition data into fixed 64-bit FIFO words.
* Preserve the order of incoming transition bits.
* Handle transitions that cross a 64-bit packing boundary.
* Provide backpressure when the FIFO cannot accept additional data.
* Store packed data in a 512-entry FIFO.
* Read FIFO data sequentially.
* Combine eight 64-bit FIFO words into one 512-bit AXI data word.
* Transfer packed data to AXI memory using AXI write transactions.
* Support sequential AXI memory addressing.
* Provide an interface for AXI memory read operations where implemented.

---

## 3. High-Level Architecture

The overall data flow is:

```text
Variable Width Transition Input
            ¦
            ?
    +-------------------+
    ¦ Transition Packer ¦
    ¦                   ¦
    ¦ Variable Width    ¦
    ¦       ?           ¦
    ¦ 64-bit Data Word  ¦
    +-------------------+
              ¦
              ¦ fifo_wr_en
              ¦ fifo_wr_data
              ?
    +-------------------+
    ¦    FIFO Buffer    ¦
    ¦                   ¦
    ¦ 64-bit × 512      ¦
    +-------------------+
              ¦
              ¦ fifo_rd_en
              ¦ fifo_rd_data
              ?
    +-------------------+
    ¦  FIFO AXI Wrapper ¦
    ¦                   ¦
    ¦ 8 × 64-bit        ¦
    ¦       ?           ¦
    ¦ 1 × 512-bit       ¦
    +-------------------+
              ¦
              ¦ AXI Write Interface
              ?
    +-------------------+
    ¦      AXI RAM      ¦
    +-------------------+
```

---

# 4. Module Description

The design consists of the following major modules:

| Module              | Function                                               |
| ------------------- | ------------------------------------------------------ |
| `transition_packer` | Packs variable-width transition data into 64-bit words |
| `fifo_buffer`       | Stores packed 64-bit words                             |
| `fifo_axi_wrapper`  | Reads FIFO data and creates AXI transactions           |
| `axi_ram`           | AXI-compatible memory model                            |
| `fifo_top`          | Integrates all modules together                        |

---

# 5. Transition Packer

## 5.1 Purpose

The `transition_packer` module accepts transition data with variable bit widths and packs the data into fixed-width 64-bit FIFO words.

The transition width is provided through the `trans_width` input.

A transition is accepted only when:

```text
trans_valid = 1
AND
trans_ready = 1
```

---

## 5.2 Interface Description

| Signal         | Direction | Width | Description                      |
| -------------- | --------- | ----: | -------------------------------- |
| `clk`          | Input     |     1 | System clock                     |
| `rst`          | Input     |     1 | Active-high synchronous reset    |
| `trans_valid`  | Input     |     1 | Indicates valid transition data  |
| `trans_ready`  | Output    |     1 | Indicates packer can accept data |
| `trans_data`   | Input     |    64 | Transition data                  |
| `trans_width`  | Input     |     7 | Number of valid bits             |
| `fifo_wr_en`   | Output    |     1 | FIFO write enable                |
| `fifo_wr_data` | Output    |    64 | Packed FIFO word                 |
| `fifo_full`    | Input     |     1 | FIFO full indication             |

---

## 5.3 Internal Registers

### Packing Buffer

```text
pack_buffer
```

The packing buffer stores transition bits that have not yet formed a complete 64-bit word.

### Packing Count

```text
pack_count
```

This register stores the number of valid bits currently stored in the packing buffer.

Range:

```text
0 to 63 bits
```

### Pending Data

```text
pending_data
pending_valid
```

When a complete 64-bit word is generated but the FIFO cannot accept it immediately, the completed word is stored in `pending_data`.

`pending_valid` indicates that a pending FIFO word exists.

---

# 6. Transition Packing Operation

The transition packer supports three main cases.

---

## 6.1 Case 1: Transition Fits Within Current Word

Condition:

```text
pack_count + trans_width < DATA_WIDTH
```

The transition is placed into the current packing buffer.

Operation:

```text
pack_buffer = pack_buffer OR
              (trans_data shifted by pack_count)
```

The valid bit count is increased:

```text
pack_count = pack_count + trans_width
```

Example:

```text
Current packed bits = 24
Incoming transition = 24 bits

Total = 48 bits
```

The transition fits inside the current 64-bit word.

No FIFO write occurs.

---

## 6.2 Case 2: Transition Exactly Fills the Word

Condition:

```text
pack_count + trans_width = DATA_WIDTH
```

The transition completes the current 64-bit word.

The completed word is stored in:

```text
pending_data
```

and:

```text
pending_valid = 1
```

The packing buffer is cleared:

```text
pack_buffer = 0
pack_count  = 0
```

The completed word is transferred to the FIFO when the FIFO is not full.

---

## 6.3 Case 3: Transition Crosses the 64-bit Boundary

Condition:

```text
pack_count + trans_width > DATA_WIDTH
```

Part of the transition completes the current 64-bit word.

The current word is stored as:

```text
pending_data =
    pack_buffer |
    (trans_data << pack_count)
```

The completed word becomes pending for FIFO transfer.

The remaining bits are retained for the next FIFO word.

Example:

```text
pack_count  = 48
trans_width = 24
```

Only:

```text
64 - 48 = 16 bits
```

are required to complete the current word.

The remaining:

```text
24 - 16 = 8 bits
```

are stored in the packing buffer for the next word.

---

# 7. Transition Packer Backpressure

The transition input ready signal is defined as:

```text
trans_ready =
    !pending_valid ||
    (pending_valid && !fifo_full)
```

This means:

### Condition 1

If no pending FIFO word exists:

```text
pending_valid = 0
```

The packer can accept new transition data.

### Condition 2

If a pending FIFO word exists but the FIFO is available:

```text
pending_valid = 1
fifo_full     = 0
```

The pending word can be transferred and new input can be accepted.

### Condition 3

If a pending word exists and FIFO is full:

```text
pending_valid = 1
fifo_full     = 1
```

The packer applies backpressure:

```text
trans_ready = 0
```

---

# 8. FIFO Buffer

## 8.1 Purpose

The FIFO buffer stores the packed 64-bit words generated by the transition packer.

The FIFO supports:

* Sequential writes.
* Sequential reads.
* Full detection.
* Empty detection.
* Circular pointer operation.

---

## 8.2 FIFO Parameters

| Parameter    | Value | Description              |
| ------------ | ----: | ------------------------ |
| `DATA_WIDTH` |    64 | Width of each FIFO entry |
| `FIFO_DEPTH` |   512 | Number of FIFO entries   |
| `ADDR_WIDTH` |     9 | Address width            |

Since:

```text
2^9 = 512
```

a 9-bit address is sufficient to access all FIFO locations.

---

## 8.3 FIFO Memory

The FIFO memory is implemented as:

```text
mem [0:FIFO_DEPTH-1]
```

Each entry stores:

```text
DATA_WIDTH bits
```

For the current configuration:

```text
512 × 64 bits
```

Total storage capacity:

```text
32768 bits
```

or:

```text
4096 bytes
```

---

# 9. FIFO Pointer Architecture

The FIFO uses read and write pointers with one additional MSB.

```text
wr_ptr [ADDR_WIDTH:0]
rd_ptr [ADDR_WIDTH:0]
```

For a 512-depth FIFO:

```text
Pointer width = 10 bits
```

The lower 9 bits represent the memory address.

The extra MSB is used to distinguish between the full and empty conditions.

---

# 10. FIFO Empty Detection

The FIFO is empty when:

```text
wr_ptr == rd_ptr
```

This means no unread data exists in the FIFO.

RTL expression:

```text
empty = (wr_ptr == rd_ptr)
```

---

# 11. FIFO Full Detection

The FIFO is full when:

* Read and write addresses are equal.
* The extra MSBs are different.

RTL expression:

```text
full =
(wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]) &&
(wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH])
```

This allows the FIFO to distinguish between:

```text
Same pointers ? FIFO Empty
Same address + different MSB ? FIFO Full
```

---

# 12. FIFO Write Operation

A FIFO write occurs when:

```text
wr_en = 1
AND
full = 0
```

This condition is represented internally as:

```text
write_fire = wr_en && !full
```

When a write occurs:

1. `wr_data` is written into the current write pointer location.
2. The write pointer increments.
3. When the pointer reaches the final FIFO address, it wraps to zero.
4. The extra MSB toggles during pointer wraparound.

---

# 13. FIFO Read Operation

A FIFO read occurs when:

```text
rd_en = 1
AND
empty = 0
```

This condition is represented as:

```text
read_fire = rd_en && !empty
```

When a read occurs:

1. Data is read from the current read pointer location.
2. The read data is registered into `rd_data`.
3. The read pointer increments.
4. When the final FIFO location is reached, the pointer wraps to zero.
5. The extra MSB toggles during pointer wraparound.

The FIFO read operation is synchronous because `rd_data` is updated inside a clocked always block.

---

# 14. FIFO Read Timing

The FIFO uses synchronous read behavior.

```text
Cycle N:
    rd_en asserted

Clock edge:
    FIFO reads memory location
    rd_data updated
    rd_ptr increments
```

Therefore, the FIFO AXI wrapper must account for the registered nature of `rd_data`.

---

# 15. FIFO to AXI Data Conversion

The FIFO stores:

```text
64-bit words
```

The AXI interface uses:

```text
512-bit data words
```

Therefore:

```text
512 / 64 = 8
```

Eight FIFO words are combined into one AXI data word.

```text
FIFO Word 0 -+
FIFO Word 1 -¦
FIFO Word 2 -¦
FIFO Word 3 -¦
FIFO Word 4 -¦--? 512-bit AXI Data
FIFO Word 5 -¦
FIFO Word 6 -¦
FIFO Word 7 -+
```

The resulting AXI word is organized as:

```text
[63:0]      = FIFO Word 0
[127:64]    = FIFO Word 1
[191:128]   = FIFO Word 2
[255:192]   = FIFO Word 3
[319:256]   = FIFO Word 4
[383:320]   = FIFO Word 5
[447:384]   = FIFO Word 6
[511:448]   = FIFO Word 7
```

---

# 16. FIFO AXI Wrapper

## 16.1 Purpose

The FIFO AXI wrapper performs the following operations:

1. Detect FIFO data availability.
2. Generate FIFO read requests.
3. Capture 64-bit FIFO words.
4. Collect eight FIFO words.
5. Create a 512-bit AXI data word.
6. Generate an AXI write transaction.
7. Wait for the AXI write response.
8. Increment the AXI memory address.

---

# 17. FIFO AXI Wrapper FSM

The wrapper uses the following states:

| State               | Description                 |
| ------------------- | --------------------------- |
| `IDLE`              | Wait for FIFO data          |
| `FIFO_READ_REQ`     | Request FIFO data           |
| `FIFO_READ_CAPTURE` | Capture FIFO output         |
| `AXI_AW`            | Send AXI write address      |
| `AXI_W`             | Send AXI write data         |
| `AXI_B`             | Wait for AXI write response |

---

## 17.1 IDLE State

The wrapper waits until:

```text
fifo_empty = 0
```

When data is available:

```text
state ? FIFO_READ_REQ
```

The data buffer and FIFO word counter are initialized before starting a new AXI transfer.

---

## 17.2 FIFO_READ_REQ State

The wrapper asserts:

```text
fifo_rd_en = 1
```

when the FIFO is not empty.

The FIFO performs a synchronous read.

The wrapper then moves to:

```text
FIFO_READ_CAPTURE
```

---

## 17.3 FIFO_READ_CAPTURE State

The wrapper captures:

```text
fifo_rd_data
```

into the AXI data buffer.

The position is determined by:

```text
fifo_word_count
```

Conceptually:

```text
axi_data_buffer[
    fifo_word_count × FIFO_DATA_WIDTH
    +:
    FIFO_DATA_WIDTH
] = fifo_rd_data
```

After collecting eight FIFO words:

```text
state ? AXI_AW
```

Otherwise, the wrapper requests another FIFO word.

---

# 18. AXI Write Operation

The AXI write operation consists of three channels:

1. Write Address Channel (AW)
2. Write Data Channel (W)
3. Write Response Channel (B)

---

## 18.1 AXI Write Address Channel

The following signals are used:

| Signal          | Description        |
| --------------- | ------------------ |
| `s_axi_awid`    | AXI transaction ID |
| `s_axi_awaddr`  | Write address      |
| `s_axi_awlen`   | Burst length       |
| `s_axi_awsize`  | Transfer size      |
| `s_axi_awburst` | Burst type         |
| `s_axi_awvalid` | Address valid      |
| `s_axi_awready` | Address ready      |

The current implementation performs a single AXI beat.

Therefore:

```text
s_axi_awlen = 0
```

The transfer size is:

```text
512 bits = 64 bytes
```

Therefore:

```text
s_axi_awsize = 6
```

because:

```text
2^6 = 64 bytes
```

The burst type is:

```text
INCR
```

represented as:

```text
s_axi_awburst = 2'b01
```

---

# 19. AXI Write Address Handshake

The write address handshake occurs when:

```text
s_axi_awvalid = 1
AND
s_axi_awready = 1
```

After the handshake completes:

```text
state ? AXI_W
```

---

# 20. AXI Write Data Channel

The 512-bit data buffer is transferred through:

```text
s_axi_wdata
```

All byte lanes are enabled:

```text
s_axi_wstrb = all ones
```

Since the current transfer contains one AXI beat:

```text
s_axi_wlast = 1
```

The data handshake occurs when:

```text
s_axi_wvalid = 1
AND
s_axi_wready = 1
```

After the handshake:

```text
state ? AXI_B
```

---

# 21. AXI Write Response

The AXI memory returns a write response through the B channel.

The wrapper asserts:

```text
s_axi_bready = 1
```

and waits for:

```text
s_axi_bvalid = 1
```

After the response is accepted:

1. The AXI address increments.
2. The wrapper returns to IDLE.

Address increment:

```text
current_axi_addr =
current_axi_addr + (AXI_DATA_WIDTH / 8)
```

For a 512-bit interface:

```text
512 / 8 = 64 bytes
```

Therefore, the AXI address increments by:

```text
64 bytes
```

after every AXI transaction.

---

# 22. AXI Read Operation

The AXI memory supports AXI read functionality through the standard AXI read channels:

```text
AR – Read Address Channel
R  – Read Data Channel
```

The read interface consists of:

### Read Address Signals

| Signal          | Description         |
| --------------- | ------------------- |
| `s_axi_arid`    | Read transaction ID |
| `s_axi_araddr`  | Read address        |
| `s_axi_arlen`   | Burst length        |
| `s_axi_arsize`  | Transfer size       |
| `s_axi_arburst` | Burst type          |
| `s_axi_arvalid` | Read address valid  |
| `s_axi_arready` | Read address ready  |

### Read Data Signals

| Signal         | Description         |
| -------------- | ------------------- |
| `s_axi_rid`    | Read transaction ID |
| `s_axi_rdata`  | Read data           |
| `s_axi_rresp`  | Read response       |
| `s_axi_rlast`  | Final read beat     |
| `s_axi_rvalid` | Read data valid     |
| `s_axi_rready` | Read data ready     |

The FIFO read interface is used internally to transfer data from the FIFO toward the AXI write path.

The AXI memory read interface provides the capability to access stored AXI memory data through AXI read transactions, according to the implementation present in the top-level and wrapper RTL.

---

# 23. Reset Behavior

The design uses an active-high synchronous reset.

When:

```text
rst = 1
```

the following operations occur.

### Transition Packer

```text
pack_buffer   = 0
pack_count    = 0
pending_valid = 0
pending_data  = 0
```

### FIFO

```text
wr_ptr  = 0
rd_ptr  = 0
rd_data = 0
```

### FIFO AXI Wrapper

```text
state            = IDLE
fifo_rd_en       = 0
fifo_word_count  = 0
axi_data_buffer  = 0
current_axi_addr = 0
```

All AXI valid signals are deasserted.

---

# 24. Complete Data Flow

The complete data flow through the design is:

### Step 1: Transition Arrival

The upstream logic provides:

```text
trans_valid
trans_data
trans_width
```

### Step 2: Transition Handshake

The transition is accepted when:

```text
trans_valid && trans_ready
```

### Step 3: Packing

Variable-width transition bits are packed into the 64-bit packing buffer.

### Step 4: FIFO Word Generation

When 64 bits are accumulated, a completed word is generated.

### Step 5: FIFO Storage

The completed word is written into the FIFO when:

```text
fifo_wr_en && !fifo_full
```

### Step 6: FIFO Read

The AXI wrapper requests data using:

```text
fifo_rd_en
```

The FIFO returns:

```text
fifo_rd_data
```

### Step 7: AXI Buffering

Eight FIFO words are collected:

```text
8 × 64 bits = 512 bits
```

### Step 8: AXI Write

The 512-bit data word is transferred to AXI memory.

### Step 9: Address Increment

After a successful AXI write response:

```text
Address = Address + 64 bytes
```

The process repeats.

---

# 25. Clocking

All RTL modules operate using the same system clock:

```text
clk
```

The following operations are synchronous to the positive edge of the clock:

* Transition packing.
* FIFO writes.
* FIFO reads.
* Pointer updates.
* FSM transitions.
* AXI transaction generation.

---

# 26. Design Parameters

| Parameter        | Default Value | Description              |
| ---------------- | ------------: | ------------------------ |
| `DATA_WIDTH`     |            64 | FIFO data width          |
| `FIFO_DEPTH`     |           512 | FIFO storage depth       |
| `ADDR_WIDTH`     |             9 | FIFO address width       |
| `AXI_DATA_WIDTH` |           512 | AXI data bus width       |
| `AXI_ADDR_WIDTH` |            32 | AXI address width        |
| `ID_WIDTH`       |             4 | AXI transaction ID width |

---

# 27. Key Functional Relationships

The following relationship exists between FIFO and AXI widths:

```text
FIFO_WORDS_PER_AXI =
AXI_DATA_WIDTH / FIFO_DATA_WIDTH
```

For the default configuration:

```text
FIFO_WORDS_PER_AXI =
512 / 64 =
8
```

Therefore, eight FIFO words are required for one AXI data transfer.

---

# 28. Important Design Assumptions

The current RTL assumes:

1. FIFO data width is compatible with the AXI data width.
2. AXI data width is an integer multiple of FIFO data width.
3. FIFO read data is synchronous.
4. The AXI transfer size is configured for the AXI data width.
5. FIFO data is transferred in the same order in which it was written.
6. The design uses a single clock domain.
7. Reset is synchronous and active high.
8. The AXI address increments sequentially after each successful write transaction.

---

# 29. Functional Limitations and Open Design Considerations

The following items should be clearly communicated during RTL handoff:

### Partial AXI Word Handling

The AXI wrapper collects eight FIFO words to form one complete 512-bit AXI word.

If fewer than eight FIFO words remain in the FIFO, the current behavior must be verified against the intended system requirement.

A flush or end-of-packet mechanism may be required if partial FIFO data must also be written to AXI memory.

### AXI Read Usage

The AXI RAM may support AXI read channels, but the top-level integration must define the required external read request interface and the intended read behavior.

### AXI Response Checking

The design receives AXI write response signals. Verification should confirm expected handling of:

```text
OKAY
SLVERR
DECERR
```

depending on system requirements.

---

# 30. Verification Handoff Requirements

The RTL design will be handed over to the Verification team for independent verification.

The Verification team should derive verification scenarios from this design specification and RTL behavior.

The RTL handoff package should contain:

```text
rtl/
¦
+-- transition_packer.v
+-- fifo_buffer.v
+-- fifo_axi_wrapper.v
+-- fifo_top.v
+-- axi_ram.v
```

Additional files:

```text
filelist.f
README.md
RTL_Design_Specification.pdf
```

The design specification should be considered the primary functional reference for verification.

---

# 31. Verification Scope for Independent Verification

The Verification team should independently verify:

* Reset behavior.
* Transition valid-ready handshake.
* Variable-width transition packing.
* Exact 64-bit packing boundary.
* Transition crossing a 64-bit boundary.
* FIFO write operation.
* FIFO read operation.
* FIFO full condition.
* FIFO empty condition.
* FIFO pointer wraparound.
* FIFO ordering.
* Backpressure behavior.
* Collection of eight FIFO words.
* Formation of 512-bit AXI data.
* AXI write address handshake.
* AXI write data handshake.
* AXI write response handling.
* AXI address increment.
* AXI read functionality, if enabled in the final top-level RTL.
* Boundary and corner-case conditions.

The verification methodology and testbench implementation are outside the scope of this RTL design document.

---

# 32. Conclusion

The design provides a complete data path for converting variable-width transition data into fixed-width packed words, buffering the packed data inside a FIFO, aggregating FIFO words into a wider AXI data format, and transferring the resulting data to AXI memory.

The architecture provides:

* Variable-width data packing.
* FIFO-based buffering.
* Full and empty protection.
* Input backpressure.
* Sequential data ordering.
* 64-bit to 512-bit data aggregation.
* AXI-based memory write capability.
* Parameterized data widths and memory depths.

The modular architecture allows each block to be independently verified and integrated into larger systems.

