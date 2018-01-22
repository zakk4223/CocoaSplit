//
//  CSNDIOutput.h
//  CSNewTekNDIStreamServicePlugin
//
//  Created by Zakk on 1/21/18.
//

#import "CSOutputBase.h"
#import "Processing.NDI.Lib.h"
#import "TPCircularBuffer.h"


@interface CSNDIOutput : CSOutputBase
{
    NDIlib_v3 *_dispatch;
    NDIlib_send_instance_t _ndi_send;
    CapturedFrameData *_last_frame;
    CapturedFrameData *_send_frame;
    
    NSString *_name;
}

-(instancetype) initWithName:(NSString *)name;


@end

