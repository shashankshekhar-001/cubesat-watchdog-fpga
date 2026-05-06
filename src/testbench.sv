// ============================================================
// Testbench: CubeSat Health Monitor - 3 Subsystem Simulation
// Author   : Shashank Shekhar Barnwal
// Institute: Central University of Jammu
// Date     : May 2026
// Simulator: Icarus Verilog 12.0 on EDA Playground
// ============================================================

module cubesat_tb;

reg clk, rst;
reg hb_power, hb_comms, hb_sensor;

wire fault_power, fault_comms, fault_sensor;
wire reset_power, reset_comms, reset_sensor;
wire [2:0] state_power, state_comms, state_sensor;

// Instantiate top module
cubesat_health_monitor uut (
    .clk(clk), .rst(rst),
    .hb_power(hb_power),   .hb_comms(hb_comms),   .hb_sensor(hb_sensor),
    .fault_power(fault_power), .fault_comms(fault_comms), .fault_sensor(fault_sensor),
    .reset_power(reset_power), .reset_comms(reset_comms), .reset_sensor(reset_sensor),
    .state_power(state_power), .state_comms(state_comms), .state_sensor(state_sensor)
);

// 10ns clock period
always #5 clk = ~clk;

initial begin
    $dumpfile("dump.vcd");
    $dumpvars;

    clk=0; rst=1;
    hb_power=0; hb_comms=0; hb_sensor=0;
    #10 rst=0;

    // Phase 1: All 3 subsystems sending heartbeats normally
    $display("--- All subsystems ONLINE ---");
    repeat(6) begin
        hb_power=1; hb_comms=1; hb_sensor=1; #10;
        hb_power=0; hb_comms=0; hb_sensor=0; #10;
    end

    // Phase 2: Power subsystem freezes — heartbeat stops
    $display("--- POWER subsystem FROZEN ---");
    hb_power=0;
    repeat(6) begin
        hb_comms=1; hb_sensor=1; #10;
        hb_comms=0; hb_sensor=0; #10;
    end
    #40;

    // Phase 3: Comms subsystem also freezes
    $display("--- COMMS subsystem FROZEN ---");
    hb_comms=0;
    repeat(6) begin
        hb_sensor=1; #10;
        hb_sensor=0; #10;
    end
    #40;

    // Phase 4: All subsystems recover
    $display("--- All subsystems RECOVERING ---");
    repeat(3) begin
        hb_power=1; hb_comms=1; hb_sensor=1; #10;
        hb_power=0; hb_comms=0; hb_sensor=0; #10;
    end

    #60;
    $finish;
end

// UART Alert Monitor — Power Subsystem
always @(posedge clk) begin
    if (fault_power && !reset_power)
        $display("[ALERT] T=%0t | Subsystem POWER  : FAULT DETECTED", $time);
    if (reset_power)
        $display("[ALERT] T=%0t | Subsystem POWER  : RECOVERY INITIATED", $time);
end

// UART Alert Monitor — Comms Subsystem
always @(posedge clk) begin
    if (fault_comms && !reset_comms)
        $display("[ALERT] T=%0t | Subsystem COMMS  : FAULT DETECTED", $time);
    if (reset_comms)
        $display("[ALERT] T=%0t | Subsystem COMMS  : RECOVERY INITIATED", $time);
end

// UART Alert Monitor — Sensor Subsystem
always @(posedge clk) begin
    if (fault_sensor && !reset_sensor)
        $display("[ALERT] T=%0t | Subsystem SENSOR : FAULT DETECTED", $time);
    if (reset_sensor)
        $display("[ALERT] T=%0t | Subsystem SENSOR : RECOVERY INITIATED", $time);
end

endmodule