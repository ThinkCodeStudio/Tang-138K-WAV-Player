module wav_player #(
    parameter SYS_CLK = 50_000_000
) (
    input clk,
    input rstn,

    input enable,
    input [15:0] in_data,

    output reg [31:0] file_size,
    output reg [1:0] channel_len,
    output reg [31:0] sample_rate,
    output reg [15:0] sample_bits_per,
    output [31:0] data_size,
    output reg outen,
    output reg out_clk,
    output reg [15:0] out_data,
    output error
);

    localparam RIFF = 0;
    localparam FILE_SIZE = 1;
    localparam FILE_FMT = 2;
    localparam FMT = 3;
    localparam BLOCK_LEN = 4;
    localparam CODE_FMT = 5;
    localparam CHANNEL_LEN = 6;
    localparam SAMPLE_RATE = 7;
    localparam DATA_RATE = 8;
    localparam BLOCK_ALIGN = 9;
    localparam SAMPLE_BITS_PER = 10;
    localparam OTHER = 11;
    localparam DATA = 12;
    localparam DATA_SIZE = 13;
    localparam DATA_BIT = 14;
    localparam ERROR = 15;
    reg [ 3:0] state;

    reg [31:0] r_data_len;
    assign data_len = r_data_len / 2;

    reg  bit_cnt;
    reg  short_data_l;
    reg  short_data_h;
    wire long_data;
    assign long_data = {short_data_l, short_data_h};
    assign error = state == ERROR;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            short_data_l = 16'd0;
            short_data_h = 16'd0;
        end else begin
            if (bit_cnt == 1'b0) short_data_l <= in_data;
            else short_data_h <= in_data;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state   <= RIFF;
            bit_cnt <= 1'b0;
        end else begin
            if (enable) begin
                bit_cnt <= bit_cnt + 1'b1;
                case (state)
                    RIFF: begin
                        if (bit_cnt == 1'b1)
                            state <= long_data == "RIFF" ? FILE_SIZE : ERROR;
                    end
                    FILE_SIZE: begin
                        if(bit_cnt == 1'b1)begin
                            file_size <= long_data;
                            state <= FILE_FMT;
                        end
                    end
                    FILE_FMT:begin
                        if(bit_cnt == 1'b1)begin
                            state <= long_data == "WAVE" ? FMT : ERROR;
                        end
                    end


                endcase
            end
        end
    end


endmodule
