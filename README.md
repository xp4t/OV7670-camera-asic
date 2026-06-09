# ASIC for OV7670 Module
Description: A RTL-based project in Verilog that shows real-time video captured by a CMOS camera OV7670 and displayed on a monitor through VGA at 640 x 480 resolution, 30 fps.       

ORGINALLY DEVELOPED BY github.com/amsacks 

I am working to develop an ASIC Based on this, and possibly a standalone module that can capture, do some process and then dump to to a VGA. 
but first I need to develop the **ASIC**. Planning to do on the **SKYWATER130NM PDK.**

I'll try with both OpenSource tools as well as the Industrial Tools like Synopsis, I only have access to synopsis rn.

I'll be adding comments and other issues i faced while Developing the ASIC. 
       
**ISSUE 1: The BRAM.**

THE ```mem_bram.v``` CAN ONLY BE USED FOR FPGAS AS THEY MAP EASILY TO THE BRAMS AVAILABLE IN THE FPGA. I Was dumb enough to think that if it works for FPGA synthesis, It'll work for ASIC,

the ```reg [WIDTH-1:0] ram [0:DEPTH-1];``` where ```(parameter WIDTH = 11, parameter DEPTH = 640*480)``` can take like 3.37 million flipflops, damn.

The only fix could be instantiating an SRAM from Cadence/Synopsis. But I ain't rich to buy that.

**Fix 1: Use OpenRAM https://github.com/VLSIDA/OpenRAM/tree/stable**

Fair enough, can be synthesized, will work on it and update.

**ISSUE 2**

The RTL has lots and lots of warnings and errors, I have to manually figure them out.

Fine, I'll do it myself. 

