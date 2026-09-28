/// AI strategy. It only looks at public information: the enemy board's marks.
protocol ShootingStrategy {
    var title: String { get }
    func chooseTarget(against enemy: Board, rng: RandomSource) -> Coordinate
}

/// Pure random: shoots any cell not shot before.
struct RandomStrategy: ShootingStrategy {
    let title = "random"

    func chooseTarget(against enemy: Board, rng: RandomSource) -> Coordinate {
        rng.pick(enemy.unshotCells)!
    }
}

/// Greedy hunt/target: finish wounded ships first, otherwise hunt on a checkerboard.
struct HuntTargetStrategy: ShootingStrategy {
    let title = "greedy hunt/target"

    func chooseTarget(against enemy: Board, rng: RandomSource) -> Coordinate {
        let unshot = enemy.unshotCells
        let unshotSet = Set(unshot)
        let hits = enemy.marks.filter { $0.value == .hit }.map { $0.key }.sorted()

        if !hits.isEmpty {
            var candidates: [Coordinate] = []
            if hits.count >= 2 {
                // Two or more hits in a line: continue along the line.
                if Set(hits.map { $0.row }).count == 1 {
                    let row = hits[0].row
                    let cols = hits.map { $0.col }
                    candidates = [Coordinate(row: row, col: cols.min()! - 1),
                                  Coordinate(row: row, col: cols.max()! + 1)]
                } else if Set(hits.map { $0.col }).count == 1 {
                    let col = hits[0].col
                    let rows = hits.map { $0.row }
                    candidates = [Coordinate(row: rows.min()! - 1, col: col),
                                  Coordinate(row: rows.max()! + 1, col: col)]
                }
                candidates = candidates.filter { unshotSet.contains($0) }
            }
            if candidates.isEmpty {
                candidates = hits.flatMap { $0.neighbors4 }.filter { unshotSet.contains($0) }
            }
            if let target = rng.pick(candidates) { return target }
        }

        // Hunt mode: checkerboard parity finds every ship of length >= 2 faster.
        let parity = unshot.filter { ($0.row + $0.col) % 2 == 0 }
        return rng.pick(parity) ?? rng.pick(unshot)!
    }
}
