import LoopKitUI
import EversenseNowClient


extension NowService: ServiceAuthenticationUI {
    public var credentialFormFieldHelperMessage: String? {
        return nil
    }

    public var credentialFormFields: [ServiceCredential] {
        return [
            ServiceCredential(
                title: LocalizedString("Username", comment: "The title of the Eversense Now username credential"),
                isSecret: false,
                keyboardType: .asciiCapable
            ),
            ServiceCredential(
                title: LocalizedString("Password", comment: "The title of the Eversense Now password credential"),
                isSecret: true,
                keyboardType: .asciiCapable
            )
        ]
    }
}
