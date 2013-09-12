//
//  XVimSourceCodeEditor.m
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IDESourceCodeEditorHook.h"
#import "IDEKit.h"
#import "Hooker.h"
#import "Logger.h"

extern long long g_currentLineNumber;

@implementation IDESourceCodeEditorHook

+ (void) hook
{
    Class delegate = NSClassFromString(@"IDESourceCodeEditor");
	[Hooker hookMethod:@selector(textView:willChangeSelectionFromCharacterRanges:toCharacterRanges:) 
			   ofClass:delegate 
			withMethod:class_getInstanceMethod([self class], @selector(textView:willChangeSelectionFromCharacterRanges:toCharacterRanges:)) 
   keepingOriginalWith:@selector(textView_:willChangeSelectionFromCharacterRanges:toCharacterRanges:)];
}

- (NSArray*) textView:(NSTextView *)textView willChangeSelectionFromCharacterRanges:(NSArray *)oldSelectedCharRanges toCharacterRanges:(NSArray *)newSelectedCharRanges
{
    IDESourceCodeEditor* editor = (IDESourceCodeEditor*)self;
    
    /*
    NSLog( @" IDESourceCodeEditor %@,%@,%lld",
          oldSelectedCharRanges, newSelectedCharRanges,
          editor._currentOneBasedLineNubmer );*/
    g_currentLineNumber = editor._currentOneBasedLineNubmer;
    
    //FIXME:need call the real IDESourceCodeEditor:textView:...?
    return newSelectedCharRanges;
}
@end