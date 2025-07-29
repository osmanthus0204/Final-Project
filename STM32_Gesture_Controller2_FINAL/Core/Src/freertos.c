/* USER CODE BEGIN Header */
/**
 ******************************************************************************
 * File Name          : freertos.c
 * Description        : Code for freertos applications
 ******************************************************************************
 * @attention
 *
 * Copyright (c) 2025 STMicroelectronics.
 * All rights reserved.
 *
 * This software is licensed under terms that can be found in the LICENSE file
 * in the root directory of this software component.
 * If no LICENSE file comes with this software, it is provided AS-IS.
 *
 ******************************************************************************
 */
/* USER CODE END Header */

/* Includes ------------------------------------------------------------------*/
#include "FreeRTOS.h"
#include "task.h"
#include "main.h"
#include "cmsis_os.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include <stdio.h>
//#include "tim.h"
#include "Listener.h"
#include "Controller.h"
#include "Presenter.h"
#include "Model_Mode.h"
#include "Model_KeyBoard.h"
#include "Model_ServoMotor.h"
#include "servomotor.h"
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
/* USER CODE BEGIN Variables */

/* USER CODE END Variables */
osThreadId defaultTaskHandle;
osThreadId myListenerTaskHandle;
osThreadId myControllerTasHandle;
osThreadId myPresenterTaskHandle;

/* Private function prototypes -----------------------------------------------*/
/* USER CODE BEGIN FunctionPrototypes */

/* USER CODE END FunctionPrototypes */

void StartDefaultTask(void const * argument);
void ListenerTask(void const * argument);
void ControllerTask(void const * argument);
void PresenterTask(void const * argument);

extern void MX_USB_DEVICE_Init(void);
void MX_FREERTOS_Init(void); /* (MISRA C 2004 rule 8.1) */

/* GetIdleTaskMemory prototype (linked to static allocation support) */
void vApplicationGetIdleTaskMemory( StaticTask_t **ppxIdleTaskTCBBuffer, StackType_t **ppxIdleTaskStackBuffer, uint32_t *pulIdleTaskStackSize );

/* USER CODE BEGIN GET_IDLE_TASK_MEMORY */
static StaticTask_t xIdleTaskTCBBuffer;
static StackType_t xIdleStack[configMINIMAL_STACK_SIZE];

void vApplicationGetIdleTaskMemory( StaticTask_t **ppxIdleTaskTCBBuffer, StackType_t **ppxIdleTaskStackBuffer, uint32_t *pulIdleTaskStackSize )
{
	*ppxIdleTaskTCBBuffer = &xIdleTaskTCBBuffer;
	*ppxIdleTaskStackBuffer = &xIdleStack[0];
	*pulIdleTaskStackSize = configMINIMAL_STACK_SIZE;
	/* place for user code */
}
/* USER CODE END GET_IDLE_TASK_MEMORY */

/**
  * @brief  FreeRTOS initialization
  * @param  None
  * @retval None
  */
void MX_FREERTOS_Init(void) {
  /* USER CODE BEGIN Init */
  /* USER CODE END Init */

  /* USER CODE BEGIN RTOS_MUTEX */
	/* add mutexes, ... */
  /* USER CODE END RTOS_MUTEX */

  /* USER CODE BEGIN RTOS_SEMAPHORES */
	/* add semaphores, ... */
  /* USER CODE END RTOS_SEMAPHORES */

  /* USER CODE BEGIN RTOS_TIMERS */
	/* start timers, add new ones, ... */
  /* USER CODE END RTOS_TIMERS */

  /* USER CODE BEGIN RTOS_QUEUES */
	/* add queues, ... */
  /* USER CODE END RTOS_QUEUES */

  /* Create the thread(s) */
  /* definition and creation of defaultTask */
  osThreadDef(defaultTask, StartDefaultTask, osPriorityNormal, 0, 128);
  defaultTaskHandle = osThreadCreate(osThread(defaultTask), NULL);

  /* definition and creation of myListenerTask */
  osThreadDef(myListenerTask, ListenerTask, osPriorityNormal, 0, 128);
  myListenerTaskHandle = osThreadCreate(osThread(myListenerTask), NULL);

  /* definition and creation of myControllerTas */
  osThreadDef(myControllerTas, ControllerTask, osPriorityNormal, 0, 128);
  myControllerTasHandle = osThreadCreate(osThread(myControllerTas), NULL);

  /* definition and creation of myPresenterTask */
  osThreadDef(myPresenterTask, PresenterTask, osPriorityNormal, 0, 128);
  myPresenterTaskHandle = osThreadCreate(osThread(myPresenterTask), NULL);

  /* USER CODE BEGIN RTOS_THREADS */
	/* add threads, ... */
	Model_ModeInit();
	Model_KeyBoardInit();
	Model_ServoMotorInit();
  /* USER CODE END RTOS_THREADS */

}

/* USER CODE BEGIN Header_StartDefaultTask */
/**
 * @brief  Function implementing the defaultTask thread.
 * @param  argument: Not used
 * @retval None
 */
/* USER CODE END Header_StartDefaultTask */
void StartDefaultTask(void const * argument)
{
  /* init code for USB_DEVICE */
  MX_USB_DEVICE_Init();
  /* USER CODE BEGIN StartDefaultTask */
	/* Infinite loop */
	for(;;)
	{
		osDelay(1);
	}
  /* USER CODE END StartDefaultTask */
}

/* USER CODE BEGIN Header_ListenerTask */
/**
 * @brief Function implementing the myListenerTask thread.
 * @param argument: Not used
 * @retval None
 */
/* USER CODE END Header_ListenerTask */
void ListenerTask(void const * argument)
{
  /* USER CODE BEGIN ListenerTask */
	Listener_Init();
	/* Infinite loop */
	for(;;)
	{
		Listener_Execute();
		//		Presenter_SendKeyToPC(0x04);
		osDelay(1);
	}
  /* USER CODE END ListenerTask */
}

/* USER CODE BEGIN Header_ControllerTask */
/**
 * @brief Function implementing the myControllerTas thread.
 * @param argument: Not used
 * @retval None
 */
/* USER CODE END Header_ControllerTask */
void ControllerTask(void const * argument)
{
  /* USER CODE BEGIN ControllerTask */
	Controller_Init();


	/* Infinite loop */
	for(;;)
	{
		Controller_Execute();
		osDelay(1);
		//		Controller_Execute();
	}
  /* USER CODE END ControllerTask */
}

/* USER CODE BEGIN Header_PresenterTask */
/**
 * @brief Function implementing the myPresenterTask thread.
 * @param argument: Not used
 * @retval None
 */
/* USER CODE END Header_PresenterTask */
void PresenterTask(void const * argument)
{
  /* USER CODE BEGIN PresenterTask */
	Presenter_Init();

	/* Infinite loop */
	for(;;)
	{
		//		Presenter_SendKeyToPC(0x04);
		Presenter_Execute();
		osDelay(1);
	}
  /* USER CODE END PresenterTask */
}

/* Private application code --------------------------------------------------*/
/* USER CODE BEGIN Application */

/* USER CODE END Application */
