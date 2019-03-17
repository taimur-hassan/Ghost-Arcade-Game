module top(KEY, SW, CLOCK_50, VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_R, VGA_G, VGA_B, PS2_CLK, PS2_DAT, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, AUD_ADCDAT, AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, FPGA_I2C_SDAT, AUD_XCK, AUD_DACDAT, FPGA_I2C_SCLK);

	input [3:0] KEY;
	input [9:0] SW;
	input CLOCK_50;
	output			VGA_CLK;  				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

	wire resetn;
	assign resetn = KEY[0];
	
	wire [8:0] colour;
	wire [7:0] x;
	wire [6:0] y;

	wire writeEn;

	input					AUD_ADCDAT;
	
	inout					AUD_BCLK;
	inout					AUD_ADCLRCK;
	inout					AUD_DACLRCK;

	inout					FPGA_I2C_SDAT;
	output				AUD_XCK;
	output				AUD_DACDAT;

	output				FPGA_I2C_SCLK;
	
	reg [3:0] sound;
	
	always @ (*) begin
		if (move_up == 1)
			sound <= 4'b0010;
		else
			sound <= 4'b0000;
	end
	
	DE1_SoC_Audio_Example a0(
		.CLOCK_50(CLOCK_50),
		.KEY(KEY[3:0]),
		.AUD_ADCDAT(AUD_ADCDAT),
		.AUD_BCLK(AUD_BCLK),
		.AUD_ADCLRCK(AUD_ADCLRCK),
		.AUD_DACLRCK(AUD_DACLRCK),
		.FPGA_I2C_SDAT(FPGA_I2C_SDAT),
		.AUD_XCK(AUD_XCK),
		.AUD_DACDAT(AUD_DACDAT),
		.FPGA_I2C_SCLK(FPGA_I2C_SCLK),
		.SW(sound)
	);


	inout PS2_CLK, PS2_DAT;
	wire send_command, command_was_sent, error_communication_timed_out, received_data_en;
	wire [7:0] the_command, received_data;
		
	PS2_Controller ps2 (
		.CLOCK_50(CLOCK_50),
		.reset(key_reset),

		.the_command(the_command),
		.send_command(send_command),

		.PS2_CLK(PS2_CLK), 
		.PS2_DAT(PS2_DAT), 

		.command_was_sent(command_was_sent),
		.error_communication_timed_out(error_communication_timed_out),

	as	
		.received_data(received_data),
		.received_data_en(received_data_en)
	);	
	
	reg key_right, key_left, key_up, key_down, key_right2, key_left2, key_up2, key_down2;

	always @ (posedge CLOCK_50) begin
		
		if (received_data == 8'h5A) begin
			key_right <= 0;
			key_left <= 0;
			key_up <= 0;
			key_down <= 0;
			key_right2 <= 0;
			key_left2 <= 0;
			key_up2 <= 0;
			key_down2 <= 0;
		end
		
		
		if (received_data == 8'hE074) begin
			key_right <= 1;
			key_left <= 0;
			key_up <= 0;
			key_down <= 0;
		end
		else if (received_data == 8'hE06B) begin
			key_right <= 0;
			key_left <= 1;
			key_up <= 0;
			key_down <= 0;
		end
		else if (received_data == 8'hE075) begin
			key_right <= 0;
			key_left <= 0;
			key_up <= 1;
			key_down <= 0;
		end
		else if (received_data == 8'hE072) begin
			key_right <= 0;
			key_left <= 0;
			key_up <= 0;
			key_down <= 1;
		end

		
		if (received_data == 8'h23) begin
			key_right2 <= 1;
			key_left2 <= 0;
			key_up2 <= 0;
			key_down2 <= 0;
		end
		else if (received_data == 8'H1C) begin
			key_right2 <= 0;
			key_left2 <= 1;
			key_up2 <= 0;
			key_down2 <= 0;
		end
		else if (received_data == 8'h1D) begin
			key_right2 <= 0;
			key_left2 <= 0;
			key_up2 <= 1;
			key_down2 <= 0;
		end
		else if (received_data == 8'h1B) begin
			key_right2 <= 0;
			key_left2 <= 0;
			key_up2 <= 0;
			key_down2 <= 1;
		end
		
	end	

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
			
		/* Signals for the DAC to drive the monitor. */	
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 3;
		defparam VGA.BACKGROUND_IMAGE = "main_menu.mif";

	assign writeEn = (counterdone | counterdone2 | counterdone3);
	// Put your code here. Your code should produce signals x,y,colour and writeEn
	// for the VGA controller, in addition to any other functionality your design may require.

	/*________________Feedback Wires From Datapath_____________________*/
	wire valid_feeback, ghost_done, ghost_done_2, erase_ghost_done, erase_ghost_done2, erase_ghost_done3, erase_ghost_done4, erase_ghost_done5, erase_ghost_done6, erase_ghost_done7, erase_ghost_done8, erase_ghost_done9, spirit_done, erase_spirit_done, endgame;
	
	wire [6:0] scorep1, scorep2;
	wire [6:0] gameclk;

	/*_________________________Control Wire___________________________*/
	wire move_right, move_left, move_up, move_down, move_right2, move_left2, move_up2, move_down2;
	wire start,	draw_ghost, draw_ghost_2, draw_spirit, rand_spirit, spirit_caught, draw_end;
	wire erase_ghost_right, erase_ghost_left, erase_ghost_up, erase_ghost_down, erase_ghost_right2, erase_ghost_left2, erase_ghost_up2, erase_ghost_down2;
	wire counterdone, counterdone2, counterdone3;
	//wire animate_map00, animate_map01, animate_map02, animate_map1, animate_map2, animate_map3, animate_map4, animate_maplast;

	seg7 clk1 (
		.hex_digit(gameclk % 10),
		.segments(HEX2)
	);
	
	seg7 clk2 (
		.hex_digit(gameclk / 10),
		.segments(HEX3)
	);	
	
	seg7 p1(
		.hex_digit(scorep1 % 10),
		.segments(HEX4)
	);
	
	seg7 p2 (
		.hex_digit(scorep1 / 10),
		.segments(HEX5)
	);
		
	seg7 p3(
		.hex_digit(scorep2 % 10),
		.segments(HEX0)
	);
	
	seg7 p4 (
		.hex_digit(scorep2 / 10),
		.segments(HEX1)
	);
	datapath d0(
	/*________Inputs____________*/
		.clk(CLOCK_50),
    	.resetn(resetn),
		.move_right(move_right2),
		.move_left(move_left2),
		.move_up(move_up2),
		.move_down(move_down2),
		.move_right2(move_right),
		.move_left2(move_left),
		.move_up2(move_up),
		.move_down2(move_down),
		.draw_ghost(draw_ghost),
		.draw_ghost_2(draw_ghost_2),
		.draw_spirit(draw_spirit),
		.rand_spirit(rand_spirit),
		.start(start),
		.erase_ghost_right(erase_ghost_right),
		.erase_ghost_left(erase_ghost_left),
		.erase_ghost_up(erase_ghost_up),
		.erase_ghost_down(erase_ghost_down),
		.erase_ghost_right2(erase_ghost_right2),
		.erase_ghost_left2(erase_ghost_left2),
		.erase_ghost_up2(erase_ghost_up2),
		.erase_ghost_down2(erase_ghost_down2),
		.spirit_caught(spirit_caught),
		.draw_end(draw_end),
//		.animate_map00(animate_map00),
//		.animate_map01(animate_map01),
//		.animate_map02(animate_map02),
//		.animate_map1(animate_map1),
//		.animate_map2(animate_map2),
//		.animate_map3(animate_map3),
//		.animate_map4(animate_map4),
//		.animate_maplast(animate_maplast),

  	/*__________Outputs____________*/	
		.valid(valid_feeback),
		.colour(colour),
		.xpos(x),
		.ypos(y),
		.ghost_done(ghost_done),
		.ghost_done_2(ghost_done_2),
		.spirit_done(spirit_done),
		.counterdone(counterdone),
		.counterdone2(counterdone2),
		.counterdone3(counterdone3),
		.erase_ghost_done(erase_ghost_done),
//		.erase_ghost_done2(erase_ghost_done2),
//		.erase_ghost_done3(erase_ghost_done3),
//		.erase_ghost_done4(erase_ghost_done4),
//		.erase_ghost_done5(erase_ghost_done5),
//		.erase_ghost_done6(erase_ghost_done6),
//		.erase_ghost_done7(erase_ghost_done7),
//		.erase_ghost_done8(erase_ghost_done8),
//		.erase_ghost_done9(erase_ghost_done9),
		.erase_spirit_done(erase_spirit_done),
		.scorep1(scorep1),
		.scorep2(scorep2),
		.gameclk(gameclk)
	);
	
	
	control c0(
		/*__________Inputs______________*/
		.clk(CLOCK_50),
		.resetn(resetn),
		.go_right(key_right),
		.go_left(key_left),
		.go_up(key_up),
		.go_down(key_down),
		.go_right2(key_right2),
		.go_left2(key_left2),
		.go_up2(key_up2),
		.go_down2(key_down2),
		.start_game(received_data == 8'h5A),
		.valid(valid_feeback),
		.ghost_done(ghost_done),
		.ghost_done_2(ghost_done_2),
		.spirit_done(spirit_done),
		.erase_ghost_done(erase_ghost_done),
//		.erase_ghost_done2(erase_ghost_done2),
//		.erase_ghost_done3(erase_ghost_done3),
//		.erase_ghost_done4(erase_ghost_done4),
//		.erase_ghost_done5(erase_ghost_done5),
//		.erase_ghost_done6(erase_ghost_done6),
//		.erase_ghost_done7(erase_ghost_done7),
//		.erase_ghost_done8(erase_ghost_done8),
//		.erase_ghost_done9(erase_ghost_done9),
		.erase_spirit_done(erase_spirit_done),
		.endgame(endgame),

		/*__________Outputs____________*/
		.move_right(move_right),
		.move_left(move_left),
		.move_up(move_up),
		.move_down(move_down),
		.move_right2(move_right2),
		.move_left2(move_left2),
		.move_up2(move_up2),
		.move_down2(move_down2),
		.draw_ghost(draw_ghost),
		.draw_ghost_2(draw_ghost_2),
		.draw_spirit(draw_spirit),
		.rand_spirit(rand_spirit),
		.start(start),
		.erase_ghost_right(erase_ghost_right),
		.erase_ghost_left(erase_ghost_left),
		.erase_ghost_up(erase_ghost_up),
		.erase_ghost_down(erase_ghost_down),
		.erase_ghost_right2(erase_ghost_right2),
		.erase_ghost_left2(erase_ghost_left2),
		.erase_ghost_up2(erase_ghost_up2),
		.erase_ghost_down2(erase_ghost_down2),
		.spirit_caught(spirit_caught),
		.draw_end(draw_end)
//		.animate_map00(animate_map00),
//		.animate_map01(animate_map01),
//		.animate_map02(animate_map02),
//		.animate_map1(animate_map1),
//		.animate_map2(animate_map2),
//		.animate_map3(animate_map3),
//		.animate_map4(animate_map4),
//		.animate_maplast(animate_maplast)
	);
endmodule
