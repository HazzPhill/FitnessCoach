//
//  FontExtentsions.swift
//  Wardy Fitness Coach
//
//  Created by Harry Phillips on 11/03/2025.
//

import SwiftUI

extension Font {
    // Macaria font for regular body text
    static func Mansfield(size: CGFloat) -> Font {
        return .custom("Mansfield", size: size)
    }
    
    static func manfieldSemiBold(size: CGFloat) -> Font {
        return .custom("Mansfield Semi Bold", size: size)
    }
    
    // Common text styles using Macaria
    static var macariaNormal: Font {
        return .Mansfield(size: 16)
    }
    
    static var macariaSmall: Font {
        return .Mansfield(size: 14)
    }
    
    static var macariaCaption: Font {
        return .Mansfield(size: 12)
    }
    
    // Common heading styles using Stranded
    static var strandedTitle: Font {
        return .manfieldSemiBold(size: 32)
    }
    
    static var strandedHeadline: Font {
        return .manfieldSemiBold(size: 24)
    }
    
    static var strandedSubheadline: Font {
        return .manfieldSemiBold(size: 20)
    }
}
