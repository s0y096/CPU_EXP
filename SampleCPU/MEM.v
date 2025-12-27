`include "lib/defines.vh"
module MEM(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,

    input wire [`EX_TO_MEM_WD-1:0] ex_to_mem_bus,
    input wire [31:0] data_sram_rdata,
    input wire [`LoadBus-1:0] ex_load_bus,// 从EX阶段传递的Load类型指令信号
    input wire [3:0] data_ram_sel,  // 数据RAM选择信号

    output wire [`MEM_TO_WB_WD-1:0] mem_to_wb_bus,
    
    output wire [`MEM_TO_RF_WD-1:0] mem_to_rf_bus //MEM阶段传回regfile的数据总线
);

    reg [`EX_TO_MEM_WD-1:0] ex_to_mem_bus_r;
    reg [`LoadBus-1:0] ex_load_bus_r;  // 暂存Load指令信号
    reg [3:0] data_ram_sel_r;          // 暂存数据RAM选择信号

    always @ (posedge clk) begin
        if (rst) begin
            ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
            data_ram_sel_r <= 4'b0;
            ex_load_bus_r <= `LoadBus'b0;
        end
        // else if (flush) begin
        //     ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        // end
        else if (stall[3]==`Stop && stall[4]==`NoStop) begin
            ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
            data_ram_sel_r <= 4'b0;
            ex_load_bus_r <= `LoadBus'b0;
        end
        else if (stall[3]==`NoStop) begin
            ex_to_mem_bus_r <= ex_to_mem_bus;
            data_ram_sel_r <= data_ram_sel;      // 更新数据RAM选择信号
            ex_load_bus_r <= ex_load_bus;        // 更新Load指令信号
        end
    end

    wire [31:0] mem_pc;
    wire data_ram_en;
    wire [3:0] data_ram_wen;
    wire sel_rf_res;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire [31:0] rf_wdata;
    wire [31:0] ex_result;
    wire [31:0] mem_result;
    
    wire inst_lw;
    
    wire [31:0] w_data;

    assign {
        mem_pc,         // 75:44
        data_ram_en,    // 43
        data_ram_wen,   // 42:39
        sel_rf_res,     // 38
        rf_we,          // 37
        rf_waddr,       // 36:32
        ex_result       // 31:0
    } =  ex_to_mem_bus_r;
    
    assign {
        inst_lw
    } = ex_load_bus_r;
    
    assign w_data = data_sram_rdata;
    
    assign mem_result = inst_lw ? w_data : 32'b0;

    assign rf_wdata = (sel_rf_res & data_ram_en) ? mem_result : ex_result;

    assign mem_to_wb_bus = {
        mem_pc,     // 69:38
        rf_we,      // 37
        rf_waddr,   // 36:32
        rf_wdata    // 31:0
    };
    
    // MEM阶段传回regfile的数据总线
    assign mem_to_rf_bus = {
        rf_we,     // 37
        rf_waddr,  // 36:32
        rf_wdata   // 31:0
    };


endmodule