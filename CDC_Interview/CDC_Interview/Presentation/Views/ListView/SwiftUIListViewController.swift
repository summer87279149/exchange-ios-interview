import SwiftUI
import Combine

struct CryptoListView: View {
    @StateObject private var viewModel = ListViewModel()

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(maxWidth: .infinity,maxHeight: .infinity)
            }else{
                TextField("Search for a token", text: $viewModel.searchText)
                    .padding(8)
                List(viewModel.displayItems, id: \.id) { item in
                    ItemView(priceItem: item, priceText: viewModel.getPriceText(item))
                       
                }
            }
        }
        .task {
            await viewModel.fetchItems(showLoading: true)
        }
    }
}


struct ItemView: View {
    let priceItem: any PriceViewModelType
    let priceText: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(priceItem.name)
                .font(.headline)
            Text(priceText)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}


#Preview {
    CryptoListView()
}
