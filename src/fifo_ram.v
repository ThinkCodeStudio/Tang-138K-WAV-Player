module fifo_ram (
    input clk,
    input rstn,

    output init_calib_complete,

    input [7:0] write_data,
    input write_en,
    output write_valid,

    input read_en,
    output [15:0] read_data,
    output read_valid,

    output [14:0] ddr_addr,
    output [2:0] ddr_ba,
    output ddr_cs,
    output ddr_ras,
    output ddr_cas,
    output ddr_we,
    output ddr_clk,
    output ddr_clk_n,
    output ddr_cke,
    output ddr_odt,
    output ddr_rst,
    inout [3:0] ddr_dqm,
    inout [31:0] ddr_dq,
    inout [3:0] ddr_dqs,
    inout [3:0] ddr_dqs_n
);

    wire clk100m;
    wire clk400m;
    wire clk_en;
    wire clk_lock;
    wire clk_out;

    localparam CMD_WRITE = 3'b000;
    localparam CMD_READ = 3'b001;

    wire cmd_ready;
    wire [2:0] cmd;
    wire cmd_en;
    wire [28:0] app_addr;

    wire wr_ready;
    wire wr_en;
    wire wr_end;

    wire [255:0] rd_data;
    wire rd_data_valid;

    localparam INIT = 4'b0000;
    localparam IDLE = 4'b0001;
    localparam WRITE_RAM = 4'b0010;
    localparam READ_RAM = 4'b0011;

    reg [3:0] state;
    reg [31:0] count;

    reg [27:0] read_addr;
    reg [27:0] write_addr;

    wire fifo_read_full;
    wire fifo_write_empty;
    wire fifo_read_almost_empty;
    wire [255:0] fifo_write_q;
    wire fifo_write_rd_en;
    wire fifo_read_wr_en;
    wire fifo_write_full;
    wire fifo_read_empty;

    assign write_valid = ~fifo_write_full;
    assign read_valid = ~fifo_read_empty;

    assign app_addr = {1'b0, cmd == CMD_WRITE ? write_addr : read_addr};
    assign cmd = state == WRITE_RAM ? CMD_WRITE : CMD_READ;
    assign cmd_en = ((state==WRITE_RAM && wr_ready) || (state == READ_RAM) )&&cmd_ready;
    assign wr_en = state == WRITE_RAM && cmd_en;
    assign wr_end = wr_en;

    assign fifo_write_rd_en = wr_en;
    assign fifo_read_wr_en = rd_data_valid;

    always @(posedge clk_out or negedge rstn) begin
        if (!rstn) begin
            state <= INIT;
            count <= 0;
            write_addr <= 0;
            read_addr <= 0;
        end else begin
            case (state)
                INIT: state <= init_calib_complete ? IDLE : state;
                IDLE: begin
                    if (!fifo_write_empty)
                        state <= WRITE_RAM;
                    else if (fifo_read_almost_empty && count != 0)
                        state <= READ_RAM;
                    else state <= state;

                end
                WRITE_RAM: begin
                    if (!fifo_write_empty && wr_en) begin
                        count <= count + 'd1;
                        write_addr <= write_addr + 28'd8;
                        state <= state;
                    end else begin
                        count <= count;
                        write_addr <= write_addr;
                        state <= fifo_write_empty ? IDLE : state;
                    end
                end
                READ_RAM: begin
                    if (!fifo_read_full && count != 0 && cmd_en) begin
                        state <= state;
                        count <= count - 'd1;
                        read_addr <= read_addr + 28'd8;
                    end else begin
                        read_addr <= read_addr;
                        count <= count;
                        state <= fifo_read_full || count == 0 ? IDLE : state;
                    end
                end
                // default : state <= INIT;
            endcase
        end
    end



    DDR3_Memory_Interface_Top ddr_module (
        .clk(clk100m),  //input clk
        .pll_stop(clk_en),  //output pll_stop
        .memory_clk(clk400m),  //input memory_clk
        .pll_lock(clk_lock),  //input pll_lock
        .rst_n(rstn),  //input rst_n

        .cmd_ready(cmd_ready),  //output cmd_ready
        .cmd(cmd),  //input [2:0] cmd
        .cmd_en(cmd_en),  //input cmd_en
        .addr(app_addr),  //input [28:0] addr

        .wr_data_rdy(wr_ready),  //output wr_data_rdy
        .wr_data(fifo_write_q),  //input [255:0] wr_data
        .wr_data_en(wr_en),  //input wr_data_en
        .wr_data_end(wr_end),  //input wr_data_end
        .wr_data_mask(0),  //input [31:0] wr_data_mask

        .rd_data(rd_data),  //output [255:0] rd_data
        .rd_data_valid(rd_data_valid),  //output rd_data_valid
        .rd_data_end(),  //output rd_data_end

        .sr_req(1'b0),  //input sr_req
        .ref_req(1'b0),  //input ref_req
        .sr_ack(),  //output sr_ack
        .ref_ack(),  //output ref_ack
        .init_calib_complete(init_calib_complete),  //output init_calib_complete
        .clk_out(clk_out),  //output clk_out

        .ddr_rst(),  //output ddr_rst
        .burst(1'b0),  //input burst

        .O_ddr_addr(ddr_addr),  //output [14:0] O_ddr_addr
        .O_ddr_ba(ddr_ba),  //output [2:0] O_ddr_ba
        .O_ddr_cs_n(ddr_cs),  //output O_ddr_cs_n
        .O_ddr_ras_n(ddr_ras),  //output O_ddr_ras_n
        .O_ddr_cas_n(ddr_cas),  //output O_ddr_cas_n
        .O_ddr_we_n(ddr_we),  //output O_ddr_we_n
        .O_ddr_clk(ddr_clk),  //output O_ddr_clk
        .O_ddr_clk_n(ddr_clk_n),  //output O_ddr_clk_n
        .O_ddr_cke(ddr_cke),  //output O_ddr_cke
        .O_ddr_odt(ddr_odt),  //output O_ddr_odt
        .O_ddr_reset_n(ddr_rst),  //output O_ddr_reset_n
        .O_ddr_dqm(ddr_dqm),  //output [3:0] O_ddr_dqm
        .IO_ddr_dq(ddr_dq),  //inout [31:0] IO_ddr_dq
        .IO_ddr_dqs(ddr_dqs),  //inout [3:0] IO_ddr_dqs
        .IO_ddr_dqs_n(ddr_dqs_n)  //inout [3:0] IO_ddr_dqs_n
    );

    fifo_ram_write fifo_write (
        .Data(write_data),  //input [7:0] Data
        .Reset(~rstn),  //input Reset
        .WrClk(clk),  //input WrClk
        .RdClk(clk_out),  //input RdClk
        .WrEn(write_en),  //input WrEn
        .RdEn(fifo_write_rd_en),  //input RdEn
        .Q(fifo_write_q),  //output [255:0] Q
        .Empty(fifo_write_empty),  //output Empty
        .Full(fifo_write_full)  //output Full
    );

    fifo_ram_read fifo_read (
        .Data(rd_data),  //input [255:0] Data
        .Reset(~rstn),  //input Reset
        .WrClk(clk_out),  //input WrClk
        .RdClk(clk),  //input RdClk
        .WrEn(fifo_read_wr_en),  //input WrEn
        .RdEn(read_en),  //input RdEn
        .Almost_Empty(fifo_read_almost_empty),  //output Almost_Empty
        .Q(read_data),  //output [15:0] Q
        .Empty(fifo_read_empty),  //output Empty
        .Full(fifo_read_full)  //output Full
    );

    Gowin_PLL pll (
        .lock(clk_lock),  //output lock
        .clkout0(),  //output clkout0
        .clkout1(clk100m),  //output clkout1
        .clkout2(clk400m),  //output clkout2
        .clkin(clk),  //input clkin
        .enclk0(1'b1),  //input enclk0
        .enclk1(1'b1),  //input enclk1
        .enclk2(clk_en)  //input enclk2
    );
endmodule
