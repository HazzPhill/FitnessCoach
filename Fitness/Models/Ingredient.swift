import Foundation

struct Ingredient: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var amount: String
    var protein: String
    var calories: String
    var carbs: String
    var fats: String
}
