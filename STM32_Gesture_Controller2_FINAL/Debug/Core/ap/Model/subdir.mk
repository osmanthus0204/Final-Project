################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (13.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Core/ap/Model/Model_KeyBoard.c \
../Core/ap/Model/Model_Mode.c \
../Core/ap/Model/Model_ServoMotor.c 

OBJS += \
./Core/ap/Model/Model_KeyBoard.o \
./Core/ap/Model/Model_Mode.o \
./Core/ap/Model/Model_ServoMotor.o 

C_DEPS += \
./Core/ap/Model/Model_KeyBoard.d \
./Core/ap/Model/Model_Mode.d \
./Core/ap/Model/Model_ServoMotor.d 


# Each subdirectory must supply rules for building sources it contributes
Core/ap/Model/%.o Core/ap/Model/%.su Core/ap/Model/%.cyclo: ../Core/ap/Model/%.c Core/ap/Model/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -g3 -DDEBUG -DSTM32 -DSTM32H743XIHx -DSTM32H7SINGLE -DSTM32H7 -DUSE_PWR_LDO_SUPPLY -DUSE_HAL_DRIVER -DSTM32H743xx -c -I../Inc -I../Core/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32H7xx/Include -I../Drivers/CMSIS/Include -I../Middlewares/Third_Party/FreeRTOS/Source/include -I../Middlewares/Third_Party/FreeRTOS/Source/CMSIS_RTOS -I../Middlewares/Third_Party/FreeRTOS/Source/portable/GCC/ARM_CM4F -I"C:/atm32/working/20250720_Gesture_Controller2/Core/ap/Model" -I"C:/atm32/working/20250720_Gesture_Controller2/Core/ap/Presenter" -I../USB_DEVICE/App -I../USB_DEVICE/Target -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Class/HID/Inc -I"C:/atm32/working/20250720_Gesture_Controller2/Core/Src" -I"C:/atm32/working/20250720_Gesture_Controller2/Core/ap/Listener" -I"C:/atm32/working/20250720_Gesture_Controller2/Core/ap/Controller" -I"C:/atm32/working/20250720_Gesture_Controller2/Core/driver" -I"C:/atm32/working/20250720_Gesture_Controller2/Drivers/STM32H7xx_HAL_Driver" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-Core-2f-ap-2f-Model

clean-Core-2f-ap-2f-Model:
	-$(RM) ./Core/ap/Model/Model_KeyBoard.cyclo ./Core/ap/Model/Model_KeyBoard.d ./Core/ap/Model/Model_KeyBoard.o ./Core/ap/Model/Model_KeyBoard.su ./Core/ap/Model/Model_Mode.cyclo ./Core/ap/Model/Model_Mode.d ./Core/ap/Model/Model_Mode.o ./Core/ap/Model/Model_Mode.su ./Core/ap/Model/Model_ServoMotor.cyclo ./Core/ap/Model/Model_ServoMotor.d ./Core/ap/Model/Model_ServoMotor.o ./Core/ap/Model/Model_ServoMotor.su

.PHONY: clean-Core-2f-ap-2f-Model

