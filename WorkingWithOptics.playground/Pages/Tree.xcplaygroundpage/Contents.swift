import Bow
import BowOptics

/*:
 **Problem:** given an n-ary tree, print the nodes located at level `m`.
 */

enum Tree<A> {
  case leaf(A)
  indirect case node(A, branches: NEA<Tree<A>>)
}

/*
 1
 |-- 3
 |   |-- 9
 |   |
 |   |-- 5
 |   |   |-- 2
 |   |   \-- 6
 |   |
 |   \-- 12
 |
 \-- 4
     |-- 21
     \-- 100
 */

let tree: Tree<Int> =
  .node(1, branches: .of(
    .node(3, branches: .of(
      .leaf(9),
      .node(5, branches: .of(
        .leaf(2),
        .leaf(6)
        )),
      .leaf(12)
      )),
    .node(4, branches: .of(
      .leaf(21),
      .leaf(100)
      ))
    )
)

extension Tree: AutoPrism {}

func nodesPrism<A>() -> Prism<Tree<A>, (A, NEA<Tree<A>>)> {
  return Tree.prism(for: Tree.node) { tree in
    guard case let .node(value, branches: branches) = tree else { return nil }
    return (value, branches)
  }
}

func branchesOptional<A>() -> Optional<Tree<A>, NEA<Tree<A>>> {
  return nodesPrism() + Tuple2._1
}

func levelTraversal<A>() -> Traversal<Tree<A>, Tree<A>> {
  return branchesOptional() + NEA<Tree<A>>.traversal
}

func level<A>(_ m: UInt) -> Traversal<Tree<A>, Tree<A>> {
  guard m > 0 else { return Traversal.identity }
  return (0 ..< m).map { _ in levelTraversal() }.reduce(Traversal.identity, +)
}

func valueGetter<A>() -> Getter<Tree<A>, A> {
  return Getter { tree in
    switch tree {
    case .leaf(let value), .node(let value, branches: _): return value
    }
  }
}

func values<A>(level m: UInt, in tree: Tree<A>) -> [A] {
  let levelFold: Fold<Tree<A>, A> = level(m).asFold + valueGetter()
  return levelFold.getAll(tree).asArray
}

print(values(level: 0, in: tree))
print(values(level: 1, in: tree))
print(values(level: 2, in: tree))
print(values(level: 3, in: tree))
print(values(level: 4, in: tree))
