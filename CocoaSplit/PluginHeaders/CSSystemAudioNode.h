//
//  CSSystemAudioNode.h
//  CocoaSplit
//
//  Created by Zakk on 5/22/20.
//  Copyright © 2020 Zakk. All rights reserved.
//

#ifndef CSSystemAudioNode_h
#define CSSystemAudioNode_h

@interface CSSystemAudioNode : NSObject
@property (strong) NSString *name;
@property (assign) UInt32 deviceID;
@property (strong) NSString *deviceUID;
@end


#endif /* CSSystemAudioNode_h */
