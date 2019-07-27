//
//  CSScriptCommand.m
//  CocoaSplit
//
//  Created by Zakk on 5/29/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSScriptCommand.h"
#import "CaptureController.h"

@implementation CSScriptCommand


-(id)performDefaultImplementation
{

    NSScriptCommandDescription *desc = self.commandDescription;
    NSString *commandName = desc.commandName;
    
    if ([commandName isEqualToString:@"goLive"])
    {
        return [self goLive];
    } else if ([commandName isEqualToString:@"swapLayouts"]) {
        return [self swapLayouts];
    } else if ([commandName isEqualToString:@"startStream"]) {
        return [self startStream];
    } else if ([commandName isEqualToString:@"stopStream"]) {
        return [self stopStream];
    } else if ([commandName isEqualToString:@"instantRecord"]) {
        return [self instantRecord];
    } else if ([commandName isEqualToString:@"hideStagingView"]) {
        return [self hideStagingView];
    } else if ([commandName isEqualToString:@"showStagingView"]) {
        return [self showStagingView];
    } else if ([commandName isEqualToString:@"toggleStagingView"]) {
        return [self toggleStagingView];
    } else if ([commandName isEqualToString:@"startRecording"]) {
        return [self startRecording];
    } else if ([commandName isEqualToString:@"stopRecording"]) {
        return [self stopRecording];
    } else if ([commandName isEqualToString:@"toggleRecording"]) {
        return [self toggleRecording];
    }
    return nil;
}




-(id) startRecording
{
    [CaptureController.sharedCaptureController startRecording];
    return nil;
}

-(id) stopRecording
{
    [CaptureController.sharedCaptureController stopRecording];
    return nil;
}

-(id) toggleRecording
{
    bool isRecording = CaptureController.sharedCaptureController.mainRecordingActive;
    if (isRecording)
    {
        [self stopRecording];
    } else {
        [self startRecording];
    }
    
    return nil;
}

-(id) hideStagingView
{
    [[CaptureController sharedCaptureController] hideStagingView];
    return nil;
}

-(id) showStagingView
{
    [[CaptureController sharedCaptureController] showStagingView];
    return nil;
}

-(id) toggleStagingView
{
    [[CaptureController sharedCaptureController] stagingViewToggle:nil];
    return nil;
}


-(id) instantRecord
{
    [[CaptureController sharedCaptureController] doInstantRecord:nil];
    return nil;
}


-(id) startStream
{
    [[CaptureController sharedCaptureController] startStream];
    return nil;
}

-(id) stopStream
{
    [[CaptureController sharedCaptureController] stopStream];
    return nil;
}


-(id)goLive
{
    [[CaptureController sharedCaptureController] stagingGoLive:nil];
    return nil;
}


-(id)swapLayouts
{
    [[CaptureController sharedCaptureController] swapStagingAndLive:nil];
    return nil;
}

@end
