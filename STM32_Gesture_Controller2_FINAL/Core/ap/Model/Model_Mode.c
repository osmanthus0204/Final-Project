/*
 * Model_Mode.c
 *
 *  Created on: Jul 4, 2025
 *      Author: kccistc
 */


#include "Model_Mode.h"

static eModestate_t modeState = S_MOTOR_MODE;

osMessageQId modeEventMsgBox;
osMessageQDef(modeEventQueue, 4, uint16_t);

void Model_ModeInit()
{
	modeEventMsgBox = osMessageCreate(osMessageQ(modeEventQueue), NULL);
}

void Model_SetModeState(eModestate_t state)
{
	modeState = state;
}

eModestate_t Model_GetModeState()
{
	return modeState;
}
