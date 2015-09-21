//
//  HistoryDataModel.h
//  UCWebViewTest
//
//  Created by Sooyo on 15/7/9.
//  Copyright (c) 2015年 Sooyo. All rights reserved.
//

#ifndef UCWebViewTest_HistoryDataModel_h
#define UCWebViewTest_HistoryDataModel_h

@class NSURL;
@class NSString;
@class NSArray;

@protocol HistoryDataModel <NSObject>

@required

/* Append */
- (void)saveHistroyWithLink:(NSURL *)link andTitle:(NSString *)title;

/* Delete */
- (void)removeHistoryWithLink:(NSURL *)link;
- (void)removeAllHistoryRecords;

/* Query */
- (int)historyRecordCount;
- (NSArray *)historyRecords;

/* Save data */
- (void)synchronize;

@end

#endif
