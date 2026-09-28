/// A cell on the board. Printed like "B5" (column letter + row number).
struct Coordinate: Hashable, Comparable, CustomStringConvertible {
    let row: Int
    let col: Int

    var isInside: Bool {
        (0..<Board.size).contains(row) && (0..<Board.size).contains(col)
    }

    var description: String {
        let letter = Character(UnicodeScalar(UInt8(65 + col)))
        return "\(letter)\(row + 1)"
    }

    static func < (a: Coordinate, b: Coordinate) -> Bool {
        (a.row, a.col) < (b.row, b.col)
    }

    /// Orthogonal neighbours (inside the board only).
    var neighbors4: [Coordinate] {
        [(-1, 0), (1, 0), (0, -1), (0, 1)]
            .map { Coordinate(row: row + $0.0, col: col + $0.1) }
            .filter { $0.isInside }
    }

    /// All 8 surrounding cells (inside the board only).
    var neighbors8: [Coordinate] {
        var result: [Coordinate] = []
        for dr in -1...1 {
            for dc in -1...1 where !(dr == 0 && dc == 0) {
                let c = Coordinate(row: row + dr, col: col + dc)
                if c.isInside { result.append(c) }
            }
        }
        return result
    }
}
