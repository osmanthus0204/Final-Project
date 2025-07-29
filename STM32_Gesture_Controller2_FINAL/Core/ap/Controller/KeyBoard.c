/*
 * StopWatch.c
 *
 *  Created on: Jul 3, 2025
 *      Author: kccistc
 */

#include "KeyBoard.h"
#include <string.h>



void KeyBoard_Init()
{

}

void KeyBoard_Execute()
{
	eKeyBoardState_t state = Model_GetKeyBoardState();

	switch(state)
	{
	case S_KEYBOARD_IDLE:
		KeyBoard_IDLE();
		break;
	case S_KEYBOARD_RIGHT:
		KeyBoard_RIGHT();
		break;
	case S_KEYBOARD_LEFT:
		KeyBoard_LEFT();
		break;
	case S_KEYBOARD_UP:
		KeyBoard_UP();
		break;
	case S_KEYBOARD_DOWN:
		KeyBoard_DOWN();
		break;
	case S_KEYBOARD_ZERO:
		KeyBoard_ZERO();
		break;
	case S_KEYBOARD_ONE:
		KeyBoard_ONE();
		break;
	case S_KEYBOARD_TWO:
		KeyBoard_TWO();
		break;
	case S_KEYBOARD_THREE:
		KeyBoard_THREE();
		break;
	case S_KEYBOARD_FOUR:
		KeyBoard_FOUR();
		break;
	case S_KEYBOARD_FIVE:
		KeyBoard_FIVE();
		break;
	case S_KEYBOARD_SIX:
		KeyBoard_SIX();
		break;
	case S_KEYBOARD_SEVEN:
		KeyBoard_SEVEN();
		break;
	case S_KEYBOARD_EIGHT:
		KeyBoard_EIGHT();
		break;
	case S_KEYBOARD_NINE:
		KeyBoard_NINE();
		break;
	default:
		break;
	}
}


void KeyBoard_IDLE()
{
	osEvent evt = osMessageGet(keyBoardEventMsgBox, 0);	// non-blocking: 들어올때까지 기다리는게 아니라, 있나 없나 체크만 하고 넘어감
	uint16_t evtState;

	if (evt.status == osEventMessage) {
		evtState = evt.value.v;

		if (evtState == EVENT_RIGHT) {
			Model_SetKeyBoardState(S_KEYBOARD_RIGHT);
		}
		else if (evtState == EVENT_LEFT) {
			Model_SetKeyBoardState(S_KEYBOARD_LEFT);
		}
		else if (evtState == EVENT_UP) {
			Model_SetKeyBoardState(S_KEYBOARD_UP);
		}
		else if (evtState == EVENT_DOWN) {
			Model_SetKeyBoardState(S_KEYBOARD_DOWN);
		}
		else if (evtState == EVENT_ZERO) {
			Model_SetKeyBoardState(S_KEYBOARD_ZERO);
		}
		else if (evtState == EVENT_ONE) {
			Model_SetKeyBoardState(S_KEYBOARD_ONE);
		}
		else if (evtState == EVENT_TWO) {
			Model_SetKeyBoardState(S_KEYBOARD_TWO);
		}
		else if (evtState == EVENT_THREE) {
			Model_SetKeyBoardState(S_KEYBOARD_THREE);
		}
		else if (evtState == EVENT_FOUR) {
			Model_SetKeyBoardState(S_KEYBOARD_FOUR);
		}
		else if (evtState == EVENT_FIVE) {
			Model_SetKeyBoardState(S_KEYBOARD_FIVE);
		}
		else if (evtState == EVENT_SIX) {
			Model_SetKeyBoardState(S_KEYBOARD_SIX);
		}
		else if (evtState == EVENT_SEVEN) {
			Model_SetKeyBoardState(S_KEYBOARD_SEVEN);
		}
		else if (evtState == EVENT_EIGHT) {
			Model_SetKeyBoardState(S_KEYBOARD_EIGHT);
		}
		else if (evtState == EVENT_NINE) {
			Model_SetKeyBoardState(S_KEYBOARD_NINE);
		}


	}
}

void KeyBoard_RIGHT()
{
	static keyBoard_t keyBoardData;

	keyBoardData.gestureData = 0x4F;

	keyBoard_t *pKeyBoardData = osMailAlloc(keyBoardDataMailBox, 0);
	memcpy(pKeyBoardData, &keyBoardData, sizeof(keyBoard_t));
	osMailPut(keyBoardDataMailBox, pKeyBoardData);

	Model_SetKeyBoardState(S_KEYBOARD_IDLE);

}

void KeyBoard_LEFT()
{
	static keyBoard_t keyBoardData;

	keyBoardData.gestureData = 0x50;

	keyBoard_t *pKeyBoardData = osMailAlloc(keyBoardDataMailBox, 0);
	memcpy(pKeyBoardData, &keyBoardData, sizeof(keyBoard_t));
	osMailPut(keyBoardDataMailBox, pKeyBoardData);

	Model_SetKeyBoardState(S_KEYBOARD_IDLE);
}

void KeyBoard_UP()
{
	static keyBoard_t keyBoardData;

	keyBoardData.gestureData = 0x51;

	keyBoard_t *pKeyBoardData = osMailAlloc(keyBoardDataMailBox, 0);
	memcpy(pKeyBoardData, &keyBoardData, sizeof(keyBoard_t));
	osMailPut(keyBoardDataMailBox, pKeyBoardData);

	Model_SetKeyBoardState(S_KEYBOARD_IDLE);
}

void KeyBoard_DOWN()
{
	static keyBoard_t keyBoardData;

	keyBoardData.gestureData = 0x52;

	keyBoard_t *pKeyBoardData = osMailAlloc(keyBoardDataMailBox, 0);
	memcpy(pKeyBoardData, &keyBoardData, sizeof(keyBoard_t));
	osMailPut(keyBoardDataMailBox, pKeyBoardData);

	Model_SetKeyBoardState(S_KEYBOARD_IDLE);
}

void KeyBoard_ZERO()
{
	static keyBoard_t keyBoardData;

	keyBoardData.gestureData = 0x62;

	keyBoard_t *pKeyBoardData = osMailAlloc(keyBoardDataMailBox, 0);
	memcpy(pKeyBoardData, &keyBoardData, sizeof(keyBoard_t));
	osMailPut(keyBoardDataMailBox, pKeyBoardData);

	Model_SetKeyBoardState(S_KEYBOARD_IDLE);
}

void KeyBoard_ONE()
{
	static keyBoard_t keyBoardData;

	keyBoardData.gestureData = 0x59;

	keyBoard_t *pKeyBoardData = osMailAlloc(keyBoardDataMailBox, 0);
	memcpy(pKeyBoardData, &keyBoardData, sizeof(keyBoard_t));
	osMailPut(keyBoardDataMailBox, pKeyBoardData);

	Model_SetKeyBoardState(S_KEYBOARD_IDLE);
}

void KeyBoard_TWO()
{
	static keyBoard_t keyBoardData;

	keyBoardData.gestureData = 0x5A;

	keyBoard_t *pKeyBoardData = osMailAlloc(keyBoardDataMailBox, 0);
	memcpy(pKeyBoardData, &keyBoardData, sizeof(keyBoard_t));
	osMailPut(keyBoardDataMailBox, pKeyBoardData);

	Model_SetKeyBoardState(S_KEYBOARD_IDLE);
}

void KeyBoard_THREE()
{
	static keyBoard_t keyBoardData;

	keyBoardData.gestureData = 0x5B;

	keyBoard_t *pKeyBoardData = osMailAlloc(keyBoardDataMailBox, 0);
	memcpy(pKeyBoardData, &keyBoardData, sizeof(keyBoard_t));
	osMailPut(keyBoardDataMailBox, pKeyBoardData);

	Model_SetKeyBoardState(S_KEYBOARD_IDLE);
}

void KeyBoard_FOUR()
{
	static keyBoard_t keyBoardData;

	keyBoardData.gestureData = 0x5C;

	keyBoard_t *pKeyBoardData = osMailAlloc(keyBoardDataMailBox, 0);
	memcpy(pKeyBoardData, &keyBoardData, sizeof(keyBoard_t));
	osMailPut(keyBoardDataMailBox, pKeyBoardData);

	Model_SetKeyBoardState(S_KEYBOARD_IDLE);
}

void KeyBoard_FIVE()
{
	static keyBoard_t keyBoardData;

	keyBoardData.gestureData = 0x5D;

	keyBoard_t *pKeyBoardData = osMailAlloc(keyBoardDataMailBox, 0);
	memcpy(pKeyBoardData, &keyBoardData, sizeof(keyBoard_t));
	osMailPut(keyBoardDataMailBox, pKeyBoardData);

	Model_SetKeyBoardState(S_KEYBOARD_IDLE);
}

void KeyBoard_SIX()
{
	static keyBoard_t keyBoardData;

	keyBoardData.gestureData = 0x5E;

	keyBoard_t *pKeyBoardData = osMailAlloc(keyBoardDataMailBox, 0);
	memcpy(pKeyBoardData, &keyBoardData, sizeof(keyBoard_t));
	osMailPut(keyBoardDataMailBox, pKeyBoardData);

	Model_SetKeyBoardState(S_KEYBOARD_IDLE);
}

void KeyBoard_SEVEN()
{
	static keyBoard_t keyBoardData;

	keyBoardData.gestureData = 0x5F;

	keyBoard_t *pKeyBoardData = osMailAlloc(keyBoardDataMailBox, 0);
	memcpy(pKeyBoardData, &keyBoardData, sizeof(keyBoard_t));
	osMailPut(keyBoardDataMailBox, pKeyBoardData);

	Model_SetKeyBoardState(S_KEYBOARD_IDLE);
}

void KeyBoard_EIGHT()
{
	static keyBoard_t keyBoardData;

	keyBoardData.gestureData = 0x60;

	keyBoard_t *pKeyBoardData = osMailAlloc(keyBoardDataMailBox, 0);
	memcpy(pKeyBoardData, &keyBoardData, sizeof(keyBoard_t));
	osMailPut(keyBoardDataMailBox, pKeyBoardData);

	Model_SetKeyBoardState(S_KEYBOARD_IDLE);
}

void KeyBoard_NINE()
{
	static keyBoard_t keyBoardData;

	keyBoardData.gestureData = 0x61;

	keyBoard_t *pKeyBoardData = osMailAlloc(keyBoardDataMailBox, 0);
	memcpy(pKeyBoardData, &keyBoardData, sizeof(keyBoard_t));
	osMailPut(keyBoardDataMailBox, pKeyBoardData);

	Model_SetKeyBoardState(S_KEYBOARD_IDLE);
}


