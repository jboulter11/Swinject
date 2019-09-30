import Foundation
import Swinject

// Here's a test to show what happens when you register the same thing multiple times with different configurations

protocol A {
    func f()
}
class AImpl : A {
    func f() {
        print("AImpl")
    }
}
class AImpl2 : A {
    func f() {
        print("AImpl2")
    }
}
class AImpl3 : A {
    func f() {
        print("AImpl3")
    }
}
class AImpl4 : A {
    func f() {
        print("AImpl4")
    }
}

class aAssembly : Assembly {
    func assemble(container: Container) {
        container.register(A.self) { _ in AImpl() }
        container.register(A.self) { _ in AImpl2() }
    }
}

class acAssembly : Assembly {
    func assemble(container: Container) {
        container.register(A.self) { _ in AImpl3() }
    }
}

class anotherAssembly : Assembly {
    func assemble(container: Container) {
        container.register(A.self) { _ in AImpl4() }
    }
}

let parentAssembler = Assembler([aAssembly()])
let childAssembler = Assembler([], parent: parentAssembler)
var aImpl = childAssembler.resolver.resolve(A.self)!
aImpl.f()
childAssembler.apply(assembly: anotherAssembly())
aImpl = parentAssembler.resolver.resolve(A.self)!
aImpl.f()
