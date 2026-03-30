//
//  DormOverviewView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import Charts
import SwiftUI

struct DormOverviewView: View {
    @State private var viewModel = DormOverviewViewModel()
    @Namespace var namespace
    @State private var refreshID = Int(CFAbsoluteTimeGetCurrent() * 1000)

    var body: some View {
        let destination =
            if let dorm = viewModel.primaryDorm {
                AnyView(DormDetailView(dorm: dorm))
            } else {
                AnyView(DormListView())
            }

        Group {
            #if os(macOS)
            TrackLink(destination: destination) {
                CustomGroupBox {
                    cardContent
                }
            }
            #elseif os(iOS)
            if #available(iOS 18.0, macOS 15.0, *) {
                TrackLink(
                    destination:
                        destination
                        .navigationTransition(.zoom(sourceID: "dormOverview", in: namespace))
                        .onDisappear { refreshID = Int(CFAbsoluteTimeGetCurrent() * 1000) }
                ) {
                    CustomGroupBox {
                        cardContent.matchedTransitionSource(id: "dormOverview", in: namespace)
                    }
                }
                .id(refreshID)
            } else {
                TrackLink(destination: destination) {
                    CustomGroupBox {
                        cardContent
                    }
                }
            }
            #endif
        }
        .buttonStyle(.plain)
        .onAppear(perform: viewModel.onAppear)
    }

    @ViewBuilder
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text("宿舍电量")
                    .font(.title3)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)

                if let dorm = viewModel.primaryDorm {
                    Text(dorm.room)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                } else {
                    Text("未绑定")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if viewModel.primaryDorm != nil {
                    if let lastUpdated = viewModel.lastFetchDate {
                        LastUpdatedDateView(
                            lastUpdated: lastUpdated,
                            font: .footnote,
                            foregroundStyle: .secondary
                        )
                        .contentTransition(.numericText())
                    }

                    Button(asyncAction: viewModel.queryElectricity) {
                        Image(systemName: "arrow.clockwise.circle")
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isQueryingElectricity)
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Spacer()
                    if let dorm = viewModel.primaryDorm, let lastFetchElectricity = dorm.lastFetchElectricity {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(String(format: "%.2f", lastFetchElectricity))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(ColorUtil.electricityColor(electricity: lastFetchElectricity))
                                .minimumScaleFactor(0.7)
                                .contentTransition(.numericText())

                            Text("kWh")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                        }

                        if let info = viewModel.electricityExhaustionInfo {
                            Text(info)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    } else {
                        Text("添加宿舍")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        Text("查看宿舍电量")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                dormTrendChart
                    .frame(minWidth: 120, maxWidth: .infinity, maxHeight: 120, alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var dormTrendChart: some View {
        if !viewModel.chartRecords.isEmpty {
            Chart(viewModel.chartRecords) { record in
                AreaMark(
                    x: .value("日期", record.date),
                    yStart: .value("基线", viewModel.chartYDomain.lowerBound),
                    yEnd: .value("电量", record.electricity)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.2), .blue.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("日期", record.date),
                    y: .value("电量", record.electricity)
                )
                .foregroundStyle(.blue.opacity(0.95))
                .interpolationMethod(.linear)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                if viewModel.chartRecords.count < 10 {
                    PointMark(
                        x: .value("日期", record.date),
                        y: .value("电量", record.electricity)
                    )
                    .foregroundStyle(.blue)
                }
            }
            .chartYScale(domain: viewModel.chartYDomain)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .chartPlotStyle { plotArea in
                plotArea.background(.clear)
            }
            .transaction { transaction in
                transaction.animation = nil
            }
            .allowsHitTesting(false)
            .padding(.vertical, 4)
        } else {
            Color.clear
        }
    }
}
