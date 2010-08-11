//
//  LTWPythonDocument.m
//  LTWToolkit
//
//  Created by David Alexander on 28/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LTWPythonDocument.h"

// So that we can set up the right Python component.
#import "LTWToolkitAppDelegate.h"
#import "LTWCorpus.h"
#import "LTWTokenProcessor.h"


@implementation LTWPythonDocument

-(void)windowControllerDidLoadNib:(NSWindowController*)windowController {
	if (!self->codeAttributedString) self->codeAttributedString = [[NSAttributedString alloc] initWithString:@""];
	[self->codeView setFont:[NSFont fontWithName:@"Menlo Regular" size:11]];
	[[self->codeView textStorage] setAttributedString:self->codeAttributedString];
	[self->codeView setDelegate:self];
}

-(void)textDidChange:(NSNotification*)notification {
	[[self->codeView window] setDocumentEdited:YES];
}

-(IBAction)compileAsCorpus:(id)sender {
	// NOTE: Ideally, we should recognise if the component is already a corpus, and avoid creating a new LTWCorpus if so.
	pythonComponent = [[LTWCorpus alloc] initWithImplementationCode:[[codeView textStorage] string]];
	[[(LTWToolkitAppDelegate*)[NSApp delegate] corpora] addObject:pythonComponent];
}

-(IBAction)compileAsTokenProcessor:(id)sender {
    self->pythonComponent = [[LTWTokenProcessor alloc] initWithImplementationCode:[[self->codeView textStorage] string]];
    [[(LTWToolkitAppDelegate*)[NSApp delegate] tokenProcessors] addObject:self->pythonComponent];
}

- (NSString *)windowNibName {
    // Implement this to return a nib to load OR implement -makeWindowControllers to manually create your controllers.
    return @"LTWPythonDocument";
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	
	return [[[self->codeView textStorage] string] dataUsingEncoding:NSUTF8StringEncoding];
	
    // Insert code here to write your document to data of the specified type. If the given outError != NULL, ensure that you set *outError when returning nil.

    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.

    // For applications targeted for Panther or earlier systems, you should use the deprecated API -dataRepresentationOfType:. In this case you can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.

}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	
	NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string];
	self->codeAttributedString = attributedString;
	[string release];
	
    // Insert code here to read your document from the given data of the specified type.  If the given outError != NULL, ensure that you set *outError when returning NO.

    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead. 
    
    // For applications targeted for Panther or earlier systems, you should use the deprecated API -loadDataRepresentation:ofType. In this case you can also choose to override -readFromFile:ofType: or -loadFileWrapperRepresentation:ofType: instead.
    
    return YES;
}

@end
