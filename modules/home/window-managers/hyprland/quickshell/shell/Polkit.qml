import Quickshell
import Quickshell.Services.Polkit
import QtQuick

// The session's polkit agent: the password prompt for pkexec, systemctl on
// system units and other admin actions. A wrong password keeps the request
// open (polkit asks again), so the error shows inline.
Scope {
    id: root

    readonly property AuthFlow flow: agent.flow

    PolkitAgent {
        id: agent
    }

    Connections {
        target: root.flow
        ignoreUnknownSignals: true

        function onAuthenticationFailed() {
            prompt.clear();
        }
    }

    AuthPrompt {
        id: prompt

        owner: "polkit"
        active: agent.isActive && root.flow !== null && !root.flow.isCompleted
        title: "Authentication required"
        description: [root.flow?.message ?? "",
            root.flow && !root.flow.supplementaryIsError ? root.flow.supplementaryMessage : ""]
            .filter(t => t).join("\n")
        detail: root.flow?.actionId ?? ""
        error: root.flow?.supplementaryIsError ? root.flow.supplementaryMessage
            : root.flow?.failed ? "Wrong password, try again." : ""
        placeholder: (root.flow?.inputPrompt ?? "").replace(/:\s*$/, "") || "Password"
        echo: root.flow?.responseVisible ?? false
        // PAM is checking (or hasn't asked yet).
        busy: !(root.flow?.isResponseRequired ?? false)
        okLabel: "Authenticate"

        onAccepted: text => root.flow.submit(text)
        onCancelled: root.flow.cancelAuthenticationRequest()
    }
}
