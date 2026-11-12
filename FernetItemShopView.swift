import SwiftUI

struct FernetItemShopView: View {
    @EnvironmentObject var vm: FernetShopViewModel
    @State private var selectedItem: ShopItem? = nil
    @State private var vbucks: Int = 13500

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        FernetSectionHeader(title: "Item Shop", subtitle: "Today's featured cosmetics")
                        Spacer()
                        vbucksDisplay
                    }
                    .padding(.top, 60)

                    // Featured
                    featuredSection

                    // Daily
                    dailySection

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
            }
            .background(FernetBackground())

            // Purchase animation overlay
            if vm.showPurchaseAnim {
                purchaseOverlay
            }
        }
        .sheet(item: $selectedItem) { item in
            ItemDetailSheet(item: item, vbucks: $vbucks) {
                vm.purchase(item)
                vbucks -= item.price
            }
        }
    }

    // MARK: V-Bucks Display
    private var vbucksDisplay: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(FernetGradients.goldPodium)
                .frame(width: 18, height: 18)
                .overlay(
                    Text("V")
                        .font(FernetFont.display(10))
                        .foregroundStyle(.black)
                )
            Text("\(vbucks)")
                .font(FernetFont.mono(16))
                .foregroundStyle(.fernetGold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassCard(cornerRadius: 20)
    }

    // MARK: Featured
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Featured Items", systemImage: "star.fill")
                .font(FernetFont.display(13))
                .tracking(2)
                .foregroundStyle(.fernetGold)

            VStack(spacing: 12) {
                ForEach(vm.featuredItems) { item in
                    FeaturedItemCard(item: item) {
                        selectedItem = item
                    }
                }
            }
        }
    }

    // MARK: Daily
    private var dailySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Daily Items", systemImage: "clock.fill")
                .font(FernetFont.display(13))
                .tracking(2)
                .foregroundStyle(.fernetCyan)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(vm.dailyItems) { item in
                    DailyItemCard(item: item) {
                        selectedItem = item
                    }
                }
            }
        }
    }

    // MARK: Purchase Overlay
    private var purchaseOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(FernetGradients.pinkAccent)
                        .frame(width: 80, height: 80)
                        .shadow(color: .fernetPink.opacity(0.6), radius: 20)
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .black))
                        .foregroundStyle(.black)
                }
                .scaleEffect(vm.showPurchaseAnim ? 1 : 0.3)
                .animation(.spring(duration: 0.5, bounce: 0.6), value: vm.showPurchaseAnim)

                Text("PURCHASED!")
                    .font(FernetFont.display(22))
                    .tracking(3)
                    .foregroundStyle(.white)
                    .opacity(vm.showPurchaseAnim ? 1 : 0)
                    .animation(.easeIn(duration: 0.3).delay(0.2), value: vm.showPurchaseAnim)
            }
        }
        .transition(.opacity)
    }
}

// MARK: - Featured Item Card

struct FeaturedItemCard: View {
    let item: ShopItem
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Item preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(item.rarity.gradient)
                        .frame(width: 72, height: 72)
                    Image(systemName: iconForType(item.type))
                        .font(.system(size: 26))
                        .foregroundStyle(.white.opacity(0.9))
                    if item.isOwned {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 72, height: 72)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.green)
                    }
                }

                // Info
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.name)
                        .font(FernetFont.display(15))
                        .foregroundStyle(.white)
                    Text(item.description)
                        .font(FernetFont.caption(12))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        Text(item.rarity.rawValue.uppercased())
                            .font(FernetFont.caption(9))
                            .tracking(1.5)
                            .foregroundStyle(item.rarity.color)
                        Text("·")
                            .foregroundStyle(.white.opacity(0.3))
                        Text(item.type.rawValue.uppercased())
                            .font(FernetFont.caption(9))
                            .tracking(1.5)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }

                Spacer()

                // Price
                VStack(spacing: 3) {
                    Circle()
                        .fill(FernetGradients.goldPodium)
                        .frame(width: 20, height: 20)
                        .overlay(Text("V").font(FernetFont.display(10)).foregroundStyle(.black))
                    Text("\(item.price)")
                        .font(FernetFont.mono(13))
                        .foregroundStyle(.fernetGold)
                }
            }
            .padding(14)
            .glassCard(cornerRadius: 16)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = pressing }
        }, perform: {})
    }
}

// MARK: - Daily Item Card

struct DailyItemCard: View {
    let item: ShopItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Art area
                ZStack {
                    Rectangle()
                        .fill(item.rarity.gradient)
                        .frame(height: 110)
                    Image(systemName: iconForType(item.type))
                        .font(.system(size: 34))
                        .foregroundStyle(.white.opacity(0.85))
                    if item.isOwned {
                        Rectangle()
                            .fill(Color.black.opacity(0.5))
                            .frame(height: 110)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.green)
                    }

                    // Rarity top bar
                    VStack {
                        HStack {
                            Text(item.rarity.rawValue.uppercased())
                                .font(FernetFont.caption(8))
                                .tracking(1.5)
                                .foregroundStyle(.black.opacity(0.7))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(item.rarity.color)
                                .clipShape(Capsule())
                                .padding(8)
                            Spacer()
                        }
                        Spacer()
                    }
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(FernetFont.label(12))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    HStack {
                        Text(item.type.rawValue.uppercased())
                            .font(FernetFont.caption(9))
                            .tracking(1)
                            .foregroundStyle(.white.opacity(0.4))
                        Spacer()
                        HStack(spacing: 3) {
                            Circle()
                                .fill(FernetGradients.goldPodium)
                                .frame(width: 12, height: 12)
                                .overlay(Text("V").font(.system(size: 7, weight: .black)).foregroundStyle(.black))
                            Text("\(item.price)")
                                .font(FernetFont.mono(11))
                                .foregroundStyle(.fernetGold)
                        }
                    }
                }
                .padding(10)
            }
            .background(FernetGradients.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(item.rarity.color.opacity(0.3), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Item Detail Sheet

struct ItemDetailSheet: View {
    let item: ShopItem
    @Binding var vbucks: Int
    let onPurchase: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var showConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                FernetBackground().ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        // Large preview
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(item.rarity.gradient)
                                .frame(height: 260)
                            Image(systemName: iconForType(item.type))
                                .font(.system(size: 80))
                                .foregroundStyle(.white.opacity(0.85))
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(FernetFont.display(22))
                                        .foregroundStyle(.white)
                                    HStack(spacing: 8) {
                                        Text(item.rarity.rawValue.uppercased())
                                            .font(FernetFont.caption(10))
                                            .tracking(2)
                                            .foregroundStyle(item.rarity.color)
                                        Text("·")
                                            .foregroundStyle(.white.opacity(0.3))
                                        Text(item.type.rawValue.uppercased())
                                            .font(FernetFont.caption(10))
                                            .tracking(2)
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                }
                                Spacer()
                                VStack(spacing: 3) {
                                    Circle()
                                        .fill(FernetGradients.goldPodium)
                                        .frame(width: 24, height: 24)
                                        .overlay(Text("V").font(FernetFont.display(12)).foregroundStyle(.black))
                                    Text("\(item.price)")
                                        .font(FernetFont.mono(18))
                                        .foregroundStyle(.fernetGold)
                                }
                            }

                            Text(item.description)
                                .font(FernetFont.caption(14))
                                .foregroundStyle(.white.opacity(0.6))
                                .lineSpacing(5)

                            // Buy button
                            if item.isOwned {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text("ALREADY OWNED")
                                        .font(FernetFont.display(14))
                                        .tracking(2)
                                        .foregroundStyle(.green)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .glassCard(cornerRadius: 14)
                            } else {
                                Button {
                                    guard vbucks >= item.price else { return }
                                    showConfirm = true
                                } label: {
                                    HStack(spacing: 10) {
                                        Circle()
                                            .fill(FernetGradients.goldPodium)
                                            .frame(width: 20, height: 20)
                                            .overlay(Text("V").font(FernetFont.display(10)).foregroundStyle(.black))
                                        Text("BUY FOR \(item.price)")
                                            .font(FernetFont.display(15))
                                            .tracking(2)
                                    }
                                    .foregroundStyle(vbucks >= item.price ? .black : .white.opacity(0.3))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(
                                        vbucks >= item.price
                                            ? AnyShapeStyle(FernetGradients.goldPodium)
                                            : AnyShapeStyle(Color.white.opacity(0.07))
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                                .disabled(vbucks < item.price)
                            }

                            if vbucks < item.price && !item.isOwned {
                                Text("Not enough V-Bucks")
                                    .font(FernetFont.caption(12))
                                    .foregroundStyle(.red.opacity(0.7))
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .confirmationDialog("Confirm Purchase", isPresented: $showConfirm) {
                Button("Buy \(item.name) for \(item.price) V-Bucks") {
                    onPurchase()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will deduct \(item.price) V-Bucks from your balance.")
            }
        }
    }
}

// MARK: - Helper

func iconForType(_ type: ShopItem.ItemType) -> String {
    switch type {
    case .outfit:   return "person.fill"
    case .glider:   return "wind"
    case .pickaxe:  return "hammer.fill"
    case .emote:    return "music.note"
    case .wrap:     return "paintbrush.fill"
    }
}
