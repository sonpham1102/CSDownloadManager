//
//  ActiveDownloadCell.h
//  CSDownloadManager
//
//  Created by Christian Schwarz on 16.09.12.
//  Copyright (c) 2012 Christian Schwarz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ActiveDownloadCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *textLabel;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;

@property float progress;

@end
