import ComposableArchitecture
import SwiftUI

@Reducer
struct Timers {
    struct State: Equatable {
        var isTimerActive = false
        var hoursElapsed = 0
        var minutesElapsed = 0
        var secondsElapsed = 0
    }
    
    enum Action {
        case onDisappear
        case timerTicked
        case toggleTimerButtonTapped
        case onAppear
    }
    
    @Dependency(\.mainQueue) var mainQueue
    private enum CancelID { case timer }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onDisappear:
                return .cancel(id: CancelID.timer)
                
            case .timerTicked:
                state.secondsElapsed += 1
                if state.secondsElapsed == 60 {
                    state.secondsElapsed = 0
                    state.minutesElapsed += 1
                    
                    if state.minutesElapsed == 60 {
                        state.minutesElapsed = 0
                        state.hoursElapsed += 1
                    }
                }
                return .none
                
            case .toggleTimerButtonTapped:
                state.isTimerActive.toggle()
                return .run { [isTimerActive = state.isTimerActive] send in
                    guard isTimerActive else { return }
                    for await _ in self.mainQueue.timer(interval: .seconds(1)) {
                        await send(.timerTicked, animation: .interpolatingSpring(stiffness: 3000, damping: 40))
                    }
                }
                .cancellable(id: CancelID.timer, cancelInFlight: true)
            case .onAppear:
                state.hoursElapsed = 1
                state.minutesElapsed = 59
                state.secondsElapsed = 59
                return .none
            }
        }
    }
}

// MARK: - Feature view

struct TimersView: View {
    @State var store = Store(initialState: Timers.State()) {
        Timers()
    }
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack{
                
                Text("\(viewStore.hoursElapsed) hrs \(viewStore.minutesElapsed) mins \(viewStore.secondsElapsed) secs")
                    .font(.title)
                    .padding()
                
                Form {
                    ZStack {
                        Circle()
                            .fill(
                                AngularGradient(
                                    gradient: Gradient(
                                        colors: [
                                            .blue.opacity(0.3),
                                            .blue,
                                            .blue,
                                            .green,
                                            .green,
                                            .yellow,
                                            .yellow,
                                            .red,
                                            .red,
                                            .purple,
                                            .purple,
                                            .purple.opacity(0.3),
                                        ]
                                    ),
                                    center: .center
                                )
                            )
                            .rotationEffect(.degrees(-90))
                        GeometryReader { proxy in
                            Path { path in
                                path.move(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2))
                                path.addLine(to: CGPoint(x: proxy.size.width / 2, y: 0))
                            }
                            .stroke(.primary, lineWidth: 3)
                            .rotationEffect(.degrees(Double(viewStore.secondsElapsed) * 360 / 60))
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: 280)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    
                    Button {
                        viewStore.send(.toggleTimerButtonTapped)
                    } label: {
                        Text(viewStore.isTimerActive ? "Stop" : "Start")
                            .padding(8)
                    }
                    .frame(maxWidth: .infinity)
                    .tint(viewStore.isTimerActive ? Color.red : .accentColor)
                    .buttonStyle(.borderedProminent)
                }
                .navigationTitle("Timers")
                .onDisappear {
                    viewStore.send(.onDisappear)
                }
            }
            .task { viewStore.send(.onAppear) }
        }
    }
}

// MARK: - SwiftUI previews
#Preview {
    NavigationView {
        TimersView(
            store: Store(initialState: Timers.State()) {
                Timers()
            }
        )
    }
}
