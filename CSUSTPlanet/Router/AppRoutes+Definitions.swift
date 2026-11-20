//
//  AppRoutes+Definitions.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/11/19.
//

import SwiftUI

extension AppRoutes {
    // MARK: - Overview

    static let overview = AppPage("/overview", tab: .overview) {
        OverviewView()
    }
    static let announcementList = AppPage("/overview/announcements", tab: .overview) {
        AnnouncementListView()
    }
    static let overviewSettings = AppPage("/overview/settings", tab: .overview) {
        OverviewSettingsView()
    }

    // MARK: - Schedule

    static let schedule = AppPage("/schedule", tab: .schedule) {
        ScheduleView()
    }

    // MARK: - Features

    static let features = AppPage("/features", tab: .features) {
        FeaturesView()
    }
    static let courseSchedule = AppPage("/features/course-schedule", tab: .feature(.courseSchedule)) {
        CourseScheduleView()
    }
    static let courseScheduleSettings = AppPage("/features/course-schedule/settings", tab: .feature(.courseSchedule)) {
        CourseScheduleSettingsView()
    }
    static let courseScheduleEdit = AppPage<CustomScheduleEditParams>("/features/course-schedule/edit", tab: .feature(.courseSchedule)) {
        CourseScheduleManageView(params: $0)
    }
    static let customCourseDetail = AppPage<CustomCourseDetailParams>("/features/course-schedule/detail", tab: .feature(.courseSchedule)) {
        CourseScheduleCourseDetailView(params: $0)
    }
    static let gradeQuery = AppPage("/features/grade-query", tab: .feature(.gradeQuery)) {
        GradeQueryView()
    }
    static let gradeDetail = AppPage<GradeDetailParams>("/features/grade-query/detail", tab: .feature(.gradeQuery)) {
        GradeDetailView(params: $0)
    }
    static let examSchedule = AppPage("/features/exam-schedule", tab: .feature(.examSchedule)) {
        ExamScheduleView()
    }
    static let gradeAnalysis = AppPage("/features/grade-analysis", tab: .feature(.gradeAnalysis)) {
        GradeAnalysisView()
    }
    static let courses = AppPage("/features/courses", tab: .feature(.courses)) {
        CoursesView()
    }
    static let moocCourseDetail = AppPage<MoocCourseDetailParams>("/features/courses/detail", tab: .feature(.courses)) {
        CourseDetailView(params: $0)
    }
    static let assignments = AppPage("/features/assignments", tab: .feature(.assignments)) {
        AssignmentsView()
    }
    static let chaoxingAssignments = AppPage("/features/chaoxing-assignments", tab: .feature(.chaoxingAssignments)) {
        ChaoxingAssignmentsView()
    }
    static let dormList = AppPage("/features/dorm-list", tab: .feature(.electricityQuery)) {
        DormListView()
    }
    static let dormDetail = AppPage<DormParams>("/features/dorm-list/detail", tab: .feature(.electricityQuery)) {
        DormDetailView(params: $0)
    }
    static let dormHistory = AppPage<DormParams>("/features/dorm-list/detail/history", tab: .feature(.electricityQuery)) {
        DormHistoryView(params: $0)
    }
    static let availableClassroom = AppPage("/features/available-classroom", tab: .feature(.availableClassroom)) {
        AvailableClassroomView()
    }
    static let campusMap = AppPage("/features/campus-map", tab: .feature(.campusMap)) {
        CampusMapView()
    }
    static let schoolCalendarList = AppPage("/features/school-calendar", tab: .feature(.schoolCalendar)) {
        SchoolCalendarListView()
    }
    static let schoolCalendarDetail = AppPage<SchoolCalendarParams>("/features/school-calendar/detail", tab: .feature(.schoolCalendar)) {
        SchoolCalendarView(params: $0)
    }
    static let electricityRecharge = AppPage("/features/electricity-recharge", tab: .feature(.electricityRecharge)) {
        ElectricityRechargeView()
    }
    static let webVPNConverter = AppPage("/features/web-vpn-converter", tab: .feature(.webVPNConverter)) {
        WebVPNConverterView()
    }
    static let eval = AppPage("/features/eval", tab: .feature(.eval)) {
        EvalView()
    }
    static let physicsExperimentSchedule = AppPage("/features/physics-experiment-schedule", tab: .feature(.physicsExperimentSchedule)) {
        PhysicsExperimentScheduleView()
    }
    static let physicsExperimentGrade = AppPage("/features/physics-experiment-grade", tab: .feature(.physicsExperimentGrade)) {
        PhysicsExperimentGradeView()
    }
    static let cetQuery = AppPage("/features/cet-query", tab: .feature(.cet)) {
        CETQueryView()
    }
    static let mandarinQuery = AppPage("/features/mandarin-query", tab: .feature(.mandarin)) {
        MandarinQueryView()
    }
    static let ncreQuery = AppPage("/features/ncre-query", tab: .feature(.ncre)) {
        NCREQueryView()
    }

    // MARK: - Profiles

    static let profile = AppPage("/profile", tab: .profile) {
        ProfileView()
    }
    static let profileDetail = AppPage("/profile/detail", tab: .profile) {
        ProfileDetailView()
    }
    static let networkSettings = AppPage("/profile/network-settings", tab: .profile) {
        NetworkSettingsView()
    }
    static let notificationSettings = AppPage("/profile/notification-settings", tab: .profile) {
        NotificationSettingsView()
    }
    static let scheduleNotificationSettings = AppPage("/profile/notification-settings/schedule", tab: .profile) {
        ScheduleNotificationSettingsView()
    }
    static let widgetSettings = AppPage("/profile/widget-settings", tab: .profile) {
        WidgetSettingsView()
    }
    static let about = AppPage("/profile/about", tab: .profile) {
        AboutView()
    }
    static let openSourceLicenses = AppPage("/profile/about/licenses", tab: .profile) {
        OpenSourceLicensesView()
    }
    static let licenseDetail = AppPage<LicenseDetailParams>("/profile/about/licenses/detail", tab: .profile) {
        OpenSourceLicenseDetailView(params: $0)
    }
    static let feedback = AppPage("/profile/feedback", tab: .profile) {
        FeedbackView()
    }
    static let userAgreement = AppPage("/profile/user-agreement", tab: .profile) {
        UserAgreementView(isButtonPresented: false)
    }
    #if os(iOS)
    static let backgroundTaskSettings = AppPage("/profile/background-task-settings", tab: .profile) {
        BackgroundTaskSettingsView()
    }
    #endif

    static var registrations: [Registration] {
        let pages = [
            overview.registration,
            announcementList.registration,
            overviewSettings.registration,

            schedule.registration,

            features.registration,
            courseSchedule.registration,
            courseScheduleSettings.registration,
            courseScheduleEdit.registration,
            customCourseDetail.registration,
            gradeQuery.registration,
            gradeDetail.registration,
            examSchedule.registration,
            gradeAnalysis.registration,
            courses.registration,
            moocCourseDetail.registration,
            assignments.registration,
            chaoxingAssignments.registration,
            dormList.registration,
            dormDetail.registration,
            dormHistory.registration,
            availableClassroom.registration,
            campusMap.registration,
            schoolCalendarList.registration,
            schoolCalendarDetail.registration,
            electricityRecharge.registration,
            webVPNConverter.registration,
            eval.registration,
            physicsExperimentSchedule.registration,
            physicsExperimentGrade.registration,
            cetQuery.registration,
            mandarinQuery.registration,
            ncreQuery.registration,

            profile.registration,
            profileDetail.registration,
            networkSettings.registration,
            notificationSettings.registration,
            scheduleNotificationSettings.registration,
            widgetSettings.registration,
            about.registration,
            openSourceLicenses.registration,
            licenseDetail.registration,
            feedback.registration,
            userAgreement.registration,
        ]

        #if os(iOS)
        return pages + [backgroundTaskSettings.registration]
        #else
        return pages
        #endif
    }
}
