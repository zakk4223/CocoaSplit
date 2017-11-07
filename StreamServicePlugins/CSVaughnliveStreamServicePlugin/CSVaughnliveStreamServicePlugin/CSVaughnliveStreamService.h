//
//  CSVaughnliveStreamService.h
//  CSVaughnliveStreamServicePlugin
//
//  Created by Zakk on 5/31/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSStreamServiceProtocol.h"

#define INGEST_URL @"rtmp://live.vaughnlive.tv:443/live/"


@interface CSVaughnliveStreamService : NSObject <CSStreamServiceProtocol>
{
    NSString *_ingestURL;
}


@property bool isReady;
@property (assign) NSString *streamKey;



-(NSViewController  *)getConfigurationView;
-(NSString *)getServiceDestination;
+(NSString *)label;
+(NSString *)serviceDescription;
+(NSImage *)serviceImage;
-(NSString *)getServiceFormat;
-(void)prepareForStreamStart;





@end
