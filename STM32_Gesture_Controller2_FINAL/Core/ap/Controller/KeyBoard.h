
/*
 * StopWatch.h
 *
 *  Created on: Jul 3, 2025
 *      Author: kccistc
 */

#ifndef AP_CONTROLLER_STOPWATCH_H_
#define AP_CONTROLLER_STOPWATCH_H_

#include <stdint.h>
#include "cmsis_os.h"

#include "../Model/Model_KeyBoard.h"

extern keyBoard_t keyBoardData;

void KeyBoard_Init();
void KeyBoard_Execute();
void KeyBoard_IDLE();
void KeyBoard_RIGHT();
void KeyBoard_LEFT();
void KeyBoard_UP();
void KeyBoard_DOWN();
void KeyBoard_ZERO();
void KeyBoard_ONE();
void KeyBoard_TWO();
void KeyBoard_THREE();
void KeyBoard_FOUR();
void KeyBoard_FIVE();
void KeyBoard_SIX();
void KeyBoard_SEVEN();
void KeyBoard_EIGHT();
void KeyBoard_NINE();



#endif /* AP_CONTROLLER_STOPWATCH_H_ */
