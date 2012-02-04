#include "usb_serial.h"

#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "usb_core.h"
#include "usb_dcd_int.h"
#include "usbd_cdc_core.h"
#include "usbd_cdc_vcp.h"
#include "usbd_core.h"
#include "usbd_desc.h"
#include "usbd_usr.h"

////////////////////
// Setup function //
////////////////////

#ifdef USB_OTG_HS_INTERNAL_DMA_ENABLED
  #if defined ( __ICCARM__ ) /*!< IAR Compiler */
    #pragma data_alignment = 4   
  #endif
#endif /* USB_OTG_HS_INTERNAL_DMA_ENABLED */
__ALIGN_BEGIN USB_OTG_CORE_HANDLE  USB_OTG_dev __ALIGN_END;

void UsbInit(void (*cb)(uint8_t c)) {
  USBD_Init(&USB_OTG_dev,
            USB_OTG_FS_CORE_ID,
            &USR_desc, 
            &USBD_CDC_cb, 
            &USR_cb);
}

void UsbSend(uint8_t c) {
  VCP_DataTx (&c, 1);
}

void HandleUsbInterrupt() {
  USBD_OTG_ISR_Handler (&USB_OTG_dev);
}
