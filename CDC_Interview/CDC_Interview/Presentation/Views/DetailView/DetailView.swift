import SwiftUI

struct DetailView: View {
    private let item: CryptoPriceDataType
    @StateObject private var viewModel: DetailViewModel
    
    init(item: CryptoPriceDataType,
         dependencyProvider: ListViewModelDependencyProviderType = Dependency.shared) {
        self.item = item
        _viewModel = StateObject(
            wrappedValue:DetailViewModel(
                item: item,
                dependencyProvider: dependencyProvider)
        )
        
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(item.name)
                .padding(.top)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                if viewModel.showEURPrice{
                    PriceRow(label: "USD", value: viewModel.formattedUSDPrice)
                    PriceRow(label: "EUR", value: viewModel.formattedEURPrice)
                } else {
                    PriceRow(label: "USD", value: viewModel.formattedUSDPrice)
                }
            }
            Spacer()
        }
        .padding()
    }
}

struct PriceRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    NavigationView {
        DetailView(item: MockPriceItem(id: 1, name: "BTC", usdPrice: 50000, eurPrice: 45000))
    }
}

struct MockPriceItem: CryptoPriceDataType {
    var id: Int
    var name: String
    var usdPrice: Decimal
    var eurPrice: Decimal?
}
