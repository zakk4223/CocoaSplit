//
//  OutputDestination.h
//  H264Streamer
//
//  Created by Zakk on 9/16/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFMpegTask.h"


@interface OutputDestination : NSObject <NSCoding>

{
    NSString *_destination;
    NSString *_name;
    BOOL _active;
    
}


@property (strong) NSString *server_name;
@property (strong) NSString *type_name;
@property (strong) NSString *destination;
@property (strong) NSString *output_format;
@property (strong) NSString *stream_key;
@property (strong) FFMpegTask *ffmpeg_out;
@property (strong) id<ControllerProtocol> settingsController;

@property  BOOL active;




-(id)initWithType:(NSString *)type;
-(void)stopOutput;
-(void) attachOutput:(id<ControllerProtocol>) settingsController;



@end

