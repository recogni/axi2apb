// Copyright (c) 2020 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Author: Wolfgang Roenninger <wroennin@ethz.ch>

// Derived from testbench for axi_lite_to_apb
//

`include "axi/typedef.svh"
`include "axi/assign.svh"

package axi2apb;
   // Type widths                                                                                                           
   localparam int unsigned AxiAddrWidth = 32;
   localparam int unsigned AxiDataWidth = 32;
   localparam int unsigned AxiStrbWidth = AxiDataWidth/8;

   typedef logic [AxiAddrWidth-1:0] addr_t;
   typedef axi_pkg::xbar_rule_32_t  rule_t; // Has to be the same width as axi addr                                    
   typedef logic [AxiDataWidth-1:0] data_t;
   typedef logic [AxiStrbWidth-1:0] strb_t;

   typedef struct packed {
      addr_t          paddr;
      axi_pkg::prot_t pprot;                 // same as AXI, this is allowed
      logic 			 penable;
      logic 			 pwrite;
      data_t          pwdata;
      strb_t          pstrb;
   } apb_req_t;

   typedef struct packed {
      logic 			 pready;
      data_t          prdata;
      logic 			 pslverr;
   } apb_resp_t;
   
  `AXI_LITE_TYPEDEF_AW_CHAN_T(aw_chan_t, addr_t)
  `AXI_LITE_TYPEDEF_W_CHAN_T(w_chan_t, data_t, strb_t)
  `AXI_LITE_TYPEDEF_B_CHAN_T(b_chan_t)

  `AXI_LITE_TYPEDEF_AR_CHAN_T(ar_chan_t, addr_t)
  `AXI_LITE_TYPEDEF_R_CHAN_T(r_chan_t, data_t)

  `AXI_LITE_TYPEDEF_REQ_T(axi_req_t, aw_chan_t, w_chan_t, ar_chan_t)
  `AXI_LITE_TYPEDEF_RESP_T(axi_resp_t, b_chan_t, r_chan_t)
   
endpackage // axi2apb
   
