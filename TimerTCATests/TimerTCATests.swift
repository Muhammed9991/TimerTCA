import XCTest
@testable import TimerTCA
import ComposableArchitecture

@MainActor
final class TimerTCATests: XCTestCase {

    func testToggleTimerButtonTappedGoingOverAnHour() async {
        let mainQueue = DispatchQueue.test
        let store = TestStore(initialState: Timers.State(
            hoursElapsed: 1,
            minutesElapsed: 59,
            secondsElapsed: 59
        )) {
            Timers()
        } withDependencies: {
            $0.mainQueue = mainQueue.eraseToAnyScheduler()
        }
        
        await store.send(.toggleTimerButtonTapped) {
            $0.isTimerActive = true
        }
        
        await mainQueue.advance(by: .seconds(1))
        
        await store.receive(.timerTicked) {
            $0.hoursElapsed = 2
            $0.minutesElapsed = 0
            $0.secondsElapsed = 0
        }
        
        await store.send(.onDisappear)
        
    }
    
    func testToggleTimerButtonTappedGoingOverAMinute() async {
        let mainQueue = DispatchQueue.test
        let store = TestStore(initialState: Timers.State(
            hoursElapsed: 0,
            minutesElapsed: 0,
            secondsElapsed: 59
        )) {
            Timers()
        } withDependencies: {
            $0.mainQueue = mainQueue.eraseToAnyScheduler()
        }
        
        await store.send(.toggleTimerButtonTapped) {
            $0.isTimerActive = true
        }
        
        await mainQueue.advance(by: .seconds(1))
        
        await store.receive(.timerTicked) {
            $0.hoursElapsed = 0
            $0.minutesElapsed = 1
            $0.secondsElapsed = 0
        }
        
        await store.send(.onDisappear)
        
    }
    
    func testToggleTimerButtonTappedGoingOver59Minute() async {
        let mainQueue = DispatchQueue.test
        let store = TestStore(initialState: Timers.State(
            hoursElapsed: 0,
            minutesElapsed: 59,
            secondsElapsed: 59
        )) {
            Timers()
        } withDependencies: {
            $0.mainQueue = mainQueue.eraseToAnyScheduler()
        }
        
        await store.send(.toggleTimerButtonTapped) {
            $0.isTimerActive = true
        }
        
        await mainQueue.advance(by: .seconds(1))
        
        await store.receive(.timerTicked) {
            $0.hoursElapsed = 1
            $0.minutesElapsed = 0
            $0.secondsElapsed = 0
        }
        
        await mainQueue.advance(by: .seconds(1))
        
        await store.receive(.timerTicked) {
            $0.hoursElapsed = 1
            $0.minutesElapsed = 0
            $0.secondsElapsed = 1
        }
        
        await store.send(.onDisappear)
        
    }

}
