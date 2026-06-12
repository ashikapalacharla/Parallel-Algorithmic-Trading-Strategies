// Ashika Palacharla
// EE478
// Parallel Architecture for Low-Latency Multi-Strategy Trading Execution

// vwap
// Volume Weighted Average Price trading strategy, weighs the trade based on the volume of the request
// 		Produces a BUY=2'b01 if current weight is greater than cumulative vwap
// 		Produces a SELL=2'b10 if current weight is less than cumulative vwap
// 		Produces a HOLD=2'b00 otherwise

module vwap
  (
	// Market data inputs
    input logic [31:0] curr_price_i
  , input logic [63:0] rolling_product_i // weighted price product, price*vol
  , input logic [63:0] rolling_vol_i

	// Strategy outputs
  , output logic [1:0] decision_o // 00=HOLD, 01=BUY, 10=SELL
  , output logic v_o
  
  );

  // Internal register
  logic [63:0] current_weight;


  always_comb begin
    // Wait until actual data is received
    if (rolling_vol_i != 0) begin
      v_o      		<= 1'b1; 
      // Current weight based on cumulative volume and current price
      current_weight = curr_price_i * rolling_vol_i; // if buying the volume at the current price

      // Current weight is greater than average weight, so buy
      if (current_weight > rolling_product_i) begin
        decision_o <= 2'b01;

      // Current weight is less than average weight, so sell
      end else if (current_weight < rolling_product_i) begin 
        decision_o <= 2'b10;
        
      // Otherwise hold
      end else begin
        decision_o <= 2'b00;
      end

    // Otherwise, send invalid and hold
    end else begin // before window filled
      v_o <= 1'b0;
      decision_o <= 2'b00;
    end
  end

endmodule