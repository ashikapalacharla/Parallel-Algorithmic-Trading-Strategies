// Ashika Palacharla
// EE478
// Parallel Architecture for Low-Latency Multi-Strategy Trading Execution

// market_data
// Extracts price data and produces running sums, to be used by individual trading strategies

module market_data
  ( input               clk_i     // input clock
  , input               reset_i   // input reset

    // Market data inputs
  , input        [31:0] price_i    // 32 bit price
  , input        [31:0] volume_i   // 32 bit volume
  , input               v_i       // valid input data

  , input logic arbiter_v
  , input logic [1:0] arbiter_decision
  
  , output              ready_o   // ready for new input data
  , output logic [1:0]  decision_o
  , output logic        v_o       // valid output data

  , input               yumi_i    // valid/ready handshake acknowledgement

  // Computed outputs, to trading strategies
  // Momentum 
  , output logic [31:0] prev_price_o
  , output logic [31:0] curr_price_o

    // Moving Average
  , output logic [33:0] rolling_sum_o // sum of prices
  , output logic        window_full_o //flags when count is 4

    // VWAP
  , output logic [63:0] rolling_product_o // weighted price product, price*vol
  , output logic [63:0] rolling_vol_o

  );


  // FSM State Declaration
  typedef enum logic [1:0] {eWAIT, eBUSY, eDONE} state_e;
  state_e  state_n, state_r; // next, current state


  // Internal Registers
  logic [31:0] prev_price_r, curr_price_r;

  // Used for moving average
  logic [33:0] rolling_sum_r;
  logic [31:0] window_r [0:3];
  logic window_full; //flag when average window is filled with 4 prices initially
  logic [2:0]  count_r; //count prices going into average window

  // Used for VWAP
  logic [63:0] rolling_product_r, rolling_vol_r;

  // All strategy valids and decisions
  logic mom_v, avg_v, vwap_v, arbiter_v;
  logic [1:0] mom_decision, avg_decision, vwap_decision, arbiter_decision;

  logic Done; // high when at least one strategy has been validated


  // Output Assignment
  assign ready_o = (state_r == eWAIT); // ready for new data when in eWAIT
  assign v_o = (state_r == eDONE); // valid output data when operation in eDONE
  
  assign prev_price_o      = prev_price_r;
  assign curr_price_o      = curr_price_r;

  assign rolling_sum_o     = rolling_sum_r;
  assign window_full_o     = (count_r >= 4); // when count is 4, sma window is filled

  assign rolling_product_o = rolling_product_r;
  assign rolling_vol_o     = rolling_vol_r;


  // FSM to manage BSG link signals and internal state for strategies
  always_comb begin
    case(state_r)
      // WAIT state
      eWAIT: begin
        // Go to BUSY when ready for valid input data
        if (ready_o & v_i) begin
          state_n = eBUSY;
        end else begin
        // Otherwise, stay in current WAIT state
          state_n = eWAIT;
        end
      end
      // BUSY state
      eBUSY: begin
        // Stay in BUSY if still computing
        if (!Done) begin
          state_n = eBUSY;
        // Go to DONE when GCD computation is complete
        end else begin
          state_n = eDONE;
        end
      end
      // DONE state
      eDONE: begin
        // Go to wait when valid output data has been received
        if(v_o & yumi_i) begin
          state_n = eWAIT;
        // Stay in DONE to keep trying to send valid output (waiting for handshake)
        end else begin
          // Otherwise, stay in current DONE state
          state_n = eDONE;
        end
      end
      // Default go to WAIT state
      default: state_n = eWAIT;
    endcase
  end

  // State register
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      state_r <= eWAIT;   // Reset goes to WAIT
    end else begin
      state_r <= state_n; // Otherwise update to next state
    end
  end

  // Update outputs to trading strategies based on FSM state
  always_ff @(posedge clk_i) begin
    // Reset all values during eWAIT
    if (reset_i) begin
      prev_price_r <= 32'b0;
      curr_price_r <= 32'b0;

      rolling_sum_r <= 34'b0;
      count_r <= 3'b0; //reset count to 0

      rolling_product_r <= 64'b0; 
      rolling_vol_r     <= 64'b0; 

      // set all 4 prices in the average window to 0's
      window_r[0] <= 32'b0;
      window_r[1] <= 32'b0;
      window_r[2] <= 32'b0;
      window_r[3] <= 32'b0;

      decision_o <= 2'b11;
      Done <= 1'b0;
      
    end else begin
      // Valid market data input
      if (state_r == eWAIT && v_i) begin
        // Register the previous price and current price
        prev_price_r <= curr_price_r;
        curr_price_r <= price_i; // update with input price

        // Moving avg outputs
        if (count_r < 4) begin
          // Window is getting initially filled
          window_r[count_r] <= price_i; // fill up next index of window with new price input
          rolling_sum_r   <= rolling_sum_r + price_i; // add the new price to the rolling sum
          count_r         <= count_r + 1'b1; // update counter and index of window fill

        // Window is full
        end else begin
          // Shift in the new price 
          window_r[0] <= window_r[1];
          window_r[1] <= window_r[2];
          window_r[2] <= window_r[3];
          window_r[3] <= price_i; //update with newest price input

          // Update rolling sums
          rolling_sum_r <= rolling_sum_r - window_r[0] + price_i; // subtract oldest, add in newest
        end

        // VWAP outputs
        rolling_product_r <= rolling_product_r + (price_i * volume_i); // add new weighted price, price*vol
        rolling_vol_r     <= rolling_vol_r + volume_i;
        
        Done <= 1'b0; //false, nobody has done a comparison to start

      end else if (state_r == eBUSY) begin
        if (arbiter_v) begin
          decision_o <= arbiter_decision;
          Done <= arbiter_v;
        end

      // In eDONE state, set Done directly
      end else begin 
      Done <= 1'b1; // GCD found
    end

    end
  end

endmodule