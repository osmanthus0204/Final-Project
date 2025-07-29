/*
 * Model.c
 *
 *  Created on: Jul 3, 2025
 *      Author: kccistc
 */

#include "Model_KeyBoard.h"

static eKeyBoardState_t keyBoardState = S_KEYBOARD_IDLE;

osMessageQId keyBoardEventMsgBox;
osMessageQDef(keyBoardEventQueue, 4, uint16_t);

osMailQId keyBoardDataMailBox;
osMailQDef(keyBoardDataQueue, 4, keyBoard_t);

void Model_KeyBoardInit()
{
	keyBoardEventMsgBox = osMessageCreate(osMessageQ(keyBoardEventQueue), NULL);	// Listener -> Controller
	keyBoardDataMailBox = osMailCreate(osMailQ(keyBoardDataQueue), NULL);	// Controller -> Presenter
}

// 상태 변수에 직접 접근하지 않고, 외부에서 함수를 통해 접근
void Model_SetKeyBoardState(eKeyBoardState_t state)
{
	keyBoardState = state;
}

eKeyBoardState_t Model_GetKeyBoardState()
{
	return keyBoardState;
}
