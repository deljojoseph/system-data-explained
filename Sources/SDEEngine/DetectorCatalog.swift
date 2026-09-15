enum DetectorCatalog {
    static let rules: [PathRule] =
        AppleRules.all
        + DeveloperRules.all
        + CreativeRules.all
        + ProductivityRules.all
        + CloudAndOfficeRules.all
        + VirtualMachineRules.all
        + SystemRules.all
}
