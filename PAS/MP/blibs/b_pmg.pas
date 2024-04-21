unit b_pmg;
(*
* @type: unit
* @author: bocianu <bocianu@gmail.com>
* @name: Player and missile graphics library.
* @version: 1.0.1

* @description:
* Set of useful constants, registers and methods to fiddle with hardware Atari 8-bit sprites (and missiles).
*
* This library is a part of 'blibs' - set of custom Mad-Pascal libraries.
*
* <https://gitlab.com/bocianu/blibs>
*)
interface

const
    PMG_vdelay_m0 = %00000001; // Vertical delay patterns
    PMG_vdelay_m1 = %00000010;
    PMG_vdelay_m2 = %00000100;
    PMG_vdelay_m3 = %00001000;
    PMG_vdelay_p0 = %00010000;
    PMG_vdelay_p1 = %00100000;
    PMG_vdelay_p2 = %01000000;
    PMG_vdelay_p3 = %10000000;
    
    PMG_SIZE_NORMAL = %00000000; // player widths
    PMG_SIZE_x2 = %00000001;
    PMG_SIZE_x4 = %00000011;
    
    PMG_MSIZE0_x2 = %00000001;  // missile widths
    PMG_MSIZE0_x4 = %00000011;
    PMG_MSIZE1_x2 = %00000100;
    PMG_MSIZE1_x4 = %00001100;
    PMG_MSIZE2_x2 = %00010000;
    PMG_MSIZE2_x4 = %00110000;
    PMG_MSIZE3_x2 = %01000000;
    PMG_MSIZE4_x4 = %11000000;

    PMG_gractl_missiles = %00000001;  // Turns on missiles
    PMG_gractl_players = %00000010;   // Turns on players
    PMG_gractl_latch = %00000100;
    PMG_gractl_default = PMG_gractl_missiles or PMG_gractl_players;

    PMG_sdmctl_DMA_missile = %00000100;   // Enable missiles DMA
    PMG_sdmctl_DMA_player = %00001000;    // Enable players DMA
    PMG_sdmctl_DMA_both = %00001100;
    PMG_sdmctl_oneline = %00010000;       // Set one line resolution
    PMG_sdmctl_screen_disabled = 0;
    PMG_sdmctl_screen_narrow = 1;
    PMG_sdmctl_screen_normal = %10;
    PMG_sdmctl_screen_wide = %11;
    PMG_sdmctl_default = PMG_sdmctl_DMA_both or PMG_sdmctl_screen_normal;

    PMG_collision_player_to_p0 = 1;      // Player overlaps Player0
    PMG_collision_player_to_p1 = 2;      // Player overlaps Player1
    PMG_collision_player_to_p2 = 4;      // Player overlaps Player2
    PMG_collision_player_to_p3 = 8;      // Player overlaps Player3

    PMG_5player = %00010000; // Turn on 5th player
    PMG_overlap = %00100000; // Additional color on players overlap

var
    PMG_sdmctl: byte absolute $D400; // Direct Memory Access (DMA) enable flag.
    PMG_sdmctl_S: byte absolute $22F; // Direct Memory Access (DMA) enable flag - shadow register.
    PMG_gprior: byte absolute $D01B; // Priority selection register.
    PMG_gprior_S: byte absolute $26F; // Priority selection register - shadow register.

    PMG_pcolr0: byte absolute $D012; // Player colors.
    PMG_pcolr1: byte absolute $D013;
    PMG_pcolr2: byte absolute $D014;
    PMG_pcolr3: byte absolute $D015;
    PMG_pcolr: array [0..3] of byte absolute $D012;

    PMG_pcolr0_S: byte absolute $2C0; // Player colors - shadow registers.
    PMG_pcolr1_S: byte absolute $2C1;
    PMG_pcolr2_S: byte absolute $2C2;
    PMG_pcolr3_S: byte absolute $2C3;
    PMG_pcolr_S: array [0..3] of byte absolute $2C0;

    PMG_hpos0: byte absolute $D000; // Horizontal positions of players.
    PMG_hpos1: byte absolute $D001;
    PMG_hpos2: byte absolute $D002;
    PMG_hpos3: byte absolute $D003;
    PMG_hpos: array [0..3] of byte absolute $D000;

    PMG_hposm0: byte absolute $D004; // Horizontal positions of missiles.
    PMG_hposm1: byte absolute $D005;
    PMG_hposm2: byte absolute $D006;
    PMG_hposm3: byte absolute $D007;
    PMG_hposm: array [0..3] of byte absolute $D004;

    PMG_sizep0: byte absolute $D008; // Size of players.
    PMG_sizep1: byte absolute $D009;
    PMG_sizep2: byte absolute $D00A;
    PMG_sizep3: byte absolute $D00B;
    PMG_sizep: array [0..3] of byte absolute $D008;

    PMG_sizem: byte absolute $D00C; // Size of missiles

    PMG_grafp0: byte absolute $D00D; // Players graphics shapes (non DMA).
    PMG_grafp1: byte absolute $D00E;
    PMG_grafp2: byte absolute $D00F;
    PMG_grafp3: byte absolute $D010;
    PMG_grafp: array [0..3] of byte absolute $D00D;

    PMG_grafm: byte absolute $D011; // Missile graphics shapes (non DMA).
    
    PMG_p0pl: byte absolute $D00C; // Player to player collison statuses.
    PMG_p1pl: byte absolute $D00D;
    PMG_p2pl: byte absolute $D00E;
    PMG_p3pl: byte absolute $D00F;
    PMG_ppl: array [0..3] of byte absolute $D00C;

    PMG_vdelay: byte absolute $D01C; // Vertical delay register.
    PMG_gractl: byte absolute $D01D; // Graphics Control register. Controls receipt of Player/Missile DMA data
    PMG_hitclr: byte absolute $D01E; // Clear Collisions
    PMG_pmbase: byte absolute $D407; // Upper byte of the player/missile base address

    PMG_oneline: boolean;   (* @var contains true if current mode uses single line resolution.
                                    contains false for double line resolution *)
    PMG_base: pointer;      (* @var contains base address *)
    PMG_size: word;         (* @var contains memory size used by PMG *)

procedure PMG_Init(base: byte); overload;
(*
* @description:
* Initializes PMG engine with default settings.
*
* @param: base - upper byte of PMG memory address
*
*)

procedure PMG_Init(base, sdmctl: byte); overload;
(*
* @description:
* Initializes PMG engine with custom sdmctl value.
*
* @param: base - upper byte of PMG memory address
* @param: sdmctl - SDMCTL register initial value
*
*)

procedure PMG_Init(base, sdmctl, gractl: byte); overload;
(*
* @description:
* Initializes PMG engine with custom sdmctl and gractl values.
*
* @param: base - upper byte of PMG memory address
* @param: sdmctl - SDMCTL register initial value
* @param: gractl - GRACTL register initial value
*
*)

procedure PMG_Clear;
(*
* @description:
* Clears memory of sprites and missiles filling it with zeroes.
*)
procedure PMG_Disable;
(*
* @description:
* Turns off PMG
*)

implementation

procedure PMG_Init(base, sdmctl, gractl: byte); overload;
var sdmctl_flags:byte;
begin
    PMG_pmbase := base;
    PMG_base := pointer(base*256);
    PMG_gractl := gractl;
    sdmctl_flags := (PMG_sdmctl_S and %11100000) or sdmctl;
    PMG_sdmctl := sdmctl_flags;
    PMG_sdmctl_S := sdmctl_flags;
    if sdmctl and 16 <> 0 then begin
        PMG_oneline := true;
        PMG_size := $0800;
    end else begin
        PMG_oneline := false;
        PMG_size := $0400;
    end;
end;

procedure PMG_Init(base, sdmctl: byte); overload;
var gractl: byte = PMG_gractl_default;
begin
    PMG_Init(base, sdmctl, gractl);
end;

procedure PMG_Init(base: byte); overload;
var sdmctl: byte = PMG_sdmctl_default;
begin
    PMG_Init(base, sdmctl);
end;

procedure PMG_Clear;
begin
    FillChar(PMG_base,PMG_size,0);
end;

procedure PMG_Disable;
var sdmctl_flags:byte;
begin
    PMG_gractl := 0;
    sdmctl_flags := (PMG_sdmctl_S and %11000011);
    PMG_sdmctl := sdmctl_flags;
    PMG_sdmctl_S := sdmctl_flags;
end;

end.
