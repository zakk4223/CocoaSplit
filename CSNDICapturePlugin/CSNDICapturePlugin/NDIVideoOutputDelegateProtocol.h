//
//  NDIVideoOutputDelegateProtocol.h
//  CSNDICapturePlugin
//
//  Created by Zakk on 1/18/18.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
@class CSNDIReceiver;

@protocol NDIVideoOutputDelegateProtocol <NSObject>


-(void)NDIVideoOutput:(CMSampleBufferRef)sampleBuffer fromReceiver:(CSNDIReceiver *)fromReceiver;

@end
