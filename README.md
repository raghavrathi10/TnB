# TnB: Resolving Collisions in LoRa based on the Peak MatchingCost and Block Error Correction (FOR EDUCATION AND ADADEMIC RESEARCH ONLY)

TnB decodes wireless signals in LoRa networks. It is capable of decoding packets transmitted by commodity LoRa devices, even when multiple packets overlaps in time, i.e., experience collision. 

This webpage contains the source code of TnB written in Matlab. To test it, you may download the trace files collected in our experiments and feed the trace to TnB as input, or collect and use own traces. Our trace files can be downloaded at https://zenodo.org/record/7199527. Trace collection guidelines can be found at the end of this file.

To run TnB, MATLAB R2021b or above is needed, along with the following toolboxes: Fixed Point Designer, Communications Toolbox, Signal Processing Toolbox and DSP System Toolbox.

Our trace files were collected in 3 deployed testbeds, named “Indoor,” “Outdoor 1,” and “Outdoor 2.” For each testbed, 8 traces have been uploaded, one for each combination of Spreading Factor (SF), which is either 8 or 10, and Coding Rate (CR), which is from 1 to 4. The file name is, for example, “indoor-SF8-CR3.” This
set of trace files were selected from a total of 360 trace files, because they contain the most number of decoded packets for each SF and CR combination. In each trace, there are about 30 seconds of data collected at 1 Msps with Over-Sampling Factor (OSF) 8. The bandwidth of the LoRa node was 125 kHz. More details about the trace collections can be found in our CoNEXT 2022 paper: https://doi.org/10.1145/3555050.3569132.

To run TnB, after downloading the source file, there should a directory, named TnB, which is the source code directory. The main file, named TnBMain.m, can be found under the TnB directory. The trace data should be downloaded to another directory, which can be called AEexpdata and can be at the same level as TnB. You may then simply open Matlab, go to the TnB directory, and type “TnBMain” in the command window.

To test different traces, you may open TnBMain.m and modify the first two lines. One is to select the trace, such as:
    TraceName = ’../AEexpdata/outdoor1-SF8-CR4’;
and the other is to set the corresponding Spreading Factor:
    SF = 8;
After the program finishes, the number of decoded packets is printed, such as:
    -- TnB decoded 278 pkts --

We used Adafruit Feather M0 with RFM95 LoRa Radio 900 MHz in our experiments with default setting. To collect own traces, here are a few things to keep in mind:

 * Our LoRa device transmits a preamble that starts with 8 upchirps, followed by a symbol with peak at 9, then a symbol with peak at 17, then 2.25 downchirps.
 * A transmitted packet starts with 4 bytes of header, followed by 2 bytes as the node ID, 2 bytes as the packet sequence number, 6 bytes of data, then 2 bytes of CRC. Other packet format can also be decoded by TnB, as long as the last two bytes are the CRC. 
• The signal was sampled by a USRP B210 at 1 Msps, where each sample consists of a real part and an imaginary part, both as 16-bit integers.
