//
//  AppRoute.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/4/12.
//

import CSUSTKit
import Foundation
import SwiftUI

enum AppRoute: Hashable {
    case overview(OverviewRoute)
    case features(FeaturesRoute)
    case profile(ProfileRoute)

    var trackSegment: String {
        switch self {
        case .overview(let route):
            return route.trackSegment
        case .features(let route):
            return route.trackSegment
        case .profile(let route):
            return route.trackSegment
        }
    }

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

    enum OverviewRoute: Hashable {
        case announcementList(viewModel: AnnouncementListViewModel)
        case overviewSettings

        var trackSegment: String {
            switch self {
            case .announcementList:
                return "AnnouncementList"
            case .overviewSettings:
                return "OverviewSettings"
            }
        }

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

    enum FeaturesRoute: Hashable {
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

        var trackSegment: String {
            switch self {
            case .courseSchedule(let route):
                return route?.trackSegment ?? "CourseSchedule"
            case .gradeQuery(let route):
                return route?.trackSegment ?? "GradeQuery"
            case .examSchedule:
                return "ExamSchedule"
            case .gradeAnalysis:
                return "GradeAnalysis"
            case .courses(let route):
                return route?.trackSegment ?? "Courses"
            case .assignments:
                return "Assignments"
            case .chaoxingAssignments:
                return "ChaoxingAssignments"
            case .dormList(let route):
                return route?.trackSegment ?? "DormList"
            case .availableClassroom:
                return "AvailableClassroom"
            case .campusMap:
                return "CampusMap"
            case .schoolCalendarList(let route):
                return route?.trackSegment ?? "SchoolCalendarList"
            case .electricityRecharge:
                return "ElectricityRecharge"
            case .webVPNConverter:
                return "WebVPNConverter"
            case .eval:
                return "Eval"
            case .physicsExperimentSchedule:
                return "PhysicsExperimentSchedule"
            case .physicsExperimentGrade:
                return "PhysicsExperimentGrade"
            case .cetQuery:
                return "CET"
            case .mandarinQuery:
                return "Mandarin"
            case .ncreQuery:
                return "NCRE"
            }
        }

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

        // MARK: - CourseScheduleRoute

        enum CourseScheduleRoute: Hashable {
            case settings
            case edit(CustomCourseScheduleGRDB)
            case courseDetail(CustomCourseGRDB)

            var trackSegment: String {
                switch self {
                case .settings:
                    return "CourseScheduleSettings"
                case .edit:
                    return "CourseScheduleEdit"
                case .courseDetail:
                    return "CourseScheduleCourseDetail"
                }
            }

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

        enum GradeQueryRoute: Hashable {
            case detail(EduHelper.CourseGrade)

            var trackSegment: String {
                switch self {
                case .detail:
                    return "GradeDetail"
                }
            }

            @ViewBuilder
            var destinationView: some View {
                switch self {
                case .detail(let courseGrade):
                    GradeDetailView(courseGrade: courseGrade)
                }
            }
        }

        enum CoursesRoute: Hashable {
            case detail(MoocHelper.Course)

            var trackSegment: String {
                switch self {
                case .detail:
                    return "CourseDetail"
                }
            }

            @ViewBuilder
            var destinationView: some View {
                switch self {
                case .detail(let course):
                    CourseDetailView(course: course)
                }
            }
        }

        enum DormListRoute: Hashable {
            case detail(DormGRDB, DormDetailRoute? = nil)

            var trackSegment: String {
                switch self {
                case .detail(_, let route):
                    return route?.trackSegment ?? "DormDetail"
                }
            }

            @ViewBuilder
            var destinationView: some View {
                switch self {
                case .detail(let dorm, nil):
                    DormDetailView(dorm: dorm)
                case .detail(_, let route?):
                    route.destinationView
                }
            }

            enum DormDetailRoute: Hashable {
                case history(DormDetailViewModel)

                var trackSegment: String {
                    switch self {
                    case .history:
                        return "DormHistory"
                    }
                }

                @ViewBuilder
                var destinationView: some View {
                    switch self {
                    case .history(let viewModel):
                        DormHistoryView(viewModel: viewModel)
                    }
                }
            }
        }

        enum SchoolCalendarListRoute: Hashable {
            case detail(SchoolCalendar)

            var trackSegment: String {
                switch self {
                case .detail:
                    return "SchoolCalendar"
                }
            }

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

    enum ProfileRoute: Hashable {
        case profileDetail
        case networkSettings
        case backgroundTaskSettings
        case notificationSettings
        case widgetSettings
        case about(AboutRoute? = nil)
        case feedback
        case userAgreement

        var trackSegment: String {
            switch self {
            case .profileDetail:
                return "ProfileDetail"
            case .networkSettings:
                return "NetworkSettings"
            case .backgroundTaskSettings:
                return "BackgroundTaskSettings"
            case .notificationSettings:
                return "NotificationSettings"
            case .widgetSettings:
                return "WidgetSettings"
            case .about(let route):
                return route?.trackSegment ?? "About"
            case .feedback:
                return "Feedback"
            case .userAgreement:
                return "UserAgreement"
            }
        }

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

        enum AboutRoute: Hashable {
            case openSourceLicenses(OpenSourceLicensesRoute? = nil)

            var trackSegment: String {
                switch self {
                case .openSourceLicenses(let route):
                    return route?.trackSegment ?? "OpenSourceLicenses"
                }
            }

            @ViewBuilder
            var destinationView: some View {
                switch self {
                case .openSourceLicenses(nil):
                    OpenSourceLicensesView()
                case .openSourceLicenses(let route?):
                    route.destinationView
                }
            }

            enum OpenSourceLicensesRoute: Hashable {
                case detail(OpenSourceLicense)

                var trackSegment: String {
                    switch self {
                    case .detail:
                        return "OpenSourceLicenseDetail"
                    }
                }

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

enum AppTabItem: Hashable {
    case overview
    case schedule
    case features
    case profile
    case feature(FeatureTabID)

    var trackSegment: String {
        switch self {
        case .overview:
            return "Overview"
        case .schedule:
            return "Schedule"
        case .features:
            return "Features"
        case .profile:
            return "Profile"
        case .feature(let feature):
            return feature.trackSegment
        }
    }
}
