CC = gcc
CFLAGS = -Wall -Wextra -std=c11 -g -Isrc -Ipre_generated
LEX = flex
YACC = bison
YFLAGS = -d

SRCDIR = src
GENDIR = pre_generated
BUILDDIR = build
VPATH = $(SRCDIR):$(GENDIR)

$(shell mkdir -p $(BUILDDIR) $(GENDIR))

CORE_C_SRCS = main.c riscv.c
LEX_L_SRC = lexer.l
YACC_Y_SRC = parser.y
GEN_C_FILES = lex.yy.c parser.tab.c
GEN_H_PATH = $(GENDIR)/parser.tab.h

OBJS = $(addprefix $(BUILDDIR)/, $(CORE_C_SRCS:.c=.o) $(GEN_C_FILES:.c=.o))

TARGET = $(BUILDDIR)/compiler
UNSUPPORTED_TARGET = $(BUILDDIR)/compiler_unsupported

CORE_HDRS = $(SRCDIR)/compiler.h $(SRCDIR)/riscv.h

.PHONY: all clean unsupported

all: $(TARGET)

unsupported: $(UNSUPPORTED_TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

$(UNSUPPORTED_TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

$(TARGET): $(GENDIR)/lex.yy.c $(GENDIR)/parser.tab.c $(GEN_H_PATH)

$(GEN_H_PATH): $(GENDIR)/parser.tab.c

$(GENDIR)/parser.tab.c: $(YACC_Y_SRC)
	$(YACC) $(YFLAGS) --defines=$(GEN_H_PATH) -o $(GENDIR)/parser.tab.c $(SRCDIR)/$(YACC_Y_SRC)

$(GENDIR)/lex.yy.c: $(LEX_L_SRC) $(GEN_H_PATH)
	$(LEX) -o $(GENDIR)/lex.yy.c $(SRCDIR)/$(LEX_L_SRC)

$(BUILDDIR)/%.o: %.c $(CORE_HDRS) $(GEN_H_PATH)
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf $(BUILDDIR) $(GENDIR)/lex.yy.c $(GENDIR)/parser.tab.c $(GEN_H_PATH) output.s *.dSYM parser.tab.h

.SECONDARY: $(OBJS) $(GENDIR)/lex.yy.c $(GENDIR)/parser.tab.c $(GEN_H_PATH)