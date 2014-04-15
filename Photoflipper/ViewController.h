//
//  ViewController.h
//  Photobook
//
//  Created by Bryan Porter on 4/10/14.
//  Copyright (c) 2014 Bryan Porter. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface ViewController : UIViewController <FBLoginViewDelegate>

typedef enum requestImageType {
    RequestImageTypeNext,
    RequestImageTypePrev
} RequestImageType;

@property (strong, nonatomic) FBLoginView * loginView;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) NSArray * imageUrls;
@property (strong, nonatomic) NSString* nextUrl;
@property (strong, nonatomic) NSString* prevUrl;
@property (nonatomic) int currentImageIndex;

-(NSArray*)generateImageUrls:(id)photoAlbumData;
-(NSString*)generateNextUrl:(id)photoAlbumData;
-(NSString*)generatePrevUrl:(id)photoAlbumData;

-(void)requestImages:(RequestImageType)type;

-(void)showImage:(int)imageIndex;

-(void)nextImage;
-(void)previousImage;

-(void)showLoading;
-(void)hideLoading;

-(void)loginViewShowingLoggedInUser:(FBLoginView *)loginView;
-(void)loginView:(FBLoginView *)loginView handleError:(NSError *)error;

- (IBAction)leftSwipe:(id)sender;
- (IBAction)rightSwipe:(id)sender;
- (IBAction)showLogOutButton:(id)sender;


@end
