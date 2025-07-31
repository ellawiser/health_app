// MARK: - Views/RacePlanning/RaceSelectionView.swift
import SwiftUI

struct RaceSelectionView: View {
    @EnvironmentObject var raceViewModel: RaceViewModel
    @EnvironmentObject var trainingPlanViewModel: TrainingPlanViewModel
    @State private var showingRaceSetup = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if raceViewModel.races.isEmpty {
                    emptyStateView
                } else {
                    raceList
                }
            }
            .navigationTitle("Races")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Race") {
                        showingRaceSetup = true
                    }
                }
            }
            .sheet(isPresented: $showingRaceSetup) {
                RaceSetupView()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("No Races Added")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add your first race to generate a personalized training plan")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Add Your First Race") {
                showingRaceSetup = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var raceList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(raceViewModel.races) { race in
                    RaceCard(race: race) {
                        selectRace(race)
                    }
                }
            }
            .padding()
        }
    }
    
    private func selectRace(_ race: Race) {
        raceViewModel.selectRace(race)
        trainingPlanViewModel.generatePlan(for: race)
    }
}

// MARK: - Views/RacePlanning/RaceSetupView.swift
struct RaceSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var raceViewModel: RaceViewModel
    @EnvironmentObject var trainingPlanViewModel: TrainingPlanViewModel
    
    @State private var raceName = ""
    @State private var raceDate = Date().addingTimeInterval(86400 * 120) // 4 months from now
    @State private var raceLocation = ""
    @State private var selectedDistance: IronmanDistance = .half
    @State private var showingDatePicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Race Information") {
                    TextField("Race Name", text: $raceName)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Location", text: $raceLocation)
                        .textInputAutocapitalization(.words)
                    
                    DatePicker("Race Date", selection: $raceDate, in: Date()..., displayedComponents: .date)
                        .datePickerStyle(.compact)
                }
                
                Section("Distance") {
                    Picker("Race Distance", selection: $selectedDistance) {
                        ForEach(IronmanDistance.allCases, id: \.self) { distance in
                            VStack(alignment: .leading) {
                                Text(distance.rawValue)
                                    .font(.headline)
                                Text(distance.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(distance)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                Section("Training Plan") {
                    HStack {
                        Text("Estimated Training Duration")
                        Spacer()
                        Text("\(selectedDistance.estimatedTrainingWeeks) weeks")
                            .foregroundColor(.secondary)
                    }
                    
                    let startDate = Calendar.current.date(byAdding: .weekOfYear, value: -selectedDistance.estimatedTrainingWeeks, to: raceDate) ?? Date()
                    HStack {
                        Text("Training Start Date")
                        Spacer()
                        Text(startDate, style: .date)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Add Race")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveRace()
                    }
                    .fontWeight(.semibold)
                    .disabled(raceName.isEmpty || raceLocation.isEmpty)
                }
            }
        }
    }
    
    private func saveRace() {
        let newRace = Race(
            name: raceName,
            date: raceDate,
            location: raceLocation,
            distance: selectedDistance
        )
        
        raceViewModel.addRace(newRace)
        raceViewModel.selectRace(newRace)
        trainingPlanViewModel.generatePlan(for: newRace)
        
        dismiss()
    }
}

// MARK: - Views/Components/RaceCard.swift
struct RaceCard: View {
    let race: Race
    let action: () -> Void
    @EnvironmentObject var raceViewModel: RaceViewModel
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(race.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(race.location)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        if race.isCompleted {
                            Text("Completed")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        } else {
                            Text("\(race.daysUntilRace) days")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        Text(race.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text(race.distance.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    if raceViewModel.selectedRace?.id == race.id {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Selected")
                        }
                        .font(.caption)
                        .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .stroke(
                        raceViewModel.selectedRace?.id == race.id ? Color.green : Color(.systemGray4),
                        lineWidth: raceViewModel.selectedRace?.id == race.id ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Views/Progress/ProgressView.swift
struct ProgressView: View {
    @EnvironmentObject var trainingPlanViewModel: TrainingPlanViewModel
    @EnvironmentObject var raceViewModel: RaceViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if trainingPlanViewModel.trainingWeeks.isEmpty {
                        emptyProgressView
                    } else {
                        progressContent
                    }
                }
                .padding()
            }
            .navigationTitle("Progress")
        }
    }
    
    private var emptyProgressView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Progress Data")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Complete some workouts to see your training progress")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var progressContent: some View {
        VStack(spacing: 20) {
            // Overall stats
            overallStatsSection
            
            // Weekly progress
            weeklyProgressSection
            
            // Sport breakdown
            sportBreakdownSection
        }
    }
    
    private var overallStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overall Progress")
                .font(.headline)
            
            let totalWorkouts = trainingPlanViewModel.trainingWeeks.flatMap { $0.workouts }.count
            let completedWorkouts = trainingPlanViewModel.trainingWeeks.flatMap { $0.workouts }.filter { $0.completed }.count
            let totalHours = trainingPlanViewModel.trainingWeeks.reduce(0) { $0 + $1.totalHours }
            
            HStack(spacing: 20) {
                StatCard(title: "Total Hours", value: String(format: "%.1f", totalHours), icon: "clock")
                StatCard(title: "Completed", value: "\(completedWorkouts)/\(totalWorkouts)", icon: "checkmark.circle")
                StatCard(title: "Completion Rate", value: "\(totalWorkouts > 0 ? Int((Double(completedWorkouts) / Double(totalWorkouts)) * 100) : 0)%", icon: "chart.pie")
            }
        }
    }
    
    private var weeklyProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Progress")
                .font(.headline)
            
            LazyVStack(spacing: 8) {
                ForEach(trainingPlanViewModel.trainingWeeks.prefix(4)) { week in
                    WeekProgressRow(week: week)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var sportBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training by Sport")
                .font(.headline)
            
            let sportStats = calculateSportStats()
            
            VStack(spacing: 12) {
                ForEach(Sport.allCases.filter { $0 != .rest }, id: \.self) { sport in
                    if let stats = sportStats[sport] {
                        SportProgressRow(sport: sport, stats: stats)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private func calculateSportStats() -> [Sport: (completed: Int, total: Int, hours: Double)] {
        var stats: [Sport: (completed: Int, total: Int, hours: Double)] = [:]
        
        let allWorkouts = trainingPlanViewModel.trainingWeeks.flatMap { $0.workouts }
        
        for sport in Sport.allCases {
            let sportWorkouts = allWorkouts.filter { $0.sport == sport }
            let completed = sportWorkouts.filter { $0.completed }.count
            let total = sportWorkouts.count
            let hours = sportWorkouts.filter { $0.completed }.reduce(0) { $0 + ($1.actualDuration ?? $1.duration) / 60 }
            
            if total > 0 {
                stats[sport] = (completed: completed, total: total, hours: hours)
            }
        }
        
        return stats
    }
}

// MARK: - Views/Components/StatCard.swift
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Views/Components/WeekProgressRow.swift
struct WeekProgressRow: View {
    let week: TrainingWeek
    
    var body: some View {
        HStack {
            Text("Week \(week.weekNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text("\(week.completedWorkouts)/\(week.workouts.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ProgressView(value: week.completionPercentage)
                .frame(width: 60)
                .tint(.blue)
        }
    }
}

// MARK: - Views/Components/SportProgressRow.swift
struct SportProgressRow: View {
    let sport: Sport
    let stats: (completed: Int, total: Int, hours: Double)
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: sport.icon)
                .font(.title3)
                .foregroundColor(sport.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(sport.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(stats.completed)/\(stats.total) workouts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1fh", stats.hours))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(Int((Double(stats.completed) / Double(stats.total)) * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Views/Profile/ProfileView.swift
struct ProfileView: View {
    @StateObject private var userViewModel = UserViewModel()
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(userViewModel.user.name.isEmpty ? "Athlete" : userViewModel.user.name)
                                .font(.headline)
                            
                            Text(userViewModel.user.fitnessLevel.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Training") {
                    NavigationLink(destination: TrainingZonesView()) {
                        Label("Training Zones", systemImage: "heart")
                    }
                    
                    NavigationLink(destination: PreferencesView()) {
                        Label("Preferences", systemImage: "slider.horizontal.3")
                    }
                }
                
                Section("Settings") {
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gear")
                    }
                    
                    Label("Export Data", systemImage: "square.and.arrow.up")
                    
                    Label("Help & Support", systemImage: "questionmark.circle")
                }
            }
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Services/TrainingPlanGenerator.swift
class TrainingPlanGenerator {
    static func generatePlan(for race: Race, weeksOut: Int? = nil) -> [TrainingWeek] {
        let trainingWeeks = weeksOut ?? race.distance.estimatedTrainingWeeks
        var weeks: [TrainingWeek] = []
        let calendar = Calendar.current
        
        for weekNum in 1...trainingWeeks {
            let weekStartDate = calendar.date(byAdding: .weekOfYear, value: -(trainingWeeks - weekNum), to: race.date) ?? Date()
            let phase = determinePhase(weekNumber: weekNum, totalWeeks: trainingWeeks)
            let workouts = generateWeeklyWorkouts(
                weekNumber: weekNum,
                startDate: weekStartDate,
                phase: phase,
                raceDistance: race.distance
            )
            
            weeks.append(TrainingWeek(
                weekNumber: weekNum,
                startDate: weekStartDate,
                workouts: workouts,
                phase: phase
            ))
        }
        
        return weeks
    }
    
    private static func determinePhase(weekNumber: Int, totalWeeks: Int) -> TrainingPhase {
        let progress = Double(weekNumber) / Double(totalWeeks)
        
        switch progress {
        case 0.0..<0.4: return .base
        case 0.4..<0.7: return .build
        case 0.7..<0.9: return .peak
        default: return .taper
        }
    }
    
    private static func generateWeeklyWorkouts(
        weekNumber: Int,
        startDate: Date,
        phase: TrainingPhase,
        raceDistance: IronmanDistance
    ) -> [Workout] {
        var workouts: [Workout] = []
        let calendar = Calendar.current
        
        // Training pattern: 6 days on, 1 day rest
        for dayOffset in 0..<7 {
            guard dayOffset != 6 else { continue } // Sunday rest
            
            let workoutDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate) ?? startDate
            
            if let workout = generateDayWorkout(
                dayOfWeek: dayOffset,
                phase: phase,
                weekNumber: weekNumber,
                date: workoutDate,
                raceDistance: raceDistance
            ) {
                workouts.append(workout)
            }
        }
        
        return workouts
    }
    
    private static func generateDayWorkout(
        dayOfWeek: Int,
        phase: TrainingPhase,
        weekNumber: Int,
        date: Date,
        raceDistance: IronmanDistance
    ) -> Workout? {
        let baseMultiplier = phase.volumeMultiplier
        
        switch dayOfWeek {
        case 0: // Monday - Swimming
            return Workout(
                date: date,
                sport: .swim,
                title: "Swim Technique",
                description: generateSwimWorkout(phase: phase, isEndurance: false),
                duration: 45 * baseMultiplier,
                intensity: .moderate
            )
            
        case 1: // Tuesday - Running
            return Workout(
                date: date,
                sport: .run,
                title: phase == .base ? "Base Run" : "Run Intervals",
                description: generateRunWorkout(phase: phase),
                duration: 60 * baseMultiplier,
                intensity: phase == .peak ? .hard : .moderate
            )
            
        case 2: // Wednesday - Cycling
            return Workout(
                date: date,
                sport: .bike,
                title: "Bike Endurance",
                description: generateBikeWorkout(phase: phase),
                duration: 90 * baseMultiplier,
                intensity: .moderate
            )
            
        case 3: // Thursday - Swimming
            return Workout(
                date: date,
                sport: .swim,
                title: "Swim Endurance",
                description: generateSwimWorkout(phase: phase, isEndurance: true),
                duration: 60 * baseMultiplier,
                intensity: .easy
            )
            
        case 4: // Friday - Recovery Run
            return Workout(
                date: date,
                sport: .run,
                title: "Recovery Run",
                description: "Easy-paced recovery run focusing on form and relaxation. Keep heart rate in Zone 1-2.",
                duration: 30,
                intensity: .recovery
            )
            
        case 5: // Saturday - Long Workout
            if weekNumber % 3 == 0 && phase != .taper {
                return Workout(
                    date: date,
                    sport: .brick,
                    title: "Brick Workout",
                    description: generateBrickWorkout(phase: phase),
                    duration: 120 * baseMultiplier,
                    intensity: .moderate
                )
            } else {
                return Workout(
                    date: date,
                    sport: .bike,
                    title: "Long Ride",
                    description: generateLongRideWorkout(phase: phase),
                    duration: 150 * baseMultiplier,
                    intensity: .easy
                )
            }
            
        default:
            return nil
        }
    }
    
    private static func generateSwimWorkout(phase: TrainingPhase, isEndurance: Bool) -> String {
        if isEndurance {
            return """
            Warm-up: 400m easy swim
            Main Set: 8 x 100m at steady pace (15s rest)
            Cool-down: 200m easy
            
            Focus: Maintain consistent stroke rate and breathing pattern throughout the main set.
            """
        } else {
            return """
            Warm-up: 300m easy swim
            Drill Set: 4 x 50m (catch-up drill, fingertip drag)
            Main Set: 6 x 75m build (easy-moderate-fast by 25m)
            Cool-down: 200m easy
            
            Focus: Technique refinement and stroke efficiency.
            """
        }
    }
    
    private static func generateRunWorkout(phase: TrainingPhase) -> String {
        switch phase {
        case .base:
            return """
            Warm-up: 15 min easy pace
            Main Set: 4 x 5 min at tempo pace (2 min easy recovery)
            Cool-down: 10 min easy
            
            Focus: Building aerobic base and tempo endurance.
            """
        case .build, .peak:
            return """
            Warm-up: 20 min easy with 4 x 100m strides
            Main Set: 6 x 800m at 5K pace (90s walking recovery)
            Cool-down: 15 min easy
            
            Focus: Speed development and lactate threshold improvement.
            """
        case .taper:
            return """
            Warm-up: 15 min easy
            Main Set: 4 x 200m at race pace (full recovery)
            Cool-down: 10 min easy
            
            Focus: Maintaining speed with reduced volume for race preparation.
            """
        case .recovery:
            return """
            Easy continuous run at conversational pace.
            
            Focus: Active recovery and movement quality.
            """
        }
    }
    
    private static func generateBikeWorkout(phase: TrainingPhase) -> String {
        return """
        Warm-up: 15 min easy spinning
        Main Set: 3 x 15 min at threshold pace (5 min easy recovery)
        Cool-down: 15 min easy
        
        Focus: Building sustainable power at race pace. Maintain aero position during intervals.
        """
    }
    
    private static func generateBrickWorkout(phase: TrainingPhase) -> String {
        return """
        Bike: 60 min at race pace (last 10 min build to slightly above race effort)
        Transition: Quick change - practice T2 setup (under 2 minutes)
        Run: 20 min off the bike at target race pace
        
        Focus: Race-day transitions and running efficiently off the bike.
        """
    }
    
    private static func generateLongRideWorkout(phase: TrainingPhase) -> String {
        return """
        Duration: 2-3 hours at aerobic pace (Zone 2)
        Include: 3 x 10 min at race pace every hour
        Nutrition: Practice race-day fueling strategy every 20-30 minutes
        
        Focus: Building endurance and testing nutrition/hydration strategies.
        """
    }
}

#Preview {
    RaceSelectionView()
        .environmentObject(RaceViewModel())
        .environmentObject(TrainingPlanViewModel())
}