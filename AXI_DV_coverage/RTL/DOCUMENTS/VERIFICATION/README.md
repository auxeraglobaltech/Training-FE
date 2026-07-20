# VERIFICATION

The AXI(Advanced eXtensible Interface) IP is verified extensively based on the UVM - Universal Verification Methodology.

## Directory Structure:

```
AXI
          ├─.....
          ├─.....
          ├─VERIFICATION
               ├─UVME
                  ├──AXI_M_AGENTS      # contains driver and monitor
                  ├──AXI_M_ENVIROMENT  # contains scoreboard and reference model
                  ├──AXI_M_SEQUENCES   # contains randomized the sequences,sequence item 
                  ├──AXI_M_TESTS       # contains test cases to drive randomized sequences
                  ├──AXI_M_TOP         # contains interfaces and top file
                  ├──AXI_M_PACKAGES    # contains env,seq and test packages
                  └──sim               # contains run scripts and supporting scripts

```

## Files in this Directory

#### [AXI_M_AGENTS](https://github.com/chandanhp/zilla_ip_verif/tree/main/AXI/VERIFICATION/UVME/AXI_M_AGENTS)
This contains `AXI_M_AGENTS` which drives and monitors the internal & external signals of design.

#### [AXI_M_ENVIRONMENT](https://github.com/chandanhp/zilla_ip_verif/tree/main/AXI/VERIFICATION/UVME/AXI_M_ENVIRONMENT)
This contains `scoreboard` for comparison of actual RTL output against the expected output.

#### [AXI_M_PACKAGES](https://github.com/chandanhp/zilla_ip_verif/tree/main/AXI/VERIFICATION/UVME/AXI_M_PACKAGES)
It includes enviroment package, sequence package and test package. New sequence and tests need to be included here.

#### [AXI_M_SEQUENCES](https://github.com/chandanhp/zilla_ip_verif/tree/main/AXI/VERIFICATION/UVME/AXI_M_SEQUENCES)
It includes sequencer, sequence item and Randomized sequences are generated for RTL Design verification.

#### [AXI_M_TESTS](https://github.com/chandanhp/zilla_ip_verif/tree/main/AXI/VERIFICATION/UVME/AXI_M_TESTS)
It includes testcases used to drive the randomized sequences.

#### [AXI_M_TOP](https://github.com/chandanhp/zilla_ip_verif/tree/main/AXI/VERIFICATION/UVME/AXI_M_TOP)
It includes interface and the test_top.

#### [sim](https://github.com/chandanhp/zilla_ip_verif/tree/main/AXI/VERIFICATION/sim)
It includes runs script - `axi_m_run.pl` for running the standalone simulation and `axi_m_regression.pl` for running regressions.

#### axi_m_comp_file.f
It Specifies the compilation sequence of UVM verification environment and RTL.

## Pre-Requisites

#### Cadence® Xcelium™ Logic Simulator

[Cadence® Xcelium™ Logic Simulation](https://www.cadence.com/ko_KR/home/tools/system-design-and-verification/simulation-and-testbench-verification/xcelium-simulator.html) provides best-in-class core engine performance for SystemVerilog, VHDL, SystemC®, e, UVM, mixed signal, low power, and X-propagation. It leverages single-core and multi-core simulation technology for best individual test performance and machine learning-optimized regression technology for best regression throughput.

#### Perl

## Steps to Run Standalone Tests

The `axi_m_run.pl` script is used to run standalone test.

To run the standalone test execute the command 

    perl axi_m_run.pl <test_type>
    
**_<test_type>_** can be found [here](https://github.com/chandanhp/zilla_ip_verif/tree/main/AXI/VERIFICATION/UVME/AXI_M_TESTS).

   TESTS                  

* axi_m_test         
* axi_m_64_test       
* axi_m_rand_test       
 

**NOTE: Custom tests can be written inside [AXI_M_TESTS](https://github.com/chandanhp/zilla_ip_verif/tree/main/AXI/VERIFICATION/UVME/AXI_M_TESTS) and called.**

###### Example

## To Verify axi_m_test, the command would be

    perl axi_m_run.pl axi_m_test  
           
## Steps to Run Regressions

`axi_m_regression.pl` :  perl script (in sim directory) to run regression by passing test_list. Add test_name and number of ittration of that test for regression in test_list.f.
   
To run regression without coverage : 
                      
    perl axi_m_regression.pl test_list.f
                
To run regression with coverage :
                      
    perl axi_m_regression.pl test_list.f 1

                
           
