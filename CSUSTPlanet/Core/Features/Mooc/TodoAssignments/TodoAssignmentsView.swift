//
//  TodoAssignmentsView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/20.
//

import CSUSTKit
import SwiftUI

struct TodoAssignmentsView: View {
    @State private var viewModel = TodoAssignmentsViewModel()

    var body: some View {
        Group {
            if let courseGroups = viewModel.todoAssignmentsData?.value, !courseGroups.isEmpty {
                Form {
                    ForEach(courseGroups, id: \.course.id) { group in
                        Section {
                            DisclosureGroup(isExpanded: bindingForCourse(group.course.id)) {
                                let assignments = viewModel.displayedAssignments(for: group)
                                ForEach(assignments.indices, id: \.self) { index in
                                    AssignmentInfoView(assignment: assignments[index])
                                }
                            } label: {
                                HStack {
                                    Text(group.course.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .contentShape(.rect)
                                        .onTapGesture {
                                            withAnimation { viewModel.toggleExpanded(courseID: group.course.id) }
                                        }

                                    Spacer()

                                    Button {
                                        withAnimation { viewModel.toggleShowAllAssignments(courseID: group.course.id) }
                                    } label: {
                                        Text(viewModel.isShowingAllAssignments(courseID: group.course.id) ? "仅未截止" : "查看全部")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .formStyle(.grouped)
            } else {
                ContentUnavailableView("暂无待提交作业", systemImage: "book.closed", description: Text("当前没有需要提交的作业"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        #if os(iOS)
        .background(Color(PlatformColor.systemGroupedBackground))
        #endif
        .task { await viewModel.loadInitial() }
        .safeRefreshable { await viewModel.loadTodoAssignments() }
        .errorToast($viewModel.errorToast)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(asyncAction: viewModel.loadTodoAssignments) {
                    if viewModel.isLoadingAssignments {
                        ProgressView().smallControlSizeOnMac()
                    } else {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(viewModel.isLoadingAssignments)
            }
        }
        .navigationTitle("待提交作业")
        .navigationSubtitleCompat("共\(viewModel.unexpiredAssignmentsCount)个未截止作业")
        .trackView("TodoAssignments")
    }

    private func bindingForCourse(_ courseID: String) -> Binding<Bool> {
        Binding(
            get: { viewModel.isExpanded(courseID: courseID) },
            set: { viewModel.setExpanded($0, courseID: courseID) }
        )
        .withAnimation()
    }
}

struct AssignmentInfoView: View {
    let assignment: MoocHelper.Assignment

    @ViewBuilder
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(assignment.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                Spacer()

                if assignment.submitStatus {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                } else if assignment.canSubmit {
                    Image(systemName: "circle")
                        .foregroundColor(.orange)
                        .font(.caption)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            HStack {
                Text("发布人")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(assignment.publisher)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("开始时间")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(assignment.startTime, format: .dateTime.year().month().day().hour().minute())
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(assignment.startTime, format: .relative(presentation: .named, unitsStyle: .abbreviated))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.secondary.opacity(0.15), in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(.secondary.opacity(0.25), lineWidth: 0.5)
                    }
            }

            HStack {
                Text("截止时间")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(assignment.deadline, format: .dateTime.year().month().day().hour().minute())
                    .font(.caption)
                    .foregroundColor(assignment.submitStatus ? .secondary : .red)
                Text(assignment.deadline, format: .relative(presentation: .named, unitsStyle: .abbreviated))
                    .font(.caption2)
                    .foregroundColor(assignment.submitStatus ? .secondary : .red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background((assignment.submitStatus ? Color.secondary : .red).opacity(0.15), in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke((assignment.submitStatus ? Color.secondary : .red).opacity(0.25), lineWidth: 0.5)
                    }
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    NavigationStack {
        TodoAssignmentsView()
    }
}
