//
//  CAMultiAudioMixingProtocol.h
//  CocoaSplit
//
//  Created by Zakk on 11/15/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#ifndef CocoaSplit_CAMultiAudioMixingProtocol_h
#define CocoaSplit_CAMultiAudioMixingProtocol_h

#import <Foundation/Foundation.h>


@protocol CAMultiAudioMixingProtocol


@required
-(void)setVolumeOnInputBus:(UInt32)bus volume:(float)volume;
-(void)setVolumeOnOutputBus:(UInt32)bus volume:(float)volume;
-(void)setVolumeOnOutput:(float)volume;
-(void)enableMeteringOnInputBus:(UInt32)bus;
-(Float32)powerForInputBus:(UInt32)bus;

@end

#endif
