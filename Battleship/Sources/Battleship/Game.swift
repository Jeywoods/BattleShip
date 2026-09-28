/// Finite state machine of a game session.
enum GameState {
    case setup                                  // announce the game
    case placingShips                           // both fleets are arranged
    case turnStart                              // attacker takes aim
    case aiming                                 // strategy picks a target
    case firing(Coordinate)                     // shot is fired at the enemy board
    case resolving(Coordinate, ShotResult)      // outcome is applied
    case turnEnd(keepsTurn: Bool)               // hit => shoot again, miss => pass turn
    case gameOver(winner: Player)
}

final class Game {
    let players: [Player]
    private let rng: RandomSource
    private(set) var state: GameState = .setup
    private var currentIndex = 0
    private var turnCount = 0

    private var attacker: Player { players[currentIndex] }
    private var defender: Player { players[(currentIndex + 1) % players.count] }

    init(players: [Player], rng: RandomSource) {
        precondition(players.count == 2, "Battleship is a two-player game")
        self.players = players
        self.rng = rng
    }

    /// Runs the FSM until somebody wins.
    func run() {
        while true {
            if case .gameOver(let winner) = state {
                printSummary(winner: winner)
                return
            }
            step()
        }
    }

    /// One FSM transition.
    private func step() {
        switch state {
        case .setup:
            log("Started a new game of Battleship")
            log("======")
            state = .placingShips

        case .placingShips:
            for p in players {
                p.board.placeFleetRandomly(using: rng)
                log("\(p.name) arranges the fleet (\(p.board.ships.count) ships), strategy: \(p.strategy.title)")
            }
            log("======")
            state = .turnStart

        case .turnStart:
            turnCount += 1
            log("\(attacker.name) takes aim")
            state = .aiming

        case .aiming:
            let target = attacker.strategy.chooseTarget(against: defender.board, rng: rng)
            state = .firing(target)

        case .firing(let target):
            log("\(attacker.name) fires at \(target)")
            let result = defender.board.receiveShot(at: target)
            attacker.recordShot(result)
            state = .resolving(target, result)

        case .resolving(_, let result):
            switch result {
            case .miss:
                log("Miss")
                state = .turnEnd(keepsTurn: false)
            case .hit(let ship):
                log("Hit! \(defender.name)'s \(ship.name) is damaged")
                state = .turnEnd(keepsTurn: true)
            case .sunk(let ship, let auto):
                log("Hit! \(defender.name)'s \(ship.name) is sunk (\(auto.count) surrounding cells revealed)")
                if defender.board.allSunk {
                    state = .gameOver(winner: attacker)
                } else {
                    state = .turnEnd(keepsTurn: true)
                }
            case .repeated:
                log("Already shot there")
                state = .turnEnd(keepsTurn: false)
            }

        case .turnEnd(let keepsTurn):
            if keepsTurn {
                log("\(attacker.name) shoots again")
            } else {
                currentIndex = (currentIndex + 1) % players.count
            }
            state = .turnStart

        case .gameOver:
            break
        }
    }

    // MARK: Output

    private func log(_ message: String) { print(message) }

    private func printSummary(winner: Player) {
        log("======")
        log("\(winner.name) wins after \(turnCount) turns!")
        for p in players {
            let accuracy = p.shotsFired == 0 ? 0 : p.hitsLanded * 100 / p.shotsFired
            log("\(p.name): shots \(p.shotsFired), hits \(p.hitsLanded) (\(accuracy)%), ships sunk \(p.shipsSunk)")
        }
        log("")
        log("Final boards (S ship, X hit, # sunk, o miss)")
        let left = players[0].board.render(revealShips: true)
        let right = players[1].board.render(revealShips: true)
        let pad = String(repeating: " ", count: max(0, 24 - players[0].name.count))
        log(players[0].name + pad + "    " + players[1].name)
        for (l, r) in zip(left, right) { log(l + "    " + r) }
    }
}
