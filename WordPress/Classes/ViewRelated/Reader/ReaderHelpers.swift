import Foundation
import WordPressComAnalytics

/// A collection of helper methods used by the Reader.
///
@objc public class ReaderHelpers : NSObject {


    // MARK: - Topic Helpers


    /// Check if the specified topic is a default topic
    ///
    /// - Parameters:
    ///     - topic: A ReaderAbstractTopic
    ///
    /// - Returns: True if the topic is a default topic
    ///
    public class func isTopicDefault(topic:ReaderAbstractTopic) -> Bool {
        return topic.isKindOfClass(ReaderDefaultTopic)
    }


    /// Check if the specified topic is a list
    ///
    /// - Parameters:
    ///     - topic: A ReaderAbstractTopic
    ///
    /// - Returns: True if the topic is a list topic
    ///
    public class func isTopicList(topic:ReaderAbstractTopic) -> Bool {
        return topic.isKindOfClass(ReaderListTopic)
    }


    /// Check if the specified topic is a site topic
    ///
    /// - Parameters:
    ///     - topic: A ReaderAbstractTopic
    ///
    /// - Returns: True if the topic is a site topic
    ///
    public class func isTopicSite(topic:ReaderAbstractTopic) -> Bool {
        return topic.isKindOfClass(ReaderSiteTopic)
    }


    /// Check if the specified topic is a tag topic
    ///
    /// - Parameters:
    ///     - topic: A ReaderAbstractTopic
    ///
    /// - Returns: True if the topic is a tag topic
    ///
    public class func isTopicTag(topic:ReaderAbstractTopic) -> Bool {
        return topic.isKindOfClass(ReaderTagTopic)
    }


    /// Check if the specified topic is for Freshly Pressed
    ///
    /// - Parameters:
    ///     - topic: A ReaderAbstractTopic
    ///
    /// - Returns: True if the topic is for Freshly Pressed
    ///
    public class func topicIsFreshlyPressed(topic: ReaderAbstractTopic) -> Bool {
        let path = topic.path as NSString!
        return path.hasSuffix("/freshly-pressed")
    }


    /// Check if the specified topic is for Discover
    ///
    /// - Parameters:
    ///     - topic: A ReaderAbstractTopic
    ///
    /// - Returns: True if the topic is for Discover
    ///
    public class func topicIsDiscover(topic: ReaderAbstractTopic) -> Bool {
        let path = topic.path as NSString!
        return path.containsString("/read/sites/53424024/posts")
    }


    /// Check if the specified topic is for Following
    ///
    /// - Parameters:
    ///     - topic: A ReaderAbstractTopic
    ///
    /// - Returns: True if the topic is for Following
    ///
    public class func topicIsFollowing(topic: ReaderAbstractTopic) -> Bool {
        let path = topic.path as NSString!
        return path.hasSuffix("/read/following")
    }


    /// Check if the specified topic is for Posts I Like
    ///
    /// - Parameters:
    ///     - topic: A ReaderAbstractTopic
    ///
    /// - Returns: True if the topic is for Posts I Like
    ///
    public class func topicIsLiked(topic: ReaderAbstractTopic) -> Bool {
        let path = topic.path as NSString!
        return path.hasSuffix("/read/liked")
    }


    // MARK: Analytics Helpers

    public class func trackLoadedTopic(topic: ReaderAbstractTopic, withProperties properties:[NSObject : AnyObject]) {
        var stat:WPAnalyticsStat?

        if topicIsFreshlyPressed(topic) {
            stat = .ReaderFreshlyPressedLoaded

        } else if isTopicDefault(topic) && topicIsDiscover(topic) {
            // Tracks Discover only if it was one of the default menu items.
            stat = .ReaderDiscoverViewed

        } else if isTopicList(topic) {
            stat = .ReaderListLoaded

        } else if isTopicTag(topic) {
            stat = .ReaderTagLoaded

        }
        if (stat != nil) {
            WPAnalytics.track(stat!, withProperties: properties)
        }
    }


    public class func statsPropertiesForPost(post:ReaderPost, andValue value:AnyObject?, forKey key:String?) -> [NSObject: AnyObject] {
        var properties = [NSObject: AnyObject]()
        properties[WPAppAnalyticsKeyBlogID] = post.siteID
        properties[WPAppAnalyticsKeyPostID] = post.postID
        properties[WPAppAnalyticsKeyIsJetpack] = post.isJetpack
        if let feedID = post.feedID, feedItemID = post.feedItemID {
            properties[WPAppAnalyticsKeyFeedID] = feedID
            properties[WPAppAnalyticsKeyFeedItemID] = feedItemID
        }

        if let value = value, key = key {
            properties[key] = value
        }

        return properties
    }


    public class func bumpPageViewForPost(post: ReaderPost) {
        // Don't bump page views for feeds else the wrong blog/post get's bumped
        if post.isExternal && !post.isJetpack {
            return
        }

        // If the user is an admin on the post's site do not bump the page view unless
        // the the post is private.
        if !post.isPrivate() && isUserAdminOnSiteWithID(post.siteID) {
            return
        }

        guard let host = NSURL(string: post.blogURL)?.host else {
            return
        }

        let pixelStatReferrer = "https://wordpress.com/"
        let pixel = "https://pixel.wp.com/g.gif"
        let params:NSArray = [
            "v=wpcom",
            "reader=1",
            "ref=\(pixelStatReferrer)",
            "host=\(host)",
            "blog=\(post.siteID)",
            "post=\(post.postID)",
            NSString(format:"t=%d", arc4random())
        ]

        let userAgent = WPUserAgent.wordPressUserAgent()
        let path  = NSString(format: "%@?%@", pixel, params.componentsJoinedByString("&")) as String
        let url = NSURL(string: path)

        let request = NSMutableURLRequest(URL: url!)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.addValue(pixelStatReferrer, forHTTPHeaderField: "Referer")

        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request)
        task.resume()
    }

    public class func isUserAdminOnSiteWithID(siteID:NSNumber) -> Bool {
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)
        if let blog = blogService.blogByBlogId(siteID) {
            return blog.isAdmin
        }
        return false
    }


    // MARK: Logged in helper

    public class func isLoggedIn() -> Bool {
        // Is Logged In
        let service = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        let account = service.defaultWordPressComAccount()
        return account != nil
    }

}
