//
//  PlistHistorySaver.m
//  UCWebViewTest
//
//  Created by Sooyo on 15/7/10.
//  Copyright (c) 2015年 Sooyo. All rights reserved.
//

#import "PlistHistorySaver.h"

/* We define the dictionary keys over here */
NSString *const kPlistHistorySaverRecordKeyUrl = @"plUrl";
NSString *const kPlistHistorySaverRecordKeyDate = @"plDate";
NSString *const kPlistHistorySaverRecordKeyTitle = @"plTitle";

NSString *const PlistHistoryRecordUnknownTitle = @"Unknown title";  // A constant to indicate the title for this record is not set

/* A constant path to store the history records */
static NSString *const kPlistHistorySaverRecordFile = @"HistoryRecord.plist";

static const NSInteger MaximumCachedRecordCount = 200;  // Totally cached history records amount

/* Continuation */
@interface PlistHistorySaver ()

@property (nonatomic, retain) NSDateFormatter *dateFormatter;
@property (nonatomic, retain) NSMutableArray *recordList;

@property (atomic, retain) NSLock *lock;

@end

@implementation PlistHistorySaver

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _lock = [[NSLock alloc] init];
        
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        
        /* Load the record file if it existed */
        NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSString *recordFilePath = [documentPath stringByAppendingPathComponent:kPlistHistorySaverRecordFile];
        
        NSFileManager *defalutManager = [NSFileManager defaultManager];
        if ([defalutManager fileExistsAtPath:recordFilePath])
        {
            _recordList = [[NSMutableArray arrayWithContentsOfFile:recordFilePath] retain];
        }
    }
    
    return self;
}

- (void)dealloc
{
    [_recordList release];
    _recordList = nil;
    
    [_lock release];
    _lock = nil;
    
    [super dealloc];
}


- (void)saveHistroyWithLink:(NSURL *)link andTitle:(NSString *)title
{
    [self.lock lock];
    
    if (link == nil || link.absoluteString.length == 0)
    {
        /* We'll not save record with empty link */
        [self.lock unlock];
        
        return ;
    }
    
    NSString *dateString = [self.dateFormatter stringFromDate:[NSDate date]];
    NSMutableDictionary *newRecord = [NSMutableDictionary dictionary];
    
    newRecord[kPlistHistorySaverRecordKeyUrl] = link.absoluteString;
    newRecord[kPlistHistorySaverRecordKeyDate] = dateString;
    
    if (title == nil || title.length == 0)
    {
        title = PlistHistoryRecordUnknownTitle;  // Mark it as unknown title
    }
    
    newRecord[kPlistHistorySaverRecordKeyTitle] = title;
    
    /* If we don't have any record before, just add it to the record array */
    if (self.recordList == nil || self.recordList.count == 0)
    {
        [self.recordList addObject:newRecord];
        
        /* Sync the file */
        // ...
        
        [self.lock unlock];
        
        return;
    }
    
    /* Check for repeated record */
    NSDictionary *repeatedRecord = nil;
    for (NSDictionary *record in self.recordList)
    {
        NSString *recordUrl = record[kPlistHistorySaverRecordKeyUrl];
        if ([recordUrl isEqualToString:newRecord[kPlistHistorySaverRecordKeyUrl]])
        {
            repeatedRecord = record;
            break;
        }
    }
    
    if (repeatedRecord != nil) // We got a repeated record
    {
        if (![repeatedRecord[kPlistHistorySaverRecordKeyDate] isEqualToString:newRecord[kPlistHistorySaverRecordKeyDate]])
        {
            [self.recordList removeObject:repeatedRecord];
            [self.recordList insertObject:newRecord atIndex:0];
            
            /* Sync the file */
            //...
        }
    }
    else // We didn't found  a repeated record, insert it but take care of the list count
    {
        if (self.recordList.count + 1 > MaximumCachedRecordCount)
        {
            [self.recordList removeLastObject];
        }
        
        [self.recordList insertObject:newRecord atIndex:0];
        /* Sync the file */
        //...
        
    }
    
    [self.lock unlock];
}

- (void)removeHistoryWithLink:(NSURL *)link
{
    [self.lock lock];
    
    BOOL isLinkEmpty = (link == nil || link.absoluteString.length == 0);
    BOOL isRecordsEmpty = (self.recordList == nil || self.recordList.count == 0);
    if (isRecordsEmpty || isLinkEmpty)
    {
        /* What do you want to remove ? */
        [self.lock unlock];
        
        return;
    }
    
    NSDictionary *targetRecord = nil;
    for (NSDictionary *record in self.recordList)
    {
        NSString *recordUrl = record[kPlistHistorySaverRecordKeyUrl];
        if ([recordUrl isEqualToString:link.absoluteString])
        {
            targetRecord = record;
            break;
        }
    }
    
    if (targetRecord != nil)
    {
        [self.recordList removeObject:targetRecord];
        /* Sync the file */
        // ..
    }
    
    [self.lock unlock];
}

- (void)removeAllHistoryRecords
{
    [self.lock lock];
    
    if (self.recordList == nil || self.recordList.count == 0)
    {
        [self.lock unlock];
    
        return;
    }
    
    [self.recordList removeAllObjects];
    [self.lock unlock];
}

@end
