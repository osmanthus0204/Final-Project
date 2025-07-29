/*
 * Model_ServoMotor.c
 *
 *  Created on: Jul 19, 2025
 *      Author: kccistc
 */


#include "Model_ServoMotor.h"

static eServoMotorState_t servoMotorState = S_SERVO_IDLE;

osMessageQId servoMotorEventMsgBox;
osMessageQDef(servoMotorEventQueue, 4, uint16_t);

osMailQId servoMotorDataMailBox;
osMailQDef(servoMotorDataQueue, 4, servoMotor_t);

void Model_ServoMotorInit()
{
	servoMotorEventMsgBox = osMessageCreate(osMessageQ(servoMotorEventQueue), NULL);	// Listener -> Controller
	servoMotorDataMailBox = osMailCreate(osMailQ(servoMotorDataQueue), NULL);	// Controller -> Presenter
}

// 상태 변수에 직접 접근하지 않고, 외부에서 함수를 통해 접근
void Model_SetServoMotorState(eServoMotorState_t state)
{
	servoMotorState = state;
}

eServoMotorState_t Model_GetServoMotorState()
{
	return servoMotorState;
}
