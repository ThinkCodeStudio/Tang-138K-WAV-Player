module top (
    input clk,
    input rstn,


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
    inout [3:0] ddr_dqs_n,

	output wire init_calib_complete
);

    localparam INIT = 0;
    localparam IDLE = 1;
    localparam WRITE = 2;
    localparam WITE = 3;
    localparam READ = 4;
    localparam OK = 5;

    reg [3:0] state;

    wire write_valid;
    wire read_valid;

    wire write_en;
    wire read_en;
    assign write_en = state == WRITE;
    assign read_en  = state == READ;

    reg  [ 7:0] write_data;
    wire [15:0] read_data;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state <= INIT;
        end else begin
            case (state)
                INIT: state <= init_calib_complete ? IDLE : state;
                IDLE: state <= write_valid ? WRITE : state;
                WRITE: begin
                    write_data <= write_data + 8'd1;
                    state <= &write_data ? WITE : state;
                end
                WITE: state <= read_valid ? READ : state;
                READ: state <= !read_valid ? OK : state;
                OK: ;
                default state <= INIT;
            endcase
        end
    end


    fifo_ram fifo_ram_module (
        .clk (clk),
        .rstn(rstn),

        .init_calib_complete(init_calib_complete),

        .write_data(write_data),
        .write_en(write_en),
        .write_valid(write_valid),

        .read_en(read_en),
        .read_data(read_data),
        .read_valid(read_valid),

        .ddr_addr(ddr_addr),
        .ddr_ba(ddr_ba),
        .ddr_cs(ddr_cs),
        .ddr_ras(ddr_ras),
        .ddr_cas(ddr_cas),
        .ddr_we(ddr_we),
        .ddr_clk(ddr_clk),
        .ddr_clk_n(ddr_clk_n),
        .ddr_cke(ddr_cke),
        .ddr_odt(ddr_odt),
        .ddr_rst(ddr_rst),
        .ddr_dqm(ddr_dqm),
        .ddr_dq(ddr_dq),
        .ddr_dqs(ddr_dqs),
        .ddr_dqs_n(ddr_dqs_n)
    );
endmodule
