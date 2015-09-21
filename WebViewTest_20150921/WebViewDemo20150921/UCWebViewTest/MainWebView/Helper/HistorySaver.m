/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : HistorySaver.m
 *
 * Description   : 
 *
 * Creation       : 2015/06/26
 * Author          : luyc@ucweb.com
 * History         :
 *                 Creation, 2015/06/25, luyc, Create the file
 ***************************************************************************
 **/
#import "HistorySaver.h"

/* Constant string for keys and file name */
NSString *const HistoryRecordKeyUrl = @"URL";
NSString *const HistoryRecordKeyDate = @"Date";
static NSString *const HistoryRecordFileName = @"HistroyUrl.plist";

static const NSInteger MaximumCacheRecordCount = 200; // The total amount of history record we'll save for the user

@interface HistorySaver ()

@property (nonatomic, retain) NSDateFormatter *dateFormatter;  // We need this property to do some enhancement on time. Just put it here right now
@property (nonatomic, retain) NSMutableDictionary *historyDictionary;
@property (nonatomic, retain) NSMutableArray *sortedKeys;

@property (nonatomic, assign) NSInteger operateCount;

@end


@implementation HistorySaver

- (instancetype)init
{
    if ((self = [super init]))
    {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        
        NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *historyRecordFile = [documentDir stringByAppendingPathComponent:HistoryRecordFileName];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:historyRecordFile])
        {
            NSDictionary *recordArray = [NSDictionary dictionaryWithContentsOfFile:historyRecordFile];
            [self classifyDateTimeForHistoryRecords:recordArray];       // Construncting the core data dictionary over here
        }
    }
    
    return self;
}

- (void)dealloc
{
    [_dateFormatter release];
    _dateFormatter = nil;
    
    [_historyDictionary  release];
    _historyDictionary = nil;
    
    [_sortedKeys release];
    _sortedKeys = nil;
    
    [super dealloc];
}

- (NSString *)literalTimespanToDateString:(NSString *)historyRecordDate
{
    NSString *currentDateString = [self.dateFormatter stringFromDate:[NSDate date]];
    
    /* We need to copmare the integer value to find out the time span */
    NSInteger currentDateIntegerValue = [[[currentDateString componentsSeparatedByString:@" "][0] stringByReplacingOccurrencesOfString:@"-" withString:@""] integerValue];
    NSInteger recordDateIntegerValue = [[[historyRecordDate componentsSeparatedByString:@" "][0] stringByReplacingOccurrencesOfString:@"-" withString:@""] integerValue];
    
    if (recordDateIntegerValue > currentDateIntegerValue)
    {
        return nil;
    }
    
    NSString *literalResult = nil;
    switch(currentDateIntegerValue - recordDateIntegerValue)  // We needs string like "today", "yesterday" and other easy to read strings
    {
        case 0:  // The time has no different, it stands for the record is produced at the same day with current date time
        {
            literalResult = @"今天";
        }
            break;
            
        case 1:
        {
            literalResult = @"昨天";
        }
            break;
            
        case 2:
        {
            literalResult = @"前天";
        }
            break;
            
        default:
        {
            literalResult = @"更早前";
        }
            break;
    }
    
    return literalResult;
}

- (NSInteger)getDateIntByLiteralTimeSpan:(NSString *)timeSpan
{
    /* A badly designed data struct result in a STUPID method define */
    NSInteger dateInt = 0;
    if ([timeSpan isEqualToString:@"今天"])
    {
        dateInt = 3;
    }
    else if ([timeSpan isEqualToString:@"昨天"])
    {
        dateInt = 2;
    }
    else if ([timeSpan isEqualToString:@"前天"])
    {
        dateInt = 1;
    }

    return dateInt;
}

- (NSArray *)sortKeyByTimeSpan
{
    NSArray *keys = [self.historyDictionary allKeys];
    NSArray *sortedKeys = [keys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *date1 = (NSString *)obj1;
        NSString *date2 = (NSString *)obj2;
        
        NSInteger dateInt1 = [self getDateIntByLiteralTimeSpan:date1];
        NSInteger dateInt2 = [self getDateIntByLiteralTimeSpan:date2];
        
        NSComparisonResult result = NSOrderedSame;
        if (dateInt1 > dateInt2)
        {
            result = NSOrderedAscending;
        }
        else if (dateInt1 < dateInt2)
        {
            result = NSOrderedDescending;
        }
        
        return  result;
    }];
    
    return sortedKeys;
}

- (void)classifyDateTimeForHistoryRecords:(NSDictionary *)historyDictionary
{
    self.historyDictionary = [NSMutableDictionary dictionary];
    
    for (NSArray *historyRecords in [historyDictionary allValues])
    {
        for (NSDictionary *historyRecord in historyRecords)
        {
            NSString *timeSpan = [self literalTimespanToDateString:historyRecord[HistoryRecordKeyDate]];
            if (timeSpan == nil)
            {
                continue;
            }
            
            NSMutableArray *arrayForThisTimeSpan = nil;
            if (![[self.historyDictionary allKeys] containsObject:timeSpan])
            {
                arrayForThisTimeSpan = [NSMutableArray arrayWithObject:historyRecord];
            }
            else
            {
                arrayForThisTimeSpan = self.historyDictionary[timeSpan];
                [arrayForThisTimeSpan addObject:historyRecord];
            }
            
            self.historyDictionary[timeSpan] = arrayForThisTimeSpan;
        }
    }
    
    self.sortedKeys = [NSMutableArray arrayWithArray:[self sortKeyByTimeSpan]];
}

- (NSInteger)recordCount
{
    NSInteger count = 0;
    for (NSArray *array in [self.historyDictionary allValues])
    {
        count += array.count;
    }
    
    return count;
}

- (NSDictionary *)repeatedUrlToHit:(NSString*)targetLink inTimeSpecificArray:(NSArray *)timeSpanArray
{
    /* This is a small wrap to simplify the dedup function for Saver */
    for (NSDictionary *record in timeSpanArray)
    {
        NSString *recordUrl = record[HistoryRecordKeyUrl];
        if ([recordUrl isEqualToString:targetLink])
        {
            return record;
        }
    }
    
    return nil;
}

- (void)insertRecord:(NSDictionary *)newRecord
{
    /* This function inserts a new record to the history records, it also will do some dedup handling and capacity checking */
    NSDictionary *repeatedRecord = nil;
    for (NSString *timeKey in self.sortedKeys)
    {
        NSMutableArray *timeSpanArray = self.historyDictionary[timeKey];
        repeatedRecord = [self repeatedUrlToHit:newRecord[HistoryRecordKeyUrl] inTimeSpecificArray:timeSpanArray];
        
        if (repeatedRecord != nil)
        {
            /* You need to remove the old record at first */
            [timeSpanArray removeObject:repeatedRecord];
            if (timeSpanArray.count == 0)
            {
                [self.historyDictionary removeObjectForKey:timeKey];
            }
            else
            {
                self.historyDictionary[timeKey] = timeSpanArray;
            }
            
            break;
        }
    }
    
    /* Check if we need to remove the oldest record before inserting the new one */
    NSInteger totalAmount = [self recordCount];
    if (repeatedRecord == nil && totalAmount > MaximumCacheRecordCount)
    {
        NSString *lastTimeSpan = [[self sortedKeys] lastObject];
        NSMutableArray *lastTimeSpanRecordArray = self.historyDictionary[lastTimeSpan];
        [lastTimeSpanRecordArray removeLastObject];
        
        if (lastTimeSpanRecordArray.count == 0)
        {
            [self.historyDictionary removeObjectForKey:lastTimeSpan];
        }
    }
    
    /* Now, we can insert it */
    if (![[self.historyDictionary allKeys] containsObject:@"今天"])
    {
        NSMutableArray *initialHistoryRecordArray = [NSMutableArray arrayWithObject:newRecord];
        self.historyDictionary[@"今天"] = initialHistoryRecordArray;
        
        if (![self.sortedKeys containsObject:@"今天"])
        {
            [self.sortedKeys insertObject:@"今天" atIndex:0];
        }
    }
    else
    {
        NSMutableArray *recordForToday = self.historyDictionary[@"今天"];
        [recordForToday insertObject:newRecord atIndex:0];
        self.historyDictionary[@"今天"] = recordForToday;
    }
}

- (void)saveLinkHistory:(NSURL *)link
{
    NSString *dateString = [self.dateFormatter stringFromDate:[NSDate date]];
    NSDictionary *historyRecord= @{HistoryRecordKeyDate : dateString, HistoryRecordKeyUrl : [link absoluteString]};
    
    if (self.historyDictionary == nil)
    {
        /* This function always saves link for the day of current date */
        NSMutableArray *initialHistoryRecordArray = [NSMutableArray arrayWithObject:historyRecord];
        
        self.historyDictionary =  [NSMutableDictionary dictionary];
        self.historyDictionary[@"今天"] = initialHistoryRecordArray;
    }
    else
    {
        [self insertRecord:historyRecord];
    }
}

- (NSDictionary *)history
{
    return self.historyDictionary;
}

- (NSInteger)histroySectionCount
{
    NSInteger result = 0;
    if (self.historyDictionary != nil)
    {
        result = [self.historyDictionary count];
    }
    
    return result;
}

- (NSInteger)numberOfRecordsInSection:(NSInteger)section
{
    NSInteger result = 0;
    if (self.historyDictionary != nil && section < self.historyDictionary.count)
    {
        NSString *key = self.sortedKeys[section];
        result = [self.historyDictionary[key] count];
    }
    
    return result;
}

- (NSString *)titleForSection:(NSInteger)section
{
    NSString *title = nil;
    if (self.historyDictionary != nil && section < self.historyDictionary.count)
    {
        title = self.sortedKeys[section];
    }
    
    return title;
}

- (NSDictionary *)recordAtSection:(NSInteger)section andRow:(NSInteger)rowIndex
{
    NSDictionary *record = nil;
    if (self.historyDictionary != nil && section < self.historyDictionary.count)
    {
        NSString *key = self.sortedKeys[section];
        NSArray *records = self.historyDictionary[key];
        if (records.count > rowIndex)
        {
            record = records[rowIndex];
        }
    }
    
    return record;
}

- (void)synchronize
{
    NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *historyRecordFile = [documentDir stringByAppendingPathComponent:HistoryRecordFileName];
    
    [self.historyDictionary writeToFile:historyRecordFile atomically:YES];
    self.operateCount = 0;
}

- (void)syncAutomaticallyIfNeeded
{
    // FIXME: 如果operateCount只是4个，这个时候崩溃了怎么办？这个方法不是完美的。
    if (++ self.operateCount > 5)
    {
        [self synchronize];
        self.operateCount = 0;
    }
}

- (void)removeAllRecordsInSection:(NSInteger)sectionIndex
{
    if (sectionIndex > [self.historyDictionary count])
    {
        return;
    }
    
    [self.historyDictionary removeObjectForKey:self.sortedKeys[sectionIndex]];
    [self synchronize];
    
    if ([self.historyDictionary count] == 0)
    {
        [_historyDictionary release];
        _historyDictionary = nil;
    }
}

- (void)removeRecordAtSection:(NSInteger)sectionIndex andRow:(NSInteger)rowIndex
{
 
    if (sectionIndex > self.sortedKeys.count)
    {
        return;
    }
        
    NSString *key = self.sortedKeys[sectionIndex];
    NSMutableArray *recordArray = self.historyDictionary[key];
    
    [recordArray removeObjectAtIndex:rowIndex];
    [self syncAutomaticallyIfNeeded];

    if ([recordArray count] == 0)
    {
        [self.historyDictionary removeObjectForKey:key];
        if ([self.historyDictionary count] == 0)
        {
            [_historyDictionary release];
            _historyDictionary = nil;
        }
    }
    else
    {
        self.historyDictionary[key] = recordArray;
    }
}

- (void)removeAllRecords
{
    [self.historyDictionary removeAllObjects];
    [self synchronize];
    
    // FIXME: 为什没么要释放这个？导致上面的insert逻辑不统一，分成nil和非nil两种逻辑，反而不值得。
    [_historyDictionary release];
    _historyDictionary = nil;
}


@end
