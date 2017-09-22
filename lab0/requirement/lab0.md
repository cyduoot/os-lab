# 实验 0：工具链

## 实验目标

* 准备好开发 AIM 所需的环境，主要包括工具链和调试器。
* 熟悉与工具链和开发流程相关的环境变量。

## 实验原理

开发环境通常只会携带原生工具链，对于我们现有的安装在 x86_64 上的环境来说，它
只能编译 x86 系列平台运行的程序，也只能操作这一平台上的机器码。要进行跨平台
开发，就需要准备交叉工具链。通常意义上，基本工具链包括机器码工具（汇编器、
链接器等）、C 语言编译器和 C 标准库。参考 LFS [www.linuxfromscratch.org]。

我们要进行的是内核开发，所以不需要用户态 C 库，但可能会用到一些头文件（libgcc 也
会用到）。通常使用的 glibc 依赖 linux 内核的头文件，不适合我们使用，所以我们需要另选一个
C 库。另外，为了完成调试，我们还需要一个交叉工作的 gdb。

## 实验准备

* 类 Unix 操作系统，最好是版本较新的 Linux 发行版，必须包含：
  + 较新版本的 gcc（包含 g++），最好不低于 6.0。在 macOS 上需要单独安装 gcc。
  + 原生的基本工具链，其中 libc 和 libstdc++ 的头文件可能需要单独安装。
  + 一个你熟悉的 shell，如 bash、zsh 或 fish。
  + 如果此系统有比较大的内存（如大于4GB），请将 tmpfs 预先挂载到 /tmp 处。
* 另有一些包是可选的，或不需要安装于系统上，主要包括：
  + （几乎必须）zlib 的头文件，可能需要单独安装。
  + （必须，但有替代方法）gmp 及其头文件，可能需要单独安装。
  + （必须，但有替代方法）mpc 及其头文件，可能需要单独安装。
  + （必须，但有替代方法）mpfr 及其头文件，可能需要单独安装。
  + （可选，且有替代方法）isl 及其头文件，要求版本不低于 0.14，推荐版本不低于 0.15。
* 源代码包，大部分可以在 ftp.gnu.org 及其镜像下载到。newlib 可以在
  sourceware.org/pub/newlib 下载到。我们推荐使用最新稳定版本，以下的版本号供参考。
  请留意版本号使用规则，注有日期或使用了较大的数字（如 89、90、99）的版本号通常不是稳定版本。
  某些软件（如 linux 和 gnome）的小版本号为奇数时也不是我们这里意义上的稳定版本，但我们的实验中
  目前不会出现这种情况。
  + binutils-2.29
  + gcc-7.2.0
  + gdb-8.0
  + newlib-2.5.0
* 基本理解终端、shell、环境变量、特权等概念，对 linux 管理文件目录的方式（FHS）有初步的印象。

## 实验步骤

警告：本实验中 **不需要** 使用任何特权，包括 `su` 和 `sudo` 等，这能够保证系统不会印误操作等
原因损坏。请不要掉以轻心，因为不恰当的操作仍然可能破坏用户主目录内的程序、配置和数据。请务必仔细
检查每一条命令。

### 准备工作

1. 在 `$HOME` 中选择用于存放源代码、编译工具链和安装工具链的目录，如
   `$HOME/cross/src`、`$HOME/cross/build` 和 `$HOME/cross`。如果 /tmp 挂载了
   tmpfs，将编译目录放在其中可以显著加快编译。
2. 在用于编译的目录中创建5个子目录：`binutils`、`gcc-pass1`、`newlib`、
   `gcc-pass2`、`gdb`。
3. 在源代码目录中将预先准备好的压缩包解压。

### Binutils

1. 在 binutils 的编译目录中，运行 binutils 的 configure 脚本。此脚本在
   binutils 代码目录最上层，需要给出路径执行。这一步涉及一些参数和环境变量：
   + `CFLAGS` 和 `CXXFLAGS` 变量（可选），分别包含传给原生 gcc 和 g++ 的行为
     控制参数。默认值均为 `-O2 -g`。如果希望编译产物运行更快，可以将其设置为
     `-O3 -mtune=native`。
   + `--prefix=目录` 参数（必须），指定安装路径，默认值为 `/usr/local`。请务
     必将其设置为先前在 `$HOME` 中选择的目录，以防错误配置的工具链影响系统
     正常运行。
   + `--target=目标` 参数（必须），选择目标平台。这里的目标平台是指，编译所得
     的 `as` 等程序操作的汇编和二进制代码的平台，而非其运行的平台。AIM
     目前使用的目标平台包括：i386-pc-elf、arm-unknown-eabi、
     mips{,64}{,el}-unknown-elf 等。有些架构名称可以在此使用，但可能会生成有差异
     的工具链，包括：i686、x86_64、amd64、armhf、armv7a、aarch64 等。
   + `--disable-nls` 参数（推荐），不编译这个包的消息翻译。使用此参数可以使
     工具链输出英语消息，不受环境影响。
   + `--disable-werror` 参数（可选），不给编译器传递 `-Werror`，用于忽略警告。
     在推荐的环境中应当没有警告产生，通常不需要使用此选项。
   + 其他参数，通常平台相关。主要有 `--enable-interwork`、`--enable-multilib`
     和 ARM 平台上的 `--enable-thumb` 等。
   + 示例：`$SRC/binutils-2.28/configure --prefix=$PREFIX --target=arm-unknown-eabi --enable-thumb --enable-interwork --enable-multilib --disable-nls`
   + 示例：`$SRC/binutils-2.28/configure --prefix=$PREFIX --target=i386-pc-elf --disable-nls`
2. 运行 `make`。如果系统有比较多的处理器，可以加 `-jn` 参数进行多线程编译，
   其中 n 为最多允许同时进行的任务数。但是这一选项会打乱编译过程的日志，影响
   错误的排查。
3. 如果需要，可以执行 `make check` 测试新编译的程序。测试过程会使用 `expect`
   和 `runtest` 程序（后者来自 dejagnu 包），可能需要单独安装并重新进行
   `configure`。在通常的场景中，这些测试并没有很大帮助，可以安全忽略。希望获得有帮助的测试结果
   可能需要额外配置环境，不在实验的讨论范围之内。
4. 运行 `make install` 安装编译好的程序。这一步 **不应该** 出现没有权限而失败
   的情况。请 **千万不要** 在此使用 `sudo`。

### $PATH 变量

在安装路径中有一个 `bin` 目录，将其 **绝对路径** 添加到 `$PATH` 变量的末尾，
如：`export PATH=$PATH:$PREFIX/bin`
如果系统上已经有一套同名的工具链（少见），该路径需要添加到原有工具链的 bin 路径之前。

上述命令只在当前 shell 中生效，每次使用都需要设置。可以将其添加到
`$HOME/.profile` 中，用户每次登录时就会将 `$PATH` 准备好。如果使用的是 fish，
请将对应的 fish 命令写入到 `$HOME/.config/fish/config.fish` 中。

如果该变量已设置好，重新安装交叉工具链时 **不要** 再进行设置。

### GCC 第一遍

1. 在 gcc 第一遍的编译目录中，运行 gcc 的 configure 脚本。此脚本在
   gcc 代码目录最上层，需要给出路径执行。这一步涉及一些参数和环境变量：
   + `CFLAGS` 和 `CXXFLAGS` 变量，同上。
   + `--prefix=目录` 参数，同上。
   + `--target=目标` 参数，同上，必须与之前使用的值完全相同。
   + `--disable-nls` 参数，同上。
   + `--enable-languages=c` 参数（必须），指定只编译 C 语言编译器。
   + `--without-headers --with-newlib` 参数（必须），通知 gcc 当前的环境是受限
     的，部分依赖关系无法满足，需要 gcc 作出调整。
   + `--disable-libssp` 参数（几乎必须）。`libssp` 是 gcc 内部的一个库，现在
     由于依赖关系无法满足，它很可能导致编译失败，需要我们手动禁用。由于系统
     环境有差异，这个库或许能够编译通过，此时这一参数不再必须。同理，gcc
     其他的内部库也可能会编译失败，如果在编译日志中确认了这一情况，可以相应
     禁用该库。
   + `--disable-libquadmath` 参数（几乎必须），同上。
   + `--with-system-zlib` 参数（几乎必须）。gcc 携带的 zlib 很可能会无法编译
     通过，这一选项告知 gcc 使用系统上安装的 zlib。使用此参数要求系统上安装有 zlib 及其头文件。
   + 其他参数，包括在 binutils 的步骤中提到的三个。
   + 示例：`$SRC/gcc-7.0.0/configure --prefix=$PREFIX --target=arm-unknown-eabi --enable-thumb --enable-interwork --enable-multilib --disable-nls --enable-languages=c --without-headers --with-newlib --with-system-zlib --disable-libssp`
2. 运行 `make`，同上。
3. 如果需要，可以执行 `make check`，同上。gcc 的测试用到了 autogen，需要单独
   安装，但无需重新 configure。在通常的场景中，这些测试并没有很大帮助，可以安全忽略。
   希望获得有帮助的测试结果可能需要额外配置环境，不在实验的讨论范围之内。
4. 运行 `make install`。这一步 **不应该** 出现没有权限而失败的情况。请
   **千万不要** 在此使用 `sudo`。

### newlib

1. 在 newlib 的编译目录中，运行 newlib 的 configure 脚本。此脚本在
   newlib 代码目录最上层，需要给出路径执行。这一步涉及一些参数和环境变量：
   + `CFLAGS` 和 `CXXFLAGS` 变量，同上。
   + `--prefix=目录` 参数，同上。
   + `--target=目标` 参数，同上，必须与之前使用的值完全相同。此处设置 target
     而非 host 是为了安装到交叉编译环境中，如果搭建的是直接供目标平台使用的
     系统，则需要指定 host。
   + `--disable-nls` 参数，同上。AIM 只使用 newlib 的头文件，所以此选项作用
     很小。二者会生成几乎一致的执行码，但生成流程和产物的 RPATH 会有区别。
   + 其他参数，但在 binutils 的步骤中提到的三个对 AIM 没有帮助。
   + 示例：`$SRC/newlib-2.5.0/configure --prefix=$PREFIX --target=arm-unknown-eabi --disable-nls`
2. 运行 `make`，同上。
3. 如果需要，可以执行 `make check`，同上。
4. 运行 `make install`。这一步 **不应该** 出现没有权限而失败的情况。请
   **千万不要** 在此使用 `sudo`。

### GCC 第二遍

在 gcc 第二遍的编译目录中，与第一遍相似地编译、测试并安装 gcc。由于 newlib
已经安装好，缺失的依赖关系已经补全，所以用于处理这些问题的参数都不应再
使用，包括 `--without-headers --with-newlib` 和
`--disable-libssp --disable-libquadmath` 等。

`--with-system-zlib` 参数不是用于解决依赖关系的，应该保持原样。

示例：`$SRC/gcc-6.2.0/configure --prefix=$PREFIX --target=arm-unknown-eabi --enable-thumb --enable-interwork --enable-multilib --disable-nls --enable-languages=c --with-system-zlib`

## 思考题目

1. （必须）在 i386 等平台上，以上过程搭建的工具链尚不能够编译 `int main(void) { return 0; }` 通过，
   会提示缺少 crt0.o。crt0 的职责在于提供全局符号 _start，准备栈帧并且调用 main。
   请以所选平台的汇编语言编写 crt0.s，以新工具链编译通过并安装到 `$PREFIX/$TARGET/lib` 处。
   安装时应当使用 `install` 而非 `cp`。
2. （必须）我们的内核是否应当链接到上述的 crt0.o？如果是，它承担哪些职责？如果不是，我们为什么要
   求它存在？
2. （推荐）以上过程中没有编译 gdb，请自行确定参数和步骤，编译安装 gdb。

## 验收方式

1. 编译安装好的工具链能够编译 `int main(void) { return 0; }` 通过，产物的反汇编
   输出合理。
2. 提交一报告，描述自己实际使用的平台（发行版及版本、内核版本和工具链
   主要软件包版本）、编译安装的各软件包版本、整个流程中运行的命令（包括失败
   和回滚涉及的命令）及参数，作出简要解释。
3. 是否编译了 gdb？是否对流程有所调整？如果有，请一并提交，并简要解释。

