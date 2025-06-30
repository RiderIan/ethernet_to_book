task init_reset (
    ref logic rst);
    begin
        rst = 1'b1;
        #20;
        rst = 1'b0;
    end
endtask

task wait_lock (
    ref logic lock0,
    ref logic lock1);
    begin
        wait(lock0 == 1'b1 && lock1 == 1'b1);
    end
endtask

// task tx_rgmii_data (
//     input  logic [7:0] byte,
//     input  logic clk,
//     output logic [3:0] data,
//     output logic       ctrl);
//     begin
// 
//         @(posedge clk);
//         data = byte[7:4];
//         ctrl = 1'b1;
//         @(negedge clk);
//         data = byte[3:0];
// 
// 
//     end
// endtask
