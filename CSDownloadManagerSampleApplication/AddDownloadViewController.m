//
//  AddDownloadViewController.m
//  CSDownloadManager
//
//  Created by Christian Schwarz on 22.09.12.
//  Copyright (c) 2012 Christian Schwarz. All rights reserved.
//

#import "AddDownloadViewController.h"

@interface AddDownloadViewController ()

@end

@implementation AddDownloadViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didPushStartDownload:(id)sender {
    [self callDelegateAndDismiss];
}
- (IBAction)didPushDone:(id)sender {
    [self callDelegateAndDismiss];
}

#pragma mark - helpers

- (void)callDelegateAndDismiss {
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate addDownloadController:self didDismissWithInput:self.urlTextView.text];
    }];
    
}

@end
