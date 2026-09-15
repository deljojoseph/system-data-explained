import SDEDomain

enum CreativeRules {
    static let all: [PathRule] = [
        PathRule(
            id: "creative.adobe.caches",
            matcher: .homePrefix("Library/Caches/Adobe"),
            category: .creativeData,
            displayName: "Adobe Media Caches",
            owner: "Adobe",
            explanation: "Generated previews, media indexes, and temporary working data used by Adobe applications.",
            whyLarge: "High-resolution video, photo, and design projects can generate large reusable previews.",
            risk: .rebuildable
        ),
        PathRule(
            id: "creative.adobe.common-media-cache",
            matcher: .homePrefix("Library/Application Support/Adobe/Common/Media Cache Files"),
            category: .creativeData,
            displayName: "Adobe Video & Audio Cache",
            owner: "Adobe Premiere Pro and Media Encoder",
            explanation: "Faster-to-read copies of video and audio made while importing media.",
            whyLarge: "Long, high-resolution projects can create many preview and conformed-audio files.",
            risk: .rebuildable
        ),
        PathRule(
            id: "creative.adobe.application-support",
            matcher: .homePrefix("Library/Application Support/Adobe"),
            category: .creativeData,
            displayName: "Adobe Working Data",
            owner: "Adobe",
            explanation: "Shared support files, downloaded assets, and application working data used by Adobe software.",
            whyLarge: "Multiple Adobe applications may store shared assets, models, plug-ins, and media databases.",
            risk: .review
        ),
        PathRule(
            id: "creative.final-cut.caches",
            matcher: .homePrefix("Library/Caches/com.apple.FinalCut"),
            category: .creativeData,
            displayName: "Final Cut Pro Caches",
            owner: "Final Cut Pro",
            explanation: "Generated working data used while editing video.",
            whyLarge: "Video analysis, thumbnails, and previews grow with the number and resolution of projects.",
            risk: .rebuildable
        ),
        PathRule(
            id: "creative.logic.support",
            matcher: .homePrefix("Library/Application Support/Logic"),
            category: .creativeData,
            displayName: "Logic Pro Content",
            owner: "Logic Pro",
            explanation: "Instrument, preset, and supporting content used by Logic Pro.",
            whyLarge: "Audio libraries contain many high-quality samples and instruments.",
            risk: .review
        ),
        PathRule(
            id: "creative.garageband.support",
            matcher: .homePrefix("Library/Application Support/GarageBand"),
            category: .creativeData,
            displayName: "GarageBand Content",
            owner: "GarageBand",
            explanation: "Instrument, lesson, loop, and supporting content used by GarageBand.",
            whyLarge: "Downloaded sound libraries contain many audio samples.",
            risk: .review
        ),
        PathRule(
            id: "creative.apple-audio-loops",
            matcher: .absolutePrefix("/Library/Audio/Apple Loops"),
            category: .creativeData,
            displayName: "Apple Audio Loops",
            owner: "Apple Creative Apps",
            explanation: "Reusable music and sound loops installed for Apple's audio applications.",
            whyLarge: "Complete loop collections contain thousands of audio files.",
            risk: .review
        )
    ]
}
