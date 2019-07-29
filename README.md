# UNIXCourses_MiniLibC

Extend the Mini Lib C to Handle Signals
In this homework, you have to extend the mini C library introduced in the class to support signal relevant system calls. You have to implement the following C library functions in Assembly and C using the syntax supported by yasm x86_64 assembler.

1. setjmp: prepare for long jump by saving the current CPU state. In addition, preserve the signal mask of the current process.
2. longjmp: perform the long jump by restoring a saved CPU state. In addition, restore the preserved signal mask.
3. signal and sigaction: setup the handler of a signal.
4. sigprocmask: can be used to block/unblock signals, and get/set the current signal mask.
5. sigpending: check if there is any pending signal.
6. alarm: setup a timer for the current process.
7. functions to handle sigset_t data type: sigemptyset, sigfillset, sigaddset, sigdelset, and sigismember.

## Samples
```
$ make alarm1
gcc -c -g -Wall -fno-stack-protector -nostdlib -I. -I.. -DUSEMINI alarm1.c
ld -m elf_x86_64 --dynamic-linker /lib64/ld-linux-x86-64.so.2 -o alarm1 alarm1.o start.o -L. -L.. -lmini
rm alarm1.o
$ LD_LIBRARY_PATH=. ./alarm1
(3 seconds later ...)
Alarm clock
```
```
$ make alarm2
gcc -c -g -Wall -fno-stack-protector -nostdlib -I. -I.. -DUSEMINI alarm2.c
ld -m elf_x86_64 --dynamic-linker /lib64/ld-linux-x86-64.so.2 -o alarm2 alarm2.o start.o -L. -L.. -lmini
rm alarm2.o
$ LD_LIBRARY_PATH=. ./alarm2
(5 seconds later ...)
sigalrm is pending.
```
```
$ make alarm3
gcc -c -g -Wall -fno-stack-protector -nostdlib -I. -I.. -DUSEMINI alarm3.c
ld -m elf_x86_64 --dynamic-linker /lib64/ld-linux-x86-64.so.3 -o alarm3 alarm3.o start.o -L. -L.. -lmini
rm alarm3.o
$ LD_LIBRARY_PATH=. ./alarm3
^Csigalrm is pending.
```
```
$ make jmp1
gcc -o jmp1.o -c -g -Wall -fno-stack-protector -nostdlib -I. -I.. -DUSEMINI jmp1.c
ld -m elf_x86_64 --dynamic-linker /lib64/ld-linux-x86-64.so.2 -o jmp1 jmp1.o start.o -L. -L.. -lmini
rm jmp1.o
$ LD_LIBRARY_PATH=. ./jmp1
This is function a().
This is function b().
This is function c().
This is function d().
This is function e().
This is function f().
This is function g().
This is function h().
This is function i().
This is function j().
$
```

## hints
* [x86_64 system call table](http://blog.rchapman.org/posts/Linux_System_Call_Table_for_x86_64/)
* With LXR, you may also check how a system call is implemented, especially when an error code is returned from a system call. For example, here is the implementation for [sys_rt_sigaction](https://elixir.bootlin.com/linux/v4.16.8/source/kernel/signal.c#L3711) system call in the kernel. By reading the codes, you would know that passing an incorrect sigset_t size would lead to a negative EINVAL error code.
* For implementing setjmp with a preserved process signal mask, the recommended data structure for x86_64 is given below:
```
typedef struct jmp_buf_s {
	long long reg[8];
	sigset_t mask;
} jmp_buf[1];
```
The minimal eight 64-bit values you have to preserve in the reg array are: RBX, RSP, RBP, R12, R13, R14, R15, and the return address (to the caller of setjmp). The current process signal mask can be preserved in the mask field.
* To ensure that a signal handler can be properly called without crashing a process, you have to do the following additional setup in your implemented sigaction function as follows (illustrated in C language):
```
long sigaction(int how, const struct sigaction *nact, struct sigaction *oact) {
	...
	nact->sa_flags |= SA_RESTORER;
	nact->sa_restorer = /* your customized restore routine, e.g., __myrt */;
	ret = sys_rt_sigaction(how, nact, oact, sizeof(sigset_t));
	...
}
```
The implementation of the __myrt function is simply making a system call to sigreturn (rax = 15).
