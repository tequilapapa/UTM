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

// MARK: - Drives list

@available(iOS 14, *)
struct VMConfigDrivesView: View {
    @ObservedObject var config: UTMQemuConfiguration
    @State private var createDriveVisible: Bool = false
    @State private var attemptDelete: IndexSet?
    @State private var importDrivePresented: Bool = false
    @State private var triggerRefresh: Bool = false
    @EnvironmentObject private var data: UTMData
    
    var body: some View {
        Group {
            if config.drives.count == 0 {
                Text("No drives added.").font(.headline)
            } else {
                Form {
                    List {
                        ForEach($config.drives) { $drive in
                            NavigationLink(
                                destination: VMConfigDriveDetailsView(config: drive, triggerRefresh: $triggerRefresh, onDelete: nil), label: {
                                    VStack(alignment: .leading) {
                                        if drive.isRemovable {
                                            Text("Removable Drive")
                                        } else if drive.imageName == QEMUPackageFileName.efiVariables.rawValue {
                                            Text("EFI Variables")
                                        } else if let imageName = drive.imageName {
                                            Text(imageName)
                                                .lineLimit(1)
                                        } else {
                                            Text("(new)")
                                        }
                                        HStack {
                                            Text(drive.imageType.prettyValue).font(.caption)
                                            if drive.imageType == .disk || drive.imageType == .cd {
                                                Text("-")
                                                Text(drive.interface.prettyValue).font(.caption)
                                            }
                                        }
                                    }
                                })
                        }.onDelete { offsets in
                            attemptDelete = offsets
                        }
                        .onMove(perform: moveDrives)
                    }
                }.toolbar {
                    ToolbarItem(placement: .status) {
                        Text("Note: Boot order is as listed.")
                    }
                }.onChange(of: triggerRefresh) { _ in
                    // HACK: we need edits of drive to trigger a redraw
                }
            }
        }
        .navigationBarItems(trailing:
            HStack {
                EditButton().padding(.trailing, 10)
                Button(action: { importDrivePresented.toggle() }, label: {
                    Label("Import Drive", systemImage: "square.and.arrow.down").labelStyle(.iconOnly)
                }).padding(.trailing, 10)
                Button(action: { createDriveVisible.toggle() }, label: {
                    Label("New Drive", systemImage: "plus").labelStyle(.iconOnly)
                })
            }
        )
        .fileImporter(isPresented: $importDrivePresented, allowedContentTypes: [.item], onCompletion: importDrive)
        .sheet(isPresented: $createDriveVisible) {
            CreateDrive(system: config.system, onDismiss: newDrive)
        }
        .actionSheet(item: $attemptDelete) { offsets in
            ActionSheet(title: Text("Confirm Delete"), message: Text("Are you sure you want to permanently delete this disk image?"), buttons: [.cancel(), .destructive(Text("Delete")) {
                deleteDrives(offsets: offsets)
            }])
        }
    }
    
    private func importDrive(result: Result<URL, Error>) {
        data.busyWorkAsync {
            switch result {
            case .success(let url):
                await MainActor.run {
                    let drive = UTMQemuConfigurationDrive()
                    drive.reset(forArchitecture: config.system.architecture, target: config.system.target, isRemovable: true)
                    drive.imageURL = url
                    config.drives.append(drive)
                }
                break
            case .failure(let err):
                throw err
            }
        }
    }
    
    private func newDrive(drive: UTMQemuConfigurationDrive) {
        config.drives.append(drive)
    }
    
    private func deleteDrives(offsets: IndexSet) {
        config.drives.remove(atOffsets: offsets)
    }
    
    private func moveDrives(source: IndexSet, destination: Int) {
        config.drives.move(fromOffsets: source, toOffset: destination)
    }
}

// MARK: - Create Drive

@available(iOS 14, *)
private struct CreateDrive: View {
    @ObservedObject var system: UTMQemuConfigurationSystem
    let onDismiss: (UTMQemuConfigurationDrive) -> Void
    @StateObject private var config = UTMQemuConfigurationDrive()
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        NavigationView {
            VMConfigDriveCreateView(config: config, system: system)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: cancel)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", action: done)
                    }
                }
        }.navigationViewStyle(.stack)
        .onAppear {
            config.reset(forArchitecture: system.architecture, target: system.target)
        }
    }
    
    private func cancel() {
        presentationMode.wrappedValue.dismiss()
    }
    
    private func done() {
        presentationMode.wrappedValue.dismiss()
        onDismiss(config)
    }
}

// MARK: - Preview

@available(iOS 14, *)
struct VMConfigDrivesView_Previews: PreviewProvider {
    @ObservedObject static private var config = UTMQemuConfiguration()
    @ObservedObject static private var system = UTMQemuConfigurationSystem()
    
    static var previews: some View {
        Group {
            VMConfigDrivesView(config: config)
            CreateDrive(system: system) { _ in
                
            }
        }.onAppear {
            if config.drives.count == 0 {
                let drive = UTMQemuConfigurationDrive()
                drive.reset(forArchitecture: .x86_64, target: QEMUTarget_x86_64.pc)
                drive.imageName = "test.img"
                drive.imageType = .disk
                drive.interface = .ide
                config.drives.append(drive.copy())
                drive.reset(forArchitecture: .x86_64, target: QEMUTarget_x86_64.pc)
                drive.imageName = "bios.bin"
                drive.imageType = .bios
                drive.interface = .none
                config.drives.append(drive.copy())
            }
        }
    }
}
