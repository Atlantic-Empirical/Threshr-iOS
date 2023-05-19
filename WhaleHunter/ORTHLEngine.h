//
//  ORTHLEngine.h
//  Threshr
//
//  Created by Rodrigo Sieiro on 01/08/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ORTHLEngineDelegate;

@interface ORTHLEngine : NSObject

@property (atomic, strong) NSMutableOrderedSet *allItems;
@property (atomic, strong) NSMutableArray *displayedItems;
@property (nonatomic, weak) id<ORTHLEngineDelegate> delegate;

- (id)initWithDelegate:(id<ORTHLEngineDelegate>)delegate;
- (void)start;
- (void)reset;
- (void)reload;
- (void)removeItemAtIndex:(NSUInteger)index;
- (void)unhideAll;

- (void)stopTimer;
- (void)startTimer;

@end

@protocol ORTHLEngineDelegate <NSObject>

- (void)thlItemsRefreshed:(NSUInteger)count;
- (void)thlItemsUpdated:(NSUInteger)count;
- (void)thlRefreshFailed;

@end

