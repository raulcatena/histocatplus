//
//  IMCMathWindowController.h
//  IMCReader
//
//  Created by Raul Catena on 9/12/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol MathAnalysisWindow <NSObject>

-(void)saveData:(NSDictionary *)maskDict oldDict:(NSDictionary *)oldDict;

@end

@interface IMCMathWindowController : NSWindowController<NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) id<MathAnalysisWindow>delegate;

-(IBAction)updateGraph:(id)sender;
-(IBAction)changedColorSelector:(id)sender;

@end
