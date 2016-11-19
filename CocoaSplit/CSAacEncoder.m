//
//  CSAacEncoder.m
//  CocoaSplit
//
//  Created by Zakk on 11/9/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CSAacEncoder.h"
#import "CaptureController.h"


@implementation CSAacEncoder



-(instancetype)init
{
    if (self = [super init])
    {
        encoderQueue = dispatch_queue_create("CSAACEncoderQueue", NULL);
        _aSemaphore = dispatch_semaphore_create(0);
        
        
    }
    
    return self;
}

-(void)setupEncoderBuffer
{
    TPCircularBufferInit(&_inputBuffer, self.inputASBD->mBytesPerFrame * 4096);
    TPCircularBufferInit(&_scratchBuffer, self.inputASBD->mBytesPerFrame * 4096);

    dispatch_async(encoderQueue, ^{[self encodeAudio];});
}


-(void) enqueuePCM:(AudioBufferList *)pcmBuffer atTime:(const AudioTimeStamp *)atTime
{
    TPCircularBufferCopyAudioBufferList(&_inputBuffer, pcmBuffer, atTime, kTPCircularBufferCopyAll, NULL);
    dispatch_semaphore_signal(_aSemaphore);
}


-(void)encodeAudio
{
    
    
    if (!self.encoderStarted)
    {
        [self setupEncoder];
        self.encoderStarted = YES;
    }
    
    while (1)
    {
        dispatch_semaphore_wait(_aSemaphore, DISPATCH_TIME_FOREVER);
        
        
        
        while (TPCircularBufferPeek(&_inputBuffer, NULL, self.inputASBD) >= 1024)
        {
            AudioBufferList *inBuffer = TPCircularBufferPrepareEmptyAudioBufferListWithAudioFormat(&_scratchBuffer, self.inputASBD, 1024, NULL);
            UInt32 inFrameCnt = 1024;
            AudioTimeStamp atTime;
            
            TPCircularBufferDequeueBufferListFrames(&_inputBuffer, &inFrameCnt, inBuffer, &atTime, self.inputASBD);
            
            Float32 *writebuf = malloc(inBuffer->mBuffers[0].mDataByteSize*2);
            AudioBuffer buffer0 = inBuffer->mBuffers[0];
            AudioBuffer buffer1 = inBuffer->mBuffers[1];
            Float32 *data0 = buffer0.mData;
            Float32 *data1 = buffer1.mData;
            int channel_size = buffer0.mDataByteSize/sizeof(Float32);
            int i, u;
            for(i=u=0; i < channel_size; i++,u+=2)
            {
                writebuf[u] = data0[i];
                writebuf[u+1] = data1[i];
            }
            
            @autoreleasepool {
                
                UInt32 num_packets = 1;
                UInt32 outstatus = 0;
                
                
                
                
                
                
                UInt32 bufsize =  inBuffer->mBuffers[0].mDataByteSize*2;//This should be equal to 2x pcmBuffer->mBuffers[0].mDataByteSize
                
                
                
                
                
                UInt32 buffer_size = maxOutputSize;
                
                void *aacBuffer = malloc(maxOutputSize);
                
                
                OSStatus err;
                
                err = AudioCodecAppendInputData(aacCodec, writebuf, &bufsize, NULL, NULL);
                
                free(writebuf);
                AudioStreamPacketDescription packetDesc;
                
                
                
                err = AudioCodecProduceOutputPackets(aacCodec, aacBuffer, &buffer_size, &num_packets, &packetDesc, &outstatus);
                
                if (err != 0)
                {
                    NSLog(@"CODEC PRODUCE OUTPUT ERROR IS %@", [[NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil] description]);
                    
                }
                
                
                if (outstatus == kAudioCodecProduceOutputPacketNeedsMoreInputData)
                {
                    NSLog(@"NEED MORE INPUT DATA");
                    free(aacBuffer);
                    break;
                }
                
                
                if (self.encodedReceiver && buffer_size)
                {
                    
                    
                    CMTime duration = CMTimeMake(1024, self.sampleRate);
                    uint64_t mach_now = atTime.mHostTime;
                    
                    double abs_pts = (double)mach_now/NSEC_PER_SEC;
                    
                    CMTime ptsTime = CMTimeMake(abs_pts*1000, 1000);
                    
                    CMSampleTimingInfo timeInfo;
                    
                    timeInfo.duration = duration;
                    timeInfo.presentationTimeStamp = ptsTime;
                    timeInfo.decodeTimeStamp = kCMTimeInvalid;
                    
                    CMSampleBufferRef newSampleBuf;
                    CMSampleBufferRef timingSampleBuf;
                    CMBlockBufferRef bufferRef;
                    
                    
                    CMBlockBufferCreateWithMemoryBlock(NULL, aacBuffer, buffer_size, kCFAllocatorMalloc, NULL, 0, buffer_size, 0, &bufferRef);
                    
                    
                    CMAudioSampleBufferCreateWithPacketDescriptions(kCFAllocatorDefault, bufferRef, YES, NULL, NULL, cmFormat, 1, ptsTime, &packetDesc, &newSampleBuf);
                    
                    
                    CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault, newSampleBuf, 1, &timeInfo, &timingSampleBuf);
                    
                    CFRelease(newSampleBuf);
                    //The sample buffer retains the block buffer when it is handed over to it, we can release ours.
                    CFRelease(bufferRef);
                    
                    
                    [self.encodedReceiver captureOutputAudio:nil didOutputSampleBuffer:timingSampleBuf];
                    
                    //Individual video compressors retain the buffer until they push it to their output, we can release it now.
                    CFRelease(timingSampleBuf);
                    
                } else {
                    free(aacBuffer);
                }
                
                
                
                buffer_size = maxOutputSize;
                num_packets = 1;
                
                outputSampleCount += 1024;
            }
            
        }
    }
}

-(void) setupEncoder
{
    //create the input format.
    
     AudioStreamBasicDescription inputFormat = {0};
    
    
    inputFormat.mSampleRate = self.sampleRate;
    inputFormat.mFormatID = kAudioFormatLinearPCM;
    inputFormat.mFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsFloat;
    inputFormat.mChannelsPerFrame = 2;
    inputFormat.mBitsPerChannel = 32;
    inputFormat.mBytesPerFrame = 8;
    inputFormat.mBytesPerPacket = 8;
    inputFormat.mFramesPerPacket = 1;
    
    AudioStreamBasicDescription outputFormat = {0};
    
    outputFormat.mSampleRate = self.sampleRate;
    outputFormat.mFormatID = kAudioFormatMPEG4AAC;
    outputFormat.mChannelsPerFrame = 2;
    outputFormat.mBytesPerPacket = 0;
    outputFormat.mBytesPerFrame = 0;
    outputFormat.mFramesPerPacket = 1024;
    outputFormat.mBitsPerChannel = 0;
    
    
    OSStatus err;
    AudioComponentDescription acDesc = {0};
    
    acDesc.componentType = kAudioEncoderComponentType;
    acDesc.componentSubType = kAudioFormatMPEG4AAC;
    
   
    
    AudioComponent aComp = NULL;
    
    aComp = AudioComponentFindNext(aComp, &acDesc);
    AudioComponentInstanceNew(aComp, &aacCodec);
    
    
    
    UInt32 control_mode = kAudioCodecBitRateControlMode_LongTermAverage;
    
    
    UInt32 getoutputsize = sizeof(UInt32);
    Boolean writeable;
    UInt32 cookiestructsize;
    AudioStreamBasicDescription outasbd;
    UInt32 outasbd_size = sizeof(outasbd);
    
    
    err = AudioCodecSetProperty(aacCodec, kAudioCodecPropertyBitRateControlMode, sizeof(control_mode), &control_mode);
    if (err)
    {
        NSLog(@"SET TARGET BITRATE CONTROL %d", err);
    }
    
    err = AudioCodecSetProperty(aacCodec, kAudioCodecPropertyCurrentTargetBitRate, sizeof(_bitRate), &_bitRate);
    if (err)
    {
        NSLog(@"SET TARGET BITRATE %d", err);
    }


    err = AudioCodecInitialize(aacCodec, &inputFormat, &outputFormat, NULL, 0);
    if (err)
    {
        NSLog(@"CODEC INITIALIZE %@", [[NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil] description]);
    }


    err = AudioCodecGetProperty(aacCodec, kAudioCodecPropertyCurrentOutputFormat, &outasbd_size, &outasbd);
    
    
    err = AudioCodecGetPropertyInfo(aacCodec, kAudioCodecPropertyMagicCookie, &cookiestructsize, &writeable);

    err = AudioCodecGetProperty(aacCodec, kAudioCodecPropertyMaximumPacketByteSize, &getoutputsize, &maxOutputSize);
    magicCookie = malloc(cookiestructsize);

    
    err = AudioCodecGetProperty(aacCodec, kAudioCodecPropertyMagicCookie, &cookiestructsize, magicCookie);


    
    
    outputSampleCount = 0;
    
    
    CMAudioFormatDescriptionCreate(kCFAllocatorDefault, &outasbd, 0, NULL, cookiestructsize ,magicCookie, NULL, &cmFormat);
    
    
    CFDictionaryRef encoderState;
    
    cookiestructsize = sizeof(CFDictionaryRef);
    
    AudioCodecGetProperty(aacCodec, kAudioCodecPropertySettings, &cookiestructsize, &encoderState);
    return;
    
}

-(void)stopEncoder
{
    if (self.encoderStarted == YES)
    {
        self.encoderStarted = NO;
        AudioCodecUninitialize(aacCodec);
        free(magicCookie);
    }
    
}
-(void)dealloc
{
    [self stopEncoder];
    AudioComponentInstanceDispose(aacCodec);
    
}


@end

