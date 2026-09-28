/// Player class: owns a board and a shooting strategy, and keeps statistics.
final class Player {
    let name: String
    let strategy: ShootingStrategy
    let board = Board()
    private(set) var shotsFired = 0
    private(set) var hitsLanded = 0
    private(set) var shipsSunk = 0

    init(name: String, strategy: ShootingStrategy) {
        self.name = name
        self.strategy = strategy
    }

    func recordShot(_ result: ShotResult) {
        shotsFired += 1
        switch result {
        case .hit:  hitsLanded += 1
        case .sunk: hitsLanded += 1; shipsSunk += 1
        default: break
        }
    }
}
