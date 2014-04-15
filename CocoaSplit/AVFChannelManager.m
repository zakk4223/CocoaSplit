//
//  AVFChannelManager.m
//  CocoaSplit
//
//  Created by Zakk on 4/6/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "AVFChannelManager.h"

@implementation AVFChannelManager


@synthesize dataOutput = _dataOutput;




-(id)init
{
    self = [super init];
    if (self)
    {
        self.channels = [[NSMutableArray alloc] init];
        
    }
    
    return self;
}


-(id)initWithPreviewOutput:(AVCaptureOutput *)previewOutput
{
    self = [self init];
    if (self)
    {
        self.previewOutput = previewOutput;
        [self setupPreviewChannels];
    }
    return self;
}




-(void)setupPreviewChannels
{
    
    AVCaptureConnection *previewConnection = [self.previewOutput.connections objectAtIndex:0];
    
    if (previewConnection)
    {
        for (AVCaptureAudioChannel *channel in previewConnection.audioChannels)
        {
            
            AVFAudioChannel *chantmp = [[AVFAudioChannel alloc] initWithMasterChannel:channel];
            [self.channels addObject:chantmp];
            
        }
 
    }
}

//preview channels have to be setup
-(void)setupOutputChannels
{
    AVCaptureConnection *outputConnection = [self.dataOutput.connections objectAtIndex:0];
    if (outputConnection)
    {
        
        for (int i = 0; i < [outputConnection.audioChannels count]; i++)
        {
            AVCaptureAudioChannel *avchannel = [outputConnection.audioChannels objectAtIndex:i];
            
            
            AVFAudioChannel *masterchannel = [self.channels objectAtIndex:i];
            
            if (avchannel && masterchannel)
            {
                [masterchannel addSlaveChannel:avchannel];
                
            }
        }
            
    }
}

-(AVCaptureOutput *)dataOutput
{
    return _dataOutput;
}

-(void)setDataOutput:(AVCaptureOutput *)dataOutput
{
    _dataOutput = dataOutput;
    [self setupOutputChannels];
}




@end
