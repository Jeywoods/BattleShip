import Foundation

// Usage: swift run Battleship [--seed 42]
// In Xcode: Product > Scheme > Edit Scheme > Run > Arguments to pass a seed.
var seed = UInt64(Date().timeIntervalSince1970 * 1000)
let args = CommandLine.arguments
if let i = args.firstIndex(of: "--seed"), i + 1 < args.count, let s = UInt64(args[i + 1]) {
    seed = s
}

let rng = RandomSource(seed: seed)
let game = Game(
    players: [
        Player(name: "Alice", strategy: HuntTargetStrategy()),
        Player(name: "Bob", strategy: RandomStrategy())
    ],
    rng: rng
)
game.run()
