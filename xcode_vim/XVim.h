//
//  XVim.h
//  XVim
//
//  Created by Shuichiro Suzuki on 1/19/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface XVim : NSObject
{
    NSString* m_documentPath;
}

+ (XVim*)instance;

@end
