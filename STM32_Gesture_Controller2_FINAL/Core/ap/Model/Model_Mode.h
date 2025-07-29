/*
 * Model_Mode.h
 *
 *  Created on: Jul 4, 2025
 *      Author: kccistc
 */

#ifndef AP_MODEL_MODEL_MODE_H_
#define AP_MODEL_MODEL_MODE_H_

#include <stdint.h>
#include "cmsis_os.h"

typedef enum {S_MOTOR_MODE, S_KEYBOARD_MODE, S_MOUSE_MODE} eModestate_t;
typedef enum {EVENT_MODE} eModeEvent_t;


extern osMessageQId modeEventMsgBox;

void Model_ModeInit();
void Model_SetModeState(eModestate_t state);
eModestate_t Model_GetModeState();


#endif /* AP_MODEL_MODEL_MODE_H_ */
