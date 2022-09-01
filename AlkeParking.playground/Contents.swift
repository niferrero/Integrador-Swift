import UIKit
import Foundation

//Enum que nos sirve para tipar fuertemente los tips de vehiculos que puede hacer referencia una instancia de Vehiculo
enum VehicleType {
    case car
    case motorcycle
    case miniBus
    case bus
    
    var rate: Int {
        switch self {
            case .car: return 20
            case .motorcycle: return 15
            case .miniBus: return 25
            case .bus: return 30
        }
    }
}

//Protocolo que nos da los lineamientos para un vehiculo que se pueda aparcar
protocol Parkable {
    var plate: String { get }
    var type: VehicleType { get }
    var checkInTime: Date { get }
    var discountCard: String? { get set }
    var parkedTime: Int { get }
}

//Estructura que prepresenta al parking
struct Parking {
    var vehicles: Set<Vehicle> = []
    private let capacity: Int = 20
    var parkingStatistics : (earnings: Int, vehicles: Int) = (0, 0)
    
    mutating func checkInVehicle(_ vehicle: Vehicle, onFinish: (Bool) -> Void) {
        //Se verifica si no se pasa la capacidad del parking y si el vehiculo existe, si cualquiera de estas condiciones es falsa se envia un error a la closure
        guard capacity > self.vehicles.count && !self.vehicles.contains(vehicle) else {
            onFinish(false)
            return
        }
        
        //Se inserta el vehiculo al parking
        self.vehicles.insert(vehicle)
        onFinish(true)
        return
    }
    
    mutating func checkOutVehicle(plate: String, onSuccess: (Int) -> Void, onError: () -> Void) {
        //Se verifica si el vehiculo existe
        let vehicleFound = self.vehicles.first(where: { $0.plate == plate })
        //Se desempaqueta debido a el metodo frist nos devuelve un optional
        guard let vehicle = vehicleFound else {
            onError()
            return
        }

        //Se elimina el vehiculo
        self.vehicles.remove(vehicle)
        //Se verifica si tiene descuento
        let hasDiscount = vehicle.discountCard != nil
        //Se calcula el monto a pagar
        let checkoutFee = self.calculateFee(type: vehicle.type, parkedTime: vehicle.parkedTime, hasDiscountCard: hasDiscount)
        //Se actualzian las estadisticas del parking
        self.parkingStatistics.earnings += checkoutFee
        self.parkingStatistics.vehicles += 1
        onSuccess(checkoutFee)
        return
    }
    
    private func calculateFee(type: VehicleType, parkedTime: Int, hasDiscountCard: Bool) -> Int {
        let hoursInMinutes = 120
        var total = 0
        //Si el tiempo de estacionamiento es menor o igual a 2H el cobro es $20.
        //Si el tiempo es de mas de 2H:
        //  - Se calculan los minutos restantes
        //  - Se calculan los los bloques de 15' (se usa la funcion ceil para redondear siempre para arriba si hay decimales tal como se muestra en el ejemplo del pdf)
        //  - Se calculan el total a partir de precio de las 2H mas los bloques de 15' multiplicados por el valor de cada bloque de 15'
        if parkedTime <= 120 {
            total = type.rate
        } else {
            let minutesleft = Float(parkedTime - hoursInMinutes)
            let feeBlocks = ceil((minutesleft/15))
            total = type.rate + Int(feeBlocks) * (type.rate/4)
        }

        //Se usa un operador trnario para saber si tiene descuento y se aplica este 15% o si se cobra el total
        return hasDiscountCard ? Int(floor(Float(total) * 0.85)) : total
    }
    
    func showStatistics() {
        print("\(self.parkingStatistics.vehicles) vehicles have checked out and have earnings of $\(self.parkingStatistics.earnings)")
    }
    
    func listVehicles() {
        self.vehicles.forEach { vehicle in
            print("Vehicle plate is \(vehicle.plate)")
        }
    }
}

//Estructura que prepresenta al vehiculo
struct Vehicle: Parkable, Hashable {
    let plate: String
    let type: VehicleType
    let checkInTime: Date = Date()
    var discountCard: String?
    var parkedTime: Int {
        Calendar.current.dateComponents([.minute], from: checkInTime, to: Date()).minute ?? 0
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(plate)
    }
    
    static func ==(lhs: Vehicle, rhs: Vehicle) -> Bool {
        return lhs.plate == rhs.plate
    }
}

var alkeParking = Parking()

let vehicles = [
    Vehicle(plate: "AA111AA", type:VehicleType.car, discountCard: "DISCOUNT_CARD_001"),
    Vehicle(plate: "B222BBB", type: VehicleType.motorcycle, discountCard: nil),
    Vehicle(plate: "DD444DD", type: VehicleType.bus, discountCard: "DISCOUNT_CARD_002"),
    Vehicle(plate: "CC333CC", type: VehicleType.miniBus, discountCard: nil),
    Vehicle(plate: "DD55DD", type: VehicleType.bus, discountCard: "DISCOUNT_CARD_002"),
    Vehicle(plate: "AA111BB", type: VehicleType.car, discountCard: "DISCOUNT_CARD_003"),
    Vehicle(plate: "B222CCC", type: VehicleType.motorcycle, discountCard: "DISCOUNT_CARD_004"),
    Vehicle(plate: "CC333DD", type: VehicleType.miniBus, discountCard: nil),
    Vehicle(plate: "DD444EE", type: VehicleType.bus, discountCard: "DISCOUNT_CARD_005"),
    Vehicle(plate: "AA111CC", type: VehicleType.car, discountCard: nil),
    Vehicle(plate: "B222DDD", type: VehicleType.motorcycle, discountCard: nil),
    Vehicle(plate: "CC333EE", type: VehicleType.miniBus, discountCard: nil),
    Vehicle(plate: "DD444GG", type: VehicleType.bus, discountCard: "DISCOUNT_CARD_006"),
    Vehicle(plate: "AA111DD", type: VehicleType.car, discountCard: "DISCOUNT_CARD_007"),
    Vehicle(plate: "B222EEE", type: VehicleType.motorcycle, discountCard: nil),
    Vehicle(plate: "CC333FF", type: VehicleType.miniBus, discountCard: nil),
    Vehicle(plate: "AA444HH", type: VehicleType.bus, discountCard: "DISCOUNT_CARD_008"),
    Vehicle(plate: "AA888PP", type: VehicleType.car, discountCard: "DISCOUNT_CARD_009"),
    Vehicle(plate: "B555QQQ", type: VehicleType.motorcycle, discountCard: nil),
]

//Inserto los 19 primeros vehiculos
print("************************************")
print("Ingreso \(vehicles.count) vehiculos:")
vehicles.forEach { vehicle in
    alkeParking.checkInVehicle(vehicle) { canInsert in
        if !canInsert {
            print("Sorry, the check-in failed")
        } else {
            print("Welcome to AlkeParking!")
        }
    }
}
print("************************************\n")

//Pruebo ingresar un vehiculo que ya existe
print("************************************")
print("Prueba vehiculo patente repetida:")
let repeatedVehicle = Vehicle(plate: "B555QQQ", type: VehicleType.car, discountCard: nil)
alkeParking.checkInVehicle(repeatedVehicle) { canInsert in
    if !canInsert {
        print("Sorry, the check-in failed")
    } else {
        print("Welcome to AlkeParking!")
    }
}
print("************************************\n")

//Ingreso el vehiculo numero 20
print("************************************")
print("Ingreso el vehiculo numero 20:")
let vehicle20 = Vehicle(plate: "CC444WW", type: VehicleType.miniBus, discountCard: nil)
alkeParking.checkInVehicle(vehicle20) { canInsert in
    if !canInsert {
        print("Sorry, the check-in failed")
    } else {
        print("Welcome to AlkeParking!")
    }
}
print("************************************\n")

//Pruebo ingresar un vehiculo luego de que ya haya 20 dentro
print("************************************")
print("Prueba ingresar unvehiculo con parking lleno:")
let vehicle21 = Vehicle(plate: "CC444ZZ", type: VehicleType.miniBus, discountCard: nil)
alkeParking.checkInVehicle(vehicle21) { canInsert in
    if !canInsert {
        print("Sorry, the check-in failed")
    } else {
        print("Welcome to AlkeParking!")
    }
}
print("************************************\n")

//Pruebo hacer el checkout de un vehivulo que existe
print("************************************")
print("Prueba checkout de 2 vehiculos existentes:")
alkeParking.checkOutVehicle(plate: "CC444WW") { fee in
    print("Your fee is $\(fee). Come back soon")
} onError: {
    print("Sorry, the check-out failed")
}
//Muestro las estadisticas del parking
alkeParking.showStatistics()

//Pruebo hacer el checkout de un vehivulo que existe
alkeParking.checkOutVehicle(plate: "AA888PP") { fee in
    print("Your fee is $\(fee). Come back soon")
} onError: {
    print("Sorry, the check-out failed")
}
//Muestro las estadisticas del parking
alkeParking.showStatistics()
print("************************************\n")

//Pruebo hacer el checkout de un vehivulo que no existe
print("************************************")
print("Prueba checkout de vehiculo que no existe:")
alkeParking.checkOutVehicle(plate: "CC444ZZ") { fee in
    print("Your fee is $\(fee). Come back soon")
} onError: {
    print("Sorry, the check-out failed")
}
print("************************************")
