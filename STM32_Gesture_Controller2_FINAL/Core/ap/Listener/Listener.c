/*
 * Listener.c
 *
 *  Created on: Jul 3, 2025
 *      Author: kccistc
 */

#include "Listener.h"


void Listener_Init()
{
	HAL_UART_Receive_IT(&huart1, &rx_data, 1);
}

void Listener_Execute()
{

}


void Listener_CheckMode()
{

}
