/*
 * Controller.c
 *
 *  Created on: Jul 3, 2025
 *      Author: kccistc
 */

#include "Controller.h"
#include <string.h>

void Controller_CheckEventMode();

void Controller_Init()
{
	Motor_Init();// 나중에 motor_init
}

void Controller_Execute()
{
	eModestate_t state = Model_GetModeState();

	Controller_CheckEventMode();
	switch(state)
	{
	case S_MOTOR_MODE:
		Motor_Execute();
		break;
	case S_KEYBOARD_MODE:
		KeyBoard_Execute();
		break;
	case S_MOUSE_MODE:

		break;
	}
}

void Controller_CheckEventMode()
{
	osEvent evt = osMessageGet(modeEventMsgBox, 0);
	uint16_t evtState;

	if (evt.status == osEventMessage) {
		evtState = evt.value.v;

		if (evtState == S_KEYBOARD_MODE) {
			Model_SetModeState(S_KEYBOARD_MODE);
		}

		else if (evtState == S_MOTOR_MODE) {
			Model_SetModeState(S_MOTOR_MODE);
		}
	}
}





