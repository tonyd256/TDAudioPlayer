//
//  TDDetailViewController.h
//  TDAudioPlayer
//
//  Created by Tony DiPasquale on 10/16/13.
//  Copyright (c) 2013 Tony DiPasquale. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDDetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
