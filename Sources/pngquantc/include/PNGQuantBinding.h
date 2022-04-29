//
//  Header.h
//  
//
//  Created by Radzivon Bartoshyk on 27/04/2022.
//

#ifndef PNGQuantBinding_h
#define PNGQuantBinding_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NSData * _Nullable quantizedImageData(UIImage * _Nonnull image, int speed);
NSError * _Nullable quantizedImageTo(NSString * _Nonnull path, UIImage * _Nonnull image, int speed);

#endif /* PNGQuantBinding_h */
