//
//  ORTHLEngine.m
//  Threshr
//
//  Created by Rodrigo Sieiro on 01/08/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import "ORTHLEngine.h"
#import "ORURL.h"

#define CACHE_LIMIT_SECONDS 75.0f
#define TIMER_RELOAD_SECONDS 75.0f
#define MINIMUM_ITEM_COUNT 0
#define ITEM_MAXIMUM_AGE_SECONDS 5400.0f

@interface ORTHLEngine ()

@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, assign) NSUInteger tweetCount;
@property (nonatomic, weak) MKNetworkOperation *op;
@property (nonatomic, copy) NSString *cacheFile;
@property (nonatomic, strong) NSDate *lastUpdate;
@property (nonatomic, assign) BOOL isRefreshing;
@property (atomic, strong) NSTimer *timer;
@property (atomic, assign) BOOL isWorking;

@end

@implementation ORTHLEngine

- (id)initWithDelegate:(id<ORTHLEngineDelegate>)delegate
{
    self = [super init];
    if (!self) return nil;
    
    self.queue = dispatch_queue_create("com.orooso.thlqueue", NULL);
    self.delegate = delegate;
    self.tweetCount = 0;
    
    return self;
}

- (void)start
{
    dispatch_async(self.queue, ^{
        [self loadCacheFile];
        
        if (!self.lastUpdate || [[NSDate date] timeIntervalSinceDate:self.lastUpdate] > CACHE_LIMIT_SECONDS || self.displayedItems.count == 0) {
            self.isRefreshing = YES;
            [self fetchNewItems];
		} else {
			[self updateDisplayedItems:YES];
		}
    });
    
    [self startTimer];
}

- (void)startTimer
{
    if (self.timer) [self stopTimer];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_RELOAD_SECONDS
                                                  target:self
                                                selector:@selector(timerCallback)
                                                userInfo:nil
                                                 repeats:YES];
    
    NSLog(@"Twitter fetch timer started");
}

- (void)stopTimer
{
    [self.timer invalidate];
    self.timer = nil;
    
    NSLog(@"Twitter fetch timer stopped");
}

- (void)reset
{
    self.displayedItems = nil;
    self.tweetCount = 0;
    
    dispatch_async(self.queue, ^{
        if (self.op) [self.op cancel];
        self.op = nil;
        self.isRefreshing = NO;
        self.isWorking = NO;
        self.allItems = nil;
        self.lastUpdate = nil;
        
        if (self.cacheFile) {
            [[NSFileManager defaultManager] removeItemAtPath:self.cacheFile error:nil];
            self.cacheFile = nil;
        }
    });
    
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)reload
{
    dispatch_async(self.queue, ^{
        if (!self.lastUpdate || [[NSDate date] timeIntervalSinceDate:self.lastUpdate] > CACHE_LIMIT_SECONDS) {
            self.isRefreshing = YES;
            [self fetchNewItems];
        } else {
            [self dedupeItemsAndForceDelete:YES];
            [self sortItems];
            [self storeCacheFile];
            [self updateDisplayedItems:YES];
        }
    });
}

- (void)removeItemAtIndex:(NSUInteger)index
{
    // Mark the item as removed so it never appears again
    ORSFItem *item = self.displayedItems[index];
    item.removed = YES;
    
    // Remove it from displayed items
    [self.displayedItems removeObjectAtIndex:index];
    
    // Store changes on cache
    dispatch_async(self.queue, ^{
        [self storeCacheFile];
    });
}

- (void)timerCallback
{
    if (self.isWorking) return;
    
    dispatch_async(self.queue, ^{
        self.isRefreshing = NO;
        [self fetchNewItems];
    });
}

- (ORSFTwitterURL *)findDuplicate:(ORURL *)url
{
    if (![url.finalURL.absoluteString isEqualToString:url.originalURL.absoluteString]) {
        ORSFTwitterURL *item = [[ORSFTwitterURL alloc] initEmptyWithId:url.finalURL.absoluteString];
        NSUInteger idx = [self.allItems indexOfObject:item];
        
        if (idx != NSNotFound) {
            item = [self.allItems objectAtIndex:idx];
            
            ORSFTwitterURL *old = [[ORSFTwitterURL alloc] initEmptyWithId:url.originalURL.absoluteString];
            idx = [self.allItems indexOfObject:old];
            
            if (idx != NSNotFound) {
                old = [self.allItems objectAtIndex:idx];
                
                if (item != old) {
                    for (ORTweet *tweet in old.tweets) [item addTweet:tweet];
                    if ((url.pageTitle && !item.detailURL.pageTitle) || (url.imageURL && !item.detailURL.imageURL)) {
                        [item.detailURL copyDataFrom:url];
                        if (item.detailURL.imageURL) item.imageURL = item.detailURL.imageURL;
                    }
                    return old;
                }
            }
        }
    }
    
    return nil;
}

- (void)fetchNewItems
{
    if (self.isWorking) return;
    if (!TwitterEngine.isAuthenticated) return;

    self.isWorking = YES;
    self.lastUpdate = [NSDate date];
    
    NSLog(@"Fetching new items from Twitter...");
    
    self.op = [TwitterEngine homeTimeline:200 maxID:NSNotFound sinceID:NSNotFound completion:^(NSError *error, NSArray *tweets) {
        dispatch_async(self.queue, ^{
            self.op = nil;
            
            if (error) {
                NSLog(@"Error: %@", error);
                
                self.isWorking = NO;
                self.isRefreshing = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate thlRefreshFailed];
                });
            }
            
            self.tweetCount = tweets.count;
            
            // Create the item set, if needed
            if (!self.allItems) self.allItems = [NSMutableOrderedSet orderedSetWithCapacity:tweets.count];
            NSMutableArray *urls = [NSMutableArray arrayWithCapacity:10];
            
            NSUInteger added = 0;
            BOOL changed = NO;
            
            for (ORTweet *item in tweets) {
                // Discard tweets without URLs
                if (item.urls.count <= 0) continue;
                
                ORSFTwitterURL *tweet = [[ORSFTwitterURL alloc] initWithTweet:item andEntity:nil];
                NSUInteger idx = [self.allItems indexOfObject:tweet];
                
                if (idx != NSNotFound) {
                    // Add the RT count
                    tweet = [self.allItems objectAtIndex:idx];
                    [tweet addTweet:item];
                    [tweet setRawScores];
                    changed = YES;
                } else {
                    // Add to the set
                    tweet.taken = NO;
                    [tweet setRawScores];
                    [self.allItems addObject:tweet];
                    added++;
                    
                    if (!tweet.detailURL.isResolved) [urls addObject:tweet.detailURL.finalURL.absoluteString];
                }
            }
            
            if (urls.count > 0) {
                // Try a batch resolve against the server
                [[ORURLResolver sharedInstance] resolveBatch:urls completion:^(NSError *error, NSArray *finalURLs) {
                    dispatch_async(self.queue, ^{
                        if (error) NSLog(@"Error: %@", error);
                        
                        for (ORURL *url in finalURLs) {
                            ORSFTwitterURL *dupe = [self findDuplicate:url];
                            if (dupe && !dupe.taken) {
                                [self.allItems removeObject:dupe];
                                continue;
                            }
                            
                            ORSFTwitterURL *item = [[ORSFTwitterURL alloc] initEmptyWithId:url.originalURL.absoluteString];
                            NSUInteger idx = [self.allItems indexOfObject:item];
                            if (idx != NSNotFound) {
                                item = [self.allItems objectAtIndex:idx];
                                if (item.detailURL.imageURL) item.imageURL = item.detailURL.imageURL;
                            }
                        }
                        
                        [self dedupeItemsAndForceDelete:self.isRefreshing];
                        [self sortItems];
                        [self storeCacheFile];
                        self.isWorking = NO;
                        
                        // Update the Displayed Items
                        [self updateDisplayedItems:self.isRefreshing];
                    });
                }];
            } else {
                [self dedupeItemsAndForceDelete:self.isRefreshing];
                [self sortItems];
                [self storeCacheFile];
                self.isWorking = NO;
                
                // Update the Displayed Items
                [self updateDisplayedItems:self.isRefreshing];
            }
        });
    }];
}

- (void)dedupeItemsAndForceDelete:(BOOL)delete
{
    NSMutableArray *itemsToDelete = [NSMutableArray array];
    
    for (ORSFTwitterURL *item in self.allItems) {
        if (![item.itemID isEqualToString:item.detailURL.finalURL.absoluteString]) {
            ORSFTwitterURL *newItem = [[ORSFTwitterURL alloc] initEmptyWithId:item.detailURL.finalURL.absoluteString];
            NSUInteger idx = [self.allItems indexOfObject:newItem];
            
            if (idx != NSNotFound) {
                newItem = [self.allItems objectAtIndex:idx];
                for (ORTweet *tweet in item.tweets) [newItem addTweet:tweet];
                if ((item.detailURL.pageTitle && !newItem.detailURL.pageTitle) || (item.detailURL.imageURL && !newItem.detailURL.imageURL)) {
                    [newItem.detailURL copyDataFrom:item.detailURL];
                    if (newItem.detailURL.imageURL) newItem.imageURL = newItem.detailURL.imageURL;
                }
                
                if (item && (delete || !item.taken)) [itemsToDelete addObject:item];
            }
        } else {
            ORSFTwitterURL *dupe = [self findDuplicate:item.detailURL];
            if (dupe && (delete || !dupe.taken)) [itemsToDelete addObject:dupe];
        }
    }
    
    if (itemsToDelete.count > 0) [self.allItems removeObjectsInArray:itemsToDelete];
}

- (void)sortItems
{
    [self.allItems sortUsingComparator:^NSComparisonResult(ORSFTwitterURL *obj1, ORSFTwitterURL *obj2) {
        NSTimeInterval age1 = [[NSDate date] timeIntervalSinceDate:obj1.lastActivity];
        NSTimeInterval age2 = [[NSDate date] timeIntervalSinceDate:obj2.lastActivity];

        // Age (Less than 90m first)
        if (age1 <= ITEM_MAXIMUM_AGE_SECONDS && age2 > ITEM_MAXIMUM_AGE_SECONDS) {
            return NSOrderedAscending;
        } else if (age1 > ITEM_MAXIMUM_AGE_SECONDS && age2 <= ITEM_MAXIMUM_AGE_SECONDS) {
            return NSOrderedDescending;
        }
        
        // Score (descending)
        if (obj1.scoreBlendedNormalized > obj2.scoreBlendedNormalized) {
            return NSOrderedAscending;
        } else if (obj1.scoreBlendedNormalized < obj2.scoreBlendedNormalized) {
            return NSOrderedDescending;
        }
        
        return NSOrderedSame;
    }];
}

- (void)updateDisplayedItems:(BOOL)reload
{
    NSUInteger count = 0, removed = 0;
    NSUInteger itemCount = self.allItems.count;
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:itemCount];

    NSMutableArray *itemsToRemove = nil;
    BOOL shouldDelete = (reload && itemCount > MINIMUM_ITEM_COUNT);
    BOOL foundOld = NO;
    
    for (ORSFTwitterURL *item in self.allItems) {
        if (item.removed) continue;
        if (!reload && item.taken) continue;
        
        NSTimeInterval age = [[NSDate date] timeIntervalSinceDate:item.lastActivity];
        
        /*
        if (age > ITEM_MAXIMUM_AGE_SECONDS && !foundOld) {
            ORSFTwitterURL *dummy = [[ORSFTwitterURL alloc] initEmptyWithId:@"_separator_"];
            foundOld = dummy.firstOldItem = YES;
            [items addObject:dummy];
        }
        */
        
        // Remove items older than the defined age
        if (shouldDelete && age > ITEM_MAXIMUM_AGE_SECONDS) {
            if (!itemsToRemove) itemsToRemove = [NSMutableArray array];
            [itemsToRemove addObject:item];
            removed++;
        }

        count++;
        item.taken = YES;
        [items addObject:item];
    }
    
    if (self.tweetCount == 0) self.tweetCount = count;
    
    if (count > MINIMUM_ITEM_COUNT && itemsToRemove && removed > 0) {
        // Only remove items until the minimum count remains
        if ((itemCount - removed) < MINIMUM_ITEM_COUNT) {
            NSUInteger realRemove = itemCount - MINIMUM_ITEM_COUNT;
            [itemsToRemove sortUsingComparator:^NSComparisonResult(ORSFTwitterURL *o1, ORSFTwitterURL *o2) {
                return [o1.lastActivity compare:o2.lastActivity];
            }];
            
            // We should always remove the oldest items
            [itemsToRemove removeObjectsInRange:NSMakeRange(realRemove - 1, removed - realRemove)];
            removed = realRemove;
        }
        
        NSLog(@"Cleanup: removed %d old items", removed);
        [self.allItems removeObjectsInArray:itemsToRemove];
        [items removeObjectsInArray:itemsToRemove];
        count = items.count;
    }
    
    if (reload && self.tweetCount > 0) {
        // Add the Stats card
        ORSFTwitterURL *dummy = [[ORSFTwitterURL alloc] initEmptyWithId:@"_stats_"];
        dummy.content = [NSString stringWithFormat:@"%d articles shared in the past %d minutes\n %d tweets analyzed",
                         count, (int)ITEM_MAXIMUM_AGE_SECONDS / 60, self.tweetCount];
        
        [items addObject:dummy];
        [self storeCacheFile];
    }
    
    if (foundOld) {
        ORSFTwitterURL *item = [items lastObject];
        if (item.firstOldItem) [items removeLastObject];
        item = items[0];
        if (item.firstOldItem) [items removeObjectAtIndex:0];
    }
    
    if (reload) {
        NSLog(@"THL Reloaded. Total Items: %d", count);
        
        self.isRefreshing = NO;
        self.displayedItems = items;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate thlItemsRefreshed:count];
        });
    } else {
        NSLog(@"THL Updated. New Items: %d", count);
        
        if (count > 0) {
            // This would make the items be added at the end of the CV
            // But for now we better wait for a manual refresh
            // [self.displayedItems addObjectsFromArray:items];
            count = 0;
            
            if (!self.displayedItems) self.displayedItems = items;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate thlItemsUpdated:count];
            });
        }
    }
}

#pragma mark - Cache

- (void)storeCacheFile
{
    if (!TwitterEngine.screenName || !self.lastUpdate) return;
    
    if (!self.cacheFile) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachesDirectory = paths[0];
        self.cacheFile = [cachesDirectory stringByAppendingPathComponent:@"TwitterNews.dat"];
    }
    
    NSDictionary *data;
    
    if (self.allItems) {
        data = @{@"account": TwitterEngine.screenName,
                 @"lastUpdate": self.lastUpdate,
                 @"items": self.allItems};
    } else {
        data = @{@"account": TwitterEngine.screenName,
                 @"lastUpdate": self.lastUpdate};
    }
    
    [NSKeyedArchiver archiveRootObject:data toFile:self.cacheFile];
}

- (void)loadCacheFile
{
    if (!self.cacheFile) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachesDirectory = paths[0];
        self.cacheFile = [cachesDirectory stringByAppendingPathComponent:@"TwitterNews.dat"];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.cacheFile]){
        NSDictionary *data = [NSKeyedUnarchiver unarchiveObjectWithFile:self.cacheFile];
        
        if (data && [TwitterEngine.screenName isEqualToString:data[@"account"]]) {
            self.lastUpdate = data[@"lastUpdate"];
            self.allItems = [NSMutableOrderedSet orderedSetWithCapacity:[data[@"items"] count]];
            
            for (ORSFTwitterURL *item in data[@"items"]) {
                item.detailURL = [[ORURLResolver sharedInstance] findOnCache:item.detailURL];
                
                item.detailURL.originalURL = item.detailURL.finalURL;
                [item.detailURL replaceKnownQueryParams];
                
                if (!item.detailURL.isResolved) {
                    [[ORURLResolver sharedInstance] resolveORURL:item.detailURL localOnly:YES completion:^(NSError *error, ORURL *finalURL) {
                        if (finalURL) item.detailURL = finalURL;
                    }];
                }
                
                item.itemID = item.detailURL.finalURL.absoluteString;
                item.taken = NO;

                [self.allItems addObject:item];
            }
            
            [self dedupeItemsAndForceDelete:YES];
        }
    }
}

- (void)unhideAll
{
    for (ORSFTwitterURL *item in self.allItems)
        item.removed = NO;
}

@end
