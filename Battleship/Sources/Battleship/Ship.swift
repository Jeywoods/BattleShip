/// Ship class with its own behaviour: it tracks damage and knows when it is sunk.
final class Ship {
    let name: String
    let length: Int
    private(set) var cells: [Coordinate] = []
    private(set) var hits: Set<Coordinate> = []

    init(name: String, length: Int) {
        self.name = name
        self.length = length
    }

    var isSunk: Bool { hits.count == length }

    func place(at cells: [Coordinate]) {
        precondition(cells.count == length, "Wrong number of cells for \(name)")
        self.cells = cells
    }

    func occupies(_ c: Coordinate) -> Bool { cells.contains(c) }

    func registerHit(at c: Coordinate) {
        if occupies(c) { hits.insert(c) }
    }
}

/// Russian-rules fleet: 1x4, 2x3, 3x2, 4x1.
enum Fleet {
    static let spec: [(name: String, length: Int, count: Int)] = [
        ("Battleship", 4, 1),
        ("Cruiser", 3, 2),
        ("Destroyer", 2, 3),
        ("Boat", 1, 4)
    ]

    static func make() -> [Ship] {
        spec.flatMap { s in
            (1...s.count).map { i in
                Ship(name: s.count > 1 ? "\(s.name) #\(i)" : s.name, length: s.length)
            }
        }
    }
}
