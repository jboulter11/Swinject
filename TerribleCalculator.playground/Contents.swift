import Swinject
import UIKit

protocol PerformsIntegerCalculations {
    func add(lhs: Int, rhs: Int) -> Int
    func subtract(lhs: Int, rhs: Int) -> Int
    func multiply(lhs: Int, rhs: Int) -> Int
    func divide(lhs: Int, rhs: Int) -> (quotient: Int, remainder: Int)?
}

class TerribleIntegerCalculator : PerformsIntegerCalculations {
    func add(lhs: Int, rhs: Int) -> Int {
        let expression = NSExpression(format: "%d + %d", lhs, rhs)
        if let value = expression.expressionValue(with: nil, context: nil),
            let intValue = value as? Int {
            return intValue
        }
        return 0
    }
    
    func subtract(lhs: Int, rhs: Int) -> Int {
        let expression = NSExpression(format: "%d - %d", lhs, rhs)
        if let value = expression.expressionValue(with: nil, context: nil),
            let intValue = value as? Int {
            return intValue
        }
        return 0
    }
    
    func multiply(lhs: Int, rhs: Int) -> Int {
        let expression = NSExpression(format: "%d * %d", lhs, rhs)
        if let value = expression.expressionValue(with: nil, context: nil),
            let intValue = value as? Int {
            return intValue
        }
        return 0
    }
    
    func divide(lhs: Int, rhs: Int) -> (quotient: Int, remainder: Int)? {
        let divisionExpression = NSExpression(format: "%d / %d", lhs, rhs)
        let modExpression = NSExpression(forFunction: "modulus:by:", arguments: [NSExpression(forConstantValue: lhs), NSExpression(forConstantValue: rhs)])
        if let divisionValue = divisionExpression.expressionValue(with: nil, context: nil),
            let divisionIntValue = divisionValue as? Int,
            let modValue = modExpression.expressionValue(with: nil, context: nil),
            let modIntValue = modValue as? Int {
            return (quotient: divisionIntValue, remainder: modIntValue)
        }
        return nil
    }
    
}

class CalculatorViewController : UIViewController {
    enum MathOperation {
        case addition
        case subtraction
        case multiplication
        case division
    }
    
    var integerCalculator: PerformsIntegerCalculations
    
    init(integerCalculator: PerformsIntegerCalculations) {
        self.integerCalculator = integerCalculator
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    var existingTotal: Int = 0
    var operation: MathOperation? = nil
    var argumentValue: Int? = nil
    
    func equalsTapped() {
        guard let operation = self.operation else {
            return
        }
        
        switch operation {
        case .addition:
            self.existingTotal = self.integerCalculator.add(lhs: self.existingTotal, rhs: self.argumentValue ?? 0)
        case .subtraction:
            self.existingTotal = self.integerCalculator.subtract(lhs: self.existingTotal, rhs: self.argumentValue ?? 0)
        case .multiplication:
            self.existingTotal = self.integerCalculator.multiply(lhs: self.existingTotal, rhs: self.argumentValue ?? 1)
        case .division:
            guard let divAnswer = self.integerCalculator.divide(lhs: self.existingTotal, rhs: self.argumentValue ?? 1) else {
                return
            }
            self.existingTotal = divAnswer.quotient
        }
        self.operation = nil
        self.argumentValue = nil
    }
}

let terribleCalculator = TerribleIntegerCalculator()

terribleCalculator.divide(lhs: 5, rhs: 2)

func testDivisionOperationWhenEqualsTapped() {
    let vc = CalculatorViewController(integerCalculator: terribleCalculator)
    vc.existingTotal = 5
    vc.operation = .division
    vc.argumentValue = 2
    
    vc.equalsTapped()
    print(vc.existingTotal)
    assert(vc.existingTotal == 2)
    print(vc.operation as Any)
    assert(vc.operation == nil)
    print(vc.argumentValue as Any)
    assert(vc.argumentValue == nil)
}
testDivisionOperationWhenEqualsTapped()
print("finished")
