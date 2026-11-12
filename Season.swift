import SwiftUI

struct Season: Identifiable, Hashable {
    let id: String
    let chapter: Int
    let number: String
    let title: String
    let subtitle: String
    let theme: String
    let symbol: String
    let startDate: String
    let endDate: String

    var chapterTitle: String {
        "CHAPTER \(chapter)"
    }

    var displayTitle: String {
        "\(chapterTitle) • \(title)"
    }

    /// Only regular numbered seasons (and Season X) have a locker filter.
    var lockerSupported: Bool {
        Int(number) != nil || number == "X"
    }

    var versions: [String] {
        Self.versionTable[id] ?? []
    }

    var summary: String {
        let name = "\(chapterTitle.capitalized) \(title) \"\(subtitle)\""
        let period = startDate == endDate
            ? "took place in \(startDate)"
            : "ran from \(startDate) to \(endDate)"
        return "\(name) \(period). Theme: \(theme)."
    }

    var trailerSearchURL: URL? {
        var components = URLComponents(string: "https://www.youtube.com/results")
        components?.queryItems = [
            URLQueryItem(
                name: "search_query",
                value: "Fortnite \(chapterTitle.capitalized) \(title) \(subtitle) launch trailer"
            )
        ]
        return components?.url
    }

    /// Chapter and season as the cosmetics database writes them.
    var cosmeticsKey: (chapter: String, season: String)? {
        lockerSupported ? (String(chapter), number) : nil
    }

    // Artwork from the Fortnite community image archive.
    var artworkURL: URL? {
        let files: [String: String] = [
            "c1s3": "Season_3_-_Key_Art_-_Fortnite.jpg",
            "c1s4": "Season_4_-_Battle_Pass_-_Fortnite.jpg",
            "c1s5": "Fortnite_(Season_5)_-_Cover_Art_-_Fortnite.jpg",
            "c1s6": "Season_6_-_Battle_Pass_-_Fortnite.jpg",
            "c1s7": "Season_7_-_Key_Art_-_Fortnite.jpg",
            "c1s8": "Season_8_-_Cover_Art_-_Fortnite.png",
            "c1s9": "Season_9_-_Battle_Pass_-_Fortnite.jpg",
            "c2s1": "Chapter_2_Season_1_-_Keyart_-_Fortnite.jpg",
            "c2s2": "Chapter_2_Season_2_-_Keyart_-_Fortnite.jpg",
            "c2s3": "Chapter_2_Season_3_-_Key_Art_-_Fortnite.jpeg",
            "c5s4": "Chapter_5_Season_4_-_Keyart_-_Fortnite.jpg",
            "c6s1": "Chapter_6_Season_1_-_Keyart_2_-_Fortnite.jpg",
            "c6s2": "Chapter_6_Season_2_-_Keyart_-_Fortnite.jpg",
            "c6s4": "Chapter_6_Season_4_-_Keyart_-_Fortnite.png"
        ]

        guard let file = files[id] else { return nil }

        let encoded = file.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        ) ?? file

        return URL(
            string: "https://fortnite.fandom.com/wiki/Special:FilePath/\(encoded)"
        )
    }

    static let chapters: [Int] = Array(Set(all.map { $0.chapter })).sorted()

    // MARK: - Versions (iOS)

    private static let versionTable: [String: [String]] = [
        "c1s3": ["v3.3.0", "v3.3.1", "v3.4.0", "v3.4.4", "v3.5.0", "v3.5.1", "v3.5.2"],
        "c1s4": ["v4.0.0", "v4.1.0", "v4.2.0", "v4.3.0", "v4.4.0", "v4.4.1", "v4.5.0"],
        "c1s5": ["v5.0.0", "v5.1.0", "v5.2.0", "v5.2.1", "v5.3.0", "v5.4.0", "v5.4.1"],
        "c1s6": ["v6.0.0", "v6.0.1", "v6.0.2", "v6.1.0", "v6.20", "v6.21", "v6.22", "v6.30", "v6.31"],
        "c1s7": ["v7.00", "v7.01", "v7.10", "v7.20", "v7.30", "v7.40"],
        "c1s8": ["v8.00", "v8.01", "v8.10", "v8.11", "v8.20", "v8.30", "v8.40", "v8.50", "v8.51"],
        "c1s9": ["v9.00", "v9.01", "v9.10", "v9.20", "v9.21", "v9.30", "v9.40", "v9.41"],
        "c1sx": ["v10.00", "v10.10", "v10.20", "v10.30", "v10.40"],
        "c2s1": ["v11.00", "v11.01", "v11.10", "v11.11", "v11.20", "v11.21", "v11.30", "v11.31", "v11.40", "v11.50"],
        "c2s2": ["v12.00", "v12.10", "v12.20", "v12.21", "v12.30", "v12.40", "v12.41", "v12.50", "v12.60", "v12.61"],
        "c2s3": ["v13.00", "v13.20", "v13.30", "v13.40"],
        "c5s4": ["v31.00", "v31.10", "v31.20", "v31.30", "v31.40"],
        "c5rx": ["v32.00", "v32.10", "v32.11"],
        "c6s1": ["v33.00", "v33.10", "v33.20", "v33.30"],
        "c6s2": ["v34.00", "v34.10", "v34.20", "v34.30"],
        "c6m1": ["v35.00", "v35.10", "v35.20", "v35.30", "v35.40"],
        "c6s3": ["v36.00", "v36.10", "v36.20", "v36.30"],
        "c6s4": ["v37.00", "v37.10", "v37.20"],
        "c6m2": ["v38.00", "v38.10", "v38.20", "v38.30"],
        "c7s1": ["v39.00", "v39.10", "v39.20", "v39.30"],
        "c7s2": ["v40.00", "v40.10", "v40.20", "v40.30", "v40.40"]
    ]

    // MARK: - Seasons

    static let all: [Season] = [
        Season(id:"c1s1",chapter:1,number:"1",title:"Season 1",subtitle:"The Beginning",theme:"Original",symbol:"sparkles",startDate:"October 2017",endDate:"December 2017"),
        Season(id:"c1s2",chapter:1,number:"2",title:"Season 2",subtitle:"Fort Knights",theme:"Medieval",symbol:"shield",startDate:"December 2017",endDate:"February 2018"),
        Season(id:"c1s3",chapter:1,number:"3",title:"Season 3",subtitle:"Meteor Strike",theme:"Space",symbol:"moon.stars",startDate:"February 2018",endDate:"April 2018"),
        Season(id:"c1s4",chapter:1,number:"4",title:"Season 4",subtitle:"Brace for Impact",theme:"Superheroes",symbol:"bolt",startDate:"May 2018",endDate:"July 2018"),
        Season(id:"c1s5",chapter:1,number:"5",title:"Season 5",subtitle:"Worlds Collide",theme:"Rift",symbol:"globe",startDate:"July 2018",endDate:"September 2018"),
        Season(id:"c1s6",chapter:1,number:"6",title:"Season 6",subtitle:"Darkness Rises",theme:"Darkness",symbol:"moon",startDate:"September 2018",endDate:"December 2018"),
        Season(id:"c1s7",chapter:1,number:"7",title:"Season 7",subtitle:"You Better Watch Out",theme:"Winter",symbol:"snowflake",startDate:"December 2018",endDate:"February 2019"),
        Season(id:"c1s8",chapter:1,number:"8",title:"Season 8",subtitle:"X Marks the Spot",theme:"Adventure",symbol:"flame",startDate:"February 2019",endDate:"May 2019"),
        Season(id:"c1s9",chapter:1,number:"9",title:"Season 9",subtitle:"The Future Is Yours",theme:"Future",symbol:"cpu",startDate:"May 2019",endDate:"August 2019"),
        Season(id:"c1sx",chapter:1,number:"X",title:"Season X",subtitle:"Out of Time",theme:"Time",symbol:"clock",startDate:"August 2019",endDate:"October 2019"),

        Season(id:"c2s1",chapter:2,number:"1",title:"Season 1",subtitle:"New World",theme:"New World",symbol:"leaf",startDate:"October 2019",endDate:"February 2020"),
        Season(id:"c2s2",chapter:2,number:"2",title:"Season 2",subtitle:"Top Secret",theme:"Spy",symbol:"eye",startDate:"February 2020",endDate:"June 2020"),
        Season(id:"c2s3",chapter:2,number:"3",title:"Season 3",subtitle:"Splashdown",theme:"Water",symbol:"drop",startDate:"June 2020",endDate:"August 2020"),

        Season(id:"c5s4",chapter:5,number:"4",title:"Season 4",subtitle:"Absolute Doom",theme:"Marvel",symbol:"shield.lefthalf.filled",startDate:"August 2024",endDate:"November 2024"),
        Season(id:"c5rx",chapter:5,number:"R",title:"Remix",subtitle:"Chapter 2 Remix",theme:"Remix",symbol:"music.note",startDate:"November 2024",endDate:"November 2024"),

        Season(id:"c6s1",chapter:6,number:"1",title:"Season 1",subtitle:"Hunters",theme:"Hunters",symbol:"target",startDate:"December 2024",endDate:"February 2025"),
        Season(id:"c6s2",chapter:6,number:"2",title:"Season 2",subtitle:"Lawless",theme:"Crime",symbol:"building.columns",startDate:"February 2025",endDate:"May 2025"),
        Season(id:"c6m1",chapter:6,number:"M1",title:"Mini Season 1",subtitle:"Galactic Battle",theme:"Star Wars",symbol:"star",startDate:"May 2025",endDate:"June 2025"),
        Season(id:"c6s3",chapter:6,number:"3",title:"Season 3",subtitle:"Super",theme:"Superheroes",symbol:"bolt",startDate:"June 2025",endDate:"August 2025"),
        Season(id:"c6s4",chapter:6,number:"4",title:"Season 4",subtitle:"Shock 'N Awesome",theme:"Invasion",symbol:"burst",startDate:"August 2025",endDate:"November 2025"),
        Season(id:"c6m2",chapter:6,number:"M2",title:"Mini Season 2",subtitle:"The Simpsons",theme:"Simpsons",symbol:"tv",startDate:"November 2025",endDate:"November 2025"),

        Season(id:"c7s1",chapter:7,number:"1",title:"Season 1",subtitle:"Pacific Break",theme:"Pacific",symbol:"water.waves",startDate:"November 2025",endDate:"March 2026"),
        Season(id:"c7s2",chapter:7,number:"2",title:"Season 2",subtitle:"Showdown",theme:"Showdown",symbol:"flame",startDate:"March 2026",endDate:"June 2026"),
        Season(id:"c7s3",chapter:7,number:"3",title:"Season 3",subtitle:"Runners",theme:"Runners",symbol:"figure.run",startDate:"June 2026",endDate:"August 2026")
    ]
}
