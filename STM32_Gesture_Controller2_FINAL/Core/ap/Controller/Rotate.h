/*
 * Rotate.h
 *
 *  Created on: Jul 18, 2025
 *      Author: kccistc
 */

#ifndef AP_CONTROLLER_ROTATE_H_
#define AP_CONTROLLER_ROTATE_H_
#include "servomotor.h"
#include <stdint.h>
#include "cmsis_os.h"
#include "Model_ServoMotor.h"
void Motor_Execute();
void Motor_Init();
void Servo_IDLE();
void Servo_LEFT();
void Servo_RIGHT();

#endif /* AP_CONTROLLER_ROTATE_H_ */
