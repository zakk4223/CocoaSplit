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
        
    }
    
    return self;
}


-(void) enqueuePCM:(AVAudioPCMBuffer *)pcmBuffer atTime:(AVAudioTime *)atTime
{
    
    dispatch_async(encoderQueue, ^{
    
        if (!self.encoderStarted)
        {
            [self setupEncoder];
            self.encoderStarted = YES;
        }
        
        
        //for now assume Float32, 2 channel, non-interleaved. We have to interleave it outselves here.
        
        NSLog(@"PCM BUFFER %@ FRAMES %d", pcmBuffer.format, pcmBuffer.frameLength);
        
        OSStatus err;
        size_t channel_size = pcmBuffer.frameLength;
        UInt32 bufsize = (UInt32)channel_size*pcmBuffer.format.channelCount*4;
        bufsize += leftover_size;
        UInt32 orig_size = bufsize;
        UInt32 wrote_bytes = 0;
        
        
        //NSLog(@"ENCODE BUFFER SIZE %u", (unsigned int)bufsize);
        Float32 *tmpbuf = malloc(bufsize);
        Float32 *readbuf = tmpbuf;
        
        
        const AudioBufferList *bufList = pcmBuffer.audioBufferList;
        AudioBuffer buffer0 = bufList->mBuffers[0];
        AudioBuffer buffer1 = bufList->mBuffers[1];
        Float32 *data0 = buffer0.mData;
        Float32 *data1 = buffer1.mData;
        
        
        if (leftover_size > 0)
        {
            memcpy(tmpbuf, PCMleftover, leftover_size);
        }
        
        Float32 *writebuf = tmpbuf + leftover_size;
        leftover_size = 0;
        
        for(int i=0; i < channel_size; i++)
        {
            writebuf[i] = data0[i];
            writebuf[i+1] = data1[i];
        }
        
        
        UInt32 buffer_size = maxOutputSize;
        UInt32 num_packets = 1;
        UInt32 outstatus = 0;
        
        while (true)
        {
            void *aacBuffer = malloc(maxOutputSize);

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
            
            if (outstatus == kAudioCodecProduceOutputPacketNeedsMoreInputData || wrote_bytes >= orig_size)
            {
                break;
            }

            
            if (self.encodedReceiver)
            {
                CMTime ptsTime = CMTimeMake(outputSampleCount, self.sampleRate);
                
                CMSampleBufferRef newSampleBuf;
                CMBlockBufferRef bufferRef;
                
                CMBlockBufferCreateWithMemoryBlock(NULL, aacBuffer, buffer_size, NULL, NULL, 0, buffer_size, 0, &bufferRef);
                
                
                CMAudioSampleBufferCreateReadyWithPacketDescriptions(kCFAllocatorDefault, bufferRef, cmFormat, 1, ptsTime, &packetDesc, &newSampleBuf);
                
                [self.encodedReceiver captureOutputAudio:nil didOutputSampleBuffer:newSampleBuf];
                
            }
            
            
            
            
            buffer_size = maxOutputSize;
            num_packets = 1;

            outputSampleCount += 1024;
            
            
        }
        
        //NSLog(@"WROTE BYTES %d ORIG_SIZE %d", wrote_bytes, orig_size);
        
        if (wrote_bytes < orig_size)
        {
            leftover_size = orig_size-bufsize;
            //NSLog(@"LEFTOVER BYTES %zu", leftover_size);
            memcpy(PCMleftover, readbuf, leftover_size);
            
        }
        
        
        
        
        
        free(tmpbuf);

    });
    
    
}


-(void) setupEncoder
{
    //create the input format.
    
    AVAudioFormat *inputFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:self.sampleRate channels:2 interleaved:YES];
    
    outputFormat = [[AVAudioFormat alloc] initWithSettings:@{AVFormatIDKey: [NSNumber numberWithInt:kAudioFormatMPEG4AAC],
                                                                            AVSampleRateKey: @(self.sampleRate),
                                                                            AVNumberOfChannelsKey: @2
                                                                            
                                                                        }];
    
    
    
    
    OSStatus err;
    AudioComponentDescription acDesc = {0};
    
    acDesc.componentType = kAudioEncoderComponentType;
    acDesc.componentSubType = kAudioFormatMPEG4AAC;
    
   
    
    AudioComponent aComp = NULL;
    
    /*
    while ((aComp = (AudioComponentFindNext(aComp, &acDesc))))
    {
        CFStringRef aName;
        AudioComponentCopyName(aComp, &aName);
        NSLog(@"COMPONENT NAME %@", aName);
        
    }
    
     */
    
    aComp = AudioComponentFindNext(aComp, &acDesc);
    AudioComponentInstanceNew(aComp, &aacCodec);
    
    err = AudioCodecInitialize(aacCodec, inputFormat.streamDescription, outputFormat.streamDescription, NULL, 0);
    
    
    UInt32 control_mode = kAudioCodecBitRateControlMode_VariableConstrained;
    
    
    UInt32 getoutputsize = sizeof(UInt32);
    Boolean writeable;
    UInt32 cookiestructsize;
    
    AudioCodecGetPropertyInfo(aacCodec, kAudioCodecPropertyMagicCookie, &cookiestructsize, &writeable);
    
    magicCookie = malloc(cookiestructsize);
    
    
    
    
    AudioCodecSetProperty(aacCodec, kAudioCodecPropertyCurrentTargetBitRate, sizeof(_bitRate), &_bitRate);
    AudioCodecSetProperty(aacCodec, kAudioCodecPropertyBitRateControlMode, sizeof(control_mode), &control_mode);
    
    
    AVAudioChannelLayout *stereoLayout = [AVAudioChannelLayout layoutWithLayoutTag:kAudioChannelLayoutTag_Stereo];
    
    UInt32 layout_size = sizeof(AudioChannelLayout);
    
    AudioCodecSetProperty(aacCodec, kAudioCodecPropertyCurrentInputChannelLayout, layout_size, stereoLayout.layout);
    AudioCodecSetProperty(aacCodec, kAudioCodecPropertyCurrentOutputChannelLayout, layout_size, stereoLayout.layout);

    
    AudioCodecGetProperty(aacCodec, kAudioCodecPropertyMaximumPacketByteSize, &getoutputsize, &maxOutputSize);
    err = AudioCodecGetProperty(aacCodec, kAudioCodecPropertyMagicCookie, &cookiestructsize, magicCookie);
    
    
    
   // NSLog(@"CODEC INIT %d COOKIE SIZE %u MAX %u", err, magicCookie->mMagicCookieSize, cookiestructsize);
    PCMleftover = malloc(8192);
    leftover_size = 0;
    outputSampleCount = 0;
    
    
    CMAudioFormatDescriptionCreate(kCFAllocatorDefault, outputFormat.streamDescription, 0, NULL, cookiestructsize ,magicCookie, NULL, &cmFormat);
    
    
    CFDictionaryRef encoderState;
    
    cookiestructsize = sizeof(CFDictionaryRef);
    
    AudioCodecGetProperty(aacCodec, kAudioCodecPropertySettings, &cookiestructsize, &encoderState);
    NSLog(@"ENCODER STATE %@", encoderState);
    
    
    
    return;
    
}

-(void)stopEncoder
{
    if (self.encoderStarted == YES)
    {
        self.encoderStarted = NO;
        AudioCodecUninitialize(aacCodec);
        free(PCMleftover);
        free(magicCookie);
    }
    
}
-(void)dealloc
{
    [self stopEncoder];
    AudioComponentInstanceDispose(aacCodec);
    
}


@end

