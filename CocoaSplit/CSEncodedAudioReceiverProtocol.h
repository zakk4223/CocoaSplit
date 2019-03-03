//
//  CSEncodedAudioReceiverProtocol.h
//  CocoaSplit
//
//  Created by Zakk on 6/26/17.
//

#import <Foundation/Foundation.h>

@protocol CSEncodedAudioReceiverProtocol <NSObject>
-(void)captureOutputAudio:(NSString *)withTag didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;
-(void)captureOutputAudio:(NSString *)withTag didOutputPCMSampleBuffer:(CMSampleBufferRef)sampleBuffer;


@end
