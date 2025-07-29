/*
 * Presenter_StopWatch.h
 *
 *  Created on: Jul 3, 2025
 *      Author: kccistc
 */

#ifndef AP_PRESENTER_PRESENTER_STOPWATCH_H_
#define AP_PRESENTER_PRESENTER_STOPWATCH_H_

#include "cmsis_os.h"
#include "Model_KeyBoard.h"
#include "usbd_hid.h"
#include "usb_device.h"
#include "usbd_desc.h"
#include "usbd_core.h"
#include "tim.h"
//#include "lcd.h"
//#include <string.h>

extern volatile uint8_t flag;
extern volatile uint8_t send_ready;

#endif /* AP_PRESENTER_PRESENTER_STOPWATCH_H_ */
void Presenter_KeyBoardInit();
void Presenter_KeyBoardExecute();
void Presenter_SendKeyToPC(uint8_t keycode);
//void Presenter_StopWatch_LCD(stopWatch_t stopWatchData);
