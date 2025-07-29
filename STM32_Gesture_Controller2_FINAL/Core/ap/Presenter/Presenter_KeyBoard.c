/*
 * Presenter_StopWatch.c
 *
 *  Created on: Jul 3, 2025
 *      Author: kccistc
 */

#include "Presenter_KeyBoard.h"

#include <stdio.h>
#include <string.h>

static keyBoard_t keyBoardData;

static uint8_t buf[8] = {0};


void Presenter_KeyBoardInit()
{
	//	LCD_Init(&hi2c1);
}

void Presenter_KeyBoardExecute()
{
	keyBoard_t *pKeyBoardData;
	osEvent evt = osMailGet(keyBoardDataMailBox, 0);
	USBD_HID_HandleTypeDef *hhid = (USBD_HID_HandleTypeDef*) hUsbDeviceFS.pClassData;

	if (evt.status == osEventMail) {
		pKeyBoardData = evt.value.p;
		memcpy(&keyBoardData, pKeyBoardData, sizeof(keyBoard_t));
		osMailFree(keyBoardDataMailBox, pKeyBoardData);
		Presenter_SendKeyToPC(keyBoardData.gestureData);
	}

	if (hhid->state == USBD_HID_IDLE && send_ready==1){
		buf[2] = 0;
		USBD_HID_SendReport(&hUsbDeviceFS, buf, sizeof(buf));
		send_ready = 0;
	}
}


/*
void Presenter_KeyBoardExecute()
{
	keyBoard_t *pKeyBoardData;
	osEvent evt = osMailGet(keyBoardDataMailBox, 0);
	if (evt.status == osEventMail) {
		pKeyBoardData = evt.value.p;
		memcpy(&keyBoardData, pKeyBoardData, sizeof(keyBoard_t));
		osMailFree(keyBoardDataMailBox, pKeyBoardData);
//		Presenter_StopWatch_LCD(keyBoardData); //여기서 pc로 보내줘야됨 어떻게? usb로
		Presenter_SendKeyToPC(keyBoardData.gestureData);
	}

}
 */



void Presenter_SendKeyToPC(uint8_t keycode) // 추가: 키보드 전송 함수
{
	if (hUsbDeviceFS.dev_state != USBD_STATE_CONFIGURED)
	{
		printf("USB not configured!\r\n");
		return;
	}

	USBD_HID_HandleTypeDef *hhid = (USBD_HID_HandleTypeDef*) hUsbDeviceFS.pClassData;

	printf("HID state before send: %d\r\n", hhid->state);  // <-- 여기에 출력





	if (hhid->state == USBD_HID_IDLE) {
		buf[2] = keycode;
		USBD_HID_SendReport(&hUsbDeviceFS, buf, sizeof(buf));
		flag=1;
		HAL_TIM_Base_Start_IT(&htim2);
		//		HAL_Delay(20);
	}





	//	    while (hhid->state != 0) osDelay(1);
	//	    USBD_HID_SendReport(&hUsbDeviceFS, buf, sizeof(buf));
	////	    HAL_Delay(20);
	//	    buf[2] = 0;
	//
	//	    while (hhid->state != 0) osDelay(1);
	//	    USBD_HID_SendReport(&hUsbDeviceFS, buf, sizeof(buf));

	printf("Key sent: 0x%02X\r\n", keycode);

}


/*
void Presenter_StopWatch_LCD(stopWatch_t stopWatchData)
{
	char str[30];

	static eStopWatchState_t prevStopWatchState = -1;
	eStopWatchState_t stopWatchState = Model_GetStopWatchState();
	if(stopWatchState != prevStopWatchState){
		prevStopWatchState = stopWatchState;
		if(stopWatchState == S_STOPWATCH_STOP) {
			sprintf(str, "STOP     ");
		}
		else if(stopWatchState == S_STOPWATCH_RUN) {
			sprintf(str, "RUN      ");
		}
		else if(stopWatchState == S_STOPWATCH_CLEAR) {
			sprintf(str, "CLEAR    ");
		}
		LCD_writeStringXY(0, 11, str);
	}

	sprintf(str, "%02d:%02d:%02d:%02d        ",
			stopWatchData.hour, stopWatchData.min,
			stopWatchData.sec, stopWatchData.msec / 10);

	LCD_writeStringXY(1, 0, str);
}
 */
