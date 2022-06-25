//
// Copyright © 2022 osy. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

/// Tweaks and advanced QEMU settings.
@available(iOS 13, macOS 11, *)
class UTMQemuConfigurationQEMU: Codable, ObservableObject {
    /// Base path of VM. This property is not saved to file.
    @Published var dataURL: URL?
    
    /// If true, write standard output to debug.log in the VM bundle.
    @Published var hasDebugLog: Bool = false
    
    /// If true, use UEFI boot on supported architectures.
    @Published var hasUefiBoot: Bool = false
    
    /// If true, create a virtio-rng device on supported targets.
    @Published var hasRNGDevice: Bool = false
    
    /// If true, create a virtio-balloon device on supported targets.
    @Published var hasBalloonDevice: Bool = false
    
    /// If true, create a vTPM device with an emulated backend.
    @Published var hasTPMDevice: Bool = false
    
    /// If true, use HVF hypervisor instead of TCG emulation.
    @Published var hasHypervisor: Bool = false
    
    /// If true, attempt to sync RTC with the local time.
    @Published var hasRTCLocalTime: Bool = false
    
    /// If true, emulate a PS/2 controller instead of relying on USB emulation.
    @Published var hasPS2Controller: Bool = false
    
    /// QEMU machine property that overrides the default property defined by UTM.
    @Published var machinePropertyOverride: String?
    
    /// Additional QEMU arguments.
    @Published var additionalArguments: [QEMUArgument] = []
    
    enum CodingKeys: String, CodingKey {
        case hasDebugLog = "DebugLog"
        case hasUefiBoot = "UEFIBoot"
        case hasRNGDevice = "RNGDevice"
        case hasBalloonDevice = "BalloonDevice"
        case hasTPMDevice = "TPMDevice"
        case hasHypervisor = "Hypervisor"
        case hasRTCLocalTime = "RTCLocalTime"
        case hasPS2Controller = "PS2Controller"
        case machinePropertyOverride = "MachinePropertyOverride"
        case additionalArguments = "AdditionalArguments"
    }
    
    init() {
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        hasDebugLog = try values.decode(Bool.self, forKey: .hasDebugLog)
        hasUefiBoot = try values.decode(Bool.self, forKey: .hasUefiBoot)
        hasRNGDevice = try values.decode(Bool.self, forKey: .hasRNGDevice)
        hasBalloonDevice = try values.decode(Bool.self, forKey: .hasBalloonDevice)
        hasTPMDevice = try values.decode(Bool.self, forKey: .hasTPMDevice)
        hasHypervisor = try values.decode(Bool.self, forKey: .hasHypervisor)
        hasRTCLocalTime = try values.decode(Bool.self, forKey: .hasRTCLocalTime)
        hasPS2Controller = try values.decode(Bool.self, forKey: .hasPS2Controller)
        machinePropertyOverride = try values.decodeIfPresent(String.self, forKey: .machinePropertyOverride)
        additionalArguments = try values.decode([QEMUArgument].self, forKey: .additionalArguments)
        dataURL = decoder.userInfo[.dataURL] as? URL
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hasDebugLog, forKey: .hasDebugLog)
        try container.encode(hasUefiBoot, forKey: .hasUefiBoot)
        try container.encode(hasRNGDevice, forKey: .hasRNGDevice)
        try container.encode(hasBalloonDevice, forKey: .hasBalloonDevice)
        try container.encode(hasTPMDevice, forKey: .hasTPMDevice)
        try container.encode(hasHypervisor, forKey: .hasHypervisor)
        try container.encode(hasRTCLocalTime, forKey: .hasRTCLocalTime)
        try container.encode(hasPS2Controller, forKey: .hasPS2Controller)
        try container.encodeIfPresent(machinePropertyOverride, forKey: .machinePropertyOverride)
        try container.encode(additionalArguments, forKey: .additionalArguments)
    }
}

// MARK: - Default construction

@available(iOS 13, macOS 11, *)
extension UTMQemuConfigurationQEMU {
    convenience init(forArchitecture architecture: QEMUArchitecture, target: QEMUTarget) {
        self.init()
        let rawTarget = target.rawValue
        if rawTarget.hasPrefix("pc") || rawTarget.hasPrefix("q35") {
            hasUefiBoot = true
            hasRNGDevice = true
        } else if (architecture == .arm || architecture == .aarch64) && (rawTarget.hasPrefix("virt-") || rawTarget == "virt") {
            hasUefiBoot = true
            hasRNGDevice = true
        }
        #if arch(arm64) && os(macOS)
        if architecture == .aarch64 {
            hasHypervisor = true
        }
        #elseif arch(x86_64) && os(macOS)
        if architecture == .x86_64 {
            hasHypervisor = true
        }
        #endif
    }
}

// MARK: - Conversion of old config format

@available(iOS 13, macOS 11, *)
extension UTMQemuConfigurationQEMU {
    convenience init(migrating oldConfig: UTMLegacyQemuConfiguration) {
        self.init()
        hasDebugLog = oldConfig.debugLogEnabled
        hasUefiBoot = oldConfig.systemBootUefi
        hasRNGDevice = oldConfig.systemRngEnabled
        hasHypervisor = oldConfig.useHypervisor
        hasRTCLocalTime = oldConfig.rtcUseLocalTime
        hasPS2Controller = oldConfig.forcePs2Controller
        machinePropertyOverride = oldConfig.systemMachineProperties
        if let oldAddArgs = oldConfig.systemArguments {
            additionalArguments = oldAddArgs.map({ QEMUArgument($0) })
        }
        dataURL = oldConfig.existingPath
    }
}
