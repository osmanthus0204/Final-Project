/*
 * servo.c
 *
 *  Created on: Jul 18, 2025
 *      Author: kccistc
 */

#include "servomotor.h"

void Servo_Init()
{
   HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_1);
}
void Servo_SetAngle(uint8_t angle)
{
    // 0도 = 1ms, 90도 = 2ms, 180도 = 3ms 기준
    uint16_t pulse = 1000 + ((angle * 2000) / 180);  // 1000us ~ 3000us
    __HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_1, pulse);
}
