//
//  Recents.swift
//  GoSnow
//
//  Created by federico Liu on 2024/8/8.
//

import SwiftUI

struct Recents: View {
    
    @EnvironmentObject private var sessionsStore: SessionsStore
    @State private var maxSpeedKmh: Double = 0
    @State private var isStopping = false
    @StateObject private var vm: RecordingViewModel

    let onSummary: (SessionSummary) -> Void
    let onWillStop: () -> Void

    // 由父视图传入 VM
    // ✅ 便捷 init：内部自建 VM，兼容不传 vm 的调用
    init(
        onWillStop: @escaping () -> Void = {},
        onSummary:  @escaping (SessionSummary) -> Void = { _ in }
    ) {
        self.onWillStop = onWillStop
        self.onSummary  = onSummary
        _vm = StateObject(
            wrappedValue: RecordingViewModel(
                recorder: BasicSessionRecorder(
                    location: CoreLocationService(),
                    metrics: BasicMetricsComputer()
                ),
                store: JSONLocalStore()
            )
        )
    }


    private var isRecording: Bool { vm.state == .recording }
    private var isPaused:    Bool { vm.state == .paused }

    var body: some View {
        VStack(spacing: 20) {
            // 控制区
            HStack(spacing: 12) {
                Button {
                    switch vm.state {
                    case .idle:
                        Task { await vm.start(resortId: nil) }
                        maxSpeedKmh = 0
                    case .recording:
                        vm.pause()
                    case .paused:
                        vm.resume()
                    }
                } label: {
                    Label(buttonTitle, systemImage: buttonIcon)
                }
                .buttonStyle(.borderedProminent)
                .tint(vm.state == .recording ? .orange : .green)
                .controlSize(.large)
                .buttonBorderShape(.capsule)
                .disabled(isStopping)

                Button {
                    guard !isStopping else { return }
                    isStopping = true
                    onWillStop()
                    Task.detached {
                        let result = await vm.stopSaveAndSummarize()
                        await MainActor.run {
                            if let (summary, session) = result {
                                sessionsStore.ingest(session)
                                onSummary(summary)
                            }
                            isStopping = false
                        }
                    }
                } label: {
                    Label("结束", systemImage: "stop.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
                .buttonBorderShape(.capsule)
                .disabled(!(isRecording || isPaused) || isStopping)
            }

            // 指标展示
            HStack(spacing: 28) {
                metricBig(
                    value: String(format: "%.1f", Double(vm.durationSec) / 60.0)
                        .replacingOccurrences(of: ".0", with: ""),
                    title: "滑行时间（分钟）"
                )
                .monospacedDigit()

                metricBig(value: String(format: "%.1f", maxSpeedKmh), title: "最高速度 (km/h)")
                metricBig(value: String(format: "%.1f", vm.distanceKm), title: "滑行里程 (km)")
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 16)
        .onChange(of: vm.speedKmh) { _, v in
            if v > maxSpeedKmh { maxSpeedKmh = v }
        }
    }

    private var buttonTitle: String {
        switch vm.state {
        case .idle:      return "开始"
        case .recording: return "暂停"
        case .paused:    return "恢复"
        }
    }
    private var buttonIcon: String {
        switch vm.state {
        case .idle:      return "play.fill"
        case .recording: return "pause.fill"
        case .paused:    return "play.fill"
        }
    }

    private func metricBig(value: String, title: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 48, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}














/*
 
 import SwiftUI
 import MijickTimer

 struct Recents: View {
     @StateObject private var motionManager = CoreMotionManager()
     private let dataStorageManager = DataStorageManager()

     @State private var isRunning: Bool = false
     @State private var totalDistance: Double = 0.0
     

     // 计时器相关
     @State private var currentTime: MTime = .zero
     @State private var isTimerRunning: Bool = false
     @State private var timerProgress: Double = 0.0

     var body: some View {
         VStack {
             // 控制按钮
             HStack {
                 Button {
                     isRunning.toggle()
                     if isRunning {
                         startTimer()
                         motionManager.startTracking()
                     } else {
                         stopTimer()
                         motionManager.stopTracking()
                     }
                 } label: {
                     Label(isRunning ? "暂停" : "开始", systemImage: isRunning ? "stop.fill" : "play.fill")
                 }
                 .buttonStyle(.borderedProminent)
                 .tint(.green)
                 .controlSize(.large)
                 .buttonBorderShape(.capsule)

                 Button(action: {
                     endRun()
                 }) {
                     Label("结束", systemImage: "stop.fill")
                 }
                 .buttonStyle(.borderedProminent)
                 .tint(.red)
                 .controlSize(.large)
                 .buttonBorderShape(.capsule)
                 .disabled(!isRunning) // 只有在跑步时才能点击“结束”
             }

             // 数据显示
             HStack(spacing: 28) {
                 VStack(spacing: 5) {
                     Text("\(currentTime.minutes)") // 直接显示分钟数，不格式化为两位数
                         .minimumScaleFactor(0.5)
                         .lineLimit(1)
                         .font(.system(size: 48, weight: .semibold))
                     Text("滑行时间（分钟）")
                         .font(.caption)
                         .foregroundColor(.gray)
                 }

                 VStack(spacing: 5) {
                     Text(String(format: "%.1f", motionManager.maxSpeed * 3.6)) // 米/秒转千米/小时
                         .font(.system(size: 48, weight: .semibold))
                         .minimumScaleFactor(0.5)
                         .lineLimit(1)
                     Text("最高速度 (km/h)")
                         .font(.caption)
                         .foregroundColor(.gray)
                 }

                 VStack(spacing: 5) {
                     let distanceInKilometers = motionManager.distanceDuringCurrentRun / 1000.0 // 转换为千米
                     Text(String(format: "%.1f", distanceInKilometers)) // 显示1位小数的千米数
                         .font(.system(size: 48, weight: .semibold))
                         .minimumScaleFactor(0.5)
                         .lineLimit(1)
                     Text("滑行里程 (km)") // 单位改为 km
                         .font(.caption)
                         .foregroundColor(.gray)
                 }
             }
             Spacer()
         }
         .onAppear {
             let savedData = dataStorageManager.getTotalRunData()
             totalDistance = savedData.distance
         }
         .onReceive(motionManager.$distanceDuringCurrentRun) { newDistance in
             totalDistance = newDistance
         }
     }

     private func timeInSeconds(from mTime: MTime) -> TimeInterval {
         return TimeInterval(mTime.hours * 3600 + mTime.minutes * 60 + mTime.seconds)
     }

     private func startTimer() {
         let startTime = MTime(hours: 0, minutes: 0, seconds: 0)
         let endTime = MTime(hours: 0, minutes: 0, seconds: 1)

         do {
             try MTimer.publish(every: 1, currentTime: $currentTime)
                 .bindTimerStatus(isTimerRunning: $isTimerRunning)
                 .bindTimerProgress(progress: $timerProgress)
                 .start(from: startTime, to: endTime)
         } catch {
             print("Failed to start timer: \(error)")
         }

         isTimerRunning = true
     }

     private func stopTimer() {
         MTimer.stop()
         isTimerRunning = false
     }

     private func endRun() {
         stopTimer()
         motionManager.stopTracking()

         let distanceInMeters = motionManager.distanceDuringCurrentRun
         let distanceInKilometers = distanceInMeters / 1000.0
         let timeInSeconds = timeInSeconds(from: currentTime)

         do {
             try dataStorageManager.saveRunData(time: timeInSeconds, distance: distanceInKilometers)
             print("运动数据保存成功")
         } catch {
             print("保存数据失败：\(error)")
         }

         resetRunData()
         isRunning = false // 更新按钮状态
     }

     private func resetRunData() {
         currentTime = .zero
         motionManager.reset()
     }
 }

 #Preview {
     Recents()
 }
 
 
 */
