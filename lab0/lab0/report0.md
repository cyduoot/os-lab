# 系统环境

* 操作系统 Ubuntu 16.04.3 LTS
* 内核版本 x86
* 工具链:
  + gcc-7.2.0
  + newlib-2.5.0.20170818
  + binutils-2.28.1
  + gdb-8.0
  + gmp-6.1.0
  + mpfr-3.1.4-1
  + mpc-1.0.3

# binutils
```
~/cross/src/binutils-2.28.1/configure --prefix=/home/chenyangdong/cross  --target=i386-pc-elf --disable-nls

make

make install
```
经过上面三个命令后`cross`目录中多了`bin`、`share`和`i386-pc-elf`三个文件夹。

# PATH变量

```
export PATH=$PATH:/home/chenyangdong/cross/bin
```

# gcc第一遍
```
~/cross/src/gcc-7.2.0/configure --prefix=/home/chenyangdong/cross  --target=i386-pc-elf --disable-nls --enable-languages=c --without-headers --with-newlib --disable-libssp --disable-libquadmath --with-system-zlib
```
发生错误，缺失相应库
>error: Building GCC requires GMP 4.2+, MPFR 2.4.0+ and MPC 0.8.0+.

通过包管理器搜索并安装相应库，名称及版本号分别为`libgmp-dev(6.1.0)`、`libmpfr-dev(3.1.4-1)`、`libmpc-dev(1.0.3)`。

安装完成后再次执行`configure`，成功完成。

下一步进行`make`以及`make install`

发现`cross`目录中多了`include`、`lib`和`libexec`三个文件夹

# newlib
```
~/cross/src/newlib-2.5.0.20170818/configure --prefix=/home/chenyangdong/cross  --target=i386-pc-elf --disable-nls
```

成功

继续进行`make`以及`make install`步骤

顺利完成

# GCC第二遍
```
~/cross/src/gcc-7.2.0/configure --prefix=/home/chenyangdong/cross  --target=i386-pc-elf --disable-nls --enable-languages=c  --with-system-zlib
```

顺利完成，进行下一步`make`以及`make install`步骤

顺利完成

# 思考

## 第一题

尝试编译hello.c
```c
int main() {return 0;}
```

>cannot find crt0.o: 没有那个文件或目录

尝试自行编写crt0.s

第一次，通过wikipedia搜索到crt0.s的基本功能，wiki上的示例代码如下
```
.text

.globl _start

_start: # _start is the entry point known to the linker
    mov %rsp, %rbp    # setup a new stack frame
    mov 0(%rbp), %rdi # get argc from the stack
    mov 8(%rbp), %rsi # get argv from the stack
    call main         # %rdi, %rsi are the first two args to main

    mov %rax, %rdi    # mov the return of main to the first argument
    mov $60, %rax     # set %rax for syscall 60 (exit)
    syscall           # call the kernel to exit
```

代码来源（https://en.wikipedia.org/wiki/Crt0）

这个是在x86_64平台的代码，将其相应的寄存器改成e开头的，并按照说明文档的指引安装好后可以使用gcc编译，编译命令包括`i386-pc-elf-gcc -c crt0.s`,`install crt0.o ~/cross/i386-pc-elf/lib/`,`i386-pc-elf-gcc hello.c`但是运行`a.out`时出现错误，提示为非法指令（核心已转储），经GDB调试发现似乎x86平台没有syscall这条命令，而且查询资料发现x86平台exit的序号应该为1，通过搜索引擎查找`x86 assembly linux system calls`关键字，在 https://en.wikibooks.org/wiki/X86_Assembly/Interfacing_with_Linux 网站上找到了x86相关解决方法，并且发现在x86中相应的rdi,rsi等应该改成ebx,ecx,使用修改后的crt0.s再次尝试编译，发现可以顺利通过。

## 第二题

我认为不需要链接到上述的`crt0.o`，它存在是因为，程序正常退出的`exit`指令也属于一种系统调用，而用户态本身是无法进行这种调用的，而`crt0.o`让程序在正常结束后有可以陷入内核态进行对`exit`调用的接口，保证了系统调用过程中的安全性和用户态与内核态权限关系的严密性。

## 第三题

```
~/cross/src/gdb-8.0/configure --prefix=/home/chenyangdong/cross  --target=i386-pc-elf
```

随后进行`make`,`make install`成功编译完成gdb,但是进入gdb尝试调试程序发现无法调试
>Don't know how to run.  Try "help target".

通过help看出需要有core等文件或者`gdbserver`才可以正常运行文件，但是目前并没有目标系统的内核，尝试编译`gdbserver`

```
~/cross/src/gdb-8.0/gdb/gdbserver/configure --prefix=/home/chenyangdong/cross  --host=i386-pc-elf
```
>configure: error: C compiler cannot create executables

打开编译目录的`config.log`查看发现，错误出在`newlib`上，一堆链接错误，据微信群的讨论所说先把这个问题放着，gdb的编译暂时只能做到这里。

后来经助教提示，host应该仍为本机
```
~/cross/src/gdb-8.0/gdb/gdbserver/configure --prefix=/home/chenyangdong/cross  --host=i386-pc-elf
```
>Error: target not supported by gdbserver.

看来对整个流程的理解还是不到位，暂时放下这个任务。
