package com.example.pilulasdoconhecimento

import android.content.Context
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.lang.reflect.Field
import kotlin.collections.HashMap

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.pilulasdoconhecimento.dev/car_info"
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "isCarParked" -> {
                            try {
                                val mapResult = readGearOrParkReflection()
                                result.success(mapResult)
                            } catch (e: Exception) {
                                Log.w(TAG, "Erro em isCarParked: ${e.message}", e)
                                val fallback = HashMap<String, Any?>()
                                fallback["parked"] = true
                                fallback["property"] = null
                                fallback["rawValue"] = null
                                result.success(fallback)
                            }
                        }

                        "listCarProperties" -> {
                            try {
                                val list = listCarPropertiesReflection()
                                result.success(list)
                            } catch (e: Exception) {
                                Log.w(TAG, "Erro em listCarProperties: ${e.message}", e)
                                result.success(emptyList<Map<String, Any?>>())
                            }
                        }

                        "readPropertyById" -> {
                            try {
                                val arg = call.arguments
                                val id = when (arg) {
                                    is Int -> arg
                                    is Number -> arg.toInt()
                                    is String -> arg.toIntOrNull() ?: -1
                                    else -> -1
                                }
                                if (id == -1) {
                                    result.error("INVALID_ARG", "Property id inválido", null)
                                } else {
                                    val map = readPropertyByIdReflection(id)
                                    result.success(map)
                                }
                            } catch (e: Exception) {
                                Log.w(TAG, "Erro em readPropertyById handler: ${e.message}", e)
                                result.error("ERROR", "Erro interno", e.message)
                            }
                        }

                        else -> result.notImplemented()
                    }
                }
    }

    private fun readGearOrParkReflection(): HashMap<String, Any?> {
        val res = HashMap<String, Any?>()
        res["parked"] = true
        res["property"] = null
        res["rawValue"] = null

        try {
            val carClass = try {
                Class.forName("android.car.Car")
            } catch (e: Exception) {
                Log.w(TAG, "Classe android.car.Car não encontrada via reflection: ${e.message}")
                return res
            }

            val createCarMethod = carClass.getMethod("createCar", Context::class.java)
            val carInstance = try {
                createCarMethod.invoke(null, this)
            } catch (e: Exception) {
                Log.w(TAG, "Falha ao invocar Car.createCar(): ${e.message}")
                return res
            }

            if (carInstance == null) {
                Log.w(TAG, "Car.createCar() retornou null.")
                return res
            }

            val propertyServiceField = try {
                carClass.getField("PROPERTY_SERVICE").get(null) as? String
            } catch (e: Exception) {
                Log.w(TAG, "Não conseguiu ler Car.PROPERTY_SERVICE: ${e.message}")
                try { carInstance.javaClass.getMethod("disconnect").invoke(carInstance) } catch (_: Exception) {}
                return res
            }

            if (propertyServiceField == null) {
                Log.w(TAG, "Car.PROPERTY_SERVICE é nulo.")
                try { carInstance.javaClass.getMethod("disconnect").invoke(carInstance) } catch (_: Exception) {}
                return res
            }

            val getCarManagerMethod = try {
                carClass.getMethod("getCarManager", String::class.java)
            } catch (e: Exception) {
                Log.w(TAG, "Car.getCarManager method não encontrada: ${e.message}")
                try { carInstance.javaClass.getMethod("disconnect").invoke(carInstance) } catch (_: Exception) {}
                return res
            }

            val carPropManager = try {
                getCarManagerMethod.invoke(carInstance, propertyServiceField)
            } catch (e: Exception) {
                Log.w(TAG, "Falha ao invocar getCarManager: ${e.message}")
                try { carInstance.javaClass.getMethod("disconnect").invoke(carInstance) } catch (_: Exception) {}
                return res
            }

            if (carPropManager == null) {
                Log.w(TAG, "carPropManager é nulo (Car API não disponível).")
                try { carInstance.javaClass.getMethod("disconnect").invoke(carInstance) } catch (_: Exception) {}
                return res
            }

            val vehiclePropertyIdsClass = try {
                Class.forName("android.car.VehiclePropertyIds")
            } catch (e: Exception) {
                Log.w(TAG, "VehiclePropertyIds não encontrada: ${e.message}")
                try { carInstance.javaClass.getMethod("disconnect").invoke(carInstance) } catch (_: Exception) {}
                return res
            }

            val keywords = listOf("GEAR", "TRANSMISSION", "PARK", "PARKING", "SHIFT")

            val candidates = mutableListOf<Pair<String, Int>>()
            for (f in vehiclePropertyIdsClass.fields) {
                try {
                    val name = f.name
                    val upper = name.uppercase()
                    if (keywords.any { upper.contains(it) }) {
                        val id = f.getInt(null)
                        candidates.add(Pair(name, id))
                    }
                } catch (e: Exception) {
                    // ignora
                }
            }

            Log.i(TAG, "Candidatas para gear/park: ${candidates.map { it.first }}")

            var areaGlobalObj: Any? = null
            try {
                val vehicleAreaTypeClass = Class.forName("android.car.VehicleAreaType")
                val globalField = vehicleAreaTypeClass.getField("GLOBAL")
                areaGlobalObj = globalField.get(null)
            } catch (e: Exception) {
                Log.w(TAG, "VehicleAreaType não encontrada, usaremos 0 como areaId: ${e.message}")
                areaGlobalObj = 0
            }

            val getPropertyMethod = try {
                carPropManager.javaClass.getMethod("getProperty", Int::class.javaPrimitiveType, Int::class.javaPrimitiveType)
            } catch (e: Exception) {
                Log.w(TAG, "carPropManager.getProperty(int,int) não encontrada: ${e.message}")
                try { carInstance.javaClass.getMethod("disconnect").invoke(carInstance) } catch (_: Exception) {}
                return res
            }

            for ((name, id) in candidates) {
                try {
                    val areaInt = when (areaGlobalObj) {
                        is Int -> areaGlobalObj as Int
                        is Number -> (areaGlobalObj as Number).toInt()
                        else -> 0
                    }

                    val propObj = try {
                        getPropertyMethod.invoke(carPropManager, id, areaInt)
                    } catch (e: Exception) {
                        Log.w(TAG, "getProperty failed for $name($id): ${e.message}")
                        null
                    }

                    if (propObj == null) {
                        Log.i(TAG, "Propriedade $name devolveu null")
                        continue
                    }

                    val valueField: Field? = try {
                        propObj.javaClass.getField("value")
                    } catch (e: Exception) {
                        null
                    }

                    val rawValue = if (valueField != null) {
                        valueField.get(propObj)
                    } else {
                        try {
                            val m = propObj.javaClass.getMethod("getValue")
                            m.invoke(propObj)
                        } catch (e: Exception) {
                            null
                        }
                    }

                    Log.i(TAG, "Propriedade encontrada: $name (id=$id) -> rawValue=${rawValue?.toString() ?: "null"} (tipo=${rawValue?.javaClass})")

                    var parkedInterpret: Boolean? = null
                    if (rawValue is Boolean && name.uppercase().contains("PARK")) {
                        parkedInterpret = rawValue
                    }

                    res["property"] = name
                    res["rawValue"] = rawValue?.toString()

                    if (parkedInterpret != null) {
                        res["parked"] = parkedInterpret
                    } else {
                        res["parked"] = true
                    }

                    try { carInstance.javaClass.getMethod("disconnect").invoke(carInstance) } catch (_: Exception) {}
                    return res

                } catch (e: Exception) {
                    Log.w(TAG, "Erro lendo candidate $name: ${e.message}")
                }
            }

            Log.w(TAG, "Nenhuma propriedade de gear/park encontrada entre candidatos.")
            try { carInstance.javaClass.getMethod("disconnect").invoke(carInstance) } catch (_: Exception) {}
            return res

        } catch (e: Exception) {
            Log.w(TAG, "Exceção geral no readGearOrParkReflection: ${e.message}", e)
            return res
        }
    }

    private fun listCarPropertiesReflection(): List<Map<String, Any?>> {
        val results = mutableListOf<Map<String, Any?>>()
        try {
            val carClass = try { Class.forName("android.car.Car") } catch (e: Exception) {
                Log.w(TAG, "Car class not found: ${e.message}")
                return results
            }

            val createCarMethod = carClass.getMethod("createCar", Context::class.java)
            val carInstance = try { createCarMethod.invoke(null, this) } catch (e: Exception) {
                Log.w(TAG, "createCar invocation failed: ${e.message}")
                return results
            }
            if (carInstance == null) return results

            val propertyServiceField = try { carClass.getField("PROPERTY_SERVICE").get(null) as? String } catch (e: Exception) {
                Log.w(TAG, "Cannot read Car.PROPERTY_SERVICE: ${e.message}")
                try { carInstance.javaClass.getMethod("disconnect").invoke(carInstance) } catch (_: Exception) {}
                return results
            }

            val getCarManagerMethod = carClass.getMethod("getCarManager", String::class.java)
            val carPropManager = try { getCarManagerMethod.invoke(carInstance, propertyServiceField) } catch (e: Exception) {
                Log.w(TAG, "getCarManager invocation failed: ${e.message}")
                try { carInstance.javaClass.getMethod("disconnect").invoke(carInstance) } catch (_: Exception) {}
                return results
            }
            if (carPropManager == null) { try { carInstance.javaClass.getMethod("disconnect").invoke(carInstance) } catch (_: Exception) {} ; return results }

            try {
                val getPropertyListMethod = try { carPropManager.javaClass.getMethod("getPropertyList") } catch (e: Exception) {
                    Log.w(TAG, "carPropManager.getPropertyList() not found: ${e.message}")
                    try { carInstance.javaClass.getMethod("disconnect").invoke(carInstance) } catch (_: Exception) {}
                    return results
                }

                val propListObj = try { getPropertyListMethod.invoke(carPropManager) } catch (e: Exception) {
                    Log.w(TAG, "getPropertyList invocation failed: ${e.message}")
                    try { carInstance.javaClass.getMethod("disconnect").invoke(carInstance) } catch (_: Exception) {}
                    return results
                }

                val idToName = mutableMapOf<Int, String>()
                try {
                    val vehiclePropertyIdsClass = Class.forName("android.car.VehiclePropertyIds")
                    for (f in vehiclePropertyIdsClass.fields) {
                        try { val v = f.getInt(null); idToName[v] = f.name } catch (_: Exception) {}
                    }
                } catch (_: Exception) {}

                if (propListObj is java.util.Collection<*>) {
                    for (cfg in propListObj) {
                        try {
                            val getPropertyIdM = cfg?.javaClass?.getMethod("getPropertyId")
                            val propId = getPropertyIdM?.invoke(cfg) as? Int
                            val areaTypeM = try { cfg?.javaClass?.getMethod("getAreaType") } catch (e: Exception) { null }
                            val areaType = areaTypeM?.invoke(cfg)

                            val entry = mapOf<String, Any?>(
                                    "propertyId" to propId,
                                    "propertyName" to (if (propId != null && idToName.containsKey(propId)) idToName[propId] else null),
                                    "areaType" to (areaType?.toString()),
                                    "rawObjectClass" to (cfg?.javaClass?.name)
                            )
                            results.add(entry)
                        } catch (e: Exception) {
                            // ignore problematic entry
                        }
                    }
                }

                try { carInstance.javaClass.getMethod("disconnect").invoke(carInstance) } catch (_: Exception) {}
                return results

            } catch (e: Exception) {
                Log.w(TAG, "Exception in listCarPropertiesReflection: ${e.message}", e)
                try { carInstance.javaClass.getMethod("disconnect").invoke(carInstance) } catch (_: Exception) {}
                return results
            }

        } catch (e: Exception) {
            Log.w(TAG, "Exception in listCarPropertiesReflection: ${e.message}", e)
            return results
        }
    }

    private fun readPropertyByIdReflection(propertyId: Int): Map<String, Any?> {
        val res = HashMap<String, Any?>()
        res["propertyId"] = propertyId
        res["rawValue"] = null
        res["error"] = null

        try {
            val carClass = try { Class.forName("android.car.Car") } catch (e: Exception) { res["error"] = "Car class not found"; return res }
            val createCarMethod = carClass.getMethod("createCar", Context::class.java)
            val carInstance = try { createCarMethod.invoke(null, this) } catch (e: Exception) { res["error"] = "createCar failed: ${e.message}"; return res }
            if (carInstance == null) { res["error"] = "createCar returned null"; return res }

            val propertyServiceField = try { carClass.getField("PROPERTY_SERVICE").get(null) as? String } catch (e: Exception) { res["error"] = "no PROPERTY_SERVICE"; try { carInstance.javaClass.getMethod("disconnect").invoke(carInstance) } catch (_: Exception) {} ; return res }
            val getCarManagerMethod = carClass.getMethod("getCarManager", String::class.java)
            val carPropManager = try { getCarManagerMethod.invoke(carInstance, propertyServiceField) } catch (e: Exception) { res["error"] = "getCarManager failed"; try { carInstance.javaClass.getMethod("disconnect").invoke(carInstance) } catch (_: Exception) {} ; return res }
            if (carPropManager == null) { res["error"] = "carPropManager null"; try { carInstance.javaClass.getMethod("disconnect").invoke(carInstance) } catch (_: Exception) {} ; return res }

            var areaInt = 0
            try {
                val vehicleAreaTypeClass = Class.forName("android.car.VehicleAreaType")
                val globalField = vehicleAreaTypeClass.getField("GLOBAL")
                val areaObj = globalField.get(null)
                areaInt = when (areaObj) {
                    is Int -> areaObj
                    is Number -> (areaObj as Number).toInt()
                    else -> 0
                }
            } catch (_: Exception) {
                areaInt = 0
            }

            val getPropertyMethod = carPropManager.javaClass.getMethod("getProperty", Int::class.javaPrimitiveType, Int::class.javaPrimitiveType)
            val propObj = try { getPropertyMethod.invoke(carPropManager, propertyId, areaInt) } catch (e: Exception) { res["error"] = "getProperty failed: ${e.message}"; try { carInstance.javaClass.getMethod("disconnect").invoke(carInstance) } catch (_: Exception) {} ; return res }
            if (propObj == null) { res["rawValue"] = null; try { carInstance.javaClass.getMethod("disconnect").invoke(carInstance) } catch (_: Exception) {} ; return res }

            val rawValue = try {
                val valueField = propObj.javaClass.getField("value")
                valueField.get(propObj)
            } catch (e: Exception) {
                try {
                    val m = propObj.javaClass.getMethod("getValue")
                    m.invoke(propObj)
                } catch (ex: Exception) {
                    null
                }
            }

            res["rawValue"] = rawValue?.toString()
            try { carInstance.javaClass.getMethod("disconnect").invoke(carInstance) } catch (_: Exception) {}
            return res

        } catch (e: Exception) {
            res["error"] = "exception: ${e.message}"
            return res
        }
    }
}