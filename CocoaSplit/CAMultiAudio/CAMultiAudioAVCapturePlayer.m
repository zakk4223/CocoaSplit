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
        self.name = avDevice.localizedName;
        //self.nodeUID = avDevice.uniqueID;
        self.systemDevice = YES;
        self.deviceUID = avDevice.uniqueID;
        
    }
    return self;
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
        AVFAudioCapture *newAC = [[AVFAudioCapture alloc] initForAudioEngine:self.captureDevice sampleRate:self.sampleRate];
        self.avfCapture = newAC;        //return;
    }
    

    self.avfCapture.multiInput = self;
    [self.avfCapture startCaptureSession:nil];
}


-(void)setChannelCount:(int)channelCount
{
    super.channelCount = channelCount;
}


-(AVAudioFormat *)inputFormat
{
    if (self.captureDevice)
    {
        CMFormatDescriptionRef sDescr = self.captureDevice.activeFormat.formatDescription;
        
        
        AVAudioFormat *tmpFmt = [[AVAudioFormat alloc] initWithCMAudioFormatDescription:sDescr];
        AVAudioFormat *retFmt = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:tmpFmt.sampleRate channelLayout:tmpFmt.channelLayout];
        return retFmt;
        
    }
    
    return nil;

}

-(void)dealloc
{
    NSLog(@"DEALLOC AVCAPTURE PLAYER");
}
@end
