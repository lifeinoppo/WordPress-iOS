#import <UIKit/UIKit.h>
#import "MenuItem.h"

@class Blog;

@protocol MenuItemTypeSelectionViewDelegate;

@interface MenuItemTypeSelectionView : UIView

@property (nonatomic, weak) id <MenuItemTypeSelectionViewDelegate> delegate;

/**
 The itemType to display as selected in the UI, such as MenuItemTypePage.
 */
@property (nonatomic, strong) NSString *selectedItemType;

/**
 Fetch the postTypes available for the blog, including custom post types.
 */
- (void)loadPostTypesForBlog:(Blog *)blog;

/**
 Helper method for updating the layout if the parentView's layout changed.
 */
- (void)updateDesignForLayoutChangeIfNeeded;

/**
 Ensure the selected itemType is viisble on screen.
 */
- (void)focusSelectedTypeViewIfNeeded:(BOOL)animated;

@end

@protocol MenuItemTypeSelectionViewDelegate <NSObject>

/**
 User selected an itemType.
 */
- (void)itemTypeSelectionViewChanged:(MenuItemTypeSelectionView *)typeSelectionView type:(NSString *)itemType;

/**
 Helper method for the parentView informing the ideal layout for the view.
 */
- (BOOL)itemTypeSelectionViewRequiresFullSizedLayout:(MenuItemTypeSelectionView *)typeSelectionView;

@end