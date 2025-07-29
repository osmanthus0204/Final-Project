/*
 * servo.h
 *
 *  Created on: Jul 18, 2025
 *      Author: kccistc
 */

#ifndef DRIVER_SERVOMOTOR_H_
#define DRIVER_SERVOMOTOR_H_
#include <stdint.h>
#include "cmsis_os.h"
#include "tim.h"

void Servo_Init();
void Servo_SetAngle(uint8_t angle);

#endif /* DRIVER_SERVOMOTOR_H_ */
