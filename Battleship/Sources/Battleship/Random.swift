/// Deterministic generator (SplitMix64) so a session can be replayed with `--seed N`.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// Shared random source passed to board placement and AI strategies.
final class RandomSource {
    private var generator: SplitMix64

    init(seed: UInt64) { generator = SplitMix64(seed: seed) }

    func int(in range: Range<Int>) -> Int { Int.random(in: range, using: &generator) }
    func bool() -> Bool { Bool.random(using: &generator) }
    func pick<T>(_ array: [T]) -> T? {
        array.isEmpty ? nil : array[int(in: 0..<array.count)]
    }
}
