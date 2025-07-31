// MARK: - Views/Workouts/WorkoutListView.swift
import SwiftUI

struct WorkoutListView: View {
    @EnvironmentObject var trainingPlanViewModel: TrainingPlanViewModel
    @State private var selectedWeek: TrainingWeek?
    @State private var showingCalendar = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Week selector
                weekSelector
                
                // Workout list
                if trainingPlanViewModel.trainingWeeks.isEmpty {
                    emptyStateView
                } else {
                    workoutsList
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCalendar.toggle()
                    }) {
                        Image(systemName: showingCalendar ? "list.bullet" : "calendar")
                    }
                }
            }
        }
        .onAppear {
            if selectedWeek == nil {
                selectedWeek = trainingPlanViewModel.currentWeek ?? trainingPlanViewModel.trainingWeeks.first
            }
        }
    }
    
    private var weekSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(trainingPlanViewModel.trainingWeeks) { week in
                    WeekSelectorCard(
                        week: week,
                        isSelected: selectedWeek?.id == week.id
                    ) {
                        selectedWeek = week
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    private var workoutsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if let week = selectedWeek {
                    ForEach(week.workouts) { workout in
                        WorkoutCard(workout: workout)
                    }
                }
            }
            .padding()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Training Plan")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Select a race to generate your personalized training schedule")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            NavigationLink(destination: RaceSelectionView()) {
                Text("Select Race")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Views/Workouts/WorkoutDetailView.swift
struct WorkoutDetailView: View {
    @State var workout: Workout
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @EnvironmentObject var trainingPlanViewModel: TrainingPlanViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    workoutHeader
                    
                    // Description
                    workoutDescription
                    
                    // Completion section
                    if workout.isPast || workout.isToday {
                        completionSection
                    }
                    
                    // Notes section
                    notesSection
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle(workout.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                if workout.isPast || workout.isToday {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(workout.completed ? "Mark Incomplete" : "Complete") {
                            toggleCompletion()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(workout.completed ? .orange : .green)
                    }
                }
            }
        }
        .onAppear {
            workoutViewModel.selectWorkout(workout)
        }
    }
    
    private var workoutHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: workout.sport.icon)
                    .font(.system(size: 40))
                    .foregroundColor(workout.sport.color)
                    .frame(width: 60, height: 60)
                    .background(workout.sport.lightColor)
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.sport.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(workout.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(workout.date, format: .dateTime.weekday().month().day())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                InfoPill(icon: "clock", text: workout.formattedDuration)
                InfoPill(icon: "flame", text: workout.intensity.rawValue, color: workout.intensity.color)
                
                if workout.completed {
                    InfoPill(icon: "checkmark.circle", text: "Completed", color: .green)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var workoutDescription: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workout Details")
                .font(.headline)
            
            Text(workout.description)
                .font(.body)
                .lineSpacing(4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var completionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workout Completion")
                .font(.headline)
            
            if workout.completed {
                completedWorkoutDetails
            } else {
                incompleteWorkoutForm
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var completedWorkoutDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Duration:")
                    .fontWeight(.medium)
                Spacer()
                Text(formatDuration(workout.actualDuration ?? workout.duration))
                    .foregroundColor(.secondary)
            }
            
            if let effort = workout.perceivedEffort {
                HStack {
                    Text("Perceived Effort:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(effort)/10")
                        .foregroundColor(.secondary)
                }
            }
            
            if !workout.notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes:")
                        .fontWeight(.medium)
                    Text(workout.notes)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var incompleteWorkoutForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Duration input
            VStack(alignment: .leading, spacing: 8) {
                Text("Actual Duration")
                    .fontWeight(.medium)
                
                HStack {
                    TextField("Minutes", value: $workoutViewModel.actualDuration, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                    
                    Text("minutes")
                        .foregroundColor(.secondary)
                }
            }
            
            // RPE input
            VStack(alignment: .leading, spacing: 8) {
                Text("Perceived Effort (1-10)")
                    .fontWeight(.medium)
                
                HStack {
                    ForEach(1...10, id: \.self) { rating in
                        Button(action: {
                            workoutViewModel.updatePerceivedEffort(rating)
                        }) {
                            Text("\(rating)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .frame(width: 30, height: 30)
                                .background(workoutViewModel.perceivedEffort == rating ? Color.blue : Color(.systemGray5))
                                .foregroundColor(workoutViewModel.perceivedEffort == rating ? .white : .primary)
                                .cornerRadius(6)
                        }
                    }
                }
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
            
            if workout.completed && !workout.notes.isEmpty {
                Text(workout.notes)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                TextField("Add workout notes...", text: $workoutViewModel.workoutNotes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
            }
        }
    }
    
    private func toggleCompletion() {
        if workout.completed {
            workoutViewModel.resetWorkout()
            if let updatedWorkout = workoutViewModel.selectedWorkout {
                workout = updatedWorkout
                trainingPlanViewModel.completeWorkout(updatedWorkout)
            }
        } else {
            if let completedWorkout = workoutViewModel.completeWorkout() {
                workout = completedWorkout
                trainingPlanViewModel.completeWorkout(completedWorkout)
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 60
        let minutes = Int(duration) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Views/Components/WorkoutCard.swift
struct WorkoutCard: View {
    let workout: Workout
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            HStack(spacing: 16) {
                // Sport icon
                Image(systemName: workout.sport.icon)
                    .font(.title2)
                    .foregroundColor(workout.sport.color)
                    .frame(width: 40, height: 40)
                    .background(workout.sport.lightColor)
                    .cornerRadius(8)
                
                // Workout info
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(workout.date, format: .dateTime.weekday().abbreviated())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Duration and status
                VStack(alignment: .trailing, spacing: 4) {
                    Text(workout.formattedDuration)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 8) {
                        IntensityBadge(intensity: workout.intensity, compact: true)
                        
                        if workout.completed {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else if workout.isPast {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(workout.completed ? Color.green.opacity(0.1) : Color(.systemBackground))
                    .stroke(
                        workout.completed ? Color.green.opacity(0.3) : Color(.systemGray4),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            WorkoutDetailView(workout: workout)
        }
    }
}

// MARK: - Views/Components/WeekSelectorCard.swift
struct WeekSelectorCard: View {
    let week: TrainingWeek
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("Week \(week.weekNumber)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(week.weekRange)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                
                Text("\(week.completedWorkouts)/\(week.workouts.count)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .blue)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color(.systemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Views/Components/InfoPill.swift
struct InfoPill: View {
    let icon: String
    let text: String
    let color: Color
    
    init(icon: String, text: String, color: Color = .blue) {
        self.icon = icon
        self.text = text
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(6)
    }
}

#Preview {
    WorkoutListView()
        .environmentObject(TrainingPlanViewModel())
}