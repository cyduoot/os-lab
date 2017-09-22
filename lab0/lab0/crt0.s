.text

.global _start

_start:

mov %esp, %ebp # setup a new stack frame
mov 0(%ebp), %ebx
mov 8(%ebp), %ecx #get argc and argv
call main #call the main function with argc and argv

mov %eax, %ebx
mov $0x1, %eax
int $0x80  #make system call exit

