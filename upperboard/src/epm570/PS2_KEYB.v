module PS2_KEYB(
	input 	[15:8]	 a,
	input 		res_n,
	input 		clk,
	input 		kbd_clk,
	input 		kbd_dat,
	output	[4:0]	key_row   //выход сигналов КВ0...4 на порт FE компьютера

);

///// KEYBOARD MODULE -----------------------------------------
reg [3:0] bitcount; // we need 11 bit to get scancode: start + 8bit + parity + stop
reg scancode_ready;
reg [7:0] scancode;	// scancode data
reg parity;

///// PS2 part ----------------

// 'keyboard clock' negative edge detection using 'clk'
reg kbd_clk_prev;
reg [3:0] clk_filter;
reg clk_edge;
always @(posedge clk or negedge res_n)
    if (!res_n)
    begin
        kbd_clk_prev <= 1;
        clk_filter <= 4'b1111;
        clk_edge <= 0;
    end
    else
    begin
        // Filter in a new keyboard clock sample
        clk_filter <= { kbd_clk, clk_filter[3:1] };
        clk_edge <= 0;
        if (clk_filter==4'b1111)
            kbd_clk_prev <= 1;
        else if (clk_filter==4'd0)
        begin
            // Filter clock is low, check for edge
            if (kbd_clk_prev==1) clk_edge <= 1;
            kbd_clk_prev <= 0;
        end
    end


/// read scancode from keyboard
always @(posedge clk or negedge res_n)
    if( !res_n )
    begin
        bitcount <= 4'd0;
        scancode_ready <= 0;
    end
    else
    begin
        scancode_ready <= 0;
        if (clk_edge==1)
		begin
			case(bitcount)
				0: if(kbd_dat == 0) bitcount <= 4'd1; // start bit
				1: scancode[0] <= kbd_dat;
				2: scancode[1] <= kbd_dat;
				3: scancode[2] <= kbd_dat;
				4: scancode[3] <= kbd_dat;
				5: scancode[4] <= kbd_dat;
				6: scancode[5] <= kbd_dat;
				7: scancode[6] <= kbd_dat;
				8: scancode[7] <= kbd_dat;
				9: parity <= kbd_dat;		// parity_bit
				10: scancode_ready <= kbd_dat & (^scancode ^ parity);	// stop_bit
			endcase
			if(bitcount < 10)
				bitcount <= bitcount + 4'd1;
			else if (bitcount == 10)
				bitcount <= 4'd0;
		end
	end
///// END PS2 part ------------



reg [4:0] keys [0:7];		// 8 rows of 5 bits each: contains 0 for a pressed key at a specific location, 1 otherwise
reg released;               // Tracks "released" scan code (F0): contains 0 when a key is pressed, 1 otherwise
reg extended;               // Tracks "extended" scan code (E0)
reg shifted;                // Tracks local "shifted" state

// Output requested row of keys continously
assign key_row = 
    (a[8]  ? 5'b11111 : keys[0]) &
    (a[9]  ? 5'b11111 : keys[1]) &
    (a[10] ? 5'b11111 : keys[2]) &
    (a[11] ? 5'b11111 : keys[3]) &
    (a[12] ? 5'b11111 : keys[4]) &
    (a[13] ? 5'b11111 : keys[5]) &
    (a[14] ? 5'b11111 : keys[6]) &
    (a[15] ? 5'b11111 : keys[7]);


always @(posedge clk or negedge res_n)
    if ( !res_n )
    begin
        released <= 0;
        extended <= 0;
        shifted  <= 0;
        begin
			integer i;
			for( i = 0; i < 8; i = i + 1 ) 
				keys[i] <= 5'b11111;
		end
    end
    else if( scancode_ready )
    begin
        if( scancode == 8'hE0 ) // Extended code prefix byte
            extended <= 1;
        else if( scancode == 8'hF0 ) // Break code prefix byte
            released <= 1;
        else
        begin
            // Cancel release/extended flags for the next clock
            extended <= 0;
            released <= 0;
			
            if (extended) // Extended keys         
                case( scancode )
                    8'h14:  keys[0][0] <= released;     // CAPS SHIFT = Right Ctrl
                    8'h11:  keys[7][1] <= released;     // SYMBOL SHIFT = Right Alt

                    8'h6B:  begin                       // LEFT
                            keys[0][0] <= released;     // CAPS SHIFT
                            keys[3][4] <= released;     // 5
                            end
                    8'h72:  begin                       // DOWN
                            keys[0][0] <= released;     // CAPS SHIFT
                            keys[4][4] <= released;     // 6
                            end
                    8'h75:  begin                       // UP
                            keys[0][0] <= released;     // CAPS SHIFT
                            keys[4][3] <= released;     // 7
                            end
                    8'h74:  begin                       // RIGHT
                            keys[0][0] <= released;     // CAPS SHIFT
                            keys[4][2] <= released;     // 8
                            end
                endcase
            else
				// For each PS/2 scan-code, set the ZX keyboard matrix state
				case( scancode )
					8'h12:  shifted <= !released;       // Local SHIFT key (left)
					8'h59:  shifted <= !released;       // Local SHIFT key (right)

					8'h14:  keys[0][0] <= released;     // CAPS SHIFT = Left Ctrl
					8'h11:  keys[7][1] <= released;     // SYMBOL SHIFT = Left Alt

                    8'h58:	begin						// CAPS LOCK
                            keys[0][0] <= released;     // CAPS SHIFT
                            keys[3][1] <= released;     // 2
							end

					8'h1A:  keys[0][1] <= released;     // Z
					8'h22:  keys[0][2] <= released;     // X
					8'h21:  keys[0][3] <= released;     // C
					8'h2A:  keys[0][4] <= released;     // V

                    8'h1C:  keys[1][0] <= released;     // A
                    8'h1B:  keys[1][1] <= released;     // S
                    8'h23:  keys[1][2] <= released;     // D
                    8'h2B:  keys[1][3] <= released;     // F
                    8'h34:  keys[1][4] <= released;     // G

                    8'h15:  keys[2][0] <= released;     // Q
                    8'h1D:  keys[2][1] <= released;     // W
                    8'h24:  keys[2][2] <= released;     // E
                    8'h2D:  keys[2][3] <= released;     // R
                    8'h2C:  keys[2][4] <= released;     // T

                    8'h16:  keys[3][0] <= released;     // 1
                    8'h1E:  keys[3][1] <= released;     // 2
                    8'h26:  keys[3][2] <= released;     // 3
                    8'h25:  keys[3][3] <= released;     // 4
                    8'h2E:  keys[3][4] <= released;     // 5

                    8'h45:  keys[4][0] <= released;     // 0
                    8'h46:  keys[4][1] <= released;     // 9
                    8'h3E:  keys[4][2] <= released;     // 8
                    8'h3D:  keys[4][3] <= released;     // 7
                    8'h36:  keys[4][4] <= released;     // 6

                    8'h4D:  keys[5][0] <= released;     // P
                    8'h44:  keys[5][1] <= released;     // O
                    8'h43:  keys[5][2] <= released;     // I
                    8'h3C:  keys[5][3] <= released;     // U
                    8'h35:  keys[5][4] <= released;     // Y

                    8'h5A:  keys[6][0] <= released;     // ENTER
                    8'h4B:  keys[6][1] <= released;     // L
                    8'h42:  keys[6][2] <= released;     // K
                    8'h3B:  keys[6][3] <= released;     // J
                    8'h33:  keys[6][4] <= released;     // H

                    8'h29:  keys[7][0] <= released;     // SPACE
                    8'h3A:  keys[7][2] <= released;     // M
                    8'h31:  keys[7][3] <= released;     // N
                    8'h32:  keys[7][4] <= released;     // B

                    8'h66:  begin                       // BACKSPACE
                            keys[0][0] <= released;
                            keys[4][0] <= released;
                            end
                    8'h76:  begin                       // ESC -> BREAK
                            keys[0][0] <= released;     // CAPS SHIFT
                            keys[7][0] <= released;     // SPACE
                            end
                    // With shifted keys, we need to make inactive (set to 1) other corresponding key
                    // Otherwise, it will stay active if the shift was released first
                    8'h4E:  begin                       // - or (shifted) _
                            keys[7][1] <= released;     // SYMBOL SHIFT (Red)
                            keys[4][0] <= shifted ? released : 1'b1;     // 0
                            keys[6][3] <= shifted ? 1'b1 : released;     // J
                            end
                    8'h55:  begin                       // = or (shifted) +
                            keys[7][1] <= released;     // SYMBOL SHIFT (Red)
                            keys[6][2] <= shifted ? released : 1'b1;     // K
                            keys[6][1] <= shifted ? 1'b1 : released;     // L
                            end
                    8'h52:  begin                       // ' or (shifted) "
                            keys[7][1] <= released;     // SYMBOL SHIFT (Red)
                            keys[5][0] <= shifted ? released : 1'b1;     // P
                            keys[4][3] <= shifted ? 1'b1 : released;     // 7
                            end
                    8'h4C:  begin                       // ; or (shifted) :
                            keys[7][1] <= released;     // SYMBOL SHIFT (Red)
                            keys[0][1] <= shifted ? released : 1'b1;     // Z
                            keys[5][1] <= shifted ? 1'b1 : released;     // O
                            end
                    8'h41:  begin                       // , or (shifted) <
                            keys[7][1] <= released;     // SYMBOL SHIFT (Red)
                            keys[2][3] <= shifted ? released : 1'b1;     // R
                            keys[7][3] <= shifted ? 1'b1 : released;     // N
                            end
                    8'h49:  begin                       // . or (shifted) >
                            keys[7][1] <= released;     // SYMBOL SHIFT (Red)
                            keys[2][4] <= shifted ? released : 1'b1;     // T
                            keys[7][2] <= shifted ? 1'b1 : released;     // M
                            end
                    8'h4A:  begin                       // / or (shifted) ?
                            keys[7][1] <= released;     // SYMBOL SHIFT (Red)
                            keys[0][3] <= shifted ? released : 1'b1;     // C
                            keys[0][4] <= shifted ? 1'b1 : released;     // V
                            end
                endcase
        end
    end


///// END KEYBOARD MODULE -------------------------------------

endmodule