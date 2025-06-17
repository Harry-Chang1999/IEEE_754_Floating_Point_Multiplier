# IEEE_754_Floating_Point_Multiplier
## Overview
This project implements a pipeline floating-point multiplier designed in Verilog HDL that performs IEEE 754 double-precision multiplication operations. The design has been synthesized and undergone APR (Automatic Placement and Routing), with the complete circuit operating at 1 GHz and consuming less than 2mW power in both gate-level simulation and post-layout simulation.

## 🎯 Project Objectives
- **Implement IEEE 754 standard** double-precision floating-point multiplication
- **Design pipeline architecture** with state machine control for optimal throughput
- **Minimize power consumption** while maintaining performance requirements
- **Meet timing constraints** at 1.0 GHz operation frequency
- **Demonstrate** advanced digital design concepts for floating-point arithmetic

## 🏗️ System Architecture
### Key Features
- **Pipeline Design**: 3-state FSM controlling data flow and computation phases
- **IEEE 754 Compliance**: Full support for double-precision format (64-bit)
- **Fraction Multiplier**: 53×53 bit multiplication with sift-add
- **Round-to-Nearest**: Proper rounding implementation with tie-breaking
- **Special Cases**: Handles infinity, NaN, and zero cases according to IEEE standard
- **Power Optimization**: Designed for minimal power consumption (<2mW)

### Processing Pipeline
1. **Data Input Phase** (16 clock cycles for two 64-bit operands)
2. **Computation Phase** (Variable cycles based on operand complexity)
3. **Output Phase** (8 clock cycles for 64-bit result)

## 📊 Technical Specifications
| Signal | I/O | Width | Description |
|--------|-----|-------|-------------|
| `CLK` | I | 1 | System clock signal (1.0 GHz) |
| `RESET` | I | 1 | Active-high synchronous reset |
| `ENABLE` | I | 1 | Data input enable signal |
| `DATA_IN` | I | 8 | 8-bit input data stream |
| `DATA_OUT` | O | 8 | 8-bit output data stream |
| `READY` | O | 1 | Output data ready indicator |

## ⚡ Performance Requirements

- **Latency**: < 60 clock cycles
- **Frequency**: 1.0 GHz (Gate-level simulation & post-layout simulation)
- **Total power**: <2mW (Gate-level simulation & post-layout simulation)

## 🔄 Operation Flow

### State Machine Control
| State | Description | Duration | Function |
|-------|-------------|----------|----------|
| **`data`** | Data Input Phase | 16 clock cycles | Receives two 64-bit operands via 8-bit interface, performs data ordering and buffering |
| **`count`** | Computation Phase | 57 clock cycles | Executes IEEE 754 multiplication (sign XOR, exponent addition, mantissa shift-add), handles special cases |
| **`show`** | Output Phase | 8 clock cycles | Sequentially outputs 64-bit result via 8-bit interface, activates READY signal |

### Algorithm Innovation
The project demonstrates how **algorithmic choices** can significantly impact power consumption:
- Traditional approach: Direct 53×53 multiplier (high power)
- Optimized approach: Shift-and-add equivalent (low power)
- Trade-off: Increased latency for reduced power consumption
- Result: 60-cycle latency well within specification

### VLSI Design Flow Mastery
- **RTL Design**: Behavioral Verilog with synthesis considerations
- **Synthesis**: Logic optimization with power constraints
- **Automatic Placement & Routing**: Physical implementation with timing closure
- **Verification**: DRC/LVS checking and post-layout simulation
- **Simulation**: Gate-level simulation & Post-layout simulation

## 🚀 Prerequisites
- **Verilog Simulator**: NC-Verilog 15.20
- **Synthesis Tool**: Genus 20.10
- **Place & Route**: Innovus 21.17
- **Waveform Viewer**: nWave (Verdi_P-2019.06)

## 🧪 Testing & Verification
### Testbench Features
| Feature | Description |
|---------|-------------|
| **Random Pattern Generation** | Automatic test vector creation using `$random` |
| **Real Number Interface** | Uses `$realtobits` and `$bitstoreal` for verification |
| **Automatic Checking** | Compares hardware result with software reference |
| **Coverage Analysis** | Functional and code coverage monitoring |
| **Power Toggle Counting** | Built-in power analysis support |

### Test Flow
```verilog
// Generate random floating-point inputs using time-based seeds
sim_time = $time;
C_real = $random(sim_time);
D_real = $random(sim_time);
A_real = C_real/D_real;  // Create diverse FP numbers
B_real = E_real/F_real;

// Convert to IEEE 754 format
A = $realtobits(A_real);
B = $realtobits(B_real);

// Send to multiplier (16 cycles input + computation + 8 cycles output)
// Compare hardware result with software reference
checkZ = checkA * checkB;
C = $realtobits(checkZ);
if(C != Z) err_count++;
```

### Verification Features
- **Time-Based Randomization**: Uses `$time` as seed for true randomness
- **Real Number Interface**: Seamless conversion between real and binary
- **Comprehensive Coverage**: 200 test patterns with diverse operands
- **Toggle Count Generation**: `.tcf` files for accurate power analysis
- **Automatic Error Detection**: Real-time comparison with expected results

### Verification Result
- **Gate-level simulation & Post-layout simulation**
![tb_result](https://github.com/user-attachments/assets/b5ccc17a-4e1a-4095-aeee-8eed17693e48)

## 🧩 APR Result
![APR_result](https://github.com/user-attachments/assets/16cea98e-18d3-4173-b91e-7bef77771939)

### DRC result
![DRC_result](https://github.com/user-attachments/assets/d0736a72-e69f-4584-87a7-02b19fdd5e5d)
Note: Since I/O pads and Bump Cells were not added, there is no AP(12) metal layer present, which results in the DRC density error

### LVS result
![LVS_result](https://github.com/user-attachments/assets/c6ae4d94-bd5b-4d71-bb45-adbc896ad1fe)

## 📈 Performance Specifications
### Gate-level simulation
#### Timing Requirements
- **Operating Frequency**: 1.0 GHz
- **Throughput**: One multiplication every 57 cycles

#### Power Specifications
| Category | Leakage | Internal | Switching | Total |
|----------|---------|----------|-----------|-------|
| Subtotal (mW) | 0.0608 | 0.4348 | 0.4266 | 0.9222 |

#### Area Specifications
| Instance Modeule | Cell Count | Cell Area | Net Area | Total Area |
|------------------|------------|-----------|----------|------------|
| CHIP | 2541 | 1299.421 | 515.905 | 1815.327 |

### Post-layout simulation
#### Timing Requirements
- **Operating Frequency**: 1.0 GHz

#### Power Specifications
| Category | Leakage | Internal | Switching | Total |
|----------|---------|----------|-----------|-------|
| Subtotal (mW) | 0.0580 | 0.6063 | 0.4426 | 1.105 |

#### Area Specifications
| Die Size | Core Size |
|----------|-----------|
| 67.68 × 66.624 μm | 55.62 × 54.624 μm | 
