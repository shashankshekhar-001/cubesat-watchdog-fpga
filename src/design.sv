// ============================================
// CubeSat Hardware Watchdog & Health Monitor
// FPGA-Based Fault Detection & Recovery FSM
// Author: Shashank Shekhar Barnwal
// B.Tech ECE - Central University of Jammu
// ============================================

module watchdog_fsm(
    input clk,
    input rst,
    input heartbeat,
    input [1:0] subsys_id,        // which subsystem (0,1,2)
    output reg fault_led,
    output reg reset_out,
    output reg [2:0] current_state
);

// 5 FSM States
parameter IDLE           = 3'b000;
parameter MONITORING     = 3'b001;
parameter FAULT_DETECTED = 3'b010;
parameter RECOVERY       = 3'b011;
parameter RESUME         = 3'b100;

reg [2:0] next_state;
reg [3:0] timeout_counter;

// State register
always @(posedge clk or posedge rst) begin
    if (rst) current_state <= IDLE;
    else     current_state <= next_state;
end

// Next state logic
always @(*) begin
    case(current_state)
        IDLE:           next_state = MONITORING;
        MONITORING:     next_state = (timeout_counter >= 4'd8) ?
                                      FAULT_DETECTED : MONITORING;
        FAULT_DETECTED: next_state = RECOVERY;
        RECOVERY:       next_state = RESUME;
        RESUME:         next_state = MONITORING;
        default:        next_state = IDLE;
    endcase
end

// Timeout counter
always @(posedge clk or posedge rst) begin
    if (rst)           timeout_counter <= 0;
    else if (heartbeat) timeout_counter <= 0;
    else               timeout_counter <= timeout_counter + 1;
end

// Output logic
always @(*) begin
    fault_led  = (current_state == FAULT_DETECTED ||
                  current_state == RECOVERY);
    reset_out  = (current_state == RECOVERY);
end

endmodule


// ============================================
// TOP MODULE — 3 Subsystem Health Monitor
// ============================================

module cubesat_health_monitor(
    input clk,
    input rst,
    input hb_power,       // heartbeat from Power subsystem
    input hb_comms,       // heartbeat from Comms subsystem
    input hb_sensor,      // heartbeat from Sensor subsystem
    output fault_power,
    output fault_comms,
    output fault_sensor,
    output reset_power,
    output reset_comms,
    output reset_sensor,
    output [2:0] state_power,
    output [2:0] state_comms,
    output [2:0] state_sensor
);

// Instantiate 3 independent watchdogs
watchdog_fsm wd_power (
    .clk(clk), .rst(rst),
    .heartbeat(hb_power),
    .subsys_id(2'b00),
    .fault_led(fault_power),
    .reset_out(reset_power),
    .current_state(state_power)
);

watchdog_fsm wd_comms (
    .clk(clk), .rst(rst),
    .heartbeat(hb_comms),
    .subsys_id(2'b01),
    .fault_led(fault_comms),
    .reset_out(reset_comms),
    .current_state(state_comms)
);

watchdog_fsm wd_sensor (
    .clk(clk), .rst(rst),
    .heartbeat(hb_sensor),
    .subsys_id(2'b10),
    .fault_led(fault_sensor),
    .reset_out(reset_sensor),
    .current_state(state_sensor)
);

endmodule