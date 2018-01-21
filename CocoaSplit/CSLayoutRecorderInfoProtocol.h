//
//  CSLayoutRecorderInfoProtocol.h
//  CocoaSplit
//
//  Created by Zakk on 5/7/17.
//

#ifndef CSLayoutRecorderInfoProtocol_h
#define CSLayoutRecorderInfoProtocol_h

#import "VideoCompressor.h"

@protocol CSLayoutRecorderInfoProtocol

@property (strong) NSDictionary *compressors;
@property (readonly) float frameRate;


-(NSObject<VideoCompressor> *)compressorByName:(NSString *)name;

@end


#endif /* CSLayoutRecorderInfoProtocol_h */
