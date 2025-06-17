`timescale 1ns/1ps

module CHIP(CLK, RESET, ENABLE, DATA_IN, DATA_OUT, READY);

// I/O Ports
input           CLK;        //clock signal
input           RESET;      //sync. RESET=1
input           ENABLE;     //input data sequence when ENABLE =1
input   [7:0]   DATA_IN;    //input data sequence
output  [7:0]   DATA_OUT;   //output data sequence
output          READY;      //output data is READY when READY=1

reg change;
reg jump;
reg READY;
reg [2:0] state, next_state;
reg [5:0] data_count;
reg [7:0] DATA_OUT;
reg [7:0] A[0:7];
reg [7:0] B[0:7];

//result
reg store_sign;
reg [10:0] store_exp;
reg [51:0] store_frac;
reg [105:0] calc_frac;
reg [10:0] calc_exp;
reg [52:0] frac_A;
reg [52:0] frac_B;

reg round_up;

//comb.
reg [105:0] shift;
wire [63:0] result;

parameter data=3'd0, count=3'd1, show=3'd2;

integer i;

//concate result
assign result = {store_sign, store_exp, store_frac};

//state, next_state
always @(posedge CLK or posedge RESET) begin
    if(RESET) state<=data;
    else state<=next_state;
end

always @(*) begin
    case(state)
        data: next_state = (data_count==6'd0 && change==1'b1) ? count : data;
        count: next_state = (jump==1'b1) ? show : ((data_count==6'd56) ? show : count);
        show: next_state = (data_count==6'd8) ? data : show;
        default: next_state = data;
    endcase
end

//data_count
always @(posedge CLK or posedge RESET) begin
    if(RESET) data_count<=6'd7;
    else if(state==data) begin
        if(data_count==6'd0 && change==1'b1) data_count<=6'd0;
        else if(data_count==6'd0) data_count<=6'd7;
        else if(ENABLE==1'b1) data_count<=data_count-6'd1;
    end
    else if(state==count) begin
        if(data_count<=6'd1 && jump==1'b1) data_count<=6'd0;
        else if(data_count==6'd56) data_count<=6'd0;
        else data_count<=data_count+6'd1;
    end
    else if(state==show) begin
        if(data_count==6'd8) data_count<=6'd7;
        else data_count<=data_count+6'd1;
    end
end

//change
always @(posedge CLK or posedge RESET) begin
    if(RESET) change<=1'b0;
    else if(state==data) begin
        if(change==1'b1) begin
            if(data_count==6'd0) change<=1'b0;
        end
        else if(data_count==6'd0) change<=1'b1;
    end
end

//A
always @(posedge CLK or posedge RESET) begin
    if(RESET) begin
        for(i=0; i<8; i=i+1) A[i]<=8'd0;
    end
    else if(state==data) begin
        if(change==1'b0 && ENABLE==1'b1) A[data_count]<=DATA_IN;
    end
end

//B
always @(posedge CLK or posedge RESET) begin
    if(RESET) begin
        for(i=0; i<8; i=i+1) B[i]<=8'd0;
    end
    else if(state==data) begin
        if(change==1'b1 && ENABLE==1'b1) B[data_count]<=DATA_IN;
    end
end

//store_sign
always @(posedge CLK or posedge RESET) begin
    if(RESET) store_sign<=1'b0;
    else if(state==count) begin
        if({(A[0][6:0]), A[1][7:4]}==11'b11111111111) begin
            if(({(A[1][3:0]), A[2], A[3], A[4], A[5], A[6], A[7]})==52'd0) store_sign<=A[0][7];
            else if({B[0][6:0], B[1][7:4]}==11'b11111111111 && {(B[1][3:0]), B[2], B[3], B[4], B[5], B[6], B[7]}!=52'd0) store_sign<=B[0][7];
            else if({A[1][3:0], A[2], A[3], A[4], A[5], A[6], A[7]}==52'd0 && {B[1][3:0], B[2], B[3], B[4], B[5], B[6], B[7]}==52'd0) begin
                if({A[0][6:0], A[1][7:4]}==11'b11111111111 && {B[0][6:0], B[1][7:4]}==11'b11111111111)begin
                    store_sign<=(A[0][7])^(B[0][7]);
                end
                else store_sign<=1'b1;            
            end
            else store_sign<=(A[0][7])^(B[0][7]);
        end
        else if({B[0][6:0], B[1][7:4]}==11'b11111111111) begin
            if({A[0][6:0], A[1][7:4]}==11'b11111111111 && {(A[1][3:0]), A[2], A[3], A[4], A[5], A[6], A[7]}!=52'd0) store_sign<=A[0][7];
            else if({B[0][6:0], B[1][7:4]}==11'b11111111111 && {(B[1][3:0]), B[2], B[3], B[4], B[5], B[6], B[7]}!=52'd0) store_sign<=B[0][7];
            else if({(A[1][3:0]), A[2], A[3], A[4], A[5], A[6], A[7]}==52'd0 && {B[1][3:0], B[2], B[3], B[4], B[5], B[6], B[7]}==52'd0) begin
                if({A[0][6:0], A[1][7:4]}==11'b11111111111 && {B[0][6:0], B[1][7:4]}==11'b11111111111) begin
                    store_sign<=(A[0][7])^(B[0][7]);
                end
                else store_sign<=1'b1;
            end
            else store_sign<=(A[0][7])^(B[0][7]);
        end
        else if(data_count==6'd0) store_sign<=(A[0][7])^(B[0][7]);
    end
end

//store_exp
always @(posedge CLK or posedge RESET) begin
    if(RESET) store_exp<=11'd0;
    else if(state==count) begin
        if(({A[0][6:0], A[1][7:4]}==11'b11111111111) || ({B[0][6:0], B[1][7:4]}==11'b11111111111)) store_exp<=11'b11111111111;
        else if(({A[0][6:0], A[1][7:4]}==11'd0 && ({A[1][3:0], A[2], A[3], A[4], A[5], A[6], A[7]})==52'd0) || ({B[0][6:0], B[1][7:4]}==11'd0 && {B[1][3:0], B[2], B[3], B[4], B[5], B[6], B[7]}==52'd0)) store_exp<=11'b00000000000;
        else if(data_count==6'd55) store_exp<=calc_exp;
    end
end

//store_frac
always @(posedge CLK or posedge RESET) begin
    if(RESET) store_frac<=52'd0;
    else if(state==count) begin
        if({A[0][6:0], A[1][7:4]}==11'b11111111111 || {B[0][6:0], B[1][7:4]}==11'b11111111111) begin
            if({A[0][6:0], A[1][7:4]}==11'b11111111111 && {A[1][3:0], A[2], A[3], A[4], A[5], A[6], A[7]}==52'd0) begin
                store_frac[51]<=1'b1;
                store_frac[50:0]<={A[1][2:0], A[2], A[3], A[4], A[5], A[6], A[7]};
            end
            else if({B[0][6:0], B[1][7:4]}==11'b11111111111 && {B[1][3:0], B[2], B[3], B[4], B[5], B[6], B[7]}==52'd0) begin
                store_frac[51]<=1'b1;
                store_frac[50:0]<={B[1][2:0], B[2], B[3], B[4], B[5], B[6], B[7]};
            end
            else if({A[1][3:0], A[2], A[3], A[4], A[5], A[6], A[7]}==52'd0 && {B[1][3:0], B[2], B[3], B[4], B[5], B[6], B[7]}==52'd0) begin
                if({A[0][6:0], A[1][7:4]}==11'b11111111111 && {B[0][6:0], B[1][7:4]}==11'b11111111111) begin
                    store_frac[51]<=1'b0;
                    store_frac[50:0]<=51'b0;
                end
                else begin
                    store_frac[51]<=1'b1;
                    store_frac[50:0]<=51'b0;
                end
            end
            else store_frac<=52'd0;
        end
        else if(({A[0][6:0], A[1][7:4]}==11'd0 && {A[1][3:0], A[2], A[3], A[4], A[5], A[6], A[7]}==52'd0) || ({B[0][6:0], B[1][7:4]}==11'd0 && {B[1][3:0], B[2], B[3], B[4], B[5], B[6], B[7]}==52'd0)) store_frac<=52'd0;
        else if(data_count==6'd55) store_frac<=shift[104:53] + round_up;
    end
end

//frac_A
always @(posedge CLK or posedge RESET) begin
    if(RESET) frac_A<=53'd0;
    else if(state==data) begin
        if(data_count==6'd0) begin
            frac_A<={1'b1, {A[1][3:0], A[2], A[3], A[4], A[5], A[6], A[7]}};
        end
    end
end

//frac_B
always @(posedge CLK or posedge RESET) begin
    if(RESET) frac_B<=53'd0;
    else if(state==data) begin
        if(data_count==6'd0) begin
            frac_B<={1'b1, {B[1][3:0], B[2], B[3], B[4], B[5], B[6], B[7]}};
        end
    end
end

//calc_frac
always @(posedge CLK or posedge RESET) begin
    if(RESET) calc_frac<=106'd0;
    //else if(state==count&&data_count>6'd53) begin
    else if(state==count) begin
        if(data_count<6'd53) begin
            if(data_count==6'd0) begin
                if(frac_B[0]==1'b0) begin
                    if(frac_B[1]==1'b1) calc_frac[53:0]<={frac_A, 1'b0};
                end
                else if(frac_B[0]==1'b1)begin
                    if(frac_B[1]==1'b0) calc_frac[52:0]<=frac_A;
                    else calc_frac<=(frac_A)+({frac_A, 1'b0});
                end    
            end
            else if(data_count>6'd1) begin
                if(frac_B[data_count]==1'b1) calc_frac<=calc_frac+(frac_A<<(data_count));
            end
        end
    end
    else if(state==show) begin
        calc_frac<=106'd0;
    end
end

//calc_exp
always @(posedge CLK or posedge RESET) begin
    if(RESET) calc_exp<=11'd0;
    else if(state==count) begin
        if(data_count==6'd53) calc_exp<={A[0][6:0], A[1][7:4]}+{B[0][6:0], B[1][7:4]}+calc_frac[105];
        else if(data_count==6'd54) calc_exp<=calc_exp-11'b01111111111;
    end
end

//READY
always @(posedge CLK or posedge RESET) begin
    if(RESET) READY<=1'b0;
    else if(state==show) begin
        if(data_count==4'd8) READY<=1'b0;
        else READY<=1'b1;
    end
end

//DATA_OUT
always @(posedge CLK or posedge RESET) begin
    if(RESET) DATA_OUT<=8'd0;
    else if(state==show) begin
        case(data_count)
            4'd0: DATA_OUT<=result[7:0];
            4'd1: DATA_OUT<=result[15:8];
            4'd2: DATA_OUT<=result[23:16];
            4'd3: DATA_OUT<=result[31:24];
            4'd4: DATA_OUT<=result[39:32];
            4'd5: DATA_OUT<=result[47:40];
            4'd6: DATA_OUT<=result[55:48];
            4'd7: DATA_OUT<=result[63:56];
        endcase
    end
end

//jump
always @(posedge CLK or posedge RESET) begin
    if(RESET) jump<=1'b0;
    else if(state==count) begin
        if({A[0][6:0], A[1][7:4]}==11'b11111111111 || {B[0][6:0], B[1][7:4]}==11'b11111111111) jump<=1'b1;
        else if(({A[0][6:0], A[1][7:4]}==11'd0 && {A[1][3:0], A[2], A[3], A[4], A[5], A[6], A[7]}==52'd0) || ({B[0][6:0], B[1][7:4]}==11'd0 && {B[1][3:0], B[2], B[3], B[4], B[5], B[6], B[7]}==52'd0)) jump<=1'b1;
    end
    else if(state==show) begin
        jump<=1'b0;
    end
end

//shift
always @(posedge CLK or posedge RESET) begin
    if(RESET) shift<=106'd0;
    else if(state==count) begin
        if(data_count==6'd53) begin
            shift<=(calc_frac[105]==1'b1) ? calc_frac : (calc_frac<<1);
        end
    end
end

//round_up
always @(posedge CLK or posedge RESET) begin
    if(RESET) round_up<=1'b0;
    else if(state==count) begin
        if(data_count==6'd54) round_up<=shift[52] & (shift[51] | (|shift[50:0]) | shift[104:53]);
    end
end

endmodule