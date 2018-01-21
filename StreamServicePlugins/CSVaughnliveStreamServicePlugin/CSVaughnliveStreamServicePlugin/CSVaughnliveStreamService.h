//
//  CSVaughnliveStreamService.h
//  CSVaughnliveStreamServicePlugin
//
//  Created by Zakk on 5/31/15.
//

#import <Foundation/Foundation.h>
#import "CSStreamServiceProtocol.h"
#import "CSOutputBase.h"

#define INGEST_URL @"rtmp://live.vaughnlive.tv:443/live/"


@interface CSVaughnliveStreamService : CSOutputBase <CSStreamServiceProtocol>
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
