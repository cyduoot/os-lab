ENTRY(entry)
SECTIONS{
    . = 0x400000;
    .text.entry : {*(.text.entry)}
    .text : { *(.text) }

    . = ALIGN(16);
    .rodata : { *(.rodata) }

    . = ALIGN(16);
    data_hi_base = .;
    data_hi_rombase = 0x500000;

    .data.hi data_hi_base : AT(data_hi_rombase)
    { *(.data)}

    . = ALIGN(16);
    .data : { *(.data.hi) }

    . = ALIGN(16);
    .bss : { *(.bss) }

    . = 0x500000;
    /DISCARD/ : {
    *(.eh_frame);
    *(.comment)
    }
}
