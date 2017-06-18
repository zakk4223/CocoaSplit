//
//  JSExportUtil.h
//  CocoaSplit
//
//  Created by Zakk on 6/18/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#ifndef JSExportUtil_h
#define JSExportUtil_h

#define JSEXPORT_PROTO(X) void X##Hack() { (void)@protocol(X);}

#endif /* JSExportUtil_h */
