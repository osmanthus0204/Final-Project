/* USER CODE BEGIN Header */
/**
 ******************************************************************************
 * @file           : main.c
 * @brief          : Main program body
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
#include "main.h"
#include "cmsis_os.h"
#include "dcmi.h"
#include "dma.h"
#include "memorymap.h"
#include "spi.h"
#include "tim.h"
#include "usart.h"
#include "usb_device.h"
#include "gpio.h"
#include "fmc.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include <stdio.h>
#include <string.h>
#include "Model_Mode.h"
#include "Model_KeyBoard.h"
#include "Presenter_KeyBoard.h"
#include "Presenter.h"
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */
extern const unsigned char black_cat[];
/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/

/* USER CODE BEGIN PV */
uint16_t *camBuf[320*240];   // static ram에 잡힘

uint8_t rx_data;
int captureFlag = 0;

volatile uint8_t flag=0;
volatile uint8_t send_ready = 0;
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
void PeriphCommonClock_Config(void);
static void MPU_Config(void);
void MX_FREERTOS_Init(void);
/* USER CODE BEGIN PFP */
/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */
int __io_putchar(int ch)
{
	HAL_UART_Transmit(&huart1, (uint8_t *)&ch, 1, 1000);

	return ch;
}

void HAL_SPI_TxCpltCallback(SPI_HandleTypeDef *hspi)
{
	if(hspi->Instance == SPI1) {
		printf("SPI DMA Complete!\n");
	}
}

void HAL_DCMI_FrameEventCallback(DCMI_HandleTypeDef *hdcmi)
{
	captureFlag = 1;
	printf("Complete Oneshot Frame Capture!\n");
}
/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{

  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */

  /* MPU Configuration--------------------------------------------------------*/
  MPU_Config();

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* Configure the peripherals common clocks */
  PeriphCommonClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_DMA_Init();
  MX_SPI1_Init();
  MX_FMC_Init();
  MX_DCMI_Init();
  MX_USART1_UART_Init();
  MX_TIM2_Init();
  MX_TIM3_Init();
  /* USER CODE BEGIN 2 */
	MX_USB_DEVICE_Init();


	HAL_DCMI_Start_DMA(&hdcmi, DCMI_MODE_SNAPSHOT, (uint32_t)&camBuf, 320*240/2);

	//   uint8_t *sdramAddr = (uint32_t *)(0xC0000000);
	//
	//   for (int i=0; i<100; i++) {
	//      sdramAddr[i] = i;
	//   }
	//
	//   for (int i=0; i<100; i++) {
	//      printf("sdramAddr[%d] = %d\n", i, sdramAddr[i]);
	//   }
	//
	//   printf("Hello STM32!\n");
	//   //HAL_SPI_Transmit_DMA(&hspi1, black_cat, 100);
	//
	//   for (uint32_t i=0; i<320*240*2; i++) {
	//      sdramAddr[i] = pic_240x320[i];
	//   }

  /* USER CODE END 2 */

  /* Call init function for freertos objects (in cmsis_os2.c) */
  MX_FREERTOS_Init();

  /* Start scheduler */
  osKernelStart();

  /* We should never get here as control is now taken by the scheduler */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
	while (1)
	{


		//      ILI9341_FillScreen(ILI9341_RED);
		//      HAL_Delay(500);
		//      ILI9341_FillScreen(ILI9341_GREEN);
		//      HAL_Delay(500);
		//      ILI9341_FillScreen(ILI9341_BLUE);
		//      HAL_Delay(500);

		//      ILI9341_DrawImage(0, 0, 240, 240, (const uint16_t *)test_img_240x240);
		//      HAL_Delay(500);
		//      ILI9341_DrawImage8(0, 0, 240, 320, (const uint8_t *)pic_240x320);
		//      ILI9341_DrawImage8(0, 0, 240, 320, (const uint8_t *)sdramAddr);
		//      HAL_Delay(500);

		//      HAL_Delay(500);
		//            ILI9341_DrawImage8(20, 30, 64, 64,(const uint8_t *)black_cat);
		//      ILI9341_WriteString(10, 200, "Hello, World!", Font_7x10, ILI9341_WHITE, ILI9341_BLACK);
		//      HAL_Delay(3000);

    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
	}
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Supply configuration update enable
  */
  HAL_PWREx_ConfigSupply(PWR_LDO_SUPPLY);

  /** Configure the main internal regulator output voltage
  */
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE0);

  while(!__HAL_PWR_GET_FLAG(PWR_FLAG_VOSRDY)) {}

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI48|RCC_OSCILLATORTYPE_HSE;
  RCC_OscInitStruct.HSEState = RCC_HSE_ON;
  RCC_OscInitStruct.HSI48State = RCC_HSI48_ON;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
  RCC_OscInitStruct.PLL.PLLM = 5;
  RCC_OscInitStruct.PLL.PLLN = 192;
  RCC_OscInitStruct.PLL.PLLP = 2;
  RCC_OscInitStruct.PLL.PLLQ = 2;
  RCC_OscInitStruct.PLL.PLLR = 2;
  RCC_OscInitStruct.PLL.PLLRGE = RCC_PLL1VCIRANGE_2;
  RCC_OscInitStruct.PLL.PLLVCOSEL = RCC_PLL1VCOWIDE;
  RCC_OscInitStruct.PLL.PLLFRACN = 0;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2
                              |RCC_CLOCKTYPE_D3PCLK1|RCC_CLOCKTYPE_D1PCLK1;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.SYSCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB3CLKDivider = RCC_APB3_DIV2;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_APB1_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_APB2_DIV2;
  RCC_ClkInitStruct.APB4CLKDivider = RCC_APB4_DIV2;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_4) != HAL_OK)
  {
    Error_Handler();
  }
  __HAL_RCC_PLL2CLKOUT_ENABLE(RCC_PLL2_DIVP);
  HAL_RCC_MCOConfig(RCC_MCO2, RCC_MCO2SOURCE_PLL2PCLK, RCC_MCODIV_4);
}

/**
  * @brief Peripherals Common Clock Configuration
  * @retval None
  */
void PeriphCommonClock_Config(void)
{

  /** Enables PLL2P clock output
  */
  __HAL_RCC_PLL2_CONFIG(25, 192, 2, 2, 2);
  __HAL_RCC_PLL2_VCIRANGE(RCC_PLL2VCIRANGE_0);
  __HAL_RCC_PLL2_VCORANGE(RCC_PLL2VCOWIDE);
  __HAL_RCC_PLL2_ENABLE();
}

/* USER CODE BEGIN 4 */
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{


		if (huart->Instance == USART1 && (send_ready == 0)) {
			switch (rx_data) {

			// keyboard
			case 'a':
				osMessagePut(modeEventMsgBox, S_KEYBOARD_MODE, 0);
				osMessagePut(keyBoardEventMsgBox, EVENT_LEFT, 0);
				break;
			case 'b':
				osMessagePut(modeEventMsgBox, S_KEYBOARD_MODE, 0);
				osMessagePut(keyBoardEventMsgBox, EVENT_RIGHT, 0);
				break;
			case 'c':
				osMessagePut(modeEventMsgBox, S_KEYBOARD_MODE, 0);
				osMessagePut(keyBoardEventMsgBox, EVENT_UP, 0);
				break;
			case 'd':
				osMessagePut(modeEventMsgBox, S_KEYBOARD_MODE, 0);
				osMessagePut(keyBoardEventMsgBox, EVENT_DOWN, 0);
				break;
			case 'e':
				osMessagePut(modeEventMsgBox, S_KEYBOARD_MODE, 0);
				osMessagePut(keyBoardEventMsgBox, EVENT_ZERO, 0);
				break;
			case 'f':
				osMessagePut(modeEventMsgBox, S_KEYBOARD_MODE, 0);
				osMessagePut(keyBoardEventMsgBox, EVENT_ONE, 0);
				break;
			case 'g':
				osMessagePut(modeEventMsgBox, S_KEYBOARD_MODE, 0);
				osMessagePut(keyBoardEventMsgBox, EVENT_TWO, 0);
				break;
			case 'h':
				osMessagePut(modeEventMsgBox, S_KEYBOARD_MODE, 0);
				osMessagePut(keyBoardEventMsgBox, EVENT_THREE, 0);
				break;
			case 'i':
				osMessagePut(modeEventMsgBox, S_KEYBOARD_MODE, 0);
				osMessagePut(keyBoardEventMsgBox, EVENT_FOUR, 0);
				break;
			case 'j':
				osMessagePut(modeEventMsgBox, S_KEYBOARD_MODE, 0);
				osMessagePut(keyBoardEventMsgBox, EVENT_FIVE, 0);
				break;
			case 'k':
				osMessagePut(modeEventMsgBox, S_KEYBOARD_MODE, 0);
				osMessagePut(keyBoardEventMsgBox, EVENT_SIX, 0);
				break;
			case 'l':
				osMessagePut(modeEventMsgBox, S_KEYBOARD_MODE, 0);
				osMessagePut(keyBoardEventMsgBox, EVENT_SEVEN, 0);
				break;
			case 'm':
				osMessagePut(modeEventMsgBox, S_KEYBOARD_MODE, 0);
				osMessagePut(keyBoardEventMsgBox, EVENT_EIGHT, 0);
				break;
			case 'n':
				osMessagePut(modeEventMsgBox, S_KEYBOARD_MODE, 0);
				osMessagePut(keyBoardEventMsgBox, EVENT_NINE, 0);
				break;

			// motor
			case 'C':
				osMessagePut(modeEventMsgBox, S_MOTOR_MODE, 0);
				osMessagePut(servoMotorEventMsgBox, EVENT_SERVO_RIGHT, 0);
				break;
			case 'D':
				osMessagePut(modeEventMsgBox, S_MOTOR_MODE, 0);
				osMessagePut(servoMotorEventMsgBox, EVENT_SERVO_LEFT, 0);
				break;
			default:break;
			}
			HAL_UART_Receive_IT(&huart1, &rx_data, 1);
		}

}



/* USER CODE END 4 */

 /* MPU Configuration */

void MPU_Config(void)
{
  MPU_Region_InitTypeDef MPU_InitStruct = {0};

  /* Disables the MPU */
  HAL_MPU_Disable();

  /** Initializes and configures the Region and the memory to be protected
  */
  MPU_InitStruct.Enable = MPU_REGION_ENABLE;
  MPU_InitStruct.Number = MPU_REGION_NUMBER0;
  MPU_InitStruct.BaseAddress = 0x0;
  MPU_InitStruct.Size = MPU_REGION_SIZE_4GB;
  MPU_InitStruct.SubRegionDisable = 0x87;
  MPU_InitStruct.TypeExtField = MPU_TEX_LEVEL0;
  MPU_InitStruct.AccessPermission = MPU_REGION_NO_ACCESS;
  MPU_InitStruct.DisableExec = MPU_INSTRUCTION_ACCESS_DISABLE;
  MPU_InitStruct.IsShareable = MPU_ACCESS_SHAREABLE;
  MPU_InitStruct.IsCacheable = MPU_ACCESS_NOT_CACHEABLE;
  MPU_InitStruct.IsBufferable = MPU_ACCESS_NOT_BUFFERABLE;

  HAL_MPU_ConfigRegion(&MPU_InitStruct);

  /** Initializes and configures the Region and the memory to be protected
  */
  MPU_InitStruct.Number = MPU_REGION_NUMBER4;
  MPU_InitStruct.BaseAddress = 0xC0000000;
  MPU_InitStruct.Size = MPU_REGION_SIZE_32MB;
  MPU_InitStruct.SubRegionDisable = 0x0;
  MPU_InitStruct.TypeExtField = MPU_TEX_LEVEL1;
  MPU_InitStruct.AccessPermission = MPU_REGION_FULL_ACCESS;

  HAL_MPU_ConfigRegion(&MPU_InitStruct);
  /* Enables the MPU */
  HAL_MPU_Enable(MPU_PRIVILEGED_DEFAULT);

}

/**
  * @brief  Period elapsed callback in non blocking mode
  * @note   This function is called  when TIM17 interrupt took place, inside
  * HAL_TIM_IRQHandler(). It makes a direct call to HAL_IncTick() to increment
  * a global variable "uwTick" used as application time base.
  * @param  htim : TIM handle
  * @retval None
  */
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
  /* USER CODE BEGIN Callback 0 */
	static uint16_t us_counter = 0;

	if (htim->Instance == TIM2 && flag == 1) {
		if (++us_counter >= 20000) {  // 1us * 20000 = 20ms
			us_counter = 0;
			flag = 0;
			send_ready=1;
			HAL_TIM_Base_Stop(&htim2);
		}
	}



  /* USER CODE END Callback 0 */
  if (htim->Instance == TIM17)
  {
    HAL_IncTick();
  }
  /* USER CODE BEGIN Callback 1 */

  /* USER CODE END Callback 1 */
}

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
	/* User can add his own implementation to report the HAL error return state */
	__disable_irq();
	while (1)
	{
	}
  /* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
	/* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
