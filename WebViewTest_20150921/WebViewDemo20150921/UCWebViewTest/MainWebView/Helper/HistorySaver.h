/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : HistorySaver.h
 *
 * Description   : HistorySaver helps to manage the history data. It may be better to make it a singleton, but I don't like the singleton grammer
 *                      in non-arc condition. It is being passed from one instance to another and another and another, this is awful too. So HistorySaver
 *                      still needs to be improved. I'll try this at this weekend.
 *
 * Creation       : 2015/06/26
 * Author          : luyc@ucweb.com
 * History         :
 *                 Creation, 2015/06/25, luyc, Create the file
 ***************************************************************************
 **/

#import <Foundation/Foundation.h>

extern NSString *const HistoryRecordKeyUrl;
extern NSString *const HistoryRecordKeyDate;


// FIXME: model 没有考虑多线程安全？

@interface HistorySaver : NSObject

// FIXME: 为什没有保存网页title？如果要扩展怎么办？
- (void)saveLinkHistory:(NSURL *)link;
- (void)synchronize;    // Copy the data from memery to disk

- (NSInteger)histroySectionCount;    // A section is seperated by a time period, like "Today", "Yesterday" and etc.
- (NSInteger)numberOfRecordsInSection:(NSInteger)section;

- (NSString *)titleForSection:(NSInteger)section;
- (NSDictionary *)recordAtSection:(NSInteger)section andRow:(NSInteger)rowIndex;

- (void)removeAllRecordsInSection:(NSInteger)sectionIndex;
- (void)removeRecordAtSection:(NSInteger)sectionIndex andRow:(NSInteger)rowIndex;
- (void)removeAllRecords;

@end

