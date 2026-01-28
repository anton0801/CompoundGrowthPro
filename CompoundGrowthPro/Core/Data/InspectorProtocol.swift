import Firebase
import FirebaseDatabase

protocol InspectorProtocol {
    func inspect() async throws -> Bool
}

final class Inspector: InspectorProtocol {
    func inspect() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            Database.database().reference().child("users/log/data")
                .observeSingleEvent(of: .value) { snapshot in
                    if let urlString = snapshot.value as? String,
                       !urlString.isEmpty,
                       URL(string: urlString) != nil {
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                } withCancel: { error in
                    continuation.resume(throwing: error)
                }
        }
    }
}
