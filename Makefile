CC = gcc
CFLAGS = -Wall -Wextra -std=c11
LEX = flex
YACC = bison
YFLAGS = -d

TARGET = compiler
OBJS = lex.yy.o parser.tab.o main.o riscv.o

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

lex.yy.c: lexer.l parser.tab.h
	$(LEX) $<

parser.tab.c parser.tab.h: parser.y
	$(YACC) $(YFLAGS) $<

%.o: %.c
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f $(TARGET) $(OBJS) lex.yy.c parser.tab.c parser.tab.h output.s

.PHONY: all clean 