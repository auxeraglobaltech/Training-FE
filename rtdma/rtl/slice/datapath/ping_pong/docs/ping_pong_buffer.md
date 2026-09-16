# Ping-Pong Buffer RTL Documentation

## 1. Overview

The Ping-Pong Buffer is a packet-oriented dual-buffer storage architecture designed to allow data reception from a DMA interface while previously received data is consumed by a CPU or downstream interface.

The design consists of two independent RAM buffers:

* **Ping Buffer**
* **Pong Buffer**

At any given time, one buffer can be used for receiving DMA data while the other buffer can be in the process of being read by the CPU.

Each buffer is controlled using a three-state finite state machine:

```text
FREE ? WRITING ? READY ? FREE
```

The controller manages:

* DMA write operation
* CPU read operation
* Ping/Pong buffer selection
* Packet completion
* Buffer-full handling
* Timeout-based packet completion
* Flush operation
* Packet SOP/EOP generation
* Valid packet length tracking
* Almost-full and almost-empty status

The current implementation contains three main RTL modules:

```text
ping_pong_buffer
¦
+-- buffer_controller
¦
+-- u_ping_ram
¦   +-- buffer_ram
¦
+-- u_pong_ram
    +-- buffer_ram
```

---

# 2. Design Architecture

## 2.1 High-Level Architecture

```text
                         DMA Interface
                              ¦
                    dma_valid / dma_data
                              ¦
                              ?
                    +-------------------+
                    ¦ Ping-Pong Buffer  ¦
                    ¦                   ¦
                    ¦   Controller      ¦
                    +-------------------+
                            ¦
                 +---------------------+
                 ¦                     ¦
                 ?                     ?
          +-------------+       +-------------+
          ¦ Ping Buffer ¦       ¦ Pong Buffer ¦
          ¦    RAM      ¦       ¦    RAM      ¦
          +-------------+       +-------------+
                 ¦                     ¦
                 +---------------------+
                            ¦
                            ?
                       CPU Interface
                       cpu_data
                       cpu_rd_en
                       cpu_ready
```

The controller decides which RAM receives DMA data and which RAM supplies data to the CPU.

---

# 3. Module Hierarchy

The top-level module is:

```text
ping_pong_buffer
```

It instantiates:

```text
buffer_controller
buffer_ram      ? Ping RAM
buffer_ram      ? Pong RAM
```

### Module responsibilities

| Module              | Responsibility                                                                    |
| ------------------- | --------------------------------------------------------------------------------- |
| `ping_pong_buffer`  | Top-level integration and CPU read-data multiplexing                              |
| `buffer_controller` | Ping/Pong state machines, DMA selection, read control, timeout and packet control |
| `buffer_ram`        | Memory storage, read/write pointers, occupancy tracking and buffer status         |

---

# 4. Parameters

The top-level module contains the following parameters:

| Parameter            | Default | Description                                       |
| -------------------- | ------: | ------------------------------------------------- |
| `DATA_WIDTH`         |       8 | Width of each stored data word                    |
| `BUFFER_DEPTH`       |     512 | Number of entries in each buffer                  |
| `ALMOST_FULL_LEVEL`  |     480 | Occupancy level at which almost-full is asserted  |
| `ALMOST_EMPTY_LEVEL` |      32 | Occupancy level at which almost-empty is asserted |
| `TIMEOUT_COUNT`      |    1000 | Number of inactive DMA cycles before timeout      |

Both Ping and Pong instantiate `buffer_ram` with the same parameters.

---

# 5. Interface Description

## 5.1 Clock and Reset

| Signal | Direction | Description                   |
| ------ | --------- | ----------------------------- |
| `clk`  | Input     | System clock                  |
| `rstn` | Input     | Active-low asynchronous reset |

The RTL uses:

```verilog
always @(posedge clk or negedge rstn)
```

Therefore, reset is asynchronous and active low.

---

# 6. DMA Interface

| Signal      | Direction |        Width | Description                                          |
| ----------- | --------- | -----------: | ---------------------------------------------------- |
| `dma_valid` | Input     |            1 | Indicates valid DMA data                             |
| `dma_data`  | Input     | `DATA_WIDTH` | Data received from DMA                               |
| `dma_ready` | Output    |            1 | Indicates that a buffer is available to receive data |

The top-level DMA interface follows a valid/ready style handshake.

A DMA transfer is intended to occur when:

```text
dma_valid = 1
dma_ready = 1
```

The controller generates:

```verilog
assign dma_ready = (ping_state == FREE) ||
                   (pong_state == FREE);
```

Therefore, `dma_ready` is asserted whenever at least one Ping/Pong buffer is in the `FREE` state.

---

# 7. CPU Interface

| Signal      | Direction |        Width | Description                            |
| ----------- | --------- | -----------: | -------------------------------------- |
| `cpu_rd_en` | Input     |            1 | CPU requests a read                    |
| `cpu_ready` | Input     |            1 | CPU/downstream is ready to accept data |
| `cpu_data`  | Output    | `DATA_WIDTH` | Data returned from the selected buffer |

A CPU read is considered successful when:

```verilog
buffer_ready && cpu_rd_en && cpu_ready
```

For Ping:

```verilog
ping_read_fire =
    (ping_state == READY) &&
    cpu_ready &&
    cpu_rd_en;
```

For Pong:

```verilog
pong_read_fire =
    (pong_state == READY) &&
    cpu_ready &&
    cpu_rd_en;
```

Thus, `cpu_rd_en` alone does not cause a read. `cpu_ready` must also be asserted.

---

# 8. Packet Control Interface

| Signal      | Direction | Description                                         |
| ----------- | --------- | --------------------------------------------------- |
| `frame_end` | Input     | Indicates completion of the current frame/packet    |
| `flush`     | Input     | Forces the currently written buffer to become ready |

A buffer in the `WRITING` state transitions to `READY` when any of the following occurs:

```text
buffer_full
OR
frame_end
OR
flush
OR
timeout
```

---

# 9. Debug and Status Outputs

The top-level exposes the status of both buffers.

### Valid signals

```text
ping_valid
pong_valid
```

These indicate that the corresponding buffer is in the `READY` state.

### Packet boundary signals

```text
ping_sop
ping_eop

pong_sop
pong_eop
```

These indicate the start and end of packet data during CPU readout.

### Buffer status

```text
ping_full
pong_full

ping_empty
pong_empty

ping_almost_full
pong_almost_full

ping_almost_empty
pong_almost_empty
```

### Occupancy

```text
ping_occupancy
pong_occupancy
```

These indicate the current number of stored entries.

### Valid packet length

```text
ping_valid_length
pong_valid_length
```

These indicate the captured length of the completed packet.

---

# 10. Buffer RAM Architecture

The `buffer_ram` module implements the actual storage.

The memory is declared as:

```verilog
reg [DATA_WIDTH-1:0] mem [0:BUFFER_DEPTH-1];
```

Therefore, each buffer contains:

```text
BUFFER_DEPTH entries
```

with each entry having:

```text
DATA_WIDTH bits
```

For the default parameters:

```text
DATA_WIDTH   = 8
BUFFER_DEPTH = 512
```

the buffer contains:

```text
512 × 8-bit entries
```

---

# 11. RAM Read and Write Pointers

Each `buffer_ram` contains two pointers:

```verilog
wr_ptr
rd_ptr
```

### Write pointer

`wr_ptr` identifies the location where the next DMA data word is written.

On a successful write:

```verilog
mem[wr_ptr] <= wr_data;
wr_ptr       <= wr_ptr + 1'b1;
```

### Read pointer

`rd_ptr` identifies the location from which the next CPU data word is read.

On a successful read:

```verilog
rd_data <= mem[rd_ptr];
rd_ptr  <= rd_ptr + 1'b1;
```

---

# 12. Write Handshake

The RAM defines:

```verilog
assign write_fire = wr_en && !buffer_full;
```

Therefore, data is written only when:

```text
wr_en       = 1
buffer_full = 0
```

A successful write increments:

```text
wr_ptr
occupancy
```

---

# 13. Read Handshake

The RAM defines:

```verilog
assign read_fire = rd_en && !buffer_empty;
```

Therefore, a read occurs only when:

```text
rd_en        = 1
buffer_empty = 0
```

A successful read increments:

```text
rd_ptr
```

and decrements:

```text
occupancy
```

---

# 14. Occupancy Counter

The `occupancy` register tracks the number of currently stored data entries.

The update is controlled using:

```verilog
case ({write_fire, read_fire})
```

### Write only

```text
write_fire = 1
read_fire  = 0
```

Result:

```text
occupancy = occupancy + 1
```

### Read only

```text
write_fire = 0
read_fire  = 1
```

Result:

```text
occupancy = occupancy - 1
```

### Simultaneous read and write

```text
write_fire = 1
read_fire  = 1
```

The occupancy remains unchanged.

This is important because the buffer can maintain the same number of stored entries while one entry is written and another is read.

---

# 15. Buffer Status Generation

The buffer status signals are generated directly from `occupancy`.

## Full

```verilog
assign buffer_full = (occupancy == BUFFER_DEPTH);
```

The buffer is full when occupancy reaches the configured buffer depth.

## Empty

```verilog
assign buffer_empty = (occupancy == 0);
```

The buffer is empty when no valid entries are stored.

## Almost Full

```verilog
assign almost_full = (occupancy >= ALMOST_FULL_LEVEL);
```

The almost-full indication provides an early warning before the buffer becomes completely full.

## Almost Empty

```verilog
assign almost_empty = (occupancy <= ALMOST_EMPTY_LEVEL);
```

The almost-empty indication provides an early warning that the buffer is approaching empty.

---

# 16. Valid Packet Length

Each RAM contains a `valid_length` register.

The purpose is to remember how much data belongs to the completed packet.

The controller generates a one-cycle pulse:

```text
ping_load_valid_length
```

or

```text
pong_load_valid_length
```

when a packet is completed.

The completion conditions are:

```text
buffer_full
OR
frame_end
OR
flush
OR
timeout
```

The RAM then captures:

```verilog
valid_length <= occupancy;
```

The captured value is subsequently used by the controller to determine when CPU reading of the packet has reached the final entry.

---

# 17. Ping/Pong State Machine

Each buffer has its own state register.

The three states are:

```verilog
FREE
WRITING
READY
```

### State encoding

| State     |  Value | Description                                   |
| --------- | -----: | --------------------------------------------- |
| `FREE`    | `2'd0` | Buffer is available for a new packet          |
| `WRITING` | `2'd1` | DMA is writing packet data                    |
| `READY`   | `2'd2` | Packet is complete and available for CPU read |

---

# 18. State Flow

The normal buffer lifecycle is:

```text
             DMA starts
                ¦
                ?
          +-----------+
          ¦   FREE    ¦
          +-----------+
                ¦
                ?
          +-----------+
          ¦  WRITING  ¦
          +-----------+
                ¦
        frame_end / full
        flush / timeout
                ¦
                ?
          +-----------+
          ¦   READY   ¦
          +-----------+
                ¦
        Last data read
                ¦
                ?
          +-----------+
          ¦   FREE    ¦
          +-----------+
```

---

# 19. Ping State Machine

After reset:

```verilog
ping_state <= WRITING;
```

and:

```verilog
pong_state <= FREE;
```

Therefore, the initial configuration is:

```text
Ping = WRITING
Pong = FREE
```

This allows the first DMA packet to be received by the Ping buffer.

---

## 19.1 Ping FREE ? WRITING

When Ping is free, it can become the active writing buffer when:

```text
Pong is not WRITING
AND
dma_valid = 1
```

The output logic additionally checks:

```text
ping_full = 0
```

before asserting:

```text
ping_wr_en = 1
```

---

## 19.2 Ping WRITING ? READY

Ping transitions from `WRITING` to `READY` when any of these conditions occurs:

```text
ping_full
OR
frame_end
OR
flush
OR
timeout
```

This marks the Ping packet as complete.

---

## 19.3 Ping READY ? FREE

Ping returns to `FREE` when:

```text
ping_read_fire = 1
```

and:

```text
ping_read_count == ping_valid_length - 1
```

This represents successful consumption of the final packet entry.

---

# 20. Pong State Machine

After reset:

```text
Pong = FREE
```

Pong becomes the next writing buffer when:

```text
Ping = READY
AND
dma_valid = 1
```

---

## 20.1 Pong FREE ? WRITING

Condition:

```verilog
if ((ping_state == READY) && dma_valid)
    pong_state <= WRITING;
```

---

## 20.2 Pong WRITING ? READY

Pong transitions to `READY` when:

```text
pong_full
OR
frame_end
OR
flush
OR
timeout
```

---

## 20.3 Pong READY ? FREE

Pong returns to `FREE` after the final valid packet entry has been successfully consumed:

```text
pong_read_fire = 1
```

and:

```text
pong_read_count == pong_valid_length - 1
```

---

# 21. Ping-Pong Operation

The main purpose of the design is to allow the two buffers to alternate.

Example:

```text
Time -----------------------------------------------?

Ping :  WRITING -------? READY ---------? FREE
                            ¦
                            ¦ CPU READ
                            ?

Pong :  FREE ----------? WRITING -------? READY
                            ¦
                            ¦ DMA WRITE
                            ?
```

The intended operating principle is:

```text
Ping receives packet
        ¦
        ?
Ping becomes READY
        ¦
        +--------------? CPU reads Ping
        ¦
        ?
Pong becomes WRITING
        ¦
        ?
Pong receives next packet
```

This provides buffering between the DMA producer and CPU consumer.

---

# 22. DMA Buffer Selection

The controller exposes:

```verilog
assign dma_ready = (ping_state == FREE) ||
                   (pong_state == FREE);
```

Therefore:

```text
Ping FREE  ? DMA can potentially use Ping
Pong FREE  ? DMA can potentially use Pong
Both FREE  ? DMA ready
Neither FREE ? DMA not ready
```

The write-enable logic determines which buffer actually receives the DMA data.

---

# 23. CPU Read Selection

The top-level module contains a CPU data multiplexer:

```verilog
assign cpu_data = (ping_valid) ? ping_rd_data :
                  (pong_valid) ? pong_rd_data :
                  {DATA_WIDTH{1'b0}};
```

Therefore the priority is:

```text
1. Ping
2. Pong
3. Zero
```

If Ping is valid:

```text
cpu_data = ping_rd_data
```

Otherwise, if Pong is valid:

```text
cpu_data = pong_rd_data
```

If neither buffer is valid:

```text
cpu_data = 0
```

---

# 24. CPU Read Counter

Each READY buffer has a separate read counter:

```text
ping_read_count
pong_read_count
```

The counter starts from zero.

For Ping:

```verilog
if (ping_read_fire)
begin
    if (ping_read_count == ping_valid_length-1)
        ping_read_count <= 'd0;
    else
        ping_read_count <= ping_read_count + 1'b1;
end
```

The same mechanism is used for Pong.

The read counter therefore tracks the position of the CPU within the completed packet.

---

# 25. SOP Generation

Start-of-packet is asserted when the read counter is zero.

For Ping:

```verilog
if (ping_read_count == 0)
    ping_sop = 1'b1;
```

For Pong:

```verilog
if (pong_read_count == 0)
    pong_sop = 1'b1;
```

Therefore:

```text
read_count = 0
       ¦
       ?
     SOP = 1
```

---

# 26. EOP Generation

End-of-packet is asserted when the read counter reaches the final valid packet entry.

For Ping:

```verilog
if (ping_read_count == ping_valid_length-1)
    ping_eop = 1'b1;
```

For Pong:

```verilog
if (pong_read_count == pong_valid_length-1)
    pong_eop = 1'b1;
```

Therefore:

```text
read_count = valid_length - 1
       ¦
       ?
     EOP = 1
```

---

# 27. CPU Backpressure

A CPU read occurs only when both:

```text
cpu_rd_en = 1
cpu_ready = 1
```

Therefore, if:

```text
cpu_ready = 0
```

the corresponding read counter does not advance and the buffer remains in `READY`.

This allows the CPU/downstream interface to stall without losing packet data.

---

# 28. Timeout Mechanism

The design contains a timeout counter:

```verilog
timeout_cnt
```

The timeout value is controlled by:

```text
TIMEOUT_COUNT
```

Default:

```text
TIMEOUT_COUNT = 1000
```

The timeout mechanism handles a situation where DMA has started writing a packet but stops providing data before asserting `frame_end`.

---

## 28.1 DMA Active

When:

```text
dma_valid = 1
```

the timeout counter is reset:

```verilog
timeout_cnt <= 'd0;
```

---

## 28.2 DMA Pauses During WRITING

If either buffer is in:

```text
WRITING
```

and:

```text
dma_valid = 0
```

the timeout counter increments.

---

## 28.3 DMA Resumes

When:

```text
dma_valid = 1
```

the counter is reset to zero.

---

## 28.4 Timeout Reached

Timeout is asserted when:

```verilog
timeout = (timeout_cnt == TIMEOUT_COUNT);
```

When timeout occurs while a buffer is being written, the buffer transitions:

```text
WRITING ? READY
```

This allows a partially received packet to become available to the CPU instead of remaining permanently in the WRITING state.

---

# 29. Flush Operation

The `flush` input provides a mechanism to force completion of the current packet.

If a buffer is in:

```text
WRITING
```

and:

```text
flush = 1
```

the controller changes the buffer state to:

```text
READY
```

The corresponding `load_valid_length` signal is also generated.

Therefore:

```text
WRITING
   ¦
   ¦ flush
   ?
READY
```

---

# 30. Buffer Clear

Once the CPU has successfully consumed the final valid entry, the controller asserts:

```text
ping_clear
```

or:

```text
pong_clear
```

The RAM responds by resetting:

```text
wr_ptr
rd_ptr
occupancy
valid_length
rd_data
```

to zero.

The physical memory contents are not explicitly erased.

Instead, the pointers and status information are reset so that the old memory contents are no longer treated as valid data.

---

# 31. Almost-Full Behavior

The RAM asserts:

```verilog
almost_full = (occupancy >= ALMOST_FULL_LEVEL);
```

The controller uses the almost-full status to generate:

```text
ping_prepare_next
```

when Ping is writing and Ping reaches the configured almost-full threshold.

This provides an early indication that the active buffer is approaching capacity.

---

# 32. Almost-Empty Behavior

The RAM asserts:

```verilog
almost_empty = (occupancy <= ALMOST_EMPTY_LEVEL);
```

This provides an early indication that the buffer is approaching empty.

The current controller exposes these signals as status inputs but does not directly use `almost_empty` in the state transition logic.

---

# 33. Reset Behavior

The design uses an active-low asynchronous reset.

After reset:

```text
Ping State = WRITING
Pong State = FREE
```

RAM state for both buffers:

```text
wr_ptr       = 0
rd_ptr       = 0
occupancy    = 0
valid_length = 0
rd_data      = 0
```

The timeout counter is also cleared.

Read counters are cleared:

```text
ping_read_count = 0
pong_read_count = 0
```

This establishes Ping as the initial buffer for DMA reception.

---

# 34. Normal Packet Flow

A typical packet transfer operates as follows:

```text
              RESET
                ¦
                ?
        Ping = WRITING
        Pong = FREE
                ¦
                ¦ DMA packet
                ?
        +---------------+
        ¦ Ping receives ¦
        ¦ packet data   ¦
        +---------------+
                ¦
        frame_end / timeout /
        full / flush
                ¦
                ?
          Ping = READY
                ¦
                +--------------? CPU starts reading
                ¦
                ?
          Pong = WRITING
                ¦
                ¦ Next packet
                ?
          Pong = READY
                ¦
                ?
          Ping = FREE
```

---

# 35. Important Handshake Conditions

## DMA Write

Conceptually:

```text
DMA transfer
= dma_valid && dma_ready
```

The controller then generates the appropriate:

```text
ping_wr_en
```

or:

```text
pong_wr_en
```

and the RAM generates:

```text
write_fire = wr_en && !buffer_full
```

---

## CPU Read

A successful CPU read requires:

```text
cpu_rd_en && cpu_ready
```

and the selected buffer must be:

```text
READY
```

Therefore:

```text
ping_read_fire =
    ping_state == READY &&
    cpu_rd_en &&
    cpu_ready
```

or:

```text
pong_read_fire =
    pong_state == READY &&
    cpu_rd_en &&
    cpu_ready
```

---

# 36. Buffer State Summary

| State     | DMA Write | CPU Read | Description                      |
| --------- | --------- | -------- | -------------------------------- |
| `FREE`    | Possible  | No       | Buffer available for new packet  |
| `WRITING` | Yes       | No       | DMA is filling buffer            |
| `READY`   | No        | Yes      | Completed packet waiting for CPU |

---

# 37. State Transition Summary

## Ping

| Current State | Condition                            | Next State |
| ------------- | ------------------------------------ | ---------- |
| `FREE`        | `pong_state != WRITING && dma_valid` | `WRITING`  |
| `WRITING`     | `ping_full`                          | `READY`    |
| `WRITING`     | `frame_end`                          | `READY`    |
| `WRITING`     | `flush`                              | `READY`    |
| `WRITING`     | `timeout`                            | `READY`    |
| `READY`       | Last valid data successfully read    | `FREE`     |

## Pong

| Current State | Condition                          | Next State |
| ------------- | ---------------------------------- | ---------- |
| `FREE`        | `ping_state == READY && dma_valid` | `WRITING`  |
| `WRITING`     | `pong_full`                        | `READY`    |
| `WRITING`     | `frame_end`                        | `READY`    |
| `WRITING`     | `flush`                            | `READY`    |
| `WRITING`     | `timeout`                          | `READY`    |
| `READY`       | Last valid data successfully read  | `FREE`     |

---

# 38. Key Design Characteristics

The current RTL provides:

* Two independent RAM buffers
* Parameterized data width
* Parameterized buffer depth
* Ping/Pong state machines
* DMA valid/ready interface
* CPU valid/ready-style consumption
* Occupancy tracking
* Full and empty detection
* Almost-full detection
* Almost-empty detection
* Packet length tracking
* SOP generation
* EOP generation
* Frame-end based packet completion
* Timeout based packet completion
* Flush based packet completion
* Independent Ping/Pong read counters
* Buffer clearing after packet consumption
* CPU read-data multiplexing

---

# 39. Verification Points

The following scenarios should be verified.

## Reset

* Verify Ping enters `WRITING`
* Verify Pong enters `FREE`
* Verify occupancy is zero
* Verify pointers are reset
* Verify valid length is zero

## DMA Write

* Write a packet into Ping
* Verify Ping occupancy increments
* Verify Ping write pointer increments
* Verify data is stored correctly

## Frame Completion

* Assert `frame_end`
* Verify active buffer transitions from `WRITING` to `READY`
* Verify `ping_valid`/`pong_valid`
* Verify valid packet length

## Ping/Pong Switching

* Fill Ping
* Make Ping `READY`
* Start next packet
* Verify Pong becomes `WRITING`

## CPU Read

* Verify only READY buffers can be read
* Verify `cpu_ready` backpressure
* Verify read pointer
* Verify read counter
* Verify `cpu_data`

## SOP/EOP

Verify:

```text
First packet entry ? SOP
Last packet entry  ? EOP
```

## Timeout

* Start a DMA packet
* Stop `dma_valid`
* Verify timeout counter increments
* Verify timeout causes `WRITING ? READY`

## Flush

* Start writing a packet
* Assert `flush`
* Verify buffer becomes `READY`

## Full

* Fill buffer to `BUFFER_DEPTH`
* Verify `buffer_full`
* Verify additional writes are blocked
* Verify buffer transitions to `READY`

## Backpressure

* Keep `cpu_ready = 0`
* Verify no read occurs
* Verify read counter does not advance
* Verify EOP packet data is not lost

## Buffer Reuse

* Complete CPU read
* Verify buffer returns to `FREE`
* Verify pointers and occupancy are cleared
* Verify buffer can accept a subsequent packet

---

# 40. Important RTL Implementation Notes

The following points describe the **current implementation** and should be considered during verification.

### 40.1 `valid_length` capture

The RAM captures:

```verilog
valid_length <= occupancy;
```

when `load_valid_length` is asserted.

Because `occupancy` is updated using non-blocking assignments in the same clocked process, the value captured by `valid_length` corresponds to the pre-clock value of `occupancy`.

Therefore, when `frame_end` coincides with the final DMA write, the relationship between the final write and captured `valid_length` should be explicitly verified in simulation.

### 40.2 DMA ready is state-based

The top-level `dma_ready` is generated from buffer states:

```verilog
assign dma_ready = (ping_state == FREE) ||
                   (pong_state == FREE);
```

It is not directly generated from `ping_full`/`pong_full`.

The actual RAM write is additionally protected by:

```verilog
!buffer_full
```

### 40.3 CPU data priority

When both `ping_valid` and `pong_valid` are asserted simultaneously, the current CPU multiplexer gives Ping priority:

```verilog
ping_valid ? ping_rd_data
else
pong_valid ? pong_rd_data
```

Therefore, simultaneous READY buffers should be included in verification.

### 40.4 Memory contents are not erased

`clear_buffer` resets the control information and pointers but does not clear every physical RAM location.

Old memory contents can therefore remain physically present until overwritten. They are not considered valid after the buffer is cleared.

---

# 41. Example Parameter Configuration

Default configuration:

```text
DATA_WIDTH         = 8
BUFFER_DEPTH       = 512
ALMOST_FULL_LEVEL  = 480
ALMOST_EMPTY_LEVEL = 32
TIMEOUT_COUNT      = 1000
```

Memory capacity per buffer:

```text
512 × 8 bits
```

Total storage:

```text
2 × 512 × 8 bits
```

or:

```text
8192 bits total
```

---

# 42. RTL Files

Recommended repository structure:

```text
ping_pong_buffer/
¦
+-- rtl/
¦   +-- ping_pong_buffer.v
¦   +-- buffer_controller.v
¦   +-- buffer_ram.v
¦
+-- tb/
¦   +-- tb_ping_pong_buffer.v
¦
+-- docs/
¦   +-- ping_pong_buffer.md
¦
+-- README.md
```

---

# 43. Summary

The Ping-Pong Buffer provides a two-buffer packet storage mechanism between a DMA producer and CPU/downstream consumer.

The controller maintains independent states for Ping and Pong:

```text
FREE
WRITING
READY
```

The active buffer receives DMA data while a completed buffer can be read by the CPU. Packet completion can occur through:

```text
frame_end
buffer_full
timeout
flush
```

After completion, the buffer becomes `READY`. Once the CPU successfully consumes the final valid packet entry, the buffer is cleared and returns to `FREE`, allowing it to be reused.

The architecture therefore provides a simple mechanism for separating DMA packet reception from CPU packet consumption while maintaining packet boundaries and buffer status information.

---

# 44. Revision History

| Version | Date       | Author      | Description                                |
| ------- | ---------- | ----------- | ------------------------------------------ |
| 1.0     | 2026-09-15 | Anoop Kumar | Initial Ping-Pong Buffer RTL documentation |

