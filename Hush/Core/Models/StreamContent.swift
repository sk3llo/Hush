import Foundation
import SwiftUI

/// Represents the entire streamed content from the AI
struct StreamContent {
    /// List of renderable items with stable IDs
    var items: [Item] = []
    
    /// Whether the stream has completed
    var finished: Bool = false
    
    /// Errors collected during processing
    var errors: [IdentifiableError] = []
    
    /// Rendering and layout options
    var options = Options()
    
    /// A renderable item with stable identity
    struct Item: Identifiable {
        /// Stable identifier across rebuilds
        let id: ID
        
        /// The actual content value
        let value: StreamItemValue
        
        /// Creates a new item with an automatically generated ID
        init(ids: inout IdentifierGenerator, value: StreamItemValue) {
            self.id = ids()
            self.value = value
        }
    }
    
    /// The type of content an item can represent
    enum StreamItemValue {
        /// Text content rendered with Markdown
        case markdown(MarkdownEntry)
        
        /// Custom table view built from markdown tables
        case markdownTable(MarkdownTable)
        
        /// Interactive question element
        case question(Question)
        
        /// A group of related questions
        case questionGroup(QuestionGroup)
        
        /// Raw XML (not rendered directly)
        case xml([XMLElement])
        
        /// Custom visualization widget
        case widget(Widget)
        
        /// Container for multiple widgets
        case container(ContainerWidget)
        
        /// Form input control
        case input(Input)
    }
    
    /// Rendering and layout options
    struct Options {
        /// Page-level layout controls
        var page = PageOptions()
        
        /// Page layout options
        struct PageOptions {
            /// Type of control to show in the page
            var control: ControlType = .none
            
            /// Available control types
            enum ControlType {
                /// No control
                case none
                
                /// Submit button
                case submit
                
                /// Back button
                case back
                
                /// Next button
                case next
            }
        }
    }
}

/// An error with an identity for stable rendering
struct IdentifiableError: Identifiable {
    /// Stable identifier
    let id: UUID
    
    /// The underlying error
    let error: Error
    
    /// Creates a new identifiable error
    init(_ error: Error) {
        self.id = UUID()
        self.error = error
    }
}

/// A string-based ID
typealias ID = String

/// Protocol for generating stable, predictable identifiers
protocol IdentifierGenerator {
    /// Generate the next identifier
    mutating func callAsFunction() -> ID
    
    /// Create a new nested identifier generator
    mutating func nested() -> IdentifierGenerator
}

/// An implementation of IdentifierGenerator that generates incremental hierarchical identifiers
struct IncrementalIdentifierGenerator: IdentifierGenerator {
    /// The prefix for all identifiers from this generator
    private var prefix: String
    
    /// The current ID counter
    private var id: Int = 0
    
    /// The current nested ID counter
    private var nestedId: Int = 0
    
    /// Create a new root identifier generator
    static func create() -> IncrementalIdentifierGenerator {
        return Self(prefix: "")
    }
    
    /// Initialize with a prefix
    private init(prefix: String) {
        self.prefix = prefix
    }
    
    /// Generates the next identifier in the sequence
    /// - Returns: A unique identifier string
    mutating func callAsFunction() -> ID {
        nestedId = 0
        id += 1
        return "\(prefix)\(id)"
    }
    
    /// Creates a new nested identifier generator
    /// - Returns: A new generator instance for creating hierarchical identifiers
    mutating func nested() -> IdentifierGenerator {
        nestedId += 1
        return Self(prefix: "\(prefix).\(id)-\(nestedId).")
    }
}

/// Entry for Markdown content
struct MarkdownEntry {
    /// The full markdown content
    let content: String
    
    /// A collapsed (shortened) version if available
    var collapsed: String?
    
    /// Whether this entry can be collapsed
    var collapsible: Bool { collapsed != nil }
}

/// A table parsed from markdown
struct MarkdownTable {
    /// Column headers
    var headers: [String]
    
    /// Table rows
    var rows: [[String]]
    
    /// Create an empty table
    init() {
        self.headers = []
        self.rows = []
    }
    
    /// Create a table with headers and rows
    init(headers: [String], rows: [[String]]) {
        self.headers = headers
        self.rows = rows
    }
}

/// An interactive question element
struct Question {
    /// The question text
    let text: String
    
    /// Available answer options
    var options: [String] = []
    
    /// Selected answer index
    var selectedIndex: Int?
}

/// A group of related questions
struct QuestionGroup {
    /// The title of the group
    var title: String?
    
    /// Questions in this group
    var questions: [Question]
}

/// Raw XML element
struct XMLElement {
    /// Element name
    let name: String
    
    /// Element attributes
    let attributes: [String: String]
    
    /// Text content
    var text: String?
    
    /// Child elements
    var children: [XMLElement]
}

/// Custom visualization widget
enum Widget {
    /// A trend visualization
    case trend(TrendWidget)
    
    /// A chart visualization
    case chart(ChartWidget)
}

/// A trend visualization widget
struct TrendWidget: Decodable {
    /// The name of the risk scenario
    var riskScenarioName: String?
    
    /// Trend data points
    var trendData: [TrendData]?
    
    /// Data for a single trend point
    struct TrendData: Decodable {
        /// The likelihood value
        var eventLikelihood: Double?
        
        /// The timestamp for this data point
        var timestamp: Date?
        
        /// Coding keys for the TrendData
        enum CodingKeys: String, CodingKey {
            case eventLikelihood
            case timestamp
        }
        
        /// Custom decoder that handles partial data
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            eventLikelihood = try container.decodeIfPresent(Double.self, forKey: .eventLikelihood)
            timestamp = try? container.decodeIfPresent(Date.self, forKey: .timestamp)
        }
    }
    
    /// Coding keys for the TrendWidget
    enum CodingKeys: String, CodingKey {
        case riskScenarioName
        case trendData
    }
}

/// A chart visualization widget
struct ChartWidget: Decodable {
    /// Chart title
    var title: String?
    
    /// Data series
    var series: [Series]?
    
    /// A data series
    struct Series: Decodable {
        /// Series name
        var name: String?
        
        /// Data points
        var data: [Double]?
    }
}

/// Container for multiple widgets
struct ContainerWidget {
    /// Optional container title
    var title: String?
    
    /// Widgets in this container
    var widgets: [StreamContent.Item] = []
}

/// Form input control
struct Input {
    /// Input type
    enum InputType {
        /// Text input
        case text
        
        /// Number input
        case number
        
        /// Date input
        case date
    }
    
    /// Input name (identifier)
    var name: String
    
    /// Input label
    var label: String
    
    /// Input type
    var type: InputType
    
    /// Initial value
    var initialValue: String?
} 