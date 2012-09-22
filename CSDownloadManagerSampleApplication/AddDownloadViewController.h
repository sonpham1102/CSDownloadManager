//
//  AddDownloadViewController.h
//  CSDownloadManager
//
//  Created by Christian Schwarz on 22.09.12.
//  Copyright (c) 2012 Christian Schwarz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AddDownloadViewController;

@protocol AddDownloadViewControllerDelegate <NSObject>

- (void)addDownloadController:(AddDownloadViewController*)controller didDismissWithInput:(NSString*)input;

@end

@interface AddDownloadViewController : UIViewController

@property (nonatomic, strong) IBOutlet id<AddDownloadViewControllerDelegate> delegate;

- (IBAction)didPushStartDownload:(id)sender;
@property (weak, nonatomic) IBOutlet UITextView *urlTextView;
- (IBAction)didPushDone:(id)sender;

@end
