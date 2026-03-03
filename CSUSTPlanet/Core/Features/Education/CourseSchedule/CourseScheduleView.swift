//
//  CourseScheduleView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import AlertToast
import CSUSTKit
import SwiftUI

// MARK: - CourseScheduleView

struct CourseScheduleView: View {
    @Environment(\.horizontalSizeClass) var sizeClass

    @StateObject var viewModel = CourseScheduleViewModel()

    private var isPad: Bool {
        sizeClass == .regular
    }

    var colSpacing: CGFloat { isPad ? 4 : 2 }
    var rowSpacing: CGFloat { isPad ? 4 : 2 }
    var timeColWidth: CGFloat { isPad ? 50 : 30 }
    var headerHeight: CGFloat { isPad ? 70 : 50 }
    var sectionHeight: CGFloat { isPad ? 90 : 60 }

    var body: some View {
        VStack(spacing: 0) {
            topControlBar
            if let courseScheduleData = viewModel.data {
                let weeklyCourses = CourseScheduleUtil.getWeeklyCourses(courseScheduleData.value.courses)

                // 课表的每一周翻页
                TabView(selection: $viewModel.currentWeek) {
                    ForEach(1...CourseScheduleUtil.weekCount, id: \.self) { week in
                        tableView(for: week, semesterStartDate: courseScheduleData.value.semesterStartDate, weeklyCourses: weeklyCourses)
                            .tag(week)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea(.container, edges: .bottom)
            } else {
                emptyStateView
            }
        }
        .onAppear {
            if sizeClass == .regular {
                viewModel.isShowingDetail = true
            }
        }
        .apply { view in
            if sizeClass == .regular {
                view
                    .inspector(isPresented: $viewModel.isShowingDetail) {
                        Group {
                            if let course = viewModel.selectedCourse, let session = viewModel.selectedSession {
                                CourseScheduleDetailView(course: course, session: session, isShowingToolbar: false, isPresented: $viewModel.isShowingDetail)
                            } else {
                                ContentUnavailableView("请选择课程查看详情", systemImage: "doc.text.magnifyingglass")
                            }
                        }
                    }
                    .inspectorColumnWidth(min: 350, ideal: 400, max: 450)
            } else {
                view.sheet(isPresented: $viewModel.isShowingDetail) {
                    if let course = viewModel.selectedCourse, let session = viewModel.selectedSession {
                        CourseScheduleDetailView(course: course, session: session, isShowingToolbar: true, isPresented: $viewModel.isShowingDetail)
                    } else {
                        ContentUnavailableView("请选择课程查看详情", systemImage: "doc.text.magnifyingglass")
                    }
                }
            }
        }
        .navigationTitle("我的课表")
        .apply { view in
            if #available(iOS 26.0, *) {
                view.navigationSubtitle(viewModel.selectedSemester == nil ? "默认学期" : "学期" + (viewModel.selectedSemester ?? ""))
            } else {
                view
            }
        }
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { viewModel.isShowingSemestersSheet = true }) {
                    Image(systemName: "calendar")
                }

                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Button(action: viewModel.loadCourses) {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        .task { viewModel.task() }
        .toast(isPresenting: $viewModel.isShowingWarning) {
            AlertToast(displayMode: .banner(.slide), type: .systemImage("exclamationmark.triangle", .yellow), title: "警告", subTitle: viewModel.warningMessage)
        }
        .toast(isPresenting: $viewModel.isShowingError) {
            AlertToast(type: .error(.red), title: "错误", subTitle: viewModel.errorMessage)
        }
        .sheet(isPresented: $viewModel.isShowingSemestersSheet) {
            CourseSemesterView()
                .environmentObject(viewModel)
        }
        .trackView("CourseSchedule")
    }

    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: isPad ? 80 : 50))
                .foregroundColor(.secondary)
            Text("暂无课表数据")
                .font(isPad ? .title2 : .headline)
            Text("当前学期未设置或数据加载失败")
                .font(isPad ? .body : .subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - 顶部全局控制栏

    @ViewBuilder
    private var topControlBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("今日 \(CourseScheduleUtil.dateFormatter.string(from: viewModel.today))")
                    .font(isPad ? .title3 : .headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                if #unavailable(iOS 26.0) {
                    Text(viewModel.selectedSemester ?? "默认学期")
                        .font(isPad ? .subheadline : .caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Menu {
                    ForEach(1...CourseScheduleUtil.weekCount, id: \.self) { week in
                        Button("第 \(week) 周") {
                            withAnimation { viewModel.currentWeek = week }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("第 \(viewModel.currentWeek) 周")
                            .fontWeight(.medium)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(isPad ? .subheadline : .caption2)
                    }
                    .padding(.horizontal, isPad ? 16 : 12)
                    .padding(.vertical, isPad ? 8 : 6)
                    .background(Color.appSecondarySystemBackground)
                    .cornerRadius(8)
                }

                Button(action: viewModel.goToCurrentWeek) {
                    Text("本周")
                        .fontWeight(.medium)
                }
                .disabled(viewModel.realCurrentWeek == nil || viewModel.currentWeek == viewModel.realCurrentWeek)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.appSystemBackground)
        // .overlay(Divider().opacity(0.6), alignment: .bottom)
    }

    // MARK: - 单周课表页面

    @ViewBuilder
    private func tableView(for week: Int, semesterStartDate: Date, weeklyCourses: [Int: [CourseDisplayInfo]]) -> some View {
        // 课表网格
        ScrollView {
            ZStack(alignment: .topLeading) {
                // 背景网格
                backgroundGrid

                // 课程视图
                coursesOverlay(for: week, weeklyCourses: weeklyCourses)
            }
        }
        .safeAreaInset(edge: .top) {
            // 星期头部（日期和周几）
            headerView(for: week, semesterStartDate: semesterStartDate)
                .apply { view in
                    if #available(iOS 26.0, *) {
                        view
                            .background {
                                Rectangle()
                                    .fill(.clear)
                                    .glassEffect()
                                    .padding(.horizontal, 4)
                            }
                    } else {
                        view.background(.ultraThinMaterial)
                    }
                }
        }
    }

    // MARK: - 星期头部视图

    @ViewBuilder
    private func headerView(for week: Int, semesterStartDate: Date) -> some View {
        let dates = CourseScheduleUtil.getDatesForWeek(semesterStartDate: semesterStartDate, week: week)

        HStack(spacing: colSpacing) {
            // 左上角月份显示区
            VStack(alignment: .center, spacing: 0) {
                if let firstDate = dates.first {
                    Text(CourseScheduleUtil.monthFormatter.string(from: firstDate))
                        .font(.system(size: isPad ? 18 : 14, weight: .bold))
                    Text("月")
                        .font(.system(size: isPad ? 14 : 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: timeColWidth)

            // "周日" 到 "周六"
            ForEach(Array(zip(EduHelper.DayOfWeek.allCases, dates)), id: \.0) { day, date in
                let isToday = CourseScheduleUtil.isToday(date)
                VStack(spacing: 2) {
                    Text(day.stringValue)
                        .font(.system(size: isPad ? 15 : 11))
                        .foregroundColor(isToday ? .accentColor : .secondary)
                        .fontWeight(isToday ? .bold : .medium)

                    ZStack {
                        Circle()
                            .fill(isToday ? Color.accentColor : Color.clear)

                        Text(CourseScheduleUtil.dayFormatter.string(from: date))
                            .font(.system(size: isPad ? 18 : 14, weight: isToday ? .bold : .medium))
                            .foregroundColor(isToday ? .white : .primary)
                    }
                    .frame(width: isPad ? 36 : 26, height: isPad ? 36 : 26)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 6)
        .padding(.horizontal, 5)
    }

    // MARK: - 背景网格视图

    @ViewBuilder
    private var backgroundGrid: some View {
        HStack(spacing: colSpacing) {
            // 左侧时间列
            VStack(spacing: rowSpacing) {
                ForEach(1...10, id: \.self) { section in
                    VStack(spacing: 1) {
                        Text("\(section)")
                            .font(.system(size: isPad ? 18 : 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)

                        VStack(spacing: 0) {
                            Text(CourseScheduleUtil.sectionTimeString[section - 1].0)
                            Text(CourseScheduleUtil.sectionTimeString[section - 1].1)
                        }
                        .font(.system(size: isPad ? 12 : 9))
                        .foregroundColor(.secondary)
                    }
                    .frame(width: timeColWidth, height: sectionHeight)
                }
            }

            VStack(spacing: rowSpacing) {
                ForEach(1...10, id: \.self) { _ in
                    HStack(spacing: colSpacing) {
                        ForEach(1...7, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.appSecondarySystemBackground.opacity(0.3))
                                .frame(height: sectionHeight)
                                .cornerRadius(isPad ? 8 : 4)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical)
    }

    // MARK: - 课程浮层视图

    @ViewBuilder
    private func coursesOverlay(for week: Int, weeklyCourses: [Int: [CourseDisplayInfo]]) -> some View {
        GeometryReader { geometry in
            // 计算每日的列宽
            let horizontalPadding: CGFloat = 5

            // 通过减去水平内边距来计算实际内容宽度
            let contentWidth = geometry.size.width - (horizontalPadding * 2)

            // 正确计算间距的总宽度。8列之间有7个间隔
            let totalSpacingWidth = colSpacing * 7

            // 计算每一天列的最终宽度
            let dayColumnWidth = (contentWidth - timeColWidth - totalSpacingWidth) / 7

            ZStack(alignment: .topLeading) {
                if let coursesForWeek = weeklyCourses[week] {
                    ForEach(coursesForWeek) { courseInfo in
                        CourseCardView(course: courseInfo.course, session: courseInfo.session, color: viewModel.courseColors[courseInfo.course.courseName] ?? .gray) {
                            viewModel.selectedCourse = courseInfo.course
                            viewModel.selectedSession = courseInfo.session
                            viewModel.isShowingDetail = true
                        }
                        .frame(width: dayColumnWidth)
                        .frame(height: calculateHeight(for: courseInfo.session))
                        .offset(
                            // 应用初始内边距到 x 偏移量以对齐坐标系
                            x: horizontalPadding + calculateXOffset(for: courseInfo.session.dayOfWeek, columnWidth: dayColumnWidth),
                            y: calculateYOffset(for: courseInfo.session)
                        )
                    }
                }
            }
        }
        .padding(.vertical)
    }
}

extension CourseScheduleView {
    // 计算课程卡片的高度
    func calculateHeight(for session: EduHelper.ScheduleSession) -> CGFloat {
        let sections = CGFloat(session.endSection - session.startSection + 1)
        return sections * sectionHeight + (sections - 1) * rowSpacing
    }

    // 计算课程卡片的 Y 轴偏移
    func calculateYOffset(for session: EduHelper.ScheduleSession) -> CGFloat {
        let y = CGFloat(session.startSection - 1)
        return y * sectionHeight + y * rowSpacing
    }

    // 计算课程卡片的 X 轴偏移
    func calculateXOffset(for day: EduHelper.DayOfWeek, columnWidth: CGFloat) -> CGFloat {
        let x = CGFloat(day.rawValue)
        return timeColWidth + colSpacing + (x * columnWidth) + (x * colSpacing)
    }
}
