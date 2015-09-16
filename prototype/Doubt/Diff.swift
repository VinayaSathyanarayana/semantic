public enum Diff: Comparable, CustomDebugStringConvertible, CustomDocConvertible {
	case Empty
	case Patch(Fix, Fix)
	indirect case Copy(Syntax<Diff>)

	public static func Insert(term: Fix) -> Diff {
		return .Patch(.Empty, term)
	}

	public static func Delete(term: Fix) -> Diff {
		return .Patch(term, .Empty)
	}

	public var doc: Doc {
		switch self {
		case .Empty:
			return .Empty
		case let .Patch(a, b):
			return .Horizontal([
				.Wrap(.Text("{-"), Doc(a), .Text("-}")),
				.Wrap(.Text("{+"), Doc(b), .Text("+}"))
			])
		case let .Copy(a):
			return a.doc
		}
	}

	public var debugDescription: String {
		switch self {
		case .Empty:
			return ".Empty"
		case let .Patch(a, b):
			return ".Patch(\(String(reflecting: a)), \(String(reflecting: b)))"
		case let .Copy(a):
			return ".Copy(\(String(reflecting: a)))"
		}
	}

	public var magnitude: Int {
		switch self {
		case .Empty:
			return 0
		case .Patch:
			return 1
		case let .Copy(s):
			return s.map { $0.magnitude }.reduce(0, combine: +)
		}
	}

	public init(_ a: Fix, _ b: Fix) {
		switch (a, b) {
		case (.Empty, .Empty):
			self = .Empty

		case let (.Roll(a), .Roll(b)):
			switch (a, b) {
			case let (.Apply(a, aa), .Apply(b, bb)):
				// fixme: SES
				self = .Copy(.Apply(Diff(a, b), Diff.diff(aa, bb)))

			case let (.Abstract(p1, b1), .Abstract(p2, b2)):
				self = .Copy(.Abstract(Diff.diff(p1, p2), Diff(b1, b2)))

			case let (.Assign(n1, v1), .Assign(n2, v2)) where n1 == n2:
				self = .Copy(.Assign(n2, Diff(v1, v2)))

			case let (.Variable(n1), .Variable(n2)) where n1 == n2:
				self = .Copy(.Variable(n2))

			case let (.Literal(v1), .Literal(v2)) where v1 == v2:
				self = .Copy(.Literal(v2))

			case let (.Group(n1, v1), .Group(n2, v2)):
				self = .Copy(.Group(Diff(n1, n2), Diff.diff(v1, v2)))

			default:
				self = .Patch(Fix(a), Fix(b))
			}

		default:
			self = Patch(a, b)
		}
	}

	public static func diff<C1: CollectionType, C2: CollectionType where C1.Index : RandomAccessIndexType, C1.Generator.Element == Fix, C2.Index : RandomAccessIndexType, C2.Generator.Element == Fix>(a: C1, _ b: C2) -> [Diff] {
		var (aa, bb) = (Stream(sequence: a), Stream(sequence: b))
		var diffs: [Diff] = []
		repeat {
			if aa.isEmpty {
				diffs += bb.lazy.map(Diff.Insert)
				break
			} else if bb.isEmpty {
				diffs += aa.lazy.map(Diff.Delete)
				break
			} else {
				diffs.append(Diff(aa.first!, bb.first!))
			}

			aa = aa.rest
			bb = bb.rest
		} while !aa.isEmpty || !bb.isEmpty
		return diffs
	}
}

