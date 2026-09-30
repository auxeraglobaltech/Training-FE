# Skid Buffer RTL Documentation

## Normal One-Entry Skid Buffer

---

# 1. Overview

The Skid Buffer is a small elastic buffering architecture designed to handle downstream backpressure while maintaining correct valid/ready data transfer.

The current implementation contains one data storage register and one control register. During normal operation, the input data bypasses the storage register and is presented directly at the output. When valid input data is present while the downstream is not ready, the data is captured into the internal register and the buffer enters skid mode.

The design provides:

* Zero additional clock-cycle latency during bypass operation
* Single-entry skid storage
* Valid/ready style handshaking
* Configurable data width
* Data holding during downstream backpressure
* Automatic return to bypass mode when downstream becomes ready

---

# 2. Design Architecture

## 2.1 High-Level Architecture

```text
                         SKID BUFFER

 i_data --------------------+
                             |
                             v
                        +---------+
                        |  BYPASS |
                        |   MUX   |
                        +----+----+
                             |
                             +------------------> o_data
                             |
                       +-----v------+
                       |  data_reg  |
                       |   SKID     |
                       |  REGISTER  |
                       +------------+

 i_valid ---------------------------------------> o_valid
                                                     ^
                                                     |
                         by_pass -------------------+

 i_ready --------------------> Control Logic
                                  |
                                  v
                               o_ready
```

The control register `by_pass` selects between the direct bypass path and the stored skid data path.

---

# 3. Module Hierarchy

The current design contains one RTL module:

```text
skid_buffer
    |
    +-- data_reg
    |
    +-- by_pass
    |
    +-- bypass/output logic
```

| Module        | Responsibility                                                                                |
| ------------- | --------------------------------------------------------------------------------------------- |
| `skid_buffer` | Top-level skid-buffer implementation, bypass control, data storage, and valid/ready interface |

---

# 4. Parameters

The module contains the following parameter:

| Parameter    | Default | Description                                 |
| ------------ | ------: | ------------------------------------------- |
| `DATA_WIDTH` |      32 | Width of `i_data`, `o_data`, and `data_reg` |

---

# 5. Interface Description

## 5.1 Clock and Reset

| Signal  | Direction | Width | Description                  |
| ------- | --------- | ----: | ---------------------------- |
| `clk`   | Input     |     1 | System clock                 |
| `rst_n` | Input     |     1 | Active-low synchronous reset |

The RTL uses:

```verilog
always @(posedge clk)
```

Therefore, reset is synchronous and active low.

---

# 6. Upstream Interface

| Signal    | Direction |        Width | Description                                                         |
| --------- | --------- | -----------: | ------------------------------------------------------------------- |
| `i_valid` | Input     |            1 | Indicates that `i_data` contains valid data                         |
| `i_data`  | Input     | `DATA_WIDTH` | Data received from the upstream pipeline                            |
| `o_ready` | Output    |            1 | Indicates that the skid buffer is available to accept upstream data |

The upstream-side transfer is conceptually successful when:

```text
i_valid && o_ready
```

---

# 7. Downstream Interface

| Signal    | Direction |        Width | Description                                            |
| --------- | --------- | -----------: | ------------------------------------------------------ |
| `o_valid` | Output    |            1 | Indicates that `o_data` contains valid data            |
| `o_data`  | Output    | `DATA_WIDTH` | Data presented to the downstream pipeline              |
| `i_ready` | Input     |            1 | Indicates that the downstream pipeline can accept data |

The downstream-side transfer is successful when:

```text
o_valid && i_ready
```

---

# 8. Internal Registers

| Register   |        Width | Description                                                 |
| ---------- | -----------: | ----------------------------------------------------------- |
| `data_reg` | `DATA_WIDTH` | Stores valid input data when downstream backpressure occurs |
| `by_pass`  |            1 | Selects bypass mode (`1`) or skid mode (`0`)                |

---

# 9. Operating Modes

## 9.1 Bypass Mode

When `by_pass = 1`, the buffer operates in bypass mode.

```verilog
assign o_ready = by_pass;
assign o_data  = by_pass ? i_data : data_reg;
assign o_valid = by_pass ? i_valid : 1'b1;
```

Therefore, in bypass mode:

```text
o_ready = 1
o_data  = i_data
o_valid = i_valid
```

The input data and valid signal pass directly to the output without an additional clock-cycle delay.

## 9.2 Skid Mode

When `by_pass = 0`, the buffer operates in skid mode.

```text
o_ready = 0
o_data  = data_reg
o_valid = 1
```

The data previously captured in `data_reg` is held at the output until the downstream becomes ready.

---

# 10. Bypass to Skid Transition

The transition from bypass mode to skid mode occurs when valid data is present but the downstream is not ready.

```verilog
if (by_pass) begin
    if (i_valid && !i_ready) begin
        data_reg <= i_data;
        by_pass  <= 1'b0;
    end
end
```

At the active clock edge, `i_data` is stored in `data_reg` and `by_pass` changes to zero.

---

# 11. Skid to Bypass Transition

While in skid mode, the buffer waits for downstream readiness.

```verilog
else begin
    if (i_ready) begin
        by_pass <= 1'b1;
    end
end
```

When `i_ready` becomes high, the buffer returns to bypass mode.

---

# 12. State Flow

```text
                    RESET
                      |
                      v
                +-------------+
                |   BYPASS    |
                |  by_pass=1  |
                +------+------+
                       |
             i_valid=1 && i_ready=0
                       |
                       v
                +-------------+
                |    SKID     |
                |  by_pass=0  |
                +------+------+
                       |
                    i_ready=1
                       |
                       v
                +-------------+
                |   BYPASS    |
                |  by_pass=1  |
                +-------------+
```

---

# 13. Data Storage Operation

The data register is written only during the transition into skid mode.

```verilog
data_reg <= i_data;
```

Once in skid mode, `data_reg` is not overwritten by new upstream data. This ensures that the transaction captured during the backpressure event remains stable at the output.

---

# 14. Output Data Selection

The output data is selected using a combinational multiplexer:

```verilog
assign o_data = by_pass ? i_data : data_reg;
```

Therefore:

| `by_pass` | `o_data` source | Operating mode |
| --------: | --------------- | -------------- |
|         1 | `i_data`        | Bypass         |
|         0 | `data_reg`      | Skid           |

---

# 15. Valid Generation

The output valid signal is generated as:

```verilog
assign o_valid = by_pass ? i_valid : 1'b1;
```

In bypass mode, output valid follows the upstream valid signal.

In skid mode, `o_valid` remains asserted because `data_reg` contains the captured valid transaction.

---

# 16. Ready Generation

The ready output is generated directly from the bypass state:

```verilog
assign o_ready = by_pass;
```

| `by_pass` | `o_ready` | Meaning                                  |
| --------: | --------: | ---------------------------------------- |
|         1 |         1 | Buffer can accept/forward normal traffic |
|         0 |         0 | Buffer is holding a skid transaction     |

---

# 17. Reset Behavior

The design uses an active-low synchronous reset.

```verilog
if (!rst_n) begin
    data_reg <= {DATA_WIDTH{1'b0}};
    by_pass  <= 1'b1;
end
```

After reset:

* `data_reg` is cleared to zero
* `by_pass` is set to `1`
* The buffer starts in bypass mode
* `o_ready` is asserted

---

# 18. Normal Data Flow

### Cycle N

```text
i_valid = 1
i_ready = 1
by_pass = 1
```

Data path:

```text
i_data -------------------------------> o_data
i_valid ------------------------------> o_valid

o_ready = 1
```

When the downstream is ready, the input data bypasses the internal register.

---

# 19. Backpressure / Skid Operation

### Cycle N

```text
i_valid = 1
i_ready = 0
i_data  = A
by_pass = 1
```

At rising edge:

```verilog
data_reg <= A;
by_pass  <= 0;
```

Next cycle:

```text
o_data  = A
o_valid = 1
o_ready = 0
```

The captured data is held until downstream readiness is restored.

---

# 20. Timing Example

```text
             C0        C1        C2        C3
-------------------------------------------------------
i_valid       1         1         1         1
i_ready       1         0         0         1
i_data        A         A         B         C
by_pass       1         0         0         1
o_valid       1         1         1         1
o_ready       1         0         0         1
o_data        A         A         A         C
```

### Behavior

* **C1:** `A` is captured because downstream is not ready.
* **C2:** `A` remains stable while downstream is stalled.
* **C3:** Downstream is ready and the buffer returns to bypass.

---

# 21. Valid/Ready Handshake

The skid buffer uses two handshake relationships:

| Interface            | Handshake            | Description                          |
| -------------------- | -------------------- | ------------------------------------ |
| Upstream to buffer   | `i_valid && o_ready` | The buffer accepts upstream data     |
| Buffer to downstream | `o_valid && i_ready` | The downstream accepts buffer output |

The critical backpressure condition is:

```text
i_valid && !i_ready
```

This condition causes the input data to be captured into `data_reg`.

---

# 22. Buffer State Summary

| State              | `i_valid`         | `i_ready` | `by_pass` | Behavior                       |
| ------------------ | ----------------- | --------- | --------- | ------------------------------ |
| Bypass             | 0/1               | 1         | 1         | Input is passed directly       |
| Backpressure event | 1                 | 0         | 1 ? 0     | Current valid data is captured |
| Skid               | Stored valid data | 0         | 0         | Captured data is held          |
| Release            | Any               | 1         | 0 ? 1     | Return to bypass               |

---

# 23. Important RTL Conditions

* The buffer enters skid mode only when `i_valid` is high and `i_ready` is low.
* The captured data is stored on the rising clock edge.
* Once in skid mode, `o_ready` is deasserted.
* While in skid mode, `o_data` is driven from `data_reg`.
* While in skid mode, `o_valid` is asserted.
* The buffer returns to bypass mode when `i_ready` becomes high.
* Only one transaction can be stored by the single `data_reg`.

---

# 24. Verification Points

## 24.1 Reset

Verify:

* `by_pass` becomes `1`.
* `data_reg` is cleared.
* `o_ready` is asserted after reset.

## 24.2 Normal Bypass

Drive:

```text
i_valid = 1
i_ready = 1
```

Verify:

* `o_data` follows `i_data`.
* `o_valid` follows `i_valid`.

## 24.3 Backpressure

Drive:

```text
i_valid = 1
i_ready = 0
```

Verify:

* Input data is captured.
* `by_pass` becomes `0`.

## 24.4 Data Stability

Change `i_data` while downstream remains stalled.

Verify:

* `o_data` remains equal to the captured data.
* `o_valid` remains asserted.

## 24.5 Release

Assert `i_ready`.

Verify:

* `by_pass` returns to `1`.
* The buffer resumes bypass operation.

## 24.6 Continuous Transfer

Apply consecutive valid data words with `i_ready` high.

Verify:

* Each word appears at the output correctly.

---

# 25. Example Test Scenarios

| Test | Scenario               | Expected Result                           |
| ---- | ---------------------- | ----------------------------------------- |
| TC00 | Reset                  | Buffer starts in bypass mode              |
| TC01 | Normal bypass          | Input data passes directly to output      |
| TC02 | Downstream stall       | Valid data is captured into `data_reg`    |
| TC03 | Data held during stall | `o_data` remains equal to captured data   |
| TC04 | Downstream ready       | Buffer returns to bypass mode             |
| TC05 | No valid input         | `o_valid` is deasserted in bypass mode    |
| TC06 | Continuous traffic     | No data corruption during normal transfer |

---

# 26. Advantages

* Simple and compact RTL architecture.
* Zero additional cycle latency in bypass mode.
* Low storage requirement.
* Handles a sudden downstream backpressure event.
* Easy to integrate between pipeline blocks.
* Parameterized data width.

---

# 27. Limitations

* Only one data transaction can be stored.
* The buffer cannot accept another transaction while it is already in skid mode.
* The data and valid paths are combinational in bypass mode.
* This implementation is not a multi-entry FIFO.
* A different registered/pipeline skid architecture may be required when complete pipeline-path registration is needed.

---

# 28. Important RTL Implementation Notes

## 28.1 Single Storage Register

The design uses only one data register. The `by_pass` register acts as the mode/state indicator.

## 28.2 State Encoded by `by_pass`

No separate FSM is required. The single-bit `by_pass` register represents the two operating states.

## 28.3 Synchronous Reset

Because reset is checked inside:

```verilog
always @(posedge clk)
```

`rst_n` is synchronous despite being active low.

## 28.4 Backpressure Detection

The design captures data only when `i_valid` is high while `i_ready` is low. This is the critical event that creates the skid condition.

## 28.5 Output Stability

After capture, `o_data` is sourced from `data_reg` rather than `i_data`, preventing changes on the upstream data bus from changing the held output transaction.

---

# 29. RTL Files

Recommended repository structure:

```text
skid_buffer/
|
+-- rtl/
|   +-- skid_buffer.v
|
+-- docs/
|   +-- skid_buffer_doc.md
|
+-- README.md
```

---

# 30. Simulation

Using Cadence Xrun, the RTL and testbench can be compiled with:

```bash
xrun skid_buffer.v tb_skid_buffer.v
```

The most important waveform to inspect is the transition from bypass to skid mode and the stability of `o_data` while downstream is stalled.

> **Note:** The current repository PR contains the RTL and documentation only. The testbench is not included in the repository structure.

---

# 31. Example Default Configuration

| Parameter       |             Value |
| --------------- | ----------------: |
| `DATA_WIDTH`    |                32 |
| Storage entries |                 1 |
| Operating modes | 2 (BYPASS / SKID) |

---

# 32. Summary

The Skid Buffer provides a simple mechanism for handling downstream backpressure in a valid-ready pipeline.

During normal operation, the input data and valid signal bypass the internal storage register. When a valid transaction encounters a downstream ready deassertion, the data is captured in `data_reg` and the buffer enters skid mode.

The captured transaction is held stable until downstream readiness is restored, after which the buffer returns to bypass operation.

The implementation is compact because the `by_pass` register represents the operating state and only one data register is required.

---

# 33. Revision History

| Version | Date       | Author      | Description                           |
| ------- | ---------- | ----------- | ------------------------------------- |
| 1.0     | 2026-09-30 | Anoop Kumar | Initial Skid Buffer RTL documentation |

---

**Skid Buffer RTL Documentation**
