# FPGA 1G Ethernet to Book Engine for ITCH Market Data

## Overview
A low-latency FPGA implementation of 1G networking stack for processing UDP packets containing ITCH market data and maintaining an on fabric order book. Add, delete, and order executed messages will be supported. Currently, this project is in development so only simple add message functionality has been implemented. **This project is in progress and is not a finished/polished work. There is an estimated 1-2 weekends of work to finish the intended goal of having an ethernet to order book engine system completed.**

## Features
- **Custom MAC**
- **Low-Latency CDC**
- **Ethernet, IpV4, and UDP header parser**
- **ITCH Market Data Parser**
- **Order Map**
- **Variable Depth Order Book** (depth of 2k target for timing)
- **Variable Depth Order Book** (depth of 5 targeted for timing)
- **Tick to Book Latency of 845ns for Add Order Messages**

## Architecture
### Data Path
1. **Custom MAC**
    - Performs essentially zero parsing of the incoming ethernet packet. It includes DDR decoding and then simply passes the received byte upstream.
    - Interfaces with 1G PHY via RMGII. Clock to data skew is acheived internally via MMCM generated clock.
2. **Low-Latency CDC**
    - Bytes are streamed from the 125MHz rx domain to the 250MHz processing domain.
    - While all processing could be done on the rx clk domain it is safer to process on a clock generated on device. The rx clk is provided off board making it susceptible to glitches. Also it is not guarenteed to be running at all times.
    - A circular AFIFO CDC method was implemented with a minimal synchronization pipeline.
    - Latency across the CDC is ~14ns compared to ~42ns of the Xilinx xpm_fifo_async IP which can be optionally generated in the design as a benchmark.
3. **Ethernet Header Parser**
    - Parses ethernet frame headers (eth, ip, udp, moldUdp64) as they stream in. If a valid frame has been received on the last byte, the proceeding ITCH data is passed through with zero cycles of latency added.
    - Checks MAC dest address, ip version, ip dest address, ip checksum, protocol, ,udp destination, and moldUdp64 sequence.
4. **ITCH Parser**
    - Extracts add, delete, and order executed message types. Also on-the-fly parsing where forwarded data is driven to the outputs when it is received.
    - Separate valid signals for each message type assert when all important fields have been received.
    - Data field outputs are shared (i.e reference number) to make routing easier.
    - Zero additional cycles added to forwarded data.
4.  **Order Map** (in progress)
    - The order map is of variable depth with 2K depth being target for timing closure.
    - A hash table is implemented where the received ITCH reference number passed through a hash function to index into BRAM. The RAM is initialized to zeros which is how the insertion will detect if an address has been written to. Upon order deletion, the location will be zeroed out freeing it for future use.
    - One 64bit X 2K BRAM is used for reference number storage while a second 65 bit X 2K BRAM is used for price, quantity, and side data of correlating reference number.
5. **Order Book** (in progress)
    - Add order message type implemented with tick to top of book update in 845ns.
    - Single instrument supported with variable depth.
    - Delete and Executed messages will have higher latency due to the need for a lookup in the map.

## Implementation Details
- Xilinx Artix 7 FPGA on the Diligent Nexys Video development board
- System Verilog for synthesizable code and test benches.

