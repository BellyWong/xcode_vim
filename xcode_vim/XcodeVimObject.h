//
//  XcodeVimObject.h
//  xcode_vim
//
//  Created by chliu on 13-8-24.
//  Copyright (c) 2013 chliu. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface XcodeVimObject : NSObject
{
    NSString* m_documentPath;
}

+(XcodeVimObject *)instance ;

@end
