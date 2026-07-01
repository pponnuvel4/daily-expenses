import SwiftUI

struct FavoritesBarView: View {
    let favorites: [FavoriteExpense]
    let onAdd: (FavoriteExpense) -> Void
    let onRemove: (FavoriteExpense) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Favorites", systemImage: "star.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(favorites) { favorite in
                        Button {
                            onAdd(favorite)
                        } label: {
                            Text(favorite.displayName)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.orange.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Remove favorite", role: .destructive) {
                                onRemove(favorite)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
