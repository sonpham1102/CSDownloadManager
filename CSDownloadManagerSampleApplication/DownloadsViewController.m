//
//  DownloadsViewController.m
//  CSDownloadManager
//
//  Created by Christian Schwarz on 16.09.12.
//  Copyright (c) 2012 Christian Schwarz. All rights reserved.
//

#import "DownloadsViewController.h"
#import "CSDownloadManager.h"
#import "ActiveDownloadCell.h"
#import "DataItem.h"

typedef enum {
    ActiveSection,
    FinishedSection
} Section;

static NSString* const kDataItemKey = @"kDataItemKey";

@interface DownloadsViewController () <CSDownloadManagerDelegate>

@property (nonatomic, strong) CSDownloadManager* downMan;
@end

@implementation DownloadsViewController
@synthesize downMan;

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.downMan = [[CSDownloadManager alloc] initWithDelegate:self];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - interface methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.destinationViewController isKindOfClass:[AddDownloadViewController class]]) {
        AddDownloadViewController* controller = segue.destinationViewController;
        controller.delegate = self;
    }
    
}

#pragma mark - add view controller delegate

- (void)addDownloadController:(AddDownloadViewController *)controller didDismissWithInput:(NSString *)input {
    
    //Create data item
    DataItem* item = [[DataItem alloc] init];
    item.title = [[NSDate date] debugDescription];
    
    //Add URL
    NSURL* url = [NSURL URLWithString:input];
    [self.downMan addDownloadFromURL:url withUserInfo:@{kDataItemKey: item} callback:^(CSActiveDownload* activeDownload){
        
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:[self.downMan.activeDownloads indexOfObject:activeDownload] inSection:ActiveSection];
        
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
        
    }];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case ActiveSection:
            return [self.downMan.activeDownloads count];
            break;
        case FinishedSection:
            return [self.downMan.finishedDownloads count];
            break;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.section == ActiveSection) {
        
        CSActiveDownload* download = [self.downMan.activeDownloads objectAtIndex:indexPath.row];
        DataItem* dataItem = [download.userInfo valueForKey:kDataItemKey];
        
        static NSString *CellIdentifier = @"activeDownloadCell";
        ActiveDownloadCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        cell.textLabel.text = dataItem.title;
        
        return cell;
        
    }
    
    if (indexPath.section == FinishedSection) {
        
        CSFinishedDownload* finishedDownload = [self.downMan.finishedDownloads objectAtIndex:indexPath.row];
        DataItem* dataItem = [finishedDownload.userInfo valueForKey:kDataItemKey];
        
        static NSString *CellIdentifier = @"finishedDownloadCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        cell.textLabel.text = dataItem.title;
        
        cell.detailTextLabel.text = finishedDownload.path;
        
        return cell;
        
    }
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    
    
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == ActiveSection) {
        return YES;
    }
    if (indexPath.section == FinishedSection) {
        return YES;
    }
    
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == ActiveSection) {
        
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            
            CSActiveDownload* activeDL = [self.downMan.activeDownloads objectAtIndex:indexPath.row];
            
            [self.downMan cancelDownload:activeDL callback:^(NSError* error, NSInteger formerIndex){
                if (!error || formerIndex != NSNotFound) {
                    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:formerIndex inSection:ActiveSection]] withRowAnimation:UITableViewRowAnimationRight];
                }
            }];
            
            
        }
        
    }
    
    if (indexPath.section == FinishedSection) {
        
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            
            CSFinishedDownload* finishedDL = [self.downMan.finishedDownloads objectAtIndex:indexPath.row];
            
            [self.downMan deleteDownload:finishedDL callback:^(NSError* error, NSInteger formerIndex){
                if (!error || formerIndex != NSNotFound) {
                    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:formerIndex inSection:FinishedSection]] withRowAnimation:UITableViewRowAnimationRight];
                }
            }];
            
        }
        
    }
    
}

#pragma mark - download manager delegate

- (void)downloadManager:(CSDownloadManager *)dm didFinishDownload:(CSActiveDownload*)finishedDownload {
    
    [dm processFinishedDownload:finishedDownload callback:^(NSInteger formerIndex, NSInteger newIndex){
        NSIndexPath* former = [NSIndexPath indexPathForRow:formerIndex inSection:ActiveSection];
        NSIndexPath* new = [NSIndexPath indexPathForRow:newIndex inSection:FinishedSection];
        [self.tableView moveRowAtIndexPath:former toIndexPath:new];
    }];
    
}

- (void)downloadManager:(CSDownloadManager *)dm download:(CSActiveDownload *)activeDownload didFailWithError:(NSError *)error {
    
    [dm cancelDownload:activeDownload callback:^(NSError* error, NSInteger formerIndex){
        if (!error || formerIndex != NSNotFound) {
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:formerIndex inSection:FinishedSection]] withRowAnimation:UITableViewRowAnimationRight];
        }
    }];
    
}

- (void)downloadManager:(CSDownloadManager *)dm download:(CSActiveDownload *)activeDownload didProceed:(float)process {
    
    NSIndexPath* cellIndexPath = [NSIndexPath indexPathForRow:[self.downMan.activeDownloads indexOfObject:activeDownload] inSection:ActiveSection];
    
    ActiveDownloadCell* cell = (ActiveDownloadCell*) [self.tableView cellForRowAtIndexPath:cellIndexPath];
    
    cell.progress = process;
    
}

NSString* documentsDirectory() {
    
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [searchPaths objectAtIndex:0];
    
    return documentPath;
    
}

- (NSString *)pathForFinishedDownloadsOfDownloadManager:(CSDownloadManager *)dm {
    return documentsDirectory();
}

- (void)updateDownloadsProgress:(NSTimer*)sender {
    BOOL foundDownload = NO;
    for (CSActiveDownload* activeDownload in self.downMan.activeDownloads) {
        if ([activeDownload isEqual:sender.userInfo]) {
            NSInteger row = [self.downMan.activeDownloads indexOfObject:activeDownload];
            [self performSelectorOnMainThread:@selector(updateCellsMain:) withObject:[NSIndexPath indexPathForRow:row inSection:ActiveSection] waitUntilDone:NO];
            foundDownload = YES;
        }
    }
    if (foundDownload == NO) {
        [sender invalidate];
    }
    
}

- (void)updateCellsMain:(CSActiveDownload*)download {
    [self.tableView reloadData];
}

@end
