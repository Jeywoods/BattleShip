enum ShotMark { case miss, hit, sunk }

enum ShotResult {
    case miss
    case hit(Ship)
    case sunk(Ship, autoMissed: [Coordinate])
    case repeated
}

/// Board class: owns the ships, validates placement, resolves incoming shots.
final class Board {
    static let size = 10

    private(set) var ships: [Ship] = []
    /// Public information: what the enemy already knows about this board.
    private(set) var marks: [Coordinate: ShotMark] = [:]
    private var occupied: [Coordinate: Ship] = [:]

    var allSunk: Bool { !ships.isEmpty && ships.allSatisfy { $0.isSunk } }

    /// Every cell in row-major order that has not been shot yet.
    var unshotCells: [Coordinate] {
        var result: [Coordinate] = []
        for r in 0..<Board.size {
            for c in 0..<Board.size {
                let coord = Coordinate(row: r, col: c)
                if marks[coord] == nil { result.append(coord) }
            }
        }
        return result
    }

    // MARK: Placement

    /// Ships may not touch each other, even diagonally (Russian rules).
    private func canPlace(_ cells: [Coordinate]) -> Bool {
        for c in cells {
            guard c.isInside else { return false }
            if occupied[c] != nil { return false }
            if c.neighbors8.contains(where: { occupied[$0] != nil }) { return false }
        }
        return true
    }

    func placeFleetRandomly(using rng: RandomSource) {
        while true {
            ships = []; occupied = [:]; marks = [:]
            var ok = true
            // Longest ships first: they are hardest to fit.
            for ship in Fleet.make().sorted(by: { $0.length > $1.length }) {
                var placed = false
                for _ in 0..<500 {
                    let horizontal = rng.bool()
                    let start = Coordinate(row: rng.int(in: 0..<Board.size),
                                           col: rng.int(in: 0..<Board.size))
                    let cells = (0..<ship.length).map {
                        Coordinate(row: start.row + (horizontal ? 0 : $0),
                                   col: start.col + (horizontal ? $0 : 0))
                    }
                    if canPlace(cells) {
                        ship.place(at: cells)
                        cells.forEach { occupied[$0] = ship }
                        ships.append(ship)
                        placed = true
                        break
                    }
                }
                if !placed { ok = false; break }
            }
            if ok { return }
        }
    }

    // MARK: Shooting

    func receiveShot(at c: Coordinate) -> ShotResult {
        if marks[c] != nil { return .repeated }
        guard let ship = occupied[c] else {
            marks[c] = .miss
            return .miss
        }
        ship.registerHit(at: c)
        guard ship.isSunk else {
            marks[c] = .hit
            return .hit(ship)
        }
        // Sunk: mark the ship and auto-reveal the ring of water around it.
        var auto: [Coordinate] = []
        for cell in ship.cells {
            marks[cell] = .sunk
            for n in cell.neighbors8 where marks[n] == nil && occupied[n] == nil {
                marks[n] = .miss
                auto.append(n)
            }
        }
        return .sunk(ship, autoMissed: auto)
    }

    // MARK: Rendering

    func render(revealShips: Bool) -> [String] {
        var lines = ["   " + (0..<Board.size).map { String(Character(UnicodeScalar(UInt8(65 + $0)))) }.joined(separator: " ")]
        for r in 0..<Board.size {
            let label = r + 1 < 10 ? " \(r + 1)" : "\(r + 1)"
            var line = label + " "
            for c in 0..<Board.size {
                let coord = Coordinate(row: r, col: c)
                let ch: String
                switch marks[coord] {
                case .miss?: ch = "o"
                case .hit?:  ch = "X"
                case .sunk?: ch = "#"
                case nil:    ch = (revealShips && occupied[coord] != nil) ? "S" : "~"
                }
                line += ch + " "
            }
            lines.append(line)
        }
        return lines
    }
}
