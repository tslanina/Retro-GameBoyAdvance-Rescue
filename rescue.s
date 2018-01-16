@ -=RESCUE=-
@ GBA version of GBC Minigame 2002 compo entry (1024 bytes size limit)
@ Direct port - no changes/additions
@
@ Tomasz Slanina
@ http://www.slanina.pl

      b  start

.org 0xc0

start:
      mov r1,#0x03000000 @ IWRAM
      ldr r0, =rescue
      add r2,r0,#2048    @ 2048 - aprox data size :)
loop1:
      ldr r3,[r0],#4
      str r3,[r1],#4
      cmp r0,r2
      bne loop1
      mov pc,#0x03000000

.pool @ req for separation startup code (and consts placed after .pool)
      @ from  game code (for game code compression)

rescue:
      mov r0,#0x04000000 @ registers base
      mov r1,#0x8b       @ sound init
      strh r1,[r0,#0x84]
      ldr r1,=0xff17
      strh r1,[r0,#0x80]

      add r9,r0,#6   @ r9 = pointer to line counter
      mov r1,#0x1140 @ bg0 on, obj on,  obj 1D map
      str r1,[r0]
      add r0,r0,#8
      mov r1,#0x84   @ 256 colors, map base #0, tile base #1
      str r1,[r0]

      bl tablegen    @ color table generator

      adr r0,data @ tiles
      mov r1,#0x06000000
      add r1,r1,#0x4000  @ vram - tiles block #1
      mov r6,#24         @ 12 tiles (10 digits+transparent+spike)
      mov r7,#1
      mov r8,#0x100      @ 1 = color 1
      bl decode

      mov r1,#0x06000000
      add r1,r1,#0x10000 @ obj vram

      mov r6,#16         @ 8 tiles (2 sprites 16x16)
      mov r7,#2
      mov r8,#0x200      @ 2 = color 2 (white)
      bl decode

      mov r6,#1
      mov r7,r6
      mov r8,#0x100      @ 1 = color 1 (green)
      bl decode

      mov r0,#0x05000000 @ palette base
      add r0,r0,#0x200   @ obj palette offset
      mov r1,#0x3e0      @ green
      strh r1,[r0,#2] !  @ preinc addressing mode + writeback
      mov r1,#0x10000
      sub r1,r1,#1       @ 0xffff - white
      strh r1,[r0,#2]

      mov r0,#0x06000000 @ vram start (map)
      mov r1,#608        @ 19  lines (19*32)
      mov r2,#0
scrloop1:
      strh r2,[r0],#2
      subs r1,r1,#1
      bne scrloop1

      mov r1,#32
      mov r2,#1          @ spike
scrloop2:
      strh r2,[r0],#2
      subs r1,r1,#1
      bne scrloop2

      mov r12,#0x02000000   @ external working ram
      add r12,r12,#0x20000  @ r12 - vars (base)
      add r11,r12,#0x10000  @ r11 - shadow OAM

      adr r0,data
      ldr r1,[r0,#8]
      str r1,[r12,#48]
      ldr r1,[r0,#112]
      str r1,[r12,#52]      @ random seed

      mov r0,#0
      str r0,[r12]
      str r0,[r12,#4]
      str r0,[r12,#8]
      str r0,[r12,#12]  @ score counter (4 digits)
      str r0,[r12,#16]  @ 'game over'
      str r0,[r12,#128] @ score counter used for speed change
      add r0,r0,#2
      str r0,[r12,#132] @ speed (initial = 2)

      adr r0,startspr
      mov r1,r11
      mov r2,#8
buildspr:
      ldrh r4,[r0],#2
      strh r4,[r1],#2
      subs r2,r2,#1
      bne buildspr

      mov r2,#512*4
      mov r3,#160     @ sprite 'off'
buildspr2:
      strh r3,[r1],#2
      subs r2,r2,#1
      bne buildspr2
      b gameloop
data:                   @tiles in 1bpp format (64 bits/tile)
      .word 0x00000000 @ transparent
      .word 0x00000000

      .word 0x10387cfe @ spike
      .word 0xffffffff

      .word 0x3c424200 @ 0
      .word 0x4242423c

      .word 0x00020200 @ 1
      .word 0x02020200

      .word 0x3c02023c @ 2
      .word 0x4040403c

      .word 0x3c02023c @ 3
      .word 0x0202023c

      .word 0x0042423c @ 4
      .word 0x02020200

      .word 0x3c40403c @ 5
      .word 0x0202023c

      .word 0x3c40403c @ 6
      .word 0x4242423c

      .word 0x3c020200 @ 7
      .word 0x02020200

      .word 0x3c42423c @ 8
      .word 0x4242423c

      .word 0x3c42423c @ 9
      .word 0x0202023c

      .word 0x073f7fff @ sprite 1
      .word 0xff816110
      .word 0xc0f8fcfe
      .word 0xfe020c10
      .word 0x0313110f
      .word 0x01030404
      .word 0x809010e0
      .word 0x0804040

      .word 0x0f1f3f7f @ sprite 2
      .word 0x4f202017
      .word 0xc0f0f8fc
      .word 0xfefe1e02
      .word 0x170a070f
      .word 0x1e222101
      .word 0x458e000
      .word 0x0000000

      .word 0xc0c0c0ff @ sprite 3
      .word 0xff000000

gameloop:
      mov r3,#0
      mov r0,#0x02000000 @ color table
      mov r2,#0x05000000 @ palette

colorbar:
      ldrh r8,[r9]       @ scanline counter
      cmp r8,#60
      bge exitloop
      mov r1,r8,lsl #2
      ldrh r8,[r1,r0]
      strh r8,[r2]       @ set 0 color
      strh r3,[r2,#2]    @ set 1 color to black (digits)
      b colorbar

exitloop:

      mov r0,#0x1f
      strh r0,[r2,#2]    @ set1 color to red (spikes)

      ldr r0,[r12,#12]   @score
      add r0,r0,#2
      mov  r1,#0x06000000
      add r1,r1,#90
      strh r0,[r1],#2    @ 2 = '0' tile
      ldr r0,[r12,#8]
      add r0,r0,#2
      strh r0,[r1],#2
      ldr r0,[r12,#4]
      add r0,r0,#2
      strh r0,[r1],#2
      ldr r0,[r12]
      add r0,r0,#2
      strh r0,[r1]

      mov r0,#0x04000000 @ registers base
      add r0,r0,#0x130   @ key input offset
      ldrh r0,[r0]       @ left
      tst r0,#0x20
      bne noleft

      ldrh r3,[r11,#2]
      ands r3,r3,#0xff   @ sprite x
      subne r3,r3,#4     @ sub if != 0
      strh r3,[r11,#2]
      add r3,r3,#8
      orr r3,r3,#0x1000  @ second sprite , H flipped
      strh r3,[r11,#10]
      b skipkey

noleft:
      tst r0,#0x10       @ right
      bne skipkey

      ldrh r3,[r11,#2]
      cmp r3,#224-8      @ comapre with max value
      addle r3,r3,#8
      strh r3,[r11,#2]
      add r3,r3,#8
      orr r3,r3,#0x1000
      strh r3,[r11,#10]

skipkey:
      ldr r0,[r12,#36]
      add r0,r0,#1
      str r0,[r12,#36]   @ global counter inc
      ands r0,r0,#63
      bleq add_sprite    @ add new sprite
      ldr r0,[r12,#36]
      ands r0,r0,#3
      bleq s_autorun     @ sprite anim & autorun

      ldr r0,[r12,#16]     @ end of game ?
      cmp r0,#0
      movne pc,#0x03000000 @ jump to start of code (in internal working ram)

wait_vbl:
      ldrh r8,[r9]
      cmp r8,#160
      bne wait_vbl  @ wait for rasterline 160

      mov r0,#0
      mov r1,#0x07000000 @ OAM
copyOAM:
      ldrh r3,[r11,r0]
      strh r3,[r1,r0]    @ Shadow OAM -> OAM
      add r0,r0,#2
      cmp r0,#512*2
      bne copyOAM


wait_0:
      ldrh r8,[r9]
      cmp r8,#0
      bne wait_0    @ wait for  rasterline 0
      b gameloop

tablegen:

      mov r0,#0x02000000 @ external working  ram
      mov r3,#0x7c00     @blue

      str r3,[r0],#4
      str r3,[r0],#4
      str r3,[r0],#4
      str r3,[r0],#4
      str r3,[r0],#4

      mov r2,#28         @ 28 shades
shade2:
      rsb r1,r2,#32
      mov r4,r1,lsl #4
      orr r4,r4,r1
      mov r4,r4,lsl #5
      orr r4,r4,r1
      str r4,[r0],#4
      subs r2,r2,#4
      bne shade2

      mov r2,#28
shade3:
      mov r4,r2,lsl #4
      orr r4,r4,r2
      mov r4,r4,lsl #5
      orr r4,r4,r2
      str r4,[r0],#4
      subs r2,r2,#4
      bne shade3

      mov r2,#160
shade4:
      str r3,[r0],#4
      subs r2,r2,#1
      bne shade4
      mov pc,lr

startspr:
      .hword 0x2090,112,16,0
      .hword 0x2090,0x1078,16,0

decode:

      ldr r2,[r0],#4     @ 1bpp data
      mov r3,#0x80000000 @ initial bit mask

decode1:
      mov r4,#0
      tst r2,r3           @ test bit
      movne r4,r7         @ set pixel
      mov r3,r3,lsr #1    @ shift mask
      tst r2,r3
      orrne r4,r4,r8
      movs r3,r3,lsr #1
      strh r4,[r1],#2
      bne decode1         @ branch if  bit mask != 0
      subs r6,r6,#1
      bne decode
      mov pc,lr

s_autorun:
      ldr r0,[r12,#32] @animation counter
      add r0,r0,#1
      str r0,[r12,#32]
      mov r0,#16

sprloop:
      ldrh r1,[r11,r0] @ sprite y
      and r1,r1,#0xff
      cmp r1,#160      @ is off ?
      beq skip_sprite
      cmp r1,#144-8    @ dead ?
      ble spr_ok
      mov r1,#160
      strh r1,[r11,r0]
      str r1,[r12,#16] @dead
      mov pc,lr

spr_ok:
      cmp r1,#144-20   @collisions range check
      ble nocol
      ldrh r2,[r11,#2] @ sprite 0 - x
      sub r2,r2,#12
      add r0,r0,#2
      ldrh r1,[r11,r0] @ sprite x
      and r1,r1,#0xff
      cmp r1,r2
      ble nocollide
      sub r1,r1,#28-12+6
      cmp r1,r2
      bge nocollide
      ldr r3,[r12,#128]
      add r3,r3,#1        @ score increase
      str r3,[r12,#128]
      ldr r4,[r12,#132]   @ speed
      ands r3,r3,#15
      addeq r4,r4,#1      @ increase every 16 scores
      cmps r4,#8          @ max 8
      strle r4,[r12,#132]

      mov r3,#0           @ bcd counter with correction ;)
      mov r4,#0

score_add_2:
      ldr r5,[r12,r4]
      cmp r5,#9
      bne no9
      str r3,[r12,r4]
      add r4,r4,#4
      b score_add_2       @ recursion ...

no9:
      add r5,r5,#1
      str r5,[r12,r4]

      mov r2,#0x04000000 @ register base
      mov r1,#0x2d
      strh r1,[r2,#0x60]
      ldr r1,=0xf180
      strh r1,[r2,#0x62]
      ldr r1,=0x89e1
      strh r1,[r2,#0x64] @ play sfx

      mov r1,#160
      sub r0,r0,#2     @ sprite y
      strh r1,[r11,r0] @ off
      b skip_sprite

nocollide:
      sub r0,r0,#2
nocol:

      ldrh r1,[r11,r0]
      and r1,r1,#0xff

      ldr r2,[r12,#132] @ speed
      add r1,r1,r2      @ increase y
      orr r1,r1,#0x2000
      strh r1,[r11,r0]

      ldr r1,[r12,#32] @ anim counter
      tst r1,#0x1
      beq skip_sprite
      add r1,r0,#6
      ldrh r2,[r11,r1] @ anim mode
      cmp r2,#0
      bne nm0
      mov r2,#1        @ mode 1
      strh r2,[r11,r1]
      sub r1,r1,#2
      mov r2,#8        @ frame 1
      strh r2,[r11,r1]
      b skip_sprite
nm0:
      cmp r2,#1
      bne nm1
      mov r2,#2        @ mode 2
      strh r2,[r11,r1]
      sub r1,r1,#2
      mov r2,#0        @ frame 0
      strh r2,[r11,r1]
      b skip_sprite

nm1:
      cmp r2,#2
      bne nm2
      mov r2,#3        @ mode 3
      strh r2,[r11,r1]
      sub r1,r1,#2
      mov r2,#8        @ frame 1
      strh r2,[r11,r1]
      sub r1,r1,#2
      ldrh r2,[r11,r1]
      orr r2,r2,#0x1000 @ flip H
      strh r2,[r11,r1]
      b skip_sprite

nm2:
      mov r2,#0         @ mode 0
      strh r2,[r11,r1]
      sub r1,r1,#2
      strh r2,[r11,r1]  @ frame0
      sub r1,r1,#2
      ldrh r2,[r11,r1]
      bic r2,r2,#0x1000 @ no flip
      strh r2,[r11,r1]

skip_sprite:
      add r0,r0,#8 @ next sprite
      cmp r0,#8*12
      ble sprloop
      mov pc,lr

add_sprite:
      ldr r0,[r12,#48]  @ pseudo random number generation
      ldr r1,[r12,#52]
      mov r7,r0,ROR #30
      mov r0,r0,ROR #1
      mov r1,r1,ROR #31
      mov r5,r1
      add r7,r7,r0
      and r5,r5,#1
      mvn r6,#1
      and r0,r0,r6
      and r1,r1,r6
      orr r0,r0,r5
      and r7,r7,#1
      add r1,r7,r1
      str r0,[r12,#48]
      str r1,[r12,#52]

      mov r0,#16
sadd_loop:
      ldrh r1,[r11,r0]  @ sprite y
      and r1,r1,#0xff
      cmp r1,#160       @ is off ?
      beq add_1
      add r0,r0,#8      @ next sprite
      cmp r0,#8*12
      ble sadd_loop
      mov pc,lr

add_1:
      mov r1,#24        @ start y
      orr r1,r1,#0x2000 @ 256 colors
      strh r1,[r11,r0]
      add r0,r0,#2

      ldr r1,[r12,#48]
      ldr r2,[r12,#52]  @ random x position
      mov r2,r2,ror #16
      eor r1,r2,r1

      and r1,r1,#0xff
      cmps r1,#224      @ max x = 224
      subge r1,r1,#100

      orr r1,r1,#0x4000
      strh r1,[r11,r0]
      add r0,r0,#2
      mov r1,#0
      strh r1,[r11,r0]
      add r0,r0,#2
      ldr r1,[r12,#36] @l1
      mov r2,#0
      tst r1,#0x40
      moveq r2,#2
      strh r2,[r11,r0] @ mode
      mov pc,lr

      .ascii  "www.slanina.pl"

.END

