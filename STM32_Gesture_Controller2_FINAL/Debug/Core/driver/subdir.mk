################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (13.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Core/driver/servomotor.c 

OBJS += \
./Core/driver/servomotor.o 

C_DEPS += \
./Core/driver/servomotor.d 


# Each subdirectory must supply rules for building sources it contributes
Core/driver/%.o Core/driver/%.su Core/driver/%.cyclo: ../Core/driver/%.c Core/driver/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -g3 -DDEBUG -DSTM32 -DSTM32H743XIHx -DSTM32H7SINGLE -DSTM32H7 -DUSE_PWR_LDO_SUPPLY -DUSE_HAL_DRIVER -DSTM32H743xx -c -I../Inc -I../Core/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32H7xx/Include -I../Drivers/CMSIS/Include -I../Middlewares/Third_Party/FreeRTOS/Source/include -I../Middlewares/Third_Party/FreeRTOS/Source/CMSIS_RTOS -I../Middlewares/Third_Party/FreeRTOS/Source/portable/GCC/ARM_CM4F -I"C:/atm32/working/20250720_Gesture_Controller2/Core/ap/Model" -I"C:/atm32/working/20250720_Gesture_Controller2/Core/ap/Presenter" -I../USB_DEVICE/App -I../USB_DEVICE/Target -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Class/HID/Inc -I"C:/atm32/working/20250720_Gesture_Controller2/Core/Src" -I"C:/atm32/working/20250720_Gesture_Controller2/Core/ap/Listener" -I"C:/atm32/working/20250720_Gesture_Controller2/Core/ap/Controller" -I"C:/atm32/working/20250720_Gesture_Controller2/Core/driver" -I"C:/atm32/working/20250720_Gesture_Controller2/Drivers/STM32H7xx_HAL_Driver" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-Core-2f-driver

clean-Core-2f-driver:
	-$(RM) ./Core/driver/servomotor.cyclo ./Core/driver/servomotor.d ./Core/driver/servomotor.o ./Core/driver/servomotor.su

.PHONY: clean-Core-2f-driver

