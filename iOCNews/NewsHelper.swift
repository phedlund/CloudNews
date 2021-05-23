//
//  NewsHelper.swift
//  iOCNews
//
//  Created by Peter Hedlund on 5/22/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import Foundation

extension OCNewsHelper {

    func backgroundSync() {
        OCAPIClient.shared().requestSerializer = OCAPIClient.httpRequestSerializer()
        OCAPIClient.shared().get("feeds", parameters: nil, headers: nil, progress: nil) { task, response in

            //            if (![responseObject isKindOfClass:[NSDictionary class]])
            //            {
            //                if (self->_completionHandler && !self->completionHandlerCalled) {
            //                    self->_completionHandler(UIBackgroundFetchResultFailed);
            //                    self->completionHandlerCalled = YES;
            //                }
            //                NSDictionary *userInfo = @{@"Title": @"Error Updating Feeds",
            //                                           @"Message": @"Unknown data returned from the server"};
            //                [[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkCompleted" object:self userInfo:nil];
            //                [[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkError" object:self userInfo:userInfo];
            //                return;
            //            }



            self.updateFeeds(response)
            self.updateFolders()

        } failure: { task, error in
            //            if (self->_completionHandler && !self->completionHandlerCalled) {
            //                self->_completionHandler(UIBackgroundFetchResultFailed);
            //                self->completionHandlerCalled = YES;
            //            }
            if let response = task?.response as? HTTPURLResponse {
                let message = "\(error.localizedDescription) (\(HTTPURLResponse.localizedString(forStatusCode: response.statusCode)))"
                let userInfo = ["Title" : "Error Updating Feeds",
                                "Message": message]
                NotificationCenter.default.post(name: .networkCompleted, object: self)
                NotificationCenter.default.post(name: .networkError, object: self, userInfo: userInfo)
            }
        }
    }

}
