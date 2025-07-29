/*
 * Listener_StopWatch.h
 *
 *  Created on: Jul 3, 2025
 *      Author: kccistc
 */

#ifndef AP_LISTENER_LISTENER_KEYBOARD_H_
#define AP_LISTENER_LISTENER_KEYBOARD_H_

#include <stdint.h>
#include "cmsis_os.h"
#include "Model_KeyBoard.h"
#include "usart.h"

extern uint8_t rx_data;

void Listener_KeyBoardInit();
void Listener_KeyBoardExecute();
void Listener_CheckUART();

#endif /* AP_LISTENER_LISTENER_KEYBOARD_H_ */
