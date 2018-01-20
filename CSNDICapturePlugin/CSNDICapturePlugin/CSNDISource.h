//
//  CSNDISource.h
//  CSNDICapturePlugin
//
//  Created by Zakk on 1/19/18.
//

#import <Foundation/Foundation.h>
#import "Processing.NDI.Lib.h"

@interface CSNDISource : NSObject


@property (assign) NDIlib_source_t ndiSource;
@property (readonly) NSString *name;
@property (readonly) NSString *ipaddress;

-(instancetype)initWithSource:(NDIlib_source_t)source;

@end
