import Foundation
import Testing
@testable import DiskmanCore

@Test
func placeholderSnapshotContainsVolume() {
    #expect(DiskSnapshot.placeholder.volumes.isEmpty == false)
}

@Test
func volumeRatiosAreClamped() {
    #expect(VolumeSnapshot.ratio(25, 100) == 0.25)
    #expect(VolumeSnapshot.ratio(-10, 100) == 0)
    #expect(VolumeSnapshot.ratio(120, 100) == 1)
    #expect(VolumeSnapshot.ratio(50, 0) == 0)
}

@Test
func byteFormatterProducesUnits() {
    let formatted = DiskByteFormatter.decimal.string(fromByteCount: 1_000_000_000)

    #expect(formatted.contains("GB"))
}

@Test
func resourceSnapshotBuildsVolumeSnapshot() throws {
    let resource = VolumeResourceSnapshot(
        url: URL(filePath: "/Volumes/Backup"),
        name: "Backup",
        localizedName: nil,
        localizedFormatDescription: "APFS",
        totalCapacity: 1_000,
        availableCapacity: 250,
        importantAvailableCapacity: 200,
        isBrowsable: true,
        isInternal: false,
        isEjectable: true,
        isRemovable: false,
        isLocal: true,
        isAutomounted: false
    )

    let volume = try #require(VolumeSnapshot(resource: resource))

    #expect(volume.name == "Backup")
    #expect(volume.mountPath == "/Volumes/Backup")
    #expect(volume.kind == VolumeKind.externalDrive)
    #expect(volume.totalBytes == 1_000)
    #expect(volume.availableBytes == 250)
    #expect(volume.importantAvailableBytes == 200)
    #expect(volume.usedBytes == 750)
    #expect(volume.categories.map(\StorageCategorySnapshot.id) == [StorageCategoryID.used, .available])
}

@Test
func resourceSnapshotFiltersTechnicalVolumes() {
    let hidden = VolumeResourceSnapshot(
        url: URL(filePath: "/System/Volumes/Preboot"),
        name: "Preboot",
        localizedName: nil,
        localizedFormatDescription: "APFS",
        totalCapacity: 1_000,
        availableCapacity: 250,
        importantAvailableCapacity: nil,
        isBrowsable: false,
        isInternal: true,
        isEjectable: false,
        isRemovable: false,
        isLocal: true,
        isAutomounted: false
    )

    #expect(VolumeSnapshot(resource: hidden) == nil)
}

@Test
func resourceSnapshotClassifiesNetworkAndDiskImages() {
    let network = VolumeResourceSnapshot(
        url: URL(filePath: "/Volumes/TeamShare"),
        name: "TeamShare",
        localizedName: nil,
        localizedFormatDescription: "SMB",
        totalCapacity: 1_000,
        availableCapacity: 250,
        importantAvailableCapacity: nil,
        isBrowsable: true,
        isInternal: false,
        isEjectable: false,
        isRemovable: false,
        isLocal: false,
        isAutomounted: false
    )

    let diskImage = VolumeResourceSnapshot(
        url: URL(filePath: "/Volumes/Installer"),
        name: "Installer",
        localizedName: nil,
        localizedFormatDescription: "Disk Image",
        totalCapacity: 1_000,
        availableCapacity: 250,
        importantAvailableCapacity: nil,
        isBrowsable: true,
        isInternal: false,
        isEjectable: true,
        isRemovable: false,
        isLocal: true,
        isAutomounted: false
    )

    #expect(VolumeSnapshot(resource: network)?.kind == .network)
    #expect(VolumeSnapshot(resource: diskImage)?.kind == .diskImage)
}
