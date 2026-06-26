import SwiftUI

struct FavoriteButton: View {
    @ObservedObject var favorites: FavoritesStore
    let day: FestivalDay
    let bandId: Int
    var iconSize: CGFloat = 16
    var favoriteColor: Color = JeraTheme.accentGold

    private var isFavorite: Bool {
        favorites.isFavorite(day: day, bandId: bandId)
    }

    var body: some View {
        Button {
            favorites.toggle(day: day, bandId: bandId)
        } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(isFavorite ? favoriteColor : JeraTheme.textSecondary)
                .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
        }
        .buttonStyle(.plain)
    }
}
