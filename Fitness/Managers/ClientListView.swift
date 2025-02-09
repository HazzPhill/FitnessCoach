import SwiftUI

struct ClientListView: View {
    let groupId: String
    @StateObject private var viewModel: CoachClientsViewModel

    // Define a two-column grid layout.
    private let columns = [
        GridItem(.flexible(), spacing: 26),
        GridItem(.flexible(), spacing: 26)
    ]

    // Initialize the view model with the groupId.
    init(groupId: String) {
        self.groupId = groupId
        _viewModel = StateObject(wrappedValue: CoachClientsViewModel(groupId: groupId))
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 26) {
                ForEach(viewModel.clients, id: \.userId) { client in
                    NavigationLink {
                        ClientView(client: client)
                    } label: {
                        ClientBox(clientName: "\(client.firstName) \(client.lastName)", clientId: client.userId)
                    }
                }
            }
            .padding(.vertical)
            .padding(.horizontal)
        }
    }
}

struct ClientListView_Previews: PreviewProvider {
    static var previews: some View {
        ClientListView(groupId: "dummyGroupId")
    }
}
