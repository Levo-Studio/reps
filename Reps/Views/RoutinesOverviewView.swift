//
//  RoutinesOverviewView.swift
//  Reps
//
//  Screen 1 — app root. Flat list of routines with an inline add row.
//

import SwiftUI
import SwiftData

struct RoutinesOverviewView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Routine.sortIndex) private var routines: [Routine]

    @State private var isAddingRoutine = false
    @State private var newRoutineName = ""
    @FocusState private var addFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Reps")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Theme.primary)
                    .padding(.top, 12)
                    .padding(.bottom, 28)

                ForEach(routines) { routine in
                    NavigationLink(value: routine) {
                        routineRow(routine.name, color: Theme.primary)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) { delete(routine) } label: { Text("Delete") }
                    }
                }

                if isAddingRoutine {
                    addRoutineField
                } else {
                    Button {
                        beginAddingRoutine()
                    } label: {
                        routineRow("+ New Routine", color: Theme.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func routineRow(_ title: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 16)
            Divider().overlay(Theme.divider)
        }
        .contentShape(Rectangle())
    }

    private var addRoutineField: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("", text: $newRoutineName)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(Theme.primary)
                .tint(Theme.accent)
                .focused($addFieldFocused)
                .submitLabel(.done)
                .onSubmit { commitNewRoutine() }
                .onChange(of: addFieldFocused) { _, focused in
                    if !focused { commitNewRoutine() }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 16)
            Divider().overlay(Theme.divider)
        }
    }

    private func beginAddingRoutine() {
        newRoutineName = ""
        isAddingRoutine = true
        addFieldFocused = true
    }

    private func commitNewRoutine() {
        guard isAddingRoutine else { return }
        let name = newRoutineName.trimmingCharacters(in: .whitespacesAndNewlines)
        isAddingRoutine = false
        newRoutineName = ""
        guard !name.isEmpty else { return }
        let routine = Routine(name: name, sortIndex: (routines.map(\.sortIndex).max() ?? -1) + 1)
        context.insert(routine)
        try? context.save()
    }

    private func delete(_ routine: Routine) {
        context.delete(routine)
        try? context.save()
    }
}
