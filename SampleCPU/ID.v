`include "lib/defines.vh"
module ID(
    input wire clk, 
    input wire rst,  
    // input wire flush,
    input wire [`StallBus-1:0] stall,
    
    output wire stallreq,

    input wire [`IF_TO_ID_WD-1:0] if_to_id_bus,

    input wire [31:0] inst_sram_rdata,
    
    input wire ex_id, // EX½×¶Î´«»ØÐÅºÅ£¬EX½×¶Î´«»Øsel_rf_resÐÅºÅ

    input wire [`WB_TO_RF_WD-1:0] wb_to_rf_bus,
    
    input wire [`EX_TO_RF_WD-1:0] ex_to_rf_bus, // EXï¿½×¶Î´ï¿½ï¿½ï¿½regfileï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½

    input wire [`MEM_TO_RF_WD-1:0] mem_to_rf_bus, // MEMï¿½×¶Î´ï¿½ï¿½ï¿½regfileï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
    
    output wire stallreq_for_bru, // ÎªÌø×ª·ÖÖ§Ö¸ÁîÇëÇóÍ£¶ÙµÄÐÅºÅ
    
    output wire [`LoadBus-1:0] id_load_bus, // ID½×¶Î´«µÝµÄLoadÐÍÖ¸ÁîÐÅºÅ
    output wire [`SaveBus-1:0] id_save_bus, // ID½×¶Î´«µÝµÄSaveÐÍÖ¸ÁîÐÅºÅ

    output wire [`ID_TO_EX_WD-1:0] id_to_ex_bus,

    output wire [`BR_WD-1:0] br_bus 
);

    reg [`IF_TO_ID_WD-1:0] if_to_id_bus_r;
    wire [31:0] inst;
    wire [31:0] id_pc;
    wire ce;
    reg flag; //Í£¶Ù±êÊ¶·û
    reg [31:0] buf_inst;//»º´æÍ£¶ÙÊ±µÄÖ¸Áî

    wire wb_rf_we;
    wire [4:0] wb_rf_waddr;
    wire [31:0] wb_rf_wdata;
    
    //ï¿½ï¿½ï¿½ï¿½EXï¿½×¶Îµï¿½ï¿½Åºï¿½
    wire ex_rf_we;
    wire [4:0] ex_rf_waddr;
    wire [31:0] ex_rf_wdata; 
    
    //ï¿½ï¿½ï¿½ï¿½MEMï¿½×¶Îµï¿½ï¿½Åºï¿½
    wire mem_rf_we;
    wire [4:0] mem_rf_waddr;
    wire [31:0] mem_rf_wdata; 

    always @ (posedge clk) begin
        if (rst) begin
            if_to_id_bus_r <= `IF_TO_ID_WD'b0;
            flag <= 1'b0; //ï¿½ï¿½Î»ï¿½Åºï¿½ï¿½ï¿½Ð§ï¿½ï¿½ï¿½ï¿½Õ±ï¿½Ê¶ï¿½Åºï¿?
            buf_inst <= 32'b0; //ï¿½ï¿½Î»ï¿½Åºï¿½ï¿½ï¿½Ð§ï¿½ï¿½ï¿½ï¿½Õ»ï¿½ï¿½ï¿½ï¿½Ö¸ï¿½ï¿½
        end
        // else if (flush) begin
        //     ic_to_id_bus <= `IC_TO_ID_WD'b0;
        // end
        else if (stall[1]==`Stop && stall[2]==`NoStop) begin
            if_to_id_bus_r <= `IF_TO_ID_WD'b0;
            flag <= 1'b0; //stallï¿½Åºï¿½IDï¿½×¶Îºï¿½Í£ï¿½Ù£ï¿½ï¿½ï¿½Õ±ï¿½Ê¶ï¿½Åºï¿?
        end
        else if (stall[1]==`NoStop) begin
            if_to_id_bus_r <= if_to_id_bus;
            flag <= 1'b0; //stallï¿½Åºï¿½È«ï¿½ï¿½ï¿½ï¿½Í£ï¿½Ù£ï¿½ï¿½ï¿½Õ±ï¿½Ê¶ï¿½Åºï¿?
        end
        else if (stall[1]==`Stop && stall[2]==`Stop && flag==1'b0) begin
            flag <= 1'b1; //stallï¿½Åºï¿½IDï¿½ï¿½EXÍ£ï¿½Ù£ï¿½ï¿½Ò±ï¿½Ê¶ï¿½Åºï¿½Î´ï¿½ï¿½Í£ï¿½ï¿½×´Ì¬Î»ï¿½ï¿½ï¿½ï¿½Î»ï¿½ï¿½Ê¶ï¿½Åºï¿½
            buf_inst <= inst_sram_rdata; //stallï¿½Åºï¿½IDï¿½ï¿½EXÍ£ï¿½Ù£ï¿½ï¿½Ò±ï¿½Ê¶ï¿½Åºï¿½Î´ï¿½ï¿½Í£ï¿½ï¿½×´Ì¬Î»ï¿½ï¿½ï¿½ï¿½ï¿½æµ±Ç°Ö¸ï¿½ï¿½
        end
    end
    
    //¸ù¾ÝÊ¹ÄÜÐÅºÅºÍ±êÊ¶·ûÑ¡ÔñÖ¸Áî
    assign inst = (ce ? (flag ? buf_inst : inst_sram_rdata) : 32'b0);
    
    assign {
        ce,
        id_pc
    } = if_to_id_bus_r;
    
    assign {
        wb_rf_we,
        wb_rf_waddr,
        wb_rf_wdata
    } = wb_to_rf_bus;
    
    //ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½EXï¿½ï¿½ï¿½Åºï¿½
    assign {
        ex_rf_we,
        ex_rf_waddr,
        ex_rf_wdata
    } = ex_to_rf_bus;
    
    //ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½MEMï¿½ï¿½ï¿½Åºï¿½
    assign {
        mem_rf_we,
        mem_rf_waddr,
        mem_rf_wdata
    } = mem_to_rf_bus;

    wire [5:0] opcode;
    wire [4:0] rs,rt,rd,sa;
    wire [5:0] func;
    wire [15:0] imm;
    wire [25:0] instr_index;
    wire [19:0] code;
    wire [4:0] base;
    wire [15:0] offset;
    wire [2:0] sel;

    wire [63:0] op_d, func_d;
    wire [31:0] rs_d, rt_d, rd_d, sa_d;

    wire [2:0] sel_alu_src1;
    wire [3:0] sel_alu_src2;
    wire [11:0] alu_op;

    wire data_ram_en;
    wire [3:0] data_ram_wen;
    
    wire rf_we;
    wire [4:0] rf_waddr;
    wire sel_rf_res;   //Ñ¡Ôñalu½á¹û»òÊÇloadÊý¾ÝÐ´Èë¼Ä´æÆ÷
    wire [2:0] sel_rf_dst;

    wire [31:0] rdata1, rdata2;
    wire [31:0] ndata1, ndata2;// Ñ¡Ôñ×îÐÂµÄÊý¾Ý½øÐÐ´¦Àí
    
    regfile u_regfile(
    	.clk    (clk    ),
        .raddr1 (rs ),
        .rdata1 (rdata1 ),
        .raddr2 (rt ),
        .rdata2 (rdata2 ),
        .we     (wb_rf_we     ),
        .waddr  (wb_rf_waddr  ),
        .wdata  (wb_rf_wdata  )
    );
    
    // Ñ¡Ôñ×îÐÂµÄÊý¾Ý½øÐÐ´¦Àí
    assign ndata1 = ((ex_rf_we && rs == ex_rf_waddr) ? ex_rf_wdata : 32'b0) | 
                    ((!(ex_rf_we && rs == ex_rf_waddr) && (mem_rf_we && rs == mem_rf_waddr)) ? mem_rf_wdata : 32'b0) |
                    ((!(ex_rf_we && rs == ex_rf_waddr) && !(mem_rf_we && rs == mem_rf_waddr) && (wb_rf_we && rs == wb_rf_waddr)) ? wb_rf_wdata : 32'b0) |
                    (((ex_rf_we && rs == ex_rf_waddr) || (mem_rf_we && rs == mem_rf_waddr) || (wb_rf_we && rs == wb_rf_waddr)) ? 32'b0 : rdata1);
    assign ndata2 = ((ex_rf_we && rt == ex_rf_waddr) ? ex_rf_wdata : 32'b0) | 
                    ((!(ex_rf_we && rt == ex_rf_waddr) && (mem_rf_we && rt == mem_rf_waddr)) ? mem_rf_wdata : 32'b0) |
                    ((!(ex_rf_we && rt == ex_rf_waddr) && !(mem_rf_we && rt == mem_rf_waddr) && (wb_rf_we && rt == wb_rf_waddr)) ? wb_rf_wdata : 32'b0) |
                    (((ex_rf_we && rt == ex_rf_waddr) || (mem_rf_we && rt == mem_rf_waddr) || (wb_rf_we && rt == wb_rf_waddr)) ? 32'b0 : rdata2);
    
    assign opcode = inst[31:26];
    assign rs = inst[25:21];
    assign rt = inst[20:16];
    assign rd = inst[15:11];
    assign sa = inst[10:6];
    assign func = inst[5:0];
    assign imm = inst[15:0];
    assign instr_index = inst[25:0];
    assign code = inst[25:6];
    assign base = inst[25:21];
    assign offset = inst[15:0];
    assign sel = inst[2:0];

    wire inst_ori, inst_lui, inst_addiu, inst_beq, 
          inst_subu, inst_jal, inst_jr, inst_addu, 
          inst_sll, inst_or, inst_lw, inst_sw, inst_bne, 
          inst_xor, inst_sltu, inst_slt,inst_slti,
          inst_sltiu, inst_j;

    wire op_add, op_sub, op_slt, op_sltu;
    wire op_and, op_nor, op_or, op_xor;
    wire op_sll, op_srl, op_sra, op_lui;

    decoder_6_64 u0_decoder_6_64(
    	.in  (opcode  ),
        .out (op_d )
    );

    decoder_6_64 u1_decoder_6_64(
    	.in  (func  ),
        .out (func_d )
    );
    
    decoder_5_32 u0_decoder_5_32(
    	.in  (rs  ),
        .out (rs_d )
    );

    decoder_5_32 u1_decoder_5_32(
    	.in  (rt  ),
        .out (rt_d )
    );
    
    //ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ä´ï¿½ï¿½ï¿½ï¿½ï¿½Öµrd
    decoder_5_32 u2_decoder_5_32(
        .in  (rd),
        .out (rd_d)
    );
    //ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ä´ï¿½ï¿½ï¿½ï¿½ï¿½Öµsa
    decoder_5_32 u3_decoder_5_32(
        .in  (sa),
        .out (sa_d)
    );
    
    assign inst_ori     = op_d[6'b00_1101];
    assign inst_lui     = op_d[6'b00_1111];
    assign inst_addiu   = op_d[6'b00_1001];
    assign inst_beq     = op_d[6'b00_0100];
    assign inst_subu    = op_d[6'b00_0000] & func_d[6'b10_0011];
    assign inst_jal     = op_d[6'b00_0011];
    assign inst_jr      = op_d[6'b00_0000] & func_d[6'b00_1000] & rt_d[5'b0_0000] & rd_d[5'b0_0000] & sa_d[5'b0_0000];
    assign inst_addu    = op_d[6'b00_0000] & func_d[6'b10_0001];
    assign inst_sll     = op_d[6'b00_0000] & func_d[6'b00_0000];
    assign inst_or      = op_d[6'b00_0000] & func_d[6'b10_0101];
    assign inst_lw      = op_d[6'b10_0011];
    assign inst_sw      = op_d[6'b10_1011];
    assign inst_bne     = op_d[6'b00_0101];
    assign inst_xor     = op_d[6'b00_0000] & func_d[6'b10_0110];
    assign inst_sltu    = op_d[6'b00_0000] & func_d[6'b10_1011];
    assign inst_slt     = op_d[6'b00_0000] & func_d[6'b10_1010];
    assign inst_slti    = op_d[6'b00_1010];
    assign inst_sltiu   = op_d[6'b00_1011];
    assign inst_j       = op_d[6'b00_0010];
    
    // rs to reg1
    assign sel_alu_src1[0] = inst_ori | inst_addiu | inst_subu | inst_jr | inst_addu | inst_or | inst_lw | inst_sw | inst_xor | inst_sltu | inst_slt | inst_slti | inst_sltiu;

    // pc to reg1
    assign sel_alu_src1[1] = inst_jal;

    // sa_zero_extend to reg1
    assign sel_alu_src1[2] = inst_sll;

    
    // rt to reg2
    assign sel_alu_src2[0] = inst_subu | inst_addu | inst_sll | inst_or | inst_xor | inst_sltu | inst_slt;
    
    // imm_sign_extend to reg2
    assign sel_alu_src2[1] = inst_lui | inst_addiu | inst_lw | inst_sw | inst_slti | inst_sltiu;

    // 32'b8 to reg2
    assign sel_alu_src2[2] = inst_jal;

    // imm_zero_extend to reg2
    assign sel_alu_src2[3] = inst_ori;



    assign op_add = inst_addiu | inst_jal | inst_addu | inst_lw | inst_sw;
    assign op_sub = inst_subu;
    assign op_slt = inst_slt | inst_slti;
    assign op_sltu = inst_sltu | inst_sltiu;
    assign op_and = 1'b0;
    assign op_nor = 1'b0;
    assign op_or = inst_ori | inst_or;
    assign op_xor = inst_xor;
    assign op_sll = inst_sll;
    assign op_srl = 1'b0;
    assign op_sra = 1'b0;
    assign op_lui = inst_lui;

    assign alu_op = {op_add, op_sub, op_slt, op_sltu,
                     op_and, op_nor, op_or, op_xor,
                     op_sll, op_srl, op_sra, op_lui};



    // load and store enable
    assign data_ram_en = inst_lw | inst_sw;

    // write enable
    assign data_ram_wen = inst_sw ? 4'b1111 : 4'b0000;



    // regfile store enable
    assign rf_we = inst_ori | inst_lui | inst_addiu | inst_subu | inst_jal | inst_jr | inst_addu | inst_sll | inst_or | inst_lw | inst_xor | inst_sltu | inst_slt | inst_slti | inst_sltiu;



    // store in [rd]
    assign sel_rf_dst[0] = inst_subu | inst_addu | inst_sll | inst_or | inst_xor | inst_sltu | inst_slt;
    // store in [rt] 
    assign sel_rf_dst[1] = inst_ori | inst_lui | inst_addiu | inst_lw | inst_slti | inst_sltiu;
    // store in [31]
    assign sel_rf_dst[2] = inst_jal;

    // sel for regfile address
    assign rf_waddr = {5{sel_rf_dst[0]}} & rd 
                    | {5{sel_rf_dst[1]}} & rt
                    | {5{sel_rf_dst[2]}} & 32'd31;

    // 0 from alu_res ; 1 from ld_res
    assign sel_rf_res = inst_lw ? 1'b1 : 1'b0; 

    assign id_to_ex_bus = {
        id_pc,          // 158:127
        inst,           // 126:95
        alu_op,         // 94:83
        sel_alu_src1,   // 82:80
        sel_alu_src2,   // 79:76
        data_ram_en,    // 75
        data_ram_wen,   // 74:71
        rf_we,          // 70
        rf_waddr,       // 69:65
        sel_rf_res,     // 64
        ndata1,         // 63:32  ï¿½ï¿½ï¿½Âµï¿½ï¿½ï¿½ï¿½ï¿½1
        ndata2          // 31:0  ï¿½ï¿½ï¿½Âµï¿½ï¿½ï¿½ï¿½ï¿½2
    };


    wire br_e;
    wire [31:0] br_addr;
    wire rs_eq_rt;
    wire rs_ge_z;
    wire rs_gt_z;
    wire rs_le_z;
    wire rs_lt_z;
    wire [31:0] pc_plus_4;
    assign pc_plus_4 = id_pc + 32'h4;

    assign rs_eq_rt = (ndata1 == ndata2);

    assign br_e = (inst_beq & rs_eq_rt) | inst_jal | inst_jr | (inst_bne & ~rs_eq_rt) | inst_j;
    
    assign br_addr = inst_beq ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) :
                     inst_jal ? ({pc_plus_4[31:28], instr_index, 2'b0}) :
                     inst_jr  ? ndata1 : 
                     inst_bne ? (pc_plus_4 + {{14{inst[15]}}, inst[15:0], 2'b0}) : 
                     inst_j   ? ({pc_plus_4[31:28], instr_index, 2'b0}) : 
                     32'b0;
    
    // ½«LoadÖ¸ÁîÀàÐÍÐÅºÅ´ò°ü´«µÝµ½EX½×¶Î
    assign id_load_bus = {
        inst_lw
    };
    
    assign id_save_bus = {
        inst_sw
    };
    
    assign br_bus = {
        br_e,
        br_addr
    };
    
    assign stallreq_for_bru = (ex_id & (ex_rf_we & (rs == ex_rf_waddr | rt == ex_rf_waddr))) ? `Stop : `NoStop;

endmodule