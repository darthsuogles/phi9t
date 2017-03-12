include cuMake.inc

TRGT = max_poll

EXEC = $(TRGT:=.exec)
SRC = $(EXEC:.exec=.cu)

# Target rules
all: $(EXEC)

%.exec: %.cu
	$(NVCC) $(INCLUDES) $(ALL_LDFLAGS) $(GENCODE_SM35) -o $@ $^ $(LIBRARIES)
	mv $@ $(@:.exec=)

clean:
	rm -f $(TRGT)
