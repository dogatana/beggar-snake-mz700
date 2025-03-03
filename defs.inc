#if exists PC8001
vram_addr       equ     $f300
BYTES_PER_X     equ     2
BYTES_PER_LINE  equ     120

function xy2vram(x, y) => ((y) * BYTES_PER_LINE + (x) * BYTES_PER_X + vram_addr)
function xy2attr(x, y) => ((y) * BYTES_PER_LINE + (x) + 80 + vram_addr)
increment       macro   reg
                inc     reg
                inc     reg
                endm
decrement       macro   reg
                dec     reg
                dec     reg
                endm
#elif exists MZ700
vram_addr       equ     $d000
BYTES_PER_X     equ     1
BYTES_PER_LINE  equ     40

function xy2vram(x, y) => ((y) * BYTES_PER_LINE + (x) * BYTES_PER_X + vram_addr)
function xy2attr(x, y) => ((y) * BYTES_PER_LINE + (x) * BYTES_PER_X + vram_addr + $0800)
increment       macro   reg
                inc     reg
                nop
                endm
decrement       macro   reg
                dec     reg
                nop
                endm
#endif
