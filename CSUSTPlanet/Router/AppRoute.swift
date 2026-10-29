//
//  AppRoute.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/4/12.
//

import CSUSTKit
import Foundation
import SwiftUI

enum AppRoute: Hashable, RouteNode {
    case overview(OverviewRoute)
    case features(FeaturesRoute)
    case profile(ProfileRoute)

    @ViewBuilder
    var destinationView: some View {
        switch self {
        case .overview(let route):
            route.destinationView
        case .features(let route):
            route.destinationView
        case .profile(let route):
            route.destinationView
        }
    }

    // MARK: - OverviewRoute

    enum OverviewRoute: Hashable, RouteNode {
        case announcementList(viewModel: AnnouncementListViewModel)
        case overviewSettings

        @ViewBuilder
        var destinationView: some View {
            switch self {
            case .announcementList(let viewModel):
                AnnouncementListView(viewModel: viewModel)
            case .overviewSettings:
                OverviewSettingsView()
            }
        }
    }

    // MARK: - FeaturesRoute

    enum FeaturesRoute: Hashable, RouteNode {
        case courseSchedule(CourseScheduleRoute? = nil)
        case gradeQuery(GradeQueryRoute? = nil)
        case examSchedule
        case gradeAnalysis
        case courses(CoursesRoute? = nil)
        case assignments
        case chaoxingAssignments
        case dormList(DormListRoute? = nil)
        case availableClassroom
        case campusMap
        case schoolCalendarList(SchoolCalendarListRoute? = nil)
        case electricityRecharge
        case webVPNConverter
        case eval
        case physicsExperimentSchedule
        case physicsExperimentGrade
        case cetQuery
        case mandarinQuery
        case ncreQuery

        @ViewBuilder
        var destinationView: some View {
            switch self {
            case .courseSchedule(nil):
                CourseScheduleView()
            case .courseSchedule(let route?):
                route.destinationView
            case .gradeQuery(nil):
                GradeQueryView()
            case .gradeQuery(let route?):
                route.destinationView
            case .examSchedule:
                ExamScheduleView()
            case .gradeAnalysis:
                GradeAnalysisView()
            case .courses(nil):
                CoursesView()
            case .courses(let route?):
                route.destinationView
            case .assignments:
                AssignmentsView()
            case .chaoxingAssignments:
                ChaoxingAssignmentsView()
            case .dormList(nil):
                DormListView()
            case .dormList(let route?):
                route.destinationView
            case .availableClassroom:
                AvailableClassroomView()
            case .campusMap:
                CampusMapView()
            case .schoolCalendarList(nil):
                SchoolCalendarListView()
            case .schoolCalendarList(let route?):
                route.destinationView
            case .electricityRecharge:
                ElectricityRechargeView()
            case .webVPNConverter:
                WebVPNConverterView()
            case .eval:
                EvalView()
            case .physicsExperimentSchedule:
                PhysicsExperimentScheduleView()
            case .physicsExperimentGrade:
                PhysicsExperimentGradeView()
            case .cetQuery:
                CETQueryView()
            case .mandarinQuery:
                MandarinQueryView()
            case .ncreQuery:
                NCREQueryView()
            }
        }

        enum CourseScheduleRoute: Hashable, RouteNode {
            case settings
            case edit(CustomCourseScheduleGRDB)
            case courseDetail(CustomCourseGRDB)

            @ViewBuilder
            var destinationView: some View {
                switch self {
                case .settings:
                    CourseScheduleSettingsView()
                case .edit(let schedule):
                    CourseScheduleManageView(schedule: schedule)
                case .courseDetail(let course):
                    CourseScheduleCourseDetailView(course: course)
                }
            }
        }

        enum GradeQueryRoute: Hashable, RouteNode {
            case detail(EduHelper.CourseGrade)

            @ViewBuilder
            var destinationView: some View {
                switch self {
                case .detail(let courseGrade):
                    GradeDetailView(courseGrade: courseGrade)
                }
            }
        }

        enum CoursesRoute: Hashable, RouteNode {
            case detail(MoocHelper.Course)

            @ViewBuilder
            var destinationView: some View {
                switch self {
                case .detail(let course):
                    CourseDetailView(course: course)
                }
            }
        }

        enum DormListRoute: Hashable, RouteNode {
            case detail(DormGRDB, DormDetailRoute? = nil)

            @ViewBuilder
            var destinationView: some View {
                switch self {
                case .detail(let dorm, nil):
                    DormDetailView(dorm: dorm)
                case .detail(_, let route?):
                    route.destinationView
                }
            }

            enum DormDetailRoute: Hashable, RouteNode {
                case history(DormDetailViewModel)

                @ViewBuilder
                var destinationView: some View {
                    switch self {
                    case .history(let viewModel):
                        DormHistoryView(viewModel: viewModel)
                    }
                }
            }
        }

        enum SchoolCalendarListRoute: Hashable, RouteNode {
            case detail(SchoolCalendar)

            @ViewBuilder
            var destinationView: some View {
                switch self {
                case .detail(let calendar):
                    SchoolCalendarView(schoolCalendar: calendar)
                }
            }
        }

    }

    // MARK: - ProfileRoute

    enum ProfileRoute: Hashable, RouteNode {
        case profileDetail
        case networkSettings
        case backgroundTaskSettings
        case notificationSettings
        case widgetSettings
        case about(AboutRoute? = nil)
        case feedback
        case userAgreement

        @ViewBuilder
        var destinationView: some View {
            switch self {
            case .profileDetail:
                ProfileDetailView()
            case .networkSettings:
                NetworkSettingsView()
            case .backgroundTaskSettings:
                #if os(iOS)
                BackgroundTaskSettingsView()
                #else
                EmptyView()
                #endif
            case .notificationSettings:
                NotificationSettingsView()
            case .widgetSettings:
                WidgetSettingsView()
            case .about(nil):
                AboutView()
            case .about(let route?):
                route.destinationView
            case .feedback:
                FeedbackView()
            case .userAgreement:
                UserAgreementView(isButtonPresented: false)
            }
        }

        enum AboutRoute: Hashable, RouteNode {
            case openSourceLicenses(OpenSourceLicensesRoute? = nil)

            @ViewBuilder
            var destinationView: some View {
                switch self {
                case .openSourceLicenses(nil):
                    OpenSourceLicensesView()
                case .openSourceLicenses(let route?):
                    route.destinationView
                }
            }

            enum OpenSourceLicensesRoute: Hashable, RouteNode {
                case detail(OpenSourceLicense)

                @ViewBuilder
                var destinationView: some View {
                    switch self {
                    case .detail(let license):
                        OpenSourceLicenseDetailView(license: license)
                    }
                }
            }
        }
    }
}
