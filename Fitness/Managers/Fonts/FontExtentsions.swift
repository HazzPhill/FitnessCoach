//
//  FontExtentsions.swift
//  Wardy Fitness Coach
//
//  Created by Harry Phillips on 11/03/2025.
//

import SwiftUI

extension Font {
    // Macaria font for regular body text
    static func macaria(size: CGFloat) -> Font {
        return .custom("Macaria", size: size)
    }
    
    // Stranded font for headings and titles
    static func AloeveraDisplayRegular(size: CGFloat) -> Font {
        return .custom("AloeveraDisplay", size: size)
    }
    
    // Common text styles using Macaria
    static var macariaNormal: Font {
        return .macaria(size: 16)
    }
    
    static var macariaSmall: Font {
        return .macaria(size: 14)
    }
    
    static var macariaCaption: Font {
        return .macaria(size: 12)
    }
    
    // Common heading styles using Stranded
    static var strandedTitle: Font {
        return .AloeveraDisplayRegular(size: 32)
    }
    
    static var strandedHeadline: Font {
        return .AloeveraDisplayRegular(size: 24)
    }
    
    static var strandedSubheadline: Font {
        return .AloeveraDisplayRegular(size: 20)
    }
}
