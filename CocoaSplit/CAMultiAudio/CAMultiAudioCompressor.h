//
//  CAMultiAudioCompressor.h
//  CocoaSplit
//
//  Created by Zakk on 12/29/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CAMultiAudioNode.h"

@interface CAMultiAudioCompressor : CAMultiAudioNode
-(NSDictionary *)saveData;
-(void)restoreData:(NSDictionary *)saveData;
@property (assign) bool bypass;

@end
