import Foundation

public struct Persona: Identifiable, Codable, Hashable {
    public var id: String { email }
    public var name: String
    public var email: String
    public var isDefault: Bool
    public var isPublicSharing: Bool

    public init(name: String, email: String, isDefault: Bool = false, isPublicSharing: Bool = false) {
        self.name = name
        self.email = email
        self.isDefault = isDefault
        self.isPublicSharing = isPublicSharing
    }

    public static let standardPersonas: [Persona] = [
        Persona(
            name: "Jonathan Del Rio",
            email: "jay3oh5@gmail.com",
            isDefault: true,
            isPublicSharing: false
        ),
        Persona(
            name: "Marcus Sterling",
            email: "marcus.sterling92@gmail.com",
            isDefault: false,
            isPublicSharing: true
        )
    ]
}
