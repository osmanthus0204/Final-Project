/*
 * Presenter.c
 *
 *  Created on: Jul 3, 2025
 *      Author: kccistc
 */

#include "Presenter.h"


void Presenter_Init()
{
	USBD_Init(&hUsbDeviceFS, &FS_Desc, DEVICE_FS);
	USBD_RegisterClass(&hUsbDeviceFS, &USBD_HID);

}

void Presenter_Execute()
{
	static eModestate_t prevState = -1;
	char str[30];
	eModestate_t state = Model_GetModeState();
	if(prevState != state){
		prevState = state;
		if (state == S_KEYBOARD_MODE){
			sprintf(str, "KEYBOARD:");
		}
		else if (state == S_MOUSE_MODE){
			sprintf(str, "MOUSE:");
		}

//		LCD_writeStringXY(0, 0, str);
	}

	switch(state)
	{
	case S_MOTOR_MODE:
		Presenter_ServoMotorExecute();
		break;
	case S_KEYBOARD_MODE:
		Presenter_KeyBoardExecute();
		break;
	case S_MOUSE_MODE:

		break;
	}
}
