// MARK: - Views/Dashboard/DashboardView.swift
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var trainingPlanViewModel: TrainingPlanViewModel
    @EnvironmentObject var raceViewModel: RaceViewModel
    @State private var showingRaceSetup = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    headerSection
                    
                    // Race Countdown
                    if let nextRace = raceViewModel.getNextRace() {
                        RaceCountdownCard(race: nextRace)
                    } else {
                        noRaceCard
                    }
                    
                    // Today's Workout
                    todaysWorkoutSection
                    
                    // Weekly Progress
                    weeklyProgressSection
                    
                    // Upcoming Workouts
                    upcomingWorkoutsSection
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .sheet(isPresented: $showingRaceSetup) {
                RaceSetupView()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Good morning!")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Ready to train?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "bell")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
    private var noRaceCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("No Race Selected")
                .font(.headline)
            
            Text("Select a race to generate your personalized training plan")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Select Race") {
                showingRaceSetup = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var todaysWorkoutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Workout")
                .font(.headline)
            
            if let todaysWorkout = trainingPlanViewModel.getTodaysWorkout() {
                TodayWorkoutCard(workout: todaysWorkout)
            } else {
                restDayCard
            }
        }
    }
    
    private var restDayCard: some View {
        HStack {
            Image(systemName: "bed.double.fill")
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text("Rest Day")
                    .font(.headline)
                Text("Recovery and regeneration")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var weeklyProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)
            
            WeeklyProgressCard()
        }
    }
    
    private var upcomingWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Workouts")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink("See All") {
                    WorkoutListView()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(trainingPlanViewModel.getUpcomingWorkouts(limit: 3)) { workout in
                    UpcomingWorkoutRow(workout: workout)
                }
            }
        }
    }
}

// MARK: - Views/Dashboard/TodayWorkoutCard.swift
struct TodayWorkoutCard: View {
    let workout: Workout
    @State private var showingWorkoutDetail = false
    
    var body: some View {
        Button(action: {
            showingWorkoutDetail = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: workout.sport.icon)
                        .font(.title2)
                        .foregroundColor(workout.sport.color)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(workout.formattedDuration)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    IntensityBadge(intensity: workout.intensity)
                }
                
                if !workout.description.isEmpty {
                    Text(workout.description.prefix(100) + (workout.description.count > 100 ? "..." : ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if workout.completed {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(workout.sport.lightColor)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingWorkoutDetail) {
            WorkoutDetailView(workout: workout)
        }
    }
}

// MARK: - Views/Dashboard/RaceCountdownCard.swift
struct RaceCountdownCard: View {
    let race: Race
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(race.name)
                        .font(.headline)
                    
                    Text(race.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(race.daysUntilRace)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("days to go")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text(race.distance.rawValue)
                    .font(.subheadline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(6)
                
                Spacer()
                
                Text(race.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Views/Dashboard/WeeklyProgressCard.swift
struct WeeklyProgressCard: View {
    @EnvironmentObject var trainingPlanViewModel: TrainingPlanViewModel
    
    var body: some View {
        let stats = trainingPlanViewModel.getWeeklyStats()
        
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                ProgressStatView(
                    title: "Hours",
                    value: String(format: "%.1f", stats.totalHours),
                    icon: "clock"
                )
                
                ProgressStatView(
                    title: "Workouts",
                    value: "\(stats.completedWorkouts)/\(stats.totalWorkouts)",
                    icon: "checkmark.circle"
                )
                
                ProgressStatView(
                    title: "Completion",
                    value: "\(Int((Double(stats.completedWorkouts) / Double(max(stats.totalWorkouts, 1))) * 100))%",
                    icon: "chart.pie"
                )
            }
            
            if stats.totalWorkouts > 0 {
                ProgressView(
                    value: Double(stats.completedWorkouts),
                    total: Double(stats.totalWorkouts)
                )
                .tint(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Views/Components/ProgressStatView.swift
struct ProgressStatView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Views/Components/UpcomingWorkoutRow.swift
struct UpcomingWorkoutRow: View {
    let workout: Workout
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: workout.sport.icon)
                .font(.title3)
                .foregroundColor(workout.sport.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(workout.date, format: .dateTime.weekday().month().day())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(workout.formattedDuration)
                    .font(.caption)
                    .fontWeight(.medium)
                
                IntensityBadge(intensity: workout.intensity, compact: true)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Views/Components/IntensityBadge.swift
struct IntensityBadge: View {
    let intensity: WorkoutIntensity
    let compact: Bool
    
    init(intensity: WorkoutIntensity, compact: Bool = false) {
        self.intensity = intensity
        self.compact = compact
    }
    
    var body: some View {
        Text(intensity.rawValue)
            .font(compact ? .caption2 : .caption)
            .fontWeight(.medium)
            .padding(.horizontal, compact ? 6 : 8)
            .padding(.vertical, compact ? 2 : 4)
            .background(intensity.color.opacity(0.2))
            .foregroundColor(intensity.color)
            .cornerRadius(compact ? 4 : 6)
    }
}

#Preview {
    DashboardView()
        .environmentObject(TrainingPlanViewModel())
        .environmentObject(RaceViewModel())
}