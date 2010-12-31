-- $Id: sineram_q16b.vhd,v 1.2 2009/12/31 03:14:41 jrothwei Exp $
-- Copyright 2009 Joseph Rothweiler
--------------------------------------------------------------------------------
-- Joseph Rothweiler, Sensicomm LLC. Started 30Dec2009.
-- Using Xilinx Spartan 3E  internal block RAM as a 1k words x 16 bits RAM.
-- RAM contents is a quarter-sine wave, scaled 0 to 65535.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity sineram_q16b is
    Port (
      clock1   : in  STD_LOGIC;
      addr1    : in  STD_LOGIC_VECTOR ( 9 downto 0);
      data1out : out STD_LOGIC_VECTOR (15 downto 0);
      --
      clock2   : in  STD_LOGIC;
      addr2    : in  STD_LOGIC_VECTOR ( 9 downto 0);
      data2out : out STD_LOGIC_VECTOR (15 downto 0)
    );
end sineram_q16b ;

architecture Behavioral of sineram_q16b is
  signal CLKA  : std_logic;                     -- Port A Clock
  signal CLKB  : std_logic;                     -- Port B Clock
  signal DOA  : STD_LOGIC_VECTOR(15 downto 0); -- A Data Output - lsb's used.
  signal DOB  : STD_LOGIC_VECTOR(15 downto 0); -- B Data Output - lsb's used.
  signal DIA  : STD_LOGIC_VECTOR(15 downto 0); -- A Data Input - lsb's used.
  signal DIB  : STD_LOGIC_VECTOR(15 downto 0); -- B Data Input - lsb's used.
  signal DOPA : STD_LOGIC_VECTOR( 1 downto 0); -- A Parity Out. Unused.
  signal DOPB : STD_LOGIC_VECTOR( 1 downto 0); -- B Parity Out. Unused.
  signal DIPA : STD_LOGIC_VECTOR( 1 downto 0); -- A Parity In. Unused.
  signal DIPB : STD_LOGIC_VECTOR( 1 downto 0); -- B Parity In. Unused.
  signal ENA  : STD_LOGIC := '1';              -- A Enable. Not changed.
  signal ENB  : STD_LOGIC := '1';              -- B Enable. Not changed.
  signal SSRA : STD_LOGIC := '0';              -- A Sync Set/Reset. Not changed.
  signal SSRB : STD_LOGIC := '0';              -- B Sync Set/Reset. Not changed.
  -- signal data1in : STD_LOGIC_VECTOR (15 downto 0); -- Dummy. Not used.
  -- signal data2in : STD_LOGIC_VECTOR (15 downto 0); -- Dummy. Not used.
  signal write1  : STD_LOGIC := '0'; -- Dummy. Not used.
  signal write2  : STD_LOGIC := '0'; -- Dummy. Not used.
begin

   -- RAMB16_S18_S18: Virtex-II/II-Pro, Spartan-3/3E 2k x 8 + 1 Parity bit Dual-Port RAM
   -- Xilinx HDL Language Template.


   RAMB16_S18_S18_inst : RAMB16_S18_S18
   generic map (
      INIT_A => X"000", --  Value of output RAM registers on Port A at startup
      INIT_B => X"000", --  Value of output RAM registers on Port B at startup
      SRVAL_A => X"000", --  Port A ouput value upon SSR assertion
      SRVAL_B => X"000", --  Port B ouput value upon SSR assertion
      WRITE_MODE_A => "WRITE_FIRST", --  WRITE_FIRST, READ_FIRST or NO_CHANGE
      WRITE_MODE_B => "WRITE_FIRST", --  WRITE_FIRST, READ_FIRST or NO_CHANGE
      SIM_COLLISION_CHECK => "ALL", -- "NONE", "WARNING", "GENERATE_X_ONLY", "ALL" 
      -- The following INIT_xx declarations specify the initial contents of the RAM
      --
--             0f  0e  0d  0c  0b  0a  09  08  07  06  05  04  03  02  01  00
INIT_00 => X"061605b2054d04e90484042003bb035602f2028d022901c4016000fb00970032",
INIT_01 => X"0c5d0bf90b950b300acc0a670a03099e093a08d50871080d07a8074406df067b",
INIT_02 => X"12a3123f11da1176111210ad10490fe50f800f1c0eb80e530def0d8b0d260cc2",
INIT_03 => X"18e61881181d17b9175516f1168d162915c5156014fc1498143413d0136b1307",
INIT_04 => X"1f241ec11e5d1df91d951d311ccd1c691c051ba21b3e1ada1a761a1219ae194a",
INIT_05 => X"255e24fb2497243423d0236d230922a6224221de217b211720b320501fec1f88",
INIT_06 => X"2b922b2f2acc2a692a0629a3294028dc2879281627b3274f26ec2689262525c2",
INIT_07 => X"31c0315d30fb309830352fd32f702f0d2eaa2e472de42d812d1e2cbc2c592bf6",
INIT_08 => X"37e63784372136bf365d35fb3599353634d43471340f33ad334a32e832853223",
INIT_09 => X"3e033da13d403cde3c7d3c1b3bb93b573af53a943a3239d0396e390c38aa3848",
INIT_0a => X"441743b6435542f44293423241d0416f410e40ad404b3fea3f893f273ec63e64",
INIT_0b => X"4a2049bf495f48ff489e483e47de477d471d46bc465b45fb459a453944d84477",
INIT_0c => X"501d4fbe4f5e4eff4e9f4e3f4de04d804d204cc04c604c004ba04b404ae04a80",
INIT_0d => X"560f55b0555154f25494543553d65377531852b9525951fa519b513c50dc507d",
INIT_0e => X"5bf35b955b375ad95a7b5a1d59bf5961590258a4584657e75789572b56cc566d",
INIT_0f => X"61c9616c610f60b260555ff75f9a5f3d5ee05e825e255dc75d6a5d0c5cae5c51",
INIT_10 => X"6790673466d8667b661f65c36567650a64ae645263f56399633c62df62826226",
INIT_11 => X"6d466ceb6c906c356bda6b7f6b246ac86a6d6a1269b6695a68ff68a3684767eb",
INIT_12 => X"72ec7293723971df7185712a70d07076701c6fc16f676f0c6eb16e576dfc6da1",
INIT_13 => X"7881782877cf7776771d76c4766b761275b9755f750674ad745373fa73a07346",
INIT_14 => X"7e027dab7d537cfb7ca47c4c7bf47b9c7b447aec7a947a3b79e3798a793278d9",
INIT_15 => X"8371831a82c4826d821781c0816a811380bc8065800e7fb77f607f097eb17e5a",
INIT_16 => X"88cb8876882087cb8776872186cb8676862085cb8575851f84c98473841d83c7",
INIT_17 => X"8e0f8dbc8d688d148cc08c6c8c188bc48b708b1b8ac78a728a1e89c989748920",
INIT_18 => X"933e92ec929a924791f591a2914f90fd90aa905790048fb18f5d8f0a8eb78e63",
INIT_19 => X"9857980697b59764971396c29670961f95ce957c952a94d99487943593e39391",
INIT_1a => X"9d589d089cb99c699c1a9bca9b7a9b2a9ada9a8a9a3a99ea9999994998f898a8",
INIT_1b => X"a240a1f2a1a4a156a108a0baa06ca01d9fcf9f809f329ee39e949e459df69da7",
INIT_1c => X"a710a6c3a677a62ba5dea591a545a4f8a4aba45ea411a3c4a376a329a2dba28e",
INIT_1d => X"abc5ab7bab30aae5aa9aaa4faa04a9b9a96ea922a8d7a88ba83fa7f4a7a8a75c",
INIT_1e => X"b061b018afcfaf86af3caef3aeaaae60ae16adcdad83ad39acefaca5ac5aac10",
INIT_1f => X"b4e1b499b452b40bb3c3b37cb334b2ecb2a4b25cb214b1ccb183b13bb0f2b0a9",
INIT_20 => X"b945b8ffb8bab874b82eb7e9b7a3b75db716b6d0b68ab643b5fcb5b6b56fb528",
INIT_21 => X"bd8cbd49bd05bcc1bc7dbc39bbf5bbb1bb6cbb28bae3ba9eba59ba14b9cfb98a",
INIT_22 => X"c1b7c175c133c0f1c0afc06dc02abfe8bfa5bf63bf20beddbe9abe57be13bdd0",
INIT_23 => X"c5c3c583c543c503c4c3c483c442c402c3c1c380c33fc2fec2bdc27bc23ac1f8",
INIT_24 => X"c9b1c973c935c8f7c8b9c87ac83cc7fdc7bec77fc740c701c6c2c682c643c603",
INIT_25 => X"cd80cd44cd08cccccc8fcc53cc16cbdacb9dcb60cb23cae5caa8ca6bca2dc9ef",
INIT_26 => X"d12fd0f5d0bbd081d047d00ccfd2cf97cf5ccf21cee6ceaace6fce34cdf8cdbc",
INIT_27 => X"d4bed486d44ed416d3ded3a5d36dd334d2fbd2c2d289d250d216d1ddd1a3d169",
INIT_28 => X"d82dd7f7d7c1d78ad754d71ed6e7d6b0d67ad643d60cd5d4d59dd566d52ed4f6",
INIT_29 => X"db79db46db12dadedaa9da75da41da0cd9d7d9a2d96dd938d903d8ced898d862",
INIT_2a => X"dea4de73de41de0fddddddabdd78dd46dd13dce0dcaddc7adc47dc14dbe1dbad",
INIT_2b => X"e1ade17de14ee11ee0eee0bee08ee05de02ddffcdfccdf9bdf6adf39df07ded6",
INIT_2c => X"e493e466e438e40ae3dde3afe381e353e324e2f6e2c7e299e26ae23be20ce1dc",
INIT_2d => X"e755e72ae6ffe6d4e6a8e67ce651e625e5f9e5cce5a0e573e547e51ae4ede4c0",
INIT_2e => X"e9f4e9cbe9a2e979e950e927e8fde8d3e8a9e87fe855e82be801e7d6e7abe780",
INIT_2f => X"ec6fec49ec22ebfbebd4ebadeb85eb5eeb36eb0feae7eabfea96ea6eea46ea1d",
INIT_30 => X"eec6eea1ee7dee58ee33ee0fede9edc4ed9fed79ed54ed2eed08ece2ecbcec96",
INIT_31 => X"f0f7f0d5f0b3f091f06ef04cf029f006efe3efc0ef9cef79ef55ef32ef0eeeea",
INIT_32 => X"f304f2e4f2c4f2a4f284f264f243f223f202f1e1f1c0f19ff17ef15cf13bf119",
INIT_33 => X"f4eaf4cdf4b0f492f474f456f438f41af3fcf3ddf3bff3a0f381f362f342f323",
INIT_34 => X"f6acf691f676f65af63ff623f608f5ecf5d0f5b4f597f57bf55ef542f525f508",
INIT_35 => X"f847f82ef815f7fdf7e4f7caf7b1f798f77ef764f74af730f716f6fcf6e1f6c6",
INIT_36 => X"f9bcf9a5f98ff979f962f94bf934f91df906f8eff8d7f8bff8a8f890f877f85f",
INIT_37 => X"fb0afaf6fae2facefabafaa6fa91fa7cfa68fa53fa3efa28fa13f9fdf9e8f9d2",
INIT_38 => X"fc32fc20fc0ffbfdfbebfbd9fbc7fbb5fba3fb90fb7dfb6afb57fb44fb31fb1e",
INIT_39 => X"fd32fd23fd14fd05fcf6fce6fcd7fcc7fcb7fca7fc96fc86fc75fc65fc54fc43",
INIT_3a => X"fe0cfe00fdf3fde6fdd9fdccfdbffdb2fda4fd96fd89fd7bfd6cfd5efd50fd41",
INIT_3b => X"febefeb4feaafea0fe96fe8bfe80fe75fe6afe5ffe54fe48fe3cfe30fe24fe18",
INIT_3c => X"ff4aff42ff3aff33ff2bff22ff1aff12ff09ff00fef7feeefee5fedcfed2fec8",
INIT_3d => X"ffaeffa8ffa3ff9eff98ff93ff8dff87ff81ff7aff74ff6dff66ff5fff58ff51",
INIT_3e => X"ffeaffe7ffe5ffe2ffdfffdbffd8ffd4ffd1ffcdffc9ffc5ffc0ffbcffb7ffb3",
INIT_3f => X"fffffffffffffffefffdfffdfffcfffbfff9fff8fff6fff5fff3fff1ffefffec",
      -- -----------------------------------------------------------------------------
      -- The next set of INITP_xx are for the parity bits
      -- Address 0 to 511
      INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
      -- Address 512 to 1023
      INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
      -- Address 1024 to 1535
      INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
      -- Address 1536 to 2047
      INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000"
   )
   port map (
      DOA => DOA,      -- Port A 16-bit Data Output
      DOB => DOB,      -- Port B 16-bit Data Output
      DOPA => DOPA,    -- Port A 2-bit Parity Output
      DOPB => DOPB,    -- Port B 2-bit Parity Output
      ADDRA => addr1,  -- Port A 10-bit Address Input
      ADDRB => addr2,  -- Port B 10-bit Address Input
      CLKA => CLKA,    -- Port A Clock
      CLKB => CLKB,    -- Port B Clock
      DIA => DIA,      -- Port A 16-bit Data Input
      DIB => DIB,      -- Port B 16-bit Data Input
      DIPA => DIPA,    -- Port A 2-bit parity Input
      DIPB => DIPB,    -- Port-B 2-bit parity Input
      ENA => ENA,      -- Port A RAM Enable Input
      ENB => ENB,      -- PortB RAM Enable Input
      SSRA => SSRA,    -- Port A Synchronous Set/Reset Input
      SSRB => SSRB,    -- Port B Synchronous Set/Reset Input
      WEA => write1,   -- Port A Write Enable Input
      WEB => write2    -- Port B Write Enable Input
   );
   data1out <= DOA;
   CLKA <= clock1;

   data2out <= DOB;
   CLKB <= clock2;
end Behavioral;
