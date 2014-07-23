//
//  SKProm.h
//  PromApp
//
//  Created by Scott Krulcik on 7/11/14.
//  Copyright (c) 2014 Scott Krulcik. All rights reserved.
//

#import <Parse/Parse.h>
#import <MapKit/MapKit.h>

@interface SKProm : PFObject <PFSubclassing, MKAnnotation>
@property NSString *schoolName;
@property NSString *address;
@property NSString *locationDescription;
@property NSString *time;
@property NSString *theme;
@property PFGeoPoint *preciseLocation;
@property NSMutableArray *dresses;

+ (NSString *)parseClassName;
- (BOOL) equalTo:(SKProm*)other;

@end