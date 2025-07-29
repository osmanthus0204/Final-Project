/*
 * Model.h
 *
 *  Created on: Jul 3, 2025
 *      Author: kccistc
 */

#ifndef AP_MODEL_MODEL_KEYBOARD_H_
#define AP_MODEL_MODEL_KEYBOARD_H_

#include <stdint.h>
#include "cmsis_os.h"

typedef enum {S_KEYBOARD_IDLE, S_KEYBOARD_RIGHT, S_KEYBOARD_LEFT, S_KEYBOARD_UP, S_KEYBOARD_DOWN, S_KEYBOARD_ZERO, S_KEYBOARD_ONE, S_KEYBOARD_TWO, S_KEYBOARD_THREE, S_KEYBOARD_FOUR, S_KEYBOARD_FIVE, S_KEYBOARD_SIX, S_KEYBOARD_SEVEN, S_KEYBOARD_EIGHT, S_KEYBOARD_NINE} eKeyBoardState_t;
typedef enum {EVENT_LEFT, EVENT_RIGHT, EVENT_UP, EVENT_DOWN, EVENT_ZERO, EVENT_ONE, EVENT_TWO, EVENT_THREE, EVENT_FOUR, EVENT_FIVE, EVENT_SIX, EVENT_SEVEN, EVENT_EIGHT, EVENT_NINE} eKeyBoardEvent_t;

extern osMessageQId keyBoardEventMsgBox;
extern osMailQId keyBoardDataMailBox;


typedef struct {
	uint8_t gestureData;
}keyBoard_t;

void Model_KeyBoardInit();
void Model_SetKeyBoardState(eKeyBoardState_t state);
eKeyBoardState_t Model_GetKeyBoardState();


#endif /* AP_MODEL_MODEL_KEYBOARD_H_ */
