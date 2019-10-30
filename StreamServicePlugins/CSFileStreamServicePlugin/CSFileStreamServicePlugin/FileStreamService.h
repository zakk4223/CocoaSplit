//
//  FileStreamService.h
//  CSFileStreamServicePlugin
//
//  Created by Zakk on 8/29/14.
//

#import <Foundation/Foundation.h>
#import "CSStreamServiceProtocol.h"
#import "CSStreamServiceBase.h"

@interface FileStreamService : CSStreamServiceBase <CSStreamServiceProtocol>


@property (strong) NSString *fileName;

@property (assign) BOOL useTimestamp;
@property (assign) BOOL noClobber;
@property (readonly) BOOL segmentFile;
@property (strong) NSNumber *segmentTime;
@property (strong) NSNumber *segmentCount;
@property (strong) NSString *forceFormat;




-(NSViewController  *)getConfigurationView;
-(NSString *)getServiceDestination;
+(NSString *)label;
+(NSString *)serviceDescription;
+(NSImage *)serviceImage;



@end
