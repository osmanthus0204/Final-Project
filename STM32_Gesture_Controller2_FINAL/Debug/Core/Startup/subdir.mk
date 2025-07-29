################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (13.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
S_SRCS += \
../Core/Startup/startup_stm32h743xihx.s 

OBJS += \
./Core/Startup/startup_stm32h743xihx.o 

S_DEPS += \
./Core/Startup/startup_stm32h743xihx.d 


# Each subdirectory must supply rules for building sources it contributes
Core/Startup/%.o: ../Core/Startup/%.s Core/Startup/subdir.mk
	arm-none-eabi-gcc -mcpu=cortex-m7 -g3 -DDEBUG -c -I../Core/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc/Legacy -I../Middlewares/Third_Party/FreeRTOS/Source/include -I../Middlewares/Third_Party/FreeRTOS/Source/CMSIS_RTOS -I../Middlewares/Third_Party/FreeRTOS/Source/portable/GCC/ARM_CM4F -I../Drivers/CMSIS/Device/ST/STM32H7xx/Include -I../Drivers/CMSIS/Include -I"C:/atm32/working/20250720_Gesture_Controller2/Core/ap/Model" -I"C:/atm32/working/20250720_Gesture_Controller2/Core/ap/Presenter" -I../USB_DEVICE/App -I../USB_DEVICE/Target -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Class/HID/Inc -I"C:/atm32/working/20250720_Gesture_Controller2/Core/Src" -I"C:/atm32/working/20250720_Gesture_Controller2/Core/ap/Listener" -I"C:/atm32/working/20250720_Gesture_Controller2/Core/ap/Controller" -I"C:/atm32/working/20250720_Gesture_Controller2/Core/driver" -I"C:/atm32/working/20250720_Gesture_Controller2/Drivers/STM32H7xx_HAL_Driver" -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -o "$@" "$<"

clean: clean-Core-2f-Startup

clean-Core-2f-Startup:
	-$(RM) ./Core/Startup/startup_stm32h743xihx.d ./Core/Startup/startup_stm32h743xihx.o

.PHONY: clean-Core-2f-Startup

