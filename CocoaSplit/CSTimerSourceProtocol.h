//
//  CSTimerSourceProtocol.h
//  CocoaSplit
//
//  Created by Zakk on 7/11/15.
//

#ifndef CocoaSplit_CSTimerSourceProtocol_h
#define CocoaSplit_CSTimerSourceProtocol_h


@protocol CSTimerSourceProtocol


-(void)frameArrived:(id)ctx;
-(void)frameTimerWillStop:(id)ctx;


@end

#endif
