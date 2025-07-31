// MARK: - ViewModels/TrainingPlanViewModel.swift
import Foundation
import Combine

class TrainingPlanViewModel: ObservableObject {
    @Published var trainingWeeks: [TrainingWeek] = []
    @Published var currentWeek: TrainingWeek?
    @Published var isGenerating = false
    @Published var selectedRace: Race?
    
    private var cancellables = Set<AnyCancellable>()
    
    func generatePlan(for race: Race) {
        isGenerating = true
        selectedRace = race
        
        // Simulate async generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.trainingWeeks = TrainingPlanGenerator.generatePlan(for: race)
            self.updateCurrentWeek()
            self.isGenerating = false
        }
    }
    
    func updateCurrentWeek() {
        let today = Date()
        currentWeek = trainingWeeks.first { week in
            let endDate = Calendar.current.date(byAdding: .day, value: 6, to: week.startDate) ?? week.startDate
            return today >= week.startDate && today <= endDate
        }
    }
    
    func completeWorkout(_ workout: Workout) {
        guard let weekIndex = trainingWeeks.firstIndex(where: { $0.workouts.contains { $0.id == workout.id } }),
              let workoutIndex = trainingWeeks[weekIndex].workouts.firstIndex(where: { $0.id == workout.id }) else {
            return
        }
        
        trainingWeeks[weekIndex].workouts[workoutIndex].completed = true
        trainingWeeks[weekIndex].workouts[workoutIndex].actualDuration = workout.duration
        
        // Update current week if this workout belongs to it
        if currentWeek?.id == trainingWeeks[weekIndex].id {
            currentWeek = trainingWeeks[weekIndex]
        }
    }
    
    func getTodaysWorkout() -> Workout? {
        let today = Date()
        return currentWeek?.workouts.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }
    
    func getUpcomingWorkouts(limit: Int = 7) -> [Workout] {
        let today = Date()
        let allWorkouts = trainingWeeks.flatMap { $0.workouts }
        
        return allWorkouts
            .filter { $0.date >= today && !$0.completed }
            .sorted { $0.date < $1.date }
            .prefix(limit)
            .map { $0 }
    }
    
    func getWeeklyStats() -> (totalHours: Double, completedWorkouts: Int, totalWorkouts: Int) {
        guard let currentWeek = currentWeek else {
            return (0, 0, 0)
        }
        
        return (
            totalHours: currentWeek.totalHours,
            completedWorkouts: currentWeek.completedWorkouts,
            totalWorkouts: currentWeek.workouts.count
        )
    }
}

// MARK: - ViewModels/RaceViewModel.swift
import Foundation
import Combine

class RaceViewModel: ObservableObject {
    @Published var races: [Race] = []
    @Published var selectedRace: Race?
    @Published var isLoading = false
    
    init() {
        loadSampleData()
    }
    
    func addRace(_ race: Race) {
        races.append(race)
        saveRaces()
    }
    
    func updateRace(_ race: Race) {
        if let index = races.firstIndex(where: { $0.id == race.id }) {
            races[index] = race
            saveRaces()
        }
    }
    
    func deleteRace(_ race: Race) {
        races.removeAll { $0.id == race.id }
        if selectedRace?.id == race.id {
            selectedRace = nil
        }
        saveRaces()
    }
    
    func selectRace(_ race: Race) {
        selectedRace = race
    }
    
    func getUpcomingRaces() -> [Race] {
        let today = Date()
        return races
            .filter { $0.date >= today && !$0.isCompleted }
            .sorted { $0.date < $1.date }
    }
    
    func getNextRace() -> Race? {
        return getUpcomingRaces().first
    }
    
    private func saveRaces() {
        // TODO: Implement Core Data or UserDefaults persistence
        if let encoded = try? JSONEncoder().encode(races) {
            UserDefaults.standard.set(encoded, forKey: "SavedRaces")
        }
    }
    
    private func loadRaces() {
        if let data = UserDefaults.standard.data(forKey: "SavedRaces"),
           let decoded = try? JSONDecoder().decode([Race].self, from: data) {
            races = decoded
        }
    }
    
    private func loadSampleData() {
        // Sample data for development
        let calendar = Calendar.current
        let futureDate = calendar.date(byAdding: .month, value: 4, to: Date()) ?? Date()
        
        races = [
            Race(
                name: "Ironman 70.3 Austin",
                date: futureDate,
                location: "Austin, TX",
                distance: .half
            )
        ]
        
        selectedRace = races.first
    }
}

// MARK: - ViewModels/WorkoutViewModel.swift
import Foundation
import Combine

class WorkoutViewModel: ObservableObject {
    @Published var selectedWorkout: Workout?
    @Published var workoutNotes: String = ""
    @Published var perceivedEffort: Int = 5
    @Published var actualDuration: TimeInterval = 0
    
    func selectWorkout(_ workout: Workout) {
        selectedWorkout = workout
        workoutNotes = workout.notes
        perceivedEffort = workout.perceivedEffort ?? 5
        actualDuration = workout.actualDuration ?? workout.duration
    }
    
    func completeWorkout() -> Workout? {
        guard var workout = selectedWorkout else { return nil }
        
        workout.completed = true
        workout.notes = workoutNotes
        workout.perceivedEffort = perceivedEffort
        workout.actualDuration = actualDuration
        
        selectedWorkout = workout
        return workout
    }
    
    func resetWorkout() {
        guard var workout = selectedWorkout else { return }
        
        workout.completed = false
        workout.notes = ""
        workout.perceivedEffort = nil
        workout.actualDuration = nil
        
        selectedWorkout = workout
    }
    
    func updateWorkoutNotes(_ notes: String) {
        workoutNotes = notes
    }
    
    func updatePerceivedEffort(_ effort: Int) {
        perceivedEffort = max(1, min(10, effort))
    }
    
    func updateActualDuration(_ duration: TimeInterval) {
        actualDuration = max(0, duration)
    }
}

// MARK: - ViewModels/UserViewModel.swift
import Foundation
import Combine

class UserViewModel: ObservableObject {
    @Published var user: User
    @Published var isLoading = false
    
    init() {
        self.user = User() // Load from persistence
        loadUserData()
    }
    
    func updateUser(_ updatedUser: User) {
        user = updatedUser
        saveUserData()
    }
    
    func updateFitnessLevel(_ level: FitnessLevel) {
        user.fitnessLevel = level
        saveUserData()
    }
    
    func updateTrainingZones(
        heartRateZones: HeartRateZones? = nil,
        paceZones: PaceZones? = nil,
        powerZones: PowerZones? = nil
    ) {
        if let hrZones = heartRateZones {
            user.heartRateZones = hrZones
        }
        if let pZones = paceZones {
            user.paceZones = pZones
        }
        if let pwrZones = powerZones {
            user.powerZones = pwrZones
        }
        saveUserData()
    }
    
    func updateWeeklyHours(_ hours: Int) {
        user.weeklyTrainingHours = hours
        saveUserData()
    }
    
    private func saveUserData() {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "UserProfile")
        }
    }
    
    private func loadUserData() {
        if let data = UserDefaults.standard.data(forKey: "UserProfile"),
           let decoded = try? JSONDecoder().decode(User.self, from: data) {
            user = decoded
        }
    }
}

// MARK: - Models/User.swift (Additional model needed for UserViewModel)
import Foundation

struct User: Codable {
    var id = UUID()
    var name: String = ""
    var email: String = ""
    var age: Int = 30
    var weight: Double = 70 // kg
    var height: Double = 175 // cm
    var fitnessLevel: FitnessLevel = .intermediate
    var weeklyTrainingHours: Int = 8
    var heartRateZones: HeartRateZones?
    var paceZones: PaceZones?
    var powerZones: PowerZones?
    var preferences: UserPreferences = UserPreferences()
}

enum FitnessLevel: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case elite = "Elite"
    
    var description: String {
        switch self {
        case .beginner:
            return "New to triathlon or endurance sports"
        case .intermediate:
            return "Some triathlon experience, completed shorter races"
        case .advanced:
            return "Experienced triathlete, completed multiple races"
        case .elite:
            return "Competitive athlete with extensive racing background"
        }
    }
    
    var weeklyHoursRange: ClosedRange<Int> {
        switch self {
        case .beginner: return 4...8
        case .intermediate: return 6...12
        case .advanced: return 10...16
        case .elite: return 15...25
        }
    }
}

struct HeartRateZones: Codable {
    var zone1: ClosedRange<Int> // Recovery
    var zone2: ClosedRange<Int> // Aerobic base
    var zone3: ClosedRange<Int> // Tempo
    var zone4: ClosedRange<Int> // Lactate threshold
    var zone5: ClosedRange<Int> // VO2 max
    
    init(maxHR: Int) {
        zone1 = Int(Double(maxHR) * 0.50)...Int(Double(maxHR) * 0.60)
        zone2 = Int(Double(maxHR) * 0.60)...Int(Double(maxHR) * 0.70)
        zone3 = Int(Double(maxHR) * 0.70)...Int(Double(maxHR) * 0.80)
        zone4 = Int(Double(maxHR) * 0.80)...Int(Double(maxHR) * 0.90)
        zone5 = Int(Double(maxHR) * 0.90)...maxHR
    }
}

struct PaceZones: Codable {
    var easy: TimeInterval // minutes per km
    var tempo: TimeInterval
    var threshold: TimeInterval
    var interval: TimeInterval
    var race: TimeInterval
}

struct PowerZones: Codable {
    var zone1: ClosedRange<Int> // Recovery
    var zone2: ClosedRange<Int> // Endurance
    var zone3: ClosedRange<Int> // Tempo
    var zone4: ClosedRange<Int