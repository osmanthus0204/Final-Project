/*
 * Model_ServoMotor.h
 *
 *  Created on: Jul 19, 2025
 *      Author: kccistc
 */

#ifndef AP_MODEL_MODEL_SERVOMOTOR_H_
#define AP_MODEL_MODEL_SERVOMOTOR_H_

#include <stdint.h>
#include "cmsis_os.h"

typedef enum {S_SERVO_IDLE, S_SERVO_RIGHT, S_SERVO_LEFT} eServoMotorState_t;
typedef enum {EVENT_SERVO_LEFT, EVENT_SERVO_RIGHT} eServoMotorEvent_t;

extern osMessageQId servoMotorEventMsgBox;
extern osMailQId servoMotorDataMailBox;


typedef struct {
	int rotateData;
}servoMotor_t;

void Model_ServoMotorInit();
void Model_SetServoMotorState(eServoMotorState_t state);
eServoMotorState_t Model_GetServoMotorState();


#endif /* AP_MODEL_MODEL_SERVOMOTOR_H_ */
