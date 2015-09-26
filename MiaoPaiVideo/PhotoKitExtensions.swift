//
//  PhotoKitExtensions.swift
//  MiaoPaiVideo
//
//  Created by Phoebe Hu on 9/26/15.
//  Copyright © 2015 Phoebe Hu. All rights reserved.
//

import Foundation
import Photos


func PHAssetSaveToAlbum(creationRequest: () -> PHAssetChangeRequest, inCollection collection: PHAssetCollection? = nil, onComplete completionHandler: ((Bool, String!, NSError!) -> ())? = nil) {
    var localIdentifier: String?
    let changes: dispatch_block_t = {
        let creation = creationRequest()
        localIdentifier = creation.placeholderForCreatedAsset!.localIdentifier
        if let collection = collection {
            PHAssetCollectionChangeRequest(forAssetCollection: collection)!.addAssets([creation.placeholderForCreatedAsset!])
        }
    }
    
    let startTime = NSDate.timeIntervalSinceReferenceDate()
    if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.Authorized {
        print("已授权")
    }
    PHPhotoLibrary.sharedPhotoLibrary().performChanges(changes) { success, error in
        print("success = \(success), error = \(error) used \(NSDate.timeIntervalSinceReferenceDate() - startTime)")
        if let outerCompletionHandler = completionHandler {
            dispatch_async(dispatch_get_main_queue()){
                outerCompletionHandler(success, localIdentifier, error)
            }
        }
    }
}

protocol AlbumCompatible {
    func saveToAlbum(inCollection collection: PHAssetCollection?, onComplete completionHandler: ((Bool, String!, NSError!) -> ())?)
}

enum URLMediaType {
    case Image, Video
}


struct URLAlbumCompatible: AlbumCompatible {
    let creationRequest: () -> PHAssetChangeRequest
    func saveToAlbum(inCollection collection: PHAssetCollection? = nil, onComplete completionHandler: ((Bool, String!, NSError!) -> ())? = nil) {
        PHAssetSaveToAlbum(creationRequest, inCollection: collection, onComplete: completionHandler)
    }
}

extension NSURL {
    func asMedia(type: URLMediaType) -> URLAlbumCompatible {
        switch type {
        case .Image: return URLAlbumCompatible{ PHAssetChangeRequest.creationRequestForAssetFromImageAtFileURL(self)! }
        case .Video: return URLAlbumCompatible{ PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(self)! }
        }
    }
}

extension PHFetchResult {
    var asPHAssets: [PHAsset] {
        return (0 ..< count).map{ self[$0] as! PHAsset }
    }
}

var PHVideoAssets: [PHAsset] {
    let results = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Video, options: nil)
    return results.asPHAssets
}
