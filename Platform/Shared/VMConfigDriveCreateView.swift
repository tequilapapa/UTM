//
// Copyright © 2020 osy. All rights reserved.
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

import SwiftUI

@available(iOS 14, macOS 11, *)
struct VMConfigDriveCreateView: View {
    private let mibToGib = 1024
    let minSizeMib = 1
    
    @ObservedObject var config: UTMQemuConfigurationDrive
    @ObservedObject var system: UTMQemuConfigurationSystem
    @State private var isGiB: Bool = true
    
    var body: some View {
        Form {
            Toggle(isOn: $config.isRemovable.animation(), label: {
                Text("Removable")
            }).onChange(of: config.isRemovable) { removable in
                config.interface = UTMQemuConfigurationDrive.defaultInterface(forArchitecture: system.architecture, target: system.target, imageType: config.imageType)
            }.help("If checked, no drive image will be stored with the VM. Instead you can mount/unmount image while the VM is running.")
            VMConfigConstantPicker("Interface", selection: $config.interface)
                .help("Hardware interface on the guest used to mount this image. Different operating systems support different interfaces. The default will be the most common interface.")
            if !config.isRemovable {
                HStack {
                    NumberTextField("Size", number: Binding<Int>(get: {
                        convertToDisplay(fromSizeMib: config.sizeMib)
                    }, set: {
                        config.sizeMib = convertToMib(fromSize: $0)
                    }), onEditingChanged: validateSize)
                        .multilineTextAlignment(.trailing)
                        .help("The amount of storage to allocate for this image. Ignored if importing an image. If this is a raw image, then an empty file of this size will be stored with the VM. Otherwise, the disk image will dynamically expand up to this size.")
                    Button(action: { isGiB.toggle() }, label: {
                        Text(isGiB ? "GB" : "MB")
                            .foregroundColor(.blue)
                    }).buttonStyle(.plain)
                }
                Toggle(isOn: $config.isRawImage) {
                    Text("Raw Image")
                }.help("Advanced. If checked, a raw disk image is used. Raw disk image does not support snapshots and will not dynamically expand in size.")
            }
        }
    }
    
    private func validateSize(editing: Bool) {
        guard !editing else {
            return
        }
        if config.sizeMib < minSizeMib {
            config.sizeMib = minSizeMib
        }
    }
    
    private func convertToMib(fromSize size: Int) -> Int {
        if isGiB {
            return size * mibToGib
        } else {
            return size
        }
    }
    
    private func convertToDisplay(fromSizeMib sizeMib: Int) -> Int {
        if isGiB {
            return sizeMib / mibToGib
        } else {
            return sizeMib
        }
    }
}

@available(iOS 14, macOS 11, *)
struct VMConfigDriveCreateView_Previews: PreviewProvider {
    @StateObject static private var config = UTMQemuConfigurationDrive()
    @StateObject static private var system = UTMQemuConfigurationSystem()
    
    static var previews: some View {
        VMConfigDriveCreateView(config: config, system: system)
    }
}
