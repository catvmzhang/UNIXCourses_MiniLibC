
%macro gensys 2
	global sys_%2:function
sys_%2:
	push	r10
	mov	r10, rcx
	mov	rax, %1
	syscall
	pop	r10
	ret
%endmacro

; RDI, RSI, RDX, RCX, R8, R9 function call
; RDI, RSI, RDX, r10, R8, R9 system call


extern	errno

	section .data

	section .text

	gensys   0, read
	gensys   1, write
	gensys   2, open
	gensys   3, close
	gensys   9, mmap
	gensys  10, mprotect
	gensys  11, munmap
	gensys  13, rt_sigaction
	gensys  14, rt_sigprocmask
	gensys  22, pipe
	gensys  32, dup
	gensys  33, dup2
	gensys  34, pause
	gensys  35, nanosleep
	gensys	37, alarm
	gensys  57, fork
	gensys  60, exit
	gensys  79, getcwd
	gensys  80, chdir
	gensys  82, rename
	gensys  83, mkdir
	gensys  84, rmdir
	gensys  85, creat
	gensys  86, link
	gensys  88, unlink
	gensys  89, readlink
	gensys  90, chmod
	gensys  92, chown
	gensys  95, umask
	gensys  96, gettimeofday
	gensys 102, getuid
	gensys 104, getgid
	gensys 105, setuid
	gensys 106, setgid
	gensys 107, geteuid
	gensys 108, getegid
	gensys 127, rt_sigpending

	global open:function
open:
	call	sys_open
	cmp	rax, 0
	jge	open_success	; no error :)
open_error:
	neg	rax
%ifdef NASM
	mov	rdi, [rel errno wrt ..gotpc]
%else
	mov	rdi, [rel errno wrt ..gotpcrel]
%endif
	mov	[rdi], rax	; errno = -rax
	mov	rax, -1
	jmp	open_quit
open_success:
%ifdef NASM
	mov	rdi, [rel errno wrt ..gotpc]
%else
	mov	rdi, [rel errno wrt ..gotpcrel]
%endif
	mov	QWORD [rdi], 0		; errno = 0
open_quit:
	ret

	global sleep:function
sleep:
	sub	rsp, 32				; allocate timespec * 2
	mov	[rsp], rdi			; req.tv_sec
	mov	QWORD [rsp+8], 0	; req.tv_nsec
	mov	rdi, rsp			; rdi = req @ rsp
	lea	rsi, [rsp+16]		; rsi = rem @ rsp+16
	call	sys_nanosleep
	cmp	rax, 0
	jge	sleep_quit			; no error :)
sleep_error:
	neg	rax
	cmp	rax, 4				; rax == EINTR?
	jne	sleep_failed
sleep_interrupted:
	lea	rsi, [rsp+16]
	mov	rax, [rsi]			; return rem.tv_sec
	jmp	sleep_quit
sleep_failed:
	mov	rax, 0				; return 0 on error
sleep_quit:
	add	rsp, 32
	ret

;=============================
	global sigreturn:function
sigreturn:
	mov 	rax, 15			;system call 15 rt_sigreturn
	syscall
	ret

	global setjmp: function
setjmp:
	mov 	QWORD [rdi],    rbx		;store rax to reg[0]
	mov 	QWORD [rdi+8],  rsp		;store rcx to reg[1]
	mov 	QWORD [rdi+16], rbp		;store rcx to reg[2]
	mov 	QWORD [rdi+24], r12		;store rcx to reg[3]
	mov 	QWORD [rdi+32], r13		;store rcx to reg[4]
	mov 	QWORD [rdi+40], r14		;store rcx to reg[5]
	mov 	QWORD [rdi+48], r15		;store rcx to reg[6]
	mov 	rdx, 			QWORD [rsp]
	mov 	QWORD [rdi+56], rdx		;store rcx to reg[7]


	;call sigprocmask(0, NULL, &mask) to get signal mask
	xor 	rdi, rdi
	xor 	rsi, rsi
	lea 	rdx, [rdi+64]
	mov 	r10, 8
	call 	sys_rt_sigprocmask
	xor 	rax, rax
	ret
	

	global longjmp: function
longjmp:
	;set signal mask store in jmp_buf.mask
	push 	rsi
	push 	rdi
	lea 	rsi, [rdi+64]	;jmp_buf.mask put in argument 2
	mov 	rdi, 2			;SIG_SETMASK=2 put in argument 1
	xor 	rdx, rdx		;NULL put in argument 3
	mov 	r10, 8
	call 	sys_rt_sigprocmask
	pop 	rdi
	pop 	rsi
	xor 	rax, rax 		;clear rax
	mov 	rax, rsi		;val in longjmp(jmp_buf, val) put in return value register

	mov 	rbx, 	QWORD [rdi]
	mov 	rsp, 	QWORD [rdi+8]
	mov 	rbp, 	QWORD [rdi+16]
	mov 	r12, 	QWORD [rdi+24]
	mov 	r13, 	QWORD [rdi+32]
	mov 	r14, 	QWORD [rdi+40]
	mov 	r15, 	QWORD [rdi+48]
	mov 	rdx, 	QWORD [rdi+56]
	mov 	QWORD [rsp], 	rdx
	ret
	
