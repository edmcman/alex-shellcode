FROM ubuntu:latest

RUN apt-get -y update && apt-get install -y nasm nano binutils netcat strace

COPY shell.asm .

RUN nasm -f elf32 shell.asm -o shell.o

RUN ld -m elf_i386 -o shell shell.o

EXPOSE 4444

ENTRYPOINT ["./shell"]