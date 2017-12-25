//
//  CSEncodedAudioReceiverProtocol.h
//  CocoaSplit
//
//  Created by Zakk on 6/26/17.
//

#import <Foundation/Foundation.h>

@protocol CSEncodedAudioReceiverProtocol <NSObject>
-(void)captureOutputAudio:(id)fromDevice didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end
