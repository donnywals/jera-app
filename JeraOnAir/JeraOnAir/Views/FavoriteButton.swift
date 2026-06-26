import SwiftUI

struct FavoriteButton: View {
    @ObservedObject var favorites: FavoritesStore
    let day: FestivalDay
    let bandId: Int

    private var isFavorite: Bool {
        favorites.isFavorite(day: day, bandId: bandId)
    }

    var body: some View {
        Button {
            favorites.toggle(day: day, bandId: bandId)
        } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isFavorite ? JeraTheme.accentGold : JeraTheme.textSecondary)
                .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
        }
        .buttonStyle(.plain)
    }
}
