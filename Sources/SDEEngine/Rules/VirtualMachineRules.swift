import SDEDomain

enum VirtualMachineRules {
    static let all: [PathRule] = [
        PathRule(
            id: "virtualization.parallels",
            matcher: .homePrefix("Parallels"),
            category: .virtualMachines,
            displayName: "Parallels Virtual Machines",
            owner: "Parallels Desktop",
            explanation: "Virtual computers and disk images created by Parallels Desktop.",
            whyLarge: "A virtual machine contains an entire operating system, applications, snapshots, and personal data.",
            risk: .review
        ),
        PathRule(
            id: "virtualization.vmware",
            matcher: .homePrefix("Virtual Machines.localized"),
            category: .virtualMachines,
            displayName: "VMware Virtual Machines",
            owner: "VMware Fusion",
            explanation: "Virtual computers and disk images created by VMware Fusion.",
            whyLarge: "Each machine stores a complete guest operating system and may include snapshots.",
            risk: .review
        ),
        PathRule(
            id: "virtualization.utm",
            matcher: .homePrefix("Library/Containers/com.utmapp.UTM"),
            category: .virtualMachines,
            displayName: "UTM Virtual Machines",
            owner: "UTM",
            explanation: "Virtual machine disks and support data created by UTM.",
            whyLarge: "Guest operating systems and virtual disks can consume tens or hundreds of gigabytes.",
            risk: .review
        ),
        PathRule(
            id: "virtualization.virtualbox",
            matcher: .homePrefix("VirtualBox VMs"),
            category: .virtualMachines,
            displayName: "VirtualBox Machines",
            owner: "VirtualBox",
            explanation: "Virtual computers and disk images created by VirtualBox.",
            whyLarge: "Each virtual disk contains a complete guest operating system and its data.",
            risk: .review
        ),
        PathRule(
            id: "virtualization.disk-images",
            matcher: .fileExtensions(["vmdk", "vdi", "qcow2", "pvm"]),
            category: .virtualMachines,
            displayName: "Virtual Disk Images",
            explanation: "Disk-image files used by virtual-machine software.",
            whyLarge: "Virtual disks represent entire computer drives and can grow very large.",
            risk: .review
        )
    ]
}
