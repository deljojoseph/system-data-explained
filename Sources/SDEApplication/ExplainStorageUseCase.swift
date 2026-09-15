import SDEDomain

public struct ExplainStorageUseCase: Sendable {
    private let classifier: any StorageClassifying

    public init(classifier: any StorageClassifying) {
        self.classifier = classifier
    }

    public func execute(_ observation: StorageObservation) -> Classification {
        classifier.classify(observation)
    }
}
