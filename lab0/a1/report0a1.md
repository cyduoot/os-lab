由于完全不明白要怎么做，先去网上找了个脚本参考了一下。
```
SECTIONS
{
. = 0×10000;
.text : { *(.text) }
. = 0×8000000;
.data : { *(.data) }
.bss : { *(.bss) }
}
```
来源 http://www.cnblogs.com/li-hao/p/4107964.html

大致了解了链接器脚本的写法,然后开始按照要求进行编写。

首先第一行写入口，入口为entry
然后就是`SECTIONS`，先把游标定位到0x400000,作为节的起始，然后根据要求，需要把`entry`符号定位在这个位置，阅读`labasm.S`文件，注意到这一段
```
.section .text.entry

.globl	entry
entry:
	call	labasm
```
`entry`符号是定义在`.text.entry`这个节里面的，故而需要把`.text.entry`放在最开始的位置，并导入其中内容，随后按要求顺序摆放其他各节，并且加上ALIGN进行对齐，经助教讲解，这里采用16字节对齐以让后面的工作更省心省力。最后给游标赋个值也许可以给前面的节加上地址的上限（这里是臆测不知道对不对）。

然后是关于`data_hi`的摆放，由于运行地址和加载地址不同，故而我需要将`data_hi`节摆放在`rodata`和`data`节之间，并使用`AT`关键字指定相应的位置，同时把对应的符号`data_hi_base`和`data_hi_rombase`赋上对应的正确的值。

写到这里，开始进行编译，按给定指令编译后，使用`readelf -a labmain`命令查看文件节的情况，发现entry的值以及各节的地址都满足要求，然后使用`objdump -D labmain`查看文件内数据，发现`a`和`b`的节和文档中要求相反，故将`*(.data.hi)`和`*(.data)`对调，重新编译后成功满足要求。
最后观察c文件，发现正确的程序应该返回值为0，在gdb调试模式下`run`这个程序
>[Inferior 1 (process 11671) exited normally]

normally意味着返回值为0，至此lds文件编写基本完成。
