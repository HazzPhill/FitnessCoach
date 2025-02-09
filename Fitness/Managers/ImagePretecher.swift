//
//  ImagePretecher.swift
//  Fitness
//
//  Created by Harry Phillips on 06/02/2025.
//

import SwiftUI

final class ImagePrefetcher: ObservableObject {
    static let shared = ImagePrefetcher()
    
    private let cache = NSCache<NSString, UIImage>()
    
    // Prefetch images for a given array of URLs
    func prefetch(urls: [URL]) async {
        for url in urls {
            // Skip if the image is already cached
            if cache.object(forKey: url.absoluteString as NSString) != nil {
                continue
            }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    cache.setObject(image, forKey: url.absoluteString as NSString)
                    print("Prefetched image from \(url)")
                }
            } catch {
                print("Failed to prefetch image from \(url): \(error)")
            }
        }
    }
    
    // Retrieve a cached image, if available
    func image(for url: URL) -> UIImage? {
        return cache.object(forKey: url.absoluteString as NSString)
    }
}

