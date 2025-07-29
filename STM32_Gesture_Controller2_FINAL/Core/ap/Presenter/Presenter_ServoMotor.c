/*
 * Presenter_ServoMotor.c
 *
 *  Created on: Jul 19, 2025
 *      Author: kccistc
 */


#include "Presenter_ServoMotor.h"
#include <stdio.h>
#include <string.h>

static int prev_angle = 0;
static servoMotor_t servoMotorData;
static uint8_t buf[8] = {0};

void Presenter_ServoMotorExecute(){
	servoMotor_t *pServoMotorData;
	osEvent evt = osMailGet(servoMotorDataMailBox, 0);
	USBD_HID_HandleTypeDef *hhid = (USBD_HID_HandleTypeDef*) hUsbDeviceFS.pClassData;

	if (evt.status == osEventMail) {
		pServoMotorData = evt.value.p;
		memcpy(&servoMotorData, pServoMotorData, sizeof(servoMotor_t));
		osMailFree(servoMotorDataMailBox, pServoMotorData);

		// 상대적인 각도 조정
		int new_angle = (int)prev_angle + (int)servoMotorData.rotateData;  // 예: +10, -10

		// 범위 제한: 0도 ~ 180도
		if (new_angle <= 0) new_angle = 1;
		if (new_angle >= 90) new_angle = 89;

		prev_angle = new_angle;

		Servo_SetAngle(prev_angle);
	}
	if (hhid->state == USBD_HID_IDLE && send_ready==1){
			buf[2] = 0;
			USBD_HID_SendReport(&hUsbDeviceFS, buf, sizeof(buf));
			send_ready = 0;
	}
}

