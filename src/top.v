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

    output wire init_calib_complete,

    output sd_clk,
    inout sd_cmd,
    input sd_data,
    output sd_file_found
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
    wire sd_outen;
    assign write_en = sd_outen;
    assign read_en  = state == READ;

    wire  [ 7:0] write_data;
    wire [15:0] read_data;


    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state <= INIT;
        end else begin
            case (state)
                INIT: state <= sd_file_found ? IDLE : state;
                IDLE: state <= sd_outen ? WRITE : state;
                WRITE: state <= !sd_outen ? WITE : state;
                WITE: state <= read_valid ? READ : state;
                READ: state <= !read_valid ? OK : state;
                OK: ;
                default state <= INIT;
            endcase
        end
    end



    sd_file_reader #(
        .FILE_NAME_LEN(5),
        .FILE_NAME("m.wav")
    ) sd_reader (
        .rstn(rstn),
        .clk(clk),
        .sdclk(sd_clk),
        .sdcmd(sd_cmd),
        .sddat0(sd_data),
        .card_stat(),
        .card_type(),
        .filesystem_type(),
        .file_found(sd_file_found),
        .outen(sd_outen),
        .outbyte(write_data)
    );


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
