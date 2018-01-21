//
//  CSLavfOutput.h
//  CocoaSplit
//
//  Created by Zakk on 1/21/18.
//

#import <Foundation/Foundation.h>
#import "CSOutputBase.h"

@interface CSLavfOutput : CSOutputBase

-(BOOL) writeEncodedData:(CapturedFrameData *)frameDataIn;

@end




