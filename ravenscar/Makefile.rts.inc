CROSS=arm-none-eabi-

STM32_BASE=$(RAVENSCAR_SRC)/../src/STM32F4-Discovery_FW_V1.1.0

CFLAGS?=-O2 -g -Wall -Wno-strict-aliasing -Werror -DCONFIG_STM32F4_DISCOVERY=1 \
  -I$(STM32_BASE)/Utilities/STM32F4-Discovery \
  -I$(STM32_BASE)/Libraries/CMSIS/ST/STM32F4xx/Include \
  -I$(STM32_BASE)/Libraries/CMSIS/Include \
  -I$(STM32_BASE)/Libraries/STM32F4xx_StdPeriph_Driver/inc \
  -I$(STM32_BASE)/Libraries/STM32_USB_Device_Library/Class/cdc/inc \
  -I$(STM32_BASE)/Libraries/STM32_USB_Device_Library/Core/inc \
  -I$(STM32_BASE)/Libraries/STM32_USB_OTG_Driver/inc \
  -I$(RAVENSCAR_SRC)/stm32/ \
  -I$(RAVENSCAR_SRC)/stm32/usb \
  -DUSE_STDPERIPH_DRIVER -DSTM32F4XX -DUSE_USB_OTG_FS 

KERN_OBJS = startup_stm32f4xx.o main.o system_stm32f4xx.o context_switch-bb-arm.o

STM32_FILE=$(wildcard $(STM32_BASE)/Utilities/STM32F4-Discovery/*.c)
STM32_FILE+=$(wildcard $(STM32_BASE)/Libraries/STM32F4xx_StdPeriph_Driver/src/*.c)
STM32_FILE+=$(wildcard $(STM32_BASE)/Libraries/STM32_USB_Device_Library/Class/cdc/src/*.c)
STM32_FILE+=$(wildcard $(STM32_BASE)/Libraries/STM32_USB_Device_Library/Core/src/*.c)
STM32_FILE+=$(wildcard $(STM32_BASE)/Libraries/STM32_USB_OTG_Driver/src/usb_core.c)
STM32_FILE+=$(wildcard $(STM32_BASE)/Libraries/STM32_USB_OTG_Driver/src/usb_dcd*.c)
STM32_FILE+=$(wildcard $(RAVENSCAR_SRC)/stm32/usb/*.c)
STM32_TMP=$(filter-out %template.c,$(STM32_FILE))
STM32_OBJ=$(notdir $(STM32_TMP:.c=.o))

RTS_FILE=$(shell grep -L "^separate" $(RTS_BASE)/adainclude/*.ad[sb])
RTS_OBJ=$(notdir $(patsubst %.adb,%.o,$(RTS_FILE:.ads=.o)))

all: libgnat.a libstm32.a

libgnat.a: $(KERN_OBJS) $(RTS_OBJ) force
	$(CROSS)ar rcs $@ $(KERN_OBJS) $(RTS_OBJ)

libstm32.a: $(STM32_OBJ)
	$(CROSS)ar rcs $@ $(STM32_OBJ)

GCC_COMPILE=$(CROSS)gcc -c -o $@ $(CFLAGS) $<

%.o: $(RAVENSCAR_SRC)/%.s
	$(GCC_COMPILE)

%.o: $(RAVENSCAR_SRC)/%.c
	$(GCC_COMPILE)

%.o: $(GCC_SRC)/%.c
	$(GCC_COMPILE)

%.o: $(STM32_BASE)/Utilities/STM32F4-Discovery/%.c
	$(GCC_COMPILE)

%.o: $(STM32_BASE)/Libraries/STM32F4xx_StdPeriph_Driver/src/%.c
	$(GCC_COMPILE)

%.o: $(STM32_BASE)/Libraries/STM32_USB_Device_Library/Class/cdc/src/%.c
	$(GCC_COMPILE)

%.o: $(STM32_BASE)/Libraries/STM32_USB_Device_Library/Core/src/%.c
	$(GCC_COMPILE)

%.o: $(STM32_BASE)/Libraries/STM32_USB_OTG_Driver/src/%.c
	$(GCC_COMPILE)

%.o: $(RAVENSCAR_SRC)/stm32/usb/%.c
	$(GCC_COMPILE)

%.o: $(RTS_BASE)/adainclude/%.adb
	$(CROSS)gnatmake -gnata -a -c --RTS=$(RTS_BASE) -o $@ $(CFLAGS) $<

%.o: $(RTS_BASE)/adainclude/%.ads
	$(CROSS)gnatmake -gnata -a -c --RTS=$(RTS_BASE) -o $@ $(CFLAGS) $<

clean:
	$(RM) -f *.o *~ b~* $(PRG) *.ali *.map *.owav

force:
