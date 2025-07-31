// MARK: - IronTrainApp.swift
import SwiftUI

@main
struct IronTrainApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

// MARK: - ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var trainingPlanViewModel = TrainingPlanViewModel()
    @StateObject private var raceViewModel = RaceViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
                .tag(0)
            
            WorkoutListView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Workouts")
                }
                .tag(1)
            
            ProgressView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
                .tag(2)
            
            RaceSelectionView()
                .tabItem {
                    Image(systemName: "flag.checkered")
                    Text("Races")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .environmentObject(trainingPlanViewModel)
        .environmentObject(raceViewModel)
        .accentColor(.blue)
    }
}

// MARK: - Models/Race.swift
import Foundation

struct Race: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var date: Date
    var location: String
    var distance: IronmanDistance
    var isCompleted: Bool = false
    var goalTime: TimeInterval?
    var actualTime: TimeInterval?
    
    var daysUntilRace: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    }
    
    var weeksUntilRace: Int {
        Calendar.current.dateComponents([.weekOfYear], from: Date(), to: date).weekOfYear ?? 0
    }
}

// MARK: - Models/Workout.swift
import Foundation

struct Workout: Identifiable, Codable, Hashable {
    let id = UUID()
    var date: Date
    var sport: Sport
    var title: String
    var description: String
    var duration: TimeInterval // in minutes
    var completed: Bool = false
    var intensity: WorkoutIntensity
    var notes: String = ""
    var actualDuration: TimeInterval?
    var perceivedEffort: Int? // 1-10 RPE scale
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var isPast: Bool {
        date < Date()
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 60
        let minutes = Int(duration) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Models/TrainingWeek.swift
import Foundation

struct TrainingWeek: Identifiable, Hashable {
    let id = UUID()
    var weekNumber: Int
    var startDate: Date
    var workouts: [Workout]
    var phase: TrainingPhase
    
    var endDate: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: startDate) ?? startDate
    }
    
    var totalHours: Double {
        workouts.reduce(0) { $0 + ($1.actualDuration ?? $1.duration) / 60 }
    }
    
    var completedWorkouts: Int {
        workouts.filter { $0.completed }.count
    }
    
    var completionPercentage: Double {
        guard !workouts.isEmpty else { return 0 }
        return Double(completedWorkouts) / Double(workouts.count)
    }
    
    var weekRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

// MARK: - Models/Enums/Sport.swift
import SwiftUI

enum Sport: String, CaseIterable, Codable {
    case swim = "Swimming"
    case bike = "Cycling"
    case run = "Running"
    case brick = "Brick"
    case strength = "Strength"
    case rest = "Rest"
    
    var icon: String {
        switch self {
        case .swim: return "figure.pool.swim"
        case .bike: return "bicycle"
        case .run: return "figure.run"
        case .brick: return "arrow.triangle.2.circlepath"
        case .strength: return "dumbbell"
        case .rest: return "bed.double"
        }
    }
    
    var color: Color {
        switch self {
        case .swim: return .blue
        case .bike: return .green
        case .run: return .orange
        case .brick: return .purple
        case .strength: return .red
        case .rest: return .gray
        }
    }
    
    var lightColor: Color {
        color.opacity(0.2)
    }
}

// MARK: - Models/Enums/IronmanDistance.swift
import Foundation

enum IronmanDistance: String, CaseIterable, Codable {
    case sprint = "Sprint"
    case olympic = "Olympic"
    case half = "70.3"
    case full = "140.6"
    
    var distances: (swim: Double, bike: Double, run: Double) {
        switch self {
        case .sprint: return (0.75, 20, 5)
        case .olympic: return (1.5, 40, 10)
        case .half: return (1.9, 90, 21.1)
        case .full: return (3.8, 180, 42.2)
        }
    }
    
    var description: String {
        let d = distances
        switch self {
        case .sprint:
            return "\(d.swim)km swim, \(d.bike)km bike, \(d.run)km run"
        case .olympic:
            return "\(d.swim)km swim, \(d.bike)km bike, \(d.run)km run"
        case .half:
            return "\(d.swim)km swim, \(d.bike)km bike, \(d.run)km run"
        case .full:
            return "\(d.swim)km swim, \(d.bike)km bike, \(d.run)km run"
        }
    }
    
    var estimatedTrainingWeeks: Int {
        switch self {
        case .sprint: return 8
        case .olympic: return 12
        case .half: return 16
        case .full: return 20
        }
    }
}

// MARK: - Models/Enums/WorkoutIntensity.swift
import SwiftUI

enum WorkoutIntensity: String, CaseIterable, Codable {
    case recovery = "Recovery"
    case easy = "Easy"
    case moderate = "Moderate"
    case hard = "Hard"
    case race = "Race Pace"
    
    var color: Color {
        switch self {
        case .recovery: return .gray
        case .easy: return .green
        case .moderate: return .yellow
        case .hard: return .orange
        case .race: return .red
        }
    }
    
    var description: String {
        switch self {
        case .recovery: return "Very easy, focus on movement"
        case .easy: return "Comfortable, conversational pace"
        case .moderate: return "Comfortably hard, sustainable"
        case .hard: return "Hard effort, challenging pace"
        case .race: return "Target race day pace/effort"
        }
    }
    
    var rpeRange: String {
        switch self {
        case .recovery: return "1-3"
        case .easy: return "4-5"
        case .moderate: return "6-7"
        case .hard: return "8-9"
        case .race: return "7-8"
        }
    }
}

// MARK: - Models/Enums/TrainingPhase.swift
import Foundation

enum TrainingPhase: String, CaseIterable, Codable {
    case base = "Base Building"
    case build = "Build"
    case peak = "Peak"
    case taper = "Taper"
    case recovery = "Recovery"
    
    var volumeMultiplier: Double {
        switch self {
        case .base: return 0.8
        case .build: return 1.0
        case .peak: return 1.2
        case .taper: return 0.6
        case .recovery: return 0.4
        }
    }
    
    var description: String {
        switch self {
        case .base:
            return "Building aerobic base with consistent, moderate training"
        case .build:
            return "Increasing intensity and specificity for race preparation"
        case .peak:
            return "Highest training load with race-specific workouts"
        case .taper:
            return "Reducing volume while maintaining intensity before race"
        case .recovery:
            return "Active recovery and regeneration period"
        }
    }
    
    var color: Color {
        switch self {
        case .base: return .blue
        case .build: return .green
        case .peak: return .orange
        case .taper: return .purple
        case .recovery: return .gray
        }
    }
}