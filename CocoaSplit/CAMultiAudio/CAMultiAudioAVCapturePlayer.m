//
//  CAMultiAudioAVCapturePlayer.m
//  CocoaSplit
//
//  Created by Zakk on 11/14/14.
//

#import "CAMultiAudioAVCapturePlayer.h"
#import "CAMultiAudioMatrixMixerWindowController.h"

@implementation CAMultiAudioAVCapturePlayer



-(instancetype)initWithDevice:(AVCaptureDevice *)avDevice
{
    if (self = [super init])
    {
        
        self.captureDevice = avDevice;
        //self.sampleRate = withFormat.sampleRate;
        self.name = avDevice.localizedName;
        //self.nodeUID = avDevice.uniqueID;
        self.systemDevice = YES;
        self.deviceUID = avDevice.uniqueID;
        
    }
    return self;
}

-(AVAudioFormat *)inputFormat
{
    if (self.captureDevice)
    {
        CMFormatDescriptionRef sDescr = self.captureDevice.activeFormat.formatDescription;
        
        
        AVAudioFormat *retFmt = [[AVAudioFormat alloc] initWithCMAudioFormatDescription:sDescr];
        return retFmt;
        
    }
    
    return nil;

}


-(void)setEnabled:(bool)enabled
{
    super.enabled = enabled;
    if (!self.graph)
    {
        return;
    }
    
    if (enabled)
    {
        [self attachCaptureSession];
    } else {
        [self detachCaptureSession];
    }
}




-(void)detachCaptureSession
{
    if (self.avfCapture)
    {
        [self.avfCapture stopCaptureSession];
        self.avfCapture = nil;
    }
}

-(void)attachCaptureSession
{
    
    
    
    if (!self.avfCapture)
    {
        AVFAudioCapture *newAC = [[AVFAudioCapture alloc] initForAudioEngine:self.captureDevice];
        self.avfCapture = newAC;        //return;
    }
    

    self.avfCapture.multiInput = self;
    [self.avfCapture startCaptureSession:nil];
}


-(void)resetFormat:(AudioStreamBasicDescription *)format
{
    self.sampleRate = format->mSampleRate;
    AudioStreamBasicDescription asbd;
    UInt32 asbdSize = sizeof(asbd);
    memcpy(&asbd, format, sizeof(asbd));

    asbd.mChannelsPerFrame = self.channelCount;
    
    AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &asbd, asbdSize);
    if (self.avfCapture)
    {
        //self.avfCapture.audioSamplerate = self.sampleRate;
        
        [self.avfCapture stopAudioCompression];
        [self.avfCapture setupAudioCompression];
    }
}


-(void)resetSamplerate:(UInt32)sampleRate
{
    if (self.avfCapture)
    {
        //self.avfCapture.audioSamplerate = sampleRate;
    
        [self.avfCapture stopAudioCompression];
        [self.avfCapture setupAudioCompression];
    }
}


-(void)setChannelCount:(int)channelCount
{
    super.channelCount = channelCount;
}



/*
-(AudioStreamBasicDescription *)inputFormat
{
    if (self.captureDevice)
    {
        CMFormatDescriptionRef sDescr = self.captureDevice.activeFormat.formatDescription;
        
        
        const AudioStreamBasicDescription *asbd =  CMAudioFormatDescriptionGetStreamBasicDescription(sDescr);
        return (AudioStreamBasicDescription *)asbd;
        
    }
    
    return NULL;

}

-(void)setInputFormat:(AudioStreamBasicDescription *)inputFormat
{
    return;
}
*/


-(int)channelCount
{
    if (self.captureDevice)
    {
        CMFormatDescriptionRef sDescr = self.captureDevice.activeFormat.formatDescription;
        
        
        const AudioStreamBasicDescription *asbd =  CMAudioFormatDescriptionGetStreamBasicDescription(sDescr);
        
        

        if (asbd)
        {
            return asbd->mChannelsPerFrame;
        }
    }
    
    return super.channelCount;
}


@end
