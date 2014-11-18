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
        _pcmData = NULL;
    }
    
    return self;
}

-(void)preallocateBufferList:(AudioBufferList *)bufferList
{
    //To avoid doing mallocs every cycle, the AU callback asks us to preallocate memory based on the size of the buffers it receives
    //If the size changes, we only re-allocate if it is bigger than our preallocated size. If it's smaller we
    //just "waste" the memory and leave it be.
    
    int bufferSize = bufferList->mBuffers[0].mDataByteSize;
    
    if (bufferSize > self.preallocatedBuffersize)
    {
        NSLog(@"ALLOCATING FOR %d", bufferSize);
        _pcmData = malloc(bufferSize*2); //Assuming deinterleaved 2-ch, so allocate enough space for both channels
        self.preallocatedBuffersize = bufferSize;
    }
    
}
-(void) enqueuePCM:(AudioBufferList *)pcmBuffer atTime:(const AudioTimeStamp *)atTime
{
    
    
    
    [self preallocateBufferList:pcmBuffer];
    
    if (!self.encoderStarted)
    {
        [self setupEncoder];
        self.encoderStarted = YES;
    }
    
    
    //for now assume Float32, 2 channel, non-interleaved. We have to interleave it outselves here.
    
    
    __block UInt32 bufsize = self.preallocatedBuffersize*2; //This should be equal to 2x pcmBuffer->mBuffers[0].mDataByteSize
    
    UInt32 orig_size = bufsize;
    __block UInt32 wrote_bytes = 0;
    
    
    //NSLog(@"ENCODE BUFFER SIZE %u", (unsigned int)bufsize);
    
    
    AudioBuffer buffer0 = pcmBuffer->mBuffers[0];
    AudioBuffer buffer1 = pcmBuffer->mBuffers[1];
    Float32 *data0 = buffer0.mData;
    Float32 *data1 = buffer1.mData;
    
    Float32 *writebuf = _pcmData;
    int channel_size = buffer0.mDataByteSize/sizeof(Float32);
    int i, u;
    for(i=u=0; i < channel_size; i++,u+=2)
    {
        writebuf[u] = data0[i];
        writebuf[u+1] = data1[i];
    }
    
    __block Float32 *readbuf = _pcmData;
    
    
    //Do the actual compression on another thread so as not to block AudioUnit callbacks
    
    dispatch_async(encoderQueue, ^{
        UInt32 num_packets = 1;

        UInt32 outstatus = 0;

        UInt32 buffer_size = maxOutputSize;
        
        while (true)
        {
            
            void *aacBuffer = malloc(maxOutputSize);

            OSStatus err;
            
            err = AudioCodecAppendInputData(aacCodec, readbuf, &bufsize, NULL, NULL);
            
            
            wrote_bytes += bufsize;
            
            readbuf += bufsize/sizeof(Float32);
            //reset bufsize for next loop
            bufsize = orig_size - wrote_bytes;
            
            AudioStreamPacketDescription packetDesc;
            
            
            
            err = AudioCodecProduceOutputPackets(aacCodec, aacBuffer, &buffer_size, &num_packets, &packetDesc, &outstatus);
            
            if (err != 0)
            {
                NSLog(@"CODEC PRODUCE OUTPUT ERROR IS %@", [[NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil] description]);
                
            }
            
            
            if (outstatus == kAudioCodecProduceOutputPacketNeedsMoreInputData)
            {
                break;
            }


            if (self.encodedReceiver && buffer_size)
            {
                CMTime ptsTime = CMTimeMake(outputSampleCount, self.sampleRate);
                CMTime duration = CMTimeMake(1024, self.sampleRate);
                
                CMSampleTimingInfo timeInfo;
                
                timeInfo.duration = duration;
                timeInfo.presentationTimeStamp = ptsTime;
                timeInfo.decodeTimeStamp = kCMTimeInvalid;
                
                CMSampleBufferRef newSampleBuf;
                CMSampleBufferRef timingSampleBuf;
                CMBlockBufferRef bufferRef;
                
                
                CMBlockBufferCreateWithMemoryBlock(NULL, aacBuffer, buffer_size, NULL, NULL, 0, buffer_size, 0, &bufferRef);
                
                
                CMAudioSampleBufferCreateReadyWithPacketDescriptions(kCFAllocatorDefault, bufferRef, cmFormat, 1, ptsTime, &packetDesc, &newSampleBuf);
                
                CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault, newSampleBuf, 1, &timeInfo, &timingSampleBuf);
                CFRelease(newSampleBuf);
                
                
                [self.encodedReceiver captureOutputAudio:nil didOutputSampleBuffer:timingSampleBuf];
                
            }
            

            
            buffer_size = maxOutputSize;
            num_packets = 1;

            outputSampleCount += 1024;
            if (wrote_bytes >= orig_size)
            {
                break;
            }
            
            
        }
        
        
    });
    
    
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


    
    
   // NSLog(@"CODEC INIT %d COOKIE SIZE %u MAX %u", err, magicCookie->mMagicCookieSize, cookiestructsize);
    outputSampleCount = 0;
    
    
    CMAudioFormatDescriptionCreate(kCFAllocatorDefault, &outasbd, 0, NULL, cookiestructsize ,magicCookie, NULL, &cmFormat);
    
    
    CFDictionaryRef encoderState;
    
    cookiestructsize = sizeof(CFDictionaryRef);
    
    AudioCodecGetProperty(aacCodec, kAudioCodecPropertySettings, &cookiestructsize, &encoderState);
    //NSLog(@"ENCODER STATE %@", encoderState);
    
    
    
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

