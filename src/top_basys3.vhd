library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


-- Lab 4
entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(15 downto 0);
        btnU    :   in std_logic; -- master_reset
        btnL    :   in std_logic; -- clk_reset
        btnR    :   in std_logic; -- fsm_reset
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is

    -- signal declarations
    signal w_fsm_reset    : std_logic;
    signal w_fsm_out1     : std_logic_vector (3 downto 0);
    signal w_fsm_out2     : std_logic_vector (3 downto 0);
    signal w_slowclk      : std_logic;
    
    signal w_tdm4_reset   : std_logic;
    signal w_tdm4_out     : std_logic_vector (3 downto 0);
    
    signal w_data1        : std_logic_vector (3 downto 0); --F
    signal w_data3        : std_logic_vector (3 downto 0); --F
    
    -- testing
    signal w_an : std_logic_vector(3 downto 0);

    
    
  
	-- component declarations
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
    component elevator_controller_fsm is
		Port (
            i_clk        : in  STD_LOGIC;
            i_reset      : in  STD_LOGIC;
            is_stopped   : in  STD_LOGIC;
            go_up_down   : in  STD_LOGIC;
            o_floor : out STD_LOGIC_VECTOR (3 downto 0)		   
		 );
	end component elevator_controller_fsm;
	
	component TDM4 is
		generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	   );
    end component TDM4;
     
	component clock_divider is
        generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
	
begin
	-- PORT MAPS ----------------------------------------
	    clkdiv_inst : clock_divider 		--instantiation of clock_divider to take 
            generic map ( k_DIV => 850000 ) -- 60 Hz clock from 100 MHz
            port map (						  
                i_clk   => clk,
                i_reset => btnL,
                o_clk   => w_slowclk
            ); 
        sevenseg_unit : sevenseg_decoder
            port map (
                i_Hex       => w_tdm4_out,
                o_seg_n(0) => seg(0),
                o_seg_n(1) => seg(1),
                o_seg_n(2) => seg(2),
                o_seg_n(3) => seg(3),
                o_seg_n(4) => seg(4),
                o_seg_n(5) => seg(5),
                o_seg_n(6) => seg(6)
            );
        
        elevator_unit : elevator_controller_fsm
            port map (
                i_clk       => w_slowclk,        
                i_reset     => w_fsm_reset,
                is_stopped  => sw(0),
                go_up_down  => sw(1), 
                o_floor 	=> w_fsm_out1
            );
            
        elevator2_unit : elevator_controller_fsm
            port map (
                i_clk       => w_slowclk,        
                i_reset     => w_fsm_reset,
                is_stopped  => sw(15),
                go_up_down  => sw(14), 
                o_floor 	=> w_fsm_out2
            );
        
        tdm4_unit : TDM4
            port map (
                i_clk       => w_slowclk,
                i_reset		=> w_tdm4_reset,
                i_D3 		=> w_data3,
		        i_D2 		=> w_fsm_out1,
		        i_D1 		=> w_data1,
		        i_D0 		=> w_fsm_out2,
		        o_data		=> w_tdm4_out,
		        o_sel		=> w_an
	        );
	        
	    
            
           
	
	-- CONCURRENT STATEMENTS ----------------------------
	-- placeholders for elevators / F display
	--w_data0      <= "0000";
	w_data1      <= x"F";
	w_data3      <= x"F";
	-- LED 15 gets the FSM slow clock signal. The rest are grounded.
	led(15) <= w_slowclk;
	-- leave unused switches UNCONNECTED. Ignore any warnings this causes.
	led(3 downto 0) <= w_tdm4_out;
	
	an <= w_an;           -- drive the 7-seg anode lines
    led(9 downto 6) <= not w_an;  -- invert for visual clarity (0 = ON)

	-- reset signals
	w_fsm_reset  <= btnR or btnU;
	w_tdm4_reset <= btnL or btnU;
	
	
end top_basys3_arch;
