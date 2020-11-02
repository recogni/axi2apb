//
// Converts from axi slave to apb slave interface via axi lite
// with C2C module
//

module axi2apb_intf #(
    parameter integer AXI_ADDR_WIDTH = -1,
    parameter integer AXI_DATA_WIDTH = -1,
    parameter integer AXI_ID_WIDTH = -1,
    parameter integer AXI_USER_WIDTH = -1,
    parameter NoApbSlaves = 1,
    parameter logic [31:0] APBSlotSize = 24'h0001_0000
) (
    input logic axi_clk,
    input logic axi_rst,
    input logic apb_clk,
    input logic apb_rst,

    // AXI bus in
    AXI_BUS axi_slave,

    // APB slave req out
    output axi2apb::apb_req_t                   apb_req,
    output logic              [NoApbSlaves-1:0] apb_sel,

    // APB slave response in
    input axi2apb::apb_resp_t [NoApbSlaves-1:0] apb_resps

);

  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH    ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH    ),
    .AXI_ID_WIDTH   ( AXI_ID_WIDTH      ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH    ))
    axi_slave_cut();

  //
  // AXI slice
  //
  axi_multicut_intf #(
    .ADDR_WIDTH (AXI_ADDR_WIDTH),
    .DATA_WIDTH (AXI_DATA_WIDTH),
    .ID_WIDTH   (AXI_ID_WIDTH),
    .USER_WIDTH (AXI_USER_WIDTH),
    .NUM_CUTS   (1)
  ) i_axi_multicut_intf (
    .clk_i      ( axi_clk       ),
    .rst_ni     ( ~axi_rst      ),
    .in         ( axi_slave     ),
    .out        ( axi_slave_cut )
  );


  //
  // Serialize
  //
  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH    ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH    ),
    .AXI_ID_WIDTH   ( 1                 ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH    ))
    axi_slave_ser();

  axi_serializer_intf #(
    .AXI_ID_WIDTH   ( AXI_ID_WIDTH   ),
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH ),
    .MAX_READ_TXNS  ( 2 ),
    .MAX_WRITE_TXNS ( 2 )
  ) i_axi_serializer (
    .clk_i      ( axi_clk       ),
    .rst_ni     ( ~axi_rst      ),
    .slv        ( axi_slave_cut ),
    .mst        ( axi_slave_ser )
  );



  AXI_BUS #(
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH(32),
    .AXI_ID_WIDTH(1),
    .AXI_USER_WIDTH(AXI_USER_WIDTH)) axi_slave_32b_d();

   //
   // Reduce to 32b data width
   //
   axi_dw_converter_intf #(
			   .AXI_ID_WIDTH(1),
			   .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
			   .AXI_SLV_PORT_DATA_WIDTH(64),
			   .AXI_MST_PORT_DATA_WIDTH(32),
			   .AXI_USER_WIDTH(0),
			   .AXI_MAX_READS(1)
			   )
   data_width_64_to_32 (
			.clk_i(axi_clk),
			.rst_ni(!axi_rst),
			.slv(axi_slave_ser),
			.mst(axi_slave_32b_d)
			);

  //
  // Reduce to 24b address range
  //
  logic [23:0] aw_addr_24b;
  assign aw_addr_24b = axi_slave_32b_d.Slave.aw_addr[23:0];
  logic [23:0] ar_addr_24b;
  assign ar_addr_24b = axi_slave_32b_d.Slave.ar_addr[23:0];

  AXI_BUS #(
    .AXI_ADDR_WIDTH(24),
    .AXI_DATA_WIDTH(32),
    .AXI_ID_WIDTH(1),
    .AXI_USER_WIDTH(AXI_USER_WIDTH)
  ) axi_24b_addr ();

  axi_modify_address_intf #(
    .AXI_SLV_PORT_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_MST_PORT_ADDR_WIDTH(24),
    .AXI_DATA_WIDTH(32),
    .AXI_ID_WIDTH(1),
    .AXI_USER_WIDTH(AXI_USER_WIDTH)
  ) axi_modify_address_intf_i (
    .slv(axi_slave_32b_d),
    .mst(axi_24b_addr),
    .mst_aw_addr_i(aw_addr_24b),
    .mst_ar_addr_i(ar_addr_24b)
    );

//  █████╗ ██╗  ██╗██╗██████╗  █████╗ ██╗  ██╗██╗██╗     ██╗████████╗███████╗
// ██╔══██╗╚██╗██╔╝██║╚════██╗██╔══██╗╚██╗██╔╝██║██║     ██║╚══██╔══╝██╔════╝
// ███████║ ╚███╔╝ ██║ █████╔╝███████║ ╚███╔╝ ██║██║     ██║   ██║   █████╗
// ██╔══██║ ██╔██╗ ██║██╔═══╝ ██╔══██║ ██╔██╗ ██║██║     ██║   ██║   ██╔══╝
// ██║  ██║██╔╝ ██╗██║███████╗██║  ██║██╔╝ ██╗██║███████╗██║   ██║   ███████╗
// ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═╝   ╚═╝   ╚══════╝

  AXI_LITE #(
      .AXI_ADDR_WIDTH(24),
      .AXI_DATA_WIDTH(32)
  ) axi_lite ();

  axi_to_axi_lite_intf #(
      .AXI_ID_WIDTH  (1),
      .AXI_ADDR_WIDTH(24),
      .AXI_DATA_WIDTH(32),
      .AXI_USER_WIDTH(AXI_USER_WIDTH),
      .AXI_MAX_WRITE_TXNS(24'd1),
      .AXI_MAX_READ_TXNS(24'd1),
      .FALL_THROUGH(1'b1)
  ) i_axi_to_axi_lite (
      .clk_i      (axi_clk),
      .rst_ni     (~axi_rst),
      .testmode_i (1'b0),
      .slv        (axi_24b_addr),
      .mst        (axi_lite)
  );

//    █████╗ ██╗  ██╗██╗██╗     ██╗████████╗███████╗ ██████╗██████╗  ██████╗
//   ██╔══██╗╚██╗██╔╝██║██║     ██║╚══██╔══╝██╔════╝██╔════╝██╔══██╗██╔════╝
//   ███████║ ╚███╔╝ ██║██║     ██║   ██║   █████╗  ██║     ██║  ██║██║
//   ██╔══██║ ██╔██╗ ██║██║     ██║   ██║   ██╔══╝  ██║     ██║  ██║██║
//   ██║  ██║██╔╝ ██╗██║███████╗██║   ██║   ███████╗╚██████╗██████╔╝╚██████╗
//   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═╝   ╚═╝   ╚══════╝ ╚═════╝╚═════╝  ╚═════╝
  AXI_LITE #(
      .AXI_ADDR_WIDTH(24),
      .AXI_DATA_WIDTH(32)
  ) axi_lite_cdc ();

  axi_lite_cdc_intf #(
      .AXI_ADDR_WIDTH(24),
      .AXI_DATA_WIDTH(32)
  ) axi_lite_cdc_i (
      .src_clk_i  (axi_clk),
      .src_rst_ni (~axi_rst),
      .src        (axi_lite.Slave),

      .dst_clk_i  (apb_clk),
      .dst_rst_ni (~apb_rst),
      .dst        (axi_lite_cdc.Master)
  );

//   █████╗ ██╗  ██╗██╗██╗     ██╗████████╗███████╗██████╗  █████╗ ██████╗ ██████╗
//  ██╔══██╗╚██╗██╔╝██║██║     ██║╚══██╔══╝██╔════╝╚════██╗██╔══██╗██╔══██╗██╔══██╗
//  ███████║ ╚███╔╝ ██║██║     ██║   ██║   █████╗   █████╔╝███████║██████╔╝██████╔╝
//  ██╔══██║ ██╔██╗ ██║██║     ██║   ██║   ██╔══╝  ██╔═══╝ ██╔══██║██╔═══╝ ██╔══██╗
//  ██║  ██║██╔╝ ██╗██║███████╗██║   ██║   ███████╗███████╗██║  ██║██║     ██████╔╝
//  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═╝   ╚═╝   ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═════╝

  localparam NoAddrRules = NoApbSlaves;

  genvar i;

  // FIXME (uge) - check resulting map
  axi2apb::rule_t [NoAddrRules-1:0] AddrMap;
  for (i = 0; i < NoAddrRules; i++) begin
    assign AddrMap[i] = '{idx: i, start_addr: (APBSlotSize * i), end_addr: (APBSlotSize * (i + 1))};
  end

  logic [NoApbSlaves-1:0][32-1:0] prdata_vec;
  logic [NoApbSlaves-1:0] pready_vec;
  logic [NoApbSlaves-1:0] pslverr_vec;

  // Assign from array of apb responses to vectorized signals
  for (i = 0; i < NoApbSlaves; i++) begin
    assign pready_vec[i]  = apb_resps[i].pready;
    assign prdata_vec[i]  = apb_resps[i].prdata;
    assign pslverr_vec[i] = apb_resps[i].pslverr;
  end

  axi_lite_to_apb_intf #(
      .NoApbSlaves(NoApbSlaves),
      .NoRules    (NoAddrRules),
      .AddrWidth  (24),
      .DataWidth  (32),
      .rule_t     (axi2apb::rule_t)
  ) i_axi_lite_to_apb (
      .clk_i    (apb_clk),
      .rst_ni   (~apb_rst),

      // AXI lite slave port
      .slv      (axi_lite_cdc.Slave),

      // APB master port
      .paddr_o  (apb_req.paddr[15:0]), // Expand map fopr 64 bit alignment
      .pprot_o  (apb_req.pprot),
      .pselx_o  (apb_sel),
      .penable_o(apb_req.penable),
      .pwrite_o (apb_req.pwrite),
      .pwdata_o (apb_req.pwdata[31:0]),
      .pstrb_o  (apb_req.pstrb[3:0]),
      .pready_i (pready_vec),
      .prdata_i (prdata_vec),
      .pslverr_i(pslverr_vec),

      // Address map
      .addr_map_i(AddrMap)
  );

  assign apb_req.paddr[31:16] = '0;

endmodule  // axi2apb
