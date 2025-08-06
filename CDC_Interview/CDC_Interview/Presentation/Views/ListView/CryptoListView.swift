import SwiftUI
import Combine

// Coordinator protocol for handling navigation from SwiftUI to UIKit
protocol CryptoListCoordinator: AnyObject {
    func didSelectCryptoItem(_ item: CryptoPriceDataType)
}

struct CryptoListView: View {
    @StateObject private var viewModel = ListViewModel()
    weak var coordinator: CryptoListCoordinator?
    
    var body: some View {
        VStack {
            TextField("Search for a token", text: $viewModel.searchText)
                .padding(8)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            if viewModel.displayItems.isEmpty {
                Spacer()
            } else {
                List(viewModel.displayItems, id: \.id) { item in
                    ItemView(priceItem: item, priceText: viewModel.getPriceText(item))
                        .onTapGesture {
                            coordinator?.didSelectCryptoItem(item)
                        }
                }
            }
        }
        .task {
            await viewModel.refreshData()
        }
    }
}


struct ItemView: View {
    let priceItem: any CryptoPriceDataType
    let priceText: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(priceItem.name)
                .font(.headline)
            Text(priceText)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}


#Preview {
    CryptoListView()
}
