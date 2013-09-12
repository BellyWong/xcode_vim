//
//  XcodeVimObject.h
//  xcode_vim
//
//  Created by FrankLiu on 13-8-24.
//  Copyright (c) 2013年 FrankLiu. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface XcodeVimObject : NSObject
{
    NSString* m_documentPath;
}

+(XcodeVimObject *)instance ;

@end
