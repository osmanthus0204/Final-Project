/*
 * Rotate.c
 *
 *  Created on: Jul 18, 2025
 *      Author: kccistc
 */

#include "Rotate.h"
#include <string.h>
void Motor_Init()
{
	Servo_Init();
}
void Motor_Execute(){
	eServoMotorState_t state = Model_GetServoMotorState();

	switch(state)
	{
	case S_SERVO_IDLE:
		Servo_IDLE();
		break;
	case S_SERVO_RIGHT:
		Servo_RIGHT();
		break;
	case S_SERVO_LEFT:
		Servo_LEFT();
		break;

	}

}

void Servo_IDLE(){
	osEvent evt = osMessageGet(servoMotorEventMsgBox, 0);	// non-blocking: 들어올때까지 기다리는게 아니라, 있나 없나 체크만 하고 넘어감
	uint16_t evtState;

	if (evt.status == osEventMessage) {
		evtState = evt.value.v;

		if (evtState == EVENT_SERVO_RIGHT) {
			Model_SetServoMotorState(S_SERVO_RIGHT);
		}
		else if (evtState == EVENT_SERVO_LEFT) {
			Model_SetServoMotorState(S_SERVO_LEFT);
		}
	}
}

void Servo_LEFT(){
	static servoMotor_t servoMotorData;

	servoMotorData.rotateData = -1; //angle - 10;

	servoMotor_t *pServoMotorData = osMailAlloc(servoMotorDataMailBox, 0);
	memcpy(pServoMotorData, &servoMotorData, sizeof(servoMotor_t));
	osMailPut(servoMotorDataMailBox, pServoMotorData);

	Model_SetServoMotorState(S_SERVO_IDLE);

}

void Servo_RIGHT(){
	static servoMotor_t servoMotorData;

	servoMotorData.rotateData = 1; //angle + 10;

	servoMotor_t *pServoMotorData = osMailAlloc(servoMotorDataMailBox, 0);
	memcpy(pServoMotorData, &servoMotorData, sizeof(servoMotor_t));
	osMailPut(servoMotorDataMailBox, pServoMotorData);

	Model_SetServoMotorState(S_SERVO_IDLE);

}
