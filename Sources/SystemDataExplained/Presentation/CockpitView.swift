import SwiftUI
import AppKit
import SDEDomain

struct CockpitView: View {
    @ObservedObject var model: AppModel

    @State private var expandedCategoryID: String?
    @State private var expandedItemID: String?
    @State private var showRevealError = false
    @AppStorage("readingScale") private var readingScale = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor).ignoresSafeArea()

            VStack(spacing: 0) {
                CockpitHeader(
                    phase: model.phase,
                    checkAgain: model.startExplanation,
                    stop: model.stopExplanation,
                    readingScale: $readingScale
                )

                Group {
                    switch model.phase {
                    case .onboarding:
                        ScrollView {
                            OpeningState(begin: model.startExplanation)
                                .padding(.vertical, 22)
                        }
                    case .working:
                        WorkingState(progress: model.progress)
                    case .results:
                        if let report = model.report {
                            ResultsState(
                                report: report,
                                expandedCategoryID: $expandedCategoryID,
                                expandedItemID: $expandedItemID,
                                revealInFinder: reveal
                            )
                        } else {
                            OpeningState(begin: model.startExplanation)
                        }
                    case .failed:
                        FailureState(
                            message: model.errorMessage ?? "The check could not finish.",
                            tryAgain: model.startExplanation,
                            goBack: model.returnToStart
                        )
                    }
                }
                .frame(maxWidth: 1060, maxHeight: .infinity)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .tint(.sdeBlue)
        .environment(\.readingScale, min(2, max(1, readingScale)))
        .transaction { if reduceMotion { $0.animation = nil } }
        .alert("Finder could not open this location", isPresented: $showRevealError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The item changed, moved, or is no longer accessible. Check again to refresh it. The app won’t open a different folder in its place.")
        }
    }

    private func reveal(_ location: ObservedLocation) {
        showRevealError = !model.revealInFinder(location)
    }
}

private struct CockpitHeader: View {
    let phase: AppModel.Phase
    let checkAgain: () -> Void
    let stop: () -> Void
    @Binding var readingScale: Double

    var body: some View {
        HStack(spacing: 14) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text("System Data Explained")
                    .sdeFont(15, weight: .medium)
                    .foregroundStyle(Color.sdeInk)
                Text("Clarity for the space macOS does not explain")
                    .sdeFont(12, weight: .regular)
                    .foregroundStyle(Color.sdeMuted)
            }

            Spacer()

            Menu {
                Button("Standard text") { readingScale = 1 }
                Button("Larger text") { readingScale = 1.25 }
                Button("Extra large text") { readingScale = 1.5 }
                Button("Largest text") { readingScale = 2 }
            } label: {
                Image(systemName: "textformat.size")
                    .font(.system(size: 18))
                    .frame(minWidth: 44, minHeight: 48)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .accessibilityLabel("Text size")

            if phase == .results {
                Button(action: checkAgain) {
                    Label("Check Again", systemImage: "arrow.clockwise")
                        .sdeFont(13, weight: .regular)
                        .frame(minWidth: 128, minHeight: 44)
                }
                .modifier(SecondaryGlassButton())
            } else if phase == .working {
                Button(action: stop) {
                    Label("Stop", systemImage: "stop.fill")
                        .sdeFont(13, weight: .regular)
                        .frame(minWidth: 128, minHeight: 44)
                }
                .modifier(SecondaryGlassButton())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .modifier(FunctionalGlassBar())
    }
}

struct OpeningState: View {
    let begin: () -> Void
    @Environment(\.readingScale) private var readingScale

    var body: some View {
        let layout = readingScale > 1.2 ? AnyLayout(VStackLayout(alignment: .leading, spacing: 24)) : AnyLayout(HStackLayout(spacing: 32))
        layout {
            invitation
                .frame(maxWidth: .infinity, alignment: .leading)
            SystemDataSample()
                .frame(width: 370)
        }
        .padding(.vertical, 12)
    }

    private var invitation: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("130 GB called\n“System Data.”")
                .sdeFont(30, weight: .medium)
                .foregroundStyle(Color.sdeInk)

            Text("My Mac showed this. If yours does too, find what’s taking space and what’s worth keeping.")
                .sdeFont(15, weight: .regular)
                .foregroundStyle(Color.sdeMuted)
                .lineSpacing(3)

            Button(action: begin) {
                Text("Explain My System Data")
                    .sdeFont(14, weight: .medium)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .padding(.horizontal, 18)
            }
            .modifier(PrimaryGlassButton())
            .accessibilityHint("Finds and explains hidden storage without changing your files")

            Label("Private · Read-only · Stays on this Mac", systemImage: "lock.shield.fill")
                .sdeFont(13, weight: .regular)
                .foregroundStyle(Color.sdeMuted)

            Text("The app cannot delete or change your files. No filenames or storage information leave this Mac.")
                .sdeFont(13, weight: .regular)
                .foregroundStyle(Color.sdeMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

enum SystemDataExample: String, CaseIterable {
    case before
    case after

    var title: String { self == .before ? "Before" : "After" }
    var size: String { self == .before ? "130.03 GB" : "75.34 GB" }

    var image: NSImage? {
        let resourceBundle = Bundle.main.resourceURL?.appendingPathComponent("SystemDataExplained_SystemDataExplained.bundle")
        var url = resourceBundle.flatMap(Bundle.init(url:))?.url(forResource: rawValue, withExtension: "png")
        #if DEBUG
        if url == nil { url = Bundle.module.url(forResource: rawValue, withExtension: "png") }
        #endif
        guard let url else {
            return nil
        }
        return NSImage(contentsOf: url)
    }
}

struct SystemDataSample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("My Mac")
                .sdeFont(13)
                .foregroundStyle(Color.sdeMuted)

            ForEach(SystemDataExample.allCases, id: \.self) { example in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(example.title).sdeFont(13)
                        Spacer(minLength: 8)
                        Text(example.size).sdeFont(15, weight: .medium).monospacedDigit()
                    }
                    .foregroundStyle(Color.sdeInk)

                    if let image = example.image {
                        Image(nsImage: image)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .accessibilityHidden(true)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(example.title): \(example.size) of System Data on my Mac")
            }

            Text("I chose what to remove.")
                .sdeFont(13)
                .foregroundStyle(Color.sdeMuted)
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.32), lineWidth: 1)
        }
    }
}

struct WorkingState: View {
    let progress: ScanProgress

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.sdeBlue.opacity(0.08))
                    .frame(width: 96, height: 96)
                ProgressView()
                    .controlSize(.large)
                    .tint(.sdeBlue)
            }

            VStack(spacing: 8) {
                Text("Finding the answer…")
                    .sdeFont(22, weight: .medium)
                    .foregroundStyle(Color.sdeInk)
                Text("\(ByteFormatting.string(progress.measuredBytes)) found so far")
                    .sdeFont(17, weight: .regular).monospacedDigit()
                    .foregroundStyle(Color.sdeBlue)
            }

            Text("macOS may ask for access to some folders. You may decline. Those locations may be missing from the results.")
                .sdeFont(13)
                .foregroundStyle(Color.sdeMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 580)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ResultsState: View {
    let report: ExplanationReport
    @Binding var expandedCategoryID: String?
    @Binding var expandedItemID: String?
    let revealInFinder: (ObservedLocation) -> Void
    @AppStorage("hideDevelopmentSupportInvitation") private var hideSupportInvitation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ResultHero(report: report)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                if report.isPartial {
                    Text("Some storage couldn’t be checked. Sizes may be incomplete.")
                        .sdeFont(13)
                        .foregroundStyle(Color.sdeMuted)
                        .padding(.bottom, 10)
                }

                HStack {
                    Text("What makes up the number")
                        .sdeFont(15, weight: .medium)
                        .foregroundStyle(Color.sdeInk)
                    Spacer()
                    Text("Largest first")
                        .sdeFont(12)
                        .foregroundStyle(Color.sdeMuted)
                }
                .padding(.vertical, 10)

                SubtleLine()

                VStack(spacing: 12) {
                    ForEach(report.categories) { summary in
                        CategoryAccordion(
                            summary: summary,
                            isExpanded: expandedCategoryID == summary.id,
                            expandedItemID: $expandedItemID,
                            toggle: {
                                withAnimation(.snappy(duration: 0.28)) {
                                    if expandedCategoryID == summary.id {
                                        expandedCategoryID = nil
                                        expandedItemID = nil
                                    } else {
                                        expandedCategoryID = summary.id
                                        expandedItemID = nil
                                    }
                                }
                            },
                            revealInFinder: revealInFinder
                        )
                    }

                    VisibilityDisclosure(report: report)

                    if !hideSupportInvitation {
                        DevelopmentSupportInvitation {
                            hideSupportInvitation = true
                        }
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .scrollIndicators(.automatic)
        .frame(maxHeight: .infinity)
    }
}

private struct DevelopmentSupportInvitation: View {
    let hideForever: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            Image(systemName: "heart")
                .sdeFont(17, weight: .regular)
                .foregroundStyle(Color.sdeMuted)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("Did this help?")
                    .sdeFont(14, weight: .medium)
                    .foregroundStyle(Color.sdeInk)
                Text("Support continued development with an optional $4.99 purchase.")
                    .sdeFont(13, weight: .regular)
                    .foregroundStyle(Color.sdeMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Button("Never show again", action: hideForever)
                .buttonStyle(.plain)
                .sdeFont(13, weight: .regular)
                .foregroundStyle(Color.sdeMuted)
                .frame(minHeight: 44)

            Button("Support Development") {
                DevelopmentSupport.open()
            }
            .sdeFont(13, weight: .regular)
            .frame(minWidth: 154, minHeight: 44)
            .modifier(SecondaryGlassButton())
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

private struct ResultHero: View {
    let report: ExplanationReport
    @Environment(\.readingScale) private var readingScale

    private var largest: CategorySummary? { report.categories.first }

    var body: some View {
        let layout = readingScale > 1.2 ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16)) : AnyLayout(HStackLayout(spacing: 18))
        layout {
            VStack(alignment: .leading, spacing: 6) {
                Text("Storage found on this Mac")
                    .sdeFont(12, weight: .regular)
                    .foregroundStyle(Color.sdeMuted)
                Text(ByteFormatting.string(report.scan.measuredBytes))
                    .sdeFont(26, weight: .medium).monospacedDigit()
                    .foregroundStyle(Color.sdeInk)
                if let largest {
                    Text("Start with \(largest.category.title.lowercased()).")
                        .sdeFont(13, weight: .regular)
                        .foregroundStyle(Color.sdeMuted)
                }
            }

            Spacer()

            if let largest {
                VStack(alignment: .trailing, spacing: 5) {
                    Image(systemName: largest.category.symbolName)
                        .sdeFont(17, weight: .regular)
                        .foregroundStyle(Color.sdeMuted)
                    Text(ByteFormatting.string(largest.measuredBytes))
                        .sdeFont(17, weight: .medium).monospacedDigit()
                        .foregroundStyle(Color.sdeInk)
                    Text(largest.category.title)
                        .sdeFont(12, weight: .regular)
                        .foregroundStyle(Color.sdeMuted)
                }
                .padding(12)
                .frame(minWidth: 170)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.32), lineWidth: 1)
        }
    }
}

private struct CategoryAccordion: View {
    let summary: CategorySummary
    let isExpanded: Bool
    @Binding var expandedItemID: String?
    let toggle: () -> Void
    let revealInFinder: (ObservedLocation) -> Void

    @State private var showAllItems = false

    private var visibleItems: ArraySlice<ExplanationItem> {
        showAllItems ? summary.items[...] : summary.items.prefix(5)
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: toggle) {
                HStack(spacing: 16) {
                    Image(systemName: summary.category.symbolName)
                        .sdeFont(18, weight: .regular)
                        .foregroundStyle(Color.sdeInk)
                        .frame(width: 36, height: 36)
                        .background(Color(nsColor: .unemphasizedSelectedContentBackgroundColor), in: RoundedRectangle(cornerRadius: 9))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(summary.category.title)
                            .sdeFont(15, weight: .medium)
                            .foregroundStyle(Color.sdeInk)
                        Text(summary.category.summary)
                            .sdeFont(13, weight: .regular)
                            .foregroundStyle(Color.sdeMuted)
                    }

                    Spacer()

                    Text(ByteFormatting.string(summary.measuredBytes))
                        .sdeFont(15, weight: .medium).monospacedDigit()
                        .foregroundStyle(Color.sdeInk)

                    Image(systemName: "chevron.down")
                        .sdeFont(12, weight: .medium)
                        .foregroundStyle(Color.sdeMuted)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .frame(width: 32, height: 44)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .frame(minHeight: 60)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")

            if isExpanded {
                SubtleLine()
                    .padding(.horizontal, 18)

                VStack(spacing: 8) {
                    ForEach(visibleItems) { item in
                        ItemAccordion(
                            item: item,
                            isExpanded: expandedItemID == item.id,
                            toggle: {
                                withAnimation(.snappy(duration: 0.24)) {
                                    expandedItemID = expandedItemID == item.id ? nil : item.id
                                }
                            },
                            revealInFinder: revealInFinder
                        )
                    }

                    if summary.items.count > 5 {
                        Button {
                            withAnimation(.snappy(duration: 0.22)) {
                                showAllItems.toggle()
                            }
                        } label: {
                            Text(showAllItems ? "Show fewer" : "Show \(summary.items.count - 5) more")
                                .sdeFont(13, weight: .regular)
                                .foregroundStyle(Color.sdeMuted)
                                .frame(maxWidth: .infinity, minHeight: 46)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    isExpanded ? Color.sdeBlue.opacity(0.24) : Color(nsColor: .separatorColor).opacity(0.32),
                    lineWidth: 1
                )
        }
    }
}

private struct ItemAccordion: View {
    let item: ExplanationItem
    let isExpanded: Bool
    let toggle: () -> Void
    let revealInFinder: (ObservedLocation) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: toggle) {
                HStack(spacing: 13) {
                    Image(systemName: item.classification.risk.symbolName)
                        .sdeFont(14, weight: .regular)
                        .foregroundStyle(Color.sdeMuted)
                        .frame(width: 30, height: 30)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .sdeFont(14, weight: .medium)
                            .foregroundStyle(Color.sdeInk)
                        Text(item.classification.displayName == item.title ? (item.classification.guidance?.kind == .simulatorDevice ? "Saved test data" : item.classification.risk.title) : item.classification.displayName)
                            .sdeFont(12, weight: .regular)
                            .foregroundStyle(Color.sdeMuted)
                    }

                    Spacer()

                    Text(ByteFormatting.string(item.measuredBytes))
                        .sdeFont(14, weight: .medium).monospacedDigit()
                        .foregroundStyle(Color.sdeInk)

                    Image(systemName: "plus")
                        .sdeFont(12, weight: .regular)
                        .foregroundStyle(Color.sdeMuted)
                        .rotationEffect(.degrees(isExpanded ? 45 : 0))
                        .frame(width: 32, height: 44)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(minHeight: 52)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                InlineItemDetail(item: item, revealInFinder: revealInFinder)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(nsColor: isExpanded ? .selectedContentBackgroundColor : .windowBackgroundColor).opacity(isExpanded ? 0.08 : 0.72), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct InlineItemDetail: View {
    let item: ExplanationItem
    let revealInFinder: (ObservedLocation) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SubtleLine()
            if let guidance = item.classification.guidance {
                Text(guidance.summary)
                    .sdeFont(13)
                    .foregroundStyle(Color.sdeInk)
                explanation("If removed", guidance.consequence)
                explanation("Can I get it back?", guidance.recovery)
                explanation("Next step", guidance.nextStep)

                if item.classification.allowsFinderReveal {
                    HStack {
                        if let location = item.location {
                            Button { revealInFinder(location) } label: {
                                Label("Show this item in Finder", systemImage: "folder")
                                    .sdeFont(13)
                                    .padding(.horizontal, 12)
                                    .frame(minHeight: 48)
                            }
                            .modifier(SecondaryGlassButton())
                            .accessibilityHint("Selects " + item.title + ". Does not delete it.")
                        } else {
                            Text("Location could not be verified. Check again before opening it.")
                                .sdeFont(13)
                                .foregroundStyle(Color.sdeMuted)
                        }
                        Spacer(minLength: 0)
                    }
                } else {
                    Label("This item is marked Keep, so the app does not open its folder.", systemImage: "lock.fill")
                        .sdeFont(13)
                        .foregroundStyle(Color.sdeMuted)
                        .frame(minHeight: 44)
                }

                if !guidance.fallbackSteps.isEmpty {
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(Array(guidance.fallbackSteps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1).").foregroundStyle(Color.sdeMuted)
                                    Text(step).fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            if guidance.kind == .simulatorDevice {
                                Text("This app has not checked Xcode’s device list or whether this device is in use.")
                                    .foregroundStyle(Color.sdeMuted)
                            }
                        }
                        .sdeFont(13)
                        .foregroundStyle(Color.sdeInk)
                        .padding(.vertical, 10)
                    } label: {
                        Text(guidance.fallbackTitle).sdeFont(13).frame(minHeight: 44)
                    }
                    .foregroundStyle(Color.sdeMuted)
                }
            } else {
                Text("Inspect this item before deciding. Its removal and recovery have not been assessed.")
                    .sdeFont(13)
            }

            DisclosureGroup {
                VStack(alignment: .leading, spacing: 12) {
                    if let owner = item.classification.owner { LabeledContent("Used by", value: owner) }
                    if let simulator = item.simulator {
                        LabeledContent("Device name", value: simulator.name)
                        if let runtime = simulator.runtime {
                            Text("Software reference: " + runtime).textSelection(.enabled)
                        }
                    } else if item.classification.guidance?.kind == .simulatorDevice {
                        Text("The device name could not be read. The folder name is shown instead.")
                    }
                    LabeledContent("Measured size", value: ByteFormatting.string(item.measuredBytes))
                    Text("Size is not a promise of space you can recover. Files may change after this check.")
                    if let path = item.classification.reviewPath {
                        Text(path).sdeFont(12, design: .monospaced).textSelection(.enabled)
                    }
                    if let source = item.classification.guidance?.sourceURL, let url = URL(string: source) {
                        Link("Read the supporting guide ↗", destination: url)
                            .frame(minHeight: 44)
                            .foregroundStyle(Color.sdeBlue)
                    }
                }
                .sdeFont(13)
                .padding(.vertical, 10)
            } label: {
                Text("Why the app identified this").sdeFont(13).frame(minHeight: 44)
            }
            .foregroundStyle(Color.sdeMuted)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
    }

    private func explanation(_ label: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).sdeFont(12).foregroundStyle(Color.sdeMuted)
            Text(text).sdeFont(13).foregroundStyle(Color.sdeInk)
        }
    }
}

private struct VisibilityDisclosure: View {
    let report: ExplanationReport

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 12) {
                Text("This covers the locations checked, not every file on your Mac or Apple’s exact System Data total.")
                if report.isPartial {
                    Text("Some sizes may be incomplete. You can keep these results and check again after changing access.")
                    ForEach(report.scan.summary.issueCounts.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { kind in
                        LabeledContent(issueTitle(kind), value: report.scan.summary.issueCounts[kind, default: 0].formatted())
                    }
                    Text("These are recorded issues, not a count of unique folders.")
                }
                if let volume = report.scan.volume {
                    LabeledContent("Free space on disk", value: ByteFormatting.string(volume.freeBytes))
                    Text("Finder may show more available space because macOS can also reclaim some purgeable storage. This report explains files the app could measure and does not count purgeable storage as ordinary files.")
                }
            }
            .sdeFont(13)
            .padding(.vertical, 10)
        } label: {
            Label(report.isPartial ? "Some storage couldn’t be checked" : "About these results",
                  systemImage: report.isPartial ? "eye.slash" : "info.circle")
                .sdeFont(13)
                .frame(minHeight: 44)
        }
        .foregroundStyle(Color.sdeMuted)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 18))
    }

    private func issueTitle(_ kind: ScanIssueKind) -> String {
        switch kind {
        case .permissionDenied: "Access not allowed"
        case .unavailableRoot: "Location unavailable"
        case .transientFileChange: "Items changed during checking"
        case .volumeBoundarySkipped: "Other disks not included"
        case .metadataUnavailable: "Details unavailable"
        }
    }
}

private struct FailureState: View {
    let message: String
    let tryAgain: () -> Void
    let goBack: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.circle")
                .sdeFont(28, weight: .regular)
                .foregroundStyle(Color.sdeBlue)
            Text("The check couldn’t finish")
                .sdeFont(22, weight: .medium)
                .foregroundStyle(Color.sdeInk)
            Text(message)
                .sdeFont(13, weight: .regular)
                .foregroundStyle(Color.sdeMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 600)
            HStack(spacing: 14) {
                Button("Back", action: goBack)
                    .sdeFont(13, weight: .regular)
                    .frame(minWidth: 120, minHeight: 48)
                    .modifier(SecondaryGlassButton())
                Button("Try Again", action: tryAgain)
                    .sdeFont(13, weight: .regular)
                    .frame(minWidth: 160, minHeight: 48)
                    .modifier(PrimaryGlassButton())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct FunctionalGlassBar: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceTransparency || contrast == .increased {
            content
                .background(Color(nsColor: .windowBackgroundColor))
                .overlay(alignment: .bottom) { SubtleLine(strength: 0.75) }
        } else if #available(macOS 26.0, *) {
            content
                .glassEffect(.regular, in: Rectangle())
                .overlay(alignment: .bottom) { SubtleLine() }
        } else {
            content
                .background(.regularMaterial)
                .overlay(alignment: .bottom) { SubtleLine(strength: 0.65) }
        }
    }
}

private struct SubtleLine: View {
    @Environment(\.colorSchemeContrast) private var contrast
    var strength = 0.45

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.primary.opacity(contrast == .increased ? strength : strength * 0.22),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}

private struct PrimaryGlassButton: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                .tint(.sdeBlue)
        } else {
            content
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(.sdeBlue)
        }
    }
}

private struct SecondaryGlassButton: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .tint(.sdeBlue)
        } else {
            content
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .tint(.sdeBlue)
        }
    }
}

private extension RiskLevel {
    var symbolName: String {
        switch self {
        case .expected: "checkmark.circle"
        case .rebuildable: "arrow.triangle.2.circlepath"
        case .review: "eye"
        case .unknown: "questionmark.circle"
        }
    }

    var shortGuidance: String {
        switch self {
        case .expected: "Keep it"
        case .rebuildable: "Can be recreated"
        case .review: "Check before removing"
        case .unknown: "Leave it alone for now"
        }
    }
}
