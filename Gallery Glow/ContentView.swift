import SwiftUI

struct ContentView: View {
    private let data = PaintingData.shared
    @State private var session: GallerySession
    @State private var navigationPath: [Artist] = []
    @Environment(\.scenePhase) private var scenePhase
    @State private var paintingOfTheDay: Painting
    @State private var clockChangeID = UUID()

    init(session: GallerySession? = nil) {
        let session = session ?? GallerySession()
        _session = State(initialValue: session)
        _paintingOfTheDay = State(initialValue: session.freePainting)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 46) {
                        masthead
                        PaintingOfTheDaySection(painting: paintingOfTheDay, onSelect: presentPainting)
                        RecentlyUsedSection { session.present($0) }
                        DirectorsCutSection(paintings: data.directorsCut, onSelect: presentPainting)
                        ArtistsSection(artists: data.artists)
                        GradientsSection(onSelect: presentGradient)
                        HStack {
                            Text("Art for the everyday.").font(GalleryTheme.display(38))
                            Spacer()
                            GalleryEyebrow("Gallery Glow · The collection")
                        }
                        .padding(.horizontal, 64)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 25)
                }
                .onChange(of: navigationPath) { oldPath, newPath in
                    if newPath.isEmpty, let artist = oldPath.first {
                        scrollProxy.scrollTo(artist.id, anchor: .center)
                    }
                }
            }
            .background(GalleryTheme.paper.ignoresSafeArea())
            .navigationDestination(for: Artist.self) { artist in
                ArtistView(artist: artist, onSelect: presentPainting)
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: Binding(
                get: { session.isPresenting },
                set: { if !$0 { session.dismissPresentation() } }
            )) {
                Group {
                    if let selection = session.selection {
                        ScreensaverPresentation(selection: selection).id(selection.id)
                    } else {
                        PaywallView(purchases: session.purchases, painting: paywallPainting,
                                    onClose: session.dismissPresentation)
                    }
                }
                // Gallery and checkout inherit tvOS appearance. Full-screen
                // art uses dark chrome so system panels stay legible over art.
                .preferredColorScheme(session.selection == nil ? nil : .dark)
                .foregroundStyle(session.selection == nil ? GalleryTheme.ink : Color.white)
                .alert("Artwork unavailable", isPresented: $session.linkError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("This item is no longer in the gallery. Choose another painting or gradient.")
                }
            }
        }
        .foregroundStyle(GalleryTheme.ink)
        .onOpenURL { session.open($0) }
        .onChange(of: session.selection != nil) { _, _ in updateIdleTimer() }
        .onChange(of: scenePhase) { _, _ in updateIdleTimer() }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await session.purchases.prepare()
            session.reconcileAccess()
        }
        .onChange(of: session.purchases.entitlement) { _, _ in session.reconcileAccess() }
        .alert("Artwork unavailable", isPresented: Binding(
            get: { session.linkError && !session.isPresenting },
            set: { session.linkError = $0 }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This item is no longer in the gallery. Choose another painting or gradient.")
        }
        .task(id: scenePhase == .active ? clockChangeID : nil) {
            guard scenePhase == .active else { return }
            // Sleep until the next calendar boundary, including DST changes.
            // Foregrounding restarts the task and refreshes immediately.
            while !Task.isCancelled {
                refreshDay()
                let now = Date()
                guard let nextDay = Calendar.current.dateInterval(of: .day, for: now)?.end else { return }
                do { try await Task.sleep(for: .seconds(max(1, nextDay.timeIntervalSince(now)))) }
                catch { return }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            // Recompute both today's selection and the next midnight deadline
            // after clock/time-zone changes; the old sleep uses elapsed time.
            clockChangeID = UUID()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
            ImageCache.shared.removeAll()
        }
    }

    private var paywallPainting: Painting {
        if case .painting(let painting) = session.pendingSelection { return painting }
        return data.allPaintings.first { $0.imageName == "Botticelli/Birth_of_Venus" } ?? paintingOfTheDay
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                GalleryEyebrow("Your private art collection")
                Spacer()
                Button(action: session.showStore) {
                    HStack(spacing: 14) {
                        Text(session.purchases.isUnlocked ? "Your lifetime pass" : "Explore lifetime")
                        Image(systemName: session.purchases.isUnlocked ? "checkmark.seal" : "arrow.up.right")
                    }
                    .font(.system(size: 20, weight: .medium))
                }
                .buttonStyle(GalleryButtonStyle())
                .accessibilityIdentifier("purchaseBannerButton")
            }
            HStack(alignment: .bottom, spacing: 50) {
                Text("GALLERY GLOW")
                    .font(GalleryTheme.wordmark(150))
                    .tracking(-5)
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 10) {
                    Text("A space for art.\nA moment for you.")
                        .font(GalleryTheme.display(29)).lineSpacing(-2)
                    Text("9 artists  ·  5 ambient scenes")
                        .font(.system(size: 18)).foregroundStyle(GalleryTheme.secondary)
                }
                .padding(.bottom, 20)
            }
        }
        .padding(.horizontal, 64)
    }

    private func updateIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = session.selection != nil && scenePhase == .active
    }

    private func refreshDay() {
        paintingOfTheDay = session.freePainting
        session.reconcileAccess()
        TopShelfManager.shared.refreshIfNeeded()
    }

    private func presentPainting(_ painting: Painting) {
        session.present(.painting(painting))
    }

    private func presentGradient(_ palette: GradientPalette) {
        session.present(.gradient(palette))
    }
}

struct PaintingOfTheDaySection: View {
    let painting: Painting
    let onSelect: (Painting) -> Void
    @FocusState private var isFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button { onSelect(painting) } label: {
            HStack(alignment: .center, spacing: 58) {
                FramedPainting(painting: painting, isFocused: isFocused)
                    .scaleEffect(isFocused ? 1.012 : 1)
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 8) {
                        Circle().fill(GalleryTheme.accent).frame(width: 9, height: 9)
                        GalleryEyebrow("On view today · Free")
                    }
                    Text(painting.title)
                        .font(GalleryTheme.display(52)).tracking(-1.5)
                        .lineLimit(3).minimumScaleFactor(0.8)
                    Text("\(painting.artistName)  ·  \(String(painting.year))")
                        .font(.system(size: 22)).foregroundStyle(GalleryTheme.secondary)
                    Text(painting.description)
                        .font(.system(size: 23)).lineSpacing(6)
                        .foregroundStyle(GalleryTheme.secondary).lineLimit(4)
                    Spacer(minLength: 0)
                    HStack {
                        Text("View artwork").font(.system(size: 23, weight: .semibold))
                        Spacer()
                        GalleryArrow(filled: true)
                    }
                    .padding(.leading, 26).padding(.trailing, 9).padding(.vertical, 9)
                    .background(GalleryTheme.surface, in: Capsule())
                }
                .padding(.vertical, 14)
                .frame(width: 440)
            }
            .frame(height: 520)
            .foregroundStyle(GalleryTheme.ink)
        }
        .buttonStyle(GalleryArtworkButtonStyle())
        .focused($isFocused)
        .defaultFocus($isFocused, true)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: isFocused)
        .accessibilityIdentifier("painting-of-the-day")
        .accessibilityLabel("\(painting.title), \(painting.artistName), \(painting.year), Painting of the Day")
        .accessibilityValue("Free today")
        .accessibilityHint("Open today's artwork full screen for free")
        .padding(.horizontal, 64)
    }
}

struct RecentlyUsedSection: View {
    let onSelect: (GallerySession.Selection) -> Void
    private var items: [(RecentlyUsedItem, GallerySession.Selection)] {
        RecentlyUsedManager.shared.items.compactMap { item in
            GallerySession.selection(kind: item.type.rawValue, identifier: item.identifier).map { (item, $0) }
        }
    }
    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 26) {
                GallerySectionHeading(number: "↳", title: "Recently Viewed", detail: "Pick up where you left off")
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 36) {
                        ForEach(items, id: \.1.id) { item, selection in
                            Button { onSelect(selection) } label: {
                                Group {
                                    switch selection {
                                    case .painting(let painting): DirectorsCutCard(painting: painting)
                                    case .gradient(let palette): GradientCard(palette: palette)
                                    }
                                }
                                .frame(width: 400)
                            }
                            .buttonStyle(GalleryButtonStyle(card: true))
                            .accessibilityLabel(item.title)
                            .accessibilityHint("Open screensaver")
                            .accessibilityIdentifier("recent-\(selection.id)")
                        }
                    }
                    .padding(.horizontal, 64)
                    .padding(.vertical, 18)
                }
                .scrollClipDisabled()
            }
        }
    }
}

struct DirectorsCutSection: View {
    let paintings: [Painting]
    let onSelect: (Painting) -> Void
    private let columns = [GridItem(.adaptive(minimum: 400, maximum: 600), spacing: 36)]
    var body: some View {
        VStack(alignment: .leading, spacing: 34) {
            GallerySectionHeading(number: "01", title: "Director’s Cut", detail: "\(paintings.count) selected works")
            LazyVGrid(columns: columns, spacing: 40) {
                ForEach(paintings) { painting in
                    Button { onSelect(painting) } label: { DirectorsCutCard(painting: painting) }
                        .buttonStyle(GalleryButtonStyle(card: true))
                        .accessibilityIdentifier("directors-cut-\(painting.id)")
                        .accessibilityLabel("\(painting.title), \(painting.artistName), \(painting.year)")
                }
            }
            .padding(.horizontal, 64)
        }
    }
}

struct DirectorsCutCard: View {
    let painting: Painting
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            GalleryFrame(inset: 13) {
                PaintingImage(painting.imageName, contentMode: .fit)
                    .frame(height: 210)
            }
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(painting.title).font(GalleryTheme.display(26)).lineLimit(2, reservesSpace: true)
                    Text(painting.artistName).font(.system(size: 18)).foregroundStyle(GalleryTheme.secondary)
                }
                Spacer(minLength: 0)
                Text(String(painting.year)).font(.system(size: 18)).foregroundStyle(GalleryTheme.secondary)
            }
            .padding(.horizontal, 5)
        }
        .padding(20)
        .padding(.bottom, 5)
        .foregroundStyle(GalleryTheme.ink)
        .background(GalleryTheme.surface, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
    }
}

struct ArtistsSection: View {
    let artists: [Artist]
    private let columns = [GridItem(.adaptive(minimum: 300, maximum: 440), spacing: 36)]
    var body: some View {
        VStack(alignment: .leading, spacing: 34) {
            GallerySectionHeading(number: "02", title: "The Artists", detail: "Behind the brushstrokes")
            LazyVGrid(columns: columns, spacing: 40) {
                ForEach(artists) { artist in
                    NavigationLink(value: artist) { ArtistCard(artist: artist) }
                        .buttonStyle(GalleryButtonStyle(card: true))
                        .accessibilityIdentifier("artist-\(artist.id)")
                        .id(artist.id)
                }
            }
            .padding(.horizontal, 64)
        }
    }
}

struct ArtistCard: View {
    let artist: Artist
    var body: some View {
        VStack(alignment: .leading, spacing: 21) {
            if let painting = artist.paintings.first {
                PaintingImage(painting.imageName)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(GalleryTheme.ink.opacity(0.1), lineWidth: 1))
            }
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(artist.name).font(GalleryTheme.display(28)).lineLimit(2, reservesSpace: true)
                    Text(artist.nationality).font(.system(size: 18)).foregroundStyle(GalleryTheme.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right").font(.system(size: 20))
            }
            .padding(.horizontal, 7)
        }
        .padding(17).padding(.bottom, 7)
        .foregroundStyle(GalleryTheme.ink)
        .background(GalleryTheme.surface, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
    }
}

struct GradientsSection: View {
    let onSelect: (GradientPalette) -> Void
    private let columns = [GridItem(.adaptive(minimum: 300, maximum: 440), spacing: 36)]
    var body: some View {
        VStack(alignment: .leading, spacing: 34) {
            GallerySectionHeading(number: "03", title: "Color in Motion", detail: "A change of atmosphere")
            LazyVGrid(columns: columns, spacing: 40) {
                ForEach(GradientPalette.allCases) { palette in
                    Button { onSelect(palette) } label: { GradientCard(palette: palette) }
                        .buttonStyle(GalleryButtonStyle(card: true))
                        .accessibilityIdentifier("gradient-card-\(palette.id)")
                }
            }
            .padding(.horizontal, 64)
        }
    }
}

struct GradientCard: View {
    let palette: GradientPalette
    var body: some View {
        VStack(alignment: .leading, spacing: 21) {
            ZStack {
                LinearGradient(colors: palette.previewColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                Ellipse().fill(palette.previewColors[1]).frame(width: 180, height: 130).blur(radius: 45).offset(x: 70, y: -40)
                Ellipse().fill(palette.previewColors[2]).frame(width: 160, height: 140).blur(radius: 40).offset(x: -80, y: 50)
            }
            .frame(height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(palette.rawValue).font(GalleryTheme.display(28))
                    Text(palette.displayDescription).font(.system(size: 18)).foregroundStyle(GalleryTheme.secondary)
                }
                Spacer()
                Image(systemName: "play.circle").font(.system(size: 28))
            }
            .padding(.horizontal, 7)
        }
        .padding(17).padding(.bottom, 7)
        .foregroundStyle(GalleryTheme.ink)
        .background(GalleryTheme.surface, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
    }
}

#Preview { ContentView() }
