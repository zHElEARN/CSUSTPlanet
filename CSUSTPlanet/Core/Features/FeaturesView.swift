//
//  FeaturesView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import SwiftUI

struct FeaturesView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var globalManager: GlobalManager

    @Environment(\.horizontalSizeClass) var sizeClass

    @State private var isPhysicsExperimentLoginPresented: Bool = false
    @State private var isAnnualReviewPresented: Bool = false
    @StateObject var physicsExperimentManager = PhysicsExperimentManager.shared

    private let spacing: CGFloat = 12

    private var horizontalPadding: CGFloat {
        return sizeClass == .regular ? 32 : 20
    }

    private var shouldShowAnnualReviewBanner: Bool {
        let calendar = Calendar.current
        let cutoffComponents = DateComponents(year: 2026, month: 3, day: 14)
        guard let cutoffDate = calendar.date(from: cutoffComponents) else {
            return true
        }
        return Date() < cutoffDate
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: sizeClass == .regular ? 32 : 28) {
                    if shouldShowAnnualReviewBanner {
                        AnnualReviewBanner(isPresented: $isAnnualReviewPresented)
                            .padding(.top, 10)
                    }

                    educationalSystemSection

                    moocSection

                    campusToolsSection

                    if sizeClass == .regular {
                        HStack(alignment: .top, spacing: spacing) {
                            physicsSection
                            examQuerySection
                        }
                        .padding(.horizontal, horizontalPadding)
                    } else {
                        VStack(spacing: spacing) {
                            physicsSection
                            examQuerySection
                        }
                        .padding(.horizontal, horizontalPadding)
                    }

                    Color.clear.frame(height: 20)
                }
                .frame(maxWidth: sizeClass == .regular ? 900 : .infinity)
                .frame(maxWidth: .infinity)
                .padding(.top, sizeClass == .regular ? 20 : 0)
            }
            .navigationTitle("全部功能")
            .background(Color(uiColor: .systemGroupedBackground))
            .sheet(isPresented: $isPhysicsExperimentLoginPresented) {
                PhysicsExperimentLoginView(isPresented: $isPhysicsExperimentLoginPresented)
                    .environmentObject(physicsExperimentManager)
            }
            .fullScreenCover(isPresented: $isAnnualReviewPresented) {
                AnnualReviewView(isPresented: $isAnnualReviewPresented)
            }
            .trackView("Features")
        }
        .tabItem {
            Image(uiImage: UIImage(systemName: "square.grid.2x2")!)
            Text("全部功能")
        }
    }

    // MARK: - Extracted Subviews

    private var educationalSystemSection: some View {
        VStack(spacing: spacing) {
            sectionHeader(title: "教务系统", color: .blue) {
                Group {
                    if authManager.isSSOLoggingIn {
                        StatusBadge(text: "统一身份认证登录中")
                    } else if !authManager.isSSOLoggedIn {
                        ActionBadge(text: "点击登录", icon: "person.crop.circle.badge.exclamationmark") {
                            globalManager.selectedTab = .profile
                        }
                    } else if authManager.isEducationLoggingIn {
                        StatusBadge(text: "教务登录中")
                    } else {
                        ActionBadge(text: "刷新登录", icon: "arrow.clockwise", action: authManager.educationLogin)
                    }
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 150), spacing: spacing), count: 2), spacing: spacing) {
                HeroCard(destination: CourseScheduleView(), title: "我的课表", icon: "calendar", color: .purple)
                HeroCard(destination: GradeQueryView(), title: "成绩查询", icon: "doc.text.magnifyingglass", color: .blue)
                HeroCard(destination: ExamScheduleView(), title: "考试安排", icon: "pencil.and.outline", color: .orange)
                HeroCard(destination: GradeAnalysisView(), title: "成绩分析", icon: "chart.bar.xaxis", color: .green)
            }
        }
        .padding(.horizontal, horizontalPadding)
    }

    private var moocSection: some View {
        VStack(spacing: spacing) {
            sectionHeader(title: "网络课程中心", color: .indigo) {
                Group {
                    if authManager.isSSOLoggingIn {
                        StatusBadge(text: "统一身份认证登录中")
                    } else if !authManager.isSSOLoggedIn {
                        ActionBadge(text: "点击登录", icon: "person.crop.circle.badge.exclamationmark") {
                            globalManager.selectedTab = .profile
                        }
                    } else if authManager.isMoocLoggingIn {
                        StatusBadge(text: "课程中心登录中")
                    } else if authManager.isSSOLoggedIn && !authManager.isSSOLoggingIn {
                        ActionBadge(text: "刷新登录", icon: "arrow.clockwise", action: authManager.moocLogin)
                    }
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 150), spacing: spacing), count: 2), spacing: spacing) {
                HeroCard(destination: CoursesView(), title: "所有课程", icon: "books.vertical.fill", color: .indigo)
                HeroCard(destination: UrgentCoursesView(), title: "待提交作业", icon: "list.bullet.clipboard", color: .red)
            }
        }
        .padding(.horizontal, horizontalPadding)
    }

    private var campusToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "校园工具", color: .orange)
                .padding(.horizontal, horizontalPadding)

            if sizeClass == .regular {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 85), spacing: 12)], spacing: 12) {
                    toolItems
                }
                .padding(.horizontal, horizontalPadding)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Spacer().frame(width: horizontalPadding - 12)
                        toolItems
                        Spacer().frame(width: horizontalPadding - 12)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var toolItems: some View {
        ServiceSquare(destination: ElectricityQueryView(), title: "电量查询", icon: "bolt.fill", color: .yellow)
        ServiceSquare(destination: AvailableClassroomView(), title: "空教室查询", icon: "building.2.fill", color: .blue)
        ServiceSquare(destination: CampusMapView(), title: "校园地图", icon: "map.fill", color: .mint)
        ServiceSquare(destination: SchoolCalendarListView(), title: "校历", icon: "calendar.badge.clock", color: .pink)
        ServiceSquare(destination: ElectricityRechargeView(), title: "电费充值", icon: "creditcard.fill", color: .cyan)
        ServiceSquare(destination: WebVPNConverterView(), title: "WebVPN", icon: "lock.shield", color: .gray)
    }

    private var physicsSection: some View {
        VStack(spacing: spacing) {
            sectionHeader(title: "大学物理实验", color: .purple) {
                Button {
                    isPhysicsExperimentLoginPresented = true
                } label: {
                    Text("登录")
                        .font(.caption.bold())
                        .foregroundColor(.purple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            VStack(spacing: 0) {
                ToolRow(
                    destination: PhysicsExperimentScheduleView().environmentObject(physicsExperimentManager),
                    title: "实验安排", icon: "calendar", color: .purple)

                Divider().padding(.leading, 56)

                ToolRow(
                    destination: PhysicsExperimentGradeView().environmentObject(physicsExperimentManager),
                    title: "实验成绩", icon: "doc.text", color: .purple
                )
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        }
    }

    private var examQuerySection: some View {
        VStack(spacing: spacing) {
            sectionHeader(title: "其他考试查询", color: .indigo)

            VStack(spacing: 0) {
                ToolRow(destination: CETView(), title: "四六级查询", icon: "character.book.closed", color: .indigo)

                Divider().padding(.leading, 56)

                ToolRow(destination: MandarinView(), title: "普通话查询", icon: "mic.circle.fill", color: .indigo)
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Components Helper

    @ViewBuilder
    private func sectionHeader<Content: View>(title: String, color: Color, @ViewBuilder actions: () -> Content = { EmptyView() }) -> some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.title3.bold())

            Spacer()

            actions()
        }
    }
}

// MARK: - Custom Card Components
private struct HeroCard<Destination: View>: View {
    let destination: Destination
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        TrackLink(destination: destination) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(color.gradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                    )

                VStack(alignment: .leading) {
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(height: 28)

                    Spacer()

                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white.opacity(0.95))
                        .frame(height: 20)
                }
                .padding(14)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(height: 90)
    }
}

private struct ServiceSquare<Destination: View>: View {
    let destination: Destination
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        TrackLink(destination: destination) {
            VStack(alignment: .center, spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(color.opacity(0.15)))

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(width: 85, height: 95)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }
}

private struct ToolRow<Destination: View>: View {
    let destination: Destination
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        TrackLink(destination: destination) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(color.gradient)
                    .cornerRadius(7)

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Status Indicators

private struct ActionBadge: View {
    let text: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(text)
            }
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.blue.opacity(0.1)))
            .foregroundColor(.blue)
        }
    }
}

private struct StatusBadge: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            ProgressView()
                .scaleEffect(0.6)
                .frame(width: 10, height: 10)

            Text(text)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.secondary.opacity(0.1)))
        .foregroundColor(.secondary)
    }
}
// MARK: - 2025 年度总结 Banner

private struct AnnualReviewBanner: View {
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme

    // 主题色 - 与 AnnualReview 保持一致
    private let accentColor = Color(hex: "00E096")

    private var backgroundGradient: LinearGradient {
        if colorScheme == .dark {
            // 深色模式 - 与 AnnualReview 一致的深黑色
            return LinearGradient(
                stops: [
                    .init(color: Color(hex: "0D0D0D"), location: 0),
                    .init(color: Color(hex: "1C1C1E"), location: 1),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // 浅色模式 - 柔和的浅色渐变
            return LinearGradient(
                stops: [
                    .init(color: Color(hex: "F5F5F7"), location: 0),
                    .init(color: Color(hex: "E8E8EA"), location: 1),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(hex: "1C1C1E")
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color(hex: "8E8E93") : Color(hex: "6E6E73")
    }

    private var decorCircleColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)
    }

    var body: some View {
        Button {
            isPresented = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(backgroundGradient)

                GeometryReader { geo in
                    ZStack {
                        Circle()
                            .stroke(decorCircleColor, lineWidth: 1)
                            .frame(width: geo.size.width * 0.8)
                            .offset(x: geo.size.width * 0.4, y: -geo.size.height * 0.2)

                        Circle()
                            .stroke(decorCircleColor.opacity(0.5), lineWidth: 1)
                            .frame(width: geo.size.width * 1.2)
                            .offset(x: geo.size.width * 0.3, y: -geo.size.height * 0.4)
                    }
                }
                .clipped()

                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MEMORIES ARCHIVE 2025")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(accentColor.opacity(0.15))
                            .cornerRadius(4)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("2025 长理星球")
                                .font(.system(size: 20, weight: .bold))
                            Text("年度总结")
                                .font(.system(size: 24, weight: .heavy))
                        }
                        .foregroundColor(primaryTextColor)

                        Text("看看你在长理度过的 2025 年")
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                            .padding(.top, 4)
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(RadialGradient(colors: [accentColor.opacity(0.3), .clear], center: .center, startRadius: 1, endRadius: 40))
                            .frame(width: 80, height: 80)

                        Image(systemName: "sparkles")
                            .font(.system(size: 30))
                            .foregroundColor(accentColor.opacity(colorScheme == .dark ? 0.9 : 0.8))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .contentShape(.rect(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        FeaturesView()
            .environmentObject(AuthManager.shared)
            .environmentObject(GlobalManager.shared)
    }
}
